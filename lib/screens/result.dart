// lib/screens/result_screen.dart
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart'; // Para abrir enlaces
import '../models/cita.dart';

class ResultScreen extends StatelessWidget {
  final Cita cita;

  const ResultScreen({required this.cita, super.key});

  // Función para abrir el enlace
  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    print("Uri => $uri");
    if (!await launchUrl(uri)) {
      throw Exception('No se pudo abrir el enlace $url');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('¡Su Plan de Aniversario!'),
        backgroundColor: Colors.pink.shade300,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              const Icon(Icons.star, size: 80, color: Colors.amber),
              const SizedBox(height: 20),

              Text(
                cita.nombre,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                  color: Colors.pink,
                ),
              ),
              const SizedBox(height: 15),

              Text(
                cita.descripcion,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18, color: Colors.grey.shade700),
              ),
              const SizedBox(height: 30),

              // Detalles
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildDetail(
                    Icons.attach_money,
                    'Presupuesto: ${cita.presupuesto}',
                  ),
                  _buildDetail(Icons.access_time, 'Tiempo: ${cita.tiempo}h'),
                ],
              ),
              const SizedBox(height: 50),

              // Botón de Enlace
              if (cita.link.isNotEmpty)
                ElevatedButton.icon(
                  onPressed: () => _launchUrl(cita.link),
                  icon: const Icon(Icons.link),
                  label: const Text('Ver Detalles / Mapa'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.pink.shade400,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetail(IconData icon, String text) {
    return Column(
      children: [
        Icon(icon, size: 40, color: Colors.pink.shade300),
        const SizedBox(height: 5),
        Text(text, style: const TextStyle(fontWeight: FontWeight.w600)),
      ],
    );
  }
}
