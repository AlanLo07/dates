// lib/services/cita_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/cita.dart';
import 'api_config.dart';

class ApiService {
  // ── Singleton ──────────────────────────────────────────────────────────────
  // Evita crear una nueva instancia en cada ApiService() y permite
  // compartir el cache entre widgets.
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

  /// Invalida el cache manualmente (llamar después de mutaciones).
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

        // Soporta { "items": [...] } y array directo [...]
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
      // Si tenemos cache viejo, preferimos devolverlo antes de romper la UI
      if (_citasCache != null) return List.unmodifiable(_citasCache!);
      throw Exception('No se pudo conectar con el servidor: $e');
    }
  }

  // ── Sincronizar lugares visitados ──────────────────────────────────────────
  Future<void> syncLugares(List<Cita> lista) async {
    // Solo sincroniza las citas que realmente cambiaron (isVisited o rating)
    // para evitar N llamadas innecesarias.
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
      await Future.wait(futures); // Llamadas en paralelo, no secuenciales
      invalidateCache(); // Forzar refresh en próxima consulta
      // ignore: avoid_print
      print('Sincronización exitosa con la nube');
    } catch (e) {
      rethrow;
    }
  }

  // ── Agendar cita ───────────────────────────────────────────────────────────
  Future<void> agendarCita({
    required Cita cita,
    required String fecha, // Formato "dd-MM-yyyy"
  }) async {
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
