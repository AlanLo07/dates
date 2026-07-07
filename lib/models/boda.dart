// lib/models/boda.dart
import 'package:flutter/material.dart';

// ── Invitado ───────────────────────────────────────────────────────────────
enum RsvpStatus { confirmado, pendiente, noVa }

extension RsvpStatusX on RsvpStatus {
  String get label {
    switch (this) {
      case RsvpStatus.confirmado:
        return 'Confirmado';
      case RsvpStatus.pendiente:
        return 'Pendiente';
      case RsvpStatus.noVa:
        return 'No va';
    }
  }

  static RsvpStatus fromString(String v) {
    switch (v) {
      case 'confirmado':
        return RsvpStatus.confirmado;
      case 'noVa':
        return RsvpStatus.noVa;
      default:
        return RsvpStatus.pendiente;
    }
  }
}

class Invitado {
  final String id;
  String nombre;
  String grupo; // 'Familia', 'Amigos', 'Trabajo', etc.
  int personas;
  RsvpStatus rsvp;

  Invitado({
    required this.id,
    required this.nombre,
    this.grupo = 'Amigos',
    this.personas = 1,
    this.rsvp = RsvpStatus.pendiente,
  });

  factory Invitado.fromJson(Map<String, dynamic> json) => Invitado(
    id: json['id'] ?? '',
    nombre: json['nombre'] ?? '',
    grupo: json['grupo'] ?? 'Amigos',
    personas: json['personas'] ?? 1,
    rsvp: RsvpStatusX.fromString(json['rsvp'] ?? 'pendiente'),
  );

  Map<String, dynamic> toJson() => {
    'type': 'invitado',
    'id': id,
    'nombre': nombre,
    'grupo': grupo,
    'personas': personas,
    'rsvp': rsvp.name,
  };
}

// ── Tarea del checklist ────────────────────────────────────────────────────
class TareaBoda {
  final String id;
  String titulo;
  String categoria; // 'Venue', 'Catering', 'Flores', etc.
  bool completada;
  String? fechaLimite; // "dd-MM-yyyy"

  TareaBoda({
    required this.id,
    required this.titulo,
    this.categoria = 'General',
    this.completada = false,
    this.fechaLimite,
  });

  factory TareaBoda.fromJson(Map<String, dynamic> json) => TareaBoda(
    id: json['id'] ?? '',
    titulo: json['titulo'] ?? '',
    categoria: json['categoria'] ?? 'General',
    completada: json['completada'] ?? false,
    fechaLimite: json['fechaLimite'],
  );

  Map<String, dynamic> toJson() => {
    'type': 'tarea_boda',
    'id': id,
    'titulo': titulo,
    'categoria': categoria,
    'completada': completada,
    'fechaLimite': fechaLimite,
  };
}

// ── Paso del itinerario ────────────────────────────────────────────────────
class PasoBoda {
  final String id;
  String titulo;
  String hora; // "HH:mm"
  String nota;
  String emoji;

  PasoBoda({
    required this.id,
    required this.titulo,
    required this.hora,
    this.nota = '',
    this.emoji = '💒',
  });

  factory PasoBoda.fromJson(Map<String, dynamic> json) => PasoBoda(
    id: json['id'] ?? '',
    titulo: json['titulo'] ?? '',
    hora: json['hora'] ?? '',
    nota: json['nota'] ?? '',
    emoji: json['emoji'] ?? '💒',
  );

  Map<String, dynamic> toJson() => {
    'type': 'paso_boda',
    'id': id,
    'titulo': titulo,
    'hora': hora,
    'nota': nota,
    'emoji': emoji,
  };
}

// ── Gasto ──────────────────────────────────────────────────────────────────
class GastoBoda {
  final String id;
  String concepto;
  String categoria;
  double estimado;
  double pagado;

  GastoBoda({
    required this.id,
    required this.concepto,
    this.categoria = 'General',
    this.estimado = 0,
    this.pagado = 0,
  });

  factory GastoBoda.fromJson(Map<String, dynamic> json) => GastoBoda(
    id: json['id'] ?? '',
    concepto: json['concepto'] ?? '',
    categoria: json['categoria'] ?? 'General',
    estimado: (json['estimado'] ?? 0).toDouble(),
    pagado: (json['pagado'] ?? 0).toDouble(),
  );

  Map<String, dynamic> toJson() => {
    'type': 'gasto_boda',
    'id': id,
    'concepto': concepto,
    'categoria': categoria,
    'estimado': estimado,
    'pagado': pagado,
  };
}

// ── Canción ────────────────────────────────────────────────────────────────
class CancionBoda {
  final String id;
  String titulo;
  String artista;
  String momento; // 'Entrada', 'Primer baile', 'Vals', 'Fiesta'
  String link;

  CancionBoda({
    required this.id,
    required this.titulo,
    required this.artista,
    this.momento = 'Fiesta',
    this.link = '',
  });

  factory CancionBoda.fromJson(Map<String, dynamic> json) => CancionBoda(
    id: json['id'] ?? '',
    titulo: json['titulo'] ?? '',
    artista: json['artista'] ?? '',
    momento: json['momento'] ?? 'Fiesta',
    link: json['link'] ?? '',
  );

  Map<String, dynamic> toJson() => {
    'type': 'cancion_boda',
    'id': id,
    'titulo': titulo,
    'artista': artista,
    'momento': momento,
    'link': link,
  };
}

// ── Proveedor / Opción (Flores, Hospedaje, etc.) ────────────────────────────
enum EstadoProveedor { pendiente, confirmado, pagado }

extension EstadoProveedorX on EstadoProveedor {
  String get label {
    switch (this) {
      case EstadoProveedor.pendiente:
        return 'Pendiente';
      case EstadoProveedor.confirmado:
        return 'Confirmado';
      case EstadoProveedor.pagado:
        return 'Pagado';
    }
  }

  Color get color {
    switch (this) {
      case EstadoProveedor.pendiente:
        return const Color(0xFFFB8C00);
      case EstadoProveedor.confirmado:
        return const Color(0xFF1E88E5);
      case EstadoProveedor.pagado:
        return const Color(0xFF2E7D32);
    }
  }

  static EstadoProveedor fromString(String v) {
    switch (v) {
      case 'confirmado':
        return EstadoProveedor.confirmado;
      case 'pagado':
        return EstadoProveedor.pagado;
      default:
        return EstadoProveedor.pendiente;
    }
  }
}

class ProveedorBoda {
  final String id;
  String nombre;
  String categoria;
  String contacto;
  String link;
  double costo;
  EstadoProveedor estado;
  String notas;

  ProveedorBoda({
    required this.id,
    required this.nombre,
    required this.categoria,
    this.contacto = '',
    this.link = '',
    this.costo = 0,
    this.estado = EstadoProveedor.pendiente,
    this.notas = '',
  });

  factory ProveedorBoda.fromJson(Map<String, dynamic> json) => ProveedorBoda(
    id: json['id'] ?? '',
    nombre: json['nombre'] ?? '',
    categoria: json['categoria'] ?? '',
    contacto: json['contacto'] ?? '',
    link: json['link'] ?? '',
    costo: (json['costo'] ?? 0).toDouble(),
    estado: EstadoProveedorX.fromString(json['estado'] ?? 'pendiente'),
    notas: json['notas'] ?? '',
  );

  Map<String, dynamic> toJson() => {
    'type': 'proveedor_boda',
    'id': id,
    'nombre': nombre,
    'categoria': categoria,
    'contacto': contacto,
    'link': link,
    'costo': costo,
    'estado': estado.name,
    'notas': notas,
  };
}

// ── Look (vestuario) ────────────────────────────────────────────────────────
class LookBoda {
  final String id;
  String persona; // 'Ella' | 'Él'
  String prenda; // 'Vestido', 'Traje', 'Zapatos', 'Accesorios'...
  String tienda;
  String talla;
  double precio;
  bool comprado;
  String notas;

  LookBoda({
    required this.id,
    required this.persona,
    required this.prenda,
    this.tienda = '',
    this.talla = '',
    this.precio = 0,
    this.comprado = false,
    this.notas = '',
  });

  factory LookBoda.fromJson(Map<String, dynamic> json) => LookBoda(
    id: json['id'] ?? '',
    persona: json['persona'] ?? 'Ella',
    prenda: json['prenda'] ?? '',
    tienda: json['tienda'] ?? '',
    talla: json['talla'] ?? '',
    precio: (json['precio'] ?? 0).toDouble(),
    comprado: json['comprado'] ?? false,
    notas: json['notas'] ?? '',
  );

  Map<String, dynamic> toJson() => {
    'type': 'look_boda',
    'id': id,
    'persona': persona,
    'prenda': prenda,
    'tienda': tienda,
    'talla': talla,
    'precio': precio,
    'comprado': comprado,
    'notas': notas,
  };
}
