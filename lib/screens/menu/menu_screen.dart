import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../app.dart';
import '../../models/shop.dart';
import '../../providers/menu_provider.dart';
import '../../widgets/menu_item_card.dart';

class MenuScreen extends StatefulWidget {
  const MenuScreen({super.key});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  Shop? _selectedShop; // null = show shop list

  @override
  Widget build(BuildContext context) {
    if (_selectedShop != null) {
      return _ShopMenuView(
        shop: _selectedShop!,
        onBack: () => setState(() => _selectedShop = null),
      );
    }

    return _ShopListView(
      onShopTap: (shop) => setState(() => _selectedShop = shop),
    );
  }
}

// ─────────────────────── SHOP LIST (HOME) ────────────────────────────────────

class _ShopListView extends StatefulWidget {
  final void Function(Shop shop) onShopTap;
  const _ShopListView({required this.onShopTap});

  @override
  State<_ShopListView> createState() => _ShopListViewState();
}

class _ShopListViewState extends State<_ShopListView> {
  String _searchQuery = '';
  String _campus = 'All';

  @override
  Widget build(BuildContext context) {
    final menu = context.watch<MenuProvider>();

    final shops = menu.allShops.where((s) {
      if (_campus != 'All' && s.campus != _campus) return false;
      if (_searchQuery.isNotEmpty &&
          !s.name.toLowerCase().contains(_searchQuery.toLowerCase())) {
        return false;
      }
      return true;
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Search
              TextField(
                decoration: InputDecoration(
                  hintText: 'Search shops...',
                  hintStyle: TextStyle(color: Colors.grey.shade400),
                  prefixIcon:
                      Icon(Icons.search, color: Colors.grey.shade400),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: BorderSide(color: Colors.grey.shade200),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: BorderSide(color: Colors.grey.shade200),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: BorderSide(color: kOrange),
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
                ),
                onChanged: (v) => setState(() => _searchQuery = v),
              ),
              const SizedBox(height: 12),

              // Campus filter
              Row(
                children: [
                  _Chip(
                    label: 'All',
                    selected: _campus == 'All',
                    onTap: () => setState(() => _campus = 'All'),
                  ),
                  const SizedBox(width: 8),
                  _Chip(
                    label: '🎓 RUPP',
                    selected: _campus == 'RUPP',
                    onTap: () => setState(() => _campus = 'RUPP'),
                  ),
                  const SizedBox(width: 8),
                  _Chip(
                    label: '📚 IFL',
                    selected: _campus == 'IFL',
                    onTap: () => setState(() => _campus = 'IFL'),
                  ),
                ],
              ),
            ],
          ),
        ),

        // Section title
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            children: [
              const Text('Shops',
                  style: TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(width: 8),
              Text('(${shops.length})',
                  style: const TextStyle(
                      fontSize: 14, color: Colors.grey)),
            ],
          ),
        ),

        // Shop grid
        Expanded(
          child: menu.isLoading
              ? const Center(child: CircularProgressIndicator())
              : shops.isEmpty
                  ? const Center(
                      child: Text('No shops found',
                          style: TextStyle(color: Colors.grey)))
                  : RefreshIndicator(
                      onRefresh: menu.refresh,
                      child: GridView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
                          childAspectRatio: 0.9,
                        ),
                        itemCount: shops.length,
                        itemBuilder: (_, i) => _ShopCard(
                          shop: shops[i],
                          itemCount: context
                              .read<MenuProvider>()
                              .getItemsForShop(shops[i].id)
                              .length,
                          onTap: () => widget.onShopTap(shops[i]),
                        ),
                      ),
                    ),
        ),
      ],
    );
  }
}

class _ShopCard extends StatelessWidget {
  final Shop shop;
  final int itemCount;
  final VoidCallback onTap;

  const _ShopCard({
    required this.shop,
    required this.itemCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = [
      const Color(0xFFFFF3E0),
      const Color(0xFFE8F5E9),
      const Color(0xFFE3F2FD),
      const Color(0xFFFCE4EC),
      const Color(0xFFF3E5F5),
    ];
    final color = colors[shop.name.hashCode % colors.length];

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Shop image area / banner
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(16)),
                ),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.storefront,
                          size: 48, color: kOrange.withValues(alpha: 0.7)),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: kOrange.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          shop.campus,
                          style: const TextStyle(
                              fontSize: 10,
                              color: kOrange,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Shop info
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    shop.name,
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.bold),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    shop.description.isNotEmpty
                        ? shop.description
                        : '$itemCount items available',
                    style: const TextStyle(
                        fontSize: 11, color: Colors.grey),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(Icons.restaurant_menu,
                          size: 11, color: Colors.grey.shade400),
                      const SizedBox(width: 3),
                      Text('$itemCount items',
                          style: const TextStyle(
                              fontSize: 11, color: Colors.grey)),
                      const Spacer(),
                      Icon(Icons.arrow_forward_ios,
                          size: 11, color: Colors.grey.shade400),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────── SHOP MENU VIEW ──────────────────────────────────────

class _ShopMenuView extends StatefulWidget {
  final Shop shop;
  final VoidCallback onBack;

  const _ShopMenuView({required this.shop, required this.onBack});

  @override
  State<_ShopMenuView> createState() => _ShopMenuViewState();
}

class _ShopMenuViewState extends State<_ShopMenuView> {
  String _searchQuery = '';
  String _selectedCategory = 'All';
  bool _healthyOnly = false;
  bool _specialsOnly = false;

  @override
  Widget build(BuildContext context) {
    final menu = context.watch<MenuProvider>();
    final allItems = menu.getItemsForShop(widget.shop.id);

    final categories = ['All', ...allItems.map((i) => i.category).toSet()
        .where((c) => c.isNotEmpty).toList()..sort()];

    final filtered = allItems.where((item) {
      if (_searchQuery.isNotEmpty &&
          !item.name.toLowerCase().contains(_searchQuery.toLowerCase())) {
        return false;
      }
      if (_selectedCategory != 'All' && item.category != _selectedCategory) {
        return false;
      }
      if (_healthyOnly && !item.isHealthy) return false;
      if (_specialsOnly && !item.isSpecial) return false;
      return true;
    }).toList();

    return Column(
      children: [
        // Header
        Container(
          color: Colors.white,
          child: Column(
            children: [
              // Back + shop name
              Padding(
                padding: const EdgeInsets.fromLTRB(4, 8, 16, 4),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: widget.onBack,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.shop.name,
                            style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold),
                          ),
                          Text(
                            widget.shop.campus,
                            style: const TextStyle(
                                fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                    Row(
                      children: [
                        _IconChip(
                          icon: Icons.eco,
                          color: kGreen,
                          selected: _healthyOnly,
                          onTap: () =>
                              setState(() => _healthyOnly = !_healthyOnly),
                          label: 'Healthy',
                        ),
                        const SizedBox(width: 6),
                        _IconChip(
                          icon: Icons.local_offer,
                          color: kOrange,
                          selected: _specialsOnly,
                          onTap: () => setState(
                              () => _specialsOnly = !_specialsOnly),
                          label: 'Deals',
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Search
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Search in ${widget.shop.name}...',
                    hintStyle: TextStyle(color: Colors.grey.shade400),
                    prefixIcon:
                        Icon(Icons.search, color: Colors.grey.shade400),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide(color: Colors.grey.shade200),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide(color: Colors.grey.shade200),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide(color: kOrange),
                    ),
                    contentPadding:
                        const EdgeInsets.symmetric(vertical: 10),
                  ),
                  onChanged: (v) => setState(() => _searchQuery = v),
                ),
              ),

              // Category chips
              if (categories.length > 1)
                SizedBox(
                  height: 38,
                  child: ListView.separated(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16),
                    scrollDirection: Axis.horizontal,
                    itemCount: categories.length,
                    separatorBuilder: (_, s) => const SizedBox(width: 8),
                    itemBuilder: (_, i) {
                      final cat = categories[i];
                      return _Chip(
                        label: cat,
                        selected: _selectedCategory == cat,
                        onTap: () =>
                            setState(() => _selectedCategory = cat),
                      );
                    },
                  ),
                ),
              const SizedBox(height: 8),
            ],
          ),
        ),

        // Items
        Expanded(
          child: filtered.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.search_off,
                          size: 64, color: Colors.grey.shade300),
                      const SizedBox(height: 8),
                      const Text('No items found',
                          style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 8),
                  itemCount: filtered.length,
                  itemBuilder: (ctx, i) =>
                      MenuItemCard(item: filtered[i]),
                ),
        ),
      ],
    );
  }
}

// ─────────────────────── SHARED CHIPS ────────────────────────────────────────

class _Chip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _Chip(
      {required this.label,
      required this.selected,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? kOrange : Colors.white,
          borderRadius: BorderRadius.circular(30),
          border:
              Border.all(color: selected ? kOrange : Colors.grey.shade300),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight:
                selected ? FontWeight.bold : FontWeight.normal,
            color: selected ? Colors.white : Colors.black87,
          ),
        ),
      ),
    );
  }
}

class _IconChip extends StatelessWidget {
  final IconData icon;
  final Color color;
  final bool selected;
  final VoidCallback onTap;
  final String label;

  const _IconChip({
    required this.icon,
    required this.color,
    required this.selected,
    required this.onTap,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.15) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: selected ? color : Colors.grey.shade300),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: selected ? color : Colors.grey),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                  fontSize: 11,
                  color: selected ? color : Colors.grey,
                  fontWeight: selected
                      ? FontWeight.bold
                      : FontWeight.normal),
            ),
          ],
        ),
      ),
    );
  }
}
