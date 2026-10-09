class AuditLog {
  final String id;
  final String user;
  final String role;
  final String action;
  final String entity;
  final String entityId;
  final String? oldValue;
  final String? newValue;
  final DateTime timestamp;

  AuditLog({
    required this.id,
    required this.user,
    required this.role,
    required this.action,
    required this.entity,
    required this.entityId,
    this.oldValue,
    this.newValue,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user': user,
      'role': role,
      'action': action,
      'entity': entity,
      'entityId': entityId,
      'oldValue': oldValue,
      'newValue': newValue,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory AuditLog.fromMap(Map<String, dynamic> map) {
    return AuditLog(
      id: map['id'] ?? '',
      user: map['user'] ?? '',
      role: map['role'] ?? '',
      action: map['action'] ?? '',
      entity: map['entity'] ?? '',
      entityId: map['entityId'] ?? '',
      oldValue: map['oldValue'],
      newValue: map['newValue'],
      timestamp: map['timestamp'] != null
          ? DateTime.parse(map['timestamp'])
          : DateTime.now(),
    );
  }
}
