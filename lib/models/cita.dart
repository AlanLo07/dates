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
  });

  // Método para convertir JSON a objeto Cita
  factory Cita.fromJson(Map<String, dynamic> json) {
    return Cita(
      nombre: json['nombre'],
      descripcion: json['descripcion'],
      categoria: json['categoria'],
      presupuesto: json['presupuesto'],
      tiempo: json['tiempo'],
      link: json['link'],
      imagenUrl: json['imagenUrl'],
      typeLocation: json['typeLocation'],
      isVisited: json["isVisited"],
      rating: json["rating"],
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
    };
  }
}

const Color lavandaPalida = Color(0xFFD8C9E7);
const Color malvaSuave = Color(0xFFB0B6E8);
const Color azulCelestePastel = Color(0xFFA9D1DF);
const Color violetaProfundo = Color(0xFF796B9B);
const Color grisClaroCalido = Color(0xFFF0F0F0);
