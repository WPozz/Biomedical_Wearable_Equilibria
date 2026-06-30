import 'package:flutter/material.dart';
import 'dart:async';
import 'package:provider/provider.dart';
import 'package:flutter_application/providers/settings_provider.dart';
import 'package:flutter_application/providers/data_provider.dart';
import 'package:flutter_application/models/metric_point.dart';
import 'package:flutter_application/utils/weekly_report_model.dart';
import 'package:flutter_application/services/weekly_report_builder.dart';
import 'package:flutter_application/screens/pausa_attiva.dart';
import 'package:flutter_application/screens/report_dettaglio.dart';

class HomeScreen extends StatefulWidget {
  // Callback invocato quando il caricamento dei dati giornalieri (sleep,
  // steps, calorie, distanza, stress di oggi) è terminato — con successo
  // o errore. Usato da MainWrapper per far partire il prefetch
  // dell'archivio SOLO dopo che la Home ha finito le sue richieste,
  // evitando di sommare carico di rete proprio nella finestra più
  // delicata appena dopo il login (vedi nota in main_wrapper.dart).
  final VoidCallback? onDailyDataLoaded;

  const HomeScreen({super.key, this.onDailyDataLoaded});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {

  double _radiusMultiplier = 1.0;
  late Timer _timer;

  // ── Stato dei dati giornalieri ────────────────────────────────────────────
  bool _isLoadingDaily = true;
  String? _dailyErrorMessage;
  int _stressLevel = 0;
  double _sleepHours = 0;
  double _steps = 0;
  double _calories = 0;
  double _distanceKm = 0;

  // ── Stato del report settimanale (card "ultimo report") ───────────────────
  // PERCHÉ: prima la Home leggeva solo passivamente
  // context.watch<DataProvider>().lastWeeklyReport, che però non veniva
  // MAI scritto da nessuna parte se non si era prima passati dal Profilo.
  // Ora la Home stessa richiede il report alla cache condivisa: se è già
  // presente (perché un'altra schermata l'ha già calcolato) lo riceve subito
  // senza nuove chiamate di rete; altrimenti lo calcola una volta e lo
  // condivide con tutte le altre schermate.
  bool _isLoadingReport = true;

  late final DateTime _syncedDay;
  late final String _syncedDayStr;

  @override
  void initState() {
    super.initState();

    // Timer per l'animazione "blob" dello stress (pulsa ogni 2 secondi)
    _timer = Timer.periodic(const Duration(seconds: 2), (timer) {
      if (mounted) {
        setState(() {
          _radiusMultiplier = _radiusMultiplier == 1.0 ? 1.1 : 1.0;
        });
      }
    });

    // kArchiveEnd è il 21 giugno 2026 (ultimo giorno dell'archivio Fitbit).
    // Mostriamo il 22 giugno perché:
    // - i dati di attività (steps, calories, distance) sono stati registrati il 22
    // - il sonno del 22 è la notte tra il 21 e il 22, che il Fitbit associa
    //   alla data di sveglia (22 giugno) → esiste nell'API
    _syncedDay    = WeeklyReportBuilder.kArchiveEnd.add(const Duration(days: 1));
    _syncedDayStr = _fmtDate(_syncedDay);

    // Carichiamo i dati solo dopo che il primo frame è stato renderizzato,
    // così il context è già disponibile per leggere il DataProvider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadDailyData();
      _loadWeeklyReport();
    });
  }

  @override
  void dispose() {
    _timer.cancel(); // fondamentale: fermiamo il timer quando lo schermo viene distrutto
    super.dispose();
  }

  // Formatta una DateTime in stringa "YYYY-MM-DD" per le chiamate API
  String _fmtDate(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  Future<void> _loadWeeklyReport({bool forceRefresh = false}) async {
    if (!mounted) return;
    setState(() => _isLoadingReport = true);

    final dataProvider = context.read<DataProvider>();
    final settings     = context.read<SettingsProvider>();

    try {
      await dataProvider.getOrFetchLatestReport(
        stepsGoalTarget: settings.steps,
        sleepGoalHours:  settings.sleepHours.toDouble(),
        goalsEnabled:    settings.customGoalsEnabled,
        forceRefresh:    forceRefresh,
      );
    } catch (e) {
      print('HOME DEBUG ERROR durante _loadWeeklyReport: $e');
    } finally {
      if (mounted) setState(() => _isLoadingReport = false);
    }
  }

  Future<void> _loadDailyData() async {
    final dataProvider = context.read<DataProvider>();

    print('=== HOME: caricamento dati per il giorno $_syncedDayStr ===');

    setState(() {
      _isLoadingDaily    = true;
      _dailyErrorMessage = null;
    });

    try {
      // ── PERCHÉ fetchSingleDayMetric e non fetchMetricRange? ───────────────
      //
      // fetchMetricRange chiama /daterange/start_date/.../end_date/
      // → funziona bene per range di 7+ giorni (grafici settimanali)
      // → restituisce lista VUOTA quando start == end (un solo giorno)
      //
      // fetchSingleDayMetric chiama /day/<data>/
      // → corretto per un singolo giorno, restituisce punti intraday
      // → è l'endpoint giusto per la home che mostra sempre "oggi"
      //
      // Lanciamo tutte le fetch in parallelo con Future.wait per
      // minimizzare il tempo di attesa totale.
      final results = await Future.wait([
        dataProvider.fetchSingleDayMetric('sleep',    _syncedDayStr),
        dataProvider.fetchSingleDayMetric('steps',    _syncedDayStr),
        dataProvider.fetchSingleDayMetric('calories', _syncedDayStr),
        dataProvider.fetchSingleDayMetric('distance', _syncedDayStr),
        dataProvider.fetchCalculatedStressSingleDay(_syncedDayStr),
        // Lo stress non ha un endpoint diretto: viene calcolato localmente
        // da StressCalculator usando sleep + HR + steps + zone esercizio
      ]);

      if (!mounted) return;

      final List<MetricPoint> sleepPoints    = results[0];
      final List<MetricPoint> stepsPoints    = results[1];
      final List<MetricPoint> caloriesPoints = results[2];
      final List<MetricPoint> distancePoints = results[3];
      final List<MetricPoint> stressPoints   = results[4];

      // DEBUG: stampiamo i dati grezzi per verificare cosa arriva dall'API
      print('HOME DEBUG sleep    -> ${sleepPoints.length} punti: '
          '${sleepPoints.map((p) => "${p.fullLabel}=${p.value}").toList()}');
      print('HOME DEBUG steps    -> ${stepsPoints.length} punti: '
          '${stepsPoints.map((p) => "${p.fullLabel}=${p.value}").toList()}');
      print('HOME DEBUG calories -> ${caloriesPoints.length} punti: '
          '${caloriesPoints.map((p) => "${p.fullLabel}=${p.value}").toList()}');
      print('HOME DEBUG distance -> ${distancePoints.length} punti: '
          '${distancePoints.map((p) => "${p.fullLabel}=${p.value}").toList()}');
      print('HOME DEBUG stress   -> ${stressPoints.length} punti: '
          '${stressPoints.map((p) => "${p.fullLabel}=${p.value}").toList()}');

      // ── PERCHÉ sommiamo i valori? ─────────────────────────────────────────
      //
      // fetchSingleDayMetric restituisce i punti intraday grezzi:
      // - steps:    ogni punto = passi fatti in quell'intervallo di tempo
      // - calories: ogni punto = calorie bruciate in quell'intervallo
      // - distance: ogni punto = distanza percorsa in quell'intervallo (in cm)
      //
      // Per ottenere il totale giornaliero dobbiamo sommare tutti i punti.
      // (fetchMetricRange lo faceva già internamente prima di restituire
      // un singolo MetricPoint aggregato — qui lo facciamo noi.)
      //
      // Il sonno è diverso: fetchSingleDayMetric per 'sleep' restituisce
      // già un singolo punto con le ore totali → prendiamo solo .first.value
      double sumValues(List<MetricPoint> points) => points.isEmpty
          ? 0.0
          : points.map((p) => p.value).reduce((a, b) => a + b);

      setState(() {
        _sleepHours  = sleepPoints.isNotEmpty ? sleepPoints.first.value : 0;
        _steps       = sumValues(stepsPoints);
        _calories    = sumValues(caloriesPoints);

        // La distance arriva in cm dall'API (vedi Appendix slide 48).
        // Dividiamo per 100.000 per convertire in km.
        // Esempio: 850.000 cm → 8.5 km
        _distanceKm  = distancePoints.isNotEmpty
            ? sumValues(distancePoints) / 100000.0
            : 0;

        // Lo stress è già un valore 0-100 calcolato da StressCalculator
        _stressLevel = stressPoints.isNotEmpty
            ? stressPoints.first.value.round()
            : 0;

        _isLoadingDaily = false;

        // Mostriamo il banner "nessun dato" solo se TUTTE le metriche
        // sono vuote (es. giorno in cui l'orologio non era indossato)
        final bool noDataAtAll = sleepPoints.isEmpty &&
            stepsPoints.isEmpty &&
            caloriesPoints.isEmpty &&
            distancePoints.isEmpty;
        if (noDataAtAll) _dailyErrorMessage = 'no_data';
      });

      // Segnaliamo a MainWrapper che la Home ha finito: solo ora può
      // partire in sicurezza l'eventuale prefetch dell'archivio, senza
      // sommarsi alle richieste appena concluse.
      widget.onDailyDataLoaded?.call();

    } catch (e, stack) {
      print('HOME DEBUG ERROR durante _loadDailyData: $e');
      print(stack);
      if (!mounted) return;
      setState(() {
        _isLoadingDaily    = false;
        _dailyErrorMessage = 'error';
      });
      // Anche in caso di errore notifichiamo il completamento: il prefetch
      // non deve restare bloccato per sempre se la Home fallisce, e le
      // chiamate getOrFetch* hanno comunque la loro gestione d'errore.
      widget.onDailyDataLoaded?.call();
    }
  }

  // Restituisce il colore del blob/testo in base al livello di stress.
  // forText: true  → colore per testo (più scuro in light, più chiaro in dark)
  // forText: false → colore per il blob di sfondo (semi-trasparente)
  Color _getStressColor(int level, {bool forText = false}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (level < 30) {
      if (forText) return isDark ? const Color(0xFF6EE7A0) : const Color(0xFF166534);
      return isDark ? const Color(0xFF1A4D2E) : const Color(0xFF5DF091);
    }
    if (level < 60) {
      if (forText) return isDark ? const Color(0xFFFDE68A) : const Color(0xFF92400E);
      return isDark ? const Color(0xFF4D3A00) : const Color(0xFFEDDC5C);
    }
    if (level < 80) {
      if (forText) return isDark ? const Color(0xFFFBBF24) : const Color(0xFF9A3412);
      return isDark ? const Color(0xFF4D2A00) : const Color(0xFFF5AA49);
    }
    if (forText) return isDark ? const Color(0xFFF87171) : const Color(0xFF991B1B);
    return isDark ? const Color(0xFF4D1515) : const Color(0xFFDF6868);
  }

  // Etichetta testuale del livello di stress (bilingue)
  String _getStressLabel(int level, bool isItalian) {
    if (level < 30) return isItalian ? "Rilassato" : "Relaxed";
    if (level < 60) return isItalian ? "Livello di stress moderato" : "Moderate stress level";
    if (level < 80) return isItalian ? "Livello di stress alto" : "High stress level";
    return isItalian ? "Livello di stress molto alto" : "Very high stress level";
  }

  // Colore del badge "performance" nell'ultimo report settimanale
  Color _perfColor(WeekPerformance perf, ColorScheme scheme) {
    switch (perf) {
      case WeekPerformance.excellent: return scheme.primary;
      case WeekPerformance.good:      return const Color(0xFFF59E0B);
      case WeekPerformance.fair:      return const Color(0xFFF97316);
      case WeekPerformance.poor:      return scheme.error;
    }
  }

  // Formatta le ore di sonno in "Xh Ym"
  // Esempio: 7.75 → "7h 45m"
  String _fmtSleep(double hours) {
    final h = hours.floor();
    final m = ((hours - h) * 60).round();
    return '${h}h ${m}m';
  }

  // Formatta i passi con separatore delle migliaia (punto, stile italiano)
  // Esempio: 6430 → "6.430"
  String _fmtSteps(double steps) {
    final intSteps = steps.round();
    final str = intSteps.toString();
    final buffer = StringBuffer();
    for (int i = 0; i < str.length; i++) {
      if (i > 0 && (str.length - i) % 3 == 0) buffer.write('.');
      buffer.write(str[i]);
    }
    return buffer.toString();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isItalian   = context.watch<SettingsProvider>().isItalian;

    return Scaffold(
      appBar: AppBar(
        title: Container(
          color: Colors.transparent,
          child: Image.asset(
            'assets/images/Kairos_up.jpeg',
            height: 150,
            fit: BoxFit.contain,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        // Disabilitiamo il tint/ombra che Material 3 applica di default
        // quando il contenuto scrolla sotto l'AppBar
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
      ),
      body: SafeArea(
        child: RefreshIndicator(
          // Pull-to-refresh: ricarica i dati del giorno corrente E il report
          onRefresh: () => Future.wait([
            _loadDailyData(),
            _loadWeeklyReport(forceRefresh: true),
          ]),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ── Blob animato con indice di stress ─────────────────────
                  Column(
                    children: [
                      const SizedBox(height: 20),
                      // AnimatedContainer pulsa leggermente cambiando il border
                      // radius ogni 2 secondi grazie al Timer in initState
                      AnimatedContainer(
                        duration: const Duration(seconds: 2),
                        curve: Curves.easeInOut,
                        width: 180 * _radiusMultiplier,
                        height: 180,
                        decoration: BoxDecoration(
                          color: _getStressColor(_stressLevel).withValues(
                            alpha: Theme.of(context).brightness == Brightness.dark
                                ? 0.75
                                : 0.4,
                          ),
                          borderRadius: BorderRadius.only(
                            topLeft:     Radius.circular(80 * _radiusMultiplier),
                            topRight:    Radius.circular(100 / _radiusMultiplier),
                            bottomLeft:  Radius.circular(90 / _radiusMultiplier),
                            bottomRight: Radius.circular(70 * _radiusMultiplier),
                          ),
                        ),
                        child: Center(
                          child: Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Theme.of(context).brightness == Brightness.dark
                                  ? Colors.black.withValues(alpha: 0.15)
                                  : Colors.white.withValues(alpha: 0.5),
                            ),
                            child: Center(
                              // Mentre carichiamo mostriamo uno spinner,
                              // poi il numero 0-100 dell'indice di stress
                              child: _isLoadingDaily
                                  ? SizedBox(
                                      width: 28,
                                      height: 28,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 3,
                                        color: _getStressColor(
                                            _stressLevel, forText: true),
                                      ),
                                    )
                                  : Text(
                                      "$_stressLevel",
                                      style: TextStyle(
                                        fontSize: 32,
                                        fontWeight: FontWeight.bold,
                                        color: _getStressColor(
                                            _stressLevel, forText: true),
                                      ),
                                    ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      // Etichetta testuale del livello di stress
                      Text(
                        _isLoadingDaily
                            ? (isItalian ? 'Sincronizzazione…' : 'Syncing…')
                            : _getStressLabel(_stressLevel, isItalian),
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: _getStressColor(_stressLevel, forText: true),
                        ),
                      ),
                      // Banner di errore: mostrato solo in casi estremi
                      if (_dailyErrorMessage == 'no_data') ...[
                        const SizedBox(height: 6),
                        Text(
                          isItalian
                              ? 'Nessun dato disponibile per questo giorno'
                              : 'No data available for this day',
                          style: TextStyle(fontSize: 13, color: colorScheme.error),
                        ),
                      ] else if (_dailyErrorMessage == 'error') ...[
                        const SizedBox(height: 6),
                        Text(
                          isItalian
                              ? 'Errore di sincronizzazione, riprova'
                              : 'Sync error, please retry',
                          style: TextStyle(fontSize: 13, color: colorScheme.error),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 40),

                  // ── Bottone Pausa Attiva ───────────────────────────────────
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const PausaAttivaScreen()),
                      );
                    },
                    icon: const Icon(Icons.emoji_people, size: 40),
                    label: Text(
                      isItalian ? "Pausa attiva" : "Active break",
                      style: const TextStyle(
                          fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 110),
                      backgroundColor: colorScheme.primaryContainer,
                      foregroundColor: colorScheme.onPrimaryContainer,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25)),
                      elevation: 0,
                    ),
                  ),
                  const SizedBox(height: 40),

                  // ── Griglia metriche ──────────────────────────────────────
                  Text(
                    isItalian ? "Attività" : "Activity",
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  _buildMetricGrid(context, isItalian),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMetricGrid(BuildContext context, bool isItalian) {
    final colorScheme = Theme.of(context).colorScheme;

    // Progress circolari: sleep su 8h obiettivo, steps su 10.000 obiettivo
    final double sleepProgress = (_sleepHours / 8.0).clamp(0.0, 1.0);
    final double stepsProgress = (_steps / 10000.0).clamp(0.0, 1.0);

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                context,
                isItalian ? "Durata sonno" : "Sleep Duration",
                _isLoadingDaily ? '—' : _fmtSleep(_sleepHours),
                Icons.nights_stay,
                colorScheme.primary,
                _isLoadingDaily ? 0.0 : sleepProgress,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricCard(
                context,
                isItalian ? "Passi" : "Steps",
                _isLoadingDaily ? '—' : _fmtSteps(_steps),
                Icons.bolt,
                colorScheme.secondary,
                _isLoadingDaily ? 0.0 : stepsProgress,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Riga 2: Distanza al posto delle Calorie (non disponibili) e
        // card "ultimo report" in versione compatta al posto della
        // vecchia card distanza
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _buildMetricCard(
                context,
                isItalian ? "Distanza" : "Distance",
                _isLoadingDaily ? '—' : '${_distanceKm.toStringAsFixed(1)} km',
                Icons.favorite,
                colorScheme.error,
                0.0, // nessun progress circolare per distanza
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildLastReportCard(context, isItalian),
            ),
          ],
        ),
      ],
    );
  }

  // Versione compatta della card "ultimo report", pensata per stare
  // affiancata alle altre metriche nella griglia 2x2 (al posto della
  // vecchia card "Distanza")
  Widget _buildLastReportCard(BuildContext context, bool isItalian) {
    final colorScheme = Theme.of(context).colorScheme;
    // Leggiamo il report dalla cache condivisa del DataProvider.
    // _loadWeeklyReport() (chiamato in initState e nel pull-to-refresh)
    // garantisce che venga effettivamente calcolato/aggiornato, non solo
    // letto passivamente come prima.
    final report = context.watch<DataProvider>().lastWeeklyReport;

    // Placeholder mentre carica (e non c'è ancora nulla in cache)
    if (_isLoadingReport && report == null) {
      return Material(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  isItalian ? 'Report…' : 'Report…',
                  style: TextStyle(
                      fontSize: 15, color: colorScheme.onSurfaceVariant),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Placeholder se il report non è ancora stato caricato o non ha dati
    if (report == null || !report.hasData) {
      return Material(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  isItalian ? 'Ultimo report' : 'Latest report',
                  style: TextStyle(
                      fontSize: 15, color: colorScheme.onSurfaceVariant),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(height: 4),
              Icon(Icons.analytics_rounded,
                  color: colorScheme.onSurfaceVariant, size: 20),
            ],
          ),
        ),
      );
    }

    final Color perfColor  = _perfColor(report.performance, colorScheme);
    final String evalLabel = isItalian ? report.evaluationIt : report.evaluationEn;

    return Material(
      color: colorScheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        // Tap → naviga al dettaglio del report settimanale
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => ReportDettaglioScreen(report: report)),
        ),
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isItalian ? 'Ultimo report' : 'Latest report',
                style: TextStyle(
                    fontSize: 13, color: colorScheme.onSurfaceVariant),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                evalLabel,
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: perfColor),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                'Stress ${report.avgStressIndex.toStringAsFixed(0)}/100',
                style: TextStyle(
                    fontSize: 13, color: colorScheme.onSurfaceVariant),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const Spacer(),
              Align(
                alignment: Alignment.centerRight,
                child: Icon(Icons.chevron_right_rounded,
                    color: colorScheme.onSurfaceVariant, size: 20),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Card singola metrica con progress circolare opzionale
  Widget _buildMetricCard(
    BuildContext context,
    String title,
    String value,
    IconData icon,
    Color color,
    double progress, // 0.0 = nessun anello, 0.0-1.0 = percentuale completamento
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    return Material(
      color: colorScheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        onTap: () {},
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: TextStyle(
                            fontSize: 15,
                            color: colorScheme.onSurfaceVariant),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 4),
                    Text(value,
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              // Mostriamo il progress circolare solo se progress > 0
              // (sleep e steps hanno un obiettivo, calorie e distanza no)
              if (progress > 0)
                SizedBox(
                  width: 46,
                  height: 46,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Anello di sfondo (traccia grigia)
                      CircularProgressIndicator(
                        value: 1.0,
                        strokeWidth: 4,
                        valueColor: AlwaysStoppedAnimation<Color>(
                            color.withValues(alpha: 0.1)),
                      ),
                      // Anello di progresso colorato
                      CircularProgressIndicator(
                        value: progress,
                        strokeWidth: 4,
                        strokeCap: StrokeCap.round,
                        valueColor: AlwaysStoppedAnimation<Color>(color),
                      ),
                      // Icona al centro dell'anello
                      Center(child: Icon(icon, color: color, size: 16)),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}