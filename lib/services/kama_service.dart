import 'dart:convert';

import 'package:http/http.dart' as http;

import '../data/kama.dart';
import 'api_config.dart';

class KamaService {
  static final KamaService _instance = KamaService._internal();
  factory KamaService() => _instance;
  KamaService._internal();

  final String _baseUrl = ApiConfig.baseUrl + ApiConfig.kamaPath;

  List<KamaPosition>? _cache;
  DateTime? _cacheTimestamp;
  static const Duration _cacheTtl = Duration(minutes: 10);

  bool get _isCacheValid =>
      _cache != null &&
      _cacheTimestamp != null &&
      DateTime.now().difference(_cacheTimestamp!) < _cacheTtl;

  Future<List<KamaPosition>> getPositions({bool forceRefresh = false}) async {
    if (!forceRefresh && _isCacheValid) return List.unmodifiable(_cache!);

    try {
      final response = await http
          .get(Uri.parse(_baseUrl))
          .timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final dynamic decoded = json.decode(response.body);

        List<dynamic> items;
        if (decoded is List) {
          items = decoded;
        } else if (decoded is Map) {
          items = (decoded['items'] ?? decoded['positions'] ?? []) as List;
        } else {
          items = [];
        }

        if (items.isNotEmpty) {
          _cache = items
              .whereType<Map>()
              .map((e) => KamaPosition.fromJson(Map<String, dynamic>.from(e)))
              .toList();
          _cacheTimestamp = DateTime.now();
          return List.unmodifiable(_cache!);
        }
      }
    } catch (_) {
      // Si falla la red, usamos el fallback local para no romper la UI.
    }

    _cache = List<KamaPosition>.from(kKamaPositions);
    _cacheTimestamp = DateTime.now();
    return List.unmodifiable(_cache!);
  }
}
