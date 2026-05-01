import 'package:flutter/material.dart';

class NotificheScreen extends StatefulWidget {
  const NotificheScreen({super.key});

  @override
  State<NotificheScreen> createState() => _NotificheScreenState();
}

class _NotificheScreenState extends State<NotificheScreen> {
  bool _notificheAttive = true;
  bool _promemoriaPausa = true;
  bool _promemoriaAcqua = false;
  bool _goals = true;



  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10),
        children: [
          Text(
            "Manage how and when the app can send you health tips.",
            style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 16), 
          ),
          const SizedBox(height: 30),
          
          // Raggruppamento in una Card
          Card(
            elevation: 0,
            color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                SwitchListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  title: const Text('Enable notifications', style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: const Text('Allow the app to send you alerts'),
                  value: _notificheAttive,
                  activeThumbColor: colorScheme.primary,
                  onChanged: (bool value) {
                    setState(() {
                      _notificheAttive = value;
                      if (!value) {
                        _promemoriaPausa = false;
                        _promemoriaAcqua = false;
                      }
                    });
                  },
                  secondary: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: colorScheme.primary.withValues(alpha: 0.1), shape: BoxShape.circle),
                    child: Icon(Icons.notifications_active, color: colorScheme.primary),
                  ),
                ),
                
                const Divider(height: 1, indent: 70, endIndent: 20),
                
                SwitchListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  title: const Text('Break reminders', style: TextStyle(fontWeight: FontWeight.w500)),
                  subtitle: const Text('Notify me when I\'ve been inactive for too long'),
                  value: _promemoriaPausa,
                  activeThumbColor: colorScheme.primary,
                  onChanged: _notificheAttive ? (bool value) => setState(() => _promemoriaPausa = value) : null,
                  secondary: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: Colors.blue.withValues(alpha: 0.1), shape: BoxShape.circle),
                    child: const Icon(Icons.timer, color: Colors.blue),
                  ),
                ),

                SwitchListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  title: const Text('Hydration', style: TextStyle(fontWeight: FontWeight.w500)),
                  subtitle: const Text('Remind me to drink water during the day'),
                  value: _promemoriaAcqua,
                  activeThumbColor: colorScheme.primary,
                  onChanged: _notificheAttive ? (bool value) => setState(() => _promemoriaAcqua = value) : null,
                  secondary: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: Colors.blue.withValues(alpha: 0.1), shape: BoxShape.circle),
                    child: const Icon(Icons.water_drop, color: Colors.blue),
                  ),
                ),
                
                SwitchListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  title: const Text('Goals', style: TextStyle(fontWeight: FontWeight.w500)),
                  subtitle: const Text('Notify me when I reach my daily goals'),
                  value: _goals,
                  activeThumbColor: colorScheme.primary,
                  onChanged: _notificheAttive ? (bool value) => setState(() => _goals = value) : null,
                  secondary: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: Colors.blue.withValues(alpha: 0.1), shape: BoxShape.circle),
                    child: const Icon(Icons.emoji_events_outlined, color: Colors.blue),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}