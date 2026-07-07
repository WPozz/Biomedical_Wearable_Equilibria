import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class AuthProvider extends ChangeNotifier {
  final String _baseUrl = 'https://impact.dei.unipd.it/bwthw';

  String? _accessToken;
  String? _refreshToken;
  String? _username;

  bool get isAuthenticated => _accessToken != null;
  String? get accessToken => _accessToken;
  String? get username => _username;

  Future<bool>? _refreshInFlight;

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
        notifyListeners();
        return true;
      }
    } catch (e) {
      print("Errore durante il login: $e");
    }
    return false;
  }

   Future<bool> refresh() {
     if (_refreshInFlight != null) {
      return _refreshInFlight!;
    }

    final future = _performRefresh();
    _refreshInFlight = future;

    future.whenComplete(() {
      _refreshInFlight = null;
    });

    return future;
  }

  Future<bool> _performRefresh() async {
    final String? tokenUsatoPerQuestoRefresh = _refreshToken;
    if (tokenUsatoPerQuestoRefresh == null) return false;

    final url = Uri.parse('$_baseUrl/gate/v1/refresh/');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'refresh': tokenUsatoPerQuestoRefresh}),
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
    _refreshInFlight = null;
    notifyListeners();
  }
}