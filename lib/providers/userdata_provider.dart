import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserDataProvider extends ChangeNotifier {
  int? age;
  String? gender;
  double? height;
  double? weight;
  String? company;
  String? department;

  String firstName = "Name";
  String lastName = "Surname";
  
  
  String heightUnit = "cm"; 
  String weightUnit = "kg";

  
  UserDataProvider() {
    _loadData();
  }

  
  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    
    age = prefs.getInt('age');
    gender = prefs.getString('gender');
    height = prefs.getDouble('height');
    weight = prefs.getDouble('weight');
    company = prefs.getString('company');
    department = prefs.getString('department');
    firstName = prefs.getString('first_name') ?? "Name";
    lastName = prefs.getString('last_name') ?? "Surname";
    
    
    heightUnit = prefs.getString('height_unit') ?? "cm";
    weightUnit = prefs.getString('weight_unit') ?? "kg";
    
    notifyListeners();
  }

  
  Future<void> updateProfile({
    required String firstName,
    required String lastName,
    required int age,
    required String gender,
    required double height,
    required double weight,
    required String company,
    required String department,
    required String heightUnit, 
    required String weightUnit, 
  }) async {
    
    this.firstName = firstName; 
    this.lastName = lastName;
    this.age = age;
    this.gender = gender;
    this.height = height;
    this.weight = weight;
    this.company = company;
    this.department = department;
    this.heightUnit = heightUnit;
    this.weightUnit = weightUnit;

    
    notifyListeners();

    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('first_name', firstName); 
    await prefs.setString('last_name', lastName);
    await prefs.setInt('age', age);
    await prefs.setString('gender', gender);
    await prefs.setDouble('height', height);
    await prefs.setDouble('weight', weight);
    await prefs.setString('company', company);
    await prefs.setString('department', department);
    await prefs.setString('height_unit', heightUnit); 
    await prefs.setString('weight_unit', weightUnit); 
  }
}