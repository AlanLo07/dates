class ActividadItinerario {
  final String fecha;
  final String tiempo;
  final String actividad;

  const ActividadItinerario({
    required this.fecha,
    required this.tiempo,
    required this.actividad,
  });

  factory ActividadItinerario.fromJson(Map<String, dynamic> json) {
    return ActividadItinerario(
      fecha: (json['fecha'] ?? '').toString(),
      tiempo: (json['tiempo'] ?? '').toString(),
      actividad: (json['actividad'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {'fecha': fecha, 'tiempo': tiempo, 'actividad': actividad};
  }
}

class ItinerarioEvento {
  final List<ActividadItinerario> actividades;

  const ItinerarioEvento({this.actividades = const []});

  factory ItinerarioEvento.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const ItinerarioEvento();
    final raw = json['actividades'];
    final actividades = raw is List
        ? raw
              .whereType<Map>()
              .map(
                (item) => ActividadItinerario.fromJson(
                  Map<String, dynamic>.from(item),
                ),
              )
              .toList()
        : <ActividadItinerario>[];
    return ItinerarioEvento(actividades: actividades);
  }

  Map<String, dynamic> toJson() {
    return {'actividades': actividades.map((a) => a.toJson()).toList()};
  }
}

class ConceptoGasto {
  final String concepto;
  final double monto;

  const ConceptoGasto({required this.concepto, required this.monto});

  factory ConceptoGasto.fromJson(Map<String, dynamic> json) {
    final rawMonto = json['monto'];
    return ConceptoGasto(
      concepto: (json['concepto'] ?? '').toString(),
      monto: rawMonto is num
          ? rawMonto.toDouble()
          : double.tryParse(rawMonto?.toString() ?? '') ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {'concepto': concepto, 'monto': monto};
  }
}

class PresupuestoEvento {
  final double gastado;
  final double limite;
  final List<ConceptoGasto> conceptos;

  const PresupuestoEvento({
    this.gastado = 0.0,
    this.limite = 0.0,
    this.conceptos = const [],
  });

  factory PresupuestoEvento.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const PresupuestoEvento();
    final rawGastado = json['gastado'];
    final rawLimite = json['limite'];
    final rawConceptos = json['conceptos'];

    final conceptos = rawConceptos is List
        ? rawConceptos
              .whereType<Map>()
              .map((item) => ConceptoGasto.fromJson(Map<String, dynamic>.from(item)))
              .toList()
        : <ConceptoGasto>[];

    return PresupuestoEvento(
      gastado: rawGastado is num
          ? rawGastado.toDouble()
          : double.tryParse(rawGastado?.toString() ?? '') ?? 0.0,
      limite: rawLimite is num
          ? rawLimite.toDouble()
          : double.tryParse(rawLimite?.toString() ?? '') ?? 0.0,
      conceptos: conceptos,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'gastado': gastado,
      'limite': limite,
      'conceptos': conceptos.map((c) => c.toJson()).toList(),
    };
  }
}

class EventoImportante {
  final String id;
  final String title;
  final String description;
  final String date; // "dd-MM-yyyy"
  final String icon; // nombre del IconData de Flutter
  final ItinerarioEvento itinerario;
  final PresupuestoEvento presupuesto;
  final List<String> documentos;

  EventoImportante({
    required this.id,
    required this.title,
    required this.description,
    required this.date,
    this.icon = 'backpack_outlined',
    this.itinerario = const ItinerarioEvento(),
    this.presupuesto = const PresupuestoEvento(),
    this.documentos = const [],
  });

  factory EventoImportante.fromJson(Map<String, dynamic> json) {
    final rawDocumentos = json['documentos'];
    final documentos = rawDocumentos is List
        ? rawDocumentos.map((d) => d.toString()).toList()
        : <String>[];

    return EventoImportante(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      date: json['date'] ?? '',
      icon: json['icon'] ?? 'backpack_outlined',
      itinerario: ItinerarioEvento.fromJson(
        json['itinerario'] is Map
            ? Map<String, dynamic>.from(json['itinerario'])
            : null,
      ),
      presupuesto: PresupuestoEvento.fromJson(
        json['presupuesto'] is Map
            ? Map<String, dynamic>.from(json['presupuesto'])
            : null,
      ),
      documentos: documentos,
    );
  }

  Map<String, dynamic> toJson() => {
    'type': 'evento',
    'id': id,
    'title': title,
    'description': description,
    'date': date,
    'icon': icon,
    'itinerario': itinerario.toJson(),
    'presupuesto': presupuesto.toJson(),
    'documentos': documentos,
  };
}
