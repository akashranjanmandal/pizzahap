import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/providers.dart';
import '../../config/app_config.dart';
import '../../services/api_service.dart';
import '../../widgets/widgets.dart';
import '../../models/models.dart';

class ProductDetailScreen extends StatefulWidget {
  final int productId;
  const ProductDetailScreen({super.key, required this.productId});
  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  Product? _product;
  bool _loading = true;
  ProductSize? _selectedSize;
  CrustType? _selectedCrust;
  final Set<int> _selectedToppingIds = {};
  int _quantity = 1;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final p = await ApiService.getProduct(widget.productId);
      setState(() {
        _product = p;
        _selectedSize = p.sizes.isNotEmpty ? p.sizes.first : null;
        _selectedCrust = p.crusts.isNotEmpty ? p.crusts.first : null;
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  double get _totalPrice {
    if (_product == null || _selectedSize == null) return 0;
    double price = _selectedSize!.price;
    if (_selectedCrust != null) price += _selectedCrust!.extraPrice;
    for (final id in _selectedToppingIds) {
      final t = _product!.toppings.firstWhere((t) => t.id == id, orElse: () => Topping(id: 0, name: '', price: 0, isVeg: true, isAvailable: true));
      price += t.price;
    }
    return price * _quantity;
  }

  void _addToCart() {
    if (_product == null || _selectedSize == null) return;
    final cart = context.read<CartProvider>();
    final selectedToppings = _product!.toppings.where((t) => _selectedToppingIds.contains(t.id)).toList();
    cart.addItem(CartItem(
      product: _product!,
      size: _selectedSize!,
      crust: _selectedCrust,
      selectedToppings: selectedToppings,
      quantity: _quantity,
    ));
    showSnack(context, '${_product!.name} added to cart 🛒');
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Scaffold(body: Center(child: CircularProgressIndicator(color: Color(AppColors.primary))));
    if (_product == null) return const Scaffold(body: Center(child: Text('Product not found')));

    final p = _product!;
    return Scaffold(
      backgroundColor: const Color(AppColors.background),
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 280,
                pinned: true,
                backgroundColor: Colors.white,
                flexibleSpace: FlexibleSpaceBar(
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      PizzaNetImage(url: p.imageUrl, fit: BoxFit.cover),
                      // Gradient overlay
                      Positioned(
                        bottom: 0, left: 0, right: 0,
                        child: Container(
                          height: 80,
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.bottomCenter, end: Alignment.topCenter,
                              colors: [Color(AppColors.background), Colors.transparent],
                            ),
                          ),
                        ),
                      ),
                      Positioned(top: 16, left: 16, child: VegBadge(isVeg: p.isVeg)),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Container(
                  color: const Color(AppColors.background),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Name & rating
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(p.name, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
                                  if (p.categoryName != null)
                                    Text(p.categoryName!, style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                                ],
                              ),
                            ),
                            if (p.avgRating != null)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: const Color(AppColors.warning).withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Text('⭐', style: TextStyle(fontSize: 13)),
                                    const SizedBox(width: 4),
                                    Text(p.avgRating!.toStringAsFixed(1),
                                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                                    if (p.reviewCount != null)
                                      Text(' (${p.reviewCount})', style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                      if (p.description != null)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                          child: Text(p.description!, style: TextStyle(color: Colors.grey.shade600, fontSize: 14, height: 1.5)),
                        ),

                      // Size selector
                      if (p.sizes.isNotEmpty) ...[
                        _sectionTitle('Choose Size'),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Row(
                            children: p.sizes.map((size) {
                              final selected = _selectedSize?.id == size.id;
                              return Expanded(
                                child: GestureDetector(
                                  onTap: () => setState(() => _selectedSize = size),
                                  child: Container(
                                    margin: const EdgeInsets.symmetric(horizontal: 4),
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    decoration: BoxDecoration(
                                      color: selected ? const Color(AppColors.primary) : Colors.white,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: selected ? const Color(AppColors.primary) : Colors.grey.shade200,
                                        width: 1.5,
                                      ),
                                    ),
                                    child: Column(
                                      children: [
                                        Text(size.sizeName,
                                          style: TextStyle(
                                            fontWeight: FontWeight.w700, fontSize: 13,
                                            color: selected ? Colors.white : const Color(AppColors.textPrimary),
                                          )),
                                        const SizedBox(height: 2),
                                        Text('₹${size.price.toStringAsFixed(0)}',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w800, fontSize: 16,
                                            color: selected ? Colors.white : const Color(AppColors.primary),
                                          )),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ],

                      // Crust selector
                      if (p.crusts.isNotEmpty) ...[
                        _sectionTitle('Choose Crust'),
                        SizedBox(
                          height: 48,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: p.crusts.length,
                            separatorBuilder: (_, __) => const SizedBox(width: 8),
                            itemBuilder: (ctx, i) {
                              final c = p.crusts[i];
                              final sel = _selectedCrust?.id == c.id;
                              return GestureDetector(
                                onTap: () => setState(() => _selectedCrust = c),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: sel ? const Color(AppColors.primary) : Colors.white,
                                    borderRadius: BorderRadius.circular(24),
                                    border: Border.all(
                                      color: sel ? const Color(AppColors.primary) : Colors.grey.shade200,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(c.name, style: TextStyle(
                                        color: sel ? Colors.white : const Color(AppColors.textPrimary),
                                        fontWeight: FontWeight.w700, fontSize: 13,
                                      )),
                                      if (c.extraPrice > 0) ...[
                                        const SizedBox(width: 4),
                                        Text('+₹${c.extraPrice.toStringAsFixed(0)}',
                                          style: TextStyle(color: sel ? Colors.white70 : Colors.grey.shade500, fontSize: 11)),
                                      ],
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],

                      // Toppings
                      if (p.toppings.isNotEmpty) ...[
                        _sectionTitle('Add Toppings (Optional)'),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Wrap(
                            spacing: 8, runSpacing: 8,
                            children: p.toppings.map((t) {
                              final sel = _selectedToppingIds.contains(t.id);
                              return GestureDetector(
                                onTap: () => setState(() {
                                  sel ? _selectedToppingIds.remove(t.id) : _selectedToppingIds.add(t.id);
                                }),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: sel ? const Color(AppColors.primary).withOpacity(0.1) : Colors.white,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: sel ? const Color(AppColors.primary) : Colors.grey.shade200,
                                      width: sel ? 1.5 : 1,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      VegBadge(isVeg: t.isVeg),
                                      const SizedBox(width: 6),
                                      Text(t.name, style: TextStyle(
                                        fontSize: 12, fontWeight: FontWeight.w600,
                                        color: sel ? const Color(AppColors.primary) : const Color(AppColors.textPrimary),
                                      )),
                                      const SizedBox(width: 4),
                                      Text('+₹${t.price.toStringAsFixed(0)}',
                                        style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                                    ],
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ],

                      const SizedBox(height: 120),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // Bottom bar
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: Container(
              padding: EdgeInsets.fromLTRB(20, 16, 20, MediaQuery.of(context).padding.bottom + 16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 16, offset: const Offset(0, -4))],
              ),
              child: Row(
                children: [
                  // Quantity
                  QuantityStepper(
                    value: _quantity,
                    onDecrement: () { if (_quantity > 1) setState(() => _quantity--); },
                    onIncrement: () => setState(() => _quantity++),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _addToCart,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('Add to Cart'),
                          const SizedBox(width: 8),
                          Text('₹${_totalPrice.toStringAsFixed(0)}',
                            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) => Padding(
    padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
    child: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
  );
}
