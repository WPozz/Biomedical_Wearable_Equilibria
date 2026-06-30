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

  // ── LOCK SUL REFRESH ────────────────────────────────────────────────────
  //
  // PERCHÉ: il backend usa refresh-token "rotanti" (ogni refresh restituisce
  // un nuovo refresh token e invalida il precedente). Se più richieste HTTP
  // partono in parallelo (es. Future.wait in DataProvider) e tutte trovano
  // l'access token scaduto, OGNUNA chiamava refresh() indipendentemente:
  // - la prima ha successo e sostituisce _refreshToken con quello nuovo
  // - le altre stavano già usando il vecchio _refreshToken (letto prima
  //   che la prima lo sovrascrivesse) → il server lo rifiuta perché è
  //   già stato "consumato" → queste chiamate fallivano e innescavano
  //   un logout() che cancellava ANCHE il token valido appena ottenuto.
  //
  // Risultato: disconnessioni intermittenti a metà di un fetch parallelo,
  // dipendenti dal timing esatto di scadenza del token.
  //
  // FIX: se un refresh è già in corso, le chiamate successive non ne
  // avviano un altro ma aspettano il risultato di quello in corso.
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

  // Punto d'ingresso pubblico: invariato per chi lo chiama da fuori
  // (DataProvider continua a fare `await authProvider.refresh()` come prima).
  Future<bool> refresh() {
    // Se c'è già un refresh in corso, ci agganciamo al suo risultato
    // invece di farne partire un altro.
    if (_refreshInFlight != null) {
      return _refreshInFlight!;
    }

    final future = _performRefresh();
    _refreshInFlight = future;

    // Puliamo il "lock" non appena il refresh in corso si conclude
    // (sia in caso di successo che di fallimento), così il prossimo
    // refresh futuro (es. al prossimo giro di scadenza del token)
    // potrà partire normalmente.
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

  // LOGOUT: cancella i token ma non le preferenze utente
  void logout() {
    _accessToken = null;
    _refreshToken = null;
    _username = null;
    _refreshInFlight = null;
    notifyListeners();
  }
}