import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_application/providers/userdata_provider.dart';
import 'package:flutter_application/providers/settings_provider.dart';

class DatiPersonaliScreen extends StatefulWidget {
  const DatiPersonaliScreen({super.key});

  @override
  State<DatiPersonaliScreen> createState() => _DatiPersonaliScreenState();
}

class _DatiPersonaliScreenState extends State<DatiPersonaliScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _nomeController = TextEditingController();
  final TextEditingController _cognomeController = TextEditingController();
  final TextEditingController _etaController = TextEditingController();
  final TextEditingController _altezzaController = TextEditingController();
  final TextEditingController _pesoController = TextEditingController();

  String? _sessoSelezionato;
  String? _aziendaSelezionata;
  String? _repartoSelezionato;
  
  String _altezzaUnit = 'cm'; 
  String _pesoUnit = 'kg';

  final List<String> _opzioniSesso = ['Male', 'Female', 'Other/Prefer not to say'];
  
  final Map<String, List<String>> _aziendeEReparti = {
    'Healthcare Hospital X': ['Cardiology', 'Emergency Department', 'Administration'],
    'Tech Solutions Inc.': ['Software Development', 'Human Resources', 'Marketing'],
    'Manufacturing Ltd.': ['Production', 'Logistics', 'Quality Control'],
  };

  String _translateGender(String gender, bool isItalian) {
    if (!isItalian) return gender;
    switch (gender) {
      case 'Male': return 'Uomo';
      case 'Female': return 'Donna';
      case 'Other/Prefer not to say': return 'Altro / Preferisco non dirlo';
      default: return gender;
    }
  }

  String _translateDept(String dept, bool isItalian) {
    if (!isItalian) return dept;
    switch (dept) {
      case 'Cardiology': return 'Cardiologia';
      case 'Emergency Department': return 'Pronto Soccorso';
      case 'Administration': return 'Amministrazione';
      case 'Software Development': return 'Sviluppo Software';
      case 'Human Resources': return 'Risorse Umane';
      case 'Production': return 'Produzione';
      case 'Logistics': return 'Logistica';
      case 'Quality Control': return 'Controllo Qualità';
      default: return dept;
    }
  }

  @override
  void initState() {
    super.initState();
    
    final userData = Provider.of<UserDataProvider>(context, listen: false);

    _nomeController.text = userData.firstName;
    _cognomeController.text = userData.lastName;
    
    if (userData.age != null) _etaController.text = userData.age.toString();
    if (userData.height != null) _altezzaController.text = userData.height.toString();
    if (userData.weight != null) _pesoController.text = userData.weight.toString();
    
    _sessoSelezionato = userData.gender;
    _aziendaSelezionata = userData.company;
    _repartoSelezionato = userData.department;
    
    _altezzaUnit = userData.heightUnit;
    _pesoUnit = userData.weightUnit;
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _cognomeController.dispose();
    _etaController.dispose();
    _altezzaController.dispose();
    _pesoController.dispose();
    super.dispose();
  }

  void _salvaDati() async {
    if (_formKey.currentState!.validate()) {
      int eta = int.parse(_etaController.text);
      double altezza = double.parse(_altezzaController.text);
      double peso = double.parse(_pesoController.text);

      await Provider.of<UserDataProvider>(context, listen: false).updateProfile(
        firstName: _nomeController.text.trim(),
        lastName: _cognomeController.text.trim(),
        age: eta,
        gender: _sessoSelezionato!,
        height: altezza,
        weight: peso,
        company: _aziendaSelezionata!,
        department: _repartoSelezionato!,
        heightUnit: _altezzaUnit, 
        weightUnit: _pesoUnit,    
      );

      if (!mounted) return;

      final isItalian = Provider.of<SettingsProvider>(context, listen: false).isItalian;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isItalian ? 'Dati salvati con successo!' : 'Data saved successfully!', 
            style: const TextStyle(fontWeight: FontWeight.bold)
          ),
          backgroundColor: Theme.of(context).colorScheme.primary,
          behavior: SnackBarBehavior.floating, 
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      Navigator.pop(context);
    }
  }

  InputDecoration _buildInputDecoration(String label, {Widget? suffixIcon}) {
    return InputDecoration(
      labelText: label,
      suffixIcon: suffixIcon, 
      filled: true,
      fillColor: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.2),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: BorderSide.none, 
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
    final isItalian = context.watch<SettingsProvider>().isItalian; 

    return Scaffold(
      appBar: AppBar(
        title: Text(isItalian ? 'Informazioni personali' : 'Personal information'), 
        backgroundColor: Colors.transparent, 
        elevation: 0
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 10.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isItalian 
                    ? "Compila i campi per personalizzare i tuoi esercizi." 
                    : "Fill out the fields to customize your exercises.",
                  style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 16),
                ),
                const SizedBox(height: 30),

                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _nomeController,
                        keyboardType: TextInputType.name,
                        decoration: _buildInputDecoration(isItalian ? 'Nome *' : 'First Name *'),
                        validator: (value) => value!.isEmpty ? (isItalian ? 'Richiesto' : 'Required') : null,
                      ),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: TextFormField(
                        controller: _cognomeController,
                        keyboardType: TextInputType.name,
                        decoration: _buildInputDecoration(isItalian ? 'Cognome *' : 'Last Name *'),
                        validator: (value) => value!.isEmpty ? (isItalian ? 'Richiesto' : 'Required') : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                TextFormField(
                  controller: _etaController,
                  keyboardType: TextInputType.number,
                  decoration: _buildInputDecoration(isItalian ? 'Età *' : 'Age *'),
                  validator: (value) => value!.isEmpty ? (isItalian ? 'Inserisci la tua età' : 'Enter your age') : null,
                ),
                const SizedBox(height: 20),

                DropdownButtonFormField<String>(
                  decoration: _buildInputDecoration(isItalian ? 'Sesso *' : 'Gender *'),
                  initialValue: _sessoSelezionato,
                  items: _opzioniSesso.map((s) => DropdownMenuItem(
                    value: s, 
                    child: Text(_translateGender(s, isItalian)) 
                  )).toList(),
                  onChanged: (val) => setState(() => _sessoSelezionato = val),
                  validator: (value) => value == null ? (isItalian ? 'Seleziona sesso' : 'Select gender') : null,
                ),
                const SizedBox(height: 20),

                // --- ALTEZZA E PESO CON TENDINA INTEGRATA ---
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _altezzaController,
                        keyboardType: TextInputType.number,
                        
                        decoration: _buildInputDecoration(
                          isItalian ? 'Altezza *' : 'Height *',
                          suffixIcon: Padding(
                            padding: const EdgeInsets.only(right: 12.0),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: _altezzaUnit,
                                items: ['cm', 'ft'].map((u) => DropdownMenuItem(value: u, child: Text(u, style: TextStyle(fontWeight: FontWeight.bold, color: colorScheme.primary)))).toList(),
                                onChanged: (val) => setState(() => _altezzaUnit = val!),
                                icon: Icon(Icons.keyboard_arrow_down, size: 20, color: colorScheme.primary),
                              ),
                            ),
                          ),
                        ),
                        validator: (value) => value!.isEmpty ? (isItalian ? 'Richiesto' : 'Required') : null,
                      ),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: TextFormField(
                        controller: _pesoController,
                        keyboardType: TextInputType.number,
                        decoration: _buildInputDecoration(
                          isItalian ? 'Peso *' : 'Weight *',
                          suffixIcon: Padding(
                            padding: const EdgeInsets.only(right: 12.0),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: _pesoUnit,
                                items: ['kg', 'lbs'].map((u) => DropdownMenuItem(value: u, child: Text(u, style: TextStyle(fontWeight: FontWeight.bold, color: colorScheme.primary)))).toList(),
                                onChanged: (val) => setState(() => _pesoUnit = val!),
                                icon: Icon(Icons.keyboard_arrow_down, size: 20, color: colorScheme.primary),
                              ),
                            ),
                          ),
                        ),
                        validator: (value) => value!.isEmpty ? (isItalian ? 'Richiesto' : 'Required') : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                DropdownButtonFormField<String>(
                  decoration: _buildInputDecoration(isItalian ? 'Azienda *' : 'Company *'),
                  initialValue: _aziendaSelezionata,
                  items: _aziendeEReparti.keys.map((a) => DropdownMenuItem(value: a, child: Text(a))).toList(),
                  onChanged: (val) {
                    setState(() {
                      _aziendaSelezionata = val;
                      _repartoSelezionato = null; 
                    });
                  },
                  validator: (value) => value == null ? (isItalian ? 'Seleziona la tua azienda' : 'Select your company') : null,
                ),
                const SizedBox(height: 20),

                DropdownButtonFormField<String>(
                  decoration: _buildInputDecoration(isItalian ? 'Reparto *' : 'Department *'),
                  initialValue: _repartoSelezionato,
                  disabledHint: Text(isItalian ? "Seleziona prima un'azienda" : "Select a company first"),
                  items: _aziendaSelezionata == null 
                    ? [] 
                    : _aziendeEReparti[_aziendaSelezionata]!.map((r) => DropdownMenuItem(
                        value: r, 
                        child: Text(_translateDept(r, isItalian)) 
                      )).toList(),
                  onChanged: (val) => setState(() => _repartoSelezionato = val),
                  validator: (value) => value == null ? (isItalian ? 'Seleziona il tuo reparto' : 'Select your department') : null,
                ),

                const SizedBox(height: 40),

                ElevatedButton(
                  onPressed: _salvaDati,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.primary,
                    foregroundColor: colorScheme.onPrimary,
                    minimumSize: const Size(double.infinity, 65), 
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    elevation: 2,
                  ),
                  child: Text(
                    isItalian ? 'SALVA MODIFICHE' : 'SAVE CHANGES', 
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)
                  ),
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