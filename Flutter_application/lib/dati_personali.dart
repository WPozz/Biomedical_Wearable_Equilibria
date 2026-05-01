import 'package:flutter/material.dart';

class DatiPersonaliScreen extends StatefulWidget {
  const DatiPersonaliScreen({super.key});

  @override
  State<DatiPersonaliScreen> createState() => _DatiPersonaliScreenState();
}

class _DatiPersonaliScreenState extends State<DatiPersonaliScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _etaController = TextEditingController();
  final TextEditingController _altezzaController = TextEditingController();
  final TextEditingController _pesoController = TextEditingController();

  String? _sessoSelezionato;
  String? _aziendaSelezionata;
  String? _repartoSelezionato;

  final List<String> _opzioniSesso = ['Male', 'Female', 'Other/Prefer not to say'];
  
  final Map<String, List<String>> _aziendeEReparti = {
    'Healthcare Hospital X': ['Cardiology', 'Emergency Department', 'Administration'],
    'Tech Solutions Inc.': ['Software Development', 'Human Resources', 'Marketing'],
    'Manufacturing Ltd.': ['Production', 'Logistics', 'Quality Control'],
  };

  @override
  void dispose() {
    _etaController.dispose();
    _altezzaController.dispose();
    _pesoController.dispose();
    super.dispose();
  }

  void _salvaDati() {
    if (_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Data saved successfully!', style: TextStyle(fontWeight: FontWeight.bold)),
          backgroundColor: Theme.of(context).colorScheme.primary,
          behavior: SnackBarBehavior.floating, // Stile moderno per la notifica
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      Navigator.pop(context);
    }
  }

  // Stile unificato per i campi di testo
  InputDecoration _buildInputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.2),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: BorderSide.none, // Senza bordo quando non è selezionato
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: BorderSide(color: Theme.of(context).colorScheme.primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(color: Colors.redAccent, width: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Personal information'), backgroundColor: Colors.transparent, elevation: 0),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 10.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Fill out the fields to customize your exercises.",
                  style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 16),
                ),
                const SizedBox(height: 30),

                TextFormField(
                  controller: _etaController,
                  keyboardType: TextInputType.number,
                  decoration: _buildInputDecoration('Age *'),
                  validator: (value) => value!.isEmpty ? 'Enter your age' : null,
                ),
                const SizedBox(height: 20),

                DropdownButtonFormField<String>(
                  decoration: _buildInputDecoration('Gender *'),
                  initialValue: _sessoSelezionato,
                  items: _opzioniSesso.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                  onChanged: (val) => setState(() => _sessoSelezionato = val),
                  validator: (value) => value == null ? 'Select gender' : null,
                ),
                const SizedBox(height: 20),

                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _altezzaController,
                        keyboardType: TextInputType.number,
                        decoration: _buildInputDecoration('Height (cm) *'),
                        validator: (value) => value!.isEmpty ? 'Required' : null,
                      ),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: TextFormField(
                        controller: _pesoController,
                        keyboardType: TextInputType.number,
                        decoration: _buildInputDecoration('Weight (kg) *'),
                        validator: (value) => value!.isEmpty ? 'Required' : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                DropdownButtonFormField<String>(
                  decoration: _buildInputDecoration('Azienda *'),
                  initialValue: _aziendaSelezionata,
                  items: _aziendeEReparti.keys.map((a) => DropdownMenuItem(value: a, child: Text(a))).toList(),
                  onChanged: (val) {
                    setState(() {
                      _aziendaSelezionata = val;
                      _repartoSelezionato = null; 
                    });
                  },
                  validator: (value) => value == null ? 'Select your company' : null,
                ),
                const SizedBox(height: 20),

                DropdownButtonFormField<String>(
                  decoration: _buildInputDecoration('Department *'),
                  initialValue: _repartoSelezionato,
                  disabledHint: const Text("Select a company first"),
                  items: _aziendaSelezionata == null 
                    ? [] 
                    : _aziendeEReparti[_aziendaSelezionata]!.map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
                  onChanged: (val) => setState(() => _repartoSelezionato = val),
                  validator: (value) => value == null ? 'Select your department' : null,
                ),

                const SizedBox(height: 40),

                // BOTTONE SALVA STILE "RICERCA ESERCIZI"
                ElevatedButton(
                  onPressed: _salvaDati,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.primary,
                    foregroundColor: colorScheme.onPrimary,
                    minimumSize: const Size(double.infinity, 65), 
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    elevation: 2,
                  ),
                  child: const Text('SAVE CHANGES', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}