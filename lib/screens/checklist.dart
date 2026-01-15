import 'package:flutter/material.dart';
import '../services/cita_service.dart';
import '../models/cita.dart';
import 'result.dart';
import '../utils/animations.dart';

class AdventureListScreen extends StatefulWidget {
  final Cita cita;
  const AdventureListScreen({required this.cita, super.key});

  @override
  State<AdventureListScreen> createState() => _AdventureListScreenState();
}

class _AdventureListScreenState extends State<AdventureListScreen> {
  late Cita citaSelected;

  @override
  void initState() {
    super.initState();
    // Inicializamos usando la variable recibida
    citaSelected = widget.cita;
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
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
            child: ListTile(
              // 1. FUNCIÓN TACHADO (Al tocar el cuerpo del Card o el Checkbox)
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

              // 2. FUNCIÓN ENLACE (Botón al final)
              trailing: const Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Colors.grey,
              ),

              // También podemos hacer que al tocar el título se tache
              onTap: () {
                citaSelected = lugar;
                Navigator.of(
                  context,
                ).push(createRoute(ResultScreen(cita: citaSelected)));
              },
            ),
          );
        },
      ),
    );
  }
}
