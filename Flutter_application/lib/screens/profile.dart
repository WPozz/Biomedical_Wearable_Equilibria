import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_application/providers/auth_provider.dart';
import 'package:flutter_application/providers/userdata_provider.dart';
import 'package:flutter_application/providers/settings_provider.dart';
import 'package:flutter_application/providers/data_provider.dart';
import 'package:flutter_application/utils/weekly_report_model.dart';
import 'package:flutter_application/screens/dati_personali.dart';
import 'package:flutter_application/screens/impostazioni.dart';
import 'report_archivio.dart';
import 'report_dettaglio.dart';

class Profile extends StatefulWidget {
  const Profile({super.key});

  @override
  State<Profile> createState() => _ProfileState();
}

class _ProfileState extends State<Profile> {
  
  bool _isLoadingReport = true;
  String? _errorMessage;

  int? _lastSteps;
  double? _lastSleep;
  bool? _lastGoalsEnabled;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadLastReport());
  }

  Future<void> _loadLastReport({bool forceRefresh = false}) async {
    if (!mounted) return;

    setState(() {
      _isLoadingReport = true;
      _errorMessage = null;
    });

    final dataProvider = context.read<DataProvider>();
    final settings     = context.read<SettingsProvider>();

    try {
      await dataProvider.getOrFetchLatestReport(
        stepsGoalTarget: settings.steps,
        sleepGoalHours:  settings.sleepHours.toDouble(),
        goalsEnabled:    settings.customGoalsEnabled,
        forceRefresh:    forceRefresh,
      );
      if (!mounted) return;
      setState(() {
        _isLoadingReport = false;

        _lastSteps        = settings.steps;
        _lastSleep        = settings.sleepHours.toDouble();
        _lastGoalsEnabled = settings.customGoalsEnabled;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoadingReport = false;
        _errorMessage = 'error';
      });
    }
  }

  Color _bgColor(WeeklyReport r, BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    switch (r.performance) {
      case WeekPerformance.excellent:
        return isDark ? const Color(0xFF1A4D2E) : const Color(0xFFE6F4EA);
      case WeekPerformance.good:
        return isDark ? const Color(0xFF4D3A00) : const Color(0xFFFEF7E0);
      case WeekPerformance.fair:
      case WeekPerformance.poor:
        return isDark ? const Color(0xFF4D1515) : const Color(0xFFFCE8E6);
    }
  }

  Color _fgColor(WeeklyReport r, BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    switch (r.performance) {
      case WeekPerformance.excellent:
        return isDark ? const Color(0xFF6EE7A0) : const Color(0xFF137333);
      case WeekPerformance.good:
        return isDark ? const Color(0xFFFDE68A) : const Color(0xFFB06000);
      case WeekPerformance.fair:
      case WeekPerformance.poor:
        return isDark ? const Color(0xFFF87171) : const Color(0xFFC5221F);
    }
  }

  String _translateDept(String dept, bool isItalian) {
    if (!isItalian) return dept;
    const map = {
      'Cardiology':           'Cardiologia',
      'Emergency Department': 'Pronto Soccorso',
      'Administration':       'Amministrazione',
      'Software Development': 'Sviluppo Software',
      'Human Resources':      'Risorse Umane',
      'Production':           'Produzione',
      'Logistics':            'Logistica',
      'Quality Control':      'Controllo Qualità',
    };
    return map[dept] ?? dept;
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
    final colorScheme = Theme.of(context).colorScheme;
    final isItalian   = context.watch<SettingsProvider>().isItalian;

    // Read the report from a shared cache
    final report = context.watch<DataProvider>().lastWeeklyReport;

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

              // ── Avatar
              Consumer<UserDataProvider>(
                builder: (context, userData, child) {
                  return GestureDetector(
                    onTap: () =>
                        _showAvatarChoice(context, userData, isItalian),
                    child: Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                                color: colorScheme.primary.withOpacity(0.3),
                                width: 2),
                          ),
                          child: CircleAvatar(
                            radius: 50,
                            backgroundColor: colorScheme.primaryContainer,
                            child: _buildAvatarImage(
                                userData.avatarData, colorScheme),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: colorScheme.primary,
                            shape: BoxShape.circle,
                            border: Border.all(
                                color: Theme.of(context).scaffoldBackgroundColor,
                                width: 3),
                          ),
                          child: Icon(Icons.camera_alt,
                              size: 18, color: colorScheme.onPrimary),
                        ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 12),

              // ── Name and company
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
                              color: colorScheme.onSurfaceVariant,
                              fontSize: 13),
                        ),
                      ],
                    ],
                  );
                },
              ),
              const SizedBox(height: 25),

              // ── Card last report
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _buildReportCard(context, isItalian, colorScheme, report),
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
                  color: colorScheme.surfaceContainerHighest.withOpacity(0.3),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20)),
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    children: [
                      _buildProfileTile(
                        context: context,
                        title: isItalian ? 'Storico settimanale' : 'Weekly history',
                        icon: Icons.history_rounded,
                        color: colorScheme.primary,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const ReportArchivioScreen()),
                        ),
                      ),
                      
                      const Divider(height: 1, indent: 60, endIndent: 20),
                      
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
                              builder: (_) => const DatiPersonaliScreen()),
                        ),
                      ),
                      
                      const Divider(height: 1, indent: 60, endIndent: 20),
                      
                      _buildProfileTile(
                        context: context,
                        title: isItalian ? 'Impostazioni' : 'Settings',
                        icon: Icons.settings,
                        color: colorScheme.primary,
                        onTap: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const SettingsScreen()),
                          );

                          if (!context.mounted) return;

                          final settings = context.read<SettingsProvider>();
                          
                          final hasChanged =
                              _lastSteps != settings.steps ||
                              _lastSleep != settings.sleepHours.toDouble() ||
                              _lastGoalsEnabled != settings.customGoalsEnabled;

                          // New report if something has changed
                          if (hasChanged) {
                            context.read<DataProvider>().clearArchiveCache();
                            _loadLastReport(forceRefresh: true);
                          }
                        },
                      ),
                      
                      const Divider(height: 1, indent: 60, endIndent: 20),
                      
                      _buildProfileTile(
                        context: context,
                        title: isItalian ? 'Esci dall\'account' : 'Log out',
                        icon: Icons.logout,
                        color: Colors.redAccent,
                        onTap: () =>
                            _showLogoutDialog(context, isItalian),
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

  // ── Card last report: loading / errore / no data / real data

  Widget _buildReportCard(BuildContext context, bool isItalian,
      ColorScheme colorScheme, WeeklyReport? report) {
    if (_isLoadingReport && report == null) {
      return Container(
        height: 120,
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(24),
        ),
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_errorMessage != null && report == null) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          children: [
            Icon(Icons.wifi_off_rounded,
                color: colorScheme.error, size: 32),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                isItalian
                    ? 'Errore di sincronizzazione, riprova.'
                    : 'Sync error, please retry.',
                style: TextStyle(color: colorScheme.error, fontSize: 15),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () => _loadLastReport(forceRefresh: true),
            ),
          ],
        ),
      );
    }

    if (report == null || !report.hasData) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          children: [
            Icon(Icons.hourglass_empty_rounded,
                color: colorScheme.onSurfaceVariant, size: 32),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                isItalian
                    ? 'Nessun dato disponibile per questa settimana.'
                    : 'No data available for this week.',
                style: TextStyle(
                    color: colorScheme.onSurfaceVariant, fontSize: 15),
              ),
            ),
          ],
        ),
      );
    }

    final r           = report;
    final fg          = _fgColor(r, context);
    final bg          = _bgColor(r, context);
    final worstStress = r.dailyStress.isNotEmpty
        ? r.dailyStress
            .reduce((a, b) => a.stressIndex > b.stressIndex ? a : b)
            .stressIndex
        : 0.0;
    final sleepDeltaMin = r.sleepDeltaMin;
    final sleepDeltaStr =
        '${sleepDeltaMin >= 0 ? '↑' : '↓'} ${sleepDeltaMin.abs().toStringAsFixed(0)} min';
    final dayShort = isItalian
        ? _dayItShort(r.mostStressfulDay)
        : r.mostStressfulDay != 'N/A'
            ? r.mostStressfulDay.substring(0, 3)
            : 'N/A';

    return Container(
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
              builder: (_) => ReportDettaglioScreen(report: r)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
                      isItalian ? 'ULTIMO REPORT' : 'LATEST REPORT',
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
              Text(
                isItalian ? r.dateRangeIt : r.dateRangeEn,
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: fg),
              ),
              const SizedBox(height: 4),
              Text(
                isItalian
                    ? '${r.evaluationIt} · Stress medio: ${r.avgStressIndex.toStringAsFixed(0)}/100'
                    : '${r.evaluationEn} · Avg stress: ${r.avgStressIndex.toStringAsFixed(0)}/100',
                style: TextStyle(
                    fontSize: 13,
                    color: fg.withOpacity(0.85),
                    fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 14),
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
                  if (r.peakStressTimeRange != 'N/A') ...[
                    const SizedBox(width: 8),
                    Expanded(
                      child: _MiniStat(
                        value: r.peakStressTimeRange.replaceAll(' ', ''),
                        line1:
                            isItalian ? 'Orario critico' : 'Peak time',
                        line2:
                            '${r.peakStressDaysCount}/5 ${isItalian ? 'giorni' : 'days'}',
                        fg: fg,
                      ),
                    ),
                  ],
                  const SizedBox(width: 8),
                  Expanded(
                    child: _MiniStat(
                      value: _fmtSleepShort(r.avgSleepHours),
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
    );
  }

  // ── Avatar helpers

  Widget _buildAvatarImage(String? avatarData, ColorScheme colorScheme) {
    if (avatarData == null ||
        avatarData.isEmpty ||
        avatarData == 'default') {
      return Icon(Icons.person,
          size: 55, color: colorScheme.onPrimaryContainer);
    } else if (avatarData.startsWith('asset:')) {
      final assetPath = avatarData.replaceFirst('asset:', '');
      return ClipOval(
        child: Image.asset(assetPath,
            fit: BoxFit.cover,
            width: 100,
            height: 100,
            errorBuilder: (_, __, ___) => Icon(Icons.image_not_supported,
                color: colorScheme.onPrimaryContainer)),
      );
    } else {
      return ClipOval(
        child: Image.file(File(avatarData),
            fit: BoxFit.cover, width: 100, height: 100),
      );
    }
  }

void _showAvatarChoice(
      BuildContext context, UserDataProvider userData, bool isItalian) {
    final colorScheme = Theme.of(context).colorScheme;
    final defaultAssets = [
      'assets/images/profilo1.png',
      'assets/images/profilo2.png',
      'assets/images/profilo3.png',
      'assets/images/profilo4.png',
      'assets/images/Yumi.jpeg',
      'assets/images/Bellona.jpeg',
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: colorScheme.surfaceContainerLow,
      isScrollControlled: true, 
      shape: const RoundedRectangleBorder(
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(25))),
      builder: (bc) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                      color: Colors.grey.withOpacity(0.4),
                      borderRadius: BorderRadius.circular(10))),
              const SizedBox(height: 20),
              Text(
                isItalian
                    ? 'Modifica foto profilo'
                    : 'Change profile photo',
                style: const TextStyle(
                    fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              
              
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: GridView.builder(
                  shrinkWrap: true, 
                  physics: const NeverScrollableScrollPhysics(), 
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3, 
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                  ),
                  itemCount: defaultAssets.length,
                  itemBuilder: (context, index) {
                    final assetPath = defaultAssets[index];
                    final isSelected =
                        userData.avatarData == 'asset:$assetPath';
                    return GestureDetector(
                      onTap: () {
                        userData.setAvatar('asset:$assetPath');
                        Navigator.pop(context);
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSelected
                                ? colorScheme.primary
                                : Colors.transparent,
                            width: 3,
                          ),
                        ),
                        child: CircleAvatar(
                          radius: 35,
                          backgroundColor: colorScheme.primaryContainer,
                          child: ClipOval(
                            child: Image.asset(assetPath,
                                fit: BoxFit.cover,
                                width: 70,
                                height: 70,
                                errorBuilder: (_, __, ___) => const Icon(
                                    Icons.image_not_supported)),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              
              const SizedBox(height: 24),
              const Divider(indent: 20, endIndent: 20),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: Text(isItalian
                    ? 'Scegli dalla galleria'
                    : 'Choose from gallery'),
                onTap: () async {
                  Navigator.pop(context);
                  final picker = ImagePicker();
                  final image = await picker.pickImage(
                      source: ImageSource.gallery);
                  if (image != null) userData.setAvatar(image.path);
                },
              ),
              if (userData.avatarData != 'default' &&
                  userData.avatarData.isNotEmpty)
                ListTile(
                  leading: const Icon(Icons.delete_outline,
                      color: Colors.red),
                  title: Text(
                    isItalian
                        ? 'Rimuovi foto attuale'
                        : 'Remove current photo',
                    style: const TextStyle(color: Colors.red),
                  ),
                  onTap: () {
                    userData.setAvatar('default');
                    Navigator.pop(context);
                  },
                ),
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
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
            color: color.withOpacity(0.1), shape: BoxShape.circle),
        child: Icon(icon, color: color),
      ),
      title: Text(title,
          style: const TextStyle(
              fontSize: 17, fontWeight: FontWeight.w500)),
      trailing: const Icon(Icons.arrow_forward_ios,
          size: 14, color: Colors.grey),
      onTap: onTap,
    );
  }

  void _showLogoutDialog(BuildContext context, bool isItalian) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        title: const Text('Log Out'),
        content: Text(isItalian
            ? 'Sei sicuro di voler uscire dall\'account?'
            : 'Are you sure you want to log out?'),
        actions: [
          TextButton(
            child: Text(isItalian ? 'Annulla' : 'Cancel',
                style: const TextStyle(color: Colors.grey)),
            onPressed: () => Navigator.pop(ctx),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: Colors.redAccent),
            onPressed: () {
              context.read<AuthProvider>().logout();
              Navigator.pop(ctx);
            },
            child: Text(isItalian ? 'Esci' : 'Log out',
                style:
                    const TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}

// ── _MiniStat 

class _MiniStat extends StatelessWidget {
  final String value;
  final String line1;
  final String line2;
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
          Text(value,
              style: TextStyle(
                  fontSize: 18, fontWeight: FontWeight.bold, color: fg),
              textAlign: TextAlign.center),
          const SizedBox(height: 4),
          Text(line1,
              style:
                  TextStyle(fontSize: 10, color: fg.withOpacity(0.75)),
              textAlign: TextAlign.center),
          const SizedBox(height: 2),
          Text(line2,
              style: TextStyle(
                  fontSize: 10,
                  color: fg.withOpacity(0.9),
                  fontWeight: FontWeight.w600),
              textAlign: TextAlign.center),
        ],
      ),
    );
  }
}
