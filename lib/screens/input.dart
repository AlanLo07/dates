import 'package:flutter/material.dart';
import '../models/cita.dart';
import '../data/planes.dart';
import 'result.dart';
import 'dart:math';

class InputScreen extends StatefulWidget {
  const InputScreen({super.key});

  @override
  State<InputScreen> createState() => _InputScreenState();
}

class _InputScreenState extends State<InputScreen> {
  // Variables de estado para los filtros seleccionados
  String? _selectedCategory;
  String? _selectedBudget;
  double _selectedTimeHours = 2.0; // Valor por defecto en horas
  final double maxDailyTime = 2.0;
  final double maxTotalTime = 200.0;

  // Lista de opciones para los Dropdowns
  final List<String> categories = [
    'Romántico',
    'Aventura',
    'Relajante',
    'Compras',
    'Comida',
    'Cualquiera',
  ];
  final List<String> budgets = ['Bajo', 'Medio', 'Alto', 'Cualquiera'];

  Cita? _generarCita() {
    // 1. Filtrar la lista
    List<Cita> citasFiltradas = planesDisponibles.where((cita) {
      // Si el filtro es 'Cualquiera' o nulo, o si coincide con la categoría de la cita.
      bool cumpleCategoria =
          (_selectedCategory == 'Cualquiera' || _selectedCategory == null) ||
          cita.categoria == _selectedCategory;

      // Si el filtro es 'Cualquiera' o nulo, o si coincide con el presupuesto de la cita.
      bool cumplePresupuesto =
          (_selectedBudget == 'Cualquiera' || _selectedBudget == null) ||
          cita.presupuesto == _selectedBudget;

      // Si el tiempo de la cita es menor o igual al tiempo máximo seleccionado.
      // Asumiremos un tiempo máximo de 5 horas si no se implementa un selector de tiempo específico
      // Criterio de Tiempo (¡ACTUALIZADO!)
      // El tiempo de la cita debe ser menor o igual al tiempo máximo seleccionado por el Slider.
      bool cumpleTiempo = cita.tiempo <= _selectedTimeHours;

      return cumpleCategoria && cumplePresupuesto && cumpleTiempo;
    }).toList();

    // 2. Seleccionar una cita aleatoria
    if (citasFiltradas.isEmpty) {
      // No se encontró ninguna cita que cumpla los criterios
      return null;
    }

    // Usa el generador de números aleatorios de Dart
    final random = Random();
    int randomIndex = random.nextInt(citasFiltradas.length);

    return citasFiltradas[randomIndex];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('💘 Generador de Citas'),
        backgroundColor: Colors.pink.shade100,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            const Text(
              '¡Elijan los criterios para su próxima cita!',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),

            // --- Selector de Categoría ---
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(labelText: 'Tipo de Cita'),
              initialValue: _selectedCategory,
              items: categories
                  .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                  .toList(),
              onChanged: (value) {
                setState(() {
                  _selectedCategory = value;
                });
              },
            ),
            const SizedBox(height: 20),

            // --- Selector de Presupuesto ---
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(labelText: 'Presupuesto'),
              initialValue: _selectedBudget,
              items: budgets
                  .map((b) => DropdownMenuItem(value: b, child: Text(b)))
                  .toList(),
              onChanged: (value) {
                setState(() {
                  _selectedBudget = value;
                });
              },
            ),
            const SizedBox(height: 30),

            // --- Control Deslizante de Tiempo ---
            Text(
              'Tiempo Máximo: ${_selectedTimeHours.round()} horas',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Slider(
              value: _selectedTimeHours,
              // Establecer límites: 1 hora mínima, 8 horas máxima para planes rápidos
              // Puedes usar maxTotalTime si quieres incluir "Playa" y "Otro País"
              min: 1,
              max: maxTotalTime, // O maxDailyTime (8.0)
              divisions: (maxTotalTime - 1).toInt(), // Divisiones por hora
              label: '${_selectedTimeHours.round()} horas',
              onChanged: (double value) {
                setState(() {
                  _selectedTimeHours = value;
                });
              },
              activeColor: Colors.pink,
            ),
            const SizedBox(height: 30),

            // --- Botón de Generar ---
            ElevatedButton.icon(
              onPressed: () {
                Cita? citaElegida = _generarCita();

                if (citaElegida != null) {
                  // Navega a la pantalla de resultados, pasando la cita como argumento
                  Navigator.of(
                    context,
                  ).push(createRoute(ResultScreen(cita: citaElegida)));
                } else {
                  // Muestra un mensaje si no hay planes
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        '¡Vaya! No encontramos un plan con esos criterios. Intenta con otros.',
                      ),
                    ),
                  );
                }
              },
              icon: const Icon(Icons.favorite),
              label: const Text('¡GENERAR CITA!'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.pink.shade300,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 15),
                textStyle: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Route createRoute(Widget targetScreen) {
  return PageRouteBuilder(
    // 1. Duración de la animación
    transitionDuration: const Duration(milliseconds: 700),
    // 2. La pantalla a la que navegamos
    pageBuilder: (context, animation, secondaryAnimation) => targetScreen,

    // 3. El constructor de la transición (ejemplo: Deslizamiento o Fade)
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      // --- Opción A: Deslizamiento (Slide Transition) ---
      // Hace que la nueva pantalla se deslice desde la derecha (puedes cambiarlo)
      const begin = Offset(
        1.0,
        0.0,
      ); // Inicia fuera de la pantalla a la derecha
      const end = Offset.zero; // Termina en la posición normal (cero)
      const curve = Curves.easeOutCubic; // Define la aceleración

      var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));

      return SlideTransition(position: animation.drive(tween), child: child);

      // --- Opción B: Desvanecimiento (Fade Transition) ---
      /*
      return FadeTransition(
        opacity: animation,
        child: child,
      );
      */
    },
  );
}
