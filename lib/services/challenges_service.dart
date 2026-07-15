import 'dart:convert';

import 'package:http/http.dart' as http;

import '../data/desire_content.dart';
import 'api_config.dart';

class ChallengesService {
  static final ChallengesService _instance = ChallengesService._internal();
  factory ChallengesService() => _instance;
  ChallengesService._internal();

  final String _baseUrl = ApiConfig.baseUrl + ApiConfig.challengesPath;

  List<ChallengeItem>? _cache;
  DateTime? _cacheTimestamp;
  static const Duration _cacheTtl = Duration(minutes: 10);

  bool get _isCacheValid =>
      _cache != null &&
      _cacheTimestamp != null &&
      DateTime.now().difference(_cacheTimestamp!) < _cacheTtl;

  Future<List<ChallengeItem>> getChallenges({bool forceRefresh = false}) async {
    if (!forceRefresh && _isCacheValid) {
      return List<ChallengeItem>.unmodifiable(_cache!);
    }

    try {
      final response = await http
          .get(Uri.parse(_baseUrl))
          .timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        final parsed = _parseChallenges(decoded);
        if (parsed.isNotEmpty) {
          _cache = parsed;
          _cacheTimestamp = DateTime.now();
          return List<ChallengeItem>.unmodifiable(parsed);
        }
      }
    } catch (_) {
      // Si falla la red, devolvemos fallback local para no romper la UI.
    }

    _cache = List<ChallengeItem>.from(kChallenges);
    _cacheTimestamp = DateTime.now();
    return List<ChallengeItem>.unmodifiable(_cache!);
  }

  List<ChallengeItem> _parseChallenges(dynamic decoded) {
    List<dynamic> items;
    if (decoded is List) {
      items = decoded;
    } else if (decoded is Map) {
      items = (decoded['items'] ??
              decoded['challenges'] ??
              decoded['data'] ??
              decoded['results'] ??
              [])
          as List;
    } else {
      items = [];
    }

    return items
        .whereType<Map>()
        .map((e) => ChallengeItem.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }
}
