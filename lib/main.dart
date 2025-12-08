import 'package:flutter/material.dart';
import 'screens/home.dart';

const Color lavandaPalida = Color(0xFFD8C9E7);
const Color malvaSuave = Color(0xFFB0B6E8);
const Color azulCelestePastel = Color(0xFFA9D1DF);
const Color violetaProfundo = Color(0xFF796B9B);
const Color grisClaroCalido = Color(0xFFF0F0F0);

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Citas',
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
      home: const HomeScreen(),
    );
  }
}
