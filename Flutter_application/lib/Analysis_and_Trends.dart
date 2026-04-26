import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

void main() {
  runApp(const StressApp());
}

class StressApp extends StatelessWidget {
  // StatelessWidget since the main app doesn't hold mutable state
  const StressApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Stress Monitor & Muscle Preservation',
      theme: ThemeData(useMaterial3: true), // Material3 can be changed 
      home: const MainNavigationShell(),
    );
  }
}

// Extension to provide semantic color roles based on the ColorScheme
extension SemanticRoles on ColorScheme {
  Color get highlight => primary;
  Color get danger => error;
  Color get steady => tertiary;
  Color get surfaceRole => surface;
  Color get onSurfaceRole => onSurface;
}

// Extension to easily adjust alpha values of colors
class MainNavigationShell extends StatefulWidget {
  const MainNavigationShell({super.key});

  @override
  State<MainNavigationShell> createState() => _MainNavigationShellState();
}

// The main navigation shell with a bottom navigation bar and IndexedStack for screen management
class _MainNavigationShellState extends State<MainNavigationShell> {
  int _currentIndex = 1;

  final List<Widget> _screens = const [
    _PlaceholderScreen(
      title: 'Home',
      subtitle: 'Immediate feedback and contextual alerts will appear here.',
    ),
    AnalysisAndTrendsScreen(),
    _PlaceholderScreen(
      title: 'Recovery',
      subtitle: 'Quick exercises and check-ins will appear here.',
    ),
    _PlaceholderScreen(
      title: 'Profile',
      subtitle: 'Personal data and privacy controls will appear here.',
    ),
  ];

  // The build method constructs the Scaffold with an IndexedStack to maintain the state of each screen and a BottomNavigationBar for navigation
  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        selectedItemColor: scheme.highlight,
        unselectedItemColor: scheme.onSurfaceRole.withValues(alpha: 0.7),
        onTap: (int index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.analytics_outlined),
            activeIcon: Icon(Icons.analytics),
            label: 'Analysis & Trends',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.self_improvement_outlined),
            activeIcon: Icon(Icons.self_improvement),
            label: 'Recovery',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.privacy_tip_outlined),
            activeIcon: Icon(Icons.privacy_tip),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

// The Analysis & Trends screen with metric selection, trend visualization, and window navigation
class AnalysisAndTrendsScreen extends StatefulWidget {
  const AnalysisAndTrendsScreen({super.key});

  @override
  State<AnalysisAndTrendsScreen> createState() =>
      _AnalysisAndTrendsScreenState();
}

// State class for the Analysis & Trends screen, managing selected metric, time period, and window index, and building the UI accordingly
class _AnalysisAndTrendsScreenState extends State<AnalysisAndTrendsScreen> {
  int _selectedMetricIndex = 0;
  _TrendPeriod _selectedPeriod = _TrendPeriod.week;   // Default to week view
  int _selectedWindowIndex = 0;

  _MetricDefinition get _selectedMetric => _metrics[_selectedMetricIndex];

  List<_MetricWindow> get _selectedWindows =>
      _selectedMetric.windows[_selectedPeriod]!;

  _MetricWindow get _selectedWindow => _selectedWindows[_selectedWindowIndex];

  bool get _canGoToPreviousWindow => _selectedWindowIndex > 0;

  bool get _canGoToNextWindow =>
      _selectedWindowIndex < _selectedWindows.length - 1;
  
  // Helper methods that handles the metrics and time period selection, as well as navigating between different time windows of the trend data, updating the state accordingly to trigger UI updates
  void _selectMetric(int index) {
    setState(() {
      _selectedMetricIndex = index;
      _selectedWindowIndex = 0;
    });
  }

  // When the user selects a different time period (week or month), this method updates the selected period and resets the window index to show the first window of the newly selected period
  void _selectPeriod(_TrendPeriod period) {
    if (_selectedPeriod == period) {
      return;
    }

    // Reset to the first window of the newly selected period when changing the period
    setState(() {
      _selectedPeriod = period;
      _selectedWindowIndex = 0;
    });
  }
  // This method handles the navigation between different time windows (e.g., different weeks or months) of the trend data. It checks if the navigation is valid (not going out of bounds) and updates the selected window index accordingly to show the new window's data in the UI
  void _moveWindow(int delta) {
    final int candidate = _selectedWindowIndex + delta;
    if (candidate < 0 || candidate >= _selectedWindows.length) {
      return;
    }
    // Update the selected window index to show the new window's data in the UI when navigating between windows
    setState(() {
      _selectedWindowIndex = candidate;
    });
  }
  // The build method constructs the UI for the Analysis & Trends screen, including the header, time period selector, window navigator, trend chart, and metric selection list, using the current state to determine what data to display and how to style it
  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final TextTheme textTheme = Theme.of(context).textTheme;
    final _WindowStats stats = _WindowStats.fromPoints(_selectedWindow.points);
    final Color accentColor = _selectedMetric.resolveColor(scheme);

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 18),
          children: [
            Text('Analysis & Trends, Alex (Username)', style: textTheme.headlineSmall),
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
              label: _selectedWindow.label,
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
                      child: _MetricTrendChart(
                        points: _selectedWindow.points,
                        accentColor: accentColor,
                        textColor: scheme.onSurfaceRole,
                        unit: _selectedMetric.unit,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: _StatValue(
                            title: _selectedPeriod == _TrendPeriod.week
                                ? 'Weekly Average'
                                : 'Monthly Average',
                            value: _formatMetricValue(
                              stats.average,
                              _selectedMetric.unit,
                            ),
                          ),
                        ),
                        Expanded(
                          child: _StatValue(
                            title: 'Highest Day',
                            value:
                                '${stats.maxPoint.fullLabel} (${_formatMetricValue(stats.maxPoint.value, _selectedMetric.unit)})',
                          ),
                        ),
                        Expanded(
                          child: _StatValue(
                            title: 'Lowest Day',
                            value:
                                '${stats.minPoint.fullLabel} (${_formatMetricValue(stats.minPoint.value, _selectedMetric.unit)})',
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text('Other Well-being Metrics', style: textTheme.titleMedium),
            const SizedBox(height: 8),
            ...List<Widget>.generate(_metrics.length, (int index) {
              final _MetricDefinition metric = _metrics[index];
              final bool isSelected = index == _selectedMetricIndex;
              final _MetricWindow weekWindow =
                  metric.windows[_TrendPeriod.week]!.first;
              final _MetricPoint latest = weekWindow.points.last;
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
                                    metric.name,
                                    style: textTheme.titleSmall,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${_formatMetricValue(latest.value, metric.unit)} • ${metric.statusLabel}',
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
                              isSelected
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
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: Wrap(
                                spacing: 7,
                                runSpacing: 7,
                                children: weekWindow.points.map((point) {
                                  return Chip(
                                    visualDensity: VisualDensity.compact,
                                    side: BorderSide(
                                      color: scheme.outlineVariant,
                                    ),
                                    backgroundColor: scheme.surfaceRole
                                        .withValues(alpha: 0.8),
                                    label: Text(
                                      '${point.fullLabel}: ${_formatMetricValue(point.value, metric.unit)}',
                                      style: textTheme.bodySmall,
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                          ),
                          crossFadeState: isSelected
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
        ),
      ),
    );
  }
}

// Placeholder screen for the other tabs
class _PlaceholderScreen extends StatelessWidget {
  const _PlaceholderScreen({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(title, style: textTheme.headlineSmall),
              const SizedBox(height: 8),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: textTheme.bodyLarge,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Enumerations and data classes to represent the trend periods, metric tones, metric points, windows, and definitions, along with helper methods for formatting values and resolving colors based on the theme
enum _TrendPeriod { week, month }

// Extension to provide user-friendly labels for the trend periods
extension on _TrendPeriod {
  String get label => this == _TrendPeriod.week ? 'Week' : 'Month'; // Maybe we can add year with enough data...
}

// Enumeration to represent the tone of a metric (e.g., highlight, steady, danger) which can be used to determine the color scheme for displaying the metric in the UI
enum _MetricTone { highlight, steady, danger }


// Data class with fields for short label, full label, and value, representing a single data point for a metric (e.g., a specific day's value for the stress index)
class _MetricPoint {
  const _MetricPoint({
    required this.shortLabel,
    required this.fullLabel,
    required this.value,
  });

  final String shortLabel;
  final String fullLabel;
  final double value;
}

// Data class representing a time window for a metric, containing a label (e.g., "Oct 21 - Oct 27") and a list of metric points that fall within that window, which can be used to display the trend data for that specific time period in the UI
class _MetricWindow {
  const _MetricWindow({required this.label, required this.points});

  final String label;
  final List<_MetricPoint> points;
}

// data class with metric definitions, including the name, unit, icon, status label, tone, and a map of trend periods to lists of metric windows, along with a method to resolve the appropriate color based on the metric's tone and the current theme's color scheme
class _MetricDefinition {
  const _MetricDefinition({
    required this.name,
    required this.unit,
    required this.icon,
    required this.statusLabel,
    required this.tone,
    required this.windows,
  });

  final String name;
  final String unit;
  final IconData icon;
  final String statusLabel;
  final _MetricTone tone;
  final Map<_TrendPeriod, List<_MetricWindow>> windows;

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
  final _MetricPoint maxPoint;
  final _MetricPoint minPoint;

  factory _WindowStats.fromPoints(List<_MetricPoint> points) {
    final _MetricPoint maxPoint = points.reduce(
      (left, right) => left.value >= right.value ? left : right,
    );
    final _MetricPoint minPoint = points.reduce(
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

// Widget to allow users to toggle between different time periods (week and month) for viewing the trend data, with visual feedback to indicate the currently selected period and a callback to notify the parent widget of changes in the selected period
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
                fontSize: 12,
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
        Text('TIME PERIOD', style: Theme.of(context).textTheme.labelSmall),
        const Spacer(),
        Container(
          width: 132,
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: scheme.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              segment(period: _TrendPeriod.week, label: 'WEEK'),
              segment(period: _TrendPeriod.month, label: 'MONTH'),
            ],
          ),
        ),
      ],
    );
  }
}

// Widget to navigate between different time windows (e.g., different weeks or months) of the trend data, with buttons to go to the previous and next windows and a label to indicate the currently selected window, along with callbacks to notify the parent widget when the user wants to navigate to a different window
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

// ----------------------- Stat Value Widget ---------------------

// Widget to display a metric's value along with a title, used in the stats section below the trend chart
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
        Text(value, textAlign: TextAlign.center, style: textTheme.titleSmall),
      ],
    );
  }
}

// ---------------------- Line Chart Widget ---------------------

// Line chart widget that visualizes the trend of a metric over the selected time window
class _MetricTrendChart extends StatelessWidget {
  const _MetricTrendChart({
    required this.points,
    required this.accentColor,
    required this.textColor,
    required this.unit,
  });

  final List<_MetricPoint> points;
  final Color accentColor;
  final Color textColor;
  final String unit;

  @override
  Widget build(BuildContext context) {
    final double minValue = points
        .map((point) => point.value)
        .reduce((a, b) => a < b ? a : b);
    final double maxValue = points
        .map((point) => point.value)
        .reduce((a, b) => a > b ? a : b);
    final double range = (maxValue - minValue).abs();
    final double padding = range < 8 ? 4 : range * 0.2;
    final double interval = ((maxValue + padding) - (minValue - padding)) / 4;

    // Linechart with customized axes, grid lines, and tooltips to show metric values on hover
    return LineChart(
      duration: const Duration(milliseconds: 300), // Animate changes when switching windows
      curve: Curves.easeInOut,  // Use a smooth curve for the animation
      LineChartData(
        minY: minValue - padding,  // Add padding to the min and max values for better visual spacing
        maxY: maxValue + padding,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: interval,
          getDrawingHorizontalLine: (value) =>
              FlLine(color: textColor.withValues(alpha: 0.16), strokeWidth: 1),
        ),
        borderData: FlBorderData(show: false),
        lineTouchData: LineTouchData(
          enabled: true,
          handleBuiltInTouches: true,
          touchTooltipData: LineTouchTooltipData(
            fitInsideHorizontally: true,
            fitInsideVertically: true,
            getTooltipItems: (spots) {
              return spots.map((spot) {
                final int index = spot.x.toInt();
                final _MetricPoint point = points[index];
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
              reservedSize: 34,
              interval: interval,
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
              getTitlesWidget: (value, meta) {
                final int index = value.toInt();
                if (index < 0 || index >= points.length) {
                  return const SizedBox.shrink();
                }

                return Padding(
                  padding: const EdgeInsets.only(top: 5),
                  child: Text(
                    points[index].shortLabel,
                    style: TextStyle(fontSize: 11, color: textColor),
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
                return FlDotCirclePainter(
                  radius: 3.4,
                  color: accentColor,
                  strokeWidth: 1,
                  strokeColor: textColor.withValues(alpha: 0.35),
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

// ----------------------------- DATA DEFINITIONS -----------------

// Helper function to format metric values with appropriate units and decimal places
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

// ----------------------- Hardcoded data and metrics ---------------

// Hardcoded metric definitions with sample data for demonstration purposes
const List<_MetricDefinition> _metrics = [
  _MetricDefinition(
    name: 'Stress Index',
    unit: '/100',
    icon: Icons.monitor_heart_outlined,
    statusLabel: 'Balanced',
    tone: _MetricTone.highlight,
    windows: {
      _TrendPeriod.week: [
        _MetricWindow(
          label: 'Oct 21 - Oct 27',
          points: [
            _MetricPoint(shortLabel: 'M', fullLabel: 'Mon', value: 65),
            _MetricPoint(shortLabel: 'T', fullLabel: 'Tue', value: 74),
            _MetricPoint(shortLabel: 'W', fullLabel: 'Wed', value: 63),
            _MetricPoint(shortLabel: 'T', fullLabel: 'Thu', value: 76),
            _MetricPoint(shortLabel: 'F', fullLabel: 'Fri', value: 70),
            _MetricPoint(shortLabel: 'S', fullLabel: 'Sat', value: 51),
            _MetricPoint(shortLabel: 'S', fullLabel: 'Sun', value: 68),
          ],
        ),
        _MetricWindow(
          label: 'Oct 28 - Nov 03',
          points: [
            _MetricPoint(shortLabel: 'M', fullLabel: 'Mon', value: 63),
            _MetricPoint(shortLabel: 'T', fullLabel: 'Tue', value: 71),
            _MetricPoint(shortLabel: 'W', fullLabel: 'Wed', value: 66),
            _MetricPoint(shortLabel: 'T', fullLabel: 'Thu', value: 73),
            _MetricPoint(shortLabel: 'F', fullLabel: 'Fri', value: 69),
            _MetricPoint(shortLabel: 'S', fullLabel: 'Sat', value: 55),
            _MetricPoint(shortLabel: 'S', fullLabel: 'Sun', value: 67),
          ],
        ),
      ],
      _TrendPeriod.month: [
        _MetricWindow(
          label: 'September 2026',
          points: [
            _MetricPoint(shortLabel: 'W1', fullLabel: 'Week 1', value: 70),
            _MetricPoint(shortLabel: 'W2', fullLabel: 'Week 2', value: 67),
            _MetricPoint(shortLabel: 'W3', fullLabel: 'Week 3', value: 72),
            _MetricPoint(shortLabel: 'W4', fullLabel: 'Week 4', value: 68),
          ],
        ),
        _MetricWindow(
          label: 'October 2026',
          points: [
            _MetricPoint(shortLabel: 'W1', fullLabel: 'Week 1', value: 69),
            _MetricPoint(shortLabel: 'W2', fullLabel: 'Week 2', value: 66),
            _MetricPoint(shortLabel: 'W3', fullLabel: 'Week 3', value: 71),
            _MetricPoint(shortLabel: 'W4', fullLabel: 'Week 4', value: 65),
          ],
        ),
      ],
    },
  ),
  _MetricDefinition(
    name: 'Heart Rate Variability',
    unit: 'ms',
    icon: Icons.favorite_border,
    statusLabel: 'Weekly Average',
    tone: _MetricTone.danger,
    windows: {
      _TrendPeriod.week: [
        _MetricWindow(
          label: 'Oct 21 - Oct 27',
          points: [
            _MetricPoint(shortLabel: 'M', fullLabel: 'Mon', value: 58),
            _MetricPoint(shortLabel: 'T', fullLabel: 'Tue', value: 63),
            _MetricPoint(shortLabel: 'W', fullLabel: 'Wed', value: 60),
            _MetricPoint(shortLabel: 'T', fullLabel: 'Thu', value: 62),
            _MetricPoint(shortLabel: 'F', fullLabel: 'Fri', value: 64),
            _MetricPoint(shortLabel: 'S', fullLabel: 'Sat', value: 57),
            _MetricPoint(shortLabel: 'S', fullLabel: 'Sun', value: 61),
          ],
        ),
        _MetricWindow(
          label: 'Oct 28 - Nov 03',
          points: [
            _MetricPoint(shortLabel: 'M', fullLabel: 'Mon', value: 57),
            _MetricPoint(shortLabel: 'T', fullLabel: 'Tue', value: 62),
            _MetricPoint(shortLabel: 'W', fullLabel: 'Wed', value: 59),
            _MetricPoint(shortLabel: 'T', fullLabel: 'Thu', value: 61),
            _MetricPoint(shortLabel: 'F', fullLabel: 'Fri', value: 63),
            _MetricPoint(shortLabel: 'S', fullLabel: 'Sat', value: 58),
            _MetricPoint(shortLabel: 'S', fullLabel: 'Sun', value: 60),
          ],
        ),
      ],
      _TrendPeriod.month: [
        _MetricWindow(
          label: 'September 2026',
          points: [
            _MetricPoint(shortLabel: 'W1', fullLabel: 'Week 1', value: 61),
            _MetricPoint(shortLabel: 'W2', fullLabel: 'Week 2', value: 60),
            _MetricPoint(shortLabel: 'W3', fullLabel: 'Week 3', value: 62),
            _MetricPoint(shortLabel: 'W4', fullLabel: 'Week 4', value: 59),
          ],
        ),
        _MetricWindow(
          label: 'October 2026',
          points: [
            _MetricPoint(shortLabel: 'W1', fullLabel: 'Week 1', value: 60),
            _MetricPoint(shortLabel: 'W2', fullLabel: 'Week 2', value: 61),
            _MetricPoint(shortLabel: 'W3', fullLabel: 'Week 3', value: 58),
            _MetricPoint(shortLabel: 'W4', fullLabel: 'Week 4', value: 62),
          ],
        ),
      ],
    },
  ),
  _MetricDefinition(
    name: 'Sleep Hours',
    unit: 'h',
    icon: Icons.nightlight_round,
    statusLabel: 'Sleep Hours',
    tone: _MetricTone.steady,
    windows: {
      _TrendPeriod.week: [
        _MetricWindow(
          label: 'Oct 21 - Oct 27',
          points: [
            _MetricPoint(shortLabel: 'M', fullLabel: 'Mon', value: 6.6),
            _MetricPoint(shortLabel: 'T', fullLabel: 'Tue', value: 7.2),
            _MetricPoint(shortLabel: 'W', fullLabel: 'Wed', value: 6.8),
            _MetricPoint(shortLabel: 'T', fullLabel: 'Thu', value: 7.4),
            _MetricPoint(shortLabel: 'F', fullLabel: 'Fri', value: 7.1),
            _MetricPoint(shortLabel: 'S', fullLabel: 'Sat', value: 6.0),
            _MetricPoint(shortLabel: 'S', fullLabel: 'Sun', value: 7.5),
          ],
        ),
        _MetricWindow(
          label: 'Oct 28 - Nov 03',
          points: [
            _MetricPoint(shortLabel: 'M', fullLabel: 'Mon', value: 6.9),
            _MetricPoint(shortLabel: 'T', fullLabel: 'Tue', value: 7.1),
            _MetricPoint(shortLabel: 'W', fullLabel: 'Wed', value: 6.7),
            _MetricPoint(shortLabel: 'T', fullLabel: 'Thu', value: 7.3),
            _MetricPoint(shortLabel: 'F', fullLabel: 'Fri', value: 7.0),
            _MetricPoint(shortLabel: 'S', fullLabel: 'Sat', value: 6.2),
            _MetricPoint(shortLabel: 'S', fullLabel: 'Sun', value: 7.4),
          ],
        ),
      ],
      _TrendPeriod.month: [
        _MetricWindow(
          label: 'September 2026',
          points: [
            _MetricPoint(shortLabel: 'W1', fullLabel: 'Week 1', value: 6.9),
            _MetricPoint(shortLabel: 'W2', fullLabel: 'Week 2', value: 7.1),
            _MetricPoint(shortLabel: 'W3', fullLabel: 'Week 3', value: 6.8),
            _MetricPoint(shortLabel: 'W4', fullLabel: 'Week 4', value: 7.0),
          ],
        ),
        _MetricWindow(
          label: 'October 2026',
          points: [
            _MetricPoint(shortLabel: 'W1', fullLabel: 'Week 1', value: 7.0),
            _MetricPoint(shortLabel: 'W2', fullLabel: 'Week 2', value: 6.7),
            _MetricPoint(shortLabel: 'W3', fullLabel: 'Week 3', value: 7.2),
            _MetricPoint(shortLabel: 'W4', fullLabel: 'Week 4', value: 6.9),
          ],
        ),
      ],
    },
  ),
  _MetricDefinition(
    name: 'Step Count',
    unit: 'steps',
    icon: Icons.directions_walk,
    statusLabel: 'Daily Goal Tracking',
    tone: _MetricTone.highlight,
    windows: {
      _TrendPeriod.week: [
        _MetricWindow(
          label: 'Oct 21 - Oct 27',
          points: [
            _MetricPoint(shortLabel: 'M', fullLabel: 'Mon', value: 7100),
            _MetricPoint(shortLabel: 'T', fullLabel: 'Tue', value: 8100),
            _MetricPoint(shortLabel: 'W', fullLabel: 'Wed', value: 7600),
            _MetricPoint(shortLabel: 'T', fullLabel: 'Thu', value: 8800),
            _MetricPoint(shortLabel: 'F', fullLabel: 'Fri', value: 8400),
            _MetricPoint(shortLabel: 'S', fullLabel: 'Sat', value: 6200),
            _MetricPoint(shortLabel: 'S', fullLabel: 'Sun', value: 7900),
          ],
        ),
        _MetricWindow(
          label: 'Oct 28 - Nov 03',
          points: [
            _MetricPoint(shortLabel: 'M', fullLabel: 'Mon', value: 7350),
            _MetricPoint(shortLabel: 'T', fullLabel: 'Tue', value: 8250),
            _MetricPoint(shortLabel: 'W', fullLabel: 'Wed', value: 7750),
            _MetricPoint(shortLabel: 'T', fullLabel: 'Thu', value: 8700),
            _MetricPoint(shortLabel: 'F', fullLabel: 'Fri', value: 8500),
            _MetricPoint(shortLabel: 'S', fullLabel: 'Sat', value: 6450),
            _MetricPoint(shortLabel: 'S', fullLabel: 'Sun', value: 8050),
          ],
        ),
      ],
      _TrendPeriod.month: [
        _MetricWindow(
          label: 'September 2026',
          points: [
            _MetricPoint(shortLabel: 'W1', fullLabel: 'Week 1', value: 7600),
            _MetricPoint(shortLabel: 'W2', fullLabel: 'Week 2', value: 7900),
            _MetricPoint(shortLabel: 'W3', fullLabel: 'Week 3', value: 7450),
            _MetricPoint(shortLabel: 'W4', fullLabel: 'Week 4', value: 8050),
          ],
        ),
        _MetricWindow(
          label: 'October 2026',
          points: [
            _MetricPoint(shortLabel: 'W1', fullLabel: 'Week 1', value: 7850),
            _MetricPoint(shortLabel: 'W2', fullLabel: 'Week 2', value: 7700),
            _MetricPoint(shortLabel: 'W3', fullLabel: 'Week 3', value: 8150),
            _MetricPoint(shortLabel: 'W4', fullLabel: 'Week 4', value: 7800),
          ],
        ),
      ],
    },
  ),
];
