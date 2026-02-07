// lib/screens/phrases_screen.dart
import 'package:flutter/material.dart';
import '../data/phrases.dart'; // Importa tus frases
import '../models/phrase.dart'; // Importa el modelo

// Colores de tu paleta
const Color violetaProfundo = Color(0xFF796B9B);
const Color lavandaPalida = Color(0xFFD8C9E7);
const Color azulCelestePastel = Color(0xFFA9D1DF);

class PhrasesScreen extends StatefulWidget {
  const PhrasesScreen({super.key});

  @override
  State<PhrasesScreen> createState() => _PhrasesScreenState();
}

class _PhrasesScreenState extends State<PhrasesScreen>
    with SingleTickerProviderStateMixin {
  late LovePhrase _currentPhrase; // La frase que se muestra actualmente

  // Para la animación de desvanecimiento
  late AnimationController _animationController;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _currentPhrase = getRandomLovePhrase(); // Cargar una frase al iniciar

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );

    _animationController.forward(); // Inicia la animación al cargar la pantalla
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  // Función para generar una nueva frase
  void _generateNewPhrase() {
    _animationController.reverse().then((_) {
      // Desvanece la frase actual
      setState(() {
        _currentPhrase = getRandomLovePhrase(); // Carga una nueva frase
      });
      _animationController.forward(); // Desvanece la nueva frase
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: lavandaPalida,
      appBar: AppBar(
        title: const Text(
          'Frases de Amor',
          style: TextStyle(color: violetaProfundo),
        ),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: violetaProfundo),
        elevation: 1,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              // El emoticón del animal favorito (grande y en el centro)
              FadeTransition(
                opacity: _opacityAnimation,
                child: Text(
                  _currentPhrase.emoji,
                  style: const TextStyle(
                    fontSize: 80,
                  ), // Tamaño grande para el emoji
                ),
              ),
              const SizedBox(height: 30),
              // La frase de amor con animación de desvanecimiento
              FadeTransition(
                opacity: _opacityAnimation,
                child: Text(
                  _currentPhrase.text,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 24,
                    fontStyle: FontStyle.italic,
                    color: violetaProfundo,
                    height: 1.5,
                  ),
                ),
              ),
              const SizedBox(height: 50),
              // Botón para generar una nueva frase
              ElevatedButton.icon(
                onPressed: _generateNewPhrase,
                icon: const Icon(Icons.refresh),
                label: const Text('Otra'),
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      azulCelestePastel, // Un color de acento para el botón
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 30,
                    vertical: 15,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
