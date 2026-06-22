import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../screens/dati_personali.dart';
import '../screens/impostazioni.dart';
import '../providers/settings_provider.dart';
import '../providers/userdata_provider.dart';
import '../utils/weekly_report_model.dart';
import 'report_archivio.dart';
import 'report_dettaglio.dart';

class Profile extends StatelessWidget {
  const Profile({super.key});

  Color _getReportColor(String evaluation, BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    switch (evaluation) {
      case 'Ottimo':
        return isDark ? const Color(0xFF1A4D2E) : const Color(0xFFE6F4EA);
      case 'Buono':
        return isDark ? const Color(0xFF4D3A00) : const Color(0xFFFEF7E0);
      case 'Migliorabile':
      default:
        return isDark ? const Color(0xFF4D1515) : const Color(0xFFFCE8E6);
    }
  }

  Color _getReportOnColor(String evaluation, BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    switch (evaluation) {
      case 'Ottimo':
        return isDark ? const Color(0xFF6EE7A0) : const Color(0xFF137333);
      case 'Buono':
        return isDark ? const Color(0xFFFDE68A) : const Color(0xFFB06000);
      case 'Migliorabile':
      default:
        return isDark ? const Color(0xFFF87171) : const Color(0xFFC5221F);
    }
  }

  String _translateDept(String dept, bool isItalian) {
    if (!isItalian) return dept;
    switch (dept) {
      case 'Cardiology':           return 'Cardiologia';
      case 'Emergency Department': return 'Pronto Soccorso';
      case 'Administration':       return 'Amministrazione';
      case 'Software Development': return 'Sviluppo Software';
      case 'Human Resources':      return 'Risorse Umane';
      case 'Production':           return 'Produzione';
      case 'Logistics':            return 'Logistica';
      case 'Quality Control':      return 'Controllo Qualità';
      default:                     return dept;
    }
  }

  String _fmtSleepShort(double hours) {
    final h = hours.floor();
    final m = ((hours - h) * 60).round();
    return '${h}h${m.toString().padLeft(2, '0')}';
  }

  String _dayItShort(String enDay) {
    const map = {
      'Monday': 'Lun', 'Tuesday': 'Mar', 'Wednesday': 'Mer',
      'Thursday': 'Gio', 'Friday': 'Ven', 'Saturday': 'Sab', 'Sunday': 'Dom',
    };
    return map[enDay] ?? enDay.substring(0, 3);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme  = Theme.of(context).colorScheme;
    final isItalian    = context.watch<SettingsProvider>().isItalian;
    final ultimoReport = mockReports.first;
    final fg           = _getReportOnColor(ultimoReport.evaluationIt, context);
    final bg           = _getReportColor(ultimoReport.evaluationIt, context);

    final worstStress = ultimoReport.dailyStress
        .reduce((a, b) => a.stressIndex > b.stressIndex ? a : b)
        .stressIndex;
    final sleepDeltaMin = ultimoReport.sleepDeltaMin;
    final sleepDeltaStr = '${sleepDeltaMin >= 0 ? '↑' : '↓'} ${sleepDeltaMin.abs().toStringAsFixed(0)} min';
    final dayShort = isItalian
        ? _dayItShort(ultimoReport.mostStressfulDay)
        : ultimoReport.mostStressfulDay.substring(0, 3);

    return Scaffold(
      appBar: AppBar(
        title: Text(isItalian ? 'Tu' : 'You',
            style: const TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: 20),

              // ── Avatar ──────────────────────────────
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: colorScheme.primary.withValues(alpha: 0.3), width: 2),
                ),
                child: CircleAvatar(
                  radius: 50,
                  backgroundColor: colorScheme.primaryContainer,
                  child: Icon(Icons.person,
                      size: 55, color: colorScheme.onPrimaryContainer),
                ),
              ),
              const SizedBox(height: 12),

              // ── Nome e azienda ───────────────────────
              Consumer<UserDataProvider>(
                builder: (context, userData, child) {
                  return Column(
                    children: [
                      Text(
                        '${userData.firstName} ${userData.lastName}',
                        style: Theme.of(context)
                            .textTheme
                            .titleLarge
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      if (userData.company != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          '${userData.company} • ${_translateDept(userData.department ?? '', isItalian)}',
                          style: TextStyle(
                              color: colorScheme.onSurfaceVariant, fontSize: 13),
                        ),
                      ],
                    ],
                  );
                },
              ),
              const SizedBox(height: 25),

              // ── Card ultimo report ───────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  decoration: BoxDecoration(
                    color: bg,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: fg.withOpacity(0.2)),
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(24),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            ReportDettaglioScreen(report: ultimoReport),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Tag + freccia
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                    color: fg,
                                    borderRadius: BorderRadius.circular(12)),
                                child: Text(
                                  isItalian ? "ULTIMO REPORT" : "LATEST REPORT",
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                      fontSize: 10),
                                ),
                              ),
                              Icon(Icons.arrow_forward_ios_rounded,
                                  size: 16, color: fg),
                            ],
                          ),
                          const SizedBox(height: 10),

                          // Date range
                          Text(
                            isItalian
                                ? ultimoReport.dateRangeIt
                                : ultimoReport.dateRangeEn,
                            style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: fg),
                          ),
                          const SizedBox(height: 4),

                          // Sottotitolo: Excellent · Stress medio: 34/100
                          Text(
                            isItalian
                                ? '${ultimoReport.evaluationIt} · Stress medio: ${ultimoReport.avgStressIndex.toStringAsFixed(0)}/100'
                                : '${ultimoReport.evaluationEn} · Avg stress: ${ultimoReport.avgStressIndex.toStringAsFixed(0)}/100',
                            style: TextStyle(
                                fontSize: 13,
                                color: fg.withOpacity(0.85),
                                fontWeight: FontWeight.w500),
                          ),
                          const SizedBox(height: 14),

                          // Mini-stat: giorno / orario / sonno
                          Row(
                            children: [
                              Expanded(
                                child: _MiniStat(
                                  value: dayShort,
                                  line1: isItalian
                                      ? 'Giorno più\nstressante'
                                      : 'Most stressful\nday',
                                  line2: '${worstStress.toStringAsFixed(0)}/100',
                                  fg: fg,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _MiniStat(
                                  value: ultimoReport.peakStressTimeRange
                                      .split('–')
                                      .first
                                      .trim(),
                                  line1: isItalian ? 'Orario critico' : 'Peak time',
                                  line2:
                                      '${ultimoReport.peakStressDaysCount}/5 ${isItalian ? 'giorni' : 'days'}',
                                  fg: fg,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _MiniStat(
                                  value: _fmtSleepShort(ultimoReport.avgSleepHours),
                                  line1: isItalian ? 'Sonno medio' : 'Avg sleep',
                                  line2: sleepDeltaStr,
                                  fg: fg,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 28),

              Padding(
                padding: const EdgeInsets.only(left: 24, bottom: 10),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    isItalian ? 'PROFILO' : 'PROFILE',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurfaceVariant,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Card(
                  elevation: 0,
                  color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20)),
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    children: [
                      // Report personali con storico preview
                      _ReportArchivioTile(isItalian: isItalian),

                      const Divider(height: 1, indent: 60, endIndent: 20),

                      // Personal Information
                      _buildProfileTile(
                        context: context,
                        title: isItalian
                            ? 'Informazioni personali'
                            : 'Personal Information',
                        icon: Icons.person_outline,
                        color: colorScheme.primary,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const DatiPersonaliScreen()),
                        ),
                      ),
                      const Divider(height: 1, indent: 60, endIndent: 20),

                      // Settings
                      _buildProfileTile(
                        context: context,
                        title: isItalian ? 'Impostazioni' : 'Settings',
                        icon: Icons.settings,
                        color: colorScheme.primary,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const ImpostazioniScreen()),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileTile({
    required BuildContext context,
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
        child: Icon(icon, color: color),
      ),
      title: Text(title,
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w500)),
      trailing:
          const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
      onTap: onTap,
    );
  }
}


class _MiniStat extends StatelessWidget {
  final String value;
  final String line1; // label principale (può avere \n)
  final String line2; // info secondaria (es. "61/100", "4/5 giorni")
  final Color fg;

  const _MiniStat({
    required this.value,
    required this.line1,
    required this.line2,
    required this.fg,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
      decoration: BoxDecoration(
        color: fg.withOpacity(0.12),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
                fontSize: 18, fontWeight: FontWeight.bold, color: fg),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            line1,
            style: TextStyle(fontSize: 10, color: fg.withOpacity(0.75)),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 2),
          Text(
            line2,
            style: TextStyle(
                fontSize: 10,
                color: fg.withOpacity(0.9),
                fontWeight: FontWeight.w600),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}


class _ReportArchivioTile extends StatelessWidget {
  final bool isItalian;
  const _ReportArchivioTile({required this.isItalian});

  Color _dotColor(String evaluationIt, BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    switch (evaluationIt) {
      case 'Ottimo':
        return isDark ? const Color(0xFF6EE7A0) : const Color(0xFF137333);
      case 'Buono':
        return isDark ? const Color(0xFFFDE68A) : const Color(0xFFB06000);
      default:
        return isDark ? const Color(0xFFF87171) : const Color(0xFFC5221F);
    }
  }

  String _fmtSleepShort(double hours) {
    final h = hours.floor();
    final m = ((hours - h) * 60).round();
    return '${h}h${m.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final preview = mockReports.take(2).toList();

    return InkWell(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const ReportArchivioScreen()),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  isItalian ? 'Storico settimanale' : 'Weekly history',
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Text(
                  isItalian ? 'Vedi tutti ›' : 'See all ›',
                  style: TextStyle(
                      fontSize: 13,
                      color: colorScheme.primary,
                      fontWeight: FontWeight.w500),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Preview ultime 2 settimane
            ...preview.map((r) {
              final dot  = _dotColor(r.evaluationIt, context);
              final eval = isItalian ? r.evaluationIt : r.evaluationEn;
              final subtitle = isItalian
                  ? '$eval · Stress ${r.avgStressIndex.toStringAsFixed(0)} · Sonno ${_fmtSleepShort(r.avgSleepHours)}'
                  : '$eval · Stress ${r.avgStressIndex.toStringAsFixed(0)} · Sleep ${_fmtSleepShort(r.avgSleepHours)}';

              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  children: [
                    Container(
                      width: 9,
                      height: 9,
                      margin: const EdgeInsets.only(right: 12, top: 2),
                      decoration:
                          BoxDecoration(color: dot, shape: BoxShape.circle),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isItalian ? r.dateRangeIt : r.dateRangeEn,
                            style: const TextStyle(
                                fontSize: 13, fontWeight: FontWeight.w600),
                          ),
                          Text(
                            subtitle,
                            style: TextStyle(
                                fontSize: 12,
                                color: colorScheme.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      r.avgStressIndex.toStringAsFixed(0),
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: dot),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}