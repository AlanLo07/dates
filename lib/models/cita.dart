import 'package:flutter/material.dart';

class Cita {
  final String nombre;
  final String descripcion;
  final String categoria; // Ejemplo: 'Romántico', 'Aventura', 'Relajante'
  final String presupuesto; // Ejemplo: 'Bajo', 'Medio', 'Alto'
  final int tiempo; // Tiempo estimado en horas
  final String link; // Enlace a Google Maps o a una web
  final String imagenUrl;
  final String typeLocation;

  Cita({
    required this.nombre,
    required this.descripcion,
    required this.categoria,
    required this.presupuesto,
    required this.tiempo,
    required this.link,
    this.imagenUrl = '',
    this.typeLocation = '',
  });

  factory Cita.fromJson(Map<String, dynamic> json) {
    return Cita(
      nombre: json['nombre'] as String,
      descripcion: json['descripcion'] as String,
      categoria: json['categoria'] as String,
      presupuesto: json['presupuesto'] as String,
      tiempo: json['tiempo'] as int,
      link: json['link'] as String,
      imagenUrl: json['imagenUrl'] as String,
      typeLocation: json['typeLocation'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'nombre': nombre,
      'descripcion': descripcion,
      'categoria': categoria,
      'presupuesto': presupuesto,
      'tiempo': tiempo,
      'link': link,
      'imagenUrl': imagenUrl,
      'typeLocation': typeLocation,
    };
  }
}

const Color lavandaPalida = Color(0xFFD8C9E7);
const Color malvaSuave = Color(0xFFB0B6E8);
const Color azulCelestePastel = Color(0xFFA9D1DF);
const Color violetaProfundo = Color(0xFF796B9B);
const Color grisClaroCalido = Color(0xFFF0F0F0);
