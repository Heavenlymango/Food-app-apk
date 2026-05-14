import 'package:flutter/foundation.dart';
import '../models/cart_item.dart';
import '../models/menu_item.dart';

class CartProvider extends ChangeNotifier {
  final List<CartItem> _items = [];
  DateTime? _scheduledFor;

  List<CartItem> get items => List.unmodifiable(_items);
  int get itemCount => _items.fold(0, (sum, i) => sum + i.quantity);
  double get total => _items.fold(0.0, (sum, i) => sum + i.total);
  DateTime? get scheduledFor => _scheduledFor;
  bool get isReservation => _scheduledFor != null;

  bool contains(String menuItemId) =>
      _items.any((i) => i.menuItem.id == menuItemId);

  void addItem(MenuItem menuItem) {
    final idx = _items.indexWhere((i) => i.menuItem.id == menuItem.id);
    if (idx >= 0) {
      _items[idx].quantity++;
    } else {
      _items.add(CartItem(menuItem: menuItem));
    }
    notifyListeners();
  }

  void removeItem(String menuItemId) {
    final idx = _items.indexWhere((i) => i.menuItem.id == menuItemId);
    if (idx < 0) return;
    if (_items[idx].quantity > 1) {
      _items[idx].quantity--;
    } else {
      _items.removeAt(idx);
    }
    notifyListeners();
  }

  void deleteItem(String menuItemId) {
    _items.removeWhere((i) => i.menuItem.id == menuItemId);
    notifyListeners();
  }

  void setScheduledFor(DateTime? time) {
    _scheduledFor = time;
    notifyListeners();
  }

  void clear() {
    _items.clear();
    _scheduledFor = null;
    notifyListeners();
  }

  // Group items by shop for multi-shop orders
  Map<String, List<CartItem>> get itemsByShop {
    final map = <String, List<CartItem>>{};
    for (final item in _items) {
      map.putIfAbsent(item.menuItem.shop, () => []).add(item);
    }
    return map;
  }
}
