import 'dart:convert';

import 'package:http/http.dart' as http;

import '../data/desire_content.dart';
import 'api_config.dart';

class DiceCatalog {
  final List<DiceEntry> acciones;
  final List<DiceEntry> zonas;
  final List<DiceEntry> modificadores;

  const DiceCatalog({
    required this.acciones,
    required this.zonas,
    required this.modificadores,
  });

  bool get hasContent =>
      acciones.isNotEmpty && zonas.isNotEmpty && modificadores.isNotEmpty;
}

class DiceService {
  static final DiceService _instance = DiceService._internal();
  factory DiceService() => _instance;
  DiceService._internal();

  final String _baseUrl = ApiConfig.baseUrl + ApiConfig.dicePath;

  DiceCatalog? _cache;
  DateTime? _cacheTimestamp;
  static const Duration _cacheTtl = Duration(minutes: 10);

  bool get _isCacheValid =>
      _cache != null &&
      _cacheTimestamp != null &&
      DateTime.now().difference(_cacheTimestamp!) < _cacheTtl;

  Future<DiceCatalog> getCatalog({bool forceRefresh = false}) async {
    if (!forceRefresh && _isCacheValid) {
      return _cache!;
    }

    try {
      final response = await http
          .get(Uri.parse(_baseUrl))
          .timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        final parsed = _parseCatalog(decoded);
        if (parsed.hasContent) {
          _cache = parsed;
          _cacheTimestamp = DateTime.now();
          return parsed;
        }
      }
    } catch (_) {
      // Si falla la red, devolvemos fallback local para no romper la UI.
    }

    final fallback = DiceCatalog(
      acciones: List<DiceEntry>.from(kAcciones),
      zonas: List<DiceEntry>.from(kZonas),
      modificadores: List<DiceEntry>.from(kModificadores),
    );
    _cache = fallback;
    _cacheTimestamp = DateTime.now();
    return fallback;
  }

  DiceCatalog _parseCatalog(dynamic decoded) {
    List<DiceEntry> acciones = [];
    List<DiceEntry> zonas = [];
    List<DiceEntry> modificadores = [];

    if (decoded is Map) {
      acciones = _decodeGroup(
        decoded['acciones'] ?? decoded['actions'] ?? decoded['accion'],
      );
      zonas = _decodeGroup(decoded['zonas'] ?? decoded['zones'] ?? decoded['zona']);
      modificadores = _decodeGroup(
        decoded['modificadores'] ??
            decoded['modifiers'] ??
            decoded['estilos'] ??
            decoded['style'],
      );

      final mixedItems = decoded['items'] ?? decoded['dice'] ?? decoded['data'];
      if (mixedItems is List) {
        final grouped = _groupByType(mixedItems);
        if (acciones.isEmpty) acciones = grouped.acciones;
        if (zonas.isEmpty) zonas = grouped.zonas;
        if (modificadores.isEmpty) modificadores = grouped.modificadores;
      }
    } else if (decoded is List) {
      final grouped = _groupByType(decoded);
      acciones = grouped.acciones;
      zonas = grouped.zonas;
      modificadores = grouped.modificadores;
    }

    return DiceCatalog(
      acciones: acciones,
      zonas: zonas,
      modificadores: modificadores,
    );
  }

  List<DiceEntry> _decodeGroup(dynamic raw) {
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map((e) => DiceEntry.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  DiceCatalog _groupByType(List<dynamic> rawItems) {
    final acciones = <DiceEntry>[];
    final zonas = <DiceEntry>[];
    final modificadores = <DiceEntry>[];

    for (final item in rawItems.whereType<Map>()) {
      final map = Map<String, dynamic>.from(item);
      final rawType =
          (map['diceType'] ??
                  map['dice_type'] ??
                  map['type'] ??
                  map['kind'] ??
                  map['category'] ??
                  map['group'] ??
                  '')
              .toString()
              .toLowerCase()
              .trim();

      final entry = DiceEntry.fromJson(map);
      if (rawType.contains('accion') || rawType.contains('action')) {
        acciones.add(entry);
      } else if (rawType.contains('zona') || rawType.contains('zone')) {
        zonas.add(entry);
      } else if (rawType.contains('modificador') ||
          rawType.contains('modifier') ||
          rawType.contains('estilo') ||
          rawType.contains('style')) {
        modificadores.add(entry);
      }
    }

    return DiceCatalog(
      acciones: acciones,
      zonas: zonas,
      modificadores: modificadores,
    );
  }
}
