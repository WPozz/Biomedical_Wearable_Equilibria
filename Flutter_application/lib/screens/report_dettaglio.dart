import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_application/providers/settings_provider.dart';
import 'package:flutter_application/utils/weekly_report_model.dart';
import 'package:flutter_application/screens/goals.dart';

class ReportDetailScreen extends StatelessWidget {
  final WeeklyReport report;

  const ReportDetailScreen({super.key, required this.report});

  @override
  Widget build(BuildContext context) {
    final settings    = context.watch<SettingsProvider>();
    final isItalian   = settings.isItalian;
    final colorScheme = Theme.of(context).colorScheme;

    if (!report.hasData) {
      return _NoDataScreen(
        dateRangeIt: report.dateRangeIt,
        dateRangeEn: report.dateRangeEn,
        isItalian: isItalian,
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          isItalian ? 'Report Settimanale' : 'Weekly Report',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _WeekHeader(report: report, isItalian: isItalian),
              const SizedBox(height: 16),
              _ComparisonCard(report: report, isItalian: isItalian),
              const SizedBox(height: 24),
              _sectionTitle(
                  isItalian ? 'Indice di Stress' : 'Stress Index', context),
              const SizedBox(height: 10),
              _StressScoreRow(report: report, isItalian: isItalian),
              const SizedBox(height: 10),
              _StressBarChart(report: report, isItalian: isItalian),
              const SizedBox(height: 24),
              _sectionTitle(
                  isItalian ? 'Insight chiave' : 'Key insights', context),
              const SizedBox(height: 10),
              if (report.peakStressTimeRange != 'N/A') ...[
                _PeakTimeInsight(
                    report: report,
                    isItalian: isItalian,
                    colorScheme: colorScheme),
                const SizedBox(height: 10),
              ],
              _SleepInsight(
                  report: report,
                  isItalian: isItalian,
                  colorScheme: colorScheme),
              const SizedBox(height: 10),
              _MovementRecoveryInsight(
                  report: report,
                  isItalian: isItalian,
                  colorScheme: colorScheme),
              const SizedBox(height: 24),
              _sectionTitle(
                  isItalian ? 'Obiettivi settimana' : 'Weekly goals', context),
              const SizedBox(height: 10),
              if (report.goalsEnabled)
                _GoalsRow(report: report, isItalian: isItalian)
              else
                _GoalsDisabledCard(isItalian: isItalian),
              const SizedBox(height: 12),
              if (report.peakStressTimeRange != 'N/A')
                _TipCard(report: report, isItalian: isItalian),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(String text, BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.bold,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
        letterSpacing: 0.8,
      ),
    );
  }
}

// ─ No data screen ─────────────────────────────────────────────────────────────

class _NoDataScreen extends StatelessWidget {
  final String dateRangeIt;
  final String dateRangeEn;
  final bool isItalian;

  const _NoDataScreen({
    required this.dateRangeIt,
    required this.dateRangeEn,
    required this.isItalian,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          isItalian ? 'Report Settimanale' : 'Weekly Report',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.hourglass_empty_rounded,
                    size: 56, color: colorScheme.onSurfaceVariant),
                const SizedBox(height: 20),
                Text(
                  isItalian ? dateRangeIt : dateRangeEn,
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  isItalian
                      ? 'Nessun dato disponibile per questa settimana.\n'
                        'Il dispositivo potrebbe non aver registrato misurazioni in questo periodo.'
                      : 'No data available for this week.\n'
                        'The device may not have recorded measurements during this period.',
                  style: TextStyle(
                      fontSize: 15, color: colorScheme.onSurfaceVariant),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─ Comparison card ────────────────────────────────────────────────────────────

class _ComparisonCard extends StatelessWidget {
  final WeeklyReport report;
  final bool isItalian;
  const _ComparisonCard({required this.report, required this.isItalian});

  String _fmtSleepDelta(double minutes) {
    final bool positive = minutes >= 0;
    final double abs    = minutes.abs();
    final String sign   = positive ? '+' : '−';
    if (abs < 60) {
      return '$sign${abs.toStringAsFixed(0)} min';
    } else {
      final int h = (abs / 60).floor();
      final int m = (abs % 60).round();
      return m > 0 ? '$sign${h}h ${m}min' : '$sign${h}h';
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final stressDelta = report.stressDelta;
    final sleepDelta  = report.sleepDeltaMin;
    final stepsDelta  = report.stepsDelta;

    return Material(
      color: colorScheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(24),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isItalian
                  ? 'Rispetto alla settimana precedente'
                  : 'vs. previous week',
              style: TextStyle(
                  fontSize: 13, color: colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _ComparisonItem(
                    label: isItalian ? 'Stress' : 'Stress',
                    delta: stressDelta,
                    formatted:
                        '${stressDelta > 0 ? '+' : ''}${stressDelta.toStringAsFixed(0)} pt',
                    positiveIsGood: false,
                  ),
                ),
                Expanded(
                  child: report.sleepDeltaReliable
                      ? _ComparisonItem(
                          label: isItalian ? 'Sonno' : 'Sleep',
                          delta: sleepDelta,
                          formatted: _fmtSleepDelta(sleepDelta),
                          positiveIsGood: true,
                        )
                      : _ComparisonItemNA(
                          label: isItalian ? 'Sonno' : 'Sleep',
                          isItalian: isItalian,
                        ),
                ),
                Expanded(
                  child: _ComparisonItem(
                    label: isItalian ? 'Passi/giorno' : 'Steps/day',
                    delta: stepsDelta,
                    formatted:
                        '${stepsDelta > 0 ? '+' : ''}${(stepsDelta / 1000).toStringAsFixed(1)}k',
                    positiveIsGood: true,
                  ),
                ),
              ],
            ),
            if (report.missingSleepDays > 0) ...[
              const SizedBox(height: 12),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: colorScheme.errorContainer.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline,
                        size: 16, color: colorScheme.onErrorContainer),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        isItalian
                            ? 'Dati sonno mancanti per ${report.missingSleepDays} ${report.missingSleepDays == 1 ? 'giorno' : 'giorni'}: la media potrebbe essere imprecisa.'
                            : 'Sleep data missing for ${report.missingSleepDays} ${report.missingSleepDays == 1 ? 'day' : 'days'}: average may be inaccurate.',
                        style: TextStyle(
                            fontSize: 12,
                            color: colorScheme.onErrorContainer),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ComparisonItem extends StatelessWidget {
  final String label;
  final double delta;
  final String formatted;
  final bool positiveIsGood;

  const _ComparisonItem({
    required this.label,
    required this.delta,
    required this.formatted,
    required this.positiveIsGood,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isNeutral   = delta.abs() < 0.5;
    final isPositive  = delta > 0;
    final isGood      = isNeutral
        ? null
        : (positiveIsGood ? isPositive : !isPositive);

    final color = isNeutral
        ? colorScheme.onSurfaceVariant
        : (isGood! ? colorScheme.primary : colorScheme.error);

    final icon = isNeutral
        ? Icons.remove
        : (isPositive ? Icons.arrow_upward : Icons.arrow_downward);

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 3),
            Text(
              isNeutral ? '=' : formatted,
              style: TextStyle(
                  fontSize: 15, fontWeight: FontWeight.bold, color: color),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style:
              TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _ComparisonItemNA extends StatelessWidget {
  final String label;
  final bool isItalian;

  const _ComparisonItemNA({
    required this.label,
    required this.isItalian,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      children: [
        Text(
          'N/A',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 4),
        Text(label,
            style:
                TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
            textAlign: TextAlign.center),
        const SizedBox(height: 2),
        Text(
          isItalian ? 'dati prec. assenti' : 'no prev. data',
          style:
              TextStyle(fontSize: 10, color: colorScheme.onSurfaceVariant),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

// ─ Week header ────────────────────────────────────────────────────────────────

class _WeekHeader extends StatelessWidget {
  final WeeklyReport report;
  final bool isItalian;
  const _WeekHeader({required this.report, required this.isItalian});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final perf        = report.performance;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          isItalian ? 'Report settimanale' : 'Weekly report',
          style:
              TextStyle(fontSize: 16, color: colorScheme.onSurfaceVariant),
        ),
        const SizedBox(height: 4),
        Text(
          isItalian ? report.dateRangeIt : report.dateRangeEn,
          style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: perf.color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 7, height: 7,
                decoration:
                    BoxDecoration(color: perf.color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 6),
              Text(
                '${isItalian ? 'Settimana' : 'Week'}: ${perf.label(isItalian)}',
                style: TextStyle(
                  fontSize: 16,
                  color: HSLColor.fromColor(perf.color)
                      .withLightness(
                        (HSLColor.fromColor(perf.color).lightness * 0.7)
                            .clamp(0.0, 1.0),
                      )
                      .toColor(),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─ Stress score cards ─────────────────────────────────────────────────────────

class _StressScoreRow extends StatelessWidget {
  final WeeklyReport report;
  final bool isItalian;
  const _StressScoreRow({required this.report, required this.isItalian});

  @override
  Widget build(BuildContext context) {
    final worstStress = report.dailyStress.isNotEmpty
        ? report.dailyStress
            .reduce((a, b) => a.stressIndex > b.stressIndex ? a : b)
            .stressIndex
        : 0.0;

    return Row(
      children: [
        Expanded(
          child: _ScoreCard(
            label: isItalian ? 'Media settimana' : 'Weekly average',
            value: '${report.avgStressIndex.toStringAsFixed(0)}/100',
            valueColor: report.performance.color,
            subtitle: isItalian ? 'Indice stress' : 'Stress index',
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _ScoreCard(
            label: isItalian
                ? 'Giorno più stressante'
                : 'Most stressful day',
            value: isItalian
                ? _dayItShort(report.mostStressfulDay)
                : report.mostStressfulDay != 'N/A'
                    ? report.mostStressfulDay.substring(0, 3)
                    : 'N/A',
            valueColor: const Color(0xFFF59E0B),
            subtitle: 'Stress ${worstStress.toStringAsFixed(0)}/100',
          ),
        ),
      ],
    );
  }

  String _dayItShort(String enDay) {
    const map = {
      'Monday': 'Lun', 'Tuesday': 'Mar', 'Wednesday': 'Mer',
      'Thursday': 'Gio', 'Friday': 'Ven', 'Saturday': 'Sab',
      'Sunday': 'Dom',
    };
    return map[enDay] ?? enDay;
  }
}

class _ScoreCard extends StatelessWidget {
  final String label;
  final String value;
  final Color valueColor;
  final String subtitle;

  const _ScoreCard({
    required this.label,
    required this.value,
    required this.valueColor,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Material(
      color: colorScheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(24),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: TextStyle(
                    fontSize: 15, color: colorScheme.onSurfaceVariant)),
            const SizedBox(height: 6),
            Text(value,
                style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: valueColor)),
            const SizedBox(height: 2),
            Text(subtitle,
                style: TextStyle(
                    fontSize: 14, color: colorScheme.onSurfaceVariant)),
          ],
        ),
      ),
    );
  }
}

// ─ Stress bar chart (interattivo) ────────────────────────────────────────────

class _StressBarChart extends StatefulWidget {
  final WeeklyReport report;
  final bool isItalian;
  const _StressBarChart({required this.report, required this.isItalian});

  @override
  State<_StressBarChart> createState() => _StressBarChartState();
}

class _StressBarChartState extends State<_StressBarChart> {
  int? _selectedIndex;

  static const _labelsEn = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  static const _labelsIt = ['Lun', 'Mar', 'Mer', 'Gio', 'Ven', 'Sab', 'Dom'];
  static const _daysEn   = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
  static const _daysIt   = ['Lunedì', 'Martedì', 'Mercoledì', 'Giovedì', 'Venerdì', 'Sabato', 'Domenica'];

  String _fmt(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  Color _barColor(StressLevel level, BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    switch (level) {
      case StressLevel.low:    return colorScheme.primary;
      case StressLevel.medium: return colorScheme.secondary;
      case StressLevel.high:   return colorScheme.error;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final labels      = widget.isItalian ? _labelsIt : _labelsEn;
    final dayNames    = widget.isItalian ? _daysIt   : _daysEn;
    const chartHeight = 80.0;

    final brightness = ThemeData.estimateBrightnessForColor(
        colorScheme.surfaceContainerLow);
    final avgLineColor =
        brightness == Brightness.dark ? Colors.white : Colors.black;
    final avgFraction =
        (widget.report.avgStressIndex / 100).clamp(0.0, 1.0);

    final Map<String, DailyStress> byDate = {
      for (final ds in widget.report.dailyStress) _fmt(ds.date): ds,
    };

    Widget? tooltip;
    if (_selectedIndex != null) {
      final DateTime day =
          widget.report.weekStart.add(Duration(days: _selectedIndex!));
      final DailyStress? ds = byDate[_fmt(day)];
      final String dayName  = dayNames[_selectedIndex!];

      if (ds != null) {
        final Color barCol = _barColor(ds.level, context);
        tooltip = Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: barCol.withOpacity(0.12),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: barCol.withOpacity(0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8, height: 8,
                decoration:
                    BoxDecoration(color: barCol, shape: BoxShape.circle),
              ),
              const SizedBox(width: 8),
              Text(
                '$dayName · ${ds.stressIndex.toStringAsFixed(0)}/100',
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: barCol),
              ),
            ],
          ),
        );
      } else {
        tooltip = Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: colorScheme.outlineVariant),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.info_outline,
                  size: 14, color: colorScheme.onSurfaceVariant),
              const SizedBox(width: 6),
              Text(
                widget.isItalian
                    ? '$dayName · nessun dato'
                    : '$dayName · no data',
                style: TextStyle(
                    fontSize: 13, color: colorScheme.onSurfaceVariant),
              ),
            ],
          ),
        );
      }
    }

    return Material(
      color: colorScheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(24),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    widget.isItalian
                        ? 'Stress giornaliero · settimana'
                        : 'Daily stress · this week',
                    style: TextStyle(
                        fontSize: 16, color: colorScheme.onSurfaceVariant),
                  ),
                ),
                Row(
                  children: [
                    Container(width: 16, height: 3, color: avgLineColor),
                    const SizedBox(width: 4),
                    Text(
                      widget.isItalian ? 'media' : 'avg',
                      style: TextStyle(
                          fontSize: 12,
                          color: avgLineColor,
                          fontWeight: FontWeight.w800),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: chartHeight + 20,
              child: Stack(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: List.generate(7, (i) {
                      final DateTime day =
                          widget.report.weekStart.add(Duration(days: i));
                      final DailyStress? ds = byDate[_fmt(day)];
                      final double val  = ds?.stressIndex ?? 0;
                      final double barH = val > 0
                          ? (val / 100 * chartHeight).clamp(6.0, chartHeight)
                          : 0;
                      final Color color =
                          _barColor(ds?.level ?? StressLevel.low, context);
                      final bool isSelected = _selectedIndex == i;

                      return Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() {
                            _selectedIndex =
                                _selectedIndex == i ? null : i;
                          }),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              barH > 0
                                  ? AnimatedContainer(
                                      duration: const Duration(
                                          milliseconds: 150),
                                      height: barH,
                                      margin: const EdgeInsets.symmetric(
                                          horizontal: 3),
                                      decoration: BoxDecoration(
                                        color: isSelected
                                            ? color
                                            : color.withOpacity(0.6),
                                        borderRadius:
                                            const BorderRadius.vertical(
                                                top: Radius.circular(6)),
                                        border: isSelected
                                            ? Border.all(
                                                color: color, width: 2)
                                            : null,
                                      ),
                                    )
                                  : Container(
                                      height: 4,
                                      margin: const EdgeInsets.symmetric(
                                          horizontal: 3),
                                      decoration: BoxDecoration(
                                        color: isSelected
                                            ? colorScheme.outlineVariant
                                            : colorScheme.outlineVariant
                                                .withOpacity(0.5),
                                        borderRadius:
                                            BorderRadius.circular(4),
                                      ),
                                    ),
                              const SizedBox(height: 5),
                              Text(
                                i < labels.length ? labels[i] : '',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                  color: isSelected
                                      ? colorScheme.onSurface
                                      : ds == null
                                          ? colorScheme.outlineVariant
                                          : colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  ),
                  if (widget.report.avgStressIndex > 0)
                    Positioned(
                      top: chartHeight * (1 - avgFraction),
                      left: 0,
                      right: 0,
                      height: 3,
                      child: CustomPaint(
                        painter: _DashedLinePainter(color: avgLineColor),
                      ),
                    ),
                ],
              ),
            ),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 180),
              child: tooltip != null
                  ? Padding(
                      key: ValueKey(_selectedIndex),
                      padding: const EdgeInsets.only(top: 10),
                      child: tooltip,
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}

class _DashedLinePainter extends CustomPainter {
  final Color color;
  const _DashedLinePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke;
    const dashWidth = 6.0;
    const gapWidth  = 4.0;
    final y = size.height / 2;
    double x = 0;
    while (x < size.width) {
      canvas.drawLine(Offset(x, y), Offset(x + dashWidth, y), paint);
      x += dashWidth + gapWidth;
    }
  }

  @override
  bool shouldRepaint(_DashedLinePainter old) => old.color != color;
}

// ─ Peak time insight ──────────────────────────────────────────────────────────

class _PeakTimeInsight extends StatelessWidget {
  final WeeklyReport report;
  final bool isItalian;
  final ColorScheme colorScheme;
  const _PeakTimeInsight(
      {required this.report,
      required this.isItalian,
      required this.colorScheme});

  @override
  Widget build(BuildContext context) {
    return _InsightCard(
      icon: Icons.access_time_rounded,
      iconColor: colorScheme.error,
      label: isItalian ? 'Orario critico' : 'Peak stress time',
      text: isItalian
          ? 'In questa settimana il tuo organismo mostra i segnali fisiologici più elevati tra le ${report.peakStressTimeRange}, '
            'rilevati in ${report.peakStressDaysCount} giorni lavorativi su 5. '
            'È la fascia oraria in cui potresti sentirti più sotto pressione.'
          : 'This week your body shows the highest physiological signals between ${report.peakStressTimeRange}, '
            'detected on ${report.peakStressDaysCount} out of 5 working days. '
            'This is the time window where you may feel most under pressure.',
      tagText:
          isItalian ? 'Pausa attiva consigliata' : 'Active break suggested',
    );
  }
}

// ─ Sleep insight ──────────────────────────────────────────────────────────────

class _SleepInsight extends StatelessWidget {
  final WeeklyReport report;
  final bool isItalian;
  final ColorScheme colorScheme;
  const _SleepInsight(
      {required this.report,
      required this.isItalian,
      required this.colorScheme});

  @override
  Widget build(BuildContext context) {
    final settings     = context.watch<SettingsProvider>();
    final targetSonno  = settings.sleepHours;
    final corr         = report.sleepStressCorrelation;
    final significant  = report.sleepCorrelationSignificant;
    final fmtSleep     = _fmtSleep(report.avgSleepHours);
    final hasMissing   = report.missingSleepDays > 0;
    final daysRecorded = 7 - report.missingSleepDays;

    late String text;
    late String tag;
    late Color color;

    if (report.avgSleepHours == 0) {
      text = isItalian
          ? 'Non sono disponibili dati sul sonno per questa settimana. '
            'Il dispositivo potrebbe non aver registrato le sessioni.'
          : 'No sleep data available for this week. '
            'The device may not have recorded sleep sessions.';
      tag   = isItalian ? 'Dati non disponibili' : 'Data unavailable';
      color = colorScheme.onSurfaceVariant;
    } else if (!significant) {
      text = isItalian
          ? 'Hai dormito in media $fmtSleep${hasMissing ? ' (su $daysRecorded giorni rilevati)' : ''}. '
            'Questa settimana il sonno non ha influenzato chiaramente lo stress: servono più dati.'
          : 'Average sleep: $fmtSleep${hasMissing ? ' (over $daysRecorded days recorded)' : ''}. '
            'This week sleep didn\'t clearly affect stress — more data needed.';
      tag   = isItalian ? 'Pattern non ancora chiaro' : 'Pattern unclear';
      color = colorScheme.secondary;
    } else if (corr > 0) {
      text = isItalian
          ? 'Hai dormito in media $fmtSleep${hasMissing ? ' (su $daysRecorded giorni rilevati)' : ''}. '
            'Le notti ≥${targetSonno}h hanno ridotto lo stress del giorno dopo del ${corr.abs().toStringAsFixed(0)}%.'
          : 'Average sleep: $fmtSleep${hasMissing ? ' (over $daysRecorded days recorded)' : ''}. '
            'Nights ≥${targetSonno}h reduced next-day stress by ${corr.abs().toStringAsFixed(0)}%.';
      tag   = isItalian ? 'Continua così' : 'Keep it up';
      color = colorScheme.primary;
    } else {
      text = isItalian
          ? 'Hai dormito in media $fmtSleep${hasMissing ? ' (su $daysRecorded giorni rilevati)' : ''}, '
            'ma lo stress non è diminuito nei giorni seguenti. Potrebbero esserci altri fattori in gioco.'
          : 'Average sleep: $fmtSleep${hasMissing ? ' (over $daysRecorded days recorded)' : ''}, '
            'but stress didn\'t drop the following days. Other factors may have driven stress this week.';
      tag   = isItalian ? 'Monitora la prossima settimana' : 'Monitor next week';
      color = colorScheme.error;
    }

    return _InsightCard(
      icon: Icons.bedtime_rounded,
      iconColor: color,
      label: isItalian ? 'Sonno & recupero' : 'Sleep & recovery',
      text: text,
      tagText: tag,
    );
  }

  String _fmtSleep(double hours) {
    final h = hours.floor();
    final m = ((hours - h) * 60).round();
    return '${h}h ${m.toString().padLeft(2, '0')}min';
  }
}

// ─ Movement & recovery insight (passi + esercizio combinati) ─────────────────

class _MovementRecoveryInsight extends StatelessWidget {
  final WeeklyReport report;
  final bool isItalian;
  final ColorScheme colorScheme;
  const _MovementRecoveryInsight(
      {required this.report,
      required this.isItalian,
      required this.colorScheme});

  @override
  Widget build(BuildContext context) {
    final settings    = context.watch<SettingsProvider>();
    final goalK       = (settings.steps / 1000).toStringAsFixed(0);
    final corr        = report.stepsStressCorrelation;
    final significant = report.movementCorrelationSignificant;
    final hasExercise = report.hasExerciseData;
    final sessions    = report.exerciseSessions;

    final String activitySummary = hasExercise
        ? (isItalian
            ? 'tra passi e $sessions ${sessions == 1 ? 'allenamento registrato' : 'allenamenti registrati'}'
            : 'between steps and $sessions ${sessions == 1 ? 'logged workout' : 'logged workouts'}')
        : (isItalian
            ? 'principalmente dai passi (nessun allenamento registrato)'
            : 'mainly from steps (no workouts logged)');

    late String text;
    late String tag;
    late Color color;

    if (!significant) {
      text = isItalian
          ? 'Questa settimana il movimento ($activitySummary) non ha mostrato un legame chiaro con lo stress. '
            'Continua a muoverti: i benefici emergono nel tempo.'
          : 'This week, movement ($activitySummary) didn\'t show a clear link with stress. '
            'Keep moving — benefits build over time.';
      tag   = isItalian ? 'Pattern non ancora chiaro' : 'Pattern unclear';
      color = colorScheme.secondary;
    } else if (corr > 0) {
      text = isItalian
          ? 'I giorni più attivi ($activitySummary) hanno avuto uno stress medio del '
            '${corr.abs().toStringAsFixed(0)}% più basso rispetto ai giorni sedentari.'
          : 'Your most active days ($activitySummary) showed ${corr.abs().toStringAsFixed(0)}% '
            'lower stress than sedentary days.';
      tag   = isItalian ? 'Il movimento funziona' : 'Movement works';
      color = colorScheme.primary;
    } else {
      text = isItalian
          ? 'Questa settimana i giorni più attivi ($activitySummary) non hanno ridotto lo stress. '
            'A volte più attività riflette giornate più intense: osserva il trend nelle prossime settimane.'
          : 'This week, more active days ($activitySummary) didn\'t reduce stress. '
            'Sometimes higher activity reflects busier days — watch the trend over the coming weeks.';
      tag   = isItalian ? 'Monitora la prossima settimana' : 'Monitor next week';
      color = colorScheme.error;
    }

    return _InsightCard(
      icon: hasExercise
          ? Icons.directions_bike_rounded
          : Icons.directions_walk_rounded,
      iconColor: color,
      label: isItalian ? 'Movimento & recupero' : 'Movement & recovery',
      text: text,
      tagText: tag,
    );
  }
}

// ─ Insight card base ──────────────────────────────────────────────────────────

class _InsightCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String text;
  final String tagText;

  const _InsightCard({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.text,
    required this.tagText,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Material(
      color: colorScheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(24),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: TextStyle(
                          fontSize: 15,
                          color: colorScheme.onSurfaceVariant)),
                  const SizedBox(height: 4),
                  Text(text,
                      style:
                          const TextStyle(fontSize: 17, height: 1.45)),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(
                      color: iconColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(tagText,
                        style: TextStyle(
                            fontSize: 17,
                            color: iconColor,
                            fontWeight: FontWeight.w500)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─ Goals row ──────────────────────────────────────────────────────────────────

class _GoalsRow extends StatelessWidget {
  final WeeklyReport report;
  final bool isItalian;
  const _GoalsRow({required this.report, required this.isItalian});

  @override
  Widget build(BuildContext context) {
    final settings    = context.watch<SettingsProvider>();
    final targetPassi = settings.steps;
    final targetSonno = settings.sleepHours;

    return Row(
      children: [
        Expanded(
          child: _GoalCard(
            name: isItalian
                ? 'Passi ${(targetPassi / 1000).toStringAsFixed(0)}k/giorno'
                : '${(targetPassi / 1000).toStringAsFixed(0)}k steps/day',
            reached: report.stepsGoalDaysReached,
            total: 7,
            color: Theme.of(context).colorScheme.primary,
            isItalian: isItalian,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _GoalCard(
            name: isItalian
                ? 'Sonno ${targetSonno}h'
                : '${targetSonno}h sleep',
            reached: report.sleepGoalDaysReached,
            total: 7,
            color: Theme.of(context).colorScheme.secondary,
            isItalian: isItalian,
          ),
        ),
      ],
    );
  }
}

class _GoalCard extends StatelessWidget {
  final String name;
  final int reached;
  final int total;
  final Color color;
  final bool isItalian;

  const _GoalCard({
    required this.name,
    required this.reached,
    required this.total,
    required this.color,
    required this.isItalian,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Material(
      color: colorScheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(24),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(name,
                style: TextStyle(
                    fontSize: 15, color: colorScheme.onSurfaceVariant)),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: total > 0 ? reached / total : 0,
                backgroundColor: color.withOpacity(0.12),
                valueColor: AlwaysStoppedAnimation(color),
                minHeight: 6,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '$reached/$total ${isItalian ? 'giorni' : 'days'}',
              style: const TextStyle(
                  fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}

// ─ Goals disabilitati ─────────────────────────────────────────────────────────

class _GoalsDisabledCard extends StatelessWidget {
  final bool isItalian;
  const _GoalsDisabledCard({required this.isItalian});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Material(
      color: colorScheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(24),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Icon(Icons.flag_outlined,
                size: 36, color: colorScheme.onSurfaceVariant),
            const SizedBox(height: 10),
            Text(
              isItalian
                  ? 'Nessun obiettivo attivo questa settimana'
                  : 'No active goals this week',
              style: const TextStyle(
                  fontSize: 15, fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              isItalian
                  ? 'Puoi abilitare gli obiettivi personalizzati dalle impostazioni.'
                  : 'You can enable personal goals from settings.',
              style: TextStyle(
                  fontSize: 13, color: colorScheme.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 14),
            OutlinedButton.icon(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const GoalsScreen()),
              ),
              icon: const Icon(Icons.settings_outlined, size: 16),
              label: Text(
                isItalian ? 'Vai alle impostazioni' : 'Go to settings',
                style: const TextStyle(fontSize: 14),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: colorScheme.primary,
                side: BorderSide(
                    color: colorScheme.primary.withOpacity(0.5)),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─ Tip card ───────────────────────────────────────────────────────────────────

class _TipCard extends StatelessWidget {
  final WeeklyReport report;
  final bool isItalian;
  const _TipCard({required this.report, required this.isItalian});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final tipTime     = _tipTime(report.peakStressTimeRange);

    final tipText = isItalian
        ? 'Prova una pausa attiva di 5 min verso le $tipTime. '
          'Anche una breve camminata riduce il cortisolo del 15–20% nelle ore successive.'
        : 'Try a 5-min active break around $tipTime. '
          'Even a short walk can lower cortisol by 15–20% in the following hours.';

    return Material(
      color: colorScheme.primaryContainer,
      borderRadius: BorderRadius.circular(24),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isItalian ? '💡 Consiglio della settimana' : '💡 Tip of the week',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: colorScheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              tipText,
              style: TextStyle(
                  fontSize: 17,
                  height: 1.55,
                  color: colorScheme.onPrimaryContainer),
            ),
          ],
        ),
      ),
    );
  }

  String _tipTime(String range) {
    final start = range.split('–').first.trim();
    final hour  = int.tryParse(start.split(':').first) ?? 14;
    final h     = (hour - 1).clamp(0, 23);
    return '${h.toString().padLeft(2, '0')}:30';
  }
}