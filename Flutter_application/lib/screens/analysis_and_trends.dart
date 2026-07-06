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


// TO DO:
// [fatto] - Aggiungere più lingue (italiano / inglese) ?
// [fatto] - Mettere come sviluppi futuri l'idea di un database locale per i dati utente (Solo i dati dallo smartwatch, non le preferenze)
// - Third party access 
// [fatto] - Definire lo "Stress index"
// - Implementare UserProfileProvider per gestire i dati personali e le preferenze (unità di misura, obiettivi, notifiche, ecc.). Si può fare tranquillamente con shared_preferences.
// - Caricare UserProfileProvider nel MultiProvider in main.dart. Quando l'utente preme "SAVE CHANGES", il provider deve salvare i dati in locale e fare notifyListeners().
// - Mood tracking (con grafico a linee che mostra l'andamento del mood nel tempo, e correlazione con le altre metriche) o comunque salvarlo.
// - Notifiche vere? (Sviluppi futuri)
// - Gestione errori API (es. token scaduto, server non raggiungibile, ecc.) e feedback all'utente (es. "Sessione scaduta, effettua nuovamente il login", "Impossibile connettersi al server, controlla la tua connessione internet", ecc.)
// - Splash screen con animazioni e logo app? Kairos ("time your well-being")
// - Scalatura del testo (Widget nativo FittedBox oppure installare il pacchetto auto_size_text (usatissimo). 
//   Con AutoSizeText('Testo', maxLines: 1), il testo si rimpicciolisce da solo se non c'è spazio)



// About Provider: 
// La mia idea è usare 2 provider principali:
// 1. UserProfileProvider: gestisce i dati personali dell'utente (nome, età, peso, (anche se queste dovrebbero essere ricordate a livello locale per evitare di doverli inserire ogni volta))) e le preferenze (unità di misura, obiettivi, notifiche)
// 2. DataProvider: gestisce i dati REST di home e trends (qui potremmo anche avere sotto-provider o classi di servizio per organizzare meglio, es. HomeDataProvider, TrendsDataProvider, ecc.)
// 3. AuthProvider: gestisce l'autenticazione, il login/logout e il refresh del token (conviene lasciarlo o integrarlo in UserProfileProvider? Per ora lo lascio separato per chiarezza, ma è un punto da valutare)

// Per quanto riguarda REST API, la regola è che la UI non conosca il server. 
// Le schermate leggono dal provider, il provider parla con un repository/servizio API, e il repository aggiorna il provider quando arrivano nuovi dati.
// (non arriverranno nuovi dati visto che abbiamo una banca dati limitata ma l'idea è questa).

// Credenziali: 
// USERNAME: VKM4CPfO22
// PASSWORD: 12345678! 

void main() {
  runApp(
    MultiProvider(
      providers: [
        // 1. INDEPENDENT PROVIDERS 
        // These don't rely on any other providers, so we load them normally.
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
        ChangeNotifierProvider(create: (_) => UserDataProvider()),

        // 2. DEPENDENT PROVIDERS
        // DataProvider needs AuthProvider to access the token. 
        // We use ProxyProvider to grab AuthProvider and pass it inside.
        ChangeNotifierProxyProvider<AuthProvider, DataProvider>(
          create: (context) => DataProvider(
            authProvider: Provider.of<AuthProvider>(context, listen: false),
          ),
          update: (context, authProvider, previousDataProvider) {
            // This ensures we keep the same DataProvider alive and just pass the auth info
            return previousDataProvider ?? DataProvider(authProvider: authProvider);
          },
        ),
      ],
      child: const MyApp(),
    ),
  );
}


class MyApp extends StatelessWidget { // stateless because the theme and title of the app do not change while the app is in use
  const MyApp({super.key});

  @override // I inherit the characteristics of StatelessWidget but override the build method, customizing it
  Widget build(BuildContext context) {
    
    // 1. Detect if the user's system is set to light or dark theme
    final brightness = View.of(context).platformDispatcher.platformBrightness;

    // 2. Create the text theme using the utility functions and chosen Google fonts
    TextTheme textTheme = createTextTheme(context, "Plus Jakarta Sans", "Inter");

    // 3. Initialize the MaterialTheme class with the font configuration
    MaterialTheme theme = MaterialTheme(textTheme);

    return MaterialApp(
      title: 'Kairos', // Aggiornato con il nome ufficiale dell'app!
      debugShowCheckedModeBanner: false, // rimuove l'etichetta rossa "debug"
      
      // 4. Applica automaticamente il tema chiaro o scuro basandosi sulla palette M3 esportata
      theme: theme.light().copyWith(scaffoldBackgroundColor: const Color(0xFFFAF9F6)),
      darkTheme: theme.dark().copyWith(scaffoldBackgroundColor: const Color(0xFF121212)),
      themeMode: brightness == Brightness.light ? ThemeMode.light : ThemeMode.dark,
      
      // 5. Imposta la SplashScreen come schermata iniziale assoluta
      home: const SplashScreen(), 
      
      // 6. Definisce le rotte per la navigazione successiva
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
