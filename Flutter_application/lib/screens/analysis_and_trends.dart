// lib/screens/analysis_and_trends.dart
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import '../providers/data_provider.dart';
import '../models/metric_point.dart';
import 'dart:io';
import '../providers/userdata_provider.dart';
import 'package:flutter_application/services/weekly_report_builder.dart';

// In postman:
// New request (POST request)
// https://---// documento di cappon con token
// In the body, we select the format (FOR data), we have to use username and password.
// values are "username": "----", "password": "12345678!"
// We send the request and we have the token (with access and refresh).
// If something goes wrong we get 401 or 403, if it works we get 200 and the token.

// NOTE: questo screen non importa StressCalculator direttamente.
// Tutta la logica di calcolo stress passa per DataProvider → StressCalculator.
// Se in futuro vuoi mostrare un breakdown dello stress su questo screen,
// puoi importare StressCalculator qui senza toccare il provider.

extension SemanticRoles on ColorScheme {
  Color get highlight => primary;
  Color get danger => error;
  Color get steady => tertiary;
  Color get surfaceRole => surface;
  Color get onSurfaceRole => onSurface;
}

class AnalysisAndTrendsScreen extends StatefulWidget {
  const AnalysisAndTrendsScreen({super.key});

  @override
  State<AnalysisAndTrendsScreen> createState() =>
      _AnalysisAndTrendsScreenState();
}

class _AnalysisAndTrendsScreenState extends State<AnalysisAndTrendsScreen> {
  int _selectedMetricIndex = 0;
  _TrendPeriod _selectedPeriod = _TrendPeriod.week;
  int _windowOffset = 0;

  int? _highlightedPointIndex;

  bool _isLoading = false;
  String? _errorMessage;
  String _windowLabel = '';
  List<MetricPoint> _currentPoints = const [];
  final Map<String, List<MetricPoint>> _metricCache = {};
  final Map<String, String> _labelCache = {};

  _MetricDefinition get _selectedMetric => _metricCatalog[_selectedMetricIndex];

  bool get _canGoToPreviousWindow => _windowOffset > -2;

  bool get _canGoToNextWindow => _windowOffset < 0;

  String get _cacheKey => _makeCacheKey(
        _selectedMetric.apiMetric,
        _selectedPeriod,
        _windowOffset,
      );

  @override
  void initState() {
    super.initState();
    _loadMetricData();
  }

  void _selectMetric(int index) {
    setState(() {
      _selectedMetricIndex = index;
      _windowOffset = 0;
      _highlightedPointIndex = null;
    });
    _loadMetricData();
  }

  void _selectPeriod(_TrendPeriod period) {
    if (_selectedPeriod == period) return;

    setState(() {
      _selectedPeriod = period;
      _windowOffset = 0;
      _highlightedPointIndex = null;
    });
    _loadMetricData();
  }

  void _moveWindow(int delta) {
    final int candidate = _windowOffset + delta;
    if (candidate < -2 || candidate > 2) return;

    setState(() {
      _windowOffset = candidate;
      _highlightedPointIndex = null;
    });
    _loadMetricData();
  }

  String _makeCacheKey(String metric, _TrendPeriod period, int offset) {
    return '$metric|${period.name}|$offset';
  }

  String _formatDate(DateTime date) {
    final String year = date.year.toString().padLeft(4, '0');
    final String month = date.month.toString().padLeft(2, '0');
    final String day = date.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }

  _DateRange _getDateRange(_TrendPeriod period, int offset) {
    // Ancora = ieri (l'API non accetta end_date >= oggi)
    final DateTime yesterday = WeeklyReportBuilder.kArchiveEnd;
    switch (period) {
      case _TrendPeriod.day:
        final DateTime baseDay = yesterday.add(Duration(days: offset));
        return _DateRange(
          start: _formatDate(baseDay),
          end: _formatDate(baseDay),
          label: _formatDate(baseDay),
        );

      case _TrendPeriod.week:
        final DateTime baseEnd =
            yesterday.add(Duration(days: offset * 7));
        final DateTime baseStart =
            baseEnd.subtract(const Duration(days: 6));
        return _DateRange(
          start: _formatDate(baseStart),
          end: _formatDate(baseEnd),
          label: '${_formatDate(baseStart)} – ${_formatDate(baseEnd)}',
        );

      case _TrendPeriod.month:
        final DateTime baseEnd =
            yesterday.add(Duration(days: offset * 7));
        final DateTime baseStart =
            baseEnd.subtract(const Duration(days: 6));
        return _DateRange(
          start: _formatDate(baseStart),
          end: _formatDate(baseEnd),
          label: '${_formatDate(baseStart)} – ${_formatDate(baseEnd)}',
        );
    }
  }

  Future<void> _loadMetricData() async {
    final _DateRange range = _getDateRange(_selectedPeriod, _windowOffset);
    final String cacheKey = _cacheKey;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _highlightedPointIndex = null;
    });

    try {
      final provider = context.read<DataProvider>();
      List<MetricPoint> data;

      if (_selectedPeriod == _TrendPeriod.day) {
        if (_selectedMetric.apiMetric == 'stress') {
          data = await provider.fetchCalculatedStressSingleDay(range.start);
        } else {
          data = await provider.fetchSingleDayMetric(
              _selectedMetric.apiMetric, range.start);
        }
      } else {
        if (_selectedMetric.apiMetric == 'stress') {
          data = await provider.fetchCalculatedStressRange(
              range.start, range.end);
        } else {
          data = await provider.fetchMetricRange(
              _selectedMetric.apiMetric, range.start, range.end);
        }
      }

      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _currentPoints = data;
        _windowLabel = range.label;
        _metricCache[cacheKey] = data;
        _labelCache[cacheKey] = range.label;
        if (data.isEmpty) _errorMessage = 'No data found for this period.';
      });

      _preloadOtherMetrics();
    } catch (e, stack) {
      print('_loadMetricData ERROR: $e');
      if (!mounted) return;

      String friendlyMessage = 'Oops! We cannot load your data right now.';
      IconData errorIcon = Icons.error_outline;

      if (e is SocketException) {
        friendlyMessage =
            'You appear to be offline. Please check your connection.';
        errorIcon = Icons.wifi_off;
      }

      setState(() {
        _isLoading = false;
        _currentPoints = const [];
        _windowLabel = range.label;
        _errorMessage = friendlyMessage;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(errorIcon, color: Theme.of(context).colorScheme.onError),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  friendlyMessage,
                  style: TextStyle(
                      color: Theme.of(context).colorScheme.onError),
                ),
              ),
            ],
          ),
          backgroundColor: Theme.of(context).colorScheme.error,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.only(bottom: 20, left: 16, right: 16),
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  Future<void> _preloadOtherMetrics() async {
    final _DateRange range = _getDateRange(_selectedPeriod, _windowOffset);
    final provider = context.read<DataProvider>();

    for (int i = 0; i < _metricCatalog.length; i++) {
      if (i == _selectedMetricIndex) continue;

      final metric = _metricCatalog[i];
      final String cacheKey =
          _makeCacheKey(metric.apiMetric, _selectedPeriod, _windowOffset);

      if (_metricCache.containsKey(cacheKey)) continue;

      try {
        List<MetricPoint> data;

        if (_selectedPeriod == _TrendPeriod.day) {
          if (metric.apiMetric == 'stress') {
            data =
                await provider.fetchCalculatedStressSingleDay(range.start);
          } else {
            data = await provider.fetchSingleDayMetric(
                metric.apiMetric, range.start);
          }
        } else {
          if (metric.apiMetric == 'stress') {
            data = await provider.fetchCalculatedStressRange(
                range.start, range.end);
          } else {
            data = await provider.fetchMetricRange(
                metric.apiMetric, range.start, range.end);
          }
        }

        if (mounted) {
          setState(() {
            _metricCache[cacheKey] = data;
          });
        }
      } catch (e) {
        print('Preload error for ${metric.apiMetric}: $e');
        if (mounted) {
          setState(() {
            _metricCache[cacheKey] = const [];
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final DataProvider dataProvider = context.watch<DataProvider>();
    final UserDataProvider userDataProvider = context.watch<UserDataProvider>();
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final TextTheme textTheme = Theme.of(context).textTheme;
    final bool isLoading = _isLoading || dataProvider.isLoading;
    final List<MetricPoint> displayPoints = _currentPoints;
    final _WindowStats? stats = displayPoints.isNotEmpty
        ? _WindowStats.fromPoints(displayPoints)
        : null;
    final Color accentColor = _selectedMetric.resolveColor(scheme);
    final String windowLabel = _windowLabel.isNotEmpty
        ? _windowLabel
        : _labelCache[_cacheKey] ?? 'No range';

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 18),
          children: [
            Text(
              'Analysis & Trends, ${userDataProvider.firstName}',
              style: textTheme.headlineSmall,
            ),
            const SizedBox(height: 4),
            Text(
              'Let\'s find your metrics from your well-being today.',
              style: textTheme.bodyMedium?.copyWith(
                color: scheme.onSurfaceRole.withValues(alpha: 0.72),
              ),
            ),
            const SizedBox(height: 18),
            _TimePeriodSelector(
              selectedPeriod: _selectedPeriod,
              onPeriodChanged: _selectPeriod,
            ),
            const SizedBox(height: 8),
            _WindowNavigator(
              label: windowLabel,
              canGoPrevious: _canGoToPreviousWindow,
              canGoNext: _canGoToNextWindow,
              onPrevious: () => _moveWindow(-1),
              onNext: () => _moveWindow(1),
            ),
            const SizedBox(height: 8),
            Card(
              elevation: 0,
              color: scheme.surfaceContainerLowest,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
                side: BorderSide(color: scheme.outlineVariant),
              ),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${_selectedMetric.name} Trend (${_selectedPeriod.label})',
                      style: textTheme.titleMedium,
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      height: 180,
                      child: isLoading
                          ? const Center(child: CircularProgressIndicator())
                          : displayPoints.isEmpty
                              ? Center(
                                  child: Text(
                                    _errorMessage ??
                                        'No data found for this period.',
                                    style: textTheme.bodySmall?.copyWith(
                                      color: scheme.onSurfaceRole
                                          .withValues(alpha: 0.72),
                                    ),
                                  ),
                                )
                              : ((_selectedMetric.apiMetric == 'sleep' ||
                                          _selectedMetric.apiMetric ==
                                              'stress') &&
                                      _selectedPeriod == _TrendPeriod.day)
                                  ? _DailySummaryCard(
                                      metricId: _selectedMetric.apiMetric,
                                      value: displayPoints.first.value,
                                      accentColor: accentColor,
                                    )
                                  : IgnorePointer(
                                      ignoring:
                                          _selectedPeriod == _TrendPeriod.day,
                                      child: _MetricTrendChart(
                                        points: displayPoints,
                                        accentColor: accentColor,
                                        textColor: scheme.onSurfaceRole,
                                        unit: _selectedMetric.unit,
                                        highlightedIndex: _highlightedPointIndex,
                                        enableTouch: _selectedPeriod !=
                                            _TrendPeriod.day,
                                        maxLabels:
                                            _selectedPeriod == _TrendPeriod.day
                                                ? 6
                                                : null,
                                        onPointSelected: (index) => setState(
                                          () => _highlightedPointIndex = index,
                                        ),
                                      ),
                                    ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: _StatValue(
                            title: 'Average',
                            value: stats == null
                                ? '--'
                                : _formatMetricValue(
                                    stats.average,
                                    _selectedMetric.unit,
                                  ),
                          ),
                        ),
                        Expanded(
                          child: _StatValue(
                            title: 'Highest',
                            value: stats == null
                                ? '--'
                                : '${stats.maxPoint.shortLabel} (${_formatMetricValue(stats.maxPoint.value, _selectedMetric.unit)})',
                          ),
                        ),
                        Expanded(
                          child: _StatValue(
                            title: 'Lowest',
                            value: stats == null
                                ? '--'
                                : '${stats.minPoint.shortLabel} (${_formatMetricValue(stats.minPoint.value, _selectedMetric.unit)})',
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            if (displayPoints.isNotEmpty ||
                _selectedPeriod != _TrendPeriod.day) ...[
              const SizedBox(height: 16),
              Text('Other Well-being Metrics', style: textTheme.titleMedium),
              const SizedBox(height: 8),
              ...List<Widget>.generate(_metricCatalog.length, (int index) {
                final _MetricDefinition metric = _metricCatalog[index];
                final bool isSelected = index == _selectedMetricIndex;

                final String listKey = _makeCacheKey(
                  metric.apiMetric,
                  _selectedPeriod,
                  _windowOffset,
                );
                final List<MetricPoint> metricPoints = isSelected
                    ? displayPoints
                    : _metricCache[listKey] ?? const [];

                final MetricPoint? latest =
                    metricPoints.isNotEmpty ? metricPoints.last : null;
                final Color metricColor = metric.resolveColor(scheme);

                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  elevation: 0,
                  color: isSelected
                      ? scheme.secondaryContainer.withValues(alpha: 0.6)
                      : scheme.surface,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(
                      color:
                          isSelected ? metricColor : scheme.outlineVariant,
                    ),
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () => _selectMetric(index),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 17,
                                backgroundColor:
                                    metricColor.withValues(alpha: 0.14),
                                child: Icon(
                                  metric.icon,
                                  color: metricColor,
                                  size: 18,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      metric.name,
                                      style: textTheme.titleSmall,
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${latest == null ? '--' : _formatMetricValue(latest.value, metric.unit)} • ${metric.statusLabel}',
                                      style: textTheme.bodySmall?.copyWith(
                                        color: scheme.onSurfaceRole
                                            .withValues(alpha: 0.72),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Icon(
                                isSelected
                                    ? Icons.expand_less
                                    : Icons.chevron_right,
                                color: scheme.onSurfaceRole
                                    .withValues(alpha: 0.62),
                              ),
                            ],
                          ),
                          AnimatedCrossFade(
                            firstChild: const SizedBox.shrink(),
                            secondChild: Padding(
                              padding: const EdgeInsets.only(top: 10),
                              child: isSelected && isLoading
                                  ? const Center(
                                      child: CircularProgressIndicator(),
                                    )
                                  : metricPoints.isEmpty
                                      ? Align(
                                          alignment: Alignment.centerLeft,
                                          child: Text(
                                            _errorMessage ??
                                                'No data found for this period.',
                                            style:
                                                textTheme.bodySmall?.copyWith(
                                              color: scheme.onSurfaceRole
                                                  .withValues(alpha: 0.72),
                                            ),
                                          ),
                                        )
                                      : Align(
                                          alignment: Alignment.centerLeft,
                                          child: Wrap(
                                            spacing: 7,
                                            runSpacing: 7,
                                            children: metricPoints
                                                .asMap()
                                                .entries
                                                .map((entry) {
                                              final int pointIdx = entry.key;
                                              final MetricPoint point =
                                                  entry.value;
                                              final bool isHighlighted =
                                                  _highlightedPointIndex ==
                                                      pointIdx;

                                              return ChoiceChip(
                                                selected: isHighlighted,
                                                onSelected: (selected) {
                                                  setState(() {
                                                    _highlightedPointIndex =
                                                        selected
                                                            ? pointIdx
                                                            : null;
                                                  });
                                                },
                                                showCheckmark: false,
                                                visualDensity:
                                                    VisualDensity.compact,
                                                side: BorderSide(
                                                  color: isHighlighted
                                                      ? metricColor
                                                      : scheme.outlineVariant,
                                                ),
                                                selectedColor: metricColor
                                                    .withValues(alpha: 0.25),
                                                backgroundColor: scheme
                                                    .surfaceRole
                                                    .withValues(alpha: 0.8),
                                                label: Text(
                                                  '${point.fullLabel}: ${_formatMetricValue(point.value, metric.unit)}',
                                                  style: textTheme.bodySmall
                                                      ?.copyWith(
                                                    fontWeight: isHighlighted
                                                        ? FontWeight.bold
                                                        : FontWeight.normal,
                                                    color: isHighlighted
                                                        ? scheme.onSurface
                                                        : scheme.onSurfaceRole,
                                                  ),
                                                ),
                                              );
                                            }).toList(),
                                          ),
                                        ),
                            ),
                            crossFadeState: (isSelected &&
                                    _selectedPeriod != _TrendPeriod.day)
                                ? CrossFadeState.showSecond
                                : CrossFadeState.showFirst,
                            duration: const Duration(milliseconds: 220),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ],
          ],
        ),
      ),
    );
  }
}

// --- CLASSI DI SUPPORTO ---
enum _TrendPeriod { day, week, month }

extension on _TrendPeriod {
  String get label {
    switch (this) {
      case _TrendPeriod.day:
        return 'Day';
      case _TrendPeriod.week:
        return 'Week';
      case _TrendPeriod.month:
        return 'Month';
    }
  }
}

enum _MetricTone { highlight, steady, danger }

class _DateRange {
  const _DateRange({
    required this.start,
    required this.end,
    required this.label,
  });

  final String start;
  final String end;
  final String label;
}

class _MetricDefinition {
  const _MetricDefinition({
    required this.apiMetric,
    required this.name,
    required this.unit,
    required this.icon,
    required this.statusLabel,
    required this.tone,
  });

  final String apiMetric;
  final String name;
  final String unit;
  final IconData icon;
  final String statusLabel;
  final _MetricTone tone;

  Color resolveColor(ColorScheme scheme) {
    switch (tone) {
      case _MetricTone.highlight:
        return scheme.highlight;
      case _MetricTone.steady:
        return scheme.steady;
      case _MetricTone.danger:
        return scheme.danger;
    }
  }
}

class _WindowStats {
  const _WindowStats({
    required this.average,
    required this.maxPoint,
    required this.minPoint,
  });

  final double average;
  final MetricPoint maxPoint;
  final MetricPoint minPoint;

  factory _WindowStats.fromPoints(List<MetricPoint> points) {
    final MetricPoint maxPoint = points.reduce(
      (left, right) => left.value >= right.value ? left : right,
    );
    final MetricPoint minPoint = points.reduce(
      (left, right) => left.value <= right.value ? left : right,
    );
    final double total = points.fold(0, (sum, point) => sum + point.value);

    return _WindowStats(
      average: total / points.length,
      maxPoint: maxPoint,
      minPoint: minPoint,
    );
  }
}

// --- WIDGET DI SUPPORTO ---
class _TimePeriodSelector extends StatelessWidget {
  const _TimePeriodSelector({
    required this.selectedPeriod,
    required this.onPeriodChanged,
  });

  final _TrendPeriod selectedPeriod;
  final ValueChanged<_TrendPeriod> onPeriodChanged;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;

    Widget segment({required _TrendPeriod period, required String label}) {
      final bool isSelected = selectedPeriod == period;

      return Expanded(
        child: GestureDetector(
          onTap: () => onPeriodChanged(period),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
            padding: const EdgeInsets.symmetric(vertical: 7),
            decoration: BoxDecoration(
              color: isSelected ? scheme.primary : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color:
                    isSelected ? scheme.onPrimary : scheme.onSurfaceRole,
              ),
            ),
          ),
        ),
      );
    }

    return Row(
      children: [
        Text('TIME PERIOD',
            style: Theme.of(context).textTheme.labelSmall),
        const Spacer(),
        Container(
          width: 190,
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: scheme.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              segment(period: _TrendPeriod.day, label: 'DAY'),
              segment(period: _TrendPeriod.week, label: 'WEEK'),
              segment(period: _TrendPeriod.month, label: 'MONTH'),
            ],
          ),
        ),
      ],
    );
  }
}

class _WindowNavigator extends StatelessWidget {
  const _WindowNavigator({
    required this.label,
    required this.canGoPrevious,
    required this.canGoNext,
    required this.onPrevious,
    required this.onNext,
  });

  final String label;
  final bool canGoPrevious;
  final bool canGoNext;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        IconButton(
          icon: const Icon(Icons.chevron_left),
          visualDensity: VisualDensity.compact,
          onPressed: canGoPrevious ? onPrevious : null,
        ),
        Expanded(
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleSmall,
          ),
        ),
        IconButton(
          icon: const Icon(Icons.chevron_right),
          color: canGoNext ? scheme.onSurfaceRole : null,
          visualDensity: VisualDensity.compact,
          onPressed: canGoNext ? onNext : null,
        ),
      ],
    );
  }
}

class _StatValue extends StatelessWidget {
  const _StatValue({required this.title, required this.value});

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    final ColorScheme scheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          title,
          textAlign: TextAlign.center,
          style: textTheme.labelSmall?.copyWith(
            color: scheme.onSurfaceRole.withValues(alpha: 0.75),
          ),
        ),
        const SizedBox(height: 2),
        Text(value,
            textAlign: TextAlign.center, style: textTheme.titleSmall),
      ],
    );
  }
}

class _MetricTrendChart extends StatelessWidget {
  const _MetricTrendChart({
    required this.points,
    required this.accentColor,
    required this.textColor,
    required this.unit,
    this.highlightedIndex,
    required this.onPointSelected,
    this.enableTouch = true,
    this.maxLabels,
  });

  final List<MetricPoint> points;
  final Color accentColor;
  final Color textColor;
  final String unit;
  final bool enableTouch;
  final int? maxLabels;
  final int? highlightedIndex;
  final ValueChanged<int?> onPointSelected;

  @override
  Widget build(BuildContext context) {
    if (points.isEmpty) return const SizedBox.shrink();

    if (points.length == 1) {
      return Center(
        child: Text(
          'Not enough data points to draw a line chart.',
          style: TextStyle(color: textColor.withValues(alpha: 0.6)),
        ),
      );
    }

    final double minValue =
        points.map((p) => p.value).reduce((a, b) => a < b ? a : b);
    final double maxValue =
        points.map((p) => p.value).reduce((a, b) => a > b ? a : b);
    final double range = (maxValue - minValue).abs();
    final double padding = range < 8 ? 4 : range * 0.2;
    final double interval =
        ((maxValue + padding) - (minValue - padding)) / 4;

    return LineChart(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      LineChartData(
        minY: (minValue - padding < 0) ? 0.0 : (minValue - padding),
        maxY: maxValue + padding,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: interval == 0 ? 1 : interval,
          getDrawingHorizontalLine: (value) => FlLine(
              color: textColor.withValues(alpha: 0.16), strokeWidth: 1),
        ),
        borderData: FlBorderData(show: false),
        lineTouchData: LineTouchData(
          enabled: enableTouch,
          handleBuiltInTouches: enableTouch,
          touchCallback:
              (FlTouchEvent event, LineTouchResponse? touchResponse) {
            if (touchResponse?.lineBarSpots != null &&
                touchResponse!.lineBarSpots!.isNotEmpty) {
              if (event is FlTapUpEvent || event is FlPanUpdateEvent) {
                onPointSelected(
                    touchResponse.lineBarSpots!.first.spotIndex);
              }
            }
          },
          touchTooltipData: LineTouchTooltipData(
            fitInsideHorizontally: true,
            fitInsideVertically: true,
            getTooltipItems: (spots) {
              return spots.map((spot) {
                final int index = spot.x.toInt();
                final MetricPoint point = points[index];
                return LineTooltipItem(
                  '${point.fullLabel}: ${_formatMetricValue(point.value, unit)}',
                  TextStyle(
                    color: textColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 11,
                  ),
                );
              }).toList();
            },
          ),
        ),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 34,
              interval: interval == 0 ? 1 : interval,
              getTitlesWidget: (value, meta) {
                return Text(
                  value.toInt().toString(),
                  style: TextStyle(fontSize: 10, color: textColor),
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 25,
              interval: 1,
              getTitlesWidget: (value, meta) {
                if (value != value.toInt().toDouble()) {
                  return const SizedBox.shrink();
                }

                final int index = value.toInt();
                if (index < 0 || index >= points.length) {
                  return const SizedBox.shrink();
                }

                String label = points[index].shortLabel;

                if (maxLabels != null && maxLabels! > 0) {
                  final int step = (points.length / maxLabels!)
                      .ceil()
                      .clamp(1, points.length);

                  if (index % step != 0 && index != points.length - 1) {
                    return const SizedBox.shrink();
                  }

                  if (index == points.length - 1 && index % step != 0) {
                    final int prevPrintedIndex = index - (index % step);
                    if ((index - prevPrintedIndex) < step * 0.7) {
                      return const SizedBox.shrink();
                    }
                  }
                }

                if (label.length == 5 && label[2] == ':') {
                  label = '${label.substring(0, 2)}:00';
                }

                return Padding(
                  padding: const EdgeInsets.only(top: 5),
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 11,
                      color: index == highlightedIndex
                          ? accentColor
                          : textColor,
                      fontWeight: index == highlightedIndex
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: points.asMap().entries.map((entry) {
              return FlSpot(entry.key.toDouble(), entry.value.value);
            }).toList(),
            isCurved: true,
            color: accentColor,
            barWidth: 3.6,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) {
                final isSelected = index == highlightedIndex;
                return FlDotCirclePainter(
                  radius: isSelected ? 6.0 : 3.4,
                  color: accentColor,
                  strokeWidth: isSelected ? 2 : 1,
                  strokeColor: isSelected
                      ? Colors.white
                      : textColor.withValues(alpha: 0.35),
                );
              },
            ),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  accentColor.withValues(alpha: 0.22),
                  accentColor.withValues(alpha: 0.03),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

String _formatMetricValue(double value, String unit) {
  final bool useDecimals = unit == 'h';
  final String formatted = useDecimals
      ? value.toStringAsFixed(1)
      : value.round().toString();

  if (unit == '/100') {
    return '$formatted$unit';
  }

  return '$formatted $unit';
}

const List<_MetricDefinition> _metricCatalog = [
  _MetricDefinition(
    apiMetric: 'stress',
    name: 'Stress Index',
    unit: '/100',
    icon: Icons.monitor_heart_outlined,
    statusLabel: 'Balanced',
    tone: _MetricTone.highlight,
  ),
  _MetricDefinition(
    apiMetric: 'heart_rate',
    name: 'Heart Rate',
    unit: 'bpm',
    icon: Icons.favorite_border,
    statusLabel: 'Weekly Average',
    tone: _MetricTone.danger,
  ),
  _MetricDefinition(
    apiMetric: 'sleep',
    name: 'Sleep Hours',
    unit: 'h',
    icon: Icons.nightlight_round,
    statusLabel: 'Sleep Hours',
    tone: _MetricTone.steady,
  ),
  _MetricDefinition(
    apiMetric: 'steps',
    name: 'Step Count',
    unit: 'steps',
    icon: Icons.directions_walk,
    statusLabel: 'Daily Goal Tracking',
    tone: _MetricTone.highlight,
  ),
];

class _DailySummaryCard extends StatelessWidget {
  const _DailySummaryCard({
    required this.metricId,
    required this.value,
    required this.accentColor,
  });

  final String metricId;
  final double value;
  final Color accentColor;

  Color _getStressColor(double level, Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    if (level < 30) return isDark ? const Color(0xFF6EE7A0) : const Color(0xFF166534);
    if (level < 60) return isDark ? const Color(0xFFFDE68A) : const Color(0xFF92400E);
    if (level < 80) return isDark ? const Color(0xFFFBBF24) : const Color(0xFF9A3412);
    return isDark ? const Color(0xFFF87171) : const Color(0xFF991B1B);
  }

  @override
  Widget build(BuildContext context) {
    IconData icon = Icons.nightlight_round;
    String mainText = '';
    String subText = '';
    Color displayColor = accentColor;

    if (metricId == 'sleep') {
      icon = Icons.nightlight_round;
      final int h = value.floor();
      final int m = ((value - h) * 60).round();
      mainText = '${h}h ${m}m';
      subText = 'Total sleep time';
    } else if (metricId == 'stress') {
      icon = Icons.monitor_heart_outlined;
      mainText = '${value.round()}/100';
      subText = 'Calculated Daily Stress';
      displayColor = _getStressColor(value, Theme.of(context).brightness);
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 48, color: displayColor),
          const SizedBox(height: 12),
          Text(
            mainText,
            style: Theme.of(context).textTheme.displaySmall?.copyWith(
              color: displayColor,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subText,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}