import 'package:flutter/material.dart';

class GoalsScreen extends StatefulWidget {
  const GoalsScreen({super.key});

  @override
  State<GoalsScreen> createState() => _GoalsScreenState();
}

class _GoalsScreenState extends State<GoalsScreen> {
  // INTERRUTTORE PRINCIPALE
  bool _obiettiviAttivi = true; 

  // Variabili per memorizzare i nostri obiettivi
  int _oreSonno = 8;
  int _minutiSonno = 00;
  int _passi = 10000;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Obiettivi', style: TextStyle(fontWeight: FontWeight.bold)),
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
              
              // --- INTERRUTTORE PRINCIPALE ---
              Card(
                elevation: 0,
                color: _obiettiviAttivi 
                    ? colorScheme.primaryContainer 
                    : colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: SwitchListTile(
                  title: const Text('Define your goals', style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(
                    _obiettiviAttivi ? 'Personal goals activated' : 'Use standard values',
                    style: const TextStyle(fontSize: 13),
                  ),
                  value: _obiettiviAttivi,
                  activeThumbColor: colorScheme.primary,
                  onChanged: (bool value) {
                    setState(() {
                      _obiettiviAttivi = value;
                    });
                  },
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
              
              const SizedBox(height: 30),

              // --- IL RESTO DELLA PAGINA (Si sbiadisce e si blocca) ---
              AnimatedOpacity(
                duration: const Duration(milliseconds: 300), // Effetto dissolvenza
                opacity: _obiettiviAttivi ? 1.0 : 0.4, // 1.0 è opaco, 0.4 è sbiadito
                child: IgnorePointer( // Blocca i tap se _obiettiviAttivi è falso
                  ignoring: !_obiettiviAttivi,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [

                      _buildGoalCard(
                        context: context,
                        title: 'Sleep duration',
                        value: '${_oreSonno}h ${_minutiSonno}min',
                        subtitle: 'Giornaliero',
                        onTap: () => _mostraDialogoSonno(context),
                        colorScheme: colorScheme,
                      ),

                      const SizedBox(height: 30),

                      _buildGoalCard(
                        context: context,
                        title: 'Steps',
                        value: _passi.toString(),
                        subtitle: 'Giornaliero',
                        onTap: () => _mostraDialogoNumerico(
                          context: context,
                          titolo: 'Imposta Passi',
                          valoreIniziale: _passi,
                          unitaDiMisura: 'passi',
                          onSalva: (nuovoValore) => setState(() => _passi = nuovoValore),
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



  // Helper per creare le Card degli obiettivi
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
            color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3), // Sfondo morbidissimo coerente con le altre pagine
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Text(
                  title, 
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500)
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    value, 
                    style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w400) 
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle, 
                    style: TextStyle(fontSize: 14, color: colorScheme.onSurfaceVariant)
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- DIALOGHI PER LA MODIFICA DEI DATI ---

  void _mostraDialogoSonno(BuildContext context) {
    int tempOre = _oreSonno;
    int tempMin = _minutiSonno;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Sleep duration'),
          content: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 60,
                child: TextFormField(
                  initialValue: tempOre.toString(),
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  onChanged: (val) => tempOre = int.tryParse(val) ?? 0,
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
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                setState(() {
                  _oreSonno = tempOre;
                  _minutiSonno = tempMin;
                });
                Navigator.pop(context);
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  void _mostraDialogoNumerico({
    required BuildContext context,
    required String titolo,
    required int valoreIniziale,
    required String unitaDiMisura,
    required Function(int) onSalva,
  }) {
    int tempValore = valoreIniziale;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(titolo),
          content: TextFormField(
            initialValue: tempValore.toString(),
            keyboardType: TextInputType.number,
            autofocus: true,
            decoration: InputDecoration(
              suffixText: unitaDiMisura,
              border: const OutlineInputBorder(),
            ),
            onChanged: (val) => tempValore = int.tryParse(val) ?? valoreIniziale,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                onSalva(tempValore);
                Navigator.pop(context);
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }
}