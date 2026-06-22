import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../screens/goals.dart';
import '../screens/notifiche.dart';
import '../providers/settings_provider.dart';



class ImpostazioniScreen extends StatelessWidget {
  const ImpostazioniScreen({super.key});
 
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final settings = context.watch<SettingsProvider>();
    final isItalian = settings.isItalian;

 
    return Scaffold(
      appBar: AppBar(
        title: Text(
          isItalian ? 'Impostazioni' : 'Settings',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: 10),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Card(
                  elevation: 0,
                  color: colorScheme.surfaceContainerHighest.withOpacity(0.3),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    children: [
 
                      // 1. Goals
                      _buildSettingsTile(
                        context: context,
                        title: isItalian ? 'Obiettivi' : 'Goals',
                        icon: Icons.emoji_events_outlined,
                        color: colorScheme.primary,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const GoalsScreen(),
                          ),
                        ),
                      ),
  
 
                      const Divider(height: 1, indent: 60, endIndent: 20),

                      // 3. Notifications
                      _buildSettingsTile(
                        context: context,
                        title: isItalian ? 'Notifiche' : 'Notifications',
                        icon: Icons.notifications_outlined,
                        color: colorScheme.primary,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const NotificheScreen(),
                          ),
                        ),
                      ),
 
                      const Divider(height: 1, indent: 60, endIndent: 20),
 
                      // 4. Language 
                      _buildLanguageTile(context, settings, colorScheme),
 
                      const Divider(height: 1, indent: 60, endIndent: 20),
 
                      // 5. Change password
                      _buildSettingsTile(
                        context: context,
                        title: isItalian ? 'Cambia password' : 'Change password',
                        icon: Icons.lock_outline,
                        color: colorScheme.primary,
                        onTap: () {},
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


  // --- Tile LINGUA con bottom sheet ---
  Widget _buildLanguageTile(BuildContext context, SettingsProvider settings, ColorScheme colorScheme) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(color: colorScheme.primary.withOpacity(0.1), shape: BoxShape.circle),
        child: Icon(Icons.language, color: colorScheme.primary),
      ),
      title: Text(
        settings.isItalian ? 'Lingua' : 'Language',
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            settings.isItalian ? 'Italiano 🇮🇹' : 'English 🇬🇧',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: colorScheme.primary),
          ),
          const SizedBox(width: 8),
          const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
        ],
      ),
      onTap: () => _mostraSceltaLingua(context, settings, colorScheme),
    );
  }

  void _mostraSceltaLingua(BuildContext context, SettingsProvider settings, ColorScheme colorScheme) {
    showModalBottomSheet(
      context: context,
      backgroundColor: colorScheme.surfaceContainerLow,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.withOpacity(0.4), borderRadius: BorderRadius.circular(10))),
                const SizedBox(height: 20),
                Text(settings.isItalian ? 'Scegli la lingua' : 'Choose language', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 20),
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                  leading: const Text('🇮🇹', style: TextStyle(fontSize: 28)),
                  title: const Text('Italiano', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
                  trailing: settings.isItalian ? Icon(Icons.check_circle, color: colorScheme.primary, size: 28) : null,
                  onTap: () {
                    context.read<SettingsProvider>().setLocale(const Locale('it'));
                    Navigator.pop(context);
                  },
                ),
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                  leading: const Text('🇬🇧', style: TextStyle(fontSize: 28)),
                  title: const Text('English', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
                  trailing: !settings.isItalian ? Icon(Icons.check_circle, color: colorScheme.primary, size: 28) : null,
                  onTap: () {
                    context.read<SettingsProvider>().setLocale(const Locale('en'));
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
 
  // --- Tile generica ---
  Widget _buildSettingsTile({
    required BuildContext context,
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
        child: Icon(icon, color: color),
      ),
      title: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
      onTap: onTap,
    );
  }
}