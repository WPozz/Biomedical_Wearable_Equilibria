import 'package:flutter/material.dart';

// Questo è un buon punto dove inserire Provider ()
// Provider potrebbe salvare le unità di misura preferite per ciascun utente, in modo che siano persistenti e accessibili da qualsiasi schermata che mostra dati (es. Home, Report, ecc.)
class UnitaMisuraScreen extends StatefulWidget {
  const UnitaMisuraScreen({super.key});

  @override
  State<UnitaMisuraScreen> createState() => _UnitaMisuraScreenState();
}

class _UnitaMisuraScreenState extends State<UnitaMisuraScreen> {
  // Variabili per memorizzare le scelte dell'utente
  String _energia = 'kcal'; // Opzioni: kcal, kJ
  String _distanza = 'km';  // Opzioni: km, m

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Measurement unit', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              // --- ENERGIA ---
              _buildUnitCard(
                context: context,
                title: 'Calories',
                currentValue: _energia,
                options: ['kcal', 'kJ'],
                onSelect: (val) => setState(() => _energia = val),
                colorScheme: colorScheme,
              ),

              const SizedBox(height: 12),

              // --- DISTANZA ---
              _buildUnitCard(
                context: context,
                title: 'Distance',
                currentValue: _distanza,
                options: ['km', 'm'],
                onSelect: (val) => setState(() => _distanza = val),
                colorScheme: colorScheme,
              ),
              
              const SizedBox(height: 20),
              
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Text(
                  "Selected measurement units will apply to all charts and personal reports.",
                  style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 13),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper per creare le card delle unità (identico stile alla pagina Goals)
  Widget _buildUnitCard({
    required BuildContext context,
    required String title,
    required String currentValue,
    required List<String> options,
    required Function(String) onSelect,
    required ColorScheme colorScheme,
  }) {
    return InkWell(
      onTap: () => _mostraDialogoScelta(context, title, options, currentValue, onSelect),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 25),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3), // Stesso grigio 
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title, 
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500)
            ),
            Row(
              children: [
                Text(
                  currentValue, 
                  style: TextStyle(
                    fontSize: 22, 
                    fontWeight: FontWeight.bold, 
                    color: colorScheme.primary // Mettiamo in risalto l'unità scelta col verde medico
                  )
                ),
                const SizedBox(width: 10),
                Icon(Icons.arrow_forward_ios, size: 14, color: colorScheme.onSurfaceVariant),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Dialogo per scegliere l'unità
  void _mostraDialogoScelta(
    BuildContext context, 
    String titolo, 
    List<String> opzioni, 
    String valoreAttuale,
    Function(String) onSalva
  ) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text('Scegli unità per $titolo'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: opzioni.map((opzione) {
              return RadioListTile<String>(
                title: Text(opzione),
                value: opzione,
                groupValue: valoreAttuale,
                onChanged: (String? val) {
                  if (val != null) {
                    onSalva(val);
                    Navigator.pop(context);
                  }
                },
              );
            }).toList(),
          ),
        );
      },
    );
  }
}
