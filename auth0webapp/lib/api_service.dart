// lib/api_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'config.dart'; // Basis-URL der API

class ApiService {
  Future<String> callApi(String endpoint, String? accessToken) async {
    final url = Uri.parse('$apiBaseUrl/api/$endpoint'); // Kombiniere Basis-URL und Endpunkt

    try {
      final response = await http.get(
        url,
        headers: accessToken != null
            ? {
                'Authorization': 'Bearer $accessToken', // Füge Token hinzu, falls vorhanden
                'Content-Type': 'application/json',
              }
            : { // Header für öffentliche Endpunkte (optional)
                'Content-Type': 'application/json',
             },
      );

      print('API Aufruf an $url - Status: ${response.statusCode}');
      print('Access Token: $accessToken'); // Zum Debuggen
      // print('API Antwort Body: ${response.body}'); // Zum Debuggen

      if (response.statusCode == 200) {
         try {
           // Versuche, die JSON-Antwort zu parsen
           final Map<String, dynamic> data = jsonDecode(response.body);
           return data['message'] ?? 'Erfolgreich, aber keine Nachricht gefunden.';
         } catch (e) {
            // Falls die Antwort kein JSON ist oder 'message' fehlt
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
    return callApi('secret/public', null); // Kein Token benötigt
  }

  Future<String> getSecretData(String accessToken) async {
    return callApi('secret', accessToken); // Token wird benötigt
  }
}