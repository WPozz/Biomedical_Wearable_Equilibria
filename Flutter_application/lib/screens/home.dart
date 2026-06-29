import 'package:flutter/material.dart';
import 'dart:async';
import 'package:provider/provider.dart';
import 'package:flutter_application/providers/settings_provider.dart';
import 'package:flutter_application/providers/data_provider.dart';
import 'package:flutter_application/models/metric_point.dart'; // ← aggiunto: serve per tipizzare esplicitamente List<MetricPoint>
import 'package:flutter_application/utils/weekly_report_model.dart';
import 'package:flutter_application/services/weekly_report_builder.dart';
import 'package:flutter_application/screens/pausa_attiva.dart';
import 'package:flutter_application/screens/report_dettaglio.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

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
    // Il giorno che mostriamo in home è il 22 giugno:
    // - i dati di attività (steps, calories, distance) sono stati registrati il 22
    // - il sonno del 22 è la notte tra il 21 e il 22, che il Fitbit associa
    //   alla data di sveglia (22 giugno) → esiste nell'API
    _syncedDay    = WeeklyReportBuilder.kArchiveEnd.add(const Duration(days: 1));
    _syncedDayStr = _fmtDate(_syncedDay);

    // Carichiamo i dati solo dopo che il primo frame è stato renderizzato,
    // così il context è già disponibile per leggere il DataProvider
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadDailyData());
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
      // Il DataProvider espone due metodi per ottenere dati:
      //
      // 1. fetchMetricRange(metric, startDate, endDate)
      //    → chiama l'endpoint: /daterange/start_date/.../end_date/.../
      //    → aggrega i dati giorno per giorno e restituisce un MetricPoint
      //      per ogni giorno (con il valore già sommato o mediato)
      //    → funziona bene per range di 7+ giorni (es. grafici settimanali)
      //    → PROBLEMA: quando startDate == endDate (un solo giorno),
      //      l'API /daterange/ restituisce lista vuota → nessun dato
      //
      // 2. fetchSingleDayMetric(metric, day)
      //    → chiama l'endpoint: /day/<date>/
      //    → restituisce tutti i punti intraday della giornata
      //      (per steps/calories/distance: un punto ogni minuto)
      //    → funziona correttamente anche per un singolo giorno
      //    → è l'endpoint giusto per la home, che mostra sempre "oggi"
      //
      // La scelta corretta per la home è quindi fetchSingleDayMetric.
      // Lanciamo tutte e 5 le fetch in parallelo con Future.wait per
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

      // ── PERCHÉ sommiamo i valori? ─────────────────────────────────────────
      //
      // fetchSingleDayMetric restituisce i dati "grezzi" intraday:
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

        // La distanza arriva in cm dall'API (vedi Appendix slide 48).
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

    } catch (e, stack) {
      print('HOME DEBUG ERROR durante _loadDailyData: $e');
      print(stack);
      if (!mounted) return;
      setState(() {
        _isLoadingDaily    = false;
        _dailyErrorMessage = 'error';
      });
    }
  }

  // Restituisce il colore del blob/testo in base al livello di stress.
  // forText: true → colore per testo (più scuro in light, più chiaro in dark)
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
          // Pull-to-refresh: ricarica i dati del giorno corrente
          onRefresh: _loadDailyData,
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
                              // poi mostriamo il numero 0-100
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
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                context,
                isItalian ? "Calorie" : "Calories",
                _isLoadingDaily ? '—' : '${_calories.round()} kcal',
                Icons.local_fire_department,
                colorScheme.tertiary,
                0.0, // nessun progress circolare per calorie
              ),
            ),
            const SizedBox(width: 12),
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
          ],
        ),
        const SizedBox(height: 12),
        _buildLastReportCard(context, isItalian),
      ],
    );
  }

  Widget _buildLastReportCard(BuildContext context, bool isItalian) {
    final colorScheme = Theme.of(context).colorScheme;
    // Leggiamo il report dall'ultimo WeeklyReport caricato dal DataProvider
    final report = context.watch<DataProvider>().lastWeeklyReport;

    // Placeholder se il report non è ancora stato caricato
    if (report == null || !report.hasData) {
      return Material(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isItalian ? 'Ultimo report' : 'Latest report',
                      style: TextStyle(
                          fontSize: 15, color: colorScheme.onSurfaceVariant),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isItalian ? 'Non ancora disponibile' : 'Not yet available',
                      style: TextStyle(
                          fontSize: 15, color: colorScheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              Icon(Icons.analytics_rounded,
                  color: colorScheme.onSurfaceVariant, size: 28),
            ],
          ),
        ),
      );
    }

    final Color perfColor  = _perfColor(report.performance, colorScheme);
    final String evalLabel = isItalian ? report.evaluationIt : report.evaluationEn;
    final String dateLabel = isItalian ? report.dateRangeIt  : report.dateRangeEn;

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
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isItalian
                          ? 'Ultimo report · $dateLabel'
                          : 'Latest report · $dateLabel',
                      style: TextStyle(
                          fontSize: 13, color: colorScheme.onSurfaceVariant),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$evalLabel · Stress ${report.avgStressIndex.toStringAsFixed(0)}/100',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: perfColor),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.chevron_right_rounded,
                  color: colorScheme.onSurfaceVariant, size: 22),
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