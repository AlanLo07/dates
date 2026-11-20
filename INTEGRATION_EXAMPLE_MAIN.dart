/// Archivo de ejemplo para integrar WeeklyQuestionsScreen en main.dart
/// 
/// Reemplaza o adapta según tu estructura actual

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'screens/weekly_questions_screen.dart';
// Importa tus otras pantallas según necesites

void main() async {
  // Inicializar servicios de autenticación si es necesario
  // await AuthService.instance.initialize();
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Dates App',
      debugShowCheckedModeBanner: false,
      
      // 🌍 Localización en español
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('es', 'ES'),
        Locale('en', 'US'),
      ],
      
      // 🎨 Tema
      theme: ThemeData(
        useMaterial3: true,
        primarySwatch: Colors.pink,
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 0,
        ),
      ),
      
      // 🏠 Pantalla inicial
      home: const HomePage(),
      
      // 🛣️ Rutas nombradas
      routes: {
        '/weekly-questions': (_) => const WeeklyQuestionsScreen(),
        // Agrega tus otras rutas aquí
        // '/home': (_) => const HomePage(),
        // '/calendar': (_) => const CalendarScreen(),
      },
    );
  }
}

/// Página principal con navegación
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;

  final List<NavigationDestination> _navItems = const [
    NavigationDestination(
      icon: Icon(Icons.home),
      selectedIcon: Icon(Icons.home),
      label: 'Inicio',
    ),
    NavigationDestination(
      icon: Icon(Icons.calendar_today),
      selectedIcon: Icon(Icons.calendar_today),
      label: 'Calendario',
    ),
    NavigationDestination(
      icon: Icon(Icons.question_answer),
      selectedIcon: Icon(Icons.question_answer),
      label: 'Preguntas',
    ),
    NavigationDestination(
      icon: Icon(Icons.favorite),
      selectedIcon: Icon(Icons.favorite),
      label: 'Recuerdos',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dates'),
        elevation: 0,
      ),
      body: _buildBody(),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() => _selectedIndex = index);
        },
        destinations: _navItems,
      ),
    );
  }

  Widget _buildBody() {
    switch (_selectedIndex) {
      case 0:
        return const HomeView();
      case 1:
        return const Placeholder(); // CalendarScreen
      case 2:
        return const WeeklyQuestionsScreen(); // ✨ Nueva funcionalidad
      case 3:
        return const Placeholder(); // MemoriesScreen
      default:
        return const HomeView();
    }
  }
}

/// Vista inicial (ejemplo)
class HomeView extends StatelessWidget {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.favorite, size: 80, color: Colors.pink[400]),
          const SizedBox(height: 24),
          Text(
            'Bienvenidos',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            icon: const Icon(Icons.question_answer),
            label: const Text('Ir a Pregunta de la Semana'),
            onPressed: () {
              Navigator.pushNamed(context, '/weekly-questions');
            },
          ),
        ],
      ),
    );
  }
}
