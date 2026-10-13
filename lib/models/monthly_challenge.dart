class MonthlyChallengeContent {
  const MonthlyChallengeContent({
    required this.source,
    required this.title,
    required this.description,
    required this.category,
    this.catalogChallengeId,
  });

  final String source;
  final String title;
  final String description;
  final String category;
  final String? catalogChallengeId;

  factory MonthlyChallengeContent.fromJson(Map<String, dynamic> json) =>
      MonthlyChallengeContent(
        source: (json['source'] ?? 'custom').toString(),
        title: (json['title'] ?? '').toString(),
        description: (json['description'] ?? '').toString(),
        category: (json['category'] ?? 'otro').toString(),
        catalogChallengeId: json['catalogChallengeId']?.toString(),
      );
}

class MonthlyChallengeProposal extends MonthlyChallengeContent {
  const MonthlyChallengeProposal({
    required super.source,
    required super.title,
    required super.description,
    required super.category,
    required this.proposedBy,
    required this.proposedByName,
    required this.proposedByEmail,
    this.catalogChallengeId,
  });

  final String proposedBy;
  final String proposedByName;
  final String proposedByEmail;
  @override
  final String? catalogChallengeId;

  factory MonthlyChallengeProposal.fromJson(Map<String, dynamic> json) =>
      MonthlyChallengeProposal(
        source: (json['source'] ?? 'custom').toString(),
        title: (json['title'] ?? '').toString(),
        description: (json['description'] ?? '').toString(),
        category: (json['category'] ?? 'otro').toString(),
        proposedBy: (json['proposedBy'] ?? '').toString(),
        proposedByName: (json['proposedByName'] ?? '').toString(),
        proposedByEmail: (json['proposedByEmail'] ?? '').toString(),
        catalogChallengeId: json['catalogChallengeId']?.toString(),
      );
}

class MonthlyChallengeChoice {
  const MonthlyChallengeChoice({
    required this.userSub,
    this.proposedBy,
    this.requestRandomTiebreak = false,
  });

  final String userSub;
  final String? proposedBy;
  final bool requestRandomTiebreak;

  factory MonthlyChallengeChoice.fromJson(Map<String, dynamic> json) {
    final user = json['user'];
    return MonthlyChallengeChoice(
      userSub: (json['userSub'] ??
              json['sub'] ??
              json['userId'] ??
              json['chosenBy'] ??
              (user is Map ? user['sub'] : null) ??
              '')
          .toString(),
      proposedBy: json['proposedBy']?.toString(),
      requestRandomTiebreak: json['requestRandomTiebreak'] == true,
    );
  }
}

class MonthlyChallengePerson {
  const MonthlyChallengePerson({required this.sub, required this.email, required this.name});

  final String sub;
  final String email;
  final String name;

  factory MonthlyChallengePerson.fromJson(Map<String, dynamic> json) =>
      MonthlyChallengePerson(
        sub: (json['sub'] ?? '').toString(),
        email: (json['email'] ?? '').toString(),
        name: (json['name'] ?? '').toString(),
      );
}

class MonthlyChallengeState {
  const MonthlyChallengeState({
    required this.monthKey,
    required this.cycle,
    required this.status,
    required this.proposals,
    required this.choices,
    required this.disagreement,
    required this.availableActions,
    this.deadlineAt,
    this.selectedChallenge,
    this.selectedSource,
    this.assignedAt,
    this.completedBy,
    this.completedByEmail,
    this.completedAt,
    this.couponId,
    this.viewer,
    this.partner,
  });

  final String monthKey;
  final int cycle;
  final String status;
  final DateTime? deadlineAt;
  final MonthlyChallengeContent? selectedChallenge;
  final String? selectedSource;
  final DateTime? assignedAt;
  final String? completedBy;
  final String? completedByEmail;
  final DateTime? completedAt;
  final String? couponId;
  final List<MonthlyChallengeProposal> proposals;
  final List<MonthlyChallengeChoice> choices;
  final bool disagreement;
  final Set<String> availableActions;
  final MonthlyChallengePerson? viewer;
  final MonthlyChallengePerson? partner;

  bool get isPending => status == 'PENDING';
  bool get isAssigned => status == 'ASSIGNED';
  bool get isCompleted => status == 'COMPLETED';

  factory MonthlyChallengeState.fromJson(Map<String, dynamic> json) {
    final selected = json['selectedChallenge'];
    final viewer = json['viewer'];
    final partner = json['partner'];
    final rawProposals = json['proposals'];
    final rawChoices = json['choices'];
    final rawActions = json['availableActions'];
    return MonthlyChallengeState(
      monthKey: (json['monthKey'] ?? '').toString(),
      cycle: _asInt(json['cycle']),
      status: (json['status'] ?? 'PENDING').toString(),
      deadlineAt: DateTime.tryParse((json['deadlineAt'] ?? '').toString()),
      selectedChallenge: selected is Map
          ? MonthlyChallengeContent.fromJson(Map<String, dynamic>.from(selected))
          : null,
      selectedSource: json['selectedSource']?.toString(),
      assignedAt: DateTime.tryParse((json['assignedAt'] ?? '').toString()),
      completedBy: json['completedBy']?.toString(),
      completedByEmail: json['completedByEmail']?.toString(),
      completedAt: DateTime.tryParse((json['completedAt'] ?? '').toString()),
      couponId: json['couponId']?.toString(),
      proposals: rawProposals is List
          ? rawProposals
                .whereType<Map>()
                .map((item) => MonthlyChallengeProposal.fromJson(
                      Map<String, dynamic>.from(item),
                    ))
                .toList()
          : const [],
      choices: rawChoices is List
          ? rawChoices
                .whereType<Map>()
                .map((item) => MonthlyChallengeChoice.fromJson(
                      Map<String, dynamic>.from(item),
                    ))
                .toList()
          : const [],
      disagreement: json['disagreement'] == true,
      availableActions: rawActions is List
          ? rawActions.map((item) => item.toString()).toSet()
          : const {},
      viewer: viewer is Map
          ? MonthlyChallengePerson.fromJson(Map<String, dynamic>.from(viewer))
          : null,
      partner: partner is Map
          ? MonthlyChallengePerson.fromJson(Map<String, dynamic>.from(partner))
          : null,
    );
  }
}

class MonthlyChallengeCatalogItem extends MonthlyChallengeContent {
  const MonthlyChallengeCatalogItem({
    required String challengeId,
    required super.title,
    required super.description,
    required super.category,
    this.active = true,
  }) : challengeId = challengeId,
       super(source: 'catalog', catalogChallengeId: challengeId);

  final String challengeId;
  final bool active;

  factory MonthlyChallengeCatalogItem.fromJson(Map<String, dynamic> json) =>
      MonthlyChallengeCatalogItem(
        challengeId: (json['challengeId'] ?? json['id'] ?? '').toString(),
        title: (json['title'] ?? '').toString(),
        description: (json['description'] ?? '').toString(),
        category: (json['category'] ?? 'otro').toString(),
        active: json['active'] != false,
      );
}

class MonthlyChallengeFavorite extends MonthlyChallengeContent {
  const MonthlyChallengeFavorite({
    required this.favoriteId,
    required super.source,
    required super.title,
    required super.description,
    required super.category,
    super.catalogChallengeId,
  });

  final String favoriteId;

  factory MonthlyChallengeFavorite.fromJson(Map<String, dynamic> json) =>
      MonthlyChallengeFavorite(
        favoriteId: (json['favoriteId'] ?? json['id'] ?? '').toString(),
        source: (json['source'] ?? 'custom').toString(),
        title: (json['title'] ?? '').toString(),
        description: (json['description'] ?? '').toString(),
        category: (json['category'] ?? 'otro').toString(),
        catalogChallengeId: json['catalogChallengeId']?.toString(),
      );
}

class MonthlyChallengeCoupon {
  const MonthlyChallengeCoupon({
    required this.couponId,
    required this.title,
    required this.description,
    required this.sourceMonthKey,
    required this.sourceChallengeTitle,
    required this.createdBy,
    required this.createdByEmail,
    required this.createdByName,
    required this.redeemed,
  });

  final String couponId;
  final String title;
  final String description;
  final String sourceMonthKey;
  final String sourceChallengeTitle;
  final String createdBy;
  final String createdByEmail;
  final String createdByName;
  final bool redeemed;

  factory MonthlyChallengeCoupon.fromJson(Map<String, dynamic> json) =>
      MonthlyChallengeCoupon(
        couponId: (json['couponId'] ?? '').toString(),
        title: (json['title'] ?? '').toString(),
        description: (json['description'] ?? '').toString(),
        sourceMonthKey: (json['sourceMonthKey'] ?? '').toString(),
        sourceChallengeTitle: (json['sourceChallengeTitle'] ?? '').toString(),
        createdBy: (json['createdBy'] ?? '').toString(),
        createdByEmail: (json['createdByEmail'] ?? '').toString(),
        createdByName: (json['createdByName'] ?? '').toString(),
        redeemed: json['redeemed'] == true,
      );
}

class MonthlyChallengeCompletion {
  const MonthlyChallengeCompletion({
    required this.state,
    required this.coupon,
    required this.couponCreated,
    required this.alreadyCompleted,
  });

  final MonthlyChallengeState state;
  final MonthlyChallengeCoupon coupon;
  final bool couponCreated;
  final bool alreadyCompleted;

  factory MonthlyChallengeCompletion.fromJson(Map<String, dynamic> json) {
    final month = json['month'] is Map
        ? Map<String, dynamic>.from(json['month'])
        : <String, dynamic>{};
    final coupon = json['coupon'] is Map
        ? Map<String, dynamic>.from(json['coupon'])
        : <String, dynamic>{};
    return MonthlyChallengeCompletion(
      state: MonthlyChallengeState.fromJson(month),
      coupon: MonthlyChallengeCoupon.fromJson(coupon),
      couponCreated: json['couponCreated'] == true,
      alreadyCompleted: json['alreadyCompleted'] == true,
    );
  }
}

class MonthlyChallengeCouponResult {
  const MonthlyChallengeCouponResult({required this.coupon});

  final MonthlyChallengeCoupon coupon;

  factory MonthlyChallengeCouponResult.fromJson(Map<String, dynamic> json) =>
      MonthlyChallengeCouponResult(
        coupon: MonthlyChallengeCoupon.fromJson(
          json['coupon'] is Map
              ? Map<String, dynamic>.from(json['coupon'])
              : json,
        ),
      );
}

int _asInt(dynamic value) => value is num ? value.toInt() : int.tryParse('$value') ?? 0;