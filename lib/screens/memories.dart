import '../utils/animations.dart';
import 'package:flutter/material.dart';
import '../models/cita.dart';
import '../services/cita_service.dart';
import 'checklist.dart';

class ExperienceMenuScreen extends StatelessWidget {
  final List<Map<String, dynamic>> categorias = [
    {'nombre': 'Parques', 'icono': Icons.forest, 'tipo': 'parque'},
    {'nombre': 'Museos', 'icono': Icons.museum, 'tipo': 'museo'},
    {
      'nombre': 'Conciertos',
      'icono': Icons.confirmation_number,
      'tipo': 'concierto',
    },
    {'nombre': 'Pueblos', 'icono': Icons.holiday_village, 'tipo': 'pueblo'},
    {'nombre': 'Países', 'icono': Icons.public, 'tipo': 'pais'},
    {
      'nombre': 'Restaurantes',
      'icono': Icons.restaurant,
      'tipo': 'restaurante',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nuestras Aventuras')),
      body: FutureBuilder<List<Cita>>(
        future: ApiService().getCitas(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          } else if (!snapshot.hasData) {
            return const Center(child: Text("No hay categorías disponibles"));
          }

          final citas = snapshot.data!;

          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),
            itemCount: categorias.length,
            itemBuilder: (context, index) {
              final cat = categorias[index];
              return Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                child: InkWell(
                  onTap: () => Navigator.push(
                    context,
                    createRoute(
                      AdventureListScreen(
                        cita: Cita(
                          nombre: "nombre",
                          descripcion: "descripcion",
                          categoria: "categoria",
                          presupuesto: "presupuesto",
                          tiempo: 0,
                          link: "link",
                          typeLocation: cat['tipo'],
                        ),
                        citas: citas,
                      ),
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Mapeo de string a IconData
                      Icon(
                        cat['icono'],
                        size: 50,
                        color: const Color(0xFF796B9B),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        cat['nombre'],
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
