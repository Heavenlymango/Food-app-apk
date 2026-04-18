import 'dart:async';
import 'package:flutter/foundation.dart';
import '../services/api_service.dart';
import '../providers/auth_provider.dart';

class AppNotification {
  final String id;
  final String message;
  final bool isRead;
  final DateTime createdAt;

  const AppNotification({
    required this.id,
    required this.message,
    required this.isRead,
    required this.createdAt,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) =>
      AppNotification(
        id: json['id']?.toString() ?? '',
        message: json['message'] as String? ?? '',
        isRead: json['isRead'] as bool? ?? false,
        createdAt: json['createdAt'] != null
            ? DateTime.parse(json['createdAt'] as String)
            : DateTime.now(),
      );
}

class NotificationProvider extends ChangeNotifier {
  List<AppNotification> _notifications = [];
  Timer? _pollTimer;
  AuthProvider? _auth;

  List<AppNotification> get notifications => _notifications;
  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  void updateAuth(AuthProvider auth) {
    final changed = auth.user?.id != _auth?.user?.id;
    _auth = auth;
    if (changed) {
      _pollTimer?.cancel();
      if (auth.isLoggedIn && !auth.user!.isSeller) {
        fetch();
        _pollTimer = Timer.periodic(const Duration(seconds: 30), (_) => fetch());
      } else {
        _notifications = [];
        notifyListeners();
      }
    }
  }

  Future<void> fetch() async {
    try {
      final raw = await ApiService.getNotifications();
      _notifications = raw
          .whereType<Map<String, dynamic>>()
          .map(AppNotification.fromJson)
          .toList();
      notifyListeners();
    } catch (_) {}
  }

  Future<void> markAllRead() async {
    try {
      await ApiService.markAllNotificationsRead();
      _notifications = _notifications
          .map((n) => AppNotification(
                id: n.id,
                message: n.message,
                isRead: true,
                createdAt: n.createdAt,
              ))
          .toList();
      notifyListeners();
    } catch (_) {}
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }
}
