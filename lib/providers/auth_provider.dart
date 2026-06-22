import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

// Questo è il provider per l'autenticazione, che gestisce il login, il logout e il refresh del token.

class AuthProvider extends ChangeNotifier {
  final String _baseUrl = 'https://impact.dei.unipd.it/bwthw'; 
  
  String? _accessToken;
  String? _refreshToken;
  String? _username;

  bool get isAuthenticated => _accessToken != null;
  String? get accessToken => _accessToken;
  String? get username => _username;

  // Login: Ottiene il token JWT 
  
  // USERNAME: VKM4CPfO22
  // PASSWORD: 12345678! 
  
  Future<bool> login(String username, String password) async {
    final url = Uri.parse('$_baseUrl/gate/v1/token/');
    
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'username': username, 'password': password}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _accessToken = data['access'];
        _refreshToken = data['refresh'];
        _username = username;
        notifyListeners(); // Notifica la UI
        return true;
      }
    } catch (e) {
      print("Errore durante il login: $e");
    }
    return false;
  }

  // Refresh Token: Aggiorna il token se scaduto 
  Future<bool> refresh() async {
    if (_refreshToken == null) return false;
    
    final url = Uri.parse('$_baseUrl/gate/v1/refresh/');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'refresh': _refreshToken}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _accessToken = data['access'];
        _refreshToken = data['refresh'];
        notifyListeners();
        return true;
      }
    } catch (e) {
      print("Errore refresh token: $e");
    }
    logout();
    return false;
  }

  void logout() {
    _accessToken = null;
    _refreshToken = null;
    _username = null;
    notifyListeners();
  }
}