import 'package:flutter/material.dart';
import 'package:flutter_application_1/main_wrapper.dart'; 
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart'; // Assicurati che il percorso sia corretto rispetto a dove hai creato la cartella providers

// Delegated Authorization: Google, Facebook, ... how? (OAuth, go to the Google server and register the app, Google will give us an API Key to authenticate our app to their servers (we'll pay for the tokens)). 


class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  
  InputDecoration _buildInputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.2),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: BorderSide(color: Theme.of(context).colorScheme.primary, width: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo o Icona
                Icon(Icons.sentiment_satisfied_alt_rounded, size: 80, color: colorScheme.primary),
                const SizedBox(height: 30),
                
                // Testo di benvenuto
                Text(
                  "Welcome Back",
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                Text(
                  "Log in to monitor your stress levels",
                  style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 16),
                ),
                const SizedBox(height: 40),

                // Campo Email
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: _buildInputDecoration('Email'),
                ),
                const SizedBox(height: 20),

                // Campo Password
                TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: _buildInputDecoration('Password'),
                ),
                const SizedBox(height: 40),

                // Bottone Log In
                ElevatedButton.icon(
  onPressed: () {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const MainWrapper()),
    );
  },
  style: ElevatedButton.styleFrom(
    backgroundColor: colorScheme.primary,
    foregroundColor: colorScheme.onPrimary,
    minimumSize: const Size(double.infinity, 65),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
    elevation: 2,
  ),
  icon: const Icon(Icons.login, size: 22),
  label: const Text('LOG IN', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
),

ElevatedButton.icon(
  onPressed: () async {
    // Leggiamo il provider senza metterci in ascolto
    final authProvider = context.read<AuthProvider>();
    
    // Usiamo il controller per le credenziali (nel documento del prof era Jpefaq6m58 come username)
    bool success = await authProvider.login(
      _emailController.text, // Modifica l'etichetta dell'input in "Username" se preferisci
      _passwordController.text 
    );

    if (success) {
      if (context.mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const MainWrapper()),
        );
      }
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Login fallito! Controlla le credenziali.')),
        );
      }
    }
  },
  // ... resto dello stile del bottone ...
style: ElevatedButton.styleFrom(
  backgroundColor: colorScheme.primary,
  foregroundColor: colorScheme.onPrimary,
  minimumSize: const Size(double.infinity, 65),
  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
  elevation: 2,
),
icon: const Icon(Icons.fiber_new_rounded, size: 22),
label: const Text('SIGN UP', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
), 
              ],
            ),
          ),
        ),
      ),
    );
  }
}