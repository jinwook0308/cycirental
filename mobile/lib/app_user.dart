enum UserRole { student, admin }

class AppUser {
  const AppUser({
    this.userId,
    this.studentNumber,
    this.mustChangePassword = false,
    required this.id,
    required this.name,
    required this.role,
  });
  final int? userId;
  final String? studentNumber;
  final bool mustChangePassword;
  final String id;
  final String name;
  final UserRole role;
  bool get isAdmin => role == UserRole.admin;
}
