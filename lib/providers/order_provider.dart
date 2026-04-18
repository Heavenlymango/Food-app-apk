import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/order.dart';
import '../models/cart_item.dart';
import '../models/app_user.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';

class OrderProvider extends ChangeNotifier {
  List<Order> _orders = [];
  bool _isLoading = false;
  String? _error;
  AppUser? _user;
  Timer? _pollTimer;

  List<Order> get orders => _orders;
  bool get isLoading => _isLoading;
  String? get error => _error;

  void updateAuth(AuthProvider auth) {
    final newUser = auth.user;
    if (newUser?.id != _user?.id) {
      _user = newUser;
      _pollTimer?.cancel();
      if (_user != null) {
        fetchOrders();
        _startPolling();
      } else {
        _orders = [];
        notifyListeners();
      }
    }
  }

  void _startPolling() {
    final interval =
        _user?.isSeller == true ? const Duration(seconds: 10) : const Duration(seconds: 5);
    _pollTimer = Timer.periodic(interval, (_) => fetchOrders());
  }

  Future<void> fetchOrders() async {
    if (_user == null) return;
    try {
      final fetched = _user!.isSeller
          ? await ApiService.getSellerOrders()
          : await ApiService.getStudentOrders();
      _orders = fetched;
      _error = null;
    } catch (e) {
      _error = e.toString();
    }
    notifyListeners();
  }

  Future<bool> placeOrder({
    required List<CartItem> cartItems,
    required AppUser student,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Group by shop
      final byShop = <String, List<CartItem>>{};
      for (final item in cartItems) {
        byShop.putIfAbsent(item.menuItem.shop, () => []).add(item);
      }

      for (final entry in byShop.entries) {
        final shopItems = entry.value;
        final total = shopItems.fold<double>(0, (s, i) => s + i.total);
        final estimated = _calculateEstimatedTime(shopItems);

        await ApiService.placeOrder({
          'shopId': entry.key,
          'items': shopItems
              .map((i) => {
                    'menuItemId': i.menuItem.id,
                    'name': i.menuItem.name,
                    'price': i.menuItem.discountedPrice,
                    'quantity': i.quantity,
                    'shop': i.menuItem.shop,
                  })
              .toList(),
          'total': total,
          'estimatedMinutes': estimated,
        });
      }

      await fetchOrders();
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateStatus(String orderId, String status,
      {String? cancelReason}) async {
    try {
      await ApiService.updateOrderStatus(orderId, status,
          cancelReason: cancelReason);
      await fetchOrders();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  int _calculateEstimatedTime(List<CartItem> items) {
    int base = 3;
    for (final item in items) {
      base += item.menuItem.preparationTime;
    }
    final totalQty = items.fold(0, (s, i) => s + i.quantity);
    if (totalQty > 6) base += 4;
    else if (totalQty > 3) base += 2;

    final hour = DateTime.now().hour;
    final minute = DateTime.now().minute;
    final isPeak = (hour == 8 && minute >= 30) ||
        (hour == 9 && minute < 15) ||
        (hour >= 11 && hour < 14) ||
        (hour >= 17 && hour < 19);
    if (isPeak) base += 5;

    return base;
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }
}
