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

  // ╔══════════════════════════════════════════════════════════════════════╗
  // ║  CACHE CONDIVISA DEI WEEKLY REPORT                                   ║
  // ╠══════════════════════════════════════════════════════════════════════╣
  // ║  PERCHÉ: prima, Profile, HomeScreen e ReportArchivioScreen ognuno    ║
  // ║  calcolava "l'ultima settimana" per conto proprio, con le sue        ║
  // ║  chiamate di rete indipendenti, in momenti diversi. Risultato:       ║
  // ║  - la stessa identica settimana veniva scaricata e calcolata fino   ║
  // ║    a 2 volte (una da Profile, una come prima riga dell'Archivio)    ║
  // ║  - lastWeeklyReport non veniva mai scritto da nessuna parte, quindi ║
  // ║    la Home mostrava sempre il placeholder "non disponibile"         ║
  // ║  - se una qualsiasi delle ~9 richieste di rete di QUEL calcolo      ║
  // ║    falliva (es. per via di un refresh-token in corsa, vedi          ║
  // ║    AuthProvider), SOLO quella schermata risultava con dati          ║
  // ║    mancanti o "no data", mentre le altre — che avevano fatto le     ║
  // ║    loro chiamate in un momento diverso — magari andavano bene.      ║
  // ║    Questo è ciò che sembrava "aleatorio".                           ║
  // ║                                                                      ║
  // ║  FIX: un'unica cache in memoria, dietro a getter/metodi che fanno   ║
  // ║  fetch solo se serve davvero, e notifyListeners() quando i dati     ║
  // ║  cambiano, così tutte le schermate restano sincronizzate.           ║
  // ╚══════════════════════════════════════════════════════════════════════╝

  WeeklyReport? _lastWeeklyReport;
  List<WeeklyReport>? _cachedArchive;

  // Evita fetch duplicate in parallelo se due schermate richiedono
  // lo stesso report nello stesso istante (es. Home e Profilo aperte
  // a cascata mentre il primo fetch è ancora in corso).
  Future<WeeklyReport>? _lastReportInFlight;
  Future<List<WeeklyReport>>? _archiveInFlight;

  WeeklyReport? get lastWeeklyReport => _lastWeeklyReport;
  List<WeeklyReport>? get cachedArchive => _cachedArchive;

  /// Invalida tutta la cache dei report (sia "ultimo" che archivio).
  /// Da chiamare quando cambiano i goal nelle impostazioni, perché i report
  /// dipendono da stepsGoalTarget/sleepGoalHours/goalsEnabled.
  void clearArchiveCache() {
    _cachedArchive = null;
    _lastWeeklyReport = null;
    notifyListeners();
  }

  /// Restituisce l'ultimo report settimanale, calcolandolo solo se non è
  /// già in cache (o se [forceRefresh] è true). Lo scrive anche come prima
  /// riga della cache archivio, così le due fonti restano coerenti.
  ///
  /// Usato da HomeScreen e Profile — prima ognuno calcolava il proprio,
  /// ora condividono lo stesso risultato e lo stesso eventuale errore.
  Future<WeeklyReport> getOrFetchLatestReport({
    required int stepsGoalTarget,
    required double sleepGoalHours,
    required bool goalsEnabled,
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh && _lastWeeklyReport != null) {
      return _lastWeeklyReport!;
    }

    // Se è già in corso un fetch (lanciato da un'altra schermata aperta
    // pochi istanti prima), aspettiamo quello invece di duplicarlo.
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

      // Teniamo sincronizzata anche la prima riga dell'archivio, se già
      // presente in cache, così Archivio e Home/Profilo non divergono.
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

  /// Restituisce l'archivio completo (8 settimane), riusando la cache se
  /// già presente. Popola via via la lista e notifica ad ogni settimana
  /// pronta tramite [onProgress], così la UI può mostrare le card una alla
  /// volta come faceva prima, ma con UNA sola fonte di dati condivisa.
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
    // Riprendiamo da dove eravamo arrivati se c'è già una cache parziale.
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

      // La prima riga (settimana corrente) coincide con "l'ultimo report":
      // se è già in cache lì, evitiamo di ricalcolarla una seconda volta.
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
      // Una riga è "ancora da caricare" se è un placeholder vuoto
      // (creato da WeeklyReport.empty con dateRangeIt vuoto).
      if (!r.hasData && r.dateRangeIt.isEmpty) return i;
    }
    return reports.length;
  }

  // Mappa i nomi delle zone HR (italiano/inglese) alla chiave interna.
  // Il Fitbit usa nomi italiani o inglesi a seconda della lingua del dispositivo.
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

  // ── fetchDailyData ────────────────────────────────────────────────────────
  // Aggiorna i totali giornalieri esposti direttamente dal provider
  // (totalSteps, totalCalories, totalDistance). Usato da schermate che
  // leggono questi valori via context.watch<DataProvider>().

  Future<void> fetchDailyData(String day) async {
    if (!authProvider.isAuthenticated) return;
    isLoading = true;
    notifyListeners();
    await _fetchMetric(_patientUsername, day, 'steps',    (v) => totalSteps = v.toInt());
    await _fetchMetric(_patientUsername, day, 'calories', (v) => totalCalories = v);
    await _fetchMetric(_patientUsername, day, 'distance', (v) => totalDistance = v);
    isLoading = false;
    notifyListeners();
  }

  // Metriche che si aggregano per somma (non media) nel range giornaliero
  static const _sumMetrics = {'steps', 'calories', 'distance', 'exercise'};

  // ── fetchMetricRange ──────────────────────────────────────────────────────
  // Chiama l'endpoint /daterange/start_date/.../end_date/ e restituisce
  // un MetricPoint per ogni giorno del range (già aggregato: somma o media).
  //
  // NON usare per un singolo giorno (start == end): l'endpoint /daterange/
  // restituisce lista vuota in quel caso. Usa fetchSingleDayMetric invece.

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
                // ── FIX SONNO ──────────────────────────────────────────────
                // Usavamo timeInBed = tempo totale nel letto (sonno + momenti
                // svegli) 
                // Ora usiamo minutesAsleep = sonno reale registrato dal Fitbit,
                // che esclude i minuti di veglia durante la notte.
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
  // Chiama l'endpoint /day/<data>/ e restituisce i punti intraday grezzi
  // (un punto ogni minuto per steps/calories/distance, ogni 5s per HR).
  //
  // Endpoint corretto per un singolo giorno (es. home screen).
  // I valori NON sono già aggregati: sommare per ottenere il totale
  // giornaliero di steps/calories/distance (vedi home_screen.dart).

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
          // ── FIX SONNO ────────────────────────────────────────────────────
          // Stessa correzione applicata in fetchMetricRange:
          // minutesAsleep = sonno reale, esclude i minuti svegli nel letto.
          // timeInBed (vecchio campo) includeva anche i minuti di veglia
          // notturna.
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

        // Limitiamo i punti a 80 massimo per non sovraccaricare i grafici
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
  // Restituisce i punti HR con timestamp orario completo (data + ora).
  // Usato dal WeeklyReportBuilder per calcolare la fascia oraria di picco
  // dello stress durante la settimana.

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
                    // shortLabel = solo l'ora (HH:MM) per il calcolo del picco
                    shortLabel: time.length >= 5 ? time.substring(0, 5) : time,
                    // fullLabel  = data + ora completa per identificare il giorno
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
  // Restituisce i minuti per zona HR (outOfZone, fatBurn, cardio, peak)
  // per ogni giorno del range. Usato per calcolare il TRIMP giornaliero
  // nello StressCalculator.

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

          // Inizializziamo tutte le zone a 0 per il giorno corrente
          final Map<String, double> zoneMinutes = {
            'outOfZone': 0.0,
            'fatBurn':   0.0,
            'cardio':    0.0,
            'peak':      0.0,
          };

          // Sommiamo i minuti di tutte le sessioni di allenamento del giorno
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

          // Includiamo il giorno solo se c'è stato almeno un minuto di esercizio
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
  // Aggrega tutte le metriche necessarie per un report settimanale in un
  // unico bundle. Riduce il numero di chiamate esterne rispetto a fetch
  // separate, e centralizza la logica di recupero dati settimanali.
  // Usato esclusivamente dal WeeklyReportBuilder.

  Future<WeekBundle> fetchWeekBundle(String startDate, String endDate) async {
    // Piccoli delay tra le chiamate per non sovraccaricare il server
    final sleepPoints = await fetchMetricRange('sleep', startDate, endDate);
    await Future.delayed(const Duration(milliseconds: 150));
    final stepsPoints = await fetchMetricRange('steps', startDate, endDate);
    await Future.delayed(const Duration(milliseconds: 150));
    final hrPoints    = await fetchMetricRange('heart_rate', startDate, endDate);
    await Future.delayed(const Duration(milliseconds: 150));
    // HR intraday: timestamp orario completo per il calcolo del picco di stress
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
  // Calcola lo stress per un range di giorni combinando sleep + HR + steps
  // + zone esercizio. Usato dalla schermata Analysis & Trends (grafico
  // settimanale/mensile dello stress).

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

    // Costruiamo una mappa date → DailyRawData popolando i dati disponibili
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

    // Calcoliamo lo stress per ogni giorno e ordiniamo per data
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
  // Calcola lo stress per un singolo giorno. Usato dalla home screen e dalla
  // schermata Analysis & Trends in modalità "Day".

  Future<List<MetricPoint>> fetchCalculatedStressSingleDay(String day) async {
    final results = await Future.wait([
      fetchSingleDayMetric('sleep', day),
      // Per HR e steps usiamo fetchMetricRange anche qui: l'endpoint /daterange/
      // con start==end non funziona per step/calories/distance (vedi home),
      // ma per heart_rate e steps usati nello stress funziona perché il
      // WeeklyReportBuilder li usa già in questo modo e i dati arrivano.
      fetchMetricRange('heart_rate', day, day),
      fetchMetricRange('steps',      day, day),
    ]);

    final Map<String, Map<String, double>> exerciseZoneMinutes =
        await fetchExerciseZoneMinutesRange(day, day);

    // Assembliamo il DailyRawData per il giorno richiesto:
    // - sleep: .first.value perché fetchSingleDayMetric restituisce già il totale
    // - HR:    .first.value perché fetchMetricRange restituisce la media giornaliera
    // - steps: .first.value perché fetchMetricRange restituisce il totale giornaliero
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

  // ── _fetchMetric ──────────────────────────────────────────────────────────
  // Helper interno usato da fetchDailyData per aggiornare i totali esposti
  // direttamente dal provider (totalSteps, totalCalories, totalDistance).

  Future<void> _fetchMetric(String patientUsername, String day, String metric,
      Function(double) onDataParsed) async {
    final url = Uri.parse(
        '$_baseUrl/data/v1/$metric/patients/$patientUsername/day/$day/');
    final response = await _makeAuthenticatedGetRequest(url);
    if (response != null && response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body);
      final List<dynamic> dataList = jsonResponse['data']['data'];
      double sum = 0.0;
      for (var entry in dataList) {
        sum += double.parse(entry['value'].toString());
      }
      onDataParsed(sum);
    }
  }

  // ── _makeAuthenticatedGetRequest ──────────────────────────────────────────
  // Esegue una GET con il token Bearer. Se la risposta è 401/403 (token
  // scaduto) prova il refresh automatico e ripete la chiamata una sola volta.
  //
  // NOTA: authProvider.refresh() ora è internamente protetto da un lock
  // (vedi AuthProvider), quindi anche se questo metodo viene chiamato da
  // più richieste in parallelo, solo UN refresh HTTP viene davvero eseguito:
  // le altre chiamate aspettano il risultato di quello in corso invece di
  // innescarne uno proprio con un refresh-token già "consumato".

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
// Contenitore dei dati aggregati per una settimana, restituito da fetchWeekBundle.
// Raggruppa tutte le metriche in un'unica struttura per evitare di passare
// liste separate tra WeeklyReportBuilder e DataProvider.

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