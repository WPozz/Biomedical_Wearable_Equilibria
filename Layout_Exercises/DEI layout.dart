import 'package:flutter/material.dart';

void main() {
  runApp(const ReproduceLayoutApp());
}

class ReproduceLayoutApp extends StatelessWidget {
  const ReproduceLayoutApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Reproduce Layout',
      theme: ThemeData(
        useMaterial3: true,
      ),
      home: const Exercise01Page(),
    );
  }
}

class Exercise01Page extends StatelessWidget {
  const Exercise01Page({super.key});

  @override
  Widget build(BuildContext context) {
    // Scaffold provides the main structure (AppBar, Body, FAB)
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.red[500],
        title: const Text(
          'DEI - UNIPD',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.w500,
          ),
        ),
        centerTitle: true,
        elevation: 0,
      ),
      // SingleChildScrollView ensures the screen doesn't break on smaller phones
      body: SingleChildScrollView(
        child: Column(
          children: [
            // 1. Title and Location Row
            Padding(
              padding: const EdgeInsets.all(32.0),
              child: Row(
                children: [
                  // Expanded pushes the heart icon to the far right
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'via G. Gradenigo 6/B, 35131',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Padova (PD), Italy',
                          style: TextStyle(
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.favorite, color: Colors.black87),
                ],
              ),
            ),
            
            // 2. The Three Buttons Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildIconColumn(Icons.phone, 'CALL'),
                _buildIconColumn(Icons.directions, 'DIRECTIONS'),
                _buildIconColumn(Icons.share, 'SHARE'),
              ],
            ),
            
            // 3. The Body Text
            const Padding(
              padding: EdgeInsets.all(32.0),
              child: Text(
                "The Department's teaching and research activities primarily concern the area of Information Engineering, which includes the following disciplines: applied optics, bioengineering, computer science, electronics, operational research, systems and control theory, and telecommunications. The Department coordinates 9 first- and second-level degree programmes and a doctoral school, providing students with 15 laboratories (hosting over 150 workstations), free WiFi access and a library with over 20,000 volumes.",
                style: TextStyle( 
                  fontSize: 16,
                  height: 1.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Helper method to build the icon + label column
Widget _buildIconColumn(IconData icon, String label) {
  return Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, color: Colors.red[500]),
      const SizedBox(height: 8),
      Text(
        label,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    ],
  );
}

//
