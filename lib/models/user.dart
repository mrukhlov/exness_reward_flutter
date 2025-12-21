class User {
  final String id;
  final String name;
  final String email;
  final String? role;
  final String? avatar;

  User({
    required this.id,
    required this.name,
    required this.email,
    this.role,
    this.avatar,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      name: json['name'] as String? ?? json['full_name'] as String,
      email: json['email'] as String,
      role: json['role'] as String?,
      avatar: json['avatar'] as String? ?? json['avatar_url'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'role': role,
      'avatar': avatar,
    };
  }
}
