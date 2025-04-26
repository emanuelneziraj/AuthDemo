// lib/auth_service.dart
import 'package:flutter/foundation.dart';
import 'package:auth0_flutter/auth0_flutter.dart';
import 'package:auth0_flutter/auth0_flutter_web.dart';
import 'config.dart';

class AuthService with ChangeNotifier {
  Credentials? _credentials;
  UserProfile? _userProfile;
  bool _isLoading = false;
  String? _errorMessage;

  Auth0Web? _auth0Web; // Spezifisch für Web

  AuthService() {
    _initAuth0();
  }

  // --- Getters ---
  bool get isLoggedIn => _credentials != null;
  UserProfile? get userProfile => _userProfile;
  Credentials? get credentials => _credentials; // Enthält das Access Token
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // --- Initialisierung ---
  void _initAuth0() {
    if (kIsWeb) {
      // Wichtig: Auth0Web Instanz für Web erstellen
      _auth0Web = Auth0Web(auth0Domain, auth0ClientId);

      // Versuche, beim Start auf gespeicherte Credentials zu prüfen (optional)
      // Auth0 Flutter Web handhabt dies oft intern nach dem Redirect
      // _checkStoredCredentials();
    }
  }

  // --- Ladezustand und Fehler ---
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String? message) {
    _errorMessage = message;
    notifyListeners();
  }

  // --- Login ---
  Future<void> login() async {
    if (!kIsWeb || _auth0Web == null) {
      _setError("Login ist nur im Web verfügbar.");
      return;
    }

    _setLoading(true);
    _setError(null);
    try {
      // Startet den Redirect-Flow. Wichtig: audience angeben!
      await _auth0Web!.loginWithRedirect(
        redirectUrl: '${Uri.base.origin}/',
        audience: auth0ApiAudience, // Audience hinzufügen
        parameters: {
          'scope': 'openid profile email', // Optional: Scopes anpassen
        },
      );
      // Nach dem Redirect wird die App neu geladen.
      // Wir müssen die Credentials nach dem Neuladen abrufen.
      // Dies geschieht normalerweise in main.dart oder beim App-Start.
      // Hier setzen wir nur Loading, der Rest passiert nach dem Redirect.

    } catch (e) {
      print("Generic Login Error: $e");
     _setError("Ein unerwarteter Fehler ist aufgetreten.");
     _setLoading(false);
    }
    // Kein setLoading(false) hier, da der Redirect erfolgt.
  }

   // --- Handle Login Callback ---
   // Diese Methode wird nach dem Redirect von Auth0 aufgerufen (z.B. in main.dart)
   Future<void> handleLoginCallback() async {
     if (!kIsWeb || _auth0Web == null) return;

     _setLoading(true);
     _setError(null);
     try {
       // Prüft, ob Credentials im URL-Fragment vorhanden sind und holt sie ab
       final creds = await _auth0Web!.onLoad();

       if (creds != null) {
          _credentials = creds;
          _userProfile = creds.user;
           print("Login erfolgreich! Access Token: ${creds.tokenType} ${creds.expiresAt} ${creds.idToken}");
           print("User: ${creds.user.name}");
       } else {
           print("Keine Credentials nach Callback gefunden.");
           // Evtl. prüfen, ob schon vorher eingeloggt?
       }
     } catch (e) {
        print("Generic Callback Error: $e");
        _credentials = null;
        _userProfile = null;
     } finally {
       _setLoading(false);
     }
   }


  // --- Logout ---
  Future<void> logout() async {
     if (!kIsWeb || _auth0Web == null) {
      _setError("Logout ist nur im Web verfügbar.");
      return;
    }
    _setLoading(true);
    _setError(null);
    try {
       await _auth0Web!.logout(
           returnToUrl: Uri.base.origin // URL, zu der nach Logout weitergeleitet wird (muss in Auth0 erlaubt sein)
       );
       // Auth0 leitet zur 'returnTo' URL weiter, App wird neu geladen.
       // Effektives löschen der lokalen Daten passiert beim Neuladen oder manuell:
       _credentials = null;
       _userProfile = null;
       // notifyListeners(); // Wird durch Neuladen der App überflüssig
    } catch (e) {
       print("Generic Logout Error: $e");
      _setLoading(false);
    }
     // Kein setLoading(false) bei Erfolg, da Redirect erfolgt.
  }

  // --- Access Token abrufen ---
  // Das Access Token ist bereits in _credentials vorhanden
  String? getAccessToken() {
    return _credentials?.idToken;
  }
}