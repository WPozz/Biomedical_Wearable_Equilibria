import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_application/providers/userdata_provider.dart';
import 'package:flutter_application/providers/settings_provider.dart';

class PersonalDataScreen extends StatefulWidget {
  const PersonalDataScreen({super.key});

  @override
  State<PersonalDataScreen> createState() => _PersonalDataScreenState();
}

class _PersonalDataScreenState extends State<PersonalDataScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _surnameController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _heightController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();

  String? _selectedGender;
  String? _selectedCompany;
  String? _selectedDepartment;
  
  String _heightUnit = 'cm'; 
  String _weightUnit = 'kg';

  final List<String> _genderOptions = ['Male', 'Female', 'Other/Prefer not to say'];
  
  final Map<String, List<String>> _companyAndDepartment = {
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

    _nameController.text = userData.firstName;
    _surnameController.text = userData.lastName;
    
    if (userData.age != null) _ageController.text = userData.age.toString();
    if (userData.height != null) _heightController.text = userData.height.toString();
    if (userData.weight != null) _weightController.text = userData.weight.toString();
    
    _selectedGender = userData.gender;
    _selectedCompany= userData.company;
    _selectedDepartment = userData.department;
    
    _heightUnit = userData.heightUnit;
    _weightUnit = userData.weightUnit;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _surnameController.dispose();
    _ageController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  void _saveData() async {
    if (_formKey.currentState!.validate()) {
      int age = int.parse(_ageController.text);
      double height = double.parse(_heightController.text);
      double weight = double.parse(_weightController.text);

      await Provider.of<UserDataProvider>(context, listen: false).updateProfile(
        firstName: _nameController.text.trim(),
        lastName: _surnameController.text.trim(),
        age: age,
        gender: _selectedGender!,
        height: height,
        weight: weight,
        company: _selectedCompany!,
        department: _selectedDepartment!,
        heightUnit: _heightUnit, 
        weightUnit: _weightUnit,    
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
                
                const SizedBox(height: 20),

                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _nameController,
                        keyboardType: TextInputType.name,
                        decoration: _buildInputDecoration(isItalian ? 'Nome *' : 'First Name *'),
                        validator: (value) => value!.isEmpty ? (isItalian ? 'Richiesto' : 'Required') : null,
                      ),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: TextFormField(
                        controller: _surnameController,
                        keyboardType: TextInputType.name,
                        decoration: _buildInputDecoration(isItalian ? 'Cognome *' : 'Last Name *'),
                        validator: (value) => value!.isEmpty ? (isItalian ? 'Richiesto' : 'Required') : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                TextFormField(
                  controller: _ageController,
                  keyboardType: TextInputType.number,
                  decoration: _buildInputDecoration(isItalian ? 'Età *' : 'Age *'),
                  validator: (value) => value!.isEmpty ? (isItalian ? 'Inserisci la tua età' : 'Enter your age') : null,
                ),
                const SizedBox(height: 20),

                DropdownButtonFormField<String>(
                  decoration: _buildInputDecoration(isItalian ? 'Sesso *' : 'Gender *'),
                  initialValue: _selectedGender,
                  items: _genderOptions.map((s) => DropdownMenuItem(
                    value: s, 
                    child: Text(_translateGender(s, isItalian)) 
                  )).toList(),
                  onChanged: (val) => setState(() => _selectedGender = val),
                  validator: (value) => value == null ? (isItalian ? 'Seleziona sesso' : 'Select gender') : null,
                ),
                const SizedBox(height: 20),

                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _heightController,
                        keyboardType: TextInputType.number,
                        
                        decoration: _buildInputDecoration(
                          isItalian ? 'Altezza *' : 'Height *',
                          suffixIcon: Padding(
                            padding: const EdgeInsets.only(right: 12.0),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: _heightUnit,
                                items: ['cm', 'ft'].map((u) => DropdownMenuItem(value: u, child: Text(u, style: TextStyle(fontWeight: FontWeight.bold, color: colorScheme.primary)))).toList(),
                                onChanged: (val) => setState(() => _heightUnit = val!),
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
                        controller: _weightController,
                        keyboardType: TextInputType.number,
                        decoration: _buildInputDecoration(
                          isItalian ? 'Peso *' : 'Weight *',
                          suffixIcon: Padding(
                            padding: const EdgeInsets.only(right: 12.0),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: _weightUnit,
                                items: ['kg', 'lbs'].map((u) => DropdownMenuItem(value: u, child: Text(u, style: TextStyle(fontWeight: FontWeight.bold, color: colorScheme.primary)))).toList(),
                                onChanged: (val) => setState(() => _weightUnit = val!),
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
                  initialValue: _selectedCompany,
                  items: _companyAndDepartment.keys.map((a) => DropdownMenuItem(value: a, child: Text(a))).toList(),
                  onChanged: (val) {
                    setState(() {
                      _selectedCompany = val;
                      _selectedDepartment = null; 
                    });
                  },
                  validator: (value) => value == null ? (isItalian ? 'Seleziona la tua azienda' : 'Select your company') : null,
                ),
                const SizedBox(height: 20),

                DropdownButtonFormField<String>(
                  decoration: _buildInputDecoration(isItalian ? 'Reparto *' : 'Department *'),
                  initialValue: _selectedDepartment,
                  disabledHint: Text(isItalian ? "Seleziona prima un'azienda" : "Select a company first"),
                  items: _selectedCompany == null 
                    ? [] 
                    : _companyAndDepartment[_selectedCompany]!.map((r) => DropdownMenuItem(
                        value: r, 
                        child: Text(_translateDept(r, isItalian)) 
                      )).toList(),
                  onChanged: (val) => setState(() => _selectedDepartment = val),
                  validator: (value) => value == null ? (isItalian ? 'Seleziona il tuo reparto' : 'Select your department') : null,
                ),

                const SizedBox(height: 40),

                ElevatedButton(
                  onPressed: _saveData,
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
