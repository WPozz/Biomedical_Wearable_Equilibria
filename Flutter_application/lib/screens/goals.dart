import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_application/providers/settings_provider.dart';
import 'package:flutter_application/providers/data_provider.dart';

class GoalsScreen extends StatefulWidget {
  const GoalsScreen({super.key});

  @override
  State<GoalsScreen> createState() => _GoalsScreenState();
}

class _GoalsScreenState extends State<GoalsScreen> {
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final settings = context.watch<SettingsProvider>();
    final isItalian = settings.isItalian;

    return Scaffold(
      appBar: AppBar(
        title: Text(isItalian ? 'Obiettivi' : 'Goals', style: const TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Card(
                elevation: 0,
                color: settings.customGoalsEnabled 
                    ? colorScheme.primaryContainer 
                    : colorScheme.surfaceContainerHighest.withOpacity(0.5),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: SwitchListTile(
                  title: Text(isItalian ? 'Definisci i tuoi obiettivi' : 'Define your goals', style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(
                    settings.customGoalsEnabled 
                        ? (isItalian ? 'Obiettivi personalizzati attivi' : 'Custom goals enabled') 
                        : (isItalian ? 'Usa valori predefiniti' : 'Use default values'),
                    style: const TextStyle(fontSize: 13),
                  ),
                  value: settings.customGoalsEnabled,
                  activeColor: colorScheme.primary,
                  onChanged: (bool value) {
                    context.read<SettingsProvider>().setCustomGoalsEnabled(value);
                    context.read<DataProvider>().clearArchiveCache();
                  },
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
              
              const SizedBox(height: 30),

              AnimatedOpacity(
                duration: const Duration(milliseconds: 300),
                opacity: settings.customGoalsEnabled ? 1.0 : 0.4,
                child: IgnorePointer(
                  ignoring: !settings.customGoalsEnabled,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildGoalCard(
                        context: context,
                        title: isItalian ? 'Durata sonno' : 'Sleep duration',
                        value: '${settings.sleepHours}h ${settings.sleepMinutes}min',
                        subtitle: isItalian ? 'Quotidiano' : 'Daily',
                        onTap: () => _showSleepDialog(context, settings, isItalian),
                        colorScheme: colorScheme,
                      ),

                      const SizedBox(height: 30),

                      _buildGoalCard(
                        context: context,
                        title: isItalian ? 'Passi' : 'Steps',
                        value: settings.steps.toString(),
                        subtitle: isItalian ? 'Quotidiano' : 'Daily',
                        onTap: () => _showNumericDialog(
                          context: context,
                          title: isItalian ? 'Imposta passi' : 'Set steps', 
                          startingValue: settings.steps,
                          measurementUnit: isItalian ? 'passi' : 'steps',
                          onSave: (newValue) => context.read<SettingsProvider>().setStepsGoal(newValue),
                          isItalian: isItalian,
                        ),
                        colorScheme: colorScheme,
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

  Widget _buildGoalCard({
    required BuildContext context,
    required String title,
    required String value,
    required String subtitle,
    required VoidCallback onTap,
    required ColorScheme colorScheme,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 25),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest.withOpacity(0.3), 
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(value, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w400)),
                  const SizedBox(height: 4),
                  Text(subtitle, style: TextStyle(fontSize: 14, color: colorScheme.onSurfaceVariant)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSleepDialog(BuildContext context, SettingsProvider settings, bool isItalian) {
    int tempHours = settings.sleepHours;
    int tempMin = settings.sleepMinutes;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(isItalian ? 'Durata sonno' : 'Sleep duration'),
          content: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 60,
                child: TextFormField(
                  initialValue: tempHours.toString(),
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  onChanged: (val) => tempHours = int.tryParse(val) ?? 0,
                  decoration: const InputDecoration(suffixText: 'h'),
                ),
              ),
              const SizedBox(width: 20),
              SizedBox(
                width: 80,
                child: TextFormField(
                  initialValue: tempMin.toString(),
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  onChanged: (val) => tempMin = int.tryParse(val) ?? 0,
                  decoration: const InputDecoration(suffixText: 'min'),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(isItalian ? 'Annulla' : 'Cancel'),
            ),
            FilledButton(
              onPressed: () {
                context.read<SettingsProvider>().setSleepGoal(tempHours, tempMin); 
                context.read<DataProvider>().clearArchiveCache(); 
                Navigator.pop(context);
              },
              child: Text(isItalian ? 'Salva' : 'Save'),
            ),
          ],
        );
      },
    );
  }

  void _showNumericDialog({
    required BuildContext context,
    required String title,
    required int startingValue,
    required String measurementUnit,
    required Function(int) onSave,
    required bool isItalian,
  }) {
    int tempValue = startingValue;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(title), 
          content: TextFormField(
            initialValue: tempValue.toString(), // Questo DEVE restare initialValue
            keyboardType: TextInputType.number,
            autofocus: true,
            decoration: InputDecoration(
              suffixText: measurementUnit,
              border: const OutlineInputBorder(),
            ),
            onChanged: (val) => tempValue = int.tryParse(val) ?? startingValue,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(isItalian ? 'Annulla' : 'Cancel'),
            ),
            FilledButton(
              onPressed: () {
                onSave(tempValue); 
                context.read<DataProvider>().clearArchiveCache(); 
                Navigator.pop(context);
              },
              child: Text(isItalian ? 'Salva' : 'Save'),
            ),
          ],
        );
      },
    );
  }
}
