import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_application/providers/settings_provider.dart';
import 'package:flutter_application/providers/data_provider.dart';
import 'package:flutter_application/utils/weekly_report_model.dart';
import 'report_dettaglio.dart';

class ReportArchivioScreen extends StatefulWidget {
  const ReportArchivioScreen({super.key});

  @override
  State<ReportArchivioScreen> createState() => _ReportArchivioScreenState();
}

class _ReportArchivioScreenState extends State<ReportArchivioScreen> {
  List<WeeklyReport>? _reports;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadReports());
  }

  // ── NOTA SUL FIX ───────────────────────────────────────────────────────
  // Prima questa schermata leggeva/scriveva direttamente il campo pubblico
  // dataProvider.cachedArchive, che non notificava mai nessun listener e
  // non era in nessun modo coordinato con Profile (che calcolava la stessa
  // prima settimana per conto suo). Ora deleghiamo tutto a
  // DataProvider.getOrFetchArchive(), che:
  // - riusa l'eventuale report "ultima settimana" già calcolato da Profile
  //   o dalla Home, evitando di rifare le stesse ~9 chiamate di rete
  // - notifica correttamente tutti i listener quando i dati cambiano
  // - popola via via la lista tramite onProgress, mantenendo lo stesso
  //   comportamento "una card alla volta" di prima
  Future<void> _loadReports({bool forceRefresh = false}) async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final dataProvider = context.read<DataProvider>();
      final settings     = context.read<SettingsProvider>();

      final reports = await dataProvider.getOrFetchArchive(
        stepsGoalTarget: settings.steps,
        sleepGoalHours:  settings.sleepHours.toDouble(),
        goalsEnabled:    settings.customGoalsEnabled,
        forceRefresh:    forceRefresh,
        onProgress: (partial) {
          if (mounted) setState(() => _reports = partial);
        },
      );

      if (!mounted) return;
      setState(() {
        _reports   = reports;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading    = false;
        _errorMessage = e.toString();
      });
    }
  }

  Color _bgColor(WeeklyReport r, BuildContext context) {
    if (!r.hasData) return Theme.of(context).colorScheme.surfaceContainerLow;
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
    if (!r.hasData) return Theme.of(context).colorScheme.onSurfaceVariant;
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

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isItalian   = context.watch<SettingsProvider>().isItalian;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          isItalian ? 'Calendario Report' : 'Weekly Reports',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          if (!_isLoading)
            IconButton(
              icon: Icon(Icons.refresh_rounded, color: colorScheme.primary),
              onPressed: () => _loadReports(forceRefresh: true),
              tooltip: isItalian ? 'Ricarica' : 'Refresh',
            ),
        ],
      ),
      body: SafeArea(
        child: _buildBody(context, isItalian, colorScheme),
      ),
    );
  }

  Widget _buildBody(BuildContext context, bool isItalian, ColorScheme colorScheme) {
    if (_isLoading && (_reports == null || _reports!.isEmpty)) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(
              isItalian ? 'Caricamento report in corso…' : 'Loading reports…',
              style: TextStyle(color: colorScheme.onSurfaceVariant),
            ),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.wifi_off_rounded, size: 48, color: colorScheme.error),
              const SizedBox(height: 16),
              Text(
                isItalian
                ? 'Impossibile caricare i report.\nControlla la connessione.'
                : 'Could not load reports.\nCheck your connection.',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: () => _loadReports(forceRefresh: true),
                icon: const Icon(Icons.refresh),
                label: Text(isItalian ? 'Riprova' : 'Retry'),
              ),
            ],
          ),
        ),
      );
    }

    final reports = _reports ?? [];

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: reports.length,
      itemBuilder: (context, index) {
        final report = reports[index];
        final bgCol  = _bgColor(report, context);
        final fgCol  = _fgColor(report, context);

        return _ReportCard(
          report:    report,
          bgColor:   bgCol,
          fgColor:   fgCol,
          isItalian: isItalian,
          onTap: report.hasData
              ? () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ReportDettaglioScreen(report: report),
                    ),
                  )
              : null,
        );
      },
    );
  }
}

// ── Card singola ──────────────────────────────────────────────────────────────

class _ReportCard extends StatelessWidget {
  final WeeklyReport report;
  final Color bgColor;
  final Color fgColor;
  final bool isItalian;
  final VoidCallback? onTap;

  const _ReportCard({
    required this.report,
    required this.bgColor,
    required this.fgColor,
    required this.isItalian,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    // Placeholder: card senza dati ancora caricati
    final bool isPlaceholder = !report.hasData && report.dateRangeIt.isEmpty;

    final String subtitle = isPlaceholder
        ? (isItalian ? 'Caricamento…' : 'Loading…')
        : !report.hasData
            ? (isItalian
                ? 'Nessun dato disponibile per questa settimana'
                : 'No data available for this week')
            : report.goalsEnabled
                ? (isItalian
                    ? 'Andamento settimana: ${report.evaluationIt}'
                    : 'Week performance: ${report.evaluationEn}')
                : (isItalian
                    ? 'Andamento settimana: ${report.evaluationIt} · Obiettivi non attivi'
                    : 'Week performance: ${report.evaluationEn} · No active goals');

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      elevation: 0,
      color: bgColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: fgColor.withOpacity(0.15)),
      ),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        leading: CircleAvatar(
          backgroundColor: fgColor.withOpacity(0.15),
          child: isPlaceholder
              ? SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: fgColor,
                  ),
                )
              : Icon(
                  report.hasData
                      ? Icons.analytics_rounded
                      : Icons.hourglass_empty_rounded,
                  color: fgColor,
                ),
        ),
        title: Text(
          isPlaceholder
              ? (isItalian ? 'Caricamento…' : 'Loading…')
              : (isItalian ? report.dateRangeIt : report.dateRangeEn),
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: fgColor,
            fontSize: 16,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            subtitle,
            style: TextStyle(
              fontSize: 13,
              color: fgColor.withOpacity(0.85),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        trailing: (!isPlaceholder && report.hasData)
            ? Icon(Icons.arrow_forward_ios_rounded, size: 14, color: fgColor)
            : null,
        onTap: onTap,
      ),
    );
  }
}