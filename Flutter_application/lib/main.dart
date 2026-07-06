import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; 
import 'theme.dart'; 
import 'util.dart';
import 'main_wrapper.dart';
import 'providers/auth_provider.dart'; 
import 'providers/data_provider.dart';
import 'screens/loginpage.dart'; 
import 'screens/splash_screen.dart';
import 'providers/settings_provider.dart';
import 'providers/userdata_provider.dart';


void main() {
  runApp(
    MultiProvider(
      providers: [
        // INDEPENDENT PROVIDERS .
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
        ChangeNotifierProvider(create: (_) => UserDataProvider()),

        // DEPENDENT PROVIDERS
        ChangeNotifierProxyProvider<AuthProvider, DataProvider>(
          create: (context) => DataProvider(
            authProvider: Provider.of<AuthProvider>(context, listen: false),
          ),
          update: (context, authProvider, previousDataProvider) {
            return previousDataProvider ?? DataProvider(authProvider: authProvider);
          },
        ),
      ],
      child: const MyApp(),
    ),
  );
}


class MyApp extends StatelessWidget { 
  const MyApp({super.key});

  @override 
  Widget build(BuildContext context) {
    
    // Detect if the user's system is set to light or dark theme
    final brightness = View.of(context).platformDispatcher.platformBrightness;

    // Text theme
    TextTheme textTheme = createTextTheme(context, "Plus Jakarta Sans", "Inter");

    MaterialTheme theme = MaterialTheme(textTheme);

    return MaterialApp(
      title: 'Kairos', 
      debugShowCheckedModeBanner: false, 
      theme: theme.light().copyWith(scaffoldBackgroundColor: const Color(0xFFFAF9F6)),
      darkTheme: theme.dark().copyWith(scaffoldBackgroundColor: const Color(0xFF121212)),
      themeMode: brightness == Brightness.light ? ThemeMode.light : ThemeMode.dark,
      home: const SplashScreen(), 
      
      routes: {
        '/auth_gate': (context) => Consumer<AuthProvider>(
          builder: (context, authProvider, child) {
            return authProvider.isAuthenticated 
                ? const MainWrapper()
                : const LoginPage();
          },
        ),
      },

 
    );
  }
}