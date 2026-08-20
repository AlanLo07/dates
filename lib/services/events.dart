import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/recuerdos.dart';
import '../models/carta.dart';
import '../models/fecha.dart';
import 'api_config.dart';
import '../models/song_of_week.dart';

class EventService {
  final String _baseUrl = ApiConfig.baseUrl + ApiConfig.eventosPath;
  static const Duration _cacheTtl = Duration(seconds: 45);

  List<Map<String, dynamic>>? _allCache;
  DateTime? _allCacheAt;
  Future<List<Map<String, dynamic>>>? _allInFlight;

  Uri _uri([String extra = '']) => Uri.parse('$_baseUrl$extra');

  bool get _isAllCacheValid =>
      _allCache != null &&
      _allCacheAt != null &&
      DateTime.now().difference(_allCacheAt!) < _cacheTtl;

  void _invalidateAllCache() {
    _allCache = null;
    _allCacheAt = null;
  }

  // ── GET todos y filtra por type en cliente ────────────────────────────────
  // Un solo GET es más confiable que 3 calls con ?type= cuando la Lambda
  // puede ignorar query params en ciertas configuraciones.
  Future<List<Map<String, dynamic>>> _getAll({bool forceRefresh = false}) async {
    if (!forceRefresh && _isAllCacheValid) {
      debugPrint('🟢 [EventService] getAll: usando cache (${_allCache!.length} items)');
      return _allCache!;
    }
    if (!forceRefresh && _allInFlight != null) {
      debugPrint('🟡 [EventService] getAll: reutilizando solicitud en curso');
      return _allInFlight!;
    }

    final future = () async {
      debugPrint('🔵 [EventService] getAll: GET de eventos iniciado');
      final response = await http.get(_uri());
      debugPrint('⚪️ [EventService] getAll: respuesta HTTP ${response.statusCode}');
      if (response.statusCode == 200) {
        final dynamic body = json.decode(response.body);
        // La API puede devolver {"items": [...]} o directamente [...]
        final List<dynamic> list = body is List ? body : (body['items'] ?? []);
        final parsed = list.cast<Map<String, dynamic>>();
        _allCache = parsed;
        _allCacheAt = DateTime.now();
        debugPrint('🟢 [EventService] getAll: parseados ${parsed.length} items');
        return parsed;
      }
      debugPrint('🔴 [EventService] getAll: HTTP no exitoso');
      throw Exception('Error al obtener eventos: ${response.statusCode}');
    }();

    _allInFlight = future;
    try {
      return await future;
    } catch (e) {
      debugPrint('🔴 [EventService] getAll: excepción (${e.runtimeType}): $e');
      rethrow;
    } finally {
      _allInFlight = null;
    }
  }

  // ── Carga combinada — filtra por type en el cliente ───────────────────────
  Future<CalendarData> getCalendarData({bool forceRefresh = false}) async {
    debugPrint(
      '🔵 [EventService] getCalendarData: iniciando (forceRefresh=$forceRefresh)',
    );
    final all = await _getAll(forceRefresh: forceRefresh);

    final recuerdos = all
        .where((i) => i['type'] == 'recuerdo')
        .map(Recuerdo.fromJson)
        .toList();

    final cartas = all
        .where((i) => i['type'] == 'carta')
        .map(CartaSorpresa.fromJson)
        .toList();

    final eventos = all
        .where((i) => i['type'] == 'evento')
        .map(EventoImportante.fromJson)
        .toList();

    debugPrint(
      '🟢 [EventService] getCalendarData: recuerdos=${recuerdos.length}, '
      'cartas=${cartas.length}, eventos=${eventos.length}',
    );
    return CalendarData(recuerdos: recuerdos, cartas: cartas, eventos: eventos);
  }

  // ── Recuerdos ─────────────────────────────────────────────────────────────

  Future<List<Recuerdo>> getRecuerdos({bool forceRefresh = false}) async {
    final all = await _getAll(forceRefresh: forceRefresh);
    return all
        .where((i) => i['type'] == 'recuerdo')
        .map(Recuerdo.fromJson)
        .toList();
  }

  Future<Recuerdo> createRecuerdo(Recuerdo recuerdo) async {
    final response = await http.post(
      _uri(),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(recuerdo.toJson()),
    );
    if (response.statusCode == 201) {
      final body = json.decode(response.body);
      _invalidateAllCache();
      return Recuerdo(
        id: body['id'],
        title: recuerdo.title,
        description: recuerdo.description,
        date: recuerdo.date,
        imagePath: recuerdo.imagePath,
      );
    }
    throw Exception('Error al crear recuerdo: ${response.body}');
  }

  Future<void> updateRecuerdo(Recuerdo recuerdo) async {
    final response = await http.put(
      _uri('/${recuerdo.id}'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(recuerdo.toJson()),
    );
    if (response.statusCode != 200) {
      throw Exception('Error al actualizar recuerdo: ${response.body}');
    }
    _invalidateAllCache();
  }

  Future<void> deleteRecuerdo(String id) async {
    final response = await http.delete(_uri('/$id'));
    if (response.statusCode != 200) {
      throw Exception('Error al eliminar recuerdo: ${response.body}');
    }
    _invalidateAllCache();
  }

  // ── Cartas ────────────────────────────────────────────────────────────────

  Future<List<CartaSorpresa>> getCartas({bool forceRefresh = false}) async {
    final all = await _getAll(forceRefresh: forceRefresh);
    return all
        .where((i) => i['type'] == 'carta')
        .map(CartaSorpresa.fromJson)
        .toList();
  }

  Future<CartaSorpresa> createCarta(CartaSorpresa carta) async {
    final response = await http.post(
      _uri(),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(carta.toJson()),
    );
    if (response.statusCode == 201) {
      final body = json.decode(response.body);
      _invalidateAllCache();
      return CartaSorpresa(
        id: body['id'],
        title: carta.title,
        description: carta.description,
        date: carta.date,
        imageUrl: carta.imageUrl,
        audioUrl: carta.audioUrl,
        abierta: carta.abierta,
      );
    }
    throw Exception('Error al crear carta: ${response.body}');
  }

  Future<CartaSorpresa> abrirCarta(String id) async {
    debugPrint('🔵 [EventService] abrirCarta: PATCH iniciado');
    final response = await http.patch(_uri('/$id/abrir'));
    debugPrint('⚪️ [EventService] abrirCarta: respuesta HTTP ${response.statusCode}');
    if (response.statusCode == 200) {
      final body = json.decode(response.body);
      _invalidateAllCache();
      debugPrint('🟢 [EventService] abrirCarta: completado');
      return CartaSorpresa.fromJson(body['item']);
    }
    debugPrint('🔴 [EventService] abrirCarta: HTTP no exitoso');
    final body = json.decode(response.body);
    throw Exception(body['message'] ?? 'Error al abrir carta');
  }

  Future<void> deleteCarta(String id) async {
    final response = await http.delete(_uri('/$id'));
    if (response.statusCode != 200) {
      throw Exception('Error al eliminar carta: ${response.body}');
    }
    _invalidateAllCache();
  }

  // ── Eventos ───────────────────────────────────────────────────────────────

  Future<List<EventoImportante>> getEventos({bool forceRefresh = false}) async {
    final all = await _getAll(forceRefresh: forceRefresh);
    return all
        .where((i) => i['type'] == 'evento')
        .map(EventoImportante.fromJson)
        .toList();
  }

  Future<EventoImportante> createEvento(EventoImportante evento) async {
    debugPrint('🔵 [EventService] createEvento: POST iniciado');
    final response = await http.post(
      _uri(),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(evento.toJson()),
    );
    debugPrint('⚪️ [EventService] createEvento: respuesta HTTP ${response.statusCode}');
    if (response.statusCode == 201) {
      final body = json.decode(response.body);
      _invalidateAllCache();
      debugPrint('🟢 [EventService] createEvento: completado');
      return EventoImportante(
        id: body['id'] ?? evento.id,
        title: evento.title,
        description: evento.description,
        date: evento.date,
        icon: evento.icon,
        itinerario: evento.itinerario,
        presupuesto: evento.presupuesto,
        documentos: evento.documentos,
      );
    }
    debugPrint('🔴 [EventService] createEvento: HTTP no exitoso');
    throw Exception('Error al crear evento: ${response.body}');
  }

  Future<EventoImportante> updateEvento(EventoImportante evento) async {
    debugPrint('🔵 [EventService] updateEvento: PUT iniciado');
    final response = await http.put(
      _uri('/${evento.id}'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(evento.toJson()),
    );
    debugPrint('⚪️ [EventService] updateEvento: respuesta HTTP ${response.statusCode}');
    if (response.statusCode == 200) {
      final body = json.decode(response.body);
      _invalidateAllCache();
      debugPrint('🟢 [EventService] updateEvento: completado');
      return EventoImportante.fromJson(body['item'] ?? body);
    }
    debugPrint('🔴 [EventService] updateEvento: HTTP no exitoso');
    throw Exception('Error al actualizar evento: ${response.body}');
  }

  Future<void> deleteEvento(String id) async {
    debugPrint('🔵 [EventService] deleteEvento: DELETE iniciado');
    final response = await http.delete(_uri('/$id'));
    debugPrint('⚪️ [EventService] deleteEvento: respuesta HTTP ${response.statusCode}');
    if (response.statusCode != 200) {
      debugPrint('🔴 [EventService] deleteEvento: HTTP no exitoso');
      throw Exception('Error al eliminar evento: ${response.body}');
    }
    _invalidateAllCache();
    debugPrint('🟢 [EventService] deleteEvento: completado');
  }

  // ── Canción de la semana ──────────────────────────────────────────────────

  Future<SongOfWeek?> getSongOfWeek({bool forceRefresh = false}) async {
    final all = await _getAll(forceRefresh: forceRefresh);
    final weekKey = SongOfWeek.currentWeekKey();

    print("Number week: ${weekKey}");

    final items = all
        .where((i) => i['type'] == 'cancion_semana' && i['weekKey'] == weekKey)
        .toList();

    if (items.isEmpty) return null;
    return SongOfWeek.fromJson(items.first);
  }

  Future<SongOfWeek> setSongOfWeek(SongOfWeek song) async {
    final response = await http.post(
      _uri(),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(song.toJson()),
    );
    if (response.statusCode == 201 || response.statusCode == 200) {
      final body = json.decode(response.body);
      _invalidateAllCache();
      return SongOfWeek.fromJson({
        ...song.toJson(),
        'id': body['id'] ?? song.id,
      });
    }
    throw Exception('Error al guardar canción: ${response.body}');
  }

  Future<SongOfWeek> updateSongOfWeek(SongOfWeek song) async {
    final response = await http.put(
      _uri('/${song.id}'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(song.toJson()),
    );
    if (response.statusCode == 200) {
      _invalidateAllCache();
      return song;
    }
    throw Exception('Error al actualizar canción: ${response.body}');
  }
}

/// Contenedor tipado con los datos del calendario.
class CalendarData {
  final List<Recuerdo> recuerdos;
  final List<CartaSorpresa> cartas;
  final List<EventoImportante> eventos;

  CalendarData({
    required this.recuerdos,
    required this.cartas,
    required this.eventos,
  });
}
