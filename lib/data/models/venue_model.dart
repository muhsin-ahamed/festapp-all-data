class Venue {
  final String id;
  final String name;
  final String location;
  final int capacity;
  final String description;

  Venue({
    required this.id,
    required this.name,
    required this.location,
    this.capacity = 100,
    this.description = '',
  });

  Venue copyWith({
    String? id,
    String? name,
    String? location,
    int? capacity,
    String? description,
  }) {
    return Venue(
      id: id ?? this.id,
      name: name ?? this.name,
      location: location ?? this.location,
      capacity: capacity ?? this.capacity,
      description: description ?? this.description,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'location': location,
      'capacity': capacity,
      'description': description,
    };
  }

  factory Venue.fromMap(Map<String, dynamic> map) {
    return Venue(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      location: map['location'] ?? '',
      capacity: map['capacity'] ?? 100,
      description: map['description'] ?? '',
    );
  }
}
