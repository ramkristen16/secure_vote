class ChoiceModel {
  String name;
  int voteCount;
  final String id;

  ChoiceModel({
    required this.id,
    required this.name,
    this.voteCount = 0,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'voteCount': voteCount,
  };

  factory ChoiceModel.fromJson(Map<String, dynamic> json) => ChoiceModel(
    id: json['id'] ?? json['_id'],
    name: json['name'] ?? '',
    voteCount: json['voteCount'] ?? 0,
  );
}

class ParticipantVote {
  final String participantId;
  final String participantName;
  final int choiceIndex;
  final DateTime votedAt;

  ParticipantVote({
    required this.participantId,
    required this.participantName,
    required this.choiceIndex,
    required this.votedAt,
  });

  Map<String, dynamic> toJson() => {
    'participantId': participantId,
    'participantName': participantName,
    'choiceIndex': choiceIndex,
    'votedAt': votedAt.toIso8601String(),
  };

  factory ParticipantVote.fromJson(Map<String, dynamic> json) => ParticipantVote(
    participantId: json['participantId'] ?? '',
    participantName: json['participantName'] ?? '',
    choiceIndex: json['choiceIndex'] ?? 0,
    votedAt: DateTime.parse(json['votedAt']),
  );
}

class SubjectModel {
  final String id;
  final String creatorId;
  final String title;
  final String? description;
  final DateTime startingDate;
  final DateTime deadline;
  final List<ChoiceModel> choices;
  final bool isAnonymous;
  final bool isPrivate;
  final DateTime createdAt;

  int participantCount;
  int voteCount;

  List<ParticipantVote> participantVotes;

  String? myVoteChoiceIndex;

  SubjectModel({
    String? id,
    required this.creatorId,
    required this.title,
    this.description,
    required this.startingDate,
    required this.deadline,
    required this.choices,
    this.isAnonymous = true,
    this.isPrivate = true,
    DateTime? createdAt,
    this.participantCount = 0,
    this.voteCount = 0,
    List<ParticipantVote>? participantVotes,
    this.myVoteChoiceIndex,
  })  : id = id ?? DateTime.now().millisecondsSinceEpoch.toString(),
        createdAt = createdAt ?? DateTime.now(),
        participantVotes = participantVotes ?? [];

  bool get notStartedYet {
    return DateTime.now().isBefore(startingDate);
  }

  bool get isActive {
    final now = DateTime.now();
    return now.isAfter(startingDate) && now.isBefore(deadline);
  }

  bool get isFinished {
    return DateTime.now().isAfter(deadline);
  }

  String get status {
    if (notStartedYet) return "À venir";
    if (isActive) return "En cours";
    return "Terminé";
  }

  bool get isOpen {
    final now = DateTime.now();
    return now.isAfter(startingDate) && now.isBefore(deadline);
  }

  bool isCreatedByMe(String currentUserId) => creatorId == currentUserId;

  bool get hasVoted => myVoteChoiceIndex != null;

  List<double> get choicePercentages {
    if (voteCount == 0) return List.filled(choices.length, 0.0);
    return choices.map((c) => (c.voteCount / voteCount) * 100).toList();
  }

  void recordVote(int choiceIndex, String userId, String userName) {
    if (hasVoted) {
      final oldIndex = int.parse(myVoteChoiceIndex!);
      choices[oldIndex].voteCount--;
      voteCount--;
      participantVotes.removeWhere((v) => v.participantId == userId);
    } else {
      participantCount++;
    }

    choices[choiceIndex].voteCount++;
    myVoteChoiceIndex = choiceIndex.toString();
    voteCount++;

    participantVotes.add(ParticipantVote(
      participantId: userId,
      participantName: userName,
      choiceIndex: choiceIndex,
      votedAt: DateTime.now(),
    ));
  }

  SubjectModel copyWith({
    String? title,
    String? description,
    DateTime? startingDate,
    DateTime? deadline,
    List<ChoiceModel>? choices,
    bool? isAnonymous,
    bool? isPrivate,
    int? participantCount,
    int? voteCount,
    List<ParticipantVote>? participantVotes,
    String? myVoteChoiceIndex,
  }) {
    return SubjectModel(
      id: this.id,
      creatorId: this.creatorId,
      title: title ?? this.title,
      description: description ?? this.description,
      startingDate: startingDate ?? this.startingDate,
      deadline: deadline ?? this.deadline,
      choices: choices ?? this.choices,
      isAnonymous: isAnonymous ?? this.isAnonymous,
      isPrivate: isPrivate ?? this.isPrivate,
      createdAt: this.createdAt,
      participantCount: participantCount ?? this.participantCount,
      voteCount: voteCount ?? this.voteCount,
      participantVotes: participantVotes ?? this.participantVotes,
      myVoteChoiceIndex: myVoteChoiceIndex ?? this.myVoteChoiceIndex,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'creatorId': creatorId,
    'title': title,
    'description': description,
    'startingDate': startingDate.toIso8601String(),
    'deadline': deadline.toIso8601String(),
    'choices': choices.map((c) => c.toJson()).toList(),
    'isAnonymous': isAnonymous,
    'isPrivate': isPrivate,
    'createdAt': createdAt.toIso8601String(),
    'participantCount': participantCount,
    'voteCount': voteCount,
    'myVoteChoiceIndex': myVoteChoiceIndex,
    'participantVotes': participantVotes.map((p) => p.toJson()).toList(),
  };

  factory SubjectModel.fromJson(Map<String, dynamic> json, String currentUserId) {
    return SubjectModel(
      id: json['id'],
      creatorId: json['creatorId'],
      title: json['title'],
      description: json['description'],
      startingDate: DateTime.parse(json['startingDate']),
      deadline: DateTime.parse(json['deadline']),
      choices: (json['choices'] as List).map((c) => ChoiceModel.fromJson(c)).toList(),
      isAnonymous: json['isAnonymous'] ?? true,
      isPrivate: json['isPrivate'] ?? true,
      createdAt: DateTime.parse(json['createdAt']),
      participantCount: json['participantCount'] ?? 0,
      voteCount: json['voteCount'] ?? 0,
      myVoteChoiceIndex: json['myVoteChoiceIndex']?.toString(),
      participantVotes: json['participantVotes'] != null
          ? (json['participantVotes'] as List).map((p) => ParticipantVote.fromJson(p)).toList()
          : [],
    );
  }
}