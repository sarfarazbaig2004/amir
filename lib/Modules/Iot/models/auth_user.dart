class AuthUser {
  const AuthUser({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.permissions,
  });

  final int id;
  final String name;
  final String email;
  final String role;
  final List<String> permissions;

  bool get isSuperAdmin => role == 'SUPER_ADMIN';
  bool get isCustomer => role == 'CUSTOMER';

  bool can(String permission) => permissions.contains(permission);

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    return AuthUser(
      id: json['id'] is int ? json['id'] as int : 0,
      name: (json['name'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
      role: (json['role'] ?? 'CUSTOMER').toString(),
      permissions: (json['permissions'] as List<dynamic>? ?? [])
          .map((permission) => permission.toString())
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'role': role,
      'permissions': permissions,
    };
  }
}
