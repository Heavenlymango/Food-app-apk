import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/app_config.dart';
import '../models/order.dart';

class ApiService {
  static final _db = Supabase.instance.client;

  // ── Edge Function calls (for business logic) ─────────────────────────────
  static Future<Map<String, String>> _headers() async {
    final token = _db.auth.currentSession?.accessToken;
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  static Future<Map<String, dynamic>> _post(
      String path, Map<String, dynamic> body) async {
    final res = await http.post(
      Uri.parse('${AppConfig.apiBaseUrl}$path'),
      headers: await _headers(),
      body: jsonEncode(body),
    );
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    if (res.statusCode >= 400) {
      throw ApiException(data['error'] as String? ?? 'Request failed');
    }
    return data;
  }

  // ── Orders ────────────────────────────────────────────────────────────────
  static Future<List<Order>> getStudentOrders() async {
    final userId = _db.auth.currentUser?.id;
    if (userId == null) return [];
    final data = await _db
        .from('orders')
        .select('*, shops!inner(shop_code), order_items(*)')
        .eq('student_id', userId)
        .order('ordered_at', ascending: false)
        .limit(50);
    return (data as List)
        .map((e) => Order.fromSupabase(e as Map<String, dynamic>))
        .toList();
  }

  static Future<List<Order>> getSellerOrders() async {
    final shopId = _db.auth.currentUser?.userMetadata?['shop_id'] as String?;
    if (shopId == null) return [];
    final data = await _db
        .from('orders')
        .select('*, shops!inner(shop_code), order_items(*)')
        .eq('shop_id', shopId)
        .inFilter('status', ['pending', 'preparing', 'ready'])
        .order('ordered_at', ascending: false);
    return (data as List)
        .map((e) => Order.fromSupabase(e as Map<String, dynamic>))
        .toList();
  }

  static Future<Map<String, dynamic>> placeOrder(
      Map<String, dynamic> orderData) async {
    return _post('/api/orders/place', orderData);
  }

  static Future<void> updateOrderStatus(String orderId, String status,
      {String? cancelReason}) async {
    final body = <String, dynamic>{'orderId': orderId, 'status': status};
    if (cancelReason != null) body['cancelReason'] = cancelReason;
    await _post('/api/seller/update-order', body);
  }

  // ── Notifications ─────────────────────────────────────────────────────────
  static Future<List<dynamic>> getNotifications() async {
    final userId = _db.auth.currentUser?.id;
    if (userId == null) return [];
    final data = await _db
        .from('notifications')
        .select('id, message, is_read, created_at')
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .limit(20);
    return (data as List)
        .map((n) => {
              'id': n['id'],
              'message': n['message'],
              'isRead': n['is_read'],
              'createdAt': n['created_at'],
            })
        .toList();
  }

  static Future<void> markAllNotificationsRead() async {
    final userId = _db.auth.currentUser?.id;
    if (userId == null) return;
    await _db
        .from('notifications')
        .update({'is_read': true})
        .eq('user_id', userId)
        .eq('is_read', false);
  }

  // ── Public menu & shops (direct DB — no auth required) ───────────────────
  static Future<List<Map<String, dynamic>>> getPublicMenu() async {
    try {
      final data = await _db
          .from('menu_items')
          .select('*, shops!inner(shop_code)')
          .eq('is_available', true);
      return (data as List)
          .map((item) => {
                'id': item['id'] as String,
                'name': item['name'] as String,
                'description': item['description'] as String? ?? '',
                'price': (item['price'] as num).toDouble(),
                'category': item['category'] as String? ?? '',
                'calories': (item['calories'] as num?)?.toInt() ?? 0,
                'isHealthy': item['is_healthy'] as bool? ?? false,
                'isSpecial': item['is_special'] as bool? ?? false,
                'image': item['image_url'] as String? ?? '',
                'preparationTime': (item['preparation_time'] as num?)?.toInt() ?? 15,
                'shop': (item['shops'] as Map)['shop_code'] as String,
              })
          .toList();
    } catch (_) {
      return [];
    }
  }

  static Future<List<Map<String, dynamic>>> getPublicShops() async {
    try {
      final data = await _db
          .from('shops')
          .select('shop_code, name, description, campus')
          .eq('is_active', true);
      return (data as List)
          .map((shop) => {
                'id': shop['shop_code'] as String,
                'name': shop['name'] as String,
                'description': shop['description'] as String? ?? '',
                'campus': shop['campus'] as String,
                'healthyCount': 0,
                'totalItems': 0,
              })
          .toList();
    } catch (_) {
      return [];
    }
  }

  // ── Profile ───────────────────────────────────────────────────────────────
  static Future<void> updateStudentProfile({
    required String studentId,
    required String name,
    String? email,
    String? phone,
  }) async {
    await _db.auth.updateUser(UserAttributes(
      data: {
        'name': name,
        if (email != null && email.isNotEmpty) 'email': email,
        if (phone != null && phone.isNotEmpty) 'phone': phone,
      },
    ));
  }
}

class ApiException implements Exception {
  final String message;
  ApiException(this.message);
  @override
  String toString() => message;
}
