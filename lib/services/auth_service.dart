import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/app_user.dart';

class AuthService {
  static final _supabase = Supabase.instance.client;

  // Login: student ID → studentId@student.local, seller code → code@seller.local
  static Future<AppUser> login(String userId, String password) async {
    final email = _toEmail(userId);
    final res = await _supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );
    if (res.user == null) throw Exception('Login failed');
    return fromSupabase(res.user!);
  }

  // Register student — Supabase auth uses studentId@student.local,
  // real school email is stored in metadata only (for admin / forgot-pw later).
  static Future<AppUser> registerStudent({
    required String studentId,
    required String name,
    required String schoolEmail,
    required String password,
  }) async {
    final campus = _campusFromEmail(schoolEmail);
    final authEmail = '$studentId@student.local';
    final res = await _supabase.auth.signUp(
      email: authEmail,
      password: password,
      data: {
        'name': name,
        'student_id': studentId,
        'campus': campus,
        'role': 'student',
        'school_email': schoolEmail,
      },
    );
    if (res.user == null) throw Exception('Registration failed');
    return fromSupabase(res.user!);
  }

  static Future<AppUser?> restoreSession() async {
    final user = _supabase.auth.currentUser;
    return user != null ? fromSupabase(user) : null;
  }

  static Future<void> logout() async {
    await _supabase.auth.signOut();
  }

  // Real email passes through. Digit-first = student. Letter-first = seller.
  static String _toEmail(String userId) {
    if (userId.contains('@')) return userId;
    return RegExp(r'^\d').hasMatch(userId)
        ? '$userId@student.local'
        : '$userId@seller.local';
  }

  static String _campusFromEmail(String email) {
    if (email.toLowerCase().contains('ifl')) return 'IFL';
    return 'RUPP';
  }

  static String campusFromEmail(String email) => _campusFromEmail(email);

  static AppUser fromSupabase(User user) {
    final meta = user.userMetadata ?? {};
    return AppUser(
      id: user.id,
      name: meta['name'] as String? ?? '',
      role: meta['role'] as String? ?? 'student',
      studentId: meta['student_id'] as String?,
      campus: meta['campus'] as String?,
      shopId: meta['shop_id'] as String?,
    );
  }
}
