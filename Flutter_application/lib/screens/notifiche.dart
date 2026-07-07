import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_application/providers/settings_provider.dart';

class NotificheScreen extends StatelessWidget {
  const NotificheScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final settings    = context.watch<SettingsProvider>();
    final isItalian   = settings.isItalian;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          isItalian ? 'Notifiche' : 'Notifications',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10),
        children: [
          Text(
            isItalian
                ? "Gestisci come e quando l'app ti invia suggerimenti per la salute."
                : "Manage how and when the app sends you health suggestions.",
            style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 16),
          ),
          const SizedBox(height: 30),

          // ── Notifications card ──────────────────────────
          Card(
            elevation: 0,
            color: colorScheme.surfaceContainerHighest.withOpacity(0.3),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                // Master switch
                _buildSwitch(
                  context: context,
                  icon: Icons.notifications_active,
                  iconColor: colorScheme.primary,
                  title: isItalian ? 'Abilita notifiche' : 'Enable notifications',
                  subtitle: isItalian
                      ? "Permetti all'app di inviarti avvisi"
                      : 'Allow the app to send you alerts',
                  value: settings.notificationsEnabled,
                  onChanged: (v) => context.read<SettingsProvider>().setNotificationsEnabled(v),
                  bold: true,
                ),

                const Divider(height: 1, indent: 70, endIndent: 20),
                
                _buildSwitch(
                  context: context,
                  icon: Icons.timer,
                  iconColor: Colors.blue,
                  title: isItalian ? 'Promemoria Pausa' : 'Break Reminder',
                  subtitle: isItalian
                      ? 'Avvisami se sono inattivo da troppo tempo'
                      : "Notify me if I'm inactive for too long",
                  value: settings.breakReminder,
                  onChanged: settings.notificationsEnabled
                      ? (v) => context.read<SettingsProvider>().setBreakReminder(v)
                      : null,
                ),

                const Divider(height: 1, indent: 70, endIndent: 20),

                _buildSwitch(
                  context: context,
                  icon: Icons.water_drop,
                  iconColor: Colors.blue,
                  title: isItalian ? 'Idratazione' : 'Hydration',
                  subtitle: isItalian
                      ? 'Ricordami di bere acqua durante il giorno'
                      : 'Remind me to drink water during the day',
                  value: settings.hydrationReminder,
                  onChanged: settings.notificationsEnabled
                      ? (v) => context.read<SettingsProvider>().setHydrationReminder(v)
                      : null,
                ),

                const Divider(height: 1, indent: 70, endIndent: 20),

                _buildSwitch(
                  context: context,
                  icon: Icons.emoji_events_outlined,
                  iconColor: Colors.blue,
                  title: isItalian ? 'Obiettivi' : 'Goals',
                  subtitle: isItalian
                      ? 'Avvisami quando raggiungo i miei obiettivi'
                      : 'Notify me when I reach my goals',
                  value: settings.goalsNotification,
                  onChanged: settings.notificationsEnabled
                      ? (v) => context.read<SettingsProvider>().setGoalsNotification(v)
                      : null,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSwitch({
    required BuildContext context,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool>? onChanged,
    bool bold = false,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return SwitchListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      secondary: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: iconColor.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: iconColor),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: bold ? FontWeight.bold : FontWeight.w500,
        ),
      ),
      subtitle: Text(subtitle),
      value: value,
      activeThumbColor: colorScheme.primary,
      onChanged: onChanged,
    );
  }
}
