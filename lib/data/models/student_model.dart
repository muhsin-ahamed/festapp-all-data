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
    final chase = (map['chaseNumber'] ??
            map['chase_number'] ??
            map['chestNo'] ??
            map['chest_no'] ??
            map['chestNumber'] ??
            map['chse_no'])
        ?.toString() ??
        '';
    return Student(
      id: map['id']?.toString() ?? '',
      chaseNumber: chase,
      name: map['name']?.toString() ?? '',
      gender: map['gender']?.toString() ?? '',
      dateOfBirth: (map['dateOfBirth'] ?? map['date_of_birth'])?.toString() ?? '',
      section: FestSection.fromString(
        (map['section'])?.toString() ?? '',
        chase,
      ),
      teamId: (map['teamId'] ?? map['team_id'])?.toString() ?? '',
      phone: map['phone']?.toString() ?? '',
      className: (map['className'] ?? map['class_name'])?.toString() ?? '',
      schoolName: (map['schoolName'] ?? map['school_name'])?.toString() ?? '',
      photo: map['photo']?.toString(),
      qrCode: (map['qrCode'] ?? map['qr_code'])?.toString() ?? chase,
      createdAt: map['createdAt'] != null
          ? (DateTime.tryParse(map['createdAt'].toString()) ?? DateTime.now())
          : (map['created_at'] != null
              ? (DateTime.tryParse(map['created_at'].toString()) ?? DateTime.now())
              : DateTime.now()),
      updatedAt: map['updatedAt'] != null
          ? (DateTime.tryParse(map['updatedAt'].toString()) ?? DateTime.now())
          : (map['updated_at'] != null
              ? (DateTime.tryParse(map['updated_at'].toString()) ?? DateTime.now())
              : DateTime.now()),
    );
  }
}
