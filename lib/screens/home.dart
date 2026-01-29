// lib/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'input.dart'; // Tu pantalla de generador de citas
import '../utils/animations.dart'; // Tu función de animación
// import 'dart:math';
import 'phrases.dart';
import 'calendar.dart';
import 'memories.dart';

// Colores de tu paleta
const Color violetaProfundo = Color(0xFF796B9B);
const Color lavandaPalida = Color(0xFFD8C9E7);

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: lavandaPalida, // Fondo pastel
      appBar: AppBar(
        title: const Text(
          '💌 Nuestro Lugar seguro',
          style: TextStyle(color: violetaProfundo, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 1,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              _buildMenuItem(
                context,
                icon: Icons.favorite,
                title: 'Generar Cita',
                subtitle: '¿Qué hacemos hoy? ¡Que la la suerte decida!',
                destination: const InputScreen(),
                color: violetaProfundo,
              ),
              const SizedBox(height: 25),
              _buildMenuItem(
                context,
                icon: Icons.calendar_month,
                title: 'Calendario de Fechas Importantes',
                subtitle: 'Nuestros fechas.',
                destination: const CalendarScreen(), // Pantalla por crear
                color: violetaProfundo,
              ),
              const SizedBox(height: 25),
              _buildMenuItem(
                context,
                icon: Icons.auto_stories,
                title: 'De mi pa tu',
                subtitle: 'Por que te amo.',
                destination: const PhrasesScreen(), // Pantalla por crear
                color: violetaProfundo,
              ),
              const SizedBox(height: 25),
              _buildMenuItem(
                context,
                icon: Icons.book,
                title: 'Nuestro checklist de aventuras',
                subtitle: 'Repasa a todos los lugare, que hemos ido',
                destination: ExperienceMenuScreen(), // Pantalla por crear
                color: violetaProfundo,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Widget reutilizable para los elementos del menú
  Widget _buildMenuItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Widget destination,
    required Color color,
  }) {
    return Card(
      color: Colors.white,
      elevation: 5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 10,
        ),
        leading: Icon(icon, size: 40, color: color),
        title: Text(
          title,
          style: TextStyle(fontWeight: FontWeight.bold, color: color),
        ),
        subtitle: Text(subtitle, style: TextStyle(color: Colors.grey.shade600)),
        trailing: const Icon(
          Icons.arrow_forward_ios,
          size: 18,
          color: Colors.grey,
        ),
        onTap: () {
          // Usa tu función de animación personalizada
          Navigator.of(context).push(createRoute(destination));
        },
      ),
    );
  }
}
