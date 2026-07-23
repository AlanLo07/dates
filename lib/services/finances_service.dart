// lib/services/finances_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/finances.dart';
import 'api_config.dart';

class FinancesService {
  static final FinancesService _instance = FinancesService._internal();
  factory FinancesService() => _instance;
  FinancesService._internal();

  // Cache
  CoupleData? _coupleCache;
  List<Expense>? _expensesCache;
  Map<String, FinancialHistory>? _historyCache;
  DateTime? _cacheTimestamp;
  static const Duration _cacheTtl = Duration(minutes: 5);

  bool get _isCacheValid =>
      _cacheTimestamp != null &&
      DateTime.now().difference(_cacheTimestamp!) < _cacheTtl;

  void invalidateCache() {
    _coupleCache = null;
    _expensesCache = null;
    _historyCache = null;
    _cacheTimestamp = null;
  }

  final String _baseUrl = ApiConfig.baseUrl + ApiConfig.financesPath;

  // ───────────────────────────────────────────────────────────────────────────
  // 1. INICIALIZACIÓN
  // ───────────────────────────────────────────────────────────────────────────

  /// Inicializa la pareja (debe llamarse una sola vez)
  Future<CoupleData> initializeCouple({
    required String user1Email,
    required String user2Email,
    required String user1Name,
    required String user2Name,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('$_baseUrl/init'),
            headers: {'Content-Type': 'application/json; charset=UTF-8'},
            body: jsonEncode({
              'user1Email': user1Email,
              'user2Email': user2Email,
              'user1Name': user1Name,
              'user2Name': user2Name,
            }),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = CoupleData.fromJson(
          Map<String, dynamic>.from(jsonDecode(response.body)),
        );
        _coupleCache = data;
        invalidateCache();
        return data;
      } else {
        throw Exception(
          'Error al inicializar pareja: ${response.statusCode} — ${response.body}',
        );
      }
    } catch (e) {
      throw Exception('Error al conectar: $e');
    }
  }

  // ───────────────────────────────────────────────────────────────────────────
  // 2. DATOS DE LA PAREJA
  // ───────────────────────────────────────────────────────────────────────────

  /// Obtiene datos de la pareja
  Future<CoupleData> getCouple({bool forceRefresh = false}) async {
    if (!forceRefresh && _isCacheValid && _coupleCache != null) {
      return _coupleCache!;
    }

    try {
      final response = await http
          .get(Uri.parse(_baseUrl))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = CoupleData.fromJson(
          Map<String, dynamic>.from(jsonDecode(response.body)),
        );
        _coupleCache = data;
        _cacheTimestamp = DateTime.now();
        return data;
      } else if (response.statusCode == 404) {
        throw Exception('Pareja no inicializada. Use POST /finances/init');
      } else {
        throw Exception(
          'Error al obtener datos de pareja: ${response.statusCode}',
        );
      }
    } catch (e) {
      if (_coupleCache != null) return _coupleCache!;
      throw Exception('Error al conectar: $e');
    }
  }

  // ───────────────────────────────────────────────────────────────────────────
  // 3. GASTOS (EXPENSES)
  // ───────────────────────────────────────────────────────────────────────────

  /// Lista todos los gastos (con filtros opcionales)
  Future<List<Expense>> getExpenses({
    String? month, // YYYY-MM
    String? category,
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh && _isCacheValid && _expensesCache != null) {
      return _filterExpenses(_expensesCache!, month, category);
    }

    try {
      final queryParams = <String, String>{};
      if (month != null) queryParams['month'] = month;
      if (category != null) queryParams['category'] = category;

      final uri = Uri.parse('$_baseUrl/gastos').replace(queryParameters: queryParams);
      final response = await http.get(uri).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final List<dynamic> items =
            (decoded is Map && decoded['expenses'] is List)
                ? decoded['expenses']
                : (decoded is List ? decoded : []);

        final expenses =
            items.map((item) => Expense.fromJson(Map<String, dynamic>.from(item))).toList();
        _expensesCache = expenses;
        _cacheTimestamp = DateTime.now();
        return expenses;
      } else {
        throw Exception('Error al obtener gastos: ${response.statusCode}');
      }
    } catch (e) {
      if (_expensesCache != null) {
        return _filterExpenses(_expensesCache!, month, category);
      }
      throw Exception('Error al conectar: $e');
    }
  }

  /// Obtiene un gasto específico
  Future<Expense> getExpense(String gastoId) async {
    try {
      final response = await http
          .get(Uri.parse('$_baseUrl/gastos/$gastoId'))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return Expense.fromJson(
          Map<String, dynamic>.from(jsonDecode(response.body)),
        );
      } else if (response.statusCode == 404) {
        throw Exception('Gasto no encontrado');
      } else {
        throw Exception('Error al obtener gasto: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error al conectar: $e');
    }
  }

  /// Crea un nuevo gasto
  Future<Expense> createExpense({
    required String title,
    required double amount,
    required DateTime date,
    required ExpenseCategory category,
    required String createdBy,
    String? note,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('$_baseUrl/gastos'),
            headers: {'Content-Type': 'application/json; charset=UTF-8'},
            body: jsonEncode({
              'title': title,
              'amount': amount,
              'date': date.toIso8601String(),
              'category': category.name,
              'createdBy': createdBy,
              if (note != null) 'note': note,
            }),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 201 || response.statusCode == 200) {
        invalidateCache();
        return Expense.fromJson(
          Map<String, dynamic>.from(jsonDecode(response.body)),
        );
      } else {
        throw Exception(
          'Error al crear gasto: ${response.statusCode} — ${response.body}',
        );
      }
    } catch (e) {
      throw Exception('Error al conectar: $e');
    }
  }

  /// Actualiza un gasto
  Future<Expense> updateExpense(
    String gastoId, {
    String? title,
    double? amount,
    String? note,
  }) async {
    try {
      final body = <String, dynamic>{};
      if (title != null) body['title'] = title;
      if (amount != null) body['amount'] = amount;
      if (note != null) body['note'] = note;

      final response = await http
          .put(
            Uri.parse('$_baseUrl/gastos/$gastoId'),
            headers: {'Content-Type': 'application/json; charset=UTF-8'},
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        invalidateCache();
        return Expense.fromJson(
          Map<String, dynamic>.from(jsonDecode(response.body)),
        );
      } else if (response.statusCode == 404) {
        throw Exception('Gasto no encontrado');
      } else {
        throw Exception(
          'Error al actualizar gasto: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Error al conectar: $e');
    }
  }

  /// Elimina un gasto
  Future<void> deleteExpense(String gastoId) async {
    try {
      final response = await http
          .delete(Uri.parse('$_baseUrl/gastos/$gastoId'))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        invalidateCache();
      } else if (response.statusCode == 404) {
        throw Exception('Gasto no encontrado');
      } else {
        throw Exception('Error al eliminar gasto: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error al conectar: $e');
    }
  }

  // ───────────────────────────────────────────────────────────────────────────
  // 4. PRESUPUESTOS
  // ───────────────────────────────────────────────────────────────────────────

  /// Establece/actualiza presupuesto para un mes
  Future<Budget> setBudget(
    String monthYear, {
    required double amount,
    String? notes,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('$_baseUrl/presupuesto/$monthYear'),
            headers: {'Content-Type': 'application/json; charset=UTF-8'},
            body: jsonEncode({
              'amount': amount,
              if (notes != null) 'notes': notes,
            }),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200 || response.statusCode == 201) {
        invalidateCache();
        return Budget.fromJson(
          Map<String, dynamic>.from(jsonDecode(response.body)),
        );
      } else {
        throw Exception(
          'Error al establecer presupuesto: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Error al conectar: $e');
    }
  }

  /// Obtiene presupuesto de un mes
  Future<Budget> getBudget(String monthYear) async {
    try {
      final response = await http
          .get(Uri.parse('$_baseUrl/presupuesto/$monthYear'))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return Budget.fromJson(
          Map<String, dynamic>.from(jsonDecode(response.body)),
        );
      } else if (response.statusCode == 404) {
        throw Exception('Presupuesto no encontrado para este mes');
      } else {
        throw Exception('Error al obtener presupuesto: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error al conectar: $e');
    }
  }

  // ───────────────────────────────────────────────────────────────────────────
  // 5. HISTÓRICOS
  // ───────────────────────────────────────────────────────────────────────────

  /// Obtiene histórico de un mes específico
  Future<FinancialHistory> getMonthHistory(String monthYear) async {
    try {
      final response = await http
          .get(Uri.parse('$_baseUrl/historico/$monthYear'))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return FinancialHistory.fromJson(
          Map<String, dynamic>.from(jsonDecode(response.body)),
        );
      } else if (response.statusCode == 404) {
        throw Exception('Histórico no encontrado para este mes');
      } else {
        throw Exception('Error al obtener histórico: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error al conectar: $e');
    }
  }

  /// Obtiene históricos de últimos N meses
  Future<List<FinancialHistory>> getHistory({int limit = 12}) async {
    try {
      final uri = Uri.parse('$_baseUrl/historico')
          .replace(queryParameters: {'limit': limit.toString()});
      final response = await http.get(uri).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final List<dynamic> items =
            (decoded is Map && decoded['history'] is List)
                ? decoded['history']
                : (decoded is List ? decoded : []);

        return items
            .map((item) =>
                FinancialHistory.fromJson(Map<String, dynamic>.from(item)))
            .toList();
      } else {
        throw Exception('Error al obtener históricos: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error al conectar: $e');
    }
  }

  // ───────────────────────────────────────────────────────────────────────────
  // HELPERS
  // ───────────────────────────────────────────────────────────────────────────

  List<Expense> _filterExpenses(
    List<Expense> expenses,
    String? month,
    String? category,
  ) {
    var filtered = expenses;

    if (month != null) {
      filtered = filtered.where((e) => e.monthYear == month).toList();
    }

    if (category != null) {
      final cat = ExpenseCategory.fromString(category);
      filtered = filtered.where((e) => e.category == cat).toList();
    }

    return filtered;
  }
}
