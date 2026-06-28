import 'dart:math' as math;
import '../providers/data_provider.dart';
import '../utils/weekly_report_model.dart';
import '../models/metric_point.dart';
import 'stress_calculator.dart';

abstract class WeeklyReportBuilder {
  static final DateTime kArchiveEnd = DateTime(2026, 6, 21);

  // ── ENTRY POINT ───────────────────────────────────────────────────────────

  static Future<WeeklyReport> build({
    required DataProvider dataProvider,
    required DateTime weekStart,
    required DateTime weekEnd,
    required int stepsGoalTarget,
    required double sleepGoalHours,
    required bool goalsEnabled,
  }) async {
    final String startStr = _fmt(weekStart);
    final String endStr   = _fmt(weekEnd);

    final DateTime prevStart = weekStart.subtract(const Duration(days: 7));
    final DateTime prevEnd   = weekEnd.subtract(const Duration(days: 7));

    // Fetch settimana corrente (sleep + steps + hr + exercise in un bundle)
    final bundle = await dataProvider.fetchWeekBundle(startStr, endStr);
    final sleepPoints              = bundle.sleep;
    final stepsPoints              = bundle.steps;
    final hrPoints                 = bundle.hr;
    final hrIntraday               = bundle.hrIntraday;
    final exerciseZoneMinutesByDate = bundle.exerciseZoneMinutesByDate;

    // Stress calcolato localmente (no fetch aggiuntive)
    final stressPoints = _computeStressPoints(
      sleepPoints,
      stepsPoints,
      hrPoints,
      exerciseZoneMinutesByDate,
      weekStart,
    );
    await Future.delayed(const Duration(milliseconds: 200));

    // Fetch settimana precedente — solo sleep e steps per i delta
    final prevSleep = await dataProvider.fetchMetricRange(
        'sleep', _fmt(prevStart), _fmt(prevEnd));
    await Future.delayed(const Duration(milliseconds: 150));
    final prevSteps = await dataProvider.fetchMetricRange(
        'steps', _fmt(prevStart), _fmt(prevEnd));
    await Future.delayed(const Duration(milliseconds: 150));
    final prevStress =
        _computeStressPoints(prevSleep, prevSteps, [], const {}, prevStart);

    final List<DailyStress> dailyStress = _buildDailyStress(
      weekStart: weekStart,
      stressPoints: stressPoints,
    );

    // Conta giorni senza dato sonno — settimana corrente
    final Set<String> sleepDates = sleepPoints.map((p) => p.fullLabel).toSet();
    int missingSleepDays = 0;
    for (int i = 0; i < 7; i++) {
      if (!sleepDates.contains(_fmt(weekStart.add(Duration(days: i))))) {
        missingSleepDays++;
      }
    }

    // Conta giorni senza dato sonno — settimana precedente
    final Set<String> prevSleepDates = prevSleep.map((p) => p.fullLabel).toSet();
    int missingSleepDaysPrev = 0;
    for (int i = 0; i < 7; i++) {
      if (!prevSleepDates.contains(_fmt(prevStart.add(Duration(days: i))))) {
        missingSleepDaysPrev++;
      }
    }

    // Aggregati
    final double avgStress     = _avg(stressPoints.map((p) => p.value).toList());
    final double avgSleep      = _avg(sleepPoints.map((p) => p.value).toList());
    final double avgSteps      = _avg(stepsPoints.map((p) => p.value).toList());
    final double prevAvgStress = _avg(prevStress.map((p) => p.value).toList());
    final double prevAvgSleep  = _avg(prevSleep.map((p) => p.value).toList());
    final double prevAvgSteps  = _avg(prevSteps.map((p) => p.value).toList());

    // Conteggio sessioni esercizio
    final int exerciseSessionsCount = exerciseZoneMinutesByDate.values
        .where((zones) => zones.values.any((v) => v > 0))
        .length;

    final String mostStressfulDay = dailyStress.isNotEmpty
        ? _dayName(dailyStress
            .reduce((a, b) => a.stressIndex > b.stressIndex ? a : b)
            .date)
        : 'N/A';

    final String peakTimeRange = hrIntraday.isNotEmpty ? _peakHrRange(hrIntraday) : 'N/A';
    final int peakDaysCount = hrIntraday.isNotEmpty ? _peakDays(hrIntraday) : 0;

    final double sleepCorr = _pearson(
      _alignByDate(sleepPoints, stressPoints, weekStart),
    );

    // Correlazione attività combinata (passi + TRIMP) ↔ stress
    final List<MetricPoint> activityPoints = [];
    for (int i = 0; i < 7; i++) {
      final String dateStr = _fmt(weekStart.add(Duration(days: i)));
      double steps = 0.0;
      for (final p in stepsPoints) {
        if (p.fullLabel == dateStr) { steps = p.value; break; }
      }
      double trimp = 0.0;
      if (exerciseZoneMinutesByDate.containsKey(dateStr)) {
        final zones = exerciseZoneMinutesByDate[dateStr]!;
        trimp += (zones['outOfZone'] ?? 0) * 1.0;
        trimp += (zones['fatBurn']   ?? 0) * 2.0;
        trimp += (zones['cardio']    ?? 0) * 3.0;
        trimp += (zones['peak']      ?? 0) * 4.0;
      }
      final double equivalentSteps = steps + (trimp * 160);
      if (equivalentSteps > 0) {
        activityPoints.add(MetricPoint(
          shortLabel: dateStr.substring(5),
          fullLabel:  dateStr,
          value:      equivalentSteps,
        ));
      }
    }
    final double stepsCorr = _pearson(
      _alignByDate(activityPoints, stressPoints, weekStart),
    );

    final int stepsGoalDays = goalsEnabled
        ? stepsPoints.where((p) => p.value >= stepsGoalTarget).length
        : 0;
    final int sleepGoalDays = goalsEnabled
        ? sleepPoints.where((p) => p.value >= sleepGoalHours).length
        : 0;

    final String dateRangeIt = _dateRangeIt(weekStart, weekEnd);
    final String dateRangeEn = _dateRangeEn(weekStart, weekEnd);

    final WeeklyReport draft = WeeklyReport(
      weekStart:              weekStart,
      weekEnd:                weekEnd,
      hasData:                dailyStress.isNotEmpty,
      evaluationIt:           '',
      evaluationEn:           '',
      dateRangeIt:            dateRangeIt,
      dateRangeEn:            dateRangeEn,
      goalsAchieved:          stepsGoalDays + sleepGoalDays,
      avgStressIndex:         avgStress,
      dailyStress:            dailyStress,
      mostStressfulDay:       mostStressfulDay,
      peakStressTimeRange:    peakTimeRange,
      peakStressDaysCount:    peakDaysCount,
      avgSleepHours:          avgSleep,
      prevAvgSleepHours:      prevAvgSleep,
      sleepStressCorrelation: sleepCorr,
      avgDailySteps:          avgSteps,
      prevAvgDailySteps:      prevAvgSteps,
      exerciseSessions:       exerciseSessionsCount,
      stepsStressCorrelation: stepsCorr,
      prevAvgStressIndex:     prevAvgStress,
      goalsEnabled:           goalsEnabled,
      stepsGoalDaysReached:   stepsGoalDays,
      sleepGoalDaysReached:   sleepGoalDays,
      stepsGoalTarget:        stepsGoalTarget,
      sleepGoalHours:         sleepGoalHours,
      missingSleepDays:       missingSleepDays,
      missingSleepDaysPrev:   missingSleepDaysPrev,
    );

    return WeeklyReport(
      weekStart:              weekStart,
      weekEnd:                weekEnd,
      hasData:                dailyStress.isNotEmpty,
      evaluationIt:           draft.performance.label(true),
      evaluationEn:           draft.performance.label(false),
      dateRangeIt:            dateRangeIt,
      dateRangeEn:            dateRangeEn,
      goalsAchieved:          stepsGoalDays + sleepGoalDays,
      avgStressIndex:         avgStress,
      dailyStress:            dailyStress,
      mostStressfulDay:       mostStressfulDay,
      peakStressTimeRange:    peakTimeRange,
      peakStressDaysCount:    peakDaysCount,
      avgSleepHours:          avgSleep,
      prevAvgSleepHours:      prevAvgSleep,
      sleepStressCorrelation: sleepCorr,
      avgDailySteps:          avgSteps,
      prevAvgDailySteps:      prevAvgSteps,
      exerciseSessions:       exerciseSessionsCount,
      stepsStressCorrelation: stepsCorr,
      prevAvgStressIndex:     prevAvgStress,
      goalsEnabled:           goalsEnabled,
      stepsGoalDaysReached:   stepsGoalDays,
      sleepGoalDaysReached:   sleepGoalDays,
      stepsGoalTarget:        stepsGoalTarget,
      sleepGoalHours:         sleepGoalHours,
      missingSleepDays:       missingSleepDays,
      missingSleepDaysPrev:   missingSleepDaysPrev,
    );
  }

  // ── RANGE ARCHIVIO ────────────────────────────────────────────────────────

  static List<({DateTime start, DateTime end})> buildWeekRanges({
    DateTime? archiveEnd,
    int weekCount = 8,
  }) {
    final DateTime end = archiveEnd ?? kArchiveEnd;
    final List<({DateTime start, DateTime end})> ranges = [];
    DateTime weekEnd = end;
    for (int i = 0; i < weekCount; i++) {
      final DateTime weekStart = weekEnd.subtract(const Duration(days: 6));
      ranges.add((start: weekStart, end: weekEnd));
      weekEnd = weekStart.subtract(const Duration(days: 1));
    }
    return ranges;
  }

  // ── STRESS LOCALE ─────────────────────────────────────────────────────────

  static List<MetricPoint> _computeStressPoints(
    List<MetricPoint> sleepPoints,
    List<MetricPoint> stepsPoints,
    List<MetricPoint> hrPoints,
    Map<String, Map<String, double>> exerciseZoneMinutesByDate,
    DateTime weekStart,
  ) {
    final Map<String, DailyRawData> rawMap = {};

    void populate(List<MetricPoint> points,
        void Function(DailyRawData, double) assign) {
      for (final p in points) {
        rawMap.putIfAbsent(
            p.fullLabel, () => DailyRawData(shortLabel: p.shortLabel));
        assign(rawMap[p.fullLabel]!, p.value);
      }
    }

    populate(sleepPoints, (d, v) => d.sleepHours = v);
    populate(stepsPoints, (d, v) => d.steps       = v);
    populate(hrPoints,    (d, v) => d.heartRate    = v);

    exerciseZoneMinutesByDate.forEach((date, zoneMinutes) {
      rawMap.putIfAbsent(
        date,
        () => DailyRawData(
            shortLabel: date.length >= 10 ? date.substring(5) : date),
      );
      rawMap[date]!.heartRateZoneMinutes = zoneMinutes;
    });

    return rawMap.entries
        .where((e) =>
            e.value.sleepHours > 0 ||
            e.value.heartRate > 0 ||
            e.value.steps > 0 ||
            e.value.heartRateZoneMinutes.values.any((v) => v > 0))
        .map((e) => MetricPoint(
              shortLabel: e.value.shortLabel,
              fullLabel:  e.key,
              value:      StressCalculator.calculateDailyStress(e.value),
            ))
        .toList()
      ..sort((a, b) => a.fullLabel.compareTo(b.fullLabel));
  }

  // ── DAILY STRESS ──────────────────────────────────────────────────────────

  static List<DailyStress> _buildDailyStress({
    required DateTime weekStart,
    required List<MetricPoint> stressPoints,
  }) {
    final Map<String, double> byDate = {
      for (final p in stressPoints) p.fullLabel: p.value,
    };
    final List<DailyStress> result = [];
    for (int i = 0; i < 7; i++) {
      final DateTime day = weekStart.add(Duration(days: i));
      final String key = _fmt(day);
      if (byDate.containsKey(key)) {
        result.add(DailyStress(date: day, stressIndex: byDate[key]!));
      }
    }
    return result;
  }

  // ── PEARSON ───────────────────────────────────────────────────────────────

  static List<(double x, double y)> _alignByDate(
    List<MetricPoint> xPoints,
    List<MetricPoint> yPoints,
    DateTime weekStart,
  ) {
    final Map<String, double> xMap = {
      for (final p in xPoints) p.fullLabel: p.value
    };
    final Map<String, double> yMap = {
      for (final p in yPoints) p.fullLabel: p.value
    };
    final List<(double, double)> pairs = [];
    for (int i = 0; i < 7; i++) {
      final String key = _fmt(weekStart.add(Duration(days: i)));
      if (xMap.containsKey(key) && yMap.containsKey(key)) {
        final double x = xMap[key]!;
        final double y = yMap[key]!;
        if (x > 0 && y > 0) pairs.add((x, y));
      }
    }
    return pairs;
  }

  static double _pearson(List<(double x, double y)> pairs) {
    if (pairs.length < 3) return 0.0;
    final double meanX =
        pairs.map((p) => p.$1).reduce((a, b) => a + b) / pairs.length;
    final double meanY =
        pairs.map((p) => p.$2).reduce((a, b) => a + b) / pairs.length;
    double num = 0, denomX = 0, denomY = 0;
    for (final p in pairs) {
      final double dx = p.$1 - meanX;
      final double dy = p.$2 - meanY;
      num    += dx * dy;
      denomX += dx * dx;
      denomY += dy * dy;
    }
    final double denom = math.sqrt(denomX) * math.sqrt(denomY);
    if (denom < 1e-9) return 0.0;
    return (-(num / denom) * 100).clamp(-100.0, 100.0).roundToDouble();
  }

  // ── PEAK HR TIME RANGE ────────────────────────────────────────────────────

  static String _peakHrRange(List<MetricPoint> hrPoints) {
    final Map<int, List<double>> byHour = {};
    for (final p in hrPoints) {
      final parts = p.shortLabel.split(':');
      if (parts.isEmpty) continue;
      final int? hour = int.tryParse(parts[0]);
      if (hour == null) continue;
      byHour.putIfAbsent(hour, () => []).add(p.value);
    }
    if (byHour.isEmpty) return 'N/A';

    final Map<int, double> hourlyAvg = {
      for (final e in byHour.entries)
        e.key: e.value.reduce((a, b) => a + b) / e.value.length,
    };

    double bestAvg = -1;
    int bestHour = 9;
    final List<int> hours = hourlyAvg.keys.toList()..sort();

    for (int i = 0; i < hours.length - 1; i++) {
      final int h1 = hours[i];
      final int h2 = hours[i + 1];
      if (h2 - h1 == 1) {
        final double windowAvg = (hourlyAvg[h1]! + hourlyAvg[h2]!) / 2;
        if (windowAvg > bestAvg) {
          bestAvg  = windowAvg;
          bestHour = h1;
        }
      }
    }

    final String h1 = bestHour.toString().padLeft(2, '0');
    final String h2 = (bestHour + 2).toString().padLeft(2, '0');
    return '$h1:00 – $h2:00';
  }

  static int _peakDays(List<MetricPoint> hrPoints) {
    final Map<String, Map<int, List<double>>> byDateHour = {};
    for (final p in hrPoints) {
      final String label    = p.fullLabel;
      final String datePart = label.length >= 10 ? label.substring(0, 10) : label;
      final parts           = p.shortLabel.split(':');
      if (parts.isEmpty) continue;
      final int? hour = int.tryParse(parts[0]);
      if (hour == null) continue;
      byDateHour.putIfAbsent(datePart, () => {});
      byDateHour[datePart]!.putIfAbsent(hour, () => []).add(p.value);
    }

    int count = 0;
    for (final entry in byDateHour.entries) {
      final DateTime? date = DateTime.tryParse(entry.key);
      if (date == null || date.weekday > 5) continue;
      final Map<int, double> hourlyAvg = {
        for (final e in entry.value.entries)
          e.key: e.value.reduce((a, b) => a + b) / e.value.length,
      };
      if (hourlyAvg.isEmpty) continue;
      final int peakHour = hourlyAvg.entries
          .reduce((a, b) => a.value > b.value ? a : b)
          .key;
      if (peakHour >= 8 && peakHour <= 19) count++;
    }
    return count.clamp(0, 5);
  }

  // ── DATE UTILITIES ────────────────────────────────────────────────────────

  static double _avg(List<double> values) {
    final nonZero = values.where((v) => v > 0).toList();
    if (nonZero.isEmpty) return 0.0;
    return nonZero.reduce((a, b) => a + b) / nonZero.length;
  }

  static String _fmt(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  static String _dayName(DateTime d) {
    const days = [
      'Monday', 'Tuesday', 'Wednesday',
      'Thursday', 'Friday', 'Saturday', 'Sunday'
    ];
    return days[d.weekday - 1];
  }

  static String _dateRangeIt(DateTime s, DateTime e) {
    const m = ['', 'Gen', 'Feb', 'Mar', 'Apr', 'Mag', 'Giu',
                'Lug', 'Ago', 'Set', 'Ott', 'Nov', 'Dic'];
    return '${s.day} ${m[s.month]} – ${e.day} ${m[e.month]} ${e.year}';
  }

  static String _dateRangeEn(DateTime s, DateTime e) {
    const m = ['', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${m[s.month]} ${s.day.toString().padLeft(2, '0')} – '
           '${m[e.month]} ${e.day.toString().padLeft(2, '0')} ${e.year}';
  }
}