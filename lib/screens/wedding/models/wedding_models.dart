// lib/screens/wedding/models/wedding_models.dart
// 🟢 MODELOS UNIFICADOS PARA BODAS CON EXPORTACIÓN CSV

import 'package:intl/intl.dart';

// ─────────────────────────────────────────────────────────────────────────
// 📋 CHECKLIST - TAREAS DE BODA
// ─────────────────────────────────────────────────────────────────────────

class TareaBoda {
  final String id;
  final String titulo;
  final String categoria; // 'Venue', 'Catering', 'Fotos', 'Invitados', etc.
  bool completada;
  final DateTime? fechaLimite;
  final String? notas;
  final int? prioridad; // 1=alta, 2=media, 3=baja

  TareaBoda({
    required this.id,
    required this.titulo,
    required this.categoria,
    this.completada = false,
    this.fechaLimite,
    this.notas,
    this.prioridad = 2,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'titulo': titulo,
    'categoria': categoria,
    'completada': completada,
    'fechaLimite': fechaLimite?.toIso8601String(),
    'notas': notas,
    'prioridad': prioridad,
  };

  factory TareaBoda.fromJson(Map<String, dynamic> json) => TareaBoda(
    id: json['id'] ?? '',
    titulo: json['titulo'] ?? '',
    categoria: json['categoria'] ?? '',
    completada: json['completada'] ?? false,
    fechaLimite: json['fechaLimite'] != null 
      ? DateTime.parse(json['fechaLimite']) 
      : null,
    notas: json['notas'],
    prioridad: json['prioridad'],
  );

  // 🔵 Exportar a formato CSV
  static String toCSV(List<TareaBoda> tareas) {
    final buffer = StringBuffer();
    // Header
    buffer.writeln('Tarea,Categoría,Completada,Fecha Límite,Prioridad,Notas');
    
    // Rows
    for (final tarea in tareas) {
      final completada = tarea.completada ? 'Sí' : 'No';
      final fechaLimite = tarea.fechaLimite != null 
        ? DateFormat('dd/MM/yyyy').format(tarea.fechaLimite!)
        : '';
      final prioridad = _prioridadLabel(tarea.prioridad);
      final notas = '"${tarea.notas ?? ''}"';
      
      buffer.writeln(
        '${tarea.titulo},${ tarea.categoria},$completada,$fechaLimite,$prioridad,$notas'
      );
    }
    return buffer.toString();
  }

  static String _prioridadLabel(int? p) {
    switch (p) {
      case 1:
        return 'Alta';
      case 3:
        return 'Baja';
      default:
        return 'Media';
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────
// 💰 PRESUPUESTO - GASTOS DE BODA
// ─────────────────────────────────────────────────────────────────────────

class GastoBoda {
  final String id;
  final String concepto; // 'Fotógrafo', 'Venue', etc.
  final String categoria; // 'Fotos', 'Venue', 'Catering', etc.
  double estimado;
  double pagado;
  final String? proveedor;
  final DateTime? fechaPago;
  final String? metodoPago; // 'Efectivo', 'Tarjeta', 'Transferencia'
  final String? notas;

  GastoBoda({
    required this.id,
    required this.concepto,
    required this.categoria,
    required this.estimado,
    this.pagado = 0,
    this.proveedor,
    this.fechaPago,
    this.metodoPago,
    this.notas,
  });

  double get pendiente => estimado - pagado;
  double get porcentajePagado => estimado == 0 ? 0 : (pagado / estimado).clamp(0, 1);

  Map<String, dynamic> toJson() => {
    'id': id,
    'concepto': concepto,
    'categoria': categoria,
    'estimado': estimado,
    'pagado': pagado,
    'proveedor': proveedor,
    'fechaPago': fechaPago?.toIso8601String(),
    'metodoPago': metodoPago,
    'notas': notas,
  };

  factory GastoBoda.fromJson(Map<String, dynamic> json) => GastoBoda(
    id: json['id'] ?? '',
    concepto: json['concepto'] ?? '',
    categoria: json['categoria'] ?? '',
    estimado: (json['estimado'] ?? 0).toDouble(),
    pagado: (json['pagado'] ?? 0).toDouble(),
    proveedor: json['proveedor'],
    fechaPago: json['fechaPago'] != null 
      ? DateTime.parse(json['fechaPago']) 
      : null,
    metodoPago: json['metodoPago'],
    notas: json['notas'],
  );

  // 🔵 Exportar a CSV
  static String toCSV(List<GastoBoda> gastos) {
    final buffer = StringBuffer();
    // Header
    buffer.writeln(
      'Concepto,Categoría,Estimado,Pagado,Pendiente,% Pagado,Proveedor,Fecha Pago,Método,Notas'
    );
    
    // Rows
    for (final gasto in gastos) {
      final estimado = gasto.estimado.toStringAsFixed(2);
      final pagado = gasto.pagado.toStringAsFixed(2);
      final pendiente = gasto.pendiente.toStringAsFixed(2);
      final porcentaje = (gasto.porcentajePagado * 100).toStringAsFixed(1);
      final fecha = gasto.fechaPago != null 
        ? DateFormat('dd/MM/yyyy').format(gasto.fechaPago!)
        : '';
      final notas = '"${gasto.notas ?? ''}"';
      
      buffer.writeln(
        '${gasto.concepto},${gasto.categoria},$estimado,$pagado,$pendiente,$porcentaje%,${gasto.proveedor ?? ''},$fecha,${gasto.metodoPago ?? ''},$notas'
      );
    }
    
    // Totales
    final totalEstimado = gastos.fold<double>(0, (s, g) => s + g.estimado);
    final totalPagado = gastos.fold<double>(0, (s, g) => s + g.pagado);
    final totalPendiente = gastos.fold<double>(0, (s, g) => s + g.pendiente);
    
    buffer.writeln('');
    buffer.writeln('TOTAL,,'
      '${totalEstimado.toStringAsFixed(2)},'
      '${totalPagado.toStringAsFixed(2)},'
      '${totalPendiente.toStringAsFixed(2)},,'
      '');
    
    return buffer.toString();
  }
}

// ─────────────────────────────────────────────────────────────────────────
// 🏨 HOSPEDAJE
// ─────────────────────────────────────────────────────────────────────────

class HospedajeBoda {
  final String id;
  final String nombre;
  final String direccion;
  final String telefono;
  final String email;
  final String website;
  final double precioNoche;
  final int habitacionesDisponibles;
  final String tipoHabitacion; // 'Suite', 'Doble', 'Sencilla'
  final List<String> servicios; // ['WiFi', 'Desayuno', 'Estacionamiento']
  final String notas;

  HospedajeBoda({
    required this.id,
    required this.nombre,
    required this.direccion,
    required this.telefono,
    required this.email,
    required this.website,
    required this.precioNoche,
    required this.habitacionesDisponibles,
    required this.tipoHabitacion,
    required this.servicios,
    required this.notas,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'nombre': nombre,
    'direccion': direccion,
    'telefono': telefono,
    'email': email,
    'website': website,
    'precioNoche': precioNoche,
    'habitacionesDisponibles': habitacionesDisponibles,
    'tipoHabitacion': tipoHabitacion,
    'servicios': servicios,
    'notas': notas,
  };

  factory HospedajeBoda.fromJson(Map<String, dynamic> json) => HospedajeBoda(
    id: json['id'] ?? '',
    nombre: json['nombre'] ?? '',
    direccion: json['direccion'] ?? '',
    telefono: json['telefono'] ?? '',
    email: json['email'] ?? '',
    website: json['website'] ?? '',
    precioNoche: (json['precioNoche'] ?? 0).toDouble(),
    habitacionesDisponibles: json['habitacionesDisponibles'] ?? 0,
    tipoHabitacion: json['tipoHabitacion'] ?? '',
    servicios: List<String>.from(json['servicios'] ?? []),
    notas: json['notas'] ?? '',
  );
}

// ─────────────────────────────────────────────────────────────────────────
// 🍽️ MENÚ Y CATERING
// ─────────────────────────────────────────────────────────────────────────

class PlatoMenu {
  final String id;
  final String nombre;
  final String descripcion;
  final String? imagen;
  final bool esVegetariano;
  final bool esSinGluten;
  final List<String> alergenos; // ['Maní', 'Lácteos', 'Mariscos']

  PlatoMenu({
    required this.id,
    required this.nombre,
    required this.descripcion,
    this.imagen,
    this.esVegetariano = false,
    this.esSinGluten = false,
    this.alergenos = const [],
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'nombre': nombre,
    'descripcion': descripcion,
    'imagen': imagen,
    'esVegetariano': esVegetariano,
    'esSinGluten': esSinGluten,
    'alergenos': alergenos,
  };

  factory PlatoMenu.fromJson(Map<String, dynamic> json) => PlatoMenu(
    id: json['id'] ?? '',
    nombre: json['nombre'] ?? '',
    descripcion: json['descripcion'] ?? '',
    imagen: json['imagen'],
    esVegetariano: json['esVegetariano'] ?? false,
    esSinGluten: json['esSinGluten'] ?? false,
    alergenos: List<String>.from(json['alergenos'] ?? []),
  );
}

class MenuBoda {
  final String id;
  final String nombre; // 'Entrada', 'Plato Principal', etc.
  final List<PlatoMenu> platos;
  final String? notas;

  MenuBoda({
    required this.id,
    required this.nombre,
    required this.platos,
    this.notas,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'nombre': nombre,
    'platos': platos.map((p) => p.toJson()).toList(),
    'notas': notas,
  };

  factory MenuBoda.fromJson(Map<String, dynamic> json) => MenuBoda(
    id: json['id'] ?? '',
    nombre: json['nombre'] ?? '',
    platos: (json['platos'] as List?)
        ?.map((p) => PlatoMenu.fromJson(p))
        .toList() ?? [],
    notas: json['notas'],
  );
}

// ─────────────────────────────────────────────────────────────────────────
// 👨‍💼 PROVEEDORES Y SERVICIOS
// ─────────────────────────────────────────────────────────────────────────

class Proveedor {
  final String id;
  final String nombre;
  final String servicio; // 'Fotógrafo', 'Catering', 'Floristería', etc.
  final String telefono;
  final String email;
  final String? website;
  final double precio;
  final String? descripcion;
  final double rating; // 0-5
  final List<String> fotos; // URLs
  final bool contratado;
  final DateTime? fechaContratacion;
  final String? contrato; // URL o path
  final List<String> telefonosEmergencia;
  final String? notas;

  Proveedor({
    required this.id,
    required this.nombre,
    required this.servicio,
    required this.telefono,
    required this.email,
    this.website,
    required this.precio,
    this.descripcion,
    this.rating = 0,
    this.fotos = const [],
    this.contratado = false,
    this.fechaContratacion,
    this.contrato,
    this.telefonosEmergencia = const [],
    this.notas,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'nombre': nombre,
    'servicio': servicio,
    'telefono': telefono,
    'email': email,
    'website': website,
    'precio': precio,
    'descripcion': descripcion,
    'rating': rating,
    'fotos': fotos,
    'contratado': contratado,
    'fechaContratacion': fechaContratacion?.toIso8601String(),
    'contrato': contrato,
    'telefonosEmergencia': telefonosEmergencia,
    'notas': notas,
  };

  factory Proveedor.fromJson(Map<String, dynamic> json) => Proveedor(
    id: json['id'] ?? '',
    nombre: json['nombre'] ?? '',
    servicio: json['servicio'] ?? '',
    telefono: json['telefono'] ?? '',
    email: json['email'] ?? '',
    website: json['website'],
    precio: (json['precio'] ?? 0).toDouble(),
    descripcion: json['descripcion'],
    rating: (json['rating'] ?? 0).toDouble(),
    fotos: List<String>.from(json['fotos'] ?? []),
    contratado: json['contratado'] ?? false,
    fechaContratacion: json['fechaContratacion'] != null 
      ? DateTime.parse(json['fechaContratacion']) 
      : null,
    contrato: json['contrato'],
    telefonosEmergencia: List<String>.from(json['telefonosEmergencia'] ?? []),
    notas: json['notas'],
  );

  // 🔵 Exportar a CSV
  static String toCSV(List<Proveedor> proveedores) {
    final buffer = StringBuffer();
    buffer.writeln('Servicio,Proveedor,Teléfono,Email,Precio,Rating,Contratado,Fecha Contratación');
    
    for (final p in proveedores) {
      final contratado = p.contratado ? 'Sí' : 'No';
      final fecha = p.fechaContratacion != null 
        ? DateFormat('dd/MM/yyyy').format(p.fechaContratacion!)
        : '';
      
      buffer.writeln(
        '${p.servicio},${p.nombre},${p.telefono},${p.email},\$${p.precio.toStringAsFixed(2)},${p.rating}/5,$contratado,$fecha'
      );
    }
    return buffer.toString();
  }
}

// ─────────────────────────────────────────────────────────────────────────
// 🎁 REGALO Y MESA DE REGALOS
// ─────────────────────────────────────────────────────────────────────────

class Regalo {
  final String id;
  final String nombre;
  final String descripcion;
  final double precio;
  final String? enlace; // URL a tienda
  final String? imagen;
  final bool adquirido;
  final String? compradorNombre; // Invitado que lo compró
  final String? notas;

  Regalo({
    required this.id,
    required this.nombre,
    required this.descripcion,
    required this.precio,
    this.enlace,
    this.imagen,
    this.adquirido = false,
    this.compradorNombre,
    this.notas,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'nombre': nombre,
    'descripcion': descripcion,
    'precio': precio,
    'enlace': enlace,
    'imagen': imagen,
    'adquirido': adquirido,
    'compradorNombre': compradorNombre,
    'notas': notas,
  };

  factory Regalo.fromJson(Map<String, dynamic> json) => Regalo(
    id: json['id'] ?? '',
    nombre: json['nombre'] ?? '',
    descripcion: json['descripcion'] ?? '',
    precio: (json['precio'] ?? 0).toDouble(),
    enlace: json['enlace'],
    imagen: json['imagen'],
    adquirido: json['adquirido'] ?? false,
    compradorNombre: json['compradorNombre'],
    notas: json['notas'],
  );
}

// ─────────────────────────────────────────────────────────────────────────
// 📸 ÁLBUM DE FOTOS
// ─────────────────────────────────────────────────────────────────────────

class FotoBoda {
  final String id;
  final String url;
  final String titulo;
  final String? descripcion;
  final DateTime fechaTomada;
  final String? camarogrfo; // Quién la tomó
  final bool esDestacada;
  final List<String> tags; // ['ceremonia', 'fiesta', 'primer baile']

  FotoBoda({
    required this.id,
    required this.url,
    required this.titulo,
    this.descripcion,
    required this.fechaTomada,
    this.camarogrfo,
    this.esDestacada = false,
    this.tags = const [],
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'url': url,
    'titulo': titulo,
    'descripcion': descripcion,
    'fechaTomada': fechaTomada.toIso8601String(),
    'camarogrfo': camarogrfo,
    'esDestacada': esDestacada,
    'tags': tags,
  };

  factory FotoBoda.fromJson(Map<String, dynamic> json) => FotoBoda(
    id: json['id'] ?? '',
    url: json['url'] ?? '',
    titulo: json['titulo'] ?? '',
    descripcion: json['descripcion'],
    fechaTomada: DateTime.parse(json['fechaTomada'] ?? DateTime.now().toIso8601String()),
    camarogrfo: json['camarogrfo'],
    esDestacada: json['esDestacada'] ?? false,
    tags: List<String>.from(json['tags'] ?? []),
  );
}
