import 'dart:convert';
import 'dart:math';

import '../models/savings_goals.dart';
import 'api_config.dart';
import 'authenticated_http_client.dart' as http;

class SavingsGoalsApiException implements Exception {
  const SavingsGoalsApiException(this.message, this.statusCode);

  final String message;
  final int statusCode;

  @override
  String toString() => message;
}

class SavingsGoalsService {
  SavingsGoalsService();

  final String _financesUrl =
      '${ApiConfig.baseUrl.replaceFirst(RegExp(r'/$'), '')}${ApiConfig.financesPath}';

  Uri _uri(String path) => Uri.parse('$_financesUrl$path');

  Future<Map<String, dynamic>> _send({
    required Future<http.Response> Function() request,
    required Set<int> successCodes,
  }) async {
    final response = await request().timeout(const Duration(seconds: 12));
    final dynamic decoded = response.body.isEmpty
        ? <String, dynamic>{}
        : jsonDecode(response.body);
    if (!successCodes.contains(response.statusCode)) {
      final rawError = decoded is Map ? decoded['error'] : null;
      final message = rawError is List
          ? rawError.map((item) => item.toString()).join('\n')
          : (rawError ?? 'Error en metas de ahorro').toString();
      throw SavingsGoalsApiException(message, response.statusCode);
    }
    return decoded is Map ? Map<String, dynamic>.from(decoded) : {};
  }

  Future<SavingsBoard> getBoard() async {
    final data = await _send(
      request: () => http.get(_uri('/metas')),
      successCodes: {200},
    );
    return SavingsBoard.fromJson(_summaryOrRoot(data));
  }

  Future<SavingsGoalMutation> createGoal({
    required String name,
    required double targetAmount,
    int? priority,
    String? bodaId,
  }) async {
    final body = <String, dynamic>{
      'name': name,
      'targetAmount': targetAmount,
      if (priority != null) 'priority': priority,
      if (bodaId != null) 'bodaId': bodaId,
    };
    final data = await _send(
      request: () => http.post(
        _uri('/metas'),
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'Idempotency-Key': _newIdempotencyKey(),
        },
        body: jsonEncode(body),
      ),
      successCodes: {201},
    );
    return SavingsGoalMutation.fromJson(data);
  }

  Future<SavingsGoalMutation> updateGoal(
    String goalId, {
    String? name,
    double? targetAmount,
    String? bodaId,
    bool removeWeddingLink = false,
  }) async {
    final body = <String, dynamic>{};
    if (name != null) body['name'] = name;
    if (targetAmount != null) body['targetAmount'] = targetAmount;
    if (removeWeddingLink) body['bodaId'] = null;
    if (bodaId != null) body['bodaId'] = bodaId;
    final data = await _send(
      request: () => http.patch(
        _uri('/metas/${Uri.encodeComponent(goalId)}'),
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
        body: jsonEncode(body),
      ),
      successCodes: {200},
    );
    return SavingsGoalMutation.fromJson(data);
  }

  Future<SavingsBoard> reorderGoals(List<String> goalIds) async {
    final data = await _send(
      request: () => http.post(
        _uri('/metas/reordenar'),
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
        body: jsonEncode({'goalIds': goalIds}),
      ),
      successCodes: {200},
    );
    return SavingsBoard.fromJson(_summaryOrRoot(data));
  }

  Future<SavingsBoard> archiveGoal(String goalId) async {
    final data = await _send(
      request: () => http.delete(
        _uri('/metas/${Uri.encodeComponent(goalId)}'),
      ),
      successCodes: {200},
    );
    return SavingsBoard.fromJson(_summaryOrRoot(data));
  }

  Future<SavingsOperationResult> addContribution({
    required double amount,
    required DateTime date,
    String? note,
  }) async {
    final data = await _send(
      request: () => http.post(
        _uri('/ahorros/aportes'),
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'Idempotency-Key': _newIdempotencyKey(),
        },
        body: jsonEncode({
          'amount': amount,
          'date': date.toIso8601String(),
          if (note != null && note.isNotEmpty) 'note': note,
        }),
      ),
      successCodes: {201},
    );
    return SavingsOperationResult.fromJson(data);
  }

  Future<SavingsWithdrawalResult> withdraw({
    required double amount,
    required DateTime date,
    required String note,
  }) async {
    final data = await _send(
      request: () => http.post(
        _uri('/ahorros/retiros'),
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'Idempotency-Key': _newIdempotencyKey(),
        },
        body: jsonEncode({
          'amount': amount,
          'date': date.toIso8601String(),
          'note': note,
        }),
      ),
      successCodes: {201},
    );
    return SavingsWithdrawalResult.fromJson(data);
  }

  Future<SavingsMovementPage> getMovements({
    String? goalId,
    bool cushion = false,
    DateTime? from,
    DateTime? to,
    int limit = 25,
    String? cursor,
  }) async {
    final query = <String, String>{'limit': '$limit'};
    if (goalId != null) query['goalId'] = goalId;
    if (cushion) query['cushion'] = 'true';
    if (from != null) query['from'] = _dateOnly(from);
    if (to != null) query['to'] = _dateOnly(to);
    if (cursor != null) query['cursor'] = cursor;
    final data = await _send(
      request: () => http.get(
        _uri('/ahorros/historial').replace(queryParameters: query),
      ),
      successCodes: {200},
    );
    return SavingsMovementPage.fromJson(data);
  }

  String _dateOnly(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  Map<String, dynamic> _summaryOrRoot(Map<String, dynamic> data) =>
      data['summary'] is Map
          ? Map<String, dynamic>.from(data['summary'])
          : data;

  String _newIdempotencyKey() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    bytes[6] = (bytes[6] & 0x0f) | 0x40;
    bytes[8] = (bytes[8] & 0x3f) | 0x80;
    final hex = bytes
        .map((byte) => byte.toRadixString(16).padLeft(2, '0'))
        .join();
    return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20)}';
  }
}