import 'package:flutter/material.dart';
import '../models/carta.dart';
import 'package:confetti/confetti.dart';
import 'dart:math';

// Colores de tu paleta
const Color violetaProfundo = Color(0xFF796B9B);
const Color lavandaPalida = Color(0xFFD8C9E7);
const Color azulCelestePastel = Color(0xFFA9D1DF);

class LetterScreen extends StatefulWidget {
  final Carta carta;
  const LetterScreen({super.key, required this.carta});

  @override
  State<LetterScreen> createState() => _LetterScreenState();
}

class _LetterScreenState extends State<LetterScreen>
    with SingleTickerProviderStateMixin {
  bool _isOpened = false;
  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    // Duración de la explosión de confeti
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 3),
    );
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  void _abrirCarta() {
    setState(() {
      _isOpened = true;
    });
    // ¡Disparar confeti!
    _confettiController.play();

    // Aquí podrías llamar al servicio para actualizar el estado en DynamoDB a "leída"
  }

  void _cerrarCarta() {
    setState(() {
      _isOpened = false;
    });
    _confettiController.stop();
    // Aquí podrías llamar al servicio para actualizar el estado en DynamoDB a "leída"
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: lavandaPalida,
      appBar: AppBar(
        title: const Text(
          'Fechas Importantes',
          style: TextStyle(color: violetaProfundo),
        ),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: violetaProfundo),
      ), // Fondo rosado pastel
      body: Stack(
        alignment: Alignment.topCenter,
        children: [
          // 1. El contenido principal
          Center(
            child: GestureDetector(
              onTap: _isOpened
                  ? _cerrarCarta
                  : _abrirCarta, // Solo permite click si está cerrada
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 800),
                curve: Curves.easeInOutBack,
                width: _isOpened
                    ? MediaQuery.of(context).size.width * 0.85
                    : 250,
                height: _isOpened
                    ? MediaQuery.of(context).size.height * 0.6
                    : 180,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.pink.withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: _isOpened
                    ? _buildContenidoCarta()
                    : _buildSobreCerrado(),
              ),
            ),
          ),

          // 2. El widget de Confeti (debe ir al final del Stack para estar encima)
          Align(
            alignment: Alignment.center,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality
                  .explosive, // Explosión en todas direcciones
              shouldLoop: false,
              colors: const [
                Colors.pink,
                Colors.purple,
                Colors.blue,
                Colors.yellow,
              ],
              createParticlePath:
                  drawStar, // Opcional: Que el confeti sean estrellas
            ),
          ),
        ],
      ),
    );
  }

  // Función auxiliar para dibujar estrellas (opcional)
  Path drawStar(Size size) {
    double degToRad(double deg) => deg * (pi / 180.0);
    const numberOfPoints = 5;
    final halfWidth = size.width / 2;
    final externalRadius = halfWidth;
    final internalRadius = halfWidth / 2.5;
    final degreesPerStep = degToRad(360 / numberOfPoints);
    final halfDegreesPerStep = degreesPerStep / 2;
    final path = Path();
    final fullAngle = degToRad(360);
    path.moveTo(size.width, halfWidth);

    for (double step = 0; step < fullAngle; step += degreesPerStep) {
      path.lineTo(
        halfWidth + externalRadius * cos(step),
        halfWidth + externalRadius * sin(step),
      );
      path.lineTo(
        halfWidth + internalRadius * cos(step + halfDegreesPerStep),
        halfWidth + internalRadius * sin(step + halfDegreesPerStep),
      );
    }
    path.close();
    return path;
  }

  Widget _buildSobreCerrado() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.favorite, size: 50, color: Colors.pinkAccent),
        const SizedBox(height: 10),
        Text(
          "Para: Cebollita",
          style: TextStyle(color: Colors.pink[300], fontSize: 18),
        ),
        const SizedBox(height: 5),
        const Text("Toca para abrir", style: TextStyle(color: Colors.grey)),
      ],
    );
  }

  Widget _buildContenidoCarta() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(25),
      child: Column(
        children: [
          Text(
            widget.carta.title,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              fontFamily: 'Serif',
            ),
            textAlign: TextAlign.center,
          ),
          const Divider(color: Colors.pinkAccent, height: 30),
          Text(
            widget.carta.description,
            style: const TextStyle(
              fontSize: 16,
              height: 1.6,
              fontFamily: 'Serif',
            ),
            textAlign: TextAlign.justify,
          ),
        ],
      ),
    );
  }
}
