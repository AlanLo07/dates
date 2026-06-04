// lib/services/cita_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/cita.dart';
import 'api_config.dart';

class ApiService {
  // ── Singleton ──────────────────────────────────────────────────────────────
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  // ── Cache simple en memoria ────────────────────────────────────────────────
  List<Cita>? _citasCache;
  DateTime? _cacheTimestamp;
  static const Duration _cacheTtl = Duration(minutes: 5);

  bool get _isCacheValid =>
      _citasCache != null &&
      _cacheTimestamp != null &&
      DateTime.now().difference(_cacheTimestamp!) < _cacheTtl;

  void invalidateCache() {
    _citasCache = null;
    _cacheTimestamp = null;
  }

  // ── URLs ───────────────────────────────────────────────────────────────────
  final String _urlCitas = ApiConfig.baseUrl + ApiConfig.citasPath;
  final String _urlEventos = ApiConfig.baseUrl + ApiConfig.eventosPath;

  // ── Obtener citas (con cache) ──────────────────────────────────────────────
  Future<List<Cita>> getCitas({bool forceRefresh = false}) async {
    if (!forceRefresh && _isCacheValid) {
      return List.unmodifiable(_citasCache!);
    }

    try {
      final response = await http
          .get(Uri.parse(_urlCitas))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final dynamic decoded = json.decode(response.body);

        final List<dynamic> items = decoded is List
            ? decoded
            : (decoded['items'] as List? ?? []);

        _citasCache = items.map((item) => Cita.fromJson(item)).toList();
        _cacheTimestamp = DateTime.now();
        return List.unmodifiable(_citasCache!);
      } else {
        throw Exception('Error al cargar las citas: ${response.statusCode}');
      }
    } catch (e) {
      if (_citasCache != null) return List.unmodifiable(_citasCache!);
      throw Exception('No se pudo conectar con el servidor: $e');
    }
  }

  // ── Crear nueva cita ───────────────────────────────────────────────────────
  Future<Cita> createCita(Cita cita) async {
    final response = await http
        .post(
          Uri.parse(_urlCitas),
          headers: {'Content-Type': 'application/json; charset=UTF-8'},
          body: jsonEncode({'type': 'cita', ...cita.toJson()}),
        )
        .timeout(const Duration(seconds: 10));

    if (response.statusCode == 200 || response.statusCode == 201) {
      invalidateCache(); // fuerza reload en próxima consulta
      try {
        final body = json.decode(response.body);
        // Si la API devuelve el objeto creado, lo usamos; si no, devolvemos
        // la misma cita que enviamos (con los datos confirmados).
        if (body is Map && body.containsKey('nombre')) {
          return Cita.fromJson(Map<String, dynamic>.from(body));
        }
        // Algunos backends devuelven { "id": "...", "item": {...} }
        if (body is Map && body.containsKey('item')) {
          final item = body['item'];
          if (item is Map)
            return Cita.fromJson(Map<String, dynamic>.from(item));
        }
      } catch (_) {}
      // Fallback: devuelve la cita original tal como se envió
      return cita;
    }

    throw Exception(
      'Error al crear la cita: ${response.statusCode} — ${response.body}',
    );
  }

  // ── Sincronizar lugares visitados ──────────────────────────────────────────
  Future<void> syncLugares(List<Cita> lista) async {
    final futures = lista.map((cita) async {
      final url =
          '${ApiConfig.baseUrl}${ApiConfig.citasPath}/${Uri.encodeComponent(cita.nombre)}';
      final response = await http.put(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
        body: jsonEncode(cita.toJson()),
      );
      if (response.statusCode != 200) {
        throw Exception(
          'Fallo al sincronizar ${cita.nombre}: ${response.statusCode}',
        );
      }
    });

    try {
      await Future.wait(futures);
      invalidateCache();
      // ignore: avoid_print
      print('Sincronización exitosa con la nube');
    } catch (e) {
      rethrow;
    }
  }

  // ── Agendar cita ───────────────────────────────────────────────────────────
  Future<void> agendarCita({required Cita cita, required String fecha}) async {
    final body = {
      'type': 'evento',
      'title': cita.nombre,
      'date': fecha,
      'description': cita.descripcion,
      'icon': 'backpack_outlined',
    };

    final response = await http.post(
      Uri.parse(_urlEventos),
      headers: {'Content-Type': 'application/json; charset=UTF-8'},
      body: jsonEncode(body),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Error al agendar la cita: ${response.statusCode}');
    }
    // ignore: avoid_print
    print('Cita agendada exitosamente para $fecha');
  }
}
