import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'screens/auth/login_screen.dart';
import 'screens/home.dart';
import 'services/auth_service.dart';

const Color lavandaPalida = Color(0xFFD8C9E7);
const Color malvaSuave = Color(0xFFB0B6E8);
const Color azulCelestePastel = Color(0xFFA9D1DF);
const Color violetaProfundo = Color(0xFF796B9B);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('es_ES');
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Citas',
      locale: const Locale('es', 'ES'),
      supportedLocales: const [Locale('es', 'ES'), Locale('en', 'US')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: ThemeData(
        // Usamos el color base para el tema principal
        primaryColor: malvaSuave,
        // Definimos un esquema de color personalizado
        colorScheme:
            ColorScheme.fromSwatch(
              primarySwatch:
                  Colors.blue, // Necesario para crear la paleta Swatch
              accentColor: azulCelestePastel,
              backgroundColor: lavandaPalida,
            ).copyWith(
              // Definimos el color de fondo de las pantallas (Scaffold)
              surface: lavandaPalida,
              onSurface: violetaProfundo,
            ),
        useMaterial3: true,
      ),
      home: const AuthGate(),
    );
  }
}

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  final AuthService _authService = AuthService();
  late Future<bool> _sessionFuture;

  @override
  void initState() {
    super.initState();
    _sessionFuture = _authService.isSessionValid();
  }

  void _refreshSession() {
    setState(() {
      _sessionFuture = _authService.isSessionValid();
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _sessionFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final isAuthenticated = snapshot.data ?? false;
        if (isAuthenticated) {
          return const HomeScreen();
        }

        return LoginScreen(onLoginSuccess: _refreshSession);
      },
    );
  }
}
