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

  // ── NOTA SUL FIX ───────────────────────────────────────────────────────
  // PRIMA: questo file lanciava un proprio "prefetch" dei report 5 secondi
  // dopo l'avvio, con un TIMER FISSO scollegato da cosa stava facendo la
  // Home nello stesso momento. Se la Home impiegava più di ~5s a finire
  // (rete lenta, refresh del token in corso, ecc.), le richieste del
  // prefetch si sovrapponevano a quelle ancora in corso della Home,
  // aumentando la probabilità che più richieste trovassero il token
  // scaduto nello stesso istante → race condition sul refresh token
  // (vedi AuthProvider) → fallimenti concentrati "appena aperta l'app".
  //
  // Inoltre scriveva lastWeeklyReport/cachedArchive direttamente come
  // variabili pubbliche, senza nessun coordinamento con Profile/Home/
  // Archivio, che facevano lo stesso calcolo per conto proprio.
  //
  // FIX: il prefetch resta (serve, evita di dover aprire il Profilo per
  // veder comparire i report), ma ora:
  // 1. Usa la cache condivisa (getOrFetchLatestReport / getOrFetchArchive)
  //    invece di scrivere i campi a mano — niente più duplicazioni.
  // 2. Parte SOLO dopo che la Home ha segnalato di aver finito il suo
  //    caricamento (tramite il callback onHomeDailyDataLoaded passato a
  //    HomeScreen), non con un timer fisso — così non c'è mai
  //    sovrapposizione tra le richieste della Home e quelle del prefetch.
  bool _prefetchStarted = false;

  @override
  void initState() {
    super.initState();
    _pages = [
      HomeScreen(onDailyDataLoaded: _onHomeReady),
      const AnalysisAndTrendsScreen(),
      const EserciziScreen(),
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
      // Calcola/recupera l'ultimo report (così la card Home/Profilo è già
      // pronta anche se l'utente non ha ancora aperto quelle schermate).
      await dataProvider.getOrFetchLatestReport(
        stepsGoalTarget: settings.steps,
        sleepGoalHours:  settings.sleepHours.toDouble(),
        goalsEnabled:    settings.customGoalsEnabled,
      );
      if (!mounted) return;

      // Poi popola in background il resto dell'archivio (7 settimane
      // restanti), una alla volta — niente onProgress qui: nessuno sta
      // guardando questa schermata in questo momento, basta che il
      // risultato finisca in cache pronto per quando l'utente aprirà
      // l'Archivio.
      await dataProvider.getOrFetchArchive(
        stepsGoalTarget: settings.steps,
        sleepGoalHours:  settings.sleepHours.toDouble(),
        goalsEnabled:    settings.customGoalsEnabled,
      );
    } catch (_) {
      // Silenzioso: è un prefetch in background, se fallisce le schermate
      // che lo richiederanno esplicitamente (Home/Profilo/Archivio)
      // riproveranno comunque al loro turno tramite getOrFetch*.
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