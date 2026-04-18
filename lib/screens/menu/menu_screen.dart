import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../app.dart';
import '../../providers/menu_provider.dart';
import '../../widgets/menu_item_card.dart';

class MenuScreen extends StatelessWidget {
  const MenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final menu = context.watch<MenuProvider>();

    return Column(
      children: [
        Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Search
              TextField(
                decoration: InputDecoration(
                  hintText: 'Search menu...',
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
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
                ),
                onChanged: menu.setSearch,
              ),
              const SizedBox(height: 10),

              // Campus + special filters row
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _PillFilter(
                      label: 'All Campuses',
                      emoji: '🏫',
                      selected: menu.selectedCampus == 'All',
                      onTap: () => menu.setCampus('All'),
                    ),
                    const SizedBox(width: 6),
                    _PillFilter(
                      label: 'RUPP',
                      emoji: '🎓',
                      selected: menu.selectedCampus == 'RUPP',
                      onTap: () => menu.setCampus('RUPP'),
                    ),
                    const SizedBox(width: 6),
                    _PillFilter(
                      label: 'IFL',
                      emoji: '📚',
                      selected: menu.selectedCampus == 'IFL',
                      onTap: () => menu.setCampus('IFL'),
                    ),
                    const SizedBox(width: 6),
                    _PillFilter(
                      label: 'Healthy',
                      emoji: '🥗',
                      selected: menu.showHealthyOnly,
                      onTap: () =>
                          menu.setHealthyOnly(!menu.showHealthyOnly),
                    ),
                    const SizedBox(width: 6),
                    _PillFilter(
                      label: 'Specials',
                      emoji: '🍊',
                      selected: menu.showSpecialsOnly,
                      onTap: () =>
                          menu.setSpecialsOnly(!menu.showSpecialsOnly),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),

              // Shop filter row
              const Text('Select Shop:',
                  style: TextStyle(fontSize: 12, color: Colors.grey)),
              const SizedBox(height: 6),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _ShopPill(
                      label: 'All Shops',
                      selected: menu.selectedShop == 'All',
                      onTap: () => menu.setShop('All'),
                    ),
                    ...menu.filteredShops.map((shop) => Padding(
                          padding: const EdgeInsets.only(left: 6),
                          child: _ShopPill(
                            label: shop.name,
                            selected: menu.selectedShop == shop.id,
                            onTap: () => menu.setShop(shop.id),
                          ),
                        )),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Items list
        Expanded(
          child: menu.filteredItems.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
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
                  itemCount: menu.filteredItems.length,
                  itemBuilder: (ctx, i) =>
                      MenuItemCard(item: menu.filteredItems[i]),
                ),
        ),
      ],
    );
  }
}

class _PillFilter extends StatelessWidget {
  final String label;
  final String emoji;
  final bool selected;
  final VoidCallback onTap;

  const _PillFilter({
    required this.label,
    required this.emoji,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? kOrange : Colors.white,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
              color: selected ? kOrange : Colors.grey.shade300),
        ),
        child: Text(
          '$emoji $label',
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

class _ShopPill extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _ShopPill({
    required this.label,
    required this.selected,
    required this.onTap,
  });

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
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: selected ? kOrange : Colors.grey.shade300),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight:
                selected ? FontWeight.bold : FontWeight.normal,
            color: selected ? Colors.white : Colors.black87,
          ),
        ),
      ),
    );
  }
}
