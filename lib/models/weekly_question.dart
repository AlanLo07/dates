import 'package:intl/intl.dart';

class WeeklyQuestion {
  final String id;
  final String text;
  final String category;
  final int catalogVersion;
  final bool presented;
  final bool locked;
  final bool isCurrent;
  final String status; // unseen, pending, partial, completed
  final bool canAnswer;
  final bool canEdit;
  final Map<String, Answer> answers; // sub -> Answer
  final DateTime? firstPresentedAt;
  final String? lastPresentedWeek;

  WeeklyQuestion({
    required this.id,
    required this.text,
    required this.category,
    required this.catalogVersion,
    required this.presented,
    required this.locked,
    required this.isCurrent,
    required this.status,
    required this.canAnswer,
    required this.canEdit,
    required this.answers,
    this.firstPresentedAt,
    this.lastPresentedWeek,
  });

  factory WeeklyQuestion.fromJson(Map<String, dynamic> json) {
    final answersJson = json['answers'] as Map<String, dynamic>? ?? {};
    final answers = <String, Answer>{};
    answersJson.forEach((key, value) {
      answers[key] = Answer.fromJson(value as Map<String, dynamic>);
    });

    return WeeklyQuestion(
      id: json['id'] as String,
      text: json['text'] as String,
      category: json['category'] as String,
      catalogVersion: json['catalogVersion'] as int,
      presented: json['presented'] as bool,
      locked: json['locked'] as bool,
      isCurrent: json['isCurrent'] as bool,
      status: json['status'] as String,
      canAnswer: json['canAnswer'] as bool,
      canEdit: json['canEdit'] as bool,
      answers: answers,
      firstPresentedAt: json['firstPresentedAt'] != null
          ? DateTime.parse(json['firstPresentedAt'] as String)
          : null,
      lastPresentedWeek: json['lastPresentedWeek'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'text': text,
    'category': category,
    'catalogVersion': catalogVersion,
    'presented': presented,
    'locked': locked,
    'isCurrent': isCurrent,
    'status': status,
    'canAnswer': canAnswer,
    'canEdit': canEdit,
    'answers': answers.map((k, v) => MapEntry(k, v.toJson())),
    'firstPresentedAt': firstPresentedAt?.toIso8601String(),
    'lastPresentedWeek': lastPresentedWeek,
  };

  WeeklyQuestion copyWith({
    String? id,
    String? text,
    String? category,
    int? catalogVersion,
    bool? presented,
    bool? locked,
    bool? isCurrent,
    String? status,
    bool? canAnswer,
    bool? canEdit,
    Map<String, Answer>? answers,
    DateTime? firstPresentedAt,
    String? lastPresentedWeek,
  }) {
    return WeeklyQuestion(
      id: id ?? this.id,
      text: text ?? this.text,
      category: category ?? this.category,
      catalogVersion: catalogVersion ?? this.catalogVersion,
      presented: presented ?? this.presented,
      locked: locked ?? this.locked,
      isCurrent: isCurrent ?? this.isCurrent,
      status: status ?? this.status,
      canAnswer: canAnswer ?? this.canAnswer,
      canEdit: canEdit ?? this.canEdit,
      answers: answers ?? this.answers,
      firstPresentedAt: firstPresentedAt ?? this.firstPresentedAt,
      lastPresentedWeek: lastPresentedWeek ?? this.lastPresentedWeek,
    );
  }
}

class Answer {
  final String text;
  final DateTime createdAt;
  final DateTime updatedAt;

  Answer({
    required this.text,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Answer.fromJson(Map<String, dynamic> json) {
    return Answer(
      text: json['text'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
    'text': text,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  bool isEdited() => createdAt != updatedAt;
}

class CatalogQuestion {
  final String id;
  final String text;
  final String category;
  final int version;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String createdBy;
  final String updatedBy;

  CatalogQuestion({
    required this.id,
    required this.text,
    required this.category,
    required this.version,
    required this.createdAt,
    required this.updatedAt,
    required this.createdBy,
    required this.updatedBy,
  });

  factory CatalogQuestion.fromJson(Map<String, dynamic> json) {
    return CatalogQuestion(
      id: json['id'] as String,
      text: json['text'] as String,
      category: json['category'] as String,
      version: json['version'] as int,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      createdBy: json['createdBy'] as String,
      updatedBy: json['updatedBy'] as String,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'text': text,
    'category': category,
    'version': version,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
    'createdBy': createdBy,
    'updatedBy': updatedBy,
  };
}

class WeeklyQuestionsResponse {
  final String weekKey;
  final DateTime weekStart;
  final DateTime weekEnd;
  final String timeZone;
  final List<User> users;
  final WeeklyQuestion? question;
  final String? message;

  WeeklyQuestionsResponse({
    required this.weekKey,
    required this.weekStart,
    required this.weekEnd,
    required this.timeZone,
    required this.users,
    this.question,
    this.message,
  });

  factory WeeklyQuestionsResponse.fromJson(Map<String, dynamic> json) {
    final usersJson = json['users'] as List<dynamic>? ?? [];
    final users = usersJson
        .map((u) => User.fromJson(u as Map<String, dynamic>))
        .toList();

    return WeeklyQuestionsResponse(
      weekKey: json['weekKey'] as String,
      weekStart: DateTime.parse(json['weekStart'] as String),
      weekEnd: DateTime.parse(json['weekEnd'] as String),
      timeZone: json['timeZone'] as String,
      users: users,
      question: json['question'] != null
          ? WeeklyQuestion.fromJson(json['question'] as Map<String, dynamic>)
          : null,
      message: json['message'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'weekKey': weekKey,
    'weekStart': weekStart.toIso8601String(),
    'weekEnd': weekEnd.toIso8601String(),
    'timeZone': timeZone,
    'users': users.map((u) => u.toJson()).toList(),
    'question': question?.toJson(),
    'message': message,
  };
}

class User {
  final String sub;
  final String name;

  User({
    required this.sub,
    required this.name,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      sub: json['sub'] as String,
      name: json['name'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'sub': sub,
    'name': name,
  };
}

class PaginatedResponse<T> {
  final List<T> items;
  final String? nextToken;

  PaginatedResponse({
    required this.items,
    this.nextToken,
  });

  factory PaginatedResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) fromJson,
  ) {
    final itemsJson = json['items'] as List<dynamic>? ?? [];
    final items = itemsJson
        .map((item) => fromJson(item as Map<String, dynamic>))
        .toList();

    return PaginatedResponse(
      items: items,
      nextToken: json['nextToken'] as String?,
    );
  }

  Map<String, dynamic> toJson(Map<String, dynamic> Function(T) toJson) => {
    'items': items.map((item) => toJson(item)).toList(),
    'nextToken': nextToken,
  };
}
