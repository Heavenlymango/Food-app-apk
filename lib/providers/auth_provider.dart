import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/app_user.dart';
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  AppUser? _user;
  bool _isLoading = true;
  String? _error;

  AppUser? get user => _user;
  bool get isLoading => _isLoading;
  bool get isLoggedIn => _user != null;
  String? get error => _error;

  AuthProvider() {
    _init();
  }

  void _init() {
    final existing = Supabase.instance.client.auth.currentUser;
    _user = existing != null ? AuthService.fromSupabase(existing) : null;
    _isLoading = false;

    Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      debugPrint('AUTH STATE: ${data.event} | email=${data.session?.user.email}');
      if (data.event == AuthChangeEvent.signedOut) {
        _user = null;
        notifyListeners();
        return;
      }
      final supaUser = data.session?.user;
      if (supaUser != null) {
        _user = AuthService.fromSupabase(supaUser);
        notifyListeners();
      }
    });
  }

  Future<void> login(String userId, String password) async {
    _error = null;
    _isLoading = true;
    notifyListeners();
    try {
      _user = await AuthService.login(userId, password);
    } on AuthException catch (e) {
      debugPrint('AUTH ERROR: ${e.message} | statusCode=${e.statusCode}');
      _error = e.message;
      _user = null;
    } catch (e, st) {
      debugPrint('AUTH ERROR: $e\n$st');
      _error = e.toString().replaceFirst('Exception: ', '');
      _user = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> register({
    required String studentId,
    required String name,
    required String schoolEmail,
    required String password,
  }) async {
    _error = null;
    _isLoading = true;
    notifyListeners();
    try {
      _user = await AuthService.registerStudent(
        studentId: studentId,
        name: name,
        schoolEmail: schoolEmail,
        password: password,
      );
    } on AuthException catch (e) {
      debugPrint('REGISTER ERROR: ${e.message} | statusCode=${e.statusCode}');
      _error = e.message;
      _user = null;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      _user = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    await AuthService.logout();
    _user = null;
    _error = null;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
