class AuthUser {
  const AuthUser({
    required this.id,
    required this.email,
    required this.name,
    required this.isActive,
    this.avatar,
    this.position,
    this.roles = const [],
  });

  final int id;
  final String email;
  final String name;
  final bool isActive;
  final String? avatar;
  final String? position;
  final List<String> roles;

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    if (json['id'] is! int ||
        json['email'] is! String ||
        json['name'] is! String ||
        json['isActive'] is! bool ||
        (json['avatar'] != null && json['avatar'] is! String) ||
        (json['position'] != null && json['position'] is! String)) {
      throw const FormatException('Invalid user');
    }
    final rawRoles = json['roles'];
    if (rawRoles != null &&
        (rawRoles is! List ||
            rawRoles.any(
              (role) =>
                  role is! Map<String, dynamic> || role['name'] is! String,
            ))) {
      throw const FormatException('Invalid user roles');
    }
    return AuthUser(
      id: json['id'] as int,
      email: json['email'] as String,
      name: json['name'] as String,
      isActive: json['isActive'] as bool,
      avatar: json['avatar'] as String?,
      position: json['position'] as String?,
      roles: List.unmodifiable(
        (rawRoles as List? ?? []).map((role) => role['name'] as String),
      ),
    );
  }
}
