import 'package:flutter/material.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  // Variable to control the opacity for our fade-in animation
  double _opacity = 0.0;

  @override
  void initState() {
    super.initState();
    // This forces Flutter to wait until the screen is physically drawn
    // before it triggers your initialization, timer, and animation!
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() {
        _opacity = 1.0; // Trigger the fade-in
      });
      _initializeApp();
    });
  }

  Future<void> _initializeApp() async {
    // 2.5-second timer
    await Future.delayed(const Duration(milliseconds: 2500));
    if (mounted) {
      Navigator.pushReplacementNamed(context, '/auth_gate');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Access the current theme colors (handles both Light and Dark modes automatically)
    final colorScheme = Theme.of(context).colorScheme;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      // 1. Use the theme's surface color instead of hardcoded white
      backgroundColor: colorScheme.surface, 
      body: Center(
        // 2. Add a smooth fade-in animation
        child: AnimatedOpacity(
          opacity: _opacity,
          duration: const Duration(milliseconds: 1200), // 1.2 second fade
          curve: Curves.easeIn,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // NOTE: If your logo text is black and disappears in dark mode, 
              // consider checking 'isDarkMode' and swapping the asset here!
              // Example: Image.asset(isDarkMode ? 'assets/images/Kairos_Logo_Dark.png' : 'assets/images/Kairos_Logo.png')
              Image.asset(
                'assets/images/Kairos_Logo.png',
                width: 250,
              ),
              const SizedBox(height: 50),
              CircularProgressIndicator(
                // 3. Use the theme's primary color for the spinner
                color: colorScheme.primary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}