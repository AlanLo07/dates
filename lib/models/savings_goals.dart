class SavingsGoal {
  const SavingsGoal({
    required this.goalId,
    required this.name,
    required this.targetAmount,
    required this.accumulatedAmount,
    required this.remainingAmount,
    required this.progressPercent,
    required this.priority,
    required this.status,
    this.bodaId,
    this.isLinkedToWeddingBudget = false,
  });

  final String goalId;
  final String name;
  final double targetAmount;
  final double accumulatedAmount;
  final double remainingAmount;
  final double progressPercent;
  final int priority;
  final String status;
  final String? bodaId;
  final bool isLinkedToWeddingBudget;

  bool get isCompleted => status == 'completed';
  bool get isArchived => status == 'archived';

  factory SavingsGoal.fromJson(Map<String, dynamic> json) {
    final target = _asDouble(json['targetAmount']);
    final accumulated = _asDouble(json['accumulatedAmount']);
    return SavingsGoal(
      goalId: (json['goalId'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      targetAmount: target,
      accumulatedAmount: accumulated,
      remainingAmount: _asDouble(
        json['remainingAmount'],
        fallback: target - accumulated,
      ),
      progressPercent: _asDouble(json['progressPercent']),
      priority: _asInt(json['priority']),
      status: (json['status'] ?? 'waiting').toString(),
      bodaId: json['bodaId']?.toString(),
      isLinkedToWeddingBudget: json['isLinkedToWeddingBudget'] == true,
    );
  }
}

class SavingsCushion {
  const SavingsCushion({
    required this.goalId,
    required this.name,
    required this.balance,
  });

  final String goalId;
  final String name;
  final double balance;

  factory SavingsCushion.fromJson(Map<String, dynamic> json) => SavingsCushion(
    goalId: (json['goalId'] ?? 'COLCHON').toString(),
    name: (json['name'] ?? 'Colchón').toString(),
    balance: _asDouble(json['balance']),
  );
}

class SavingsCascadeSegment {
  const SavingsCascadeSegment({
    required this.goalId,
    required this.name,
    required this.targetAmount,
    required this.accumulatedAmount,
  });

  final String goalId;
  final String name;
  final double targetAmount;
  final double accumulatedAmount;

  double get progress => targetAmount <= 0
      ? 0
      : (accumulatedAmount / targetAmount).clamp(0.0, 1.0);

  factory SavingsCascadeSegment.fromJson(Map<String, dynamic> json) =>
      SavingsCascadeSegment(
        goalId: (json['goalId'] ?? '').toString(),
        name: (json['name'] ?? '').toString(),
        targetAmount: _asDouble(json['targetAmount']),
        accumulatedAmount: _asDouble(json['accumulatedAmount']),
      );
}

class SavingsBoard {
  const SavingsBoard({
    required this.currency,
    required this.totalSaved,
    required this.activeGoal,
    required this.activeGoalRemainingAmount,
    required this.activeGoalMissingPercent,
    required this.waitingGoals,
    required this.completedGoals,
    required this.archivedGoals,
    required this.cushion,
    required this.cascade,
    required this.latestMovements,
    required this.configVersion,
  });

  final String currency;
  final double totalSaved;
  final SavingsGoal? activeGoal;
  final double activeGoalRemainingAmount;
  final double activeGoalMissingPercent;
  final List<SavingsGoal> waitingGoals;
  final List<SavingsGoal> completedGoals;
  final List<SavingsGoal> archivedGoals;
  final SavingsCushion cushion;
  final List<SavingsCascadeSegment> cascade;
  final List<SavingsMovement> latestMovements;
  final int configVersion;

  List<SavingsGoal> get pendingGoals => [
    if (activeGoal != null) activeGoal!,
    ...waitingGoals,
  ];

  factory SavingsBoard.fromJson(Map<String, dynamic> json) {
    final active = json['activeGoal'];
    final cushion = json['cushion'];
    final cascade = json['cascade'];
    return SavingsBoard(
      currency: (json['currency'] ?? 'COP').toString(),
      totalSaved: _asDouble(json['totalSaved']),
      activeGoal: active is Map
          ? SavingsGoal.fromJson(Map<String, dynamic>.from(active))
          : null,
      activeGoalRemainingAmount: _asDouble(json['activeGoalRemainingAmount']),
      activeGoalMissingPercent: _asDouble(json['activeGoalMissingPercent']),
      waitingGoals: _goalList(json['waitingGoals']),
      completedGoals: _goalList(json['completedGoals']),
      archivedGoals: _goalList(json['archivedGoals']),
      cushion: cushion is Map
          ? SavingsCushion.fromJson(Map<String, dynamic>.from(cushion))
          : const SavingsCushion(
              goalId: 'COLCHON',
              name: 'Colchón',
              balance: 0,
            ),
      cascade: cascade is Map && cascade['segments'] is List
          ? (cascade['segments'] as List)
                .whereType<Map>()
                .map(
                  (item) => SavingsCascadeSegment.fromJson(
                    Map<String, dynamic>.from(item),
                  ),
                )
                .toList()
          : const [],
      latestMovements: _movementList(json['latestMovements']),
      configVersion: _asInt(json['configVersion']),
    );
  }
}

class SavingsGoalMutation {
  const SavingsGoalMutation({
    required this.goal,
    required this.summary,
    this.completedGoal,
  });

  final SavingsGoal? goal;
  final SavingsGoal? completedGoal;
  final SavingsBoard summary;

  factory SavingsGoalMutation.fromJson(Map<String, dynamic> json) =>
      SavingsGoalMutation(
        goal: json['goal'] is Map
            ? SavingsGoal.fromJson(Map<String, dynamic>.from(json['goal']))
            : null,
        completedGoal: json['completedGoal'] is Map
            ? SavingsGoal.fromJson(
                Map<String, dynamic>.from(json['completedGoal']),
              )
            : null,
        summary: SavingsBoard.fromJson(_mapOrEmpty(json['summary'])),
      );
}

class SavingsOperationResult {
  const SavingsOperationResult({
    required this.operationId,
    required this.allocatedToGoal,
    required this.sentToCushion,
    required this.completedGoal,
    required this.activeGoalId,
    required this.goalBalance,
    required this.cushionBalance,
    required this.currency,
    required this.summary,
    this.celebration,
    this.idempotentReplay = false,
  });

  final String operationId;
  final double allocatedToGoal;
  final double sentToCushion;
  final SavingsGoal? completedGoal;
  final String? activeGoalId;
  final double goalBalance;
  final double cushionBalance;
  final String currency;
  final SavingsBoard summary;
  final Map<String, dynamic>? celebration;
  final bool idempotentReplay;

  factory SavingsOperationResult.fromJson(Map<String, dynamic> json) =>
      SavingsOperationResult(
        operationId: (json['operationId'] ?? '').toString(),
        allocatedToGoal: _asDouble(json['allocatedToGoal']),
        sentToCushion: _asDouble(json['sentToCushion']),
        completedGoal: json['completedGoal'] is Map
            ? SavingsGoal.fromJson(
                Map<String, dynamic>.from(json['completedGoal']),
              )
            : null,
        activeGoalId: json['activeGoalId']?.toString(),
        goalBalance: _asDouble(json['goalBalance']),
        cushionBalance: _asDouble(json['cushionBalance']),
        currency: (json['currency'] ?? 'COP').toString(),
        summary: SavingsBoard.fromJson(_mapOrEmpty(json['summary'])),
        celebration: json['celebration'] is Map
            ? Map<String, dynamic>.from(json['celebration'])
            : null,
        idempotentReplay: json['idempotentReplay'] == true,
      );
}

class SavingsWithdrawalResult {
  const SavingsWithdrawalResult({
    required this.balanceBefore,
    required this.balanceAfter,
    required this.cushionBalance,
    required this.summary,
  });

  final double balanceBefore;
  final double balanceAfter;
  final double cushionBalance;
  final SavingsBoard summary;

  factory SavingsWithdrawalResult.fromJson(Map<String, dynamic> json) =>
      SavingsWithdrawalResult(
        balanceBefore: _asDouble(json['balanceBefore']),
        balanceAfter: _asDouble(json['balanceAfter']),
        cushionBalance: _asDouble(json['cushionBalance']),
        summary: SavingsBoard.fromJson(_mapOrEmpty(json['summary'])),
      );
}

class SavingsMovement {
  const SavingsMovement({
    required this.movementId,
    required this.movementType,
    required this.amount,
    required this.balanceAfter,
    required this.goalId,
    required this.goalName,
    required this.date,
    this.note,
    this.automaticReference,
    this.sourceGoalId,
    this.userEmail,
  });

  final String movementId;
  final String movementType;
  final double amount;
  final double balanceAfter;
  final String goalId;
  final String goalName;
  final DateTime date;
  final String? note;
  final String? automaticReference;
  final String? sourceGoalId;
  final String? userEmail;

  factory SavingsMovement.fromJson(Map<String, dynamic> json) =>
      SavingsMovement(
        movementId: (json['movementId'] ?? '').toString(),
        movementType: (json['movementType'] ?? '').toString(),
        amount: _asDouble(json['amount']),
        balanceAfter: _asDouble(json['balanceAfter']),
        goalId: (json['goalId'] ?? '').toString(),
        goalName: (json['goalName'] ?? '').toString(),
        date: DateTime.tryParse((json['date'] ?? '').toString()) ?? DateTime.now(),
        note: json['note']?.toString(),
        automaticReference: json['automaticReference']?.toString(),
        sourceGoalId: json['sourceGoalId']?.toString(),
        userEmail: json['userEmail']?.toString(),
      );
}

class SavingsMovementPage {
  const SavingsMovementPage({
    required this.items,
    required this.count,
    required this.limit,
    required this.nextCursor,
  });

  final List<SavingsMovement> items;
  final int count;
  final int limit;
  final String? nextCursor;

  factory SavingsMovementPage.fromJson(Map<String, dynamic> json) =>
      SavingsMovementPage(
        items: _movementList(json['items']),
        count: _asInt(json['count']),
        limit: _asInt(json['limit'], fallback: 25),
        nextCursor: json['nextCursor']?.toString(),
      );
}

List<SavingsGoal> _goalList(dynamic value) => value is List
    ? value
          .whereType<Map>()
          .map((item) => SavingsGoal.fromJson(Map<String, dynamic>.from(item)))
          .toList()
    : const [];

List<SavingsMovement> _movementList(dynamic value) => value is List
    ? value
          .whereType<Map>()
          .map((item) => SavingsMovement.fromJson(Map<String, dynamic>.from(item)))
          .toList()
    : const [];

Map<String, dynamic> _mapOrEmpty(dynamic value) => value is Map
    ? Map<String, dynamic>.from(value)
    : <String, dynamic>{};

double _asDouble(dynamic value, {double fallback = 0}) =>
    value is num ? value.toDouble() : double.tryParse('$value') ?? fallback;

int _asInt(dynamic value, {int fallback = 0}) =>
    value is num ? value.toInt() : int.tryParse('$value') ?? fallback;