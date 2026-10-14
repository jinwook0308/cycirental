enum UserRole { student, admin }

class AppUser {
  const AppUser({required this.id, required this.name, required this.role});
  final String id;
  final String name;
  final UserRole role;
  bool get isAdmin => role == UserRole.admin;

  static const student = AppUser(
    id: 'demo_student',
    name: '데모 학생',
    role: UserRole.student,
  );
  static const admin = AppUser(
    id: 'demo_admin',
    name: '데모 관리자',
    role: UserRole.admin,
  );
}

// Local demo credentials only. Replace with the authenticated server response.
AppUser? demoSignIn(String id, String password) {
  if (id.trim() == 'student' && password == 'student1234') {
    return AppUser.student;
  }
  if (id.trim() == 'admin' && password == 'admin1234') return AppUser.admin;
  return null;
}
