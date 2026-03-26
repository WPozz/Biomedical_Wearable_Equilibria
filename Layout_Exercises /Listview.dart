import 'package:flutter/material.dart';

void main() {
  runApp(const ReproduceLayoutApp());
}

class ReproduceLayoutApp extends StatelessWidget {
  const ReproduceLayoutApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: true, // Keeps the "DEBUG" banner shown in your image
      title: 'Layout Exercise',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        scaffoldBackgroundColor: Colors.white,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black87,
        ),
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatelessWidget {
  const MyHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    // The data for the list view
    final List<String> listItems = ['CHIP', 'BAY', 'GREEN', 'DEAR'];

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () {},
        ),
        title: const Text(
          'The AppBar',
          style: TextStyle(fontSize: 18),
        ),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.error), 
            color: Colors.black54,
            onPressed: () {},
          ),
          const SizedBox(width: 8), // Small padding on the right edge
        ],
      ),
      body: ListView.builder(
        itemCount: listItems.length,
        itemBuilder: (context, index) {
          return ListTile(
            leading: const Icon(Icons.info, color: Colors.black54),
            title: Text(
              listItems[index],
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                letterSpacing: 1.1,
                color: Colors.black87,
              ),
            ),
            // Icons.arrow_right is a filled triangle just like in the image
            trailing: const Icon(Icons.arrow_right, color: Colors.black54), 
            onTap: () {},
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        backgroundColor: const Color(0xFFE8DDFF), // Matches the light purple tint
        elevation: 2,
        child: const Icon(Icons.add, color: Colors.black87),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        selectedItemColor: Colors.deepPurple,
        unselectedItemColor: Colors.grey,
        backgroundColor: Colors.white,
        elevation: 8,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.group),
            label: 'Profile',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
