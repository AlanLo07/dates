class ItemChecklist {
  final String nombre;
  final bool incluido;

  const ItemChecklist({
    required this.nombre,
    this.incluido = false,
  });

  factory ItemChecklist.fromJson(Map<String, dynamic> json) {
    return ItemChecklist(
      nombre: (json['nombre'] ?? '').toString(),
      incluido: (json['comprado'] ?? json['incluido']) == true,
    );
  }

  Map<String, dynamic> toJson() {
    return {'nombre': nombre, 'comprado': incluido};
  }
}

class ChecklistEvento {
  final List<ItemChecklist> items;
  final String? titulo;

  const ChecklistEvento({this.items = const [], this.titulo});

  factory ChecklistEvento.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const ChecklistEvento();
    final raw = json['items'];
    final items = raw is List
        ? raw
              .whereType<Map>()
              .map((item) => ItemChecklist.fromJson(Map<String, dynamic>.from(item)))
              .toList()
        : <ItemChecklist>[];
    return ChecklistEvento(items: items, titulo: json['titulo'] as String?);
  }

  Map<String, dynamic> toJson() {
    if (titulo != null && titulo!.trim().isEmpty) {
      throw ArgumentError('Escribe un titulo para el checklist');
    }
    if (titulo != null && items.length > 98) {
      throw ArgumentError('El checklist admite hasta 98 items iniciales');
    }
    return {
      if (titulo != null) 'titulo': titulo,
      'items': items.map((i) => i.toJson()).toList(),
    };
  }
}

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
  final ChecklistEvento checklist;
  final String? checklistId;
  final bool actualizarChecklist;
  static const _sinCambio = Object();

  EventoImportante({
    required this.id,
    required this.title,
    required this.description,
    required this.date,
    this.icon = 'backpack_outlined',
    this.itinerario = const ItinerarioEvento(),
    this.presupuesto = const PresupuestoEvento(),
    this.documentos = const [],
    this.checklist = const ChecklistEvento(),
    this.checklistId,
    this.actualizarChecklist = false,
  });

  EventoImportante copyWith({
    String? id,
    String? title,
    String? description,
    String? date,
    String? icon,
    ItinerarioEvento? itinerario,
    PresupuestoEvento? presupuesto,
    List<String>? documentos,
    ChecklistEvento? checklist,
    Object? checklistId = _sinCambio,
  }) {
    return EventoImportante(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      date: date ?? this.date,
      icon: icon ?? this.icon,
      itinerario: itinerario ?? this.itinerario,
      presupuesto: presupuesto ?? this.presupuesto,
      documentos: documentos ?? this.documentos,
        checklist: checklist ??
          (identical(checklistId, _sinCambio)
            ? this.checklist
            : const ChecklistEvento()),
        checklistId: identical(checklistId, _sinCambio)
          ? (checklist?.titulo != null ? null : this.checklistId)
          : checklistId as String?,
        actualizarChecklist: !identical(checklistId, _sinCambio) ||
          checklist?.titulo != null || actualizarChecklist,
    );
  }

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
      checklistId: json['checklistId'] as String?,
      checklist: ChecklistEvento.fromJson(
        json['checklist'] is Map
            ? Map<String, dynamic>.from(json['checklist'])
            : null,
      ),
    );
  }

  Map<String, dynamic> toJson({bool incluirVinculo = true}) => {
    'type': 'evento',
    'id': id,
    'title': title,
    'description': description,
    'date': date,
    'icon': icon,
    'itinerario': itinerario.toJson(),
    'presupuesto': presupuesto.toJson(),
    'documentos': documentos,
    if (incluirVinculo && checklist.titulo != null)
      'checklist': checklist.toJson()
    else if (incluirVinculo && (checklistId != null || actualizarChecklist))
      'checklistId': checklistId,
  };
}
