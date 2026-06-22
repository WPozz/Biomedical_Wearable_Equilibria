import 'package:flutter/material.dart';
import 'package:flutter_application_1/screens/analysis_and_trends.dart';
import 'package:flutter_application_1/screens/esercizi.dart';
import 'package:flutter_application_1/screens/home.dart';
import 'package:flutter_application_1/screens/profile.dart';

class MainWrapper extends StatefulWidget {
  const MainWrapper({super.key});

  @override
  State<MainWrapper> createState() => _MainWrapperState();
}

class _MainWrapperState extends State<MainWrapper> {
  int _selectedIndex = 0;

  // Qui elenchiamo le pagine nell'ordine della barra
  final List<Widget> _pages = [
    const HomeScreen(),   // Indice 0
    const AnalysisAndTrendsScreen(), // Indice 1
    const EserciziScreen(), // Indice 3
    const Profile() // Indice 4
  ];

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      // IndexedStack è magico: tiene in memoria le pagine senza resettarle
      body: IndexedStack( // qui non metterei il provider per la bottom navigation, ma il wrapper deve essere il punto in cui le schermate leggono lo stato condiviso.
        index: _selectedIndex,
        children: _pages,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (int index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        backgroundColor: colorScheme.surface,
        indicatorColor: colorScheme.secondaryContainer,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.grid_view_rounded),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_today_rounded),
            label: 'Data',
          ),
          NavigationDestination(
            icon: Icon(Icons.play_circle_filled_rounded),
            label: 'Exercises',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_rounded),
            label: 'You',
          ),
        ],
      ),
    );
  }
}
