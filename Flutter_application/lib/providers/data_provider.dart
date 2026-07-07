import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'auth_provider.dart';
import '../models/metric_point.dart';
import '../services/stress_calculator.dart';
import '../services/weekly_report_builder.dart';
import '../utils/weekly_report_model.dart';

class DataProvider extends ChangeNotifier {
  final AuthProvider authProvider;
  final String _baseUrl = 'https://impact.dei.unipd.it/bwthw';
  static const String _patientUsername = 'Jpefaq6m58';

  bool isLoading = false;
  int totalSteps = 0;
  double totalCalories = 0.0;
  double totalDistance = 0.0;

  DataProvider({required this.authProvider});



  WeeklyReport? _lastWeeklyReport;
  List<WeeklyReport>? _cachedArchive;

  Future<WeeklyReport>? _lastReportInFlight;
  Future<List<WeeklyReport>>? _archiveInFlight;

  WeeklyReport? get lastWeeklyReport => _lastWeeklyReport;
  List<WeeklyReport>? get cachedArchive => _cachedArchive;


  void clearArchiveCache() {
    _cachedArchive = null;
    _lastWeeklyReport = null;
    notifyListeners();
  }


  Future<WeeklyReport> getOrFetchLatestReport({
    required int stepsGoalTarget,
    required double sleepGoalHours,
    required bool goalsEnabled,
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh && _lastWeeklyReport != null) {
      return _lastWeeklyReport!;
    }


    if (!forceRefresh && _lastReportInFlight != null) {
      return _lastReportInFlight!;
    }

    final future = _fetchLatestReport(
      stepsGoalTarget: stepsGoalTarget,
      sleepGoalHours: sleepGoalHours,
      goalsEnabled: goalsEnabled,
    );
    _lastReportInFlight = future;

    try {
      final report = await future;
      _lastWeeklyReport = report;

      if (_cachedArchive != null && _cachedArchive!.isNotEmpty) {
        _cachedArchive![0] = report;
      }

      notifyListeners();
      return report;
    } finally {
      _lastReportInFlight = null;
    }
  }

  Future<WeeklyReport> _fetchLatestReport({
    required int stepsGoalTarget,
    required double sleepGoalHours,
    required bool goalsEnabled,
  }) async {
    final ranges = WeeklyReportBuilder.buildWeekRanges(weekCount: 1);
    final range = ranges.first;
    return WeeklyReportBuilder.build(
      dataProvider: this,
      weekStart: range.start,
      weekEnd: range.end,
      stepsGoalTarget: stepsGoalTarget,
      sleepGoalHours: sleepGoalHours,
      goalsEnabled: goalsEnabled,
    );
  }


  Future<List<WeeklyReport>> getOrFetchArchive({
    required int stepsGoalTarget,
    required double sleepGoalHours,
    required bool goalsEnabled,
    void Function(List<WeeklyReport> partial)? onProgress,
    bool forceRefresh = false,
  }) {
    if (forceRefresh) {
      _cachedArchive = null;
    }

    final ranges = WeeklyReportBuilder.buildWeekRanges();

    if (_cachedArchive != null && _cachedArchive!.length >= ranges.length) {
      return Future.value(List.from(_cachedArchive!));
    }

    if (_archiveInFlight != null) {
      return _archiveInFlight!;
    }

    final future = _fetchArchive(
      ranges: ranges,
      stepsGoalTarget: stepsGoalTarget,
      sleepGoalHours: sleepGoalHours,
      goalsEnabled: goalsEnabled,
      onProgress: onProgress,
    );
    _archiveInFlight = future;

    future.whenComplete(() {
      _archiveInFlight = null;
    });

    return future;
  }

  Future<List<WeeklyReport>> _fetchArchive({
    required List<({DateTime start, DateTime end})> ranges,
    required int stepsGoalTarget,
    required double sleepGoalHours,
    required bool goalsEnabled,
    void Function(List<WeeklyReport> partial)? onProgress,
  }) async {
    final List<WeeklyReport> reports = _cachedArchive != null
        ? List.from(_cachedArchive!)
        : [];

    while (reports.length < ranges.length) {
      final r = ranges[reports.length];
      reports.add(WeeklyReport.empty(
        weekStart: r.start,
        weekEnd: r.end,
        dateRangeIt: '',
        dateRangeEn: '',
      ));
    }
    _cachedArchive = List.from(reports);
    onProgress?.call(List.from(reports));

    final int startIndex =
        _cachedArchive != null ? _firstIncompleteIndex(reports) : 0;

    for (int i = startIndex; i < ranges.length; i++) {
      final r = ranges[i];

      if (i == 0 && _lastWeeklyReport != null) {
        reports[i] = _lastWeeklyReport!;
      } else {
        final report = await WeeklyReportBuilder.build(
          dataProvider: this,
          weekStart: r.start,
          weekEnd: r.end,
          stepsGoalTarget: stepsGoalTarget,
          sleepGoalHours: sleepGoalHours,
          goalsEnabled: goalsEnabled,
        );
        reports[i] = report;
        if (i == 0) _lastWeeklyReport = report;
      }

      _cachedArchive = List.from(reports);
      onProgress?.call(List.from(reports));
    }

    notifyListeners();
    return reports;
  }

  int _firstIncompleteIndex(List<WeeklyReport> reports) {
    for (int i = 0; i < reports.length; i++) {
      final r = reports[i];
       if (!r.hasData && r.dateRangeIt.isEmpty) return i;
    }
    return reports.length;
  }

    static const Map<String, String> _zoneNameToKey = {
    'Fuori zona':        'outOfZone',
    'Out of Range':      'outOfZone',
    'Grassi bruciati':   'fatBurn',
    'Fat Burn':          'fatBurn',
    'Attivita aerobica': 'cardio',
    'Attività aerobica': 'cardio',
    'Cardio':            'cardio',
    'Picco':             'peak',
    'Peak':              'peak',
  };


  static const _sumMetrics = {'steps', 'distance', 'exercise'};

  // ── fetchMetricRange ──────────────────────────────────────────────────────
  // Contains one MetricPoint (daily sum or average) for each metric in a range. Used in weekly reports.


  Future<List<MetricPoint>> fetchMetricRange(
      String metric, String startDate, String endDate) async {
    if (!authProvider.isAuthenticated) return [];

    final url = Uri.parse(
        '$_baseUrl/data/v1/$metric/patients/$_patientUsername/daterange/start_date/$startDate/end_date/$endDate/');

    final response = await _makeAuthenticatedGetRequest(url);

    if (response != null && response.statusCode == 200) {
      try {
        final jsonResponse = jsonDecode(response.body);
        final dynamic dataField = jsonResponse['data'];
        final Map<String, List<double>> byDay = {};

        if (dataField is List) {
          for (final dayObj in dataField) {
            final String date = dayObj['date'].toString();
            if (metric == 'sleep') {
              final dynamic sleepData = dayObj['data'];
              if (sleepData != null && sleepData is Map) {
                final double minutes =
                    double.tryParse(sleepData['minutesAsleep'].toString()) ?? 0;
                byDay[date] = [minutes / 60.0];
              }
            } else {
              final dynamic rawData = dayObj['data'];
              if (rawData is! List) continue;
              byDay[date] = (rawData as List)
                  .map((e) => double.tryParse(e['value'].toString()) ?? 0.0)
                  .toList();
            }
          }
        } else if (dataField is Map) {
          final List<dynamic> flat = dataField['data'] as List;
          for (final entry in flat) {
            final String time = entry['time'].toString();
            final String date =
                time.length >= 10 ? time.substring(0, 10) : startDate;
            byDay.putIfAbsent(date, () => []);
            byDay[date]!.add(double.tryParse(entry['value'].toString()) ?? 0.0);
          }
        }

        print('fetchMetricRange [$metric]: ${byDay.length} giorni');

        final bool useSum = _sumMetrics.contains(metric);
        final points = byDay.entries.map((entry) {
          final nonZero = entry.value.where((v) => v > 0).toList();
          final double agg = nonZero.isEmpty
              ? 0
              : useSum
                  ? nonZero.reduce((a, b) => a + b)
                  : nonZero.reduce((a, b) => a + b) / nonZero.length;
          return MetricPoint(
            shortLabel: entry.key.substring(5),
            fullLabel:  entry.key,
            value: double.parse(agg.toStringAsFixed(1)),
          );
        }).toList()
          ..sort((a, b) => a.fullLabel.compareTo(b.fullLabel));

        return points;
      } catch (e, stack) {
        print('fetchMetricRange parse ERROR: $e');
        print(stack);
        return [];
      }
    }
    return [];
  }

  // ── fetchSingleDayMetric ──────────────────────────────────────────────────
  // Takes raw data (with a limit of 80 points) and aggregates them (for home screen).

  Future<List<MetricPoint>> fetchSingleDayMetric(
      String metric, String day) async {
    if (!authProvider.isAuthenticated) return [];

    final url = Uri.parse(
        '$_baseUrl/data/v1/$metric/patients/$_patientUsername/day/$day/');
    final response = await _makeAuthenticatedGetRequest(url);

    if (response != null && response.statusCode == 200) {
      try {
        final jsonResponse = jsonDecode(response.body);

        if (metric == 'sleep') {
          final dynamic sleepObj = jsonResponse['data']['data'];
          if (sleepObj == null) return [];
          final double minutes =
              double.tryParse(sleepObj['minutesAsleep'].toString()) ?? 0;
          return [
            MetricPoint(
              shortLabel: day.substring(5),
              fullLabel:  day,
              value: double.parse((minutes / 60.0).toStringAsFixed(1)),
            )
          ];
        }

        final List<dynamic> raw = jsonResponse['data']['data'];
        final filtered = raw
            .where((e) => (double.tryParse(e['value'].toString()) ?? 0) > 0)
            .toList();

        const int maxPoints = 80;
        final List<dynamic> sampled = filtered.length > maxPoints
            ? [
                for (int i = 0;
                    i < filtered.length;
                    i += (filtered.length / maxPoints).ceil())
                  filtered[i]
              ]
            : filtered;

        return sampled
            .map((e) => MetricPoint(
                  shortLabel: e['time'].toString().substring(0, 5),
                  fullLabel:  '$day ${e['time']}',
                  value: double.tryParse(e['value'].toString()) ?? 0,
                ))
            .toList();
      } catch (e, stack) {
        print('fetchSingleDayMetric [$metric] ERROR: $e');
        print(stack);
        return [];
      }
    }
    return [];
  }

  // ── fetchIntradayHrRange ──────────────────────────────────────────────────
  // Contains every HR with its timestamp (used in reports to get peak stress hours).

  Future<List<MetricPoint>> fetchIntradayHrRange(
      String startDate, String endDate) async {
    if (!authProvider.isAuthenticated) return [];

    final url = Uri.parse(
        '$_baseUrl/data/v1/heart_rate/patients/$_patientUsername/daterange/start_date/$startDate/end_date/$endDate/');
    final response = await _makeAuthenticatedGetRequest(url);

    if (response != null && response.statusCode == 200) {
      try {
        final jsonResponse = jsonDecode(response.body);
        final dynamic dataField = jsonResponse['data'];
        final List<MetricPoint> points = [];

        if (dataField is List) {
          for (final dayObj in dataField) {
            final String date = dayObj['date'].toString();
            final dynamic rawData = dayObj['data'];
            if (rawData is List) {
              for (final entry in rawData) {
                final String time = entry['time'].toString();
                final double value =
                    double.tryParse(entry['value'].toString()) ?? 0.0;
                if (value > 0) {
                  points.add(MetricPoint(
                    shortLabel: time.length >= 5 ? time.substring(0, 5) : time,
                    fullLabel:  '$date $time',
                    value: value,
                  ));
                }
              }
            }
          }
        }
        print('fetchIntradayHrRange: ${points.length} punti HR');
        return points;
      } catch (e) {
        print('fetchIntradayHrRange ERROR: $e');
        return [];
      }
    }
    return [];
  }

  // ── fetchExerciseZoneMinutesRange ─────────────────────────────────────────
  // Contains minutes per HR zone (outOfZone, fatBurn, cardio, peak), used to get daily TRIMP.

  Future<Map<String, Map<String, double>>> fetchExerciseZoneMinutesRange(
      String startDate, String endDate) async {
    if (!authProvider.isAuthenticated) return {};

    final url = Uri.parse(
        '$_baseUrl/data/v1/exercise/patients/$_patientUsername/daterange/start_date/$startDate/end_date/$endDate/');

    final response = await _makeAuthenticatedGetRequest(url);
    final Map<String, Map<String, double>> byDay = {};

    if (response == null || response.statusCode != 200) return byDay;

    try {
      final jsonResponse = jsonDecode(response.body);
      final dynamic dataField = jsonResponse['data'];

      if (dataField is List) {
        for (final dayObj in dataField) {
          final String date = dayObj['date'].toString();
          final dynamic sessionsRaw = dayObj['data'];
          if (sessionsRaw is! List) continue;


          final Map<String, double> zoneMinutes = {
            'outOfZone': 0.0,
            'fatBurn':   0.0,
            'cardio':    0.0,
            'peak':      0.0,
          };


          for (final session in sessionsRaw) {
            final dynamic zonesRaw = session['heartRateZones'];
            if (zonesRaw is! List) continue;
            for (final zone in zonesRaw) {
              final String name = zone['name']?.toString() ?? '';
              final String? key = _zoneNameToKey[name];
              if (key == null) continue;
              final double minutes =
                  double.tryParse(zone['minutes'].toString()) ?? 0.0;
              zoneMinutes[key] = (zoneMinutes[key] ?? 0.0) + minutes;
            }
          }


          if (zoneMinutes.values.any((v) => v > 0)) {
            byDay[date] = zoneMinutes;
          }
        }
      }

      print('fetchExerciseZoneMinutesRange: ${byDay.length} giorni con esercizio');
      return byDay;
    } catch (e, stack) {
      print('fetchExerciseZoneMinutesRange parse ERROR: $e');
      print(stack);
      return {};
    }
  }

  // ── fetchWeekBundle ───────────────────────────────────────────────────────
  // Puts weekly data in a bundle for the weekly report. 

  Future<WeekBundle> fetchWeekBundle(String startDate, String endDate) async {
    final sleepPoints = await fetchMetricRange('sleep', startDate, endDate);
    await Future.delayed(const Duration(milliseconds: 150));
    final stepsPoints = await fetchMetricRange('steps', startDate, endDate);
    await Future.delayed(const Duration(milliseconds: 150));
    final hrPoints    = await fetchMetricRange('heart_rate', startDate, endDate);
    await Future.delayed(const Duration(milliseconds: 150));
    final hrIntradayPoints = await fetchIntradayHrRange(startDate, endDate);
    await Future.delayed(const Duration(milliseconds: 150));
    final exerciseZoneMinutes =
        await fetchExerciseZoneMinutesRange(startDate, endDate);

    return WeekBundle(
      sleep:                   sleepPoints,
      steps:                   stepsPoints,
      hr:                      hrPoints,
      hrIntraday:              hrIntradayPoints,
      exerciseZoneMinutesByDate: exerciseZoneMinutes,
    );
  }

  // ── fetchCalculatedStressRange ────────────────────────────────────────────
  // Retrieves stress for a range of days

  Future<List<MetricPoint>> fetchCalculatedStressRange(
      String startDate, String endDate) async {
    final results = await Future.wait([
      fetchMetricRange('sleep',      startDate, endDate),
      fetchMetricRange('heart_rate', startDate, endDate),
      fetchMetricRange('steps',      startDate, endDate),
    ]);

    final List<MetricPoint> sleepData = results[0];
    final List<MetricPoint> hrData    = results[1];
    final List<MetricPoint> stepsData = results[2];
    final Map<String, Map<String, double>> exerciseZoneMinutes =
        await fetchExerciseZoneMinutesRange(startDate, endDate);

    final Map<String, DailyRawData> dailyDataMap = {};

    void populateMap(
        List<MetricPoint> data, void Function(DailyRawData, double) assigner) {
      for (var point in data) {
        dailyDataMap.putIfAbsent(
          point.fullLabel,
          () => DailyRawData(shortLabel: point.shortLabel),
        );
        assigner(dailyDataMap[point.fullLabel]!, point.value);
      }
    }

    populateMap(sleepData, (d, v) => d.sleepHours = v);
    populateMap(hrData,    (d, v) => d.heartRate   = v);
    populateMap(stepsData, (d, v) => d.steps        = v);

    exerciseZoneMinutes.forEach((date, zoneMinutes) {
      dailyDataMap.putIfAbsent(
        date,
        () => DailyRawData(
            shortLabel: date.length >= 10 ? date.substring(5) : date),
      );
      dailyDataMap[date]!.heartRateZoneMinutes = zoneMinutes;
    });

    final List<MetricPoint> stressPoints = dailyDataMap.entries.map((entry) {
      return MetricPoint(
        shortLabel: entry.value.shortLabel,
        fullLabel:  entry.key,
        value: StressCalculator.calculateDailyStress(entry.value),
      );
    }).toList()
      ..sort((a, b) => a.fullLabel.compareTo(b.fullLabel));

    return stressPoints;
  }

  // ── fetchCalculatedStressSingleDay ────────────────────────────────────────
  // Retrieves stress for a day, used in home and analysis and trends

  Future<List<MetricPoint>> fetchCalculatedStressSingleDay(String day) async {
    final results = await Future.wait([
      fetchSingleDayMetric('sleep', day),
      fetchMetricRange('heart_rate', day, day),
      fetchMetricRange('steps',      day, day),
    ]);

    final Map<String, Map<String, double>> exerciseZoneMinutes =
        await fetchExerciseZoneMinutesRange(day, day);

    final raw = DailyRawData(shortLabel: day)
      ..sleepHours           = results[0].isNotEmpty ? results[0].first.value : 0.0
      ..heartRate            = results[1].isNotEmpty ? results[1].first.value : 0.0
      ..steps                = results[2].isNotEmpty ? results[2].first.value : 0.0
      ..heartRateZoneMinutes = exerciseZoneMinutes[day] ?? <String, double>{};

    return [
      MetricPoint(
        shortLabel: day,
        fullLabel:  day,
        value: StressCalculator.calculateDailyStress(raw),
      ),
    ];
  }

  // ── _makeAuthenticatedGetRequest ──────────────────────────────────────────
  // Implements GET method

  Future<http.Response?> _makeAuthenticatedGetRequest(Uri url) async {
    var response = await http.get(
      url,
      headers: {'Authorization': 'Bearer ${authProvider.accessToken}'},
    );

    if (response.statusCode == 401 || response.statusCode == 403) {
      final bool refreshed = await authProvider.refresh();
      if (refreshed) {
        response = await http.get(
          url,
          headers: {'Authorization': 'Bearer ${authProvider.accessToken}'},
        );
      }
    }
    return response;
  }
}

// ── WeekBundle ────────────────────────────────────────────────────────────────
// fetchWeekBundle output

class WeekBundle {
  final List<MetricPoint> sleep;
  final List<MetricPoint> steps;
  final List<MetricPoint> hr;
  final List<MetricPoint> hrIntraday;
  final Map<String, Map<String, double>> exerciseZoneMinutesByDate;

  const WeekBundle({
    required this.sleep,
    required this.steps,
    required this.hr,
    this.hrIntraday            = const [],
    this.exerciseZoneMinutesByDate = const {},
  });
}
