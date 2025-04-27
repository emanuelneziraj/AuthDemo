// lib/main.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'auth_service.dart';
import 'api_service.dart';

void main() {
  // Stelle sicher, dass Widgets initialisiert sind
  WidgetsFlutterBinding.ensureInitialized();

  // Erstelle Instanzen der Services
  final authService = AuthService();
  final apiService = ApiService();

  // Führe den Callback-Check aus, bevor die App gebaut wird
  authService.handleLoginCallback().then((_) {
       // Starte die App, nachdem der Callback (falls vorhanden) verarbeitet wurde
       runApp(
         MultiProvider(
           providers: [
             ChangeNotifierProvider.value(value: authService),
             Provider.value(value: apiService), // ApiService ohne ChangeNotifier
           ],
           child: MyApp(),
         ),
       );
   });
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Auth0 Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  String _apiResponse = 'Noch keine API-Anfrage gesendet.';
  bool _isLoadingApi = false; // Ladezustand für API-Aufrufe

  // Funktion zum Aufrufen der öffentlichen API
  Future<void> _callPublicApi() async {
    setState(() {
      _isLoadingApi = true; // Start API Loading
      _apiResponse = 'Rufe öffentlichen Endpunkt auf...';
    });
    final apiService = Provider.of<ApiService>(context, listen: false);
    final result = await apiService.getPublicData();
    setState(() {
      _apiResponse = result;
      _isLoadingApi = false; // End API Loading
    });
  }

  // Funktion zum Aufrufen der gesicherten API
  Future<void> _callSecureApi() async {
    setState(() {
      _isLoadingApi = true; // Start API Loading
      _apiResponse = 'Rufe gesicherten Endpunkt auf...';
    });
    final authService = Provider.of<AuthService>(context, listen: false);
    final apiService = Provider.of<ApiService>(context, listen: false);

    final accessToken = authService.getAccessToken();

    if (accessToken == null) {
      setState(() {
        _apiResponse = 'Nicht eingeloggt oder kein Access Token vorhanden.';
         _isLoadingApi = false; // End API Loading
      });
      return;
    }

    final result = await apiService.getSecretData(accessToken);
    setState(() {
      _apiResponse = result;
      _isLoadingApi = false; // End API Loading
    });
  }

  @override
  Widget build(BuildContext context) {
    // Höre auf Änderungen im AuthService
    final authService = Provider.of<AuthService>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Flutter Auth0 & .NET API Demo'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              if (authService.isLoading)
                CircularProgressIndicator()
              else if (authService.isLoggedIn) ...[ // Wenn eingeloggt
                Text('Willkommen, ${authService.userProfile?.name ?? 'Benutzer'}!'),
                Text('Email: ${authService.userProfile?.email ?? 'N/A'}'),
                SizedBox(height: 20),
                ElevatedButton(
                  onPressed: authService.logout,
                  child: Text('Logout'),
                ),
              ] else ...[ // Wenn ausgeloggt
                Text('Du bist nicht eingeloggt.'),
                SizedBox(height: 20),
                ElevatedButton(
                  onPressed: authService.login,
                  child: Text('Login mit Auth0'),
                ),
              ],

              if (authService.errorMessage != null) ... [ // Zeige Fehlermeldungen vom AuthService
                 SizedBox(height: 10),
                 Text('Auth Fehler: ${authService.errorMessage}', style: TextStyle(color: Colors.red)),
              ],

              SizedBox(height: 40),
              Text('API Kommunikation:', style: Theme.of(context).textTheme.headlineSmall),
              SizedBox(height: 10),

              // Buttons zum Aufrufen der API
              Row(
                 mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                 children: [
                     ElevatedButton(
                       onPressed: _isLoadingApi ? null : _callPublicApi, // Deaktivieren während Laden
                       child: Text('Öffentliche API aufrufen'),
                     ),
                     ElevatedButton(
                       // Deaktiviere, wenn nicht eingeloggt oder API lädt
                       onPressed: authService.isLoggedIn && !_isLoadingApi ? _callSecureApi : null,
                       child: Text('Gesicherte API aufrufen'),
                     ),
                 ],
              ),
              SizedBox(height: 20),

              // Anzeige des API Ladezustands und der Antwort
              if (_isLoadingApi)
                 CircularProgressIndicator()
              else
                Container(
                   padding: EdgeInsets.all(12),
                   color: Colors.grey[200],
                   child: Text('API Antwort:\n$_apiResponse'),
                ),
            ],
          ),
        ),
      ),
    );
  }
}