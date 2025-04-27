// lib/api_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'config.dart';

class ApiService {
  Future<String> callApi(String endpoint, String? accessToken) async {
    final url = Uri.parse('$apiBaseUrl/api/$endpoint');

    try {
      final response = await http.get(
        url,
        headers: accessToken != null
            ? {
                'Authorization': 'Bearer $accessToken',
                'Content-Type': 'application/json',
              }
            : {
                'Content-Type': 'application/json',
             },
      );


      if (response.statusCode == 200) {
         try {
           final Map<String, dynamic> data = jsonDecode(response.body);
           return data['message'] ?? 'Erfolgreich, aber keine Nachricht gefunden.';
         } catch (e) {
            return 'Antwort von API erhalten, aber Format unerwartet: ${response.body}';
         }
      } else if (response.statusCode == 401) {
        return 'Fehler: Nicht autorisiert (401). Token fehlt oder ist ungültig.';
      } else {
        return 'API Fehler: Statuscode ${response.statusCode}\nAntwort: ${response.body}';
      }
    } catch (e) {
      print('Fehler beim API-Aufruf an $url: $e');
      // Spezifische Fehlerbehandlung für Netzwerkprobleme etc.
      if (e.toString().contains('XMLHttpRequest')) {
         return 'Netzwerkfehler: Konnte API nicht erreichen. Läuft die API? Ist CORS korrekt konfiguriert? URL: $url';
      }
      return 'Fehler beim API-Aufruf: $e';
    }
  }

  // Spezifische Methoden für Endpunkte
  Future<String> getPublicData() async {
    return callApi('secret/public', null);
  }

  Future<String> getSecretData(String accessToken) async {
    return callApi('secret', accessToken);
  }
}