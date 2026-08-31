// lib/models/checklist.dart
// Modelo de checklists genéricos (supermercado, viaje, deseos, personalizados).
// Aún no hay servicio/backend: estas clases ya incluyen fromJson/toJson para
// cuando se conecte la API, y helpers de UI (progreso, totales, agrupación).

import 'package:flutter/material.dart';

/// Tipo de checklist. Determina ícono/color por defecto y si trae
/// departamentos (grupos) precargados al crearla.
enum ChecklistKind {
  supermercado,
  viaje,
  deseos,
  personalizado;

  String get display {
    const labels = {
      'supermercado': 'Supermercado',
      'viaje': 'Viaje',
      'deseos': 'Lista de deseos',
      'personalizado': 'Personalizado',
    };
    return labels[name] ?? name;
  }

  String get emoji {
    const emojis = {
      'supermercado': '🛒',
      'viaje': '🧳',
      'deseos': '⭐',
      'personalizado': '📋',
    };
    return emojis[name] ?? '📋';
  }

  int get colorValue {
    const colors = {
      'supermercado': 0xFF4CAF50,
      'viaje': 0xFFFF8A65,
      'deseos': 0xFFAB47BC,
      'personalizado': 0xFF6A88D6,
    };
    return colors[name] ?? 0xFF6A88D6;
  }

  Color get color => Color(colorValue);

  /// Si esta clase de checklist normalmente agrupa items por departamento.
  bool get usesGroupsByDefault =>
      this == ChecklistKind.supermercado || this == ChecklistKind.viaje;

  static ChecklistKind fromString(String value) {
    try {
      return ChecklistKind.values.firstWhere((e) => e.name == value);
    } catch (_) {
      return ChecklistKind.personalizado;
    }
  }
}

/// Prioridad de un item dentro del checklist.
enum ItemPriority {
  alta,
  media,
  baja;

  String get display {
    const labels = {'alta': 'Alta', 'media': 'Media', 'baja': 'Baja'};
    return labels[name] ?? name;
  }

  int get colorValue {
    const colors = {
      'alta': 0xFFE57373,
      'media': 0xFFFFB74D,
      'baja': 0xFF81C784,
    };
    return colors[name] ?? 0xFF81C784;
  }

  Color get color => Color(colorValue);

  /// Menor = más prioritario, útil para ordenar.
  int get sortWeight => switch (this) {
    ItemPriority.alta => 0,
    ItemPriority.media => 1,
    ItemPriority.baja => 2,
  };

  static ItemPriority fromString(String value) {
    try {
      return ItemPriority.values.firstWhere((e) => e.name == value);
    } catch (_) {
      return ItemPriority.media;
    }
  }
}

/// Departamento/agrupador dentro de un checklist (ej. "Lácteos", "Ropa").
class ChecklistGroup {
  final String id;
  String nombre;
  String? emoji;
  int orden;

  ChecklistGroup({
    required this.id,
    required this.nombre,
    this.emoji,
    this.orden = 0,
  });

  factory ChecklistGroup.fromJson(Map<String, dynamic> json) {
    return ChecklistGroup(
      id: (json['id'] ?? '').toString(),
      nombre: (json['nombre'] ?? '').toString(),
      emoji: json['emoji']?.toString(),
      orden: (json['orden'] is num) ? (json['orden'] as num).toInt() : 0,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'nombre': nombre,
    'emoji': emoji,
    'orden': orden,
  };

  ChecklistGroup copyWith({String? nombre, String? emoji, int? orden}) {
    return ChecklistGroup(
      id: id,
      nombre: nombre ?? this.nombre,
      emoji: emoji ?? this.emoji,
      orden: orden ?? this.orden,
    );
  }
}

/// Item individual de un checklist.
class ChecklistItem {
  final String id;
  String nombre;
  String? groupId; // null = "Sin categoría" / lista simple (ej. deseos)
  ItemPriority prioridad;
  int prioridadOrden;
  double? precio; // opcional
  String? emoji; // opcional
  bool comprado; // "tachado" / ya comprado / ya lo tenemos
  String? nota;
  final DateTime createdAt;
  DateTime updatedAt;

  ChecklistItem({
    required this.id,
    required this.nombre,
    this.groupId,
    this.prioridad = ItemPriority.media,
    this.prioridadOrden = 0,
    this.precio,
    this.emoji,
    this.comprado = false,
    this.nota,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  factory ChecklistItem.fromJson(Map<String, dynamic> json) {
    final prioridad = ItemPriority.fromString(json['prioridad']?.toString() ?? '');
    return ChecklistItem(
      id: (json['id'] ?? '').toString(),
      nombre: (json['nombre'] ?? '').toString(),
      groupId: json['groupId']?.toString(),
      prioridad: prioridad,
      prioridadOrden: json['prioridadOrden'] is num
          ? (json['prioridadOrden'] as num).toInt()
          : prioridad.sortWeight + 1,
      precio: json['precio'] is num ? (json['precio'] as num).toDouble() : null,
      emoji: json['emoji']?.toString(),
      comprado: json['comprado'] == true,
      nota: json['nota']?.toString(),
      createdAt: json['createdAt'] is String
          ? DateTime.tryParse(json['createdAt'])
          : null,
      updatedAt: json['updatedAt'] is String
          ? DateTime.tryParse(json['updatedAt'])
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'nombre': nombre,
    'groupId': groupId,
    'prioridad': prioridad.name,
    'prioridadOrden': prioridadOrden,
    'precio': precio,
    'emoji': emoji,
    'comprado': comprado,
    'nota': nota,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  ChecklistItem copyWith({
    String? nombre,
    String? groupId,
    bool clearGroup = false,
    ItemPriority? prioridad,
    int? prioridadOrden,
    double? precio,
    bool clearPrecio = false,
    String? emoji,
    bool clearEmoji = false,
    bool? comprado,
    String? nota,
  }) {
    return ChecklistItem(
      id: id,
      nombre: nombre ?? this.nombre,
      groupId: clearGroup ? null : (groupId ?? this.groupId),
      prioridad: prioridad ?? this.prioridad,
      prioridadOrden: prioridadOrden ?? this.prioridadOrden,
      precio: clearPrecio ? null : (precio ?? this.precio),
      emoji: clearEmoji ? null : (emoji ?? this.emoji),
      comprado: comprado ?? this.comprado,
      nota: nota ?? this.nota,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}

/// Un checklist completo (tablero): supermercado, viaje, deseos, o uno
/// creado libremente por el usuario.
class ChecklistBoard {
  final String id;
  String titulo;
  ChecklistKind kind;
  String emoji;
  int colorValue;
  bool usaGrupos;
  List<ChecklistGroup> grupos;
  List<ChecklistItem> items;
  final DateTime createdAt;
  DateTime updatedAt;

  ChecklistBoard({
    required this.id,
    required this.titulo,
    this.kind = ChecklistKind.personalizado,
    String? emoji,
    int? colorValue,
    bool? usaGrupos,
    List<ChecklistGroup>? grupos,
    List<ChecklistItem>? items,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : emoji = emoji ?? kind.emoji,
       colorValue = colorValue ?? kind.colorValue,
       usaGrupos = usaGrupos ?? kind.usesGroupsByDefault,
       grupos = grupos ?? [],
       items = items ?? [],
       createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  Color get color => Color(colorValue);

  factory ChecklistBoard.fromJson(Map<String, dynamic> json) {
    return ChecklistBoard(
      id: (json['id'] ?? '').toString(),
      titulo: (json['titulo'] ?? '').toString(),
      kind: ChecklistKind.fromString(json['kind']?.toString() ?? ''),
      emoji: json['emoji']?.toString(),
      colorValue: json['colorValue'] is num
          ? (json['colorValue'] as num).toInt()
          : null,
      usaGrupos: json['usaGrupos'] == true,
      grupos: json['grupos'] is List
          ? (json['grupos'] as List)
                .map((g) => ChecklistGroup.fromJson(Map<String, dynamic>.from(g)))
                .toList()
          : [],
      items: json['items'] is List
          ? (json['items'] as List)
                .map((i) => ChecklistItem.fromJson(Map<String, dynamic>.from(i)))
                .toList()
          : [],
      createdAt: json['createdAt'] is String
          ? DateTime.tryParse(json['createdAt'])
          : null,
      updatedAt: json['updatedAt'] is String
          ? DateTime.tryParse(json['updatedAt'])
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'titulo': titulo,
    'kind': kind.name,
    'emoji': emoji,
    'colorValue': colorValue,
    'usaGrupos': usaGrupos,
    'grupos': grupos.map((g) => g.toJson()).toList(),
    'items': items.map((i) => i.toJson()).toList(),
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  // ── Helpers de UI ─────────────────────────────────────────────────────
  int get totalItems => items.length;
  int get compradosCount => items.where((i) => i.comprado).length;
  double get progreso => totalItems == 0 ? 0 : compradosCount / totalItems;

  double get precioTotal =>
      items.fold(0.0, (sum, i) => sum + (i.precio ?? 0));
  double get precioPendiente => items
      .where((i) => !i.comprado)
      .fold(0.0, (sum, i) => sum + (i.precio ?? 0));

  List<ChecklistItem> itemsByGroup(String? groupId) {
    final list = items.where((i) => i.groupId == groupId).toList();
    list.sort((a, b) {
      final p = a.prioridadOrden.compareTo(b.prioridadOrden);
      if (p != 0) return p;
      if (a.comprado != b.comprado) return a.comprado ? 1 : -1;
      final priority = a.prioridad.sortWeight.compareTo(b.prioridad.sortWeight);
      if (priority != 0) return priority;
      return a.nombre.toLowerCase().compareTo(b.nombre.toLowerCase());
    });
    return list;
  }

  /// Grupos ordenados, incluyendo un grupo virtual "Sin categoría" al final
  /// si hay items sin groupId.
  List<ChecklistGroup?> get gruposOrdenados {
    final ordered = [...grupos]..sort((a, b) => a.orden.compareTo(b.orden));
    final result = <ChecklistGroup?>[...ordered];
    final huerfanos = items.any((i) => i.groupId == null);
    if (huerfanos) result.add(null);
    return result;
  }

  void resetTodos() {
    for (final i in items) {
      i.comprado = false;
    }
    updatedAt = DateTime.now();
  }
}

/// Departamentos por defecto para un checklist de supermercado.
List<ChecklistGroup> defaultSupermercadoGroups() => [
  ChecklistGroup(id: 'g_frutas', nombre: 'Frutas y verduras', emoji: '🥦', orden: 0),
  ChecklistGroup(id: 'g_lacteos', nombre: 'Lácteos', emoji: '🥛', orden: 1),
  ChecklistGroup(id: 'g_carnes', nombre: 'Carnes y pescados', emoji: '🍗', orden: 2),
  ChecklistGroup(id: 'g_panaderia', nombre: 'Panadería', emoji: '🍞', orden: 3),
  ChecklistGroup(id: 'g_despensa', nombre: 'Despensa', emoji: '🥫', orden: 4),
  ChecklistGroup(id: 'g_bebidas', nombre: 'Bebidas', emoji: '🥤', orden: 5),
  ChecklistGroup(id: 'g_congelados', nombre: 'Congelados', emoji: '🧊', orden: 6),
  ChecklistGroup(id: 'g_limpieza', nombre: 'Limpieza', emoji: '🧴', orden: 7),
  ChecklistGroup(id: 'g_cuidado', nombre: 'Cuidado personal', emoji: '🧼', orden: 8),
  ChecklistGroup(id: 'g_otros', nombre: 'Otros', emoji: '📦', orden: 9),
];

/// Departamentos por defecto para un checklist de viaje.
List<ChecklistGroup> defaultViajeGroups() => [
  ChecklistGroup(id: 'g_ropa', nombre: 'Ropa', emoji: '👕', orden: 0),
  ChecklistGroup(id: 'g_documentos', nombre: 'Documentos', emoji: '🛂', orden: 1),
  ChecklistGroup(id: 'g_dinero', nombre: 'Dinero y tarjetas', emoji: '💳', orden: 2),
  ChecklistGroup(id: 'g_cosmeticos', nombre: 'Cosméticos y aseo', emoji: '🧴', orden: 3),
  ChecklistGroup(id: 'g_electronica', nombre: 'Electrónica', emoji: '🔌', orden: 4),
  ChecklistGroup(id: 'g_salud', nombre: 'Salud', emoji: '💊', orden: 5),
  ChecklistGroup(id: 'g_otros_viaje', nombre: 'Otros', emoji: '🎒', orden: 6),
];
