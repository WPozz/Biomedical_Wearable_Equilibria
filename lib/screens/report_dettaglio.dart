import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';
import '../utils/weekly_report_model.dart';
import '../screens/impostazioni.dart';
import '../screens/goals.dart';

class ReportDettaglioScreen extends StatelessWidget {
  final WeeklyReport report;

  const ReportDettaglioScreen({super.key, required this.report});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final isItalian = settings.isItalian;
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
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _WeekHeader(report: report, isItalian: isItalian),
              const SizedBox(height: 16),
              _ComparisonCard(report: report, isItalian: isItalian),
              const SizedBox(height: 24),
              _sectionTitle(isItalian ? 'Indice di Stress' : 'Stress Index', context),
              const SizedBox(height: 10),
              _StressScoreRow(report: report, isItalian: isItalian),
              const SizedBox(height: 10),
              _StressBarChart(report: report, isItalian: isItalian),
              const SizedBox(height: 24),
              _sectionTitle(isItalian ? 'Insight chiave' : 'Key insights', context),
              const SizedBox(height: 10),
              _PeakTimeInsight(report: report, isItalian: isItalian, colorScheme: colorScheme),
              const SizedBox(height: 10),
              _SleepInsight(report: report, isItalian: isItalian, colorScheme: colorScheme),
              const SizedBox(height: 10),
              _StepsInsight(report: report, isItalian: isItalian, colorScheme: colorScheme),
              const SizedBox(height: 24),
              _sectionTitle(isItalian ? 'Obiettivi settimana' : 'Weekly goals', context),
              const SizedBox(height: 10),
              if (report.goalsEnabled)
                _GoalsRow(report: report, isItalian: isItalian)
              else
                _GoalsDisabledCard(isItalian: isItalian),
              const SizedBox(height: 12),
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

// ─ Confronto settimana precedente ─

class _ComparisonCard extends StatelessWidget {
  final WeeklyReport report;
  final bool isItalian;
  const _ComparisonCard({required this.report, required this.isItalian});

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
              isItalian ? 'Rispetto alla settimana precedente' : 'vs. previous week',
              style: TextStyle(fontSize: 13, color: colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _ComparisonItem(
                    label: isItalian ? 'Stress' : 'Stress',
                    delta: stressDelta,
                    formatted: '${stressDelta > 0 ? '+' : ''}${stressDelta.toStringAsFixed(0)} pt',
                    positiveIsGood: false, // meno stress = meglio
                  ),
                ),
                Expanded(
                  child: _ComparisonItem(
                    label: isItalian ? 'Sonno' : 'Sleep',
                    delta: sleepDelta,
                    formatted: '${sleepDelta > 0 ? '+' : ''}${sleepDelta.toStringAsFixed(0)} min',
                    positiveIsGood: true,
                  ),
                ),
                Expanded(
                  child: _ComparisonItem(
                    label: isItalian ? 'Passi/die' : 'Steps/day',
                    delta: stepsDelta,
                    formatted: '${stepsDelta > 0 ? '+' : ''}${(stepsDelta / 1000).toStringAsFixed(1)}k',
                    positiveIsGood: true,
                  ),
                ),
              ],
            ),
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
    final isNeutral = delta.abs() < 0.5;
    final isPositive = delta > 0;
    final isGood = isNeutral
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
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

// ─ Week header ─

class _WeekHeader extends StatelessWidget {
  final WeeklyReport report;
  final bool isItalian;
  const _WeekHeader({required this.report, required this.isItalian});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final perf = report.performance;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          isItalian ? 'Report settimanale' : 'Weekly report',
          style: TextStyle(fontSize: 16, color: colorScheme.onSurfaceVariant),
        ),
        const SizedBox(height: 4),
        Text(
          isItalian ? report.dateRangeIt : report.dateRangeEn,
          style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: perf.color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 7, height: 7,
                decoration: BoxDecoration(color: perf.color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 6),
              Text(
                '${isItalian ? 'Settimana' : 'Week'}: ${perf.label(isItalian)}',
                style: TextStyle(fontSize: 16, color: perf.color, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─ Stress score cards ─

class _StressScoreRow extends StatelessWidget {
  final WeeklyReport report;
  final bool isItalian;
  const _StressScoreRow({required this.report, required this.isItalian});

  @override
  Widget build(BuildContext context) {
    final worstStress = report.dailyStress
        .reduce((a, b) => a.stressIndex > b.stressIndex ? a : b)
        .stressIndex;

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
            label: isItalian ? 'Giorno più stressante' : 'Most stressful day',
            value: isItalian ? _dayItShort(report.mostStressfulDay) : report.mostStressfulDay.substring(0, 3),
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
      'Thursday': 'Gio', 'Friday': 'Ven', 'Saturday': 'Sab', 'Sunday': 'Dom',
    };
    return map[enDay] ?? enDay.substring(0, 3);
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
            Text(label, style: TextStyle(fontSize: 15, color: colorScheme.onSurfaceVariant)),
            const SizedBox(height: 6),
            Text(value, style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: valueColor)),
            const SizedBox(height: 2),
            Text(subtitle, style: TextStyle(fontSize: 14, color: colorScheme.onSurfaceVariant)),
          ],
        ),
      ),
    );
  }
}

// ─ Stress bar chart ─

class _StressBarChart extends StatelessWidget {
  final WeeklyReport report;
  final bool isItalian;
  const _StressBarChart({required this.report, required this.isItalian});

  static const _labelsEn = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  static const _labelsIt = ['Lun', 'Mar', 'Mer', 'Gio', 'Ven', 'Sab', 'Dom'];

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final labels = isItalian ? _labelsIt : _labelsEn;
    const chartHeight = 80.0;

    return Material(
      color: colorScheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(24),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isItalian ? 'Stress giornaliero · settimana' : 'Daily stress · this week',
              style: TextStyle(fontSize: 16, color: colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: chartHeight + 20,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: List.generate(7, (i) {
                  final ds = i < report.dailyStress.length ? report.dailyStress[i] : null;
                  final val = ds?.stressIndex ?? 0;
                  final barH = (val / 100 * chartHeight).clamp(6.0, chartHeight);
                  final color = _barColor(ds?.level ?? StressLevel.low, context);
                  return Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Container(
                          height: barH,
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          decoration: BoxDecoration(
                            color: color,
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          i < labels.length ? labels[i] : '',
                          style: TextStyle(fontSize: 16, color: colorScheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _barColor(StressLevel level, BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    switch (level) {
      case StressLevel.low:    return colorScheme.primary;
      case StressLevel.medium: return colorScheme.secondary;
      case StressLevel.high:   return colorScheme.error;
    }
  }
}

// ─ Insight: orario critico ─

class _PeakTimeInsight extends StatelessWidget {
  final WeeklyReport report;
  final bool isItalian;
  final ColorScheme colorScheme;
  const _PeakTimeInsight({required this.report, required this.isItalian, required this.colorScheme});

  @override
  Widget build(BuildContext context) {
    return _InsightCard(
      icon: Icons.access_time_rounded,
      iconColor: colorScheme.error,
      label: isItalian ? 'Orario critico' : 'Peak stress time',
      text: isItalian
          ? 'Lo stress picca tra le ${report.peakStressTimeRange} per ${report.peakStressDaysCount} giorni lavorativi su 5.'
          : 'Stress peaks between ${report.peakStressTimeRange} on ${report.peakStressDaysCount} out of 5 working days.',
      tagText: isItalian ? 'Pausa consigliata' : 'Active break suggested',
    );
  }
}

// ─ Insight: sonno ─

class _SleepInsight extends StatelessWidget {
  final WeeklyReport report;
  final bool isItalian;
  final ColorScheme colorScheme;
  const _SleepInsight({required this.report, required this.isItalian, required this.colorScheme});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final targetSonno = settings.sleepHours;

    final corr = report.sleepStressCorrelation;
    final significant = report.sleepCorrelationSignificant;
    final fmtSleep = _fmtSleep(report.avgSleepHours);

    late String text;
    late String tag;
    late Color color;

    if (!significant) {
      // correlazione troppo debole per trarre conclusioni
      text = isItalian
          ? 'Hai dormito in media $fmtSleep. Questa settimana il sonno non ha influenzato chiaramente lo stress: servono più dati.'
          : 'Average sleep: $fmtSleep. This week sleep didn\'t clearly affect stress — more data needed.';
      tag  = isItalian ? 'Pattern non ancora chiaro' : 'Pattern unclear';
      color = colorScheme.secondary;
    } else if (corr > 0) {
      // più sonno meno stress
      text = isItalian
          ? 'Hai dormito in media $fmtSleep. Le notti ≥${targetSonno}h hanno ridotto lo stress del giorno dopo del ${corr.toStringAsFixed(0)}%.'
          : 'Average sleep: $fmtSleep. Nights ≥${targetSonno}h reduced next-day stress by ${corr.toStringAsFixed(0)}%.';
      tag  = isItalian ? 'Continua così' : 'Keep it up';
      color = colorScheme.primary;
    } else {
      // più sonno ma lo stress non è calato
      text = isItalian
          ? 'Hai dormito in media $fmtSleep, ma lo stress non è diminuito nei giorni seguenti. Potrebbero esserci altri fattori in gioco questa settimana.'
          : 'Average sleep: $fmtSleep, but stress didn\'t drop the following days. Other factors may have driven stress this week.';
      tag  = isItalian ? 'Monitora la prossima settimana' : 'Monitor next week';
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

// ─ Insight: passi ─

class _StepsInsight extends StatelessWidget {
  final WeeklyReport report;
  final bool isItalian;
  final ColorScheme colorScheme;
  const _StepsInsight({required this.report, required this.isItalian, required this.colorScheme});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final goalK = (settings.steps / 1000).toStringAsFixed(0);

    final corr = report.stepsStressCorrelation;
    final significant = report.stepsCorrelationSignificant;

    late String text;
    late String tag;
    late Color color;

    if (!significant) {
      text = isItalian
          ? 'Questa settimana i giorni con più passi non hanno mostrato uno stress significativamente diverso. Continua a muoverti: i benefici emergono nel tempo.'
          : 'This week, higher-step days didn\'t show clearly different stress levels. Keep moving — benefits build over time.';
      tag  = isItalian ? 'Pattern non ancora chiaro' : 'Pattern unclear';
      color = colorScheme.secondary;
    } else if (corr > 0) {
      text = isItalian
          ? 'I giorni con >${goalK}k passi hanno avuto uno stress medio del ${corr.toStringAsFixed(0)}% più basso rispetto ai giorni sedentari.'
          : 'Days with >${goalK}k steps showed ${corr.toStringAsFixed(0)}% lower stress than sedentary days.';
      tag  = isItalian ? '+2 sessioni consigliate' : '+2 sessions recommended';
      color = colorScheme.secondary;
    } else {
      text = isItalian
          ? 'Questa settimana i giorni più attivi non hanno ridotto lo stress. A volte l\'attività fisica riflette giornate più intense: osserva il trend nelle prossime settimane.'
          : 'This week, more active days didn\'t reduce stress. Sometimes higher activity reflects busier days — watch the trend over the coming weeks.';
      tag  = isItalian ? 'Monitora la prossima settimana' : 'Monitor next week';
      color = colorScheme.error;
    }

    return _InsightCard(
      icon: Icons.directions_walk_rounded,
      iconColor: color,
      label: isItalian ? 'Movimento & stress' : 'Movement & stress',
      text: text,
      tagText: tag,
    );
  }
}

// ─ Insight card (base) ─

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
                  Text(label, style: TextStyle(fontSize: 15, color: colorScheme.onSurfaceVariant)),
                  const SizedBox(height: 4),
                  Text(text, style: const TextStyle(fontSize: 17, height: 1.45)),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(
                      color: iconColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(tagText,
                        style: TextStyle(fontSize: 17, color: iconColor, fontWeight: FontWeight.w500)),
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

// ─ Goals row ─

class _GoalsRow extends StatelessWidget {
  final WeeklyReport report;
  final bool isItalian;
  const _GoalsRow({required this.report, required this.isItalian});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final targetPassi = settings.steps;
    final targetSonno = settings.sleepHours;

    return Row(
      children: [
        Expanded(
          child: _GoalCard(
            name: isItalian
                ? 'Passi ${(targetPassi / 1000).toStringAsFixed(0)}k/die'
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
            Text(name, style: TextStyle(fontSize: 15, color: colorScheme.onSurfaceVariant)),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: reached / total,
                backgroundColor: color.withOpacity(0.12),
                valueColor: AlwaysStoppedAnimation(color),
                minHeight: 6,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '$reached/$total ${isItalian ? 'giorni' : 'days'}',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}

// ─ Goals disabilitati ─

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
                MaterialPageRoute(
                  builder: (context) => const GoalsScreen(),
                ),
              ),
              icon: const Icon(Icons.settings_outlined, size: 16),
              label: Text(
                isItalian ? 'Vai alle impostazioni' : 'Go to settings',
                style: const TextStyle(fontSize: 14),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: colorScheme.primary,
                side: BorderSide(color: colorScheme.primary.withOpacity(0.5)),
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

// ─ Tip card ─

class _TipCard extends StatelessWidget {
  final WeeklyReport report;
  final bool isItalian;
  const _TipCard({required this.report, required this.isItalian});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final tipTime = _tipTime(report.peakStressTimeRange);

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
              style: TextStyle(fontSize: 17, height: 1.55, color: colorScheme.onPrimaryContainer),
            ),
          ],
        ),
      ),
    );
  }

  String _tipTime(String range) {
    final start = range.split('–').first.trim();
    final hour = int.tryParse(start.split(':').first) ?? 14;
    final h = (hour - 1).clamp(0, 23);
    return '${h.toString().padLeft(2, '0')}:30';
  }
}