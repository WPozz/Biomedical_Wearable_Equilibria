import 'package:flutter/material.dart';
import 'package:flutter_application/screens/dati_personali.dart';
import 'package:flutter_application/screens/impostazioni.dart';

class Profile extends StatelessWidget {
  const Profile({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('You', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: 30),
              
              // --- FOTO PROFILO ---
              Container(
                padding: const EdgeInsets.all(4), // Bordo esterno
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: colorScheme.primary.withValues(alpha: 0.3), width: 2),
                ),
                child: CircleAvatar(
                  radius: 55,
                  backgroundColor: colorScheme.primaryContainer,
                  child: Icon(Icons.person, size: 60, color: colorScheme.onPrimaryContainer),
                ),
              ),
              
              const SizedBox(height: 15),
              
              // --- NOME ---
              Text(
                'Name Surname',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 40),

              // --- LISTA OPZIONI ---
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Card(
                  elevation: 0,
                  color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3), // Sfondo grigio 
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    children: [
                      // 1. Dati Personali
                      _buildProfileTile(
                        context: context,
                        title: 'Personal Information',
                        icon: Icons.person_outline,
                        color: colorScheme.primary,
                        onTap: () => Navigator.push(
                          context, MaterialPageRoute(builder: (context) => const DatiPersonaliScreen())
                        ),
                      ),
                      
                      const Divider(height: 1, indent: 60, endIndent: 20), // Divisore 

                      // 2. Reports
                      _buildProfileTile(
                        context: context,
                        title: 'Personal reports',
                        icon: Icons.assignment_outlined,
                        color: colorScheme.primary,
                        onTap: (){

                        },
                      ),
                      
                      const Divider(height: 1, indent: 60, endIndent: 20),

                      // 3. Impostazioni

                      _buildProfileTile(
                        context: context,
                        title: 'Settings',
                        icon: Icons.settings,
                        color: colorScheme.primary,
                        onTap: () => Navigator.push(
                          context, MaterialPageRoute(builder: (context) => const ImpostazioniScreen())
                        ),
                      ),

                      const Divider(height: 1, indent: 60, endIndent: 20),

                      // 3. Log Out

                      _buildProfileTile(
                        context: context,
                        title: 'Log out',
                        icon: Icons.logout,
                        color: Colors.redAccent,
                        onTap: () => _mostraDialogoLogout(context),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper per creare le righe del menu 

  Widget _buildProfileTile({
    required BuildContext context, 
    required String title, 
    required IconData icon, 
    required Color color, 
    required VoidCallback onTap
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
        child: Icon(icon, color: color),
      ),
      title: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
      onTap: onTap,
    );
  }

  void _mostraDialogoLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          // Aggiungiamo un po' di "respiro" interno per ingrandire visivamente la finestra
          titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 10),
          contentPadding: const EdgeInsets.fromLTRB(24, 10, 24, 24),
          
          title: const Text(
            "Log Out", 
            style: TextStyle(
              fontSize: 20, 
              fontWeight: FontWeight.bold
            )
          ),
          
          content: const Text(
            "Log out of your account?", 
            style: TextStyle(fontSize: 18)
          ),
          
          actions: [
            TextButton(
              // Ingrandiamo anche il testo del bottone Annulla 
              child: const Text(
                "Cancel", 
                style: TextStyle(color: Colors.grey, fontSize: 16)
              ),
              onPressed: () => Navigator.pop(context),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: Colors.redAccent,
                // Rendiamo il bottone un po'più grande
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
              child: const Text(
                "Log out", 
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)
              ),
              onPressed: () {
                print("Log out");
                Navigator.pop(context);
              },
            ),
          ],
        );
      },
    );
  }
}

// Report
// IMPOSTAZIONI:
// - Obiettivi
// - Unità di misura
// - Notifiche
// - Modifica Password
// - Lingua