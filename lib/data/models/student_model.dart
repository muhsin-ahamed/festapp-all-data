import '../../core/constants/app_constants.dart';

class Student {
  final String id;
  final String chaseNumber; // Unique, e.g., 1001 or CHASE-1001
  final String name;
  final String gender;
  final String dateOfBirth;
  final FestSection section; // Sub Junior, Senior, Super Senior
  final String teamId;
  final String phone;
  final String className;
  final String schoolName;
  final String? photo;
  final String? qrCode;
  final DateTime createdAt;
  final DateTime updatedAt;

  Student({
    required this.id,
    required this.chaseNumber,
    required this.name,
    required this.gender,
    required this.dateOfBirth,
    required this.section,
    required this.teamId,
    required this.phone,
    required this.className,
    required this.schoolName,
    this.photo,
    this.qrCode,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  Student copyWith({
    String? id,
    String? chaseNumber,
    String? name,
    String? gender,
    String? dateOfBirth,
    FestSection? section,
    String? teamId,
    String? phone,
    String? className,
    String? schoolName,
    String? photo,
    String? qrCode,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Student(
      id: id ?? this.id,
      chaseNumber: chaseNumber ?? this.chaseNumber,
      name: name ?? this.name,
      gender: gender ?? this.gender,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      section: section ?? this.section,
      teamId: teamId ?? this.teamId,
      phone: phone ?? this.phone,
      className: className ?? this.className,
      schoolName: schoolName ?? this.schoolName,
      photo: photo ?? this.photo,
      qrCode: qrCode ?? this.qrCode,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'chaseNumber': chaseNumber,
      'name': name,
      'gender': gender,
      'dateOfBirth': dateOfBirth,
      'section': section.name,
      'teamId': teamId,
      'phone': phone,
      'className': className,
      'schoolName': schoolName,
      'photo': photo,
      'qrCode': qrCode,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory Student.fromMap(Map<String, dynamic> map) {
    return Student(
      id: map['id'] ?? '',
      chaseNumber: map['chaseNumber'] ?? '',
      name: map['name'] ?? '',
      gender: map['gender'] ?? '',
      dateOfBirth: map['dateOfBirth'] ?? '',
      section: FestSection.fromString(map['section'] ?? '', map['chaseNumber']),
      teamId: map['teamId'] ?? '',
      phone: map['phone'] ?? '',
      className: map['className'] ?? '',
      schoolName: map['schoolName'] ?? '',
      photo: map['photo'],
      qrCode: map['qrCode'],
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'])
          : DateTime.now(),
      updatedAt: map['updatedAt'] != null
          ? DateTime.parse(map['updatedAt'])
          : DateTime.now(),
    );
  }
}
