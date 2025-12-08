// lib/screens/phrases_screen.dart
import 'package:flutter/material.dart';

class PhrasesScreen extends StatelessWidget {
  const PhrasesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Generador de Frases de Amor')),
      body: const Center(
        child: Text('Aquí se generarán frases de amor aleatorias.'),
      ),
    );
  }
}
