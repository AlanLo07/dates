// lib/screens/result_screen.dart
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart'; // Para abrir enlaces
import '../models/cita.dart';
import 'package:cached_network_image/cached_network_image.dart'; // Importar
import 'package:lottie/lottie.dart'; // Importar

class FadingTitle extends StatefulWidget {
  final String title;

  const FadingTitle({required this.title, super.key});

  @override
  State<FadingTitle> createState() => _FadingTitleState();
}

class _FadingTitleState extends State<FadingTitle>
    with SingleTickerProviderStateMixin {
  // 1. Controlador de la animación
  late AnimationController _controller;
  // 2. Curva de la animación (opcional, pero mejora el efecto)
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();

    // Inicializar el controlador
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1), // Duración de 1 segundo
    );

    // Inicializar la animación de opacidad con una curva suave
    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeIn, // Empieza lento y se acelera ligeramente
      ),
    );

    // Iniciar la animación al cargar el widget
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Definimos el color que ya elegiste para el texto principal
    const Color violetaProfundo = Color(0xFF796B9B);

    return FadeTransition(
      opacity: _opacityAnimation, // Usamos la animación que definimos
      child: Text(
        widget.title,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: violetaProfundo, // Aplicamos el color del tema
        ),
      ),
    );
  }
}

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

  Widget _buildMediaWidget() {
    if (cita.imagenUrl.isEmpty) {
      // Si no hay URL, muestra un icono por defecto
      return const Icon(
        Icons.favorite_border,
        size: 80,
        color: violetaProfundo,
      );
    }

    // Si es un archivo Lottie (JSON)
    if (cita.imagenUrl.endsWith('.json')) {
      return Lottie.network(
        cita.imagenUrl,
        width: 250,
        height: 250,
        repeat: true,
      );
    }

    // Si es una imagen estática (JPG, PNG)
    return ClipRRect(
      borderRadius: BorderRadius.circular(20.0),
      child: CachedNetworkImage(
        imageUrl: cita.imagenUrl,
        width: 250,
        height: 250,
        fit: BoxFit.scaleDown,
        placeholder: (context, url) =>
            const Center(child: CircularProgressIndicator()),
        errorWidget: (context, url, error) => const Icon(Icons.error),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('¡Su Plan de Aniversario!'),
        backgroundColor: grisClaroCalido,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              _buildMediaWidget(),
              const SizedBox(height: 20),

              FadingTitle(title: cita.nombre),
              const SizedBox(height: 15),

              Text(
                cita.descripcion,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18, color: violetaProfundo),
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
                    backgroundColor: malvaSuave,
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
        Icon(icon, size: 40, color: violetaProfundo),
        const SizedBox(height: 5),
        Text(text, style: const TextStyle(fontWeight: FontWeight.w600)),
      ],
    );
  }
}
