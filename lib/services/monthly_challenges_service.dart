import 'dart:convert';

import '../models/monthly_challenge.dart';
import 'api_config.dart';
import 'authenticated_http_client.dart' as http;

class MonthlyChallengesApiException implements Exception {
  const MonthlyChallengesApiException(this.message, this.statusCode);

  final String message;
  final int statusCode;

  @override
  String toString() => message;
}

class MonthlyChallengesService {
  MonthlyChallengesService();

  final String _baseUrl =
      '${ApiConfig.baseUrl.replaceFirst(RegExp(r'/$'), '')}${ApiConfig.monthlyChallengesPath}';

  Uri _uri(String path, [Map<String, String>? query]) => Uri.parse('$_baseUrl$path')
      .replace(queryParameters: query?.isEmpty == true ? null : query);

  Future<Map<String, dynamic>> _request({
    required Future<http.Response> Function() request,
    required Set<int> successCodes,
  }) async {
    final response = await request().timeout(const Duration(seconds: 12));
    final dynamic decoded = response.body.isEmpty
        ? <String, dynamic>{}
        : jsonDecode(response.body);
    if (!successCodes.contains(response.statusCode)) {
      final rawError = decoded is Map ? decoded['error'] : null;
      throw MonthlyChallengesApiException(
        (rawError ?? 'Error en retos mensuales').toString(),
        response.statusCode,
      );
    }
    return decoded is Map ? Map<String, dynamic>.from(decoded) : {};
  }

  Future<void> initializeCouple({
    required String user1Email,
    required String user2Email,
    required String user1Name,
    required String user2Name,
  }) async {
    await _request(
      request: () => http.post(
        _uri('/init'),
        headers: const {'Content-Type': 'application/json; charset=UTF-8'},
        body: jsonEncode({
          'user1Email': user1Email,
          'user2Email': user2Email,
          'user1Name': user1Name,
          'user2Name': user2Name,
        }),
      ),
      successCodes: {200, 201},
    );
  }

  Future<MonthlyChallengeState> getCurrent() async {
    final data = await _request(
      request: () => http.get(_uri('/current')),
      successCodes: {200},
    );
    return MonthlyChallengeState.fromJson(data);
  }

  Future<MonthlyChallengeState> getMonth(String monthKey) async {
    final data = await _request(
      request: () => http.get(_uri('/${Uri.encodeComponent(monthKey)}')),
      successCodes: {200},
    );
    return MonthlyChallengeState.fromJson(data);
  }

  Future<MonthlyChallengeState> proposeCustom({
    required String title,
    required String description,
    required String category,
  }) => _mutateState(
    '/current/proposals',
    () => http.post(
      _uri('/current/proposals'),
      headers: const {'Content-Type': 'application/json; charset=UTF-8'},
      body: jsonEncode({
        'source': 'custom',
        'title': title,
        'description': description,
        'category': category,
      }),
    ),
    {200, 201},
  );

  Future<MonthlyChallengeState> proposeCatalog(String challengeId) => _mutateState(
    '/current/proposals',
    () => http.post(
      _uri('/current/proposals'),
      headers: const {'Content-Type': 'application/json; charset=UTF-8'},
      body: jsonEncode({
        'source': 'catalog',
        'catalogChallengeId': challengeId,
      }),
    ),
    {200, 201},
  );

  Future<MonthlyChallengeState> withdrawProposal() => _mutateState(
    '/current/proposals',
    () => http.delete(_uri('/current/proposals')),
    {200},
  );

  Future<MonthlyChallengeState> chooseProposal(String proposedBy) => _mutateState(
    '/current/choice',
    () => http.post(
      _uri('/current/choice'),
      headers: const {'Content-Type': 'application/json; charset=UTF-8'},
      body: jsonEncode({'proposedBy': proposedBy}),
    ),
    {200},
  );

  Future<MonthlyChallengeState> requestRandomTiebreak() => _mutateState(
    '/current/choice',
    () => http.post(
      _uri('/current/choice'),
      headers: const {'Content-Type': 'application/json; charset=UTF-8'},
      body: jsonEncode({'requestRandomTiebreak': true}),
    ),
    {200},
  );

  Future<MonthlyChallengeState> editActive(Map<String, String> fields) => _mutateState(
    '/current/active',
    () => http.put(
      _uri('/current/active'),
      headers: const {'Content-Type': 'application/json; charset=UTF-8'},
      body: jsonEncode(fields),
    ),
    {200},
  );

  Future<MonthlyChallengeState> cancelActive({String? reason}) => _mutateState(
    '/current/cancel',
    () => http.post(
      _uri('/current/cancel'),
      headers: const {'Content-Type': 'application/json; charset=UTF-8'},
      body: jsonEncode({if (reason != null && reason.isNotEmpty) 'reason': reason}),
    ),
    {200},
  );

  Future<MonthlyChallengeState> replaceActive({
    required MonthlyChallengeContent content,
    String? reason,
  }) => _mutateState(
    '/current/replace',
    () => http.post(
      _uri('/current/replace'),
      headers: const {'Content-Type': 'application/json; charset=UTF-8'},
      body: jsonEncode({
        ..._contentBody(content),
        if (reason != null && reason.isNotEmpty) 'reason': reason,
      }),
    ),
    {200, 201},
  );

  Future<MonthlyChallengeCompletion> completeCurrent() async {
    final data = await _request(
      request: () => http.post(
        _uri('/current/complete'),
        headers: const {'Content-Type': 'application/json; charset=UTF-8'},
      ),
      successCodes: {200, 201},
    );
    return MonthlyChallengeCompletion.fromJson(data);
  }

  Future<MonthlyChallengeCouponResult> getCurrentCoupon() async {
    final data = await _request(
      request: () => http.get(_uri('/current/coupon')),
      successCodes: {200},
    );
    return MonthlyChallengeCouponResult.fromJson(data);
  }

  Future<List<MonthlyChallengeCatalogItem>> getCatalog({String? category}) async {
    final data = await _request(
      request: () => http.get(
        _uri('/catalog', {if (category != null) 'category': category}),
      ),
      successCodes: {200},
    );
    final items = data['items'];
    return items is List
        ? items
              .whereType<Map>()
              .map((item) => MonthlyChallengeCatalogItem.fromJson(
                    Map<String, dynamic>.from(item),
                  ))
              .toList()
        : const [];
  }

  Future<MonthlyChallengeCatalogItem> getRandomSuggestion({String? category}) async {
    final data = await _request(
      request: () => http.get(
        _uri('/catalog/random', {if (category != null) 'category': category}),
      ),
      successCodes: {200},
    );
    return MonthlyChallengeCatalogItem.fromJson(data);
  }

  Future<List<MonthlyChallengeFavorite>> getFavorites() async {
    final data = await _request(
      request: () => http.get(_uri('/favorites')),
      successCodes: {200},
    );
    final items = data['items'];
    return items is List
        ? items
              .whereType<Map>()
              .map((item) => MonthlyChallengeFavorite.fromJson(
                    Map<String, dynamic>.from(item),
                  ))
              .toList()
        : const [];
  }

  Future<void> addFavorite(MonthlyChallengeContent content) async {
    await _request(
      request: () => http.post(
        _uri('/favorites'),
        headers: const {'Content-Type': 'application/json; charset=UTF-8'},
        body: jsonEncode(_contentBody(content)),
      ),
      successCodes: {200, 201},
    );
  }

  Future<void> removeFavorite(String favoriteId) async {
    await _request(
      request: () => http.delete(
        _uri('/favorites/${Uri.encodeComponent(favoriteId)}'),
      ),
      successCodes: {200, 204},
    );
  }

  Future<MonthlyChallengeState> _mutateState(
    String ignoredPath,
    Future<http.Response> Function() request,
    Set<int> successCodes,
  ) async {
    final data = await _request(request: request, successCodes: successCodes);
    return MonthlyChallengeState.fromJson(data);
  }

  Map<String, dynamic> _contentBody(MonthlyChallengeContent content) =>
      content.source == 'catalog' && content.catalogChallengeId != null
      ? {
          'source': 'catalog',
          'catalogChallengeId': content.catalogChallengeId,
        }
      : {
          'source': 'custom',
          'title': content.title,
          'description': content.description,
          'category': content.category,
        };
}