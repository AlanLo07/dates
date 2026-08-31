// lib/services/checklists_service.dart
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'authenticated_http_client.dart' as http;

import '../models/checklist.dart';
import 'api_config.dart';

class ChecklistApiException implements Exception {
  ChecklistApiException(this.message, this.statusCode);

  final String message;
  final int statusCode;

  @override
  String toString() => 'ChecklistApiException($statusCode): $message';
}

class ChecklistsService {
  final String _baseUrl = ApiConfig.baseUrl + ApiConfig.checklistsPath;
  final http.Client _client = http.Client();

  static const Map<String, String> _headers = {
    'Content-Type': 'application/json',
  };

  Uri _uri(String path) => Uri.parse('$_baseUrl$path');

  Map<String, dynamic> _decode(http.Response response) {
    final dynamic decoded = response.body.isEmpty ? {} : jsonDecode(response.body);
    final data = Map<String, dynamic>.from(decoded as Map);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ChecklistApiException(
        data['error']?.toString() ?? 'Error en Checklists API',
        response.statusCode,
      );
    }
    return data;
  }

  // ── Tableros ───────────────────────────────────────────────────────────
  Future<void> seedDefaults() async {
    debugPrint('🔵 [ChecklistsService] seedDefaults: POST iniciado');
    final response = await _client.post(
      _uri('/seed-defaults'),
      headers: _headers,
    );
    debugPrint('⚪️ [ChecklistsService] seedDefaults: respuesta HTTP ${response.statusCode}');
    _decode(response);
    debugPrint('🟢 [ChecklistsService] seedDefaults: completado');
  }

  Future<List<ChecklistBoard>> getChecklists() async {
    debugPrint('🔵 [ChecklistsService] getChecklists: GET iniciado');
    final response = await _client.get(_uri(''), headers: _headers);
    debugPrint('⚪️ [ChecklistsService] getChecklists: respuesta HTTP ${response.statusCode}');
    final data = _decode(response);
    final boards = (data['items'] as List<dynamic>? ?? [])
        .map((item) => ChecklistBoard.fromJson(Map<String, dynamic>.from(item as Map)))
        .toList();
    debugPrint('🟢 [ChecklistsService] getChecklists: parseados ${boards.length} tableros');
    return boards;
  }

  Future<ChecklistBoard> getChecklist(String checklistId) async {
    debugPrint('🔵 [ChecklistsService] getChecklist: GET iniciado ($checklistId)');
    final response = await _client.get(
      _uri('/$checklistId'),
      headers: _headers,
    );
    debugPrint('⚪️ [ChecklistsService] getChecklist: respuesta HTTP ${response.statusCode}');
    final data = _decode(response);
    final board = Map<String, dynamic>.from(data['checklist'] as Map);
    board['grupos'] = data['grupos'];
    board['items'] = data['items'];
    debugPrint('🟢 [ChecklistsService] getChecklist: completado');
    return ChecklistBoard.fromJson(board);
  }

  Future<String> createChecklist({
    required String titulo,
    ChecklistKind kind = ChecklistKind.personalizado,
    String? emoji,
    int? colorValue,
    bool? usaGrupos,
    List<ChecklistGroup>? grupos,
  }) async {
    debugPrint('🔵 [ChecklistsService] createChecklist: POST iniciado');
    final response = await _client.post(
      _uri(''),
      headers: _headers,
      body: jsonEncode({
        'titulo': titulo,
        'kind': kind.name,
        if (emoji != null) 'emoji': emoji,
        if (colorValue != null) 'colorValue': colorValue,
        if (usaGrupos != null) 'usaGrupos': usaGrupos,
        if (grupos != null) 'grupos': grupos.map((g) => g.toJson()).toList(),
      }),
    );
    debugPrint('⚪️ [ChecklistsService] createChecklist: respuesta HTTP ${response.statusCode}');
    final data = _decode(response);
    debugPrint('🟢 [ChecklistsService] createChecklist: completado');
    return data['checklistId'].toString();
  }

  Future<void> updateChecklist(
    String checklistId,
    Map<String, dynamic> patch,
  ) async {
    debugPrint('🔵 [ChecklistsService] updateChecklist: PUT iniciado ($checklistId)');
    final response = await _client.put(
      _uri('/$checklistId'),
      headers: _headers,
      body: jsonEncode(patch),
    );
    debugPrint('⚪️ [ChecklistsService] updateChecklist: respuesta HTTP ${response.statusCode}');
    _decode(response);
    debugPrint('🟢 [ChecklistsService] updateChecklist: completado');
  }

  Future<void> deleteChecklist(String checklistId) async {
    debugPrint('🔵 [ChecklistsService] deleteChecklist: DELETE iniciado ($checklistId)');
    final response = await _client.delete(
      _uri('/$checklistId'),
      headers: _headers,
    );
    debugPrint('⚪️ [ChecklistsService] deleteChecklist: respuesta HTTP ${response.statusCode}');
    _decode(response);
    debugPrint('🟢 [ChecklistsService] deleteChecklist: completado');
  }

  Future<void> resetChecklist(String checklistId) async {
    debugPrint('🔵 [ChecklistsService] resetChecklist: PATCH iniciado ($checklistId)');
    final response = await _client.patch(
      _uri('/$checklistId/reset'),
      headers: _headers,
    );
    debugPrint('⚪️ [ChecklistsService] resetChecklist: respuesta HTTP ${response.statusCode}');
    _decode(response);
    debugPrint('🟢 [ChecklistsService] resetChecklist: completado');
  }

  // ── Grupos ─────────────────────────────────────────────────────────────
  Future<String> createGroup(String checklistId, ChecklistGroup group) async {
    debugPrint('🔵 [ChecklistsService] createGroup: POST iniciado ($checklistId)');
    final response = await _client.post(
      _uri('/$checklistId/grupos'),
      headers: _headers,
      body: jsonEncode(group.toJson()),
    );
    debugPrint('⚪️ [ChecklistsService] createGroup: respuesta HTTP ${response.statusCode}');
    final data = _decode(response);
    debugPrint('🟢 [ChecklistsService] createGroup: completado');
    return data['id'].toString();
  }

  Future<void> updateGroup(
    String checklistId,
    String groupId,
    Map<String, dynamic> patch,
  ) async {
    debugPrint('🔵 [ChecklistsService] updateGroup: PUT iniciado ($groupId)');
    final response = await _client.put(
      _uri('/$checklistId/grupos/$groupId'),
      headers: _headers,
      body: jsonEncode(patch),
    );
    debugPrint('⚪️ [ChecklistsService] updateGroup: respuesta HTTP ${response.statusCode}');
    _decode(response);
    debugPrint('🟢 [ChecklistsService] updateGroup: completado');
  }

  Future<void> deleteGroup(String checklistId, String groupId) async {
    debugPrint('🔵 [ChecklistsService] deleteGroup: DELETE iniciado ($groupId)');
    final response = await _client.delete(
      _uri('/$checklistId/grupos/$groupId'),
      headers: _headers,
    );
    debugPrint('⚪️ [ChecklistsService] deleteGroup: respuesta HTTP ${response.statusCode}');
    _decode(response);
    debugPrint('🟢 [ChecklistsService] deleteGroup: completado');
  }

  // ── Items ──────────────────────────────────────────────────────────────
  Future<String> createItem(String checklistId, ChecklistItem item) async {
    debugPrint('🔵 [ChecklistsService] createItem: POST iniciado ($checklistId)');
    final response = await _client.post(
      _uri('/$checklistId/items'),
      headers: _headers,
      body: jsonEncode(item.toJson()),
    );
    debugPrint('⚪️ [ChecklistsService] createItem: respuesta HTTP ${response.statusCode}');
    final data = _decode(response);
    debugPrint('🟢 [ChecklistsService] createItem: completado');
    return data['id'].toString();
  }

  Future<void> updateItem(
    String checklistId,
    String itemId,
    Map<String, dynamic> patch,
  ) async {
    debugPrint('🔵 [ChecklistsService] updateItem: PUT iniciado ($itemId)');
    final response = await _client.put(
      _uri('/$checklistId/items/$itemId'),
      headers: _headers,
      body: jsonEncode(patch),
    );
    debugPrint('⚪️ [ChecklistsService] updateItem: respuesta HTTP ${response.statusCode}');
    _decode(response);
    debugPrint('🟢 [ChecklistsService] updateItem: completado');
  }

  Future<void> deleteItem(String checklistId, String itemId) async {
    debugPrint('🔵 [ChecklistsService] deleteItem: DELETE iniciado ($itemId)');
    final response = await _client.delete(
      _uri('/$checklistId/items/$itemId'),
      headers: _headers,
    );
    debugPrint('⚪️ [ChecklistsService] deleteItem: respuesta HTTP ${response.statusCode}');
    _decode(response);
    debugPrint('🟢 [ChecklistsService] deleteItem: completado');
  }

  Future<void> setComprado(
    String checklistId,
    String itemId,
    bool comprado,
  ) async {
    debugPrint('🔵 [ChecklistsService] setComprado: PATCH iniciado ($itemId, $comprado)');
    final response = await _client.patch(
      _uri('/$checklistId/items/$itemId/comprado'),
      headers: _headers,
      body: jsonEncode({'comprado': comprado}),
    );
    debugPrint('⚪️ [ChecklistsService] setComprado: respuesta HTTP ${response.statusCode}');
    _decode(response);
    debugPrint('🟢 [ChecklistsService] setComprado: completado');
  }

  void dispose() => _client.close();
}
