import 'package:flutter/material.dart';

class Cita {
  final String nombre;
  final String descripcion;
  final String categoria; // Ejemplo: 'Romántico', 'Aventura', 'Relajante'
  final String presupuesto; // Ejemplo: 'Bajo', 'Medio', 'Alto'
  final int tiempo; // Tiempo estimado en horas
  final String link; // Enlace a Google Maps o a una web
  final String imagenUrl;

  Cita({
    required this.nombre,
    required this.descripcion,
    required this.categoria,
    required this.presupuesto,
    required this.tiempo,
    required this.link,
    this.imagenUrl = '',
  });
}

const Color lavandaPalida = Color(0xFFD8C9E7);
const Color malvaSuave = Color(0xFFB0B6E8);
const Color azulCelestePastel = Color(0xFFA9D1DF);
const Color violetaProfundo = Color(0xFF796B9B);
const Color grisClaroCalido = Color(0xFFF0F0F0);
