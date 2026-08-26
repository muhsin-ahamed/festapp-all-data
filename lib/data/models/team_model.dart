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
  final String status; // ACTIVE, INACTIVE
  final DateTime createdAt;

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
    this.status = 'ACTIVE',
    DateTime? createdAt,
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
    String? status,
    DateTime? createdAt,
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
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'teamName': teamName,
      'teamCode': teamCode,
      'leaderId': leaderId,
      'leaderName': leaderName,
      'mentorName': mentorName,
      'assistantLeaderName': assistantLeaderName,
      'section': section,
      'logo': logo,
      'totalStudents': totalStudents,
      'totalPoints': totalPoints,
      'rank': rank,
      'status': status,
      'createdAt': createdAt.toIso8601String(),
    };
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
      status: map['status'] ?? 'ACTIVE',
      createdAt: map['createdAt'] != null ? DateTime.parse(map['createdAt']) : DateTime.now(),
    );
  }
}
