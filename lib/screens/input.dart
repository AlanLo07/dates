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
  int _selectedTime = 2; // Valor por defecto en horas

  // Lista de opciones para los Dropdowns
  final List<String> categories = [
    'Romántico',
    'Aventura',
    'Relajante',
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
      bool cumpleTiempo =
          cita.tiempo <=
          5; // Placeholder: Ajustar si añades un control deslizante de tiempo.

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

            // --- Botón de Generar ---
            ElevatedButton.icon(
              onPressed: () {
                Cita? citaElegida = _generarCita();

                if (citaElegida != null) {
                  // Navega a la pantalla de resultados, pasando la cita como argumento
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => ResultScreen(cita: citaElegida),
                    ),
                  );
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
