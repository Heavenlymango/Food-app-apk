import 'package:flutter/foundation.dart';
import '../models/menu_item.dart';
import '../models/shop.dart';
import '../data/menu_data.dart' as local;
import '../services/api_service.dart';

class MenuProvider extends ChangeNotifier {
  List<MenuItem> _allItems = List.from(local.menuItems);
  List<Shop> _allShops = List.from(local.shops);

  bool _isLoading = false;
  bool _loadedFromApi = false;

  String _searchQuery = '';
  String _selectedCampus = 'All';
  String _selectedShop = 'All';
  String _selectedCategory = 'All';
  bool _showHealthyOnly = false;
  bool _showSpecialsOnly = false;

  bool get isLoading => _isLoading;
  bool get loadedFromApi => _loadedFromApi;
  String get searchQuery => _searchQuery;
  String get selectedCampus => _selectedCampus;
  String get selectedShop => _selectedShop;
  String get selectedCategory => _selectedCategory;
  bool get showHealthyOnly => _showHealthyOnly;
  bool get showSpecialsOnly => _showSpecialsOnly;

  List<Shop> get allShops => _allShops;
  List<String> get campuses => ['All', 'RUPP', 'IFL'];

  List<String> get categories {
    final cats = _allItems.map((i) => i.category).toSet().toList()..sort();
    return ['All', ...cats];
  }

  List<Shop> get filteredShops {
    if (_selectedCampus == 'All') return _allShops;
    return _allShops.where((s) => s.campus == _selectedCampus).toList();
  }

  List<MenuItem> get filteredItems {
    return _allItems.where((item) {
      if (_searchQuery.isNotEmpty &&
          !item.name.toLowerCase().contains(_searchQuery.toLowerCase()) &&
          !item.description.toLowerCase().contains(_searchQuery.toLowerCase())) {
        return false;
      }
      if (_selectedCampus != 'All') {
        final shop = _allShops.firstWhere(
          (s) => s.id == item.shop,
          orElse: () => const Shop(
              id: '', name: '', description: '',
              healthyCount: 0, totalItems: 0, campus: ''),
        );
        if (shop.campus != _selectedCampus) return false;
      }
      if (_selectedShop != 'All' && item.shop != _selectedShop) return false;
      if (_selectedCategory != 'All' && item.category != _selectedCategory) return false;
      if (_showHealthyOnly && !item.isHealthy) return false;
      if (_showSpecialsOnly && !item.isSpecial) return false;
      return true;
    }).toList();
  }

  List<MenuItem> getItemsForShop(String shopId) =>
      _allItems.where((i) => i.shop == shopId).toList();

  List<MenuItem> searchByKeywords(List<String> keywords) {
    if (keywords.isEmpty) return [];
    return _allItems.where((item) {
      final nameLower = item.name.toLowerCase();
      final catLower = item.category.toLowerCase();
      return keywords.any((k) =>
          nameLower.contains(k.toLowerCase()) ||
          catLower.contains(k.toLowerCase()));
    }).toList();
  }

  /// Fetch live shops + menu items from the Supabase Edge Function.
  /// Falls back silently to the bundled local data on any error.
  Future<void> fetchFromApi() async {
    if (_isLoading) return;
    _isLoading = true;
    notifyListeners();

    try {
      final results = await Future.wait([
        ApiService.getPublicShops(),
        ApiService.getPublicMenu(),
      ]);

      final shopData = results[0];
      final itemData = results[1];

      if (shopData.isNotEmpty) {
        _allShops = shopData.map(Shop.fromJson).toList();
      }
      if (itemData.isNotEmpty) {
        _allItems = itemData.map(MenuItem.fromJson).toList();
        _loadedFromApi = true;
      }
    } catch (_) {
      // keep local data on error
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refresh() => fetchFromApi();

  void setSearch(String query) { _searchQuery = query; notifyListeners(); }
  void setCampus(String campus) { _selectedCampus = campus; _selectedShop = 'All'; notifyListeners(); }
  void setShop(String shop) { _selectedShop = shop; notifyListeners(); }
  void setCategory(String category) { _selectedCategory = category; notifyListeners(); }
  void setHealthyOnly(bool value) { _showHealthyOnly = value; notifyListeners(); }
  void setSpecialsOnly(bool value) { _showSpecialsOnly = value; notifyListeners(); }

  void clearFilters() {
    _searchQuery = '';
    _selectedCampus = 'All';
    _selectedShop = 'All';
    _selectedCategory = 'All';
    _showHealthyOnly = false;
    _showSpecialsOnly = false;
    notifyListeners();
  }
}
