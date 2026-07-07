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
  final VoidCallback? onDailyDataLoaded;

  const HomeScreen({super.key, this.onDailyDataLoaded});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {

  double _radiusMultiplier = 1.0;
  late Timer _timer;

  bool _isLoadingDaily = true;
  String? _dailyErrorMessage;
  int _stressLevel = 0;
  double _sleepHours = 0;
  double _steps = 0;
  double _distanceKm = 0;

  bool _sleepMissing = true;
  bool _stepsMissing = true;
  bool _distanceMissing = true;

  bool _isLoadingReport = true;

  late final DateTime _syncedDay;
  late final String _syncedDayStr;

  @override
  void initState() {
    super.initState();

    _timer = Timer.periodic(const Duration(seconds: 2), (timer) {
      if (mounted) {
        setState(() {
          _radiusMultiplier = _radiusMultiplier == 1.0 ? 1.1 : 1.0;
        });
      }
    });

    _syncedDay    = WeeklyReportBuilder.kArchiveEnd.add(const Duration(days: 1));
    _syncedDayStr = _fmtDate(_syncedDay);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadDailyData();
      _loadWeeklyReport();
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

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
      final results = await Future.wait([
        dataProvider.fetchSingleDayMetric('sleep',    _syncedDayStr),
        dataProvider.fetchSingleDayMetric('steps',    _syncedDayStr),
        dataProvider.fetchSingleDayMetric('distance', _syncedDayStr),
        dataProvider.fetchCalculatedStressSingleDay(_syncedDayStr),
      ]);

      if (!mounted) return;

      final List<MetricPoint> sleepPoints    = results[0];
      final List<MetricPoint> stepsPoints    = results[1];
      final List<MetricPoint> distancePoints = results[2];
      final List<MetricPoint> stressPoints   = results[3];

      double sumValues(List<MetricPoint> points) => points.isEmpty
          ? 0.0
          : points.map((p) => p.value).reduce((a, b) => a + b);

      setState(() {
        _sleepMissing    = sleepPoints.isEmpty;
        _stepsMissing    = stepsPoints.isEmpty;
        _distanceMissing = distancePoints.isEmpty;

        _sleepHours  = sleepPoints.isNotEmpty ? sleepPoints.first.value : 0;
        _steps       = sumValues(stepsPoints);

        _distanceKm  = distancePoints.isNotEmpty
            ? sumValues(distancePoints) / 100000.0
            : 0;

        _stressLevel = stressPoints.isNotEmpty
            ? stressPoints.first.value.round()
            : 0;

        _isLoadingDaily = false;

        final bool noDataAtAll = sleepPoints.isEmpty &&
            stepsPoints.isEmpty &&
            distancePoints.isEmpty;
        if (noDataAtAll) _dailyErrorMessage = 'no_data';
      });

      widget.onDailyDataLoaded?.call();

    } catch (e, stack) {
      print('HOME DEBUG ERROR durante _loadDailyData: $e');
      print(stack);
      if (!mounted) return;
      setState(() {
        _isLoadingDaily    = false;
        _dailyErrorMessage = 'error';
      });
      widget.onDailyDataLoaded?.call();
    }
  }

  StressLevel _stressLevelEnum(int level) =>
      DailyStress(date: _syncedDay, stressIndex: level.toDouble()).level;

  Color _getStressColor(int level, {bool forText = false}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    switch (_stressLevelEnum(level)) {
      case StressLevel.low:
        if (forText) return isDark ? const Color(0xFF6EE7A0) : const Color(0xFF166534);
        return isDark ? const Color(0xFF1A4D2E) : const Color(0xFF5DF091);
      case StressLevel.medium:
        if (forText) return isDark ? const Color(0xFFFDE68A) : const Color(0xFF92400E);
        return isDark ? const Color(0xFF4D3A00) : const Color(0xFFEDDC5C);
      case StressLevel.high:
        if (forText) return isDark ? const Color(0xFFF87171) : const Color(0xFF991B1B);
        return isDark ? const Color(0xFF4D1515) : const Color(0xFFDF6868);
    }
  }

  String _getStressLabel(int level, bool isItalian) {
    switch (_stressLevelEnum(level)) {
      case StressLevel.low:
        return isItalian ? "Rilassato" : "Relaxed";
      case StressLevel.medium:
        return isItalian ? "Livello di stress moderato" : "Moderate stress level";
      case StressLevel.high:
        return isItalian ? "Livello di stress alto" : "High stress level";
    }
  }

  Color _perfColor(WeekPerformance perf, ColorScheme scheme) {
    switch (perf) {
      case WeekPerformance.excellent: return scheme.primary;
      case WeekPerformance.good:      return const Color(0xFFF59E0B);
      case WeekPerformance.fair:      return const Color(0xFFF97316);
      case WeekPerformance.poor:      return scheme.error;
    }
  }

  String _fmtSleep(double hours) {
    final h = hours.floor();
    final m = ((hours - h) * 60).round();
    return '${h}h ${m}m';
  }

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
            'assets/images/Kairos_up.png',
            height: 150,
            fit: BoxFit.contain,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
      ),
      body: SafeArea(
        child: RefreshIndicator(
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
                  Column(
                    children: [
                      const SizedBox(height: 20),
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

                  Text(
                    isItalian ? "Panoramica" : "Vitals",
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
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                context,
                isItalian ? "Passi" : "Steps",
                _fmtSteps(_steps),
                Icons.directions_walk,
                Theme.of(context).colorScheme.secondary,
                isMissing: _stepsMissing,
                isLoading: _isLoadingDaily,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricCard(
                context,
                isItalian ? "Distanza" : "Distance",
                '${_distanceKm.toStringAsFixed(1)} km',
                Icons.route,
                Theme.of(context).colorScheme.error,
                isMissing: _distanceMissing,
                isLoading: _isLoadingDaily,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _buildMetricCard(
          context,
          isItalian ? "Durata sonno" : "Sleep Duration",
          _fmtSleep(_sleepHours),
          Icons.nights_stay,
          Theme.of(context).colorScheme.primary,
          isMissing: _sleepMissing,
          isLoading: _isLoadingDaily,
        ),
        const SizedBox(height: 12),
        _buildLastReportCard(context, isItalian),
      ],
    );
  }

  Widget _buildLastReportCard(BuildContext context, bool isItalian) {
    final colorScheme = Theme.of(context).colorScheme;
    final report = context.watch<DataProvider>().lastWeeklyReport;

    if (_isLoadingReport && report == null) {
      return Material(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  isItalian ? 'Caricamento ultimo report…' : 'Loading latest report…',
                  style: TextStyle(
                      fontSize: 15, color: colorScheme.onSurfaceVariant),
                ),
              ),
            ],
          ),
        ),
      );
    }

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

  Widget _buildMetricCard(
    BuildContext context,
    String title,
    String value,
    IconData icon,
    Color color, {
    required bool isMissing,
    required bool isLoading,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    final String displayValue = isLoading ? '—' : (isMissing ? 'N/D' : value);
    final bool dimmed = isMissing && !isLoading;
    final Color valueColor =
        dimmed ? colorScheme.onSurfaceVariant : colorScheme.onSurface;

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
                  Text(title,
                      style: TextStyle(
                          fontSize: 15, color: colorScheme.onSurfaceVariant),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(displayValue,
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              fontStyle:
                                  dimmed ? FontStyle.italic : FontStyle.normal,
                              color: valueColor)),
                      if (dimmed) ...[
                        const SizedBox(width: 6),
                        Icon(Icons.info_outline_rounded,
                            size: 14, color: colorScheme.onSurfaceVariant),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            Icon(icon, color: dimmed ? color.withValues(alpha: 0.4) : color, size: 28),
          ],
        ),
      ),
    );
  }
}