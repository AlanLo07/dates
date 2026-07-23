// lib/models/finances.dart

enum ExpenseCategory {
  subscriptions,
  groceries,
  transport,
  dateNights,
  home,
  health,
  vacations,
  gifts,
  pets,
  hobbies,
  savings,
  others;

  String get display {
    const labels = {
      'subscriptions': 'Suscripciones',
      'groceries': 'Supermercado',
      'transport': 'Transporte',
      'dateNights': 'Citas y salidas',
      'home': 'Casa',
      'health': 'Salud y bienestar',
      'vacations': 'Vacaciones',
      'gifts': 'Regalos',
      'pets': 'Mascotas',
      'hobbies': 'Gustos personales',
      'savings': 'Ahorro',
      'others': 'Otros',
    };
    return labels[name] ?? name;
  }

  String get emoji {
    const emojis = {
      'subscriptions': '🎬',
      'groceries': '🛒',
      'transport': '🚗',
      'dateNights': '🍷',
      'home': '🏠',
      'health': '🧘',
      'vacations': '✈️',
      'gifts': '🎁',
      'pets': '🐾',
      'hobbies': '❤️',
      'savings': '🏦',
      'others': '📋',
    };
    return emojis[name] ?? '';
  }

  int get colorValue {
    const colors = {
      'subscriptions': 0xFF6A88D6,
      'groceries': 0xFF4CAF50,
      'transport': 0xFF42A5F5,
      'dateNights': 0xFFE57373,
      'home': 0xFF8D6E63,
      'health': 0xFF26A69A,
      'vacations': 0xFFFF8A65,
      'gifts': 0xFFAB47BC,
      'pets': 0xFF8D6E63,
      'hobbies': 0xFFE91E63,
      'savings': 0xFF5C6BC0,
      'others': 0xFF8D6E63,
    };
    return colors[name] ?? 0xFF8D6E63;
  }

  static ExpenseCategory fromString(String value) {
    try {
      return ExpenseCategory.values.firstWhere((e) => e.name == value);
    } catch (_) {
      return ExpenseCategory.others;
    }
  }
}

class Expense {
  final String gastoId;
  final String title;
  final double amount;
  final DateTime date;
  final ExpenseCategory category;
  final String monthYear; // YYYY-MM
  final String? note;
  final String createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Expense({
    required this.gastoId,
    required this.title,
    required this.amount,
    required this.date,
    required this.category,
    required this.monthYear,
    this.note,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Expense.fromJson(Map<String, dynamic> json) {
    return Expense(
      gastoId: (json['gastoId'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      amount: (json['amount'] is num) ? (json['amount'] as num).toDouble() : 0.0,
      date: json['date'] is String
          ? DateTime.parse(json['date'])
          : DateTime.now(),
      category: ExpenseCategory.fromString(json['category']?.toString() ?? ''),
      monthYear: (json['monthYear'] ?? '').toString(),
      note: json['note']?.toString(),
      createdBy: (json['createdBy'] ?? '').toString(),
      createdAt: json['createdAt'] is String
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      updatedAt: json['updatedAt'] is String
          ? DateTime.parse(json['updatedAt'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
    'gastoId': gastoId,
    'title': title,
    'amount': amount,
    'date': date.toIso8601String(),
    'category': category.name,
    'monthYear': monthYear,
    'note': note,
    'createdBy': createdBy,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  Expense copyWith({
    String? gastoId,
    String? title,
    double? amount,
    DateTime? date,
    ExpenseCategory? category,
    String? monthYear,
    String? note,
    String? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Expense(
      gastoId: gastoId ?? this.gastoId,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      category: category ?? this.category,
      monthYear: monthYear ?? this.monthYear,
      note: note ?? this.note,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class Budget {
  final String monthYear; // YYYY-MM
  final double amount;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Budget({
    required this.monthYear,
    required this.amount,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Budget.fromJson(Map<String, dynamic> json) {
    return Budget(
      monthYear: (json['monthYear'] ?? '').toString(),
      amount: (json['amount'] is num) ? (json['amount'] as num).toDouble() : 0.0,
      notes: json['notes']?.toString(),
      createdAt: json['createdAt'] is String
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      updatedAt: json['updatedAt'] is String
          ? DateTime.parse(json['updatedAt'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
    'monthYear': monthYear,
    'amount': amount,
    'notes': notes,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };
}

class FinancialHistory {
  final String monthYear; // YYYY-MM
  final double totalSpent;
  final double budgetAmount;
  final Map<String, double> byCategory;
  final int expenseCount;
  final bool overBudget;
  final double difference;
  final DateTime calculatedAt;

  const FinancialHistory({
    required this.monthYear,
    required this.totalSpent,
    required this.budgetAmount,
    required this.byCategory,
    required this.expenseCount,
    required this.overBudget,
    required this.difference,
    required this.calculatedAt,
  });

  factory FinancialHistory.fromJson(Map<String, dynamic> json) {
    final byCategory = <String, double>{};
    if (json['byCategory'] is Map) {
      (json['byCategory'] as Map).forEach((key, value) {
        byCategory[key.toString()] =
            (value is num) ? (value as num).toDouble() : 0.0;
      });
    }

    return FinancialHistory(
      monthYear: (json['monthYear'] ?? '').toString(),
      totalSpent: (json['totalSpent'] is num)
          ? (json['totalSpent'] as num).toDouble()
          : 0.0,
      budgetAmount: (json['budgetAmount'] is num)
          ? (json['budgetAmount'] as num).toDouble()
          : 0.0,
      byCategory: byCategory,
      expenseCount: (json['expenseCount'] is int) ? json['expenseCount'] : 0,
      overBudget: json['overBudget'] == true,
      difference:
          (json['difference'] is num) ? (json['difference'] as num).toDouble() : 0.0,
      calculatedAt: json['calculatedAt'] is String
          ? DateTime.parse(json['calculatedAt'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
    'monthYear': monthYear,
    'totalSpent': totalSpent,
    'budgetAmount': budgetAmount,
    'byCategory': byCategory,
    'expenseCount': expenseCount,
    'overBudget': overBudget,
    'difference': difference,
    'calculatedAt': calculatedAt.toIso8601String(),
  };
}

class User {
  final String email;
  final String name;

  const User({required this.email, required this.name});

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      email: (json['email'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toJson() => {
    'email': email,
    'name': name,
  };
}

class CoupleData {
  final User user1;
  final User user2;
  final double monthlyBudget;
  final String currency;
  final String locale;
  final DateTime createdAt;
  final DateTime updatedAt;

  const CoupleData({
    required this.user1,
    required this.user2,
    this.monthlyBudget = 0.0,
    this.currency = '\$',
    this.locale = 'es_ES',
    required this.createdAt,
    required this.updatedAt,
  });

  factory CoupleData.fromJson(Map<String, dynamic> json) {
    return CoupleData(
      user1: json['user1'] is Map
          ? User.fromJson(Map<String, dynamic>.from(json['user1']))
          : const User(email: '', name: ''),
      user2: json['user2'] is Map
          ? User.fromJson(Map<String, dynamic>.from(json['user2']))
          : const User(email: '', name: ''),
      monthlyBudget: (json['monthlyBudget'] is num)
          ? (json['monthlyBudget'] as num).toDouble()
          : 0.0,
      currency: (json['currency'] ?? '\$').toString(),
      locale: (json['locale'] ?? 'es_ES').toString(),
      createdAt: json['createdAt'] is String
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      updatedAt: json['updatedAt'] is String
          ? DateTime.parse(json['updatedAt'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
    'user1': user1.toJson(),
    'user2': user2.toJson(),
    'monthlyBudget': monthlyBudget,
    'currency': currency,
    'locale': locale,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };
}
