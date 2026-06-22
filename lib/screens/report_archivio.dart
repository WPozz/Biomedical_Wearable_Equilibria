import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';
import '../utils/weekly_report_model.dart';
import 'report_dettaglio.dart';

class ReportArchivioScreen extends StatefulWidget {
  const ReportArchivioScreen({super.key});

  @override
  State<ReportArchivioScreen> createState() => _ReportArchivioScreenState();
}

class _ReportArchivioScreenState extends State<ReportArchivioScreen> {
  DateTimeRange? _selectedDateRange;

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

  void _selezionaPeriodo() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2025),
      lastDate: DateTime(2027),
      initialDateRange: _selectedDateRange,
    );
    if (picked != null) {
      setState(() => _selectedDateRange = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isItalian = context.watch<SettingsProvider>().isItalian;

    final reportsVisualizzati = _selectedDateRange == null
        ? mockReports
        : [mockReports.first];

    return Scaffold(
      appBar: AppBar(
        title: Text(
          isItalian ? 'Calendario Report' : 'Weekly Reports',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.calendar_month_rounded,
                color: colorScheme.primary, size: 26),
            onPressed: _selezionaPeriodo,
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            if (_selectedDateRange != null)
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      isItalian ? "Filtro periodo attivo" : "Date filter active",
                      style: const TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w500),
                    ),
                    TextButton.icon(
                      onPressed: () =>
                          setState(() => _selectedDateRange = null),
                      icon: const Icon(Icons.clear, size: 16),
                      label: Text(isItalian ? "Rimuovi filtro" : "Clear"),
                    ),
                  ],
                ),
              ),

            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(20),
                itemCount: reportsVisualizzati.length,
                itemBuilder: (context, index) {
                  final report = reportsVisualizzati[index];
                  final bgCol   = _getReportColor(report.evaluationIt, context);
                  final textCol = _getReportOnColor(report.evaluationIt, context);

                  final subtitle = report.goalsEnabled
                      ? (isItalian
                          ? "Andamento settimana: ${report.evaluationIt}"
                          : "Week performance: ${report.evaluationEn}")
                      : (isItalian
                          ? "Andamento settimana: ${report.evaluationIt} · Obiettivi non attivi"
                          : "Week performance: ${report.evaluationEn} · No active goals");

                  return Card(
                    margin: const EdgeInsets.only(bottom: 14),
                    elevation: 0,
                    color: bgCol,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(color: textCol.withOpacity(0.15)),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 12),
                      leading: CircleAvatar(
                        backgroundColor: textCol.withOpacity(0.15),
                        child: Icon(Icons.analytics, color: textCol),
                      ),
                      title: Text(
                        isItalian ? report.dateRangeIt : report.dateRangeEn,
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: textCol,
                            fontSize: 16),
                      ),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 4.0),
                        child: Text(
                          subtitle,
                          style: TextStyle(
                              fontSize: 13,
                              color: textCol.withOpacity(0.85),
                              fontWeight: FontWeight.w500),
                        ),
                      ),
                      trailing: Icon(Icons.arrow_forward_ios_rounded,
                          size: 14, color: textCol),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              ReportDettaglioScreen(report: report),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}