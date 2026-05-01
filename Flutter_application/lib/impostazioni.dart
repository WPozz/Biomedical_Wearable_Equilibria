import 'package:flutter/material.dart';
import 'package:flutter_application/screens/goals.dart';
import 'package:flutter_application/screens/notifiche.dart';
import 'package:flutter_application/screens/unita_misura.dart';

class ImpostazioniScreen extends StatelessWidget {
  const ImpostazioniScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: 20),
              
              // --- LISTA IMPOSTAZIONI ---
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Card(
                  elevation: 0,
                  color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    children: [

                      // 1. Goals
                      _buildSettingsTile(
                        context: context,
                        title: 'Goals',
                        icon: Icons.emoji_events_outlined, // Icona della coppa/obiettivo
                        color: colorScheme.primary,
                        onTap: () => Navigator.push(
                          context, MaterialPageRoute(builder: (context) => const GoalsScreen()),
                       ),
                      ), 
                      
                      const Divider(height: 1, indent: 60, endIndent: 20),

                      // 2. Measurement units
                      _buildSettingsTile(
                        context: context,
                        title: 'Measurement units',
                        icon: Icons.straighten, // Icona del righello
                        color: colorScheme.primary,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const UnitaMisuraScreen()),
                          );
                        },
                      ),
                      
                      const Divider(height: 1, indent: 60, endIndent: 20),

                      // 3. Notifications (Collegato alla tua pagina!)
                      _buildSettingsTile(
                        context: context,
                        title: 'Notifications',
                        icon: Icons.notifications_outlined,
                        color: colorScheme.primary,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const NotificheScreen()),
                          );
                        },
                      ),
                      
                      const Divider(height: 1, indent: 60, endIndent: 20),

                      // 4. Change password
                      _buildSettingsTile(
                        context: context,
                        title: 'Change password',
                        icon: Icons.lock_outline,
                        color: colorScheme.primary,
                        onTap: (){},
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

  // Riutilizziamo il tuo fantastico design per le righe
  Widget _buildSettingsTile({
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
}