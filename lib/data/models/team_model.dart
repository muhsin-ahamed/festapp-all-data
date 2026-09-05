class Team {
  final String id;
  final String teamName;
  final String teamCode;
  final String? leaderId;
  final String? leaderName;
  final String? mentorName;
  final String? assistantLeaderName;
  final String? section;
  final String? logo;
  final int totalStudents;
  final int totalPoints;
  final int rank;
  final int gradeA;
  final int gradeB;
  final int gradeC;
  final int firstPlaces;
  final int secondPlaces;
  final int thirdPlaces;
  final String status; // ACTIVE, INACTIVE
  final DateTime createdAt;
  final DateTime? updatedAt;

  Team({
    required this.id,
    required this.teamName,
    required this.teamCode,
    this.leaderId,
    this.leaderName,
    this.mentorName,
    this.assistantLeaderName,
    this.section,
    this.logo,
    this.totalStudents = 0,
    this.totalPoints = 0,
    this.rank = 0,
    this.gradeA = 0,
    this.gradeB = 0,
    this.gradeC = 0,
    this.firstPlaces = 0,
    this.secondPlaces = 0,
    this.thirdPlaces = 0,
    this.status = 'ACTIVE',
    DateTime? createdAt,
    this.updatedAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Team copyWith({
    String? id,
    String? teamName,
    String? teamCode,
    String? leaderId,
    String? leaderName,
    String? mentorName,
    String? assistantLeaderName,
    String? section,
    String? logo,
    int? totalStudents,
    int? totalPoints,
    int? rank,
    int? gradeA,
    int? gradeB,
    int? gradeC,
    int? firstPlaces,
    int? secondPlaces,
    int? thirdPlaces,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Team(
      id: id ?? this.id,
      teamName: teamName ?? this.teamName,
      teamCode: teamCode ?? this.teamCode,
      leaderId: leaderId ?? this.leaderId,
      leaderName: leaderName ?? this.leaderName,
      mentorName: mentorName ?? this.mentorName,
      assistantLeaderName: assistantLeaderName ?? this.assistantLeaderName,
      section: section ?? this.section,
      logo: logo ?? this.logo,
      totalStudents: totalStudents ?? this.totalStudents,
      totalPoints: totalPoints ?? this.totalPoints,
      rank: rank ?? this.rank,
      gradeA: gradeA ?? this.gradeA,
      gradeB: gradeB ?? this.gradeB,
      gradeC: gradeC ?? this.gradeC,
      firstPlaces: firstPlaces ?? this.firstPlaces,
      secondPlaces: secondPlaces ?? this.secondPlaces,
      thirdPlaces: thirdPlaces ?? this.thirdPlaces,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'id': id,
      'teamName': teamName,
      'teamCode': teamCode,
      'leaderId': leaderId,
      'leaderName': leaderName,
      'mentorName': mentorName,
      'section': section,
      'logo': logo,
      'totalStudents': totalStudents,
      'totalPoints': totalPoints,
      'rank': rank,
      'gradeA': gradeA,
      'gradeB': gradeB,
      'gradeC': gradeC,
      'firstPlaces': firstPlaces,
      'secondPlaces': secondPlaces,
      'thirdPlaces': thirdPlaces,
      'status': status,
      'createdAt': createdAt.toIso8601String(),
    };
    if (assistantLeaderName != null && assistantLeaderName!.isNotEmpty) {
      map['assistantLeaderName'] = assistantLeaderName;
    }
    if (updatedAt != null) {
      map['updatedAt'] = updatedAt!.toIso8601String();
    }
    return map;
  }

  factory Team.fromMap(Map<String, dynamic> map) {
    return Team(
      id: map['id'] ?? '',
      teamName: map['teamName'] ?? '',
      teamCode: map['teamCode'] ?? '',
      leaderId: map['leaderId'],
      leaderName: map['leaderName'],
      mentorName: map['mentorName'],
      assistantLeaderName: map['assistantLeaderName'],
      section: map['section'],
      logo: map['logo'],
      totalStudents: map['totalStudents'] ?? 0,
      totalPoints: map['totalPoints'] ?? 0,
      rank: map['rank'] ?? 0,
      gradeA: map['gradeA'] ?? 0,
      gradeB: map['gradeB'] ?? 0,
      gradeC: map['gradeC'] ?? 0,
      firstPlaces: map['firstPlaces'] ?? 0,
      secondPlaces: map['secondPlaces'] ?? 0,
      thirdPlaces: map['thirdPlaces'] ?? 0,
      status: map['status'] ?? 'ACTIVE',
      createdAt: map['createdAt'] != null ? DateTime.parse(map['createdAt']) : DateTime.now(),
      updatedAt: map['updatedAt'] != null ? DateTime.parse(map['updatedAt']) : null,
    );
  }
}
