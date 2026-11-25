import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'authenticated_http_client.dart' as http_client;
import 'api_config.dart';
import '../models/weekly_question.dart';

class WeeklyQuestionsService {
  WeeklyQuestionsService._();

  static final WeeklyQuestionsService instance = WeeklyQuestionsService._();

  final String _basePath = 'weekly-questions';

  String get _baseUrl {
    return '${ApiConfig.baseUrl}$_basePath';
  }

  /// Obtiene la pregunta de la semana actual
  /// Si es el primer acceso de la semana, selecciona y persiste una pregunta
  Future<WeeklyQuestionsResponse> getCurrentQuestion() async {
    try {
      final uri = Uri.parse('$_baseUrl/current');
      debugPrint('📝 [WeeklyQuestionsService] GET $_baseUrl/current');

      final response = await http_client.get(uri);

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        return WeeklyQuestionsResponse.fromJson(json);
      } else {
        throw _handleError(response);
      }
    } catch (e) {
      debugPrint('❌ [WeeklyQuestionsService] getCurrentQuestion error: $e');
      rethrow;
    }
  }

  /// Crea una nueva pregunta en el catálogo
  Future<CatalogQuestion> createCatalogQuestion({
    required String text,
    required String category,
  }) async {
    try {
      final uri = Uri.parse('$_baseUrl/catalog');
      final body = jsonEncode({
        'text': text.trim(),
        'category': category.trim(),
      });

      debugPrint('📝 [WeeklyQuestionsService] POST $_baseUrl/catalog');
      debugPrint('   Payload: text="${text.trim()}", category="$category"');

      final response = await http_client.post(
        uri,
        body: body,
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 201) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        return CatalogQuestion.fromJson(json);
      } else {
        throw _handleError(response);
      }
    } catch (e) {
      debugPrint('❌ [WeeklyQuestionsService] createCatalogQuestion error: $e');
      rethrow;
    }
  }

  /// Obtiene el catálogo de preguntas
  /// Parámetros opcionales: category, limit (1-100, default 20), nextToken
  Future<PaginatedResponse<CatalogQuestion>> getCatalog({
    String? category,
    int limit = 20,
    String? nextToken,
  }) async {
    try {
      final queryParams = <String, String>{};
      if (category != null && category.isNotEmpty) {
        queryParams['category'] = category;
      }
      queryParams['limit'] = limit.toString();
      if (nextToken != null && nextToken.isNotEmpty) {
        queryParams['nextToken'] = nextToken;
      }

      final uri = Uri.parse(
        '$_baseUrl/catalog',
      ).replace(queryParameters: queryParams);
      debugPrint(
        '📝 [WeeklyQuestionsService] GET $_baseUrl/catalog $queryParams',
      );

      final response = await http_client.get(uri);

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        return PaginatedResponse.fromJson(
          json,
          (item) => CatalogQuestion.fromJson(item),
        );
      } else {
        throw _handleError(response);
      }
    } catch (e) {
      debugPrint('❌ [WeeklyQuestionsService] getCatalog error: $e');
      rethrow;
    }
  }

  /// Obtiene una pregunta específica del catálogo
  Future<CatalogQuestion> getCatalogQuestion(String id) async {
    try {
      final uri = Uri.parse('$_baseUrl/catalog/$id');
      debugPrint('📝 [WeeklyQuestionsService] GET $_baseUrl/catalog/$id');

      final response = await http_client.get(uri);

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        return CatalogQuestion.fromJson(json);
      } else {
        throw _handleError(response);
      }
    } catch (e) {
      debugPrint('❌ [WeeklyQuestionsService] getCatalogQuestion error: $e');
      rethrow;
    }
  }

  /// Edita una pregunta del catálogo
  /// Requiere el texto, categoría y versión actual del catálogo
  Future<CatalogQuestion> updateCatalogQuestion({
    required String id,
    required String text,
    required String category,
    required int version,
  }) async {
    try {
      final uri = Uri.parse('$_baseUrl/catalog/$id');
      final body = jsonEncode({
        'text': text.trim(),
        'category': category.trim(),
        'version': version,
      });

      debugPrint('📝 [WeeklyQuestionsService] PUT $_baseUrl/catalog/$id');
      debugPrint(
        '   Payload: text="${text.trim()}", category="$category", version=$version',
      );

      final response = await http_client.put(
        uri,
        body: body,
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        return CatalogQuestion.fromJson(json);
      } else {
        throw _handleError(response);
      }
    } catch (e) {
      debugPrint('❌ [WeeklyQuestionsService] updateCatalogQuestion error: $e');
      rethrow;
    }
  }

  /// Obtiene todas las preguntas con su progreso
  /// Parámetros opcionales: status, pendingFor, category, limit, nextToken
  /// Status: unseen, pending, partial, completed
  /// pendingFor: me, partner
  Future<PaginatedResponse<WeeklyQuestion>> getQuestions({
    String? status,
    String? pendingFor,
    String? category,
    int limit = 20,
    String? nextToken,
  }) async {
    try {
      final queryParams = <String, String>{};
      if (status != null && status.isNotEmpty) {
        queryParams['status'] = status;
      }
      if (pendingFor != null && pendingFor.isNotEmpty) {
        queryParams['pendingFor'] = pendingFor;
      }
      if (category != null && category.isNotEmpty) {
        queryParams['category'] = category;
      }
      queryParams['limit'] = limit.toString();
      if (nextToken != null && nextToken.isNotEmpty) {
        queryParams['nextToken'] = nextToken;
      }

      final uri = Uri.parse(_baseUrl).replace(queryParameters: queryParams);
      debugPrint('📝 [WeeklyQuestionsService] GET $_baseUrl $queryParams');

      final response = await http_client.get(uri);

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        return PaginatedResponse.fromJson(
          json,
          (item) => WeeklyQuestion.fromJson(item),
        );
      } else {
        throw _handleError(response);
      }
    } catch (e) {
      debugPrint('❌ [WeeklyQuestionsService] getQuestions error: $e');
      rethrow;
    }
  }

  /// Obtiene una pregunta específica con su progreso y respuestas
  Future<WeeklyQuestion> getQuestion(String id) async {
    try {
      final uri = Uri.parse('$_baseUrl/$id');
      debugPrint('📝 [WeeklyQuestionsService] GET $_baseUrl/$id');

      final response = await http_client.get(uri);

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        return WeeklyQuestion.fromJson(json);
      } else {
        throw _handleError(response);
      }
    } catch (e) {
      debugPrint('❌ [WeeklyQuestionsService] getQuestion error: $e');
      rethrow;
    }
  }

  /// Crea o edita la respuesta propia a una pregunta
  /// Retorna 201 si es nueva, 200 si es edición
  Future<WeeklyQuestion> submitAnswer({
    required String questionId,
    required String text,
  }) async {
    try {
      final uri = Uri.parse('$_baseUrl/$questionId/answer');
      final body = jsonEncode({'text': text.trim()});

      debugPrint(
        '📝 [WeeklyQuestionsService] PUT $_baseUrl/$questionId/answer',
      );
      debugPrint('   Payload: text="${text.trim()}"');

      final response = await http_client.put(
        uri,
        body: body,
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        return WeeklyQuestion.fromJson(json);
      } else {
        throw _handleError(response);
      }
    } catch (e) {
      debugPrint('❌ [WeeklyQuestionsService] submitAnswer error: $e');
      rethrow;
    }
  }

  /// Maneja errores HTTP
  Exception _handleError(http_client.Response response) {
    try {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final error = json['error'] as String? ?? 'Error desconocido';
      return ApiException(message: error, statusCode: response.statusCode);
    } catch (_) {
      return ApiException(
        message: response.reasonPhrase ?? 'Error desconocido',
        statusCode: response.statusCode,
      );
    }
  }
}

class ApiException implements Exception {
  final String message;
  final int statusCode;

  ApiException({required this.message, required this.statusCode});

  @override
  String toString() => 'ApiException($statusCode): $message';

  bool get isUnauthorized => statusCode == 401;
  bool get isForbidden => statusCode == 403;
  bool get isNotFound => statusCode == 404;
  bool get isConflict => statusCode == 409;
}
