import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/recuerdos.dart';
import '../models/carta.dart';
import '../models/fecha.dart';
import 'api_config.dart';

class EventService {
  final String _baseUrl = ApiConfig.baseUrl + ApiConfig.eventosPath;

  Uri _uri([String extra = '']) => Uri.parse('$_baseUrl$extra');

  // ── GET todos y filtra por type en cliente ────────────────────────────────
  // Un solo GET es más confiable que 3 calls con ?type= cuando la Lambda
  // puede ignorar query params en ciertas configuraciones.
  Future<List<Map<String, dynamic>>> _getAll() async {
    final response = await http.get(_uri());
    if (response.statusCode == 200) {
      final dynamic body = json.decode(response.body);
      // La API puede devolver {"items": [...]} o directamente [...]
      final List<dynamic> list = body is List ? body : (body['items'] ?? []);
      return list.cast<Map<String, dynamic>>();
    }
    throw Exception('Error al obtener eventos: ${response.statusCode}');
  }

  // ── Carga combinada — filtra por type en el cliente ───────────────────────
  Future<CalendarData> getCalendarData() async {
    final all = await _getAll();

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

    return CalendarData(recuerdos: recuerdos, cartas: cartas, eventos: eventos);
  }

  // ── Recuerdos ─────────────────────────────────────────────────────────────

  Future<List<Recuerdo>> getRecuerdos() async {
    final all = await _getAll();
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
  }

  Future<void> deleteRecuerdo(String id) async {
    final response = await http.delete(_uri('/$id'));
    if (response.statusCode != 200) {
      throw Exception('Error al eliminar recuerdo: ${response.body}');
    }
  }

  // ── Cartas ────────────────────────────────────────────────────────────────

  Future<List<CartaSorpresa>> getCartas() async {
    final all = await _getAll();
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
      return CartaSorpresa(
        id: body['id'],
        title: carta.title,
        description: carta.description,
        date: carta.date,
        abierta: carta.abierta,
      );
    }
    throw Exception('Error al crear carta: ${response.body}');
  }

  Future<CartaSorpresa> abrirCarta(String id) async {
    final response = await http.patch(_uri('/$id/abrir'));
    if (response.statusCode == 200) {
      final body = json.decode(response.body);
      return CartaSorpresa.fromJson(body['item']);
    }
    final body = json.decode(response.body);
    throw Exception(body['message'] ?? 'Error al abrir carta');
  }

  Future<void> deleteCarta(String id) async {
    final response = await http.delete(_uri('/$id'));
    if (response.statusCode != 200) {
      throw Exception('Error al eliminar carta: ${response.body}');
    }
  }

  // ── Eventos ───────────────────────────────────────────────────────────────

  Future<List<EventoImportante>> getEventos() async {
    final all = await _getAll();
    return all
        .where((i) => i['type'] == 'evento')
        .map(EventoImportante.fromJson)
        .toList();
  }

  Future<EventoImportante> createEvento(EventoImportante evento) async {
    final response = await http.post(
      _uri(),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(evento.toJson()),
    );
    if (response.statusCode == 201) {
      final body = json.decode(response.body);
      return EventoImportante(
        id: body['id'],
        title: evento.title,
        description: evento.description,
        date: evento.date,
        icon: evento.icon,
      );
    }
    throw Exception('Error al crear evento: ${response.body}');
  }

  Future<void> deleteEvento(String id) async {
    final response = await http.delete(_uri('/$id'));
    if (response.statusCode != 200) {
      throw Exception('Error al eliminar evento: ${response.body}');
    }
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
