import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import 'dart:io';

import '../providers/data_provider.dart';
import '../models/metric_point.dart';
import '../providers/userdata_provider.dart';
import '../services/weekly_report_builder.dart';
import '../providers/settings_provider.dart';

/// KEY POINT 0: Color Semantics
/// Defines a set of semantic color roles to enhance the clarity of the interface and improve accessibility.

extension SemanticRoles on ColorScheme {
  Color get highlight => primary;
  Color get danger => error;
  Color get steady => tertiary;
  Color get surfaceRole => surface;
  Color get onSurfaceRole => onSurface;
}

/// Metric Catalog
/// This list defines the available metrics, their display names, units, icons, and associated color tones 
/// for the interface.

class AnalysisAndTrendsScreen extends StatefulWidget {
  const AnalysisAndTrendsScreen({super.key});

  @override
  State<AnalysisAndTrendsScreen> createState() =>
      _AnalysisAndTrendsScreenState();
}

/// State Management for Analysis and Trends Screen
/// This class manages the state of the Analysis and Trends screen, including the selected metric, time period, data loading, error handling, and caching of metric data.

class _AnalysisAndTrendsScreenState extends State<AnalysisAndTrendsScreen> {
  int _selectedMetricIndex = 0;
  int? _expandedMetricIndex;
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

  /// History Boundaries
  /// Defines retention boundaries (approx. 6 months) for pagination.
  
  int get _minOffset {
    switch (_selectedPeriod) {
      case _TrendPeriod.day:
        return -180; // 180 days retrospective limit
      case _TrendPeriod.week:
        return -24;  // 24 weeks retrospective limit
    }
  }

  bool get _canGoToPreviousWindow => _windowOffset > _minOffset;
  bool get _canGoToNextWindow => _windowOffset < 0;

  String get _cacheKey =>
      _makeCacheKey(_selectedMetric.apiMetric, _selectedPeriod, _windowOffset);

  @override
  void initState() {
    super.initState();
    _loadMetricData();
  }

  void _selectMetric(int index) {
    setState(() {
      _selectedMetricIndex = index;
      _windowOffset = 0;
      _expandedMetricIndex = index;
      _highlightedPointIndex = null;
    });
    _loadMetricData();
  }

  void _selectPeriod(_TrendPeriod period) {
    if (_selectedPeriod == period) return;

    setState(() {
      _selectedPeriod = period;
      _windowOffset = 0;
      _expandedMetricIndex = null;
      _highlightedPointIndex = null;
    });

    _loadMetricData();
  }

  void _moveWindow(int delta) {
    final int candidate = _windowOffset + delta;

    // Safety guard: prevent cross-boundary pagination into the future or beyond maximum history
    if (candidate < _minOffset || candidate > 0) return;

    setState(() {
      _windowOffset = candidate;
      _expandedMetricIndex = null;
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

  /// Date Range Generation
  /// Computes specific formatting ranges for API ingestion payloads.
  /// Day view tracks a standalone date, while Week view handles a structured 7-day chunk.
  
  _DateRange _getDateRange(_TrendPeriod period, int offset) {
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
        final DateTime baseEnd = yesterday.add(Duration(days: offset * 7));
        final DateTime baseStart = baseEnd.subtract(const Duration(days: 6));
        return _DateRange(
          start: _formatDate(baseStart),
          end: _formatDate(baseEnd),
          label: '${_formatDate(baseStart)} – ${_formatDate(baseEnd)}',
        );
    }
  }

  /// Core Repository Fetching & Error Management
  /// Performs asynchronous retrieval for the active metric based on timeframe criteria.
  /// Resolves the 'stress' type via dedicated endpoints while encapsulating network exceptions.
  
  Future<void> _loadMetricData() async {
    final _DateRange range = _getDateRange(_selectedPeriod, _windowOffset);
    final String cacheKey = _cacheKey;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _highlightedPointIndex = null;
      
      _currentPoints = _metricCache[cacheKey] ?? const [];
    });

    try {
      final provider = context.read<DataProvider>();
      List<MetricPoint> data;

      if (_selectedPeriod == _TrendPeriod.day) {
        if (_selectedMetric.apiMetric == 'stress') {
          data = await provider.fetchCalculatedStressSingleDay(range.start);
        } else {
          data = await provider.fetchSingleDayMetric(
            _selectedMetric.apiMetric,
            range.start,
          );
        }
      } else {
        if (_selectedMetric.apiMetric == 'stress') {
          data = await provider.fetchCalculatedStressRange(
            range.start,
            range.end,
          );
        } else {
          data = await provider.fetchMetricRange(
            _selectedMetric.apiMetric,
            range.start,
            range.end,
          );
        }
      }

      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _currentPoints = data;
        _windowLabel = range.label;
        _metricCache[cacheKey] = data;
        _labelCache[cacheKey] = range.label;
        if (data.isEmpty) _errorMessage = 'no_data';
      });

      _preloadOtherMetrics();
    } catch (e, stack) {
      print('_loadMetricData ERROR: $e');
      if (!mounted) return;

      String friendlyMessage = 'error';
      IconData errorIcon = Icons.error_outline;

      if (e is SocketException) {
        friendlyMessage = 'offline';
        errorIcon = Icons.wifi_off;
      }

      setState(() {
        _isLoading = false;
        _currentPoints = const [];
        _windowLabel = range.label;
        _errorMessage = friendlyMessage;
      });

      final bool isItalian = context.read<SettingsProvider>().isItalian;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(errorIcon, color: Theme.of(context).colorScheme.onError),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  e is SocketException
                      ? (isItalian
                            ? 'Sei offline. Controlla la tua connessione.'
                            : 'You appear to be offline. Please check your connection.')
                      : (isItalian
                            ? 'Impossibile caricare i dati al momento.'
                            : 'Oops! We cannot load your data right now.'),
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onError,
                  ),
                ),
              ),
            ],
          ),
          backgroundColor: Theme.of(context).colorScheme.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.only(bottom: 20, left: 16, right: 16),
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  /// Performance Optimization via Background Preloading
  /// Asynchronously populates the local cache for unselected catalog metrics.
  /// Prevents interface stutter or loading blocks when users switch active tabs.
  
  Future<void> _preloadOtherMetrics() async {
    final _DateRange range = _getDateRange(_selectedPeriod, _windowOffset);
    final provider = context.read<DataProvider>();

    for (int i = 0; i < _metricCatalog.length; i++) {
      if (i == _selectedMetricIndex) continue;

      final metric = _metricCatalog[i];
      final String cacheKey = _makeCacheKey(
        metric.apiMetric,
        _selectedPeriod,
        _windowOffset,
      );

      if (_metricCache.containsKey(cacheKey)) continue;

      try {
        List<MetricPoint> data;

        if (_selectedPeriod == _TrendPeriod.day) {
          if (metric.apiMetric == 'stress') {
            data = await provider.fetchCalculatedStressSingleDay(range.start);
          } else {
            data = await provider.fetchSingleDayMetric(
              metric.apiMetric,
              range.start,
            );
          }
        } else {
          if (metric.apiMetric == 'stress') {
            data = await provider.fetchCalculatedStressRange(
              range.start,
              range.end,
            );
          } else {
            data = await provider.fetchMetricRange(
              metric.apiMetric,
              range.start,
              range.end,
            );
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
    final bool isItalian = context.watch<SettingsProvider>().isItalian;
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final TextTheme textTheme = Theme.of(context).textTheme;

    final bool isLoading = _isLoading || dataProvider.isLoading;
    final List<MetricPoint> displayPoints = _currentPoints;

    final Color accentColor = _selectedMetric.resolveColor(scheme);
    final String windowLabel = _windowLabel.isNotEmpty
        ? _windowLabel
        : _labelCache[_cacheKey] ?? 'No range';

    return Scaffold(
      appBar: AppBar(
        title: Text(
          isItalian ? 'Analisi e Trend' : 'Analysis & Trends',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 18),
          children: [
            Text(
              isItalian
                  ? 'Ciao ${userDataProvider.firstName}, esplora le tue metriche di benessere.'
                  : 'Hi ${userDataProvider.firstName}, explore your well-being metrics.',
              style: textTheme.bodyMedium?.copyWith(
                color: scheme.onSurfaceRole.withValues(alpha: 0.72),
              ),
            ),
            const SizedBox(height: 18),
            _TimePeriodSelector(
              selectedPeriod: _selectedPeriod,
              onPeriodChanged: _selectPeriod,
              isItalian: isItalian,
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
                child: Column( crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${isItalian ? _selectedMetric.nameIt : _selectedMetric.name} Trend (${_selectedPeriod.label(isItalian)})',
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
                                _errorMessage == 'offline'
                                    ? (isItalian
                                          ? 'Sei offline.'
                                          : 'You are offline.')
                                    : (isItalian
                                          ? 'Nessun dato registrato in questo periodo.'
                                          : 'No data found for this period.'),
                                style: textTheme.bodySmall?.copyWith(
                                  color: scheme.onSurfaceRole.withValues(
                                    alpha: 0.72,
                                  ),
                                ),
                              ),
                            )


                          /// KEY POINT 5: Conditional UI Presentation Layout
                          /// Renders a dedicated single-value card widget for intraday metrics (Sleep/Stress) 
                          /// instead of building a line chart which requires multiple points to display data.
                          
                          : ((_selectedMetric.apiMetric == 'sleep' ||
                                    _selectedMetric.apiMetric == 'stress') &&
                                _selectedPeriod == _TrendPeriod.day)
                          ? _DailySummaryCard(
                              metricId: _selectedMetric.apiMetric,
                              value: displayPoints.first.value,
                              accentColor: accentColor,
                              isItalian: isItalian,
                            )
                          : IgnorePointer(
                              ignoring: _selectedPeriod == _TrendPeriod.day,
                              child: _MetricTrendChart(
                                points: displayPoints,
                                accentColor: accentColor,
                                textColor: scheme.onSurfaceRole,
                                unit: _selectedMetric.unit,
                                metricId: _selectedMetric.apiMetric,
                                isItalian: isItalian,
                                isDayView: _selectedPeriod == _TrendPeriod.day,
                                highlightedIndex: _highlightedPointIndex,
                                enableTouch:
                                    _selectedPeriod != _TrendPeriod.day,
                                maxLabels: _selectedPeriod == _TrendPeriod.day
                                    ? 6
                                    : null,
                                onPointSelected: (index) => setState(
                                  () => _highlightedPointIndex = index,
                                ),
                              ),
                            ),
                    ),
                  ],
                ),
              ),
            ),
            if (displayPoints.isNotEmpty ||
                _selectedPeriod != _TrendPeriod.day) ...[
              const SizedBox(height: 16),
              Text(
                isItalian ? 'Altre Metriche' : 'Other Well-being Metrics',
                style: textTheme.titleMedium,
              ),
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

                final MetricPoint? latest = metricPoints.isNotEmpty
                    ? metricPoints.last
                    : null;
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
                      color: isSelected ? metricColor : scheme.outlineVariant,
                    ),
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () {
                      if (isSelected) {
                        setState(() {
                          _expandedMetricIndex = _expandedMetricIndex == index
                              ? null
                              : index;
                        });
                      } else {
                        setState(() {
                          _expandedMetricIndex = index;
                        });
                        _selectMetric(index);
                      }
                    },
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
                                backgroundColor: metricColor.withValues(
                                  alpha: 0.14,
                                ),
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
                                      isItalian ? metric.nameIt : metric.name,
                                      style: textTheme.titleSmall,
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${latest == null ? '--' : _formatMetricValue(latest.value, metric.unit)} • ${isItalian ? metric.statusLabelIt : metric.statusLabel}',
                                      style: textTheme.bodySmall?.copyWith(
                                        color: scheme.onSurfaceRole.withValues(
                                          alpha: 0.72,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Icon(
                                _expandedMetricIndex == index
                                    ? Icons.expand_less
                                    : Icons.chevron_right,
                                color: scheme.onSurfaceRole.withValues(
                                  alpha: 0.62,
                                ),
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
                                        _errorMessage == 'offline'
                                            ? (isItalian
                                                  ? 'Sei offline.'
                                                  : 'You are offline.')
                                            : (isItalian
                                                  ? 'Nessun dato registrato in questo periodo.'
                                                  : 'No data found for this period.'),
                                        style: textTheme.bodySmall?.copyWith(
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
                                        children: metricPoints.asMap().entries.map((
                                          entry,
                                        ) {
                                          final int pointIdx = entry.key;
                                          final MetricPoint point = entry.value;
                                          final bool isHighlighted =
                                              _highlightedPointIndex ==
                                              pointIdx;

                                          return ChoiceChip(
                                            selected: isHighlighted,
                                            onSelected: (selected) {
                                              setState(() {
                                                _highlightedPointIndex =
                                                    selected ? pointIdx : null;
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
                                            backgroundColor: scheme.surfaceRole
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
                            crossFadeState:
                                (_expandedMetricIndex == index &&
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

// --- SUPPORT CLASSES ---
enum _TrendPeriod { day, week }

extension on _TrendPeriod {
  String label(bool isItalian) {
    switch (this) {
      case _TrendPeriod.day:
        return isItalian ? 'Giorno' : 'Day';
      case _TrendPeriod.week:
        return isItalian ? 'Settimana' : 'Week';
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
    required this.nameIt,
    required this.unit,
    required this.icon,
    required this.statusLabel,
    required this.statusLabelIt,
    required this.tone,
  });

  final String apiMetric;
  final String name;
  final String nameIt;
  final String unit;
  final IconData icon;
  final String statusLabel;
  final String statusLabelIt;
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

// --- SUPPORT WIDGETS ---
class _TimePeriodSelector extends StatelessWidget {
  const _TimePeriodSelector({
    required this.selectedPeriod,
    required this.onPeriodChanged,
    required this.isItalian,
  });

  final _TrendPeriod selectedPeriod;
  final ValueChanged<_TrendPeriod> onPeriodChanged;
  final bool isItalian;

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
                color: isSelected ? scheme.onPrimary : scheme.onSurfaceRole,
              ),
            ),
          ),
        ),
      );
    }

    return Row(
      children: [
        Text(
          isItalian ? 'PERIODO' : 'TIME PERIOD',
          style: Theme.of(context).textTheme.labelSmall,
        ),
        const Spacer(),
        Container(
          width: 150,
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: scheme.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              segment(
                period: _TrendPeriod.day,
                label: isItalian ? 'GIORNO' : 'DAY',
              ),
              segment(
                period: _TrendPeriod.week,
                label: isItalian ? 'SETT' : 'WEEK',
              ),
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

class _MetricTrendChart extends StatelessWidget {
  const _MetricTrendChart({
    required this.points,
    required this.accentColor,
    required this.textColor,
    required this.unit,
    required this.metricId,
    required this.isItalian,
    required this.isDayView,
    this.highlightedIndex,
    required this.onPointSelected,
    this.enableTouch = true,
    this.maxLabels,
  });

  final List<MetricPoint> points;
  final Color accentColor;
  final Color textColor;
  final String unit;
  final String metricId;
  final bool isItalian;
  final bool isDayView;
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
          isItalian
              ? 'Dati insufficienti per il grafico.'
              : 'Not enough data points to draw a line chart.',
          style: TextStyle(color: textColor.withValues(alpha: 0.6)),
        ),
      );
    }

    final double minValue = points
        .map((p) => p.value)
        .reduce((a, b) => a < b ? a : b);
    final double maxValue = points
        .map((p) => p.value)
        .reduce((a, b) => a > b ? a : b);

    // Default configuration variables
    double effectiveMinY = 0.0;
    double effectiveMaxY = 100.0;
    double intervalY = 25.0;

    /// Metric Domain Hardcoded Bounds Calibration
    /// Establishes mathematical, stable viewport heights and scale segments 
    /// tailored to the physiological reality of each biometric domain.
    /// This keeps charts visually readable, scaling appropriately for each metric.
    
    if (metricId == 'stress') {
      effectiveMinY = 0.0;
      effectiveMaxY = 100.0;
      intervalY = 25.0;
    } else if (metricId == 'sleep') {
      effectiveMinY = 0.0;
      effectiveMaxY = maxValue <= 8.0 ? 10.0 : (maxValue + 2.0).ceilToDouble();
      intervalY = (effectiveMaxY / 5).ceilToDouble();
    } else if (metricId == 'steps') {
      if (isDayView) {
        effectiveMinY = 0.0;
        effectiveMaxY = maxValue < 20 ? 20.0 : _niceCeil(maxValue + 5.0, 5.0);
        intervalY = effectiveMaxY / 4;
      } else {
        effectiveMinY = 0.0;
        effectiveMaxY = maxValue <= 8000.0
            ? 10000.0
            : _niceCeil(maxValue + 2000.0, 2000.0);
        intervalY = effectiveMaxY / 4;
      }
    } else if (metricId == 'heart_rate') {
      effectiveMinY = minValue >= 50.0
          ? 40.0
          : (minValue < 10.0 ? 0.0 : ((minValue - 10.0) / 10.0).floor() * 10.0);
      effectiveMaxY = maxValue <= 120.0
          ? 140.0
          : _niceCeil(maxValue + 20.0, 10.0);
      intervalY = _niceCeil((effectiveMaxY - effectiveMinY) / 4, 5.0);
    }

    if (intervalY <= 0) intervalY = 1.0;
    if (effectiveMinY >= effectiveMaxY) effectiveMaxY = effectiveMinY + 1.0;

    double intervalX = 1.0;
    if (maxLabels != null && maxLabels! > 0 && points.length > maxLabels!) {
      intervalX = (points.length / maxLabels!).ceilToDouble();
    }
    if (intervalX <= 0) intervalX = 1.0;

    return LineChart(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      LineChartData(
        minY: effectiveMinY,
        maxY: effectiveMaxY,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: intervalY,
          getDrawingHorizontalLine: (value) =>
              FlLine(color: textColor.withValues(alpha: 0.16), strokeWidth: 1),
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
                      touchResponse.lineBarSpots!.first.spotIndex,
                    );
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
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 38,
              interval: intervalY,
              getTitlesWidget: (value, meta) {
                return Text(
                  _formatAxisValue(value),
                  maxLines: 1,
                  softWrap: false,
                  overflow: TextOverflow.visible,
                  style: TextStyle(fontSize: 10, color: textColor),
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 25,
              interval: intervalX,
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
                  final int step = (points.length / maxLabels!).ceil().clamp(
                    1,
                    points.length,
                  );

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

/// Formats a metric value with its unit, applying specific formatting rules based on the unit type.
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

String _formatAxisValue(double value) {
  final int intValue = value.round();
  final int absValue = intValue.abs();

  if (absValue < 1000) {
    return intValue.toString();
  }

  final double thousands = intValue / 1000.0;
  final String formatted = thousands == thousands.roundToDouble()
      ? thousands.toStringAsFixed(0)
      : thousands.toStringAsFixed(1);

  return '${formatted}k';
}

double _niceCeil(double value, double step) {
  if (step <= 0) return value;
  return (value / step).ceil() * step;
}

const List<_MetricDefinition> _metricCatalog = [
  _MetricDefinition(
    apiMetric: 'stress',
    name: 'Stress Index',
    nameIt: 'Indice di Stress',
    unit: '/100',
    icon: Icons.monitor_heart_outlined,
    statusLabel: 'Balanced',
    statusLabelIt: 'Bilanciato',
    tone: _MetricTone.highlight,
  ),
  _MetricDefinition(
    apiMetric: 'heart_rate',
    name: 'Heart Rate',
    nameIt: 'Battito Cardiaco',
    unit: 'bpm',
    icon: Icons.favorite_border,
    statusLabel: 'Weekly Average',
    statusLabelIt: 'Media Settimanale',
    tone: _MetricTone.danger,
  ),
  _MetricDefinition(
    apiMetric: 'sleep',
    name: 'Sleep Hours',
    nameIt: 'Ore di Sonno',
    unit: 'h',
    icon: Icons.nightlight_round,
    statusLabel: 'Sleep Hours',
    statusLabelIt: 'Ore di Sonno',
    tone: _MetricTone.steady,
  ),
  _MetricDefinition(
    apiMetric: 'steps',
    name: 'Step Count',
    nameIt: 'Conteggio Passi',
    unit: 'steps',
    icon: Icons.directions_walk,
    statusLabel: 'Daily Goal Tracking',
    statusLabelIt: 'Progresso Giornaliero',
    tone: _MetricTone.highlight,
  ),
];

// Defines a card widget that displays a daily summary for specific metrics like sleep and stress, 
//including an icon, main value, and descriptive text.

class _DailySummaryCard extends StatelessWidget {
  const _DailySummaryCard({
    required this.metricId,
    required this.value,
    required this.accentColor,
    required this.isItalian,
  });

  final String metricId;
  final double value;
  final Color accentColor;
  final bool isItalian;

  Color _getStressColor(double level, Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    if (level < 30) {
      return isDark ? const Color(0xFF6EE7A0) : const Color(0xFF166534);
    }
    if (level < 60) {
      return isDark ? const Color(0xFFFDE68A) : const Color(0xFF92400E);
    }
    if (level < 80) {
      return isDark ? const Color(0xFFFBBF24) : const Color(0xFF9A3412);
    }
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
      subText = isItalian ? 'Tempo di sonno totale' : 'Total sleep time';
    } else if (metricId == 'stress') {
      icon = Icons.monitor_heart_outlined;
      mainText = '${value.round()}/100';
      subText = isItalian
          ? 'Stress Giornaliero Calcolato'
          : 'Calculated Daily Stress';
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
