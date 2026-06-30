import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_application/providers/settings_provider.dart';
import 'package:flutter_application/providers/data_provider.dart';
import 'package:flutter_application/services/weekly_report_builder.dart';
import 'package:flutter_application/utils/weekly_report_model.dart';

import 'screens/home.dart';
import 'screens/esercizi.dart';
import 'screens/profile.dart';
import 'screens/analysis_and_trends.dart';

class MainWrapper extends StatefulWidget {
  const MainWrapper({super.key});

  @override
  State<MainWrapper> createState() => _MainWrapperState();
}

class _MainWrapperState extends State<MainWrapper> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    const HomeScreen(),
    const AnalysisAndTrendsScreen(),
    const EserciziScreen(),
    const Profile(),
  ];

  @override
  void initState() {
    super.initState();
    // Avvia il prefetch in background subito dopo il login.
    // Non blocca la UI — popola la cache silenziosamente.
    WidgetsBinding.instance.addPostFrameCallback((_) {
    // Aspetta 8 secondi che la home finisca di caricare i dati del giorno
      Future.delayed(const Duration(seconds: 8), _prefetchReports);
    });
  }

  Future<void> _prefetchReports() async {
    if (!mounted) return;
    final dataProvider = context.read<DataProvider>();

    // Se la cache è già completa non fa nulla
    final cached = dataProvider.cachedArchive;
    final ranges = WeeklyReportBuilder.buildWeekRanges();
    if (cached != null && cached.length >= ranges.length) {
      // Cache completa — popola lastWeeklyReport se non è ancora settato
      if (dataProvider.lastWeeklyReport == null && cached.isNotEmpty) {
        dataProvider.lastWeeklyReport = cached.first;
        dataProvider.notifyListeners();
      }
      return;
    }

    final settings     = context.read<SettingsProvider>();
    final stepsTarget  = settings.steps;
    final sleepTarget  = settings.sleepHours.toDouble();
    final goalsEnabled = settings.customGoalsEnabled;

    // Parte dalla prima settimana non ancora in cache
    final int startFrom = cached?.length ?? 0;
    final List<WeeklyReport> reports = List.from(cached ?? []);

    // Aggiunge i placeholder per le settimane mancanti
    for (int i = startFrom; i < ranges.length; i++) {
      final r = ranges[i];
      reports.add(WeeklyReport.empty(
        weekStart:   r.start,
        weekEnd:     r.end,
        dateRangeIt: '',
        dateRangeEn: '',
      ));
    }
    dataProvider.cachedArchive = List.from(reports);

    // Carica una settimana alla volta in background
    for (int i = startFrom; i < ranges.length; i++) {
      if (!mounted) return;
      final r = ranges[i];

      try {
        final report = await WeeklyReportBuilder.build(
          dataProvider:    dataProvider,
          weekStart:       r.start,
          weekEnd:         r.end,
          stepsGoalTarget: stepsTarget,
          sleepGoalHours:  sleepTarget,
          goalsEnabled:    goalsEnabled,
        );
        reports[i] = report;
        // Aggiorna la cache dopo ogni settimana
        dataProvider.cachedArchive = List.from(reports);
        // La prima settimana è quella più recente — aggiorna subito la Home
        if (i == 0 && report.hasData) {
          dataProvider.lastWeeklyReport = report;
          dataProvider.notifyListeners();
        }
      } catch (_) {
        // Silenzioso: se una settimana fallisce continua con le altre
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isItalian   = context.watch<SettingsProvider>().isItalian;

    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (int index) {
          setState(() => _selectedIndex = index);
        },
        backgroundColor: colorScheme.surface,
        indicatorColor: colorScheme.secondaryContainer,
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.grid_view_rounded),
            label: isItalian ? 'Home' : 'Home',
          ),
          NavigationDestination(
            icon: const Icon(Icons.analytics_rounded),
            label: isItalian ? 'Dati' : 'Data',
          ),
          NavigationDestination(
            icon: const Icon(Icons.play_circle_filled_rounded),
            label: isItalian ? 'Esercizi' : 'Exercises',
          ),
          NavigationDestination(
            icon: const Icon(Icons.person_rounded),
            label: isItalian ? 'Profilo' : 'Profile',
          ),
        ],
      ),
    );
  }
}