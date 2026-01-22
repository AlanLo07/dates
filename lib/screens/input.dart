import 'package:flutter/material.dart';
import '../models/cita.dart';
import '../data/planes.dart';
import 'result.dart';
import 'dart:math';
import '../utils/animations.dart';
import 'checklist.dart';
import '../services/cita_service.dart';

class InputScreen extends StatefulWidget {
  const InputScreen({super.key});

  @override
  State<InputScreen> createState() => _InputScreenState();
}

class _InputScreenState extends State<InputScreen> {
  // Variables de estado para los filtros seleccionados
  bool _isLoading = false;
  String? _selectedCategory;
  String? _selectedBudget;
  double _selectedTimeHours = 2.0; // Valor por defecto en horas
  final double maxDailyTime = 2.0;
  final double maxTotalTime = 200.0;
  List<String> typesLocations = ['museo', 'parque', 'pueblo'];

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

  Future<void> _obtenerYGenerarCita() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // 1. Llamada a la API para traer los datos actualizados
      List<Cita> citasActualizadas = await ApiService().getCitas();

      // 2. Aplicar la lógica de filtrado sobre los datos frescos
      List<Cita> citasFiltradas = citasActualizadas.where((cita) {
        bool cumpleCategoria =
            (_selectedCategory == 'Cualquiera' || _selectedCategory == null) ||
            cita.categoria == _selectedCategory;

        bool cumplePresupuesto =
            (_selectedBudget == 'Cualquiera' || _selectedBudget == null) ||
            cita.presupuesto == _selectedBudget;

        bool cumpleTiempo = cita.tiempo <= _selectedTimeHours;

        return cumpleCategoria && cumplePresupuesto && cumpleTiempo;
      }).toList();

      // 3. Seleccionar y navegar
      if (citasFiltradas.isNotEmpty) {
        final random = Random();
        Cita citaElegida =
            citasFiltradas[random.nextInt(citasFiltradas.length)];

        // Navegación según el tipo de locación
        if (typesLocations.contains(citaElegida.typeLocation)) {
          Navigator.of(context).push(
            createRoute(
              AdventureListScreen(cita: citaElegida, citas: citasActualizadas),
            ),
          );
        } else {
          Navigator.of(
            context,
          ).push(createRoute(ResultScreen(cita: citaElegida)));
        }
      } else {
        _mostrarSnackBar('No encontramos planes con esos filtros.');
      }
    } catch (e) {
      _mostrarSnackBar('Error al conectar con la API: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _mostrarSnackBar(String mensaje) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(mensaje)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('💘 Generador de Citas'),
        backgroundColor: grisClaroCalido,
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
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
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
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
                  activeColor: azulCelestePastel,
                ),
                const SizedBox(height: 30),

                // --- Botón de Generar ---
                ElevatedButton.icon(
                  onPressed: _isLoading ? null : _obtenerYGenerarCita,
                  icon: const Icon(Icons.favorite),
                  label: Text(
                    _isLoading ? 'ACTUALIZANDO...' : '¡GENERAR CITA!',
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: azulCelestePastel,
                    foregroundColor: Colors.black87,
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
          if (_isLoading)
            Container(
              color: Colors.black26,
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }
}
