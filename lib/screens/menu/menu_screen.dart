import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import '../../providers/providers.dart';
import '../../config/app_config.dart';
import '../../widgets/widgets.dart';

class MenuScreen extends StatefulWidget {
  final int? initialCategoryId;
  const MenuScreen({super.key, this.initialCategoryId});
  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  final _searchCtrl = TextEditingController();
  bool? _vegFilter;
  int? _selectedCategoryId;

  @override
  void initState() {
    super.initState();
    _selectedCategoryId = widget.initialCategoryId;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final menu = context.read<MenuProvider>();
      if (menu.categories.isEmpty) menu.loadHomeData();
      menu.loadProducts(categoryId: _selectedCategoryId);
    });
  }

  @override
  void dispose() { _searchCtrl.dispose(); super.dispose(); }

  void _applyFilters() {
    context.read<MenuProvider>().loadProducts(
      categoryId: _selectedCategoryId,
      isVeg: _vegFilter,
      search: _searchCtrl.text.trim().isEmpty ? null : _searchCtrl.text.trim(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final menu = context.watch<MenuProvider>();
    return Scaffold(
      backgroundColor: const Color(AppColors.background),
      appBar: AppBar(
        title: const Text('Menu'),
        actions: [
          IconButton(
            icon: Icon(
              _vegFilter == null ? Icons.eco_outlined
              : _vegFilter! ? Icons.eco : Icons.no_meals,
              color: _vegFilter == true ? const Color(AppColors.vegGreen) : null,
            ),
            onPressed: () {
              setState(() {
                if (_vegFilter == null) {
                  _vegFilter = true;
                } else if (_vegFilter == true) _vegFilter = false;
                else _vegFilter = null;
              });
              _applyFilters();
            },
            tooltip: 'Filter veg/non-veg',
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: 'Search menu...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchCtrl.text.isNotEmpty
                  ? IconButton(icon: const Icon(Icons.clear), onPressed: () {
                      _searchCtrl.clear();
                      _applyFilters();
                      setState(() {});
                    })
                  : null,
              ),
              onChanged: (_) {
                setState(() {});
                Future.delayed(const Duration(milliseconds: 400), _applyFilters);
              },
            ),
          ),

          // Category filter chips
          if (menu.categories.isNotEmpty)
            SizedBox(
              height: 52,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                itemCount: menu.categories.length + 1,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (ctx, i) {
                  if (i == 0) {
                    return FilterChip(
                      label: const Text('All'),
                      selected: _selectedCategoryId == null,
                      onSelected: (_) {
                        setState(() => _selectedCategoryId = null);
                        _applyFilters();
                      },
                      selectedColor: const Color(AppColors.primary).withOpacity(0.15),
                      checkmarkColor: const Color(AppColors.primary),
                    );
                  }
                  final c = menu.categories[i - 1];
                  return FilterChip(
                    label: Text(c.name),
                    selected: _selectedCategoryId == c.id,
                    onSelected: (_) {
                      setState(() => _selectedCategoryId = _selectedCategoryId == c.id ? null : c.id);
                      _applyFilters();
                    },
                    selectedColor: const Color(AppColors.primary).withOpacity(0.15),
                    checkmarkColor: const Color(AppColors.primary),
                  );
                },
              ),
            ),

          // Veg filter banner
          if (_vegFilter != null)
            Container(
              margin: const EdgeInsets.fromLTRB(16, 4, 16, 0),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _vegFilter! ? const Color(AppColors.vegGreen).withOpacity(0.1) : const Color(AppColors.error).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.eco, color: _vegFilter! ? const Color(AppColors.vegGreen) : const Color(AppColors.error), size: 16),
                  const SizedBox(width: 6),
                  Text(
                    _vegFilter! ? 'Showing veg only' : 'Showing non-veg only',
                    style: TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w600,
                      color: _vegFilter! ? const Color(AppColors.vegGreen) : const Color(AppColors.error),
                    ),
                  ),
                ],
              ),
            ),

          // Products grid
          Expanded(
            child: menu.loading
              ? _buildShimmer()
              : menu.products.isEmpty
                ? const EmptyState(emoji: '🍕', title: 'No items found', subtitle: 'Try adjusting your filters')
                : GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2, childAspectRatio: 0.72,
                      crossAxisSpacing: 12, mainAxisSpacing: 12,
                    ),
                    itemCount: menu.products.length,
                    itemBuilder: (ctx, i) {
                      final p = menu.products[i];
                      return ProductCard(
                        product: p,
                        onTap: () => Navigator.pushNamed(context, '/product', arguments: p.id),
                        onAddToCart: () => Navigator.pushNamed(context, '/product', arguments: p.id),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildShimmer() => GridView.builder(
    padding: const EdgeInsets.all(16),
    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: 2, childAspectRatio: 0.72, crossAxisSpacing: 12, mainAxisSpacing: 12,
    ),
    itemCount: 6,
    itemBuilder: (_, __) => Shimmer.fromColors(
      baseColor: Colors.grey.shade200,
      highlightColor: Colors.grey.shade100,
      child: Container(decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16))),
    ),
  );
}
