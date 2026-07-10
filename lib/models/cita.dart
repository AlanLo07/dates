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
  bool isVisited;
  double rating;
  int prioridad;

  Cita({
    required this.nombre,
    required this.descripcion,
    required this.categoria,
    required this.presupuesto,
    required this.tiempo,
    required this.link,
    this.imagenUrl = '',
    this.typeLocation = '',
    this.isVisited = false,
    this.rating = 0.0,
    this.prioridad = 9999,
  });

  // Método para convertir JSON a objeto Cita
  factory Cita.fromJson(Map<String, dynamic> json) {
    final dynamic rawRating = json['rating'];
    final dynamic rawPrioridad = json['prioridad'];

    return Cita(
      nombre: json['nombre'],
      descripcion: json['descripcion'],
      categoria: json['categoria'],
      presupuesto: json['presupuesto'],
      tiempo: json['tiempo'],
      link: json['link'],
      imagenUrl: (json['imagenUrl'] ?? '').toString(),
      typeLocation: (json['typeLocation'] ?? '').toString(),
      isVisited: json['isVisited'] == true,
      rating: rawRating is num
          ? rawRating.toDouble()
          : double.tryParse(rawRating?.toString() ?? '') ?? 0.0,
      prioridad: rawPrioridad is int
          ? rawPrioridad
          : int.tryParse(rawPrioridad?.toString() ?? '') ?? 9999,
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
      'isVisited': isVisited,
      'rating': rating,
      'prioridad': prioridad,
    };
  }
}

const Color lavandaPalida = Color(0xFFD8C9E7);
const Color malvaSuave = Color(0xFFB0B6E8);
const Color azulCelestePastel = Color(0xFFA9D1DF);
const Color violetaProfundo = Color(0xFF796B9B);
const Color grisClaroCalido = Color(0xFFF0F0F0);
