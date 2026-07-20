import 'dart:convert';
import 'dart:math';

import 'package:http/http.dart' as http;

import 'api_config.dart';

class HomeMascotService {
  static final HomeMascotService _instance = HomeMascotService._internal();
  factory HomeMascotService() => _instance;
  HomeMascotService._internal();

  final String _baseUrl = ApiConfig.baseUrl + ApiConfig.mascotImagesPath;
  final Random _random = Random();

  List<String>? _cache;
  DateTime? _cacheTimestamp;
  static const Duration _cacheTtl = Duration(minutes: 10);

  bool get _isCacheValid =>
      _cache != null &&
      _cacheTimestamp != null &&
      DateTime.now().difference(_cacheTimestamp!) < _cacheTtl;

  Future<List<String>> getMascotImages({bool forceRefresh = false}) async {
    if (!forceRefresh && _isCacheValid) {
      return List<String>.unmodifiable(_cache!);
    }

    try {
      final response = await http
          .get(Uri.parse(_baseUrl))
          .timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        final parsed = _parseImages(decoded);
        if (parsed.isNotEmpty) {
          _cache = parsed;
          _cacheTimestamp = DateTime.now();
          return List<String>.unmodifiable(parsed);
        }
      }
    } catch (_) {
      // Sin fallback a assets: si falla red, la UI mostrará placeholder.
    }

    _cache = const [];
    _cacheTimestamp = DateTime.now();
    return const [];
  }

  Future<String?> getRandomImage({bool forceRefresh = false}) async {
    final images = await getMascotImages(forceRefresh: forceRefresh);
    if (images.isEmpty) return null;
    return images[_random.nextInt(images.length)];
  }

  List<String> _parseImages(dynamic decoded) {
    if (decoded is List) {
      return decoded
          .map(_parseImageEntry)
          .whereType<String>()
          .where((e) => e.isNotEmpty)
          .toList();
    }

    if (decoded is Map) {
      final raw = decoded['items'] ??
          decoded['images'] ??
          decoded['data'] ??
          decoded['results'] ??
          decoded['urls'];
      if (raw is List) {
        return raw
            .map(_parseImageEntry)
            .whereType<String>()
            .where((e) => e.isNotEmpty)
            .toList();
      }
      final single = _parseImageEntry(decoded);
      return single == null || single.isEmpty ? const [] : [single];
    }

    return const [];
  }

  String? _parseImageEntry(dynamic entry) {
    if (entry is String) return entry;
    if (entry is Map) {
      final map = Map<String, dynamic>.from(entry);
      return (map['url'] ?? map['imageUrl'] ?? map['image'] ?? map['src'] ?? '')
          .toString();
    }
    return null;
  }
}