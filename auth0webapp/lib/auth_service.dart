import 'package:flutter/foundation.dart';
import 'package:auth0_flutter/auth0_flutter.dart';
import 'package:auth0_flutter/auth0_flutter_web.dart';
import 'config.dart';

class AuthService with ChangeNotifier {
  Credentials? _credentials;
  UserProfile? _userProfile;
  bool _isLoading = false;
  String? _errorMessage;

  Auth0Web? _auth0Web;

  AuthService() {
    _initAuth0();
  }

  // --- Getters ---
  bool get isLoggedIn => _credentials != null;
  UserProfile? get userProfile => _userProfile;
  Credentials? get credentials => _credentials;
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
        audience: auth0ApiAudience,
        scopes: {'openid', 'profile', 'email'}
      );

    } catch (e) {
      print("Generic Login Error: $e");
     _setError("Ein unerwarteter Fehler ist aufgetreten.");
     _setLoading(false);
    }
  }

   // --- Handle Login Callback ---
   // Diese Methode wird nach dem Redirect von Auth0 aufgerufen (z.B. in main.dart)
   Future<void> handleLoginCallback() async {
     if (!kIsWeb || _auth0Web == null) return;

     _setLoading(true);
     _setError(null);
     try {
       // Prüft, ob Credentials im URL-Fragment vorhanden sind UND initialisiert
       final creds = await _auth0Web!.onLoad(
         audience: auth0ApiAudience,
         scopes: {'openid', 'profile', 'email'},
       );

       if (creds != null) {
          _credentials = creds;
          _userProfile = creds.user;
           print("--- Credentials Details ---");
           print("Access Token: ${creds.accessToken}");
           print("Token Type: ${creds.tokenType}");
           print("Expires At: ${creds.expiresAt}");
           notifyListeners();

       } else {
           print("Keine Credentials nach Callback gefunden.");
           // Evtl. prüfen, ob schon vorher eingeloggt?
       }
     } catch (e) {
        print("Generic Callback Error: $e");
        _credentials = null; // Zustand löschen
        _userProfile = null; // Zustand löschen
        _setError("Fehler beim Verarbeiten des Login-Callbacks: $e"); // Ruft notifyListeners
     } finally {
       _setLoading(false); // Ruft notifyListeners
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
    } catch (e) {
       print("Generic Logout Error: $e");
      _setLoading(false);
    }
  }

  // --- Access Token abrufen ---
  String? getAccessToken() {
    return _credentials?.accessToken;
  }
}