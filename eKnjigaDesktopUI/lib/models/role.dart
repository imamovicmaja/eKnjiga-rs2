class Role {
  final int id;
  final String name;
  final String description;

  Role({required this.id, required this.name, required this.description});

  factory Role.fromJson(Map<String, dynamic> json) {
    return Role(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: json['name'] as String? ?? '',
      description: json['description'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
      };
}
