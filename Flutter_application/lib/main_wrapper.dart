import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_application/providers/settings_provider.dart';
import 'package:flutter_application/providers/data_provider.dart';

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
  late final List<Widget> _pages;

 
  bool _prefetchStarted = false;

  @override
  void initState() {
    super.initState();
    _pages = [
      HomeScreen(onDailyDataLoaded: _onHomeReady),
      const AnalysisAndTrendsScreen(),
      const ExerciseScreen(),
      const Profile(),
    ];
  }

  void _onHomeReady() {
    if (_prefetchStarted) return;
    _prefetchStarted = true;
    _prefetchReports();
  }

  Future<void> _prefetchReports() async {
    if (!mounted) return;
    final dataProvider = context.read<DataProvider>();
    final settings     = context.read<SettingsProvider>();

    try {
      await dataProvider.getOrFetchLatestReport(
        stepsGoalTarget: settings.steps,
        sleepGoalHours:  settings.sleepHours.toDouble(),
        goalsEnabled:    settings.customGoalsEnabled,
      );
      if (!mounted) return;
      await dataProvider.getOrFetchArchive(
        stepsGoalTarget: settings.steps,
        sleepGoalHours:  settings.sleepHours.toDouble(),
        goalsEnabled:    settings.customGoalsEnabled,
      );
    } catch (_) {
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