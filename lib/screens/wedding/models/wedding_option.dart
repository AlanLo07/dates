import 'package:flutter/material.dart';

class WeddingOption {
  final String emoji;
  final String titulo;
  final String subtitulo;
  final Color color;
  final Widget? screen;

  const WeddingOption({
    required this.emoji,
    required this.titulo,
    required this.subtitulo,
    required this.color,
    required this.screen,
  });
}