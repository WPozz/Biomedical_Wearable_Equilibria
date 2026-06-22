import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter_application_1/screens/pausa_attiva.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';



class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedEmojiIndex = -1;
  final List<String> _emojis = ['😫', '🙁', '😐', '🙂', '😁'];

  // Dati simulati
  final int _stressLevel = 10; 

  // Variabili per l'animazione del blob
  double _radiusMultiplier = 1.0;
  late Timer _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 2), (timer) {
      if (mounted) {
        setState(() {
          _radiusMultiplier = _radiusMultiplier == 1.0 ? 1.1 : 1.0;
        });
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  Color _getStressColor(int level, {bool forText = false}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (level < 30) {
      if (forText) return isDark ? const Color(0xFF6EE7A0) : const Color(0xFF166534);
      return isDark ? const Color(0xFF1A4D2E) : const Color(0xFF5DF091);
    }
    if (level < 60) {
      if (forText) return isDark ? const Color(0xFFFDE68A) : const Color(0xFF92400E);
      return isDark ? const Color(0xFF4D3A00) : const Color(0xFFEDDC5C);
    }
    if (level < 80) {
      if (forText) return isDark ? const Color(0xFFFBBF24) : const Color(0xFF9A3412);
      return isDark ? const Color(0xFF4D2A00) : const Color(0xFFF5AA49);
    }
    // Stress alto
    if (forText) return isDark ? const Color(0xFFF87171) : const Color(0xFF991B1B);
    return isDark ? const Color(0xFF4D1515) : const Color(0xFFDF6868);
  }

  // Aggiunto il parametro isItalian per tradurre le label in base alla lingua
  String _getStressLabel(int level, bool isItalian) {
    if (level < 30) return isItalian ? "Rilassato" : "Relaxed";
    if (level < 60) return isItalian ? "Livello di stress moderato" : "Moderate stress level";
    if (level < 80) return isItalian ? "Livello di stress alto" : "High stress level";
    return isItalian ? "Livello di stress molto alto" : "Very high stress level";
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    // Ascolta i cambiamenti di lingua dal provider
    final isItalian = context.watch<SettingsProvider>().isItalian; 

    return Scaffold(
      appBar: AppBar(
        title: const Text("Kairos", style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // --- 1. IL BLOB DINAMICO ---
                Column(
                  children: [
                    const SizedBox(height: 20),
                    AnimatedContainer(
                      duration: const Duration(seconds: 2),
                      curve: Curves.easeInOut,
                      width: 180 * _radiusMultiplier,
                      height: 180,
                      decoration: BoxDecoration(
                        color: _getStressColor(_stressLevel).withOpacity(
                          Theme.of(context).brightness == Brightness.dark ? 0.75 : 0.4
                        ),
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(80 * _radiusMultiplier),
                          topRight: Radius.circular(100 / _radiusMultiplier),
                          bottomLeft: Radius.circular(90 / _radiusMultiplier),
                          bottomRight: Radius.circular(70 * _radiusMultiplier),
                        ),
                      ),
                      child: Center(
                        child: Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.black.withOpacity(0.15)
                            : Colors.white.withOpacity(0.5),
                            ),
                          child: Center(
                            child: Text(
                              "$_stressLevel",
                              style: TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: _getStressColor(_stressLevel, forText: true),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      _getStressLabel(_stressLevel, isItalian),
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: _getStressColor(_stressLevel, forText: true),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 40),

                // --- 2. EMOJI BAR ---
                Text(
                  isItalian ? "Come ti senti oggi?" : "How are you feeling today?",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 18, 
                    color: colorScheme.onSurfaceVariant 
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: List.generate(_emojis.length, (index) {
                  bool isSelected = _selectedEmojiIndex == index;
                  bool isDimmed = _selectedEmojiIndex != -1 && !isSelected;

                  return GestureDetector(
                    onTap: () => setState(() => _selectedEmojiIndex = index),
                    child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 300),
                    opacity: isDimmed ? 0.3 : 1.0,
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 400),
                      transitionBuilder: (child, anim) => ScaleTransition(scale: anim, child: child),
                      child: isSelected
                      ? Stack(
                          alignment: Alignment.center,
                          children: [
                            
                            const Icon(Icons.check_circle, color: Colors.green, size: 40, key: ValueKey('check')),
                          ],
                        )
                      : Text(_emojis[index], style: const TextStyle(fontSize: 30), key: ValueKey('emoji$index')),
                    ),
                  ),
                );
              }),
            ),
                const SizedBox(height: 40),
                
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const PausaAttivaScreen()),
                    );
                  },
                  icon: const Icon(Icons.emoji_people, size: 40), 
                  label: Text(
                    isItalian ? "Pausa attiva" : "Active break", // Testo tradotto
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)
                  ),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 110), 
                    backgroundColor: colorScheme.primaryContainer,
                    foregroundColor: colorScheme.onPrimaryContainer,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                    elevation: 0,
                  ),
                ),
                const SizedBox(height: 40),
                Text(
                  isItalian ? "Attività" : "Activity",
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)
                ),
                const SizedBox(height: 16),
                _buildMetricGrid(context, isItalian),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Modificato per ricevere isItalian
  Widget _buildMetricGrid(BuildContext context, bool isItalian) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                context, 
                isItalian ? "Durata sonno" : "Sleep Duration", 
                "7h 20m", 
                Icons.nights_stay, 
                colorScheme.primary, 
                0.9
              )
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricCard(
                context, 
                isItalian ? "Passi" : "Steps",
                "6.430", 
                Icons.bolt, 
                colorScheme.secondary, 
                0.65
              )
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                context, 
                isItalian ? "Calorie" : "Calories", 
                "320 kcal", 
                Icons.local_fire_department, 
                colorScheme.tertiary, 
                0.0
              )
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricCard(
                context, 
                isItalian ? "Distanza" : "Distance", 
                "20 km", 
                Icons.favorite, 
                colorScheme.error, 
                0.0
              )
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMetricCard(BuildContext context, String title, String value, IconData icon, Color color, double progress) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Material(
      color: colorScheme.surfaceContainerLow, 
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        onTap: () => print("Naviga a $title"),
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(fontSize: 15, color: colorScheme.onSurfaceVariant),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              
              
              if (progress > 0)
                SizedBox(
                  width: 46, 
                  height: 46,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      // 1. Traccia vuota
                      CircularProgressIndicator(
                        value: 1.0,
                        strokeWidth: 4,
                        valueColor: AlwaysStoppedAnimation<Color>(color.withOpacity(0.1)),
                      ),
                      // 2. Progresso effettivo
                      CircularProgressIndicator(
                        value: progress,
                        strokeWidth: 4,
                        strokeCap: StrokeCap.round,
                        valueColor: AlwaysStoppedAnimation<Color>(color),
                      ),
                      // 3. Simbolo
                      Center(
                        child: Icon(
                          icon, 
                          color: color, 
                          size: 16, 
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}