import 'package:flutter/material.dart';
import '../models/carta.dart';

class LetterScreen extends StatefulWidget {
  final CartaSorpresa carta;
  const LetterScreen({super.key, required this.carta});

  @override
  State<LetterScreen> createState() => _LetterScreenState();
}

class _LetterScreenState extends State<LetterScreen> with SingleTickerProviderStateMixin {
  bool _isOpened = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDEEF4), // Fondo rosado pastel
      body: Center(
        child: GestureDetector(
          onTap: () => setState(() => _isOpened = !_isOpened),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 800),
            curve: Curves.easeInOut,
            width: _isOpened ? 320 : 250,
            height: _isOpened ? 450 : 180,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
              boxShadow: [const BoxShadow(color: Colors.black12, blurRadius: 10)],
            ),
            child: _isOpened ? _buildContent() : _buildEnvelope(),
          ),
        ),
      ),
    );
  }

  Widget _buildEnvelope() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.mail, size: 50, color: Colors.pinkAccent),
        const SizedBox(height: 10),
        Text("Toca para abrir", style: TextStyle(color: Colors.pink[200])),
      ],
    );
  }

  Widget _buildContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Text(widget.carta.titulo, 
               style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, fontFamily: 'Serif')),
          const Divider(color: Colors.pinkAccent),
          const SizedBox(height: 10),
          Text(widget.carta.mensaje, 
               textAlign: TextAlign.justify,
               style: const TextStyle(fontSize: 16, height: 1.5)),
        ],
      ),
    );
  }
}