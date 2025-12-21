class VenueCategory {
  final String id;
  final String name;
  final String? description;

  VenueCategory({required this.id, required this.name, this.description});

  factory VenueCategory.fromJson(Map<String, dynamic> json) {
    return VenueCategory(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'name': name, 'description': description};
  }
}
