import 'package:flutter/material.dart';
import '../services/cita_service.dart';
import '../models/cita.dart';
import 'result.dart';
import '../utils/animations.dart';

class AdventureListScreen extends StatefulWidget {
  final Cita cita;
  final List<Cita> citas;
  const AdventureListScreen({
    required this.cita,
    required this.citas,
    super.key,
  });

  @override
  State<AdventureListScreen> createState() => _AdventureListScreenState();
}

class _AdventureListScreenState extends State<AdventureListScreen> {
  late Cita citaSelected;
  late List<Cita> listaLugares;

  @override
  void initState() {
    super.initState();
    // Inicializamos usando la variable recibida
    citaSelected = widget.cita;
    listaLugares = widget.citas;
  }

  // Función para construir las estrellas de calificación
  Widget _buildRatingStars(Cita lugar) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        return GestureDetector(
          onTap: () {
            setState(() {
              // Si presiona la misma estrella, bajamos el rating (opcional)
              // o simplemente asignamos el nuevo valor
              lugar.rating = index + 1.0;
            });
            saveLugares(); // Sincroniza con la API
          },
          child: Icon(
            index < (lugar.rating) ? Icons.star : Icons.star_border,
            color: Colors.amber,
            size: 28, // Tamaño ideal para tocar en iPhone
          ),
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    const Color violetaProfundo = Color(0xFF796B9B);

    final lugares = listaLugares
        .where((l) => l.typeLocation == citaSelected.typeLocation)
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Nuestras Aventuras',
          style: TextStyle(color: violetaProfundo),
        ),
        backgroundColor: Colors.white,
      ),
      body: ListView.builder(
        itemCount: lugares.length,
        itemBuilder: (context, index) {
          final lugar = lugares[index];
          print("Lugar: $lugar.isVisited $lugar.nombre");
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
            child: Column(
              children: [
                ListTile(
                  leading: Checkbox(
                    activeColor: violetaProfundo,
                    value: lugar.isVisited,
                    onChanged: (bool? value) {
                      setState(() {
                        lugar.isVisited = value ?? false;
                      });
                      saveLugares();
                    },
                  ),
                  title: Text(
                    lugar.nombre,
                    style: TextStyle(
                      decoration: lugar.isVisited
                          ? TextDecoration.lineThrough
                          : null,
                      color: lugar.isVisited ? Colors.grey : violetaProfundo,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Text(lugar.descripcion),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    Navigator.of(
                      context,
                    ).push(createRoute(ResultScreen(cita: lugar)));
                  },
                ),
                // Sección de calificación al final del Card
                Padding(
                  padding: const EdgeInsets.only(
                    bottom: 10,
                    left: 16,
                    right: 16,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "¿Qué tan increíble fue?",
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      _buildRatingStars(lugar),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> saveLugares() async {
    // 1. Opcional: Puedes seguir guardando localmente como "respaldo" (Cache)
    // final prefs = await SharedPreferences.getInstance();
    // final String encoded = json.encode(listaLugares.map((l) => l.toJson()).toList());
    // await prefs.setString(_lugaresKey, encoded);

    // 2. Sincronizar con la API (DynamoDB)
    try {
      await ApiService().syncLugares(listaLugares);
    } catch (e) {
      // Aquí puedes manejar qué pasa si no hay internet
      print("No se pudo guardar en la nube, se intentará más tarde.");
    }
  }
}
