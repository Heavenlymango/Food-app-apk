class AppUser {
  final String id;
  final String name;
  final String role; // 'student' | 'seller'
  final String? shopId;
  final String? studentId;
  final String? campus;

  const AppUser({
    required this.id,
    required this.name,
    required this.role,
    this.shopId,
    this.studentId,
    this.campus,
  });

  bool get isSeller => role == 'seller';
  bool get isStudent => role == 'student';

  factory AppUser.fromJson(Map<String, dynamic> json) => AppUser(
        id: json['id'] as String,
        name: json['name'] as String,
        role: json['role'] as String,
        shopId: json['shopId'] as String?,
        studentId: json['studentId'] as String?,
        campus: json['campus'] as String?,
      );
}
