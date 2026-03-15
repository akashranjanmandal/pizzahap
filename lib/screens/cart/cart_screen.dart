import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/providers.dart';
import '../../config/app_config.dart';
import '../../widgets/widgets.dart';
import '../../services/api_service.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});
  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final _couponCtrl = TextEditingController();
  bool _validatingCoupon = false;

  @override
  void dispose() { _couponCtrl.dispose(); super.dispose(); }

  Future<void> _validateCoupon() async {
    final cart = context.read<CartProvider>();
    if (_couponCtrl.text.trim().isEmpty) return;
    setState(() => _validatingCoupon = true);
    try {
      final coupon = await ApiService.validateCoupon(_couponCtrl.text.trim(), cart.subtotal);
      if (!mounted) return;
      cart.applyCoupon(coupon);
      showSnack(context, '🎉 Coupon applied! You save ₹${coupon.calculatedDiscount?.toStringAsFixed(0)}');
    } on ApiException catch (e) {
      if (!mounted) return;
      showSnack(context, e.message, isError: true);
    } finally {
      if (mounted) setState(() => _validatingCoupon = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();

    if (cart.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Cart')),
        body: EmptyState(
          emoji: '🛒',
          title: 'Your cart is empty',
          subtitle: 'Add some delicious pizzas to get started!',
          buttonText: 'Browse Menu',
          onButton: () => Navigator.pushNamed(context, '/menu'),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(AppColors.background),
      appBar: AppBar(
        title: const Text('Cart'),
        actions: [
          TextButton(
            onPressed: () {
              showDialog(
                context: context,
                builder: (_) => AlertDialog(
                  title: const Text('Clear Cart?'),
                  content: const Text('Remove all items from cart?'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                    TextButton(
                      onPressed: () { cart.clear(); Navigator.pop(context); },
                      child: const Text('Clear', style: TextStyle(color: Color(AppColors.error))),
                    ),
                  ],
                ),
              );
            },
            child: const Text('Clear', style: TextStyle(color: Color(AppColors.error))),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Cart items
                ...cart.items.asMap().entries.map((entry) {
                  final idx = entry.key;
                  final item = entry.value;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)],
                    ),
                    child: Row(
                      children: [
                        PizzaNetImage(
                          url: item.product.imageUrl, width: 72, height: 72,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  VegBadge(isVeg: item.product.isVeg),
                                  const SizedBox(width: 6),
                                  Expanded(child: Text(item.product.name,
                                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                                    maxLines: 1, overflow: TextOverflow.ellipsis)),
                                ],
                              ),
                              const SizedBox(height: 3),
                              Text(item.size.sizeName, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                              if (item.crust != null)
                                Text(item.crust!.name, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                              if (item.selectedToppings.isNotEmpty)
                                Text(item.selectedToppings.map((t) => t.name).join(', '),
                                  style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
                                  maxLines: 1, overflow: TextOverflow.ellipsis),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('₹${item.totalPrice.toStringAsFixed(0)}',
                                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: Color(AppColors.primary))),
                                  QuantityStepper(
                                    value: item.quantity,
                                    onDecrement: () => cart.updateQuantity(idx, item.quantity - 1),
                                    onIncrement: () => cart.updateQuantity(idx, item.quantity + 1),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        GestureDetector(
                          onTap: () => cart.removeItem(idx),
                          child: const Padding(
                            padding: EdgeInsets.only(left: 8, top: 4),
                            child: Icon(Icons.delete_outline, color: Color(AppColors.error), size: 20),
                          ),
                        ),
                      ],
                    ),
                  );
                }),

                // Coupon
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)],
                  ),
                  child: cart.appliedCoupon != null
                    ? Row(
                        children: [
                          const Text('🎫', style: TextStyle(fontSize: 20)),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(cart.appliedCoupon!.code,
                                  style: const TextStyle(fontWeight: FontWeight.w800, color: Color(AppColors.success))),
                                Text('You save ₹${cart.appliedCoupon!.calculatedDiscount?.toStringAsFixed(0)}',
                                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                              ],
                            ),
                          ),
                          TextButton(
                            onPressed: () { cart.removeCoupon(); _couponCtrl.clear(); },
                            child: const Text('Remove', style: TextStyle(color: Color(AppColors.error))),
                          ),
                        ],
                      )
                    : Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _couponCtrl,
                              textCapitalization: TextCapitalization.characters,
                              decoration: const InputDecoration(
                                hintText: 'Enter coupon code',
                                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                isDense: true,
                                prefixIcon: Icon(Icons.local_offer_outlined, size: 18, color: Color(AppColors.primary)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: _validatingCoupon ? null : _validateCoupon,
                            style: ElevatedButton.styleFrom(
                              minimumSize: const Size(80, 44),
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                            ),
                            child: _validatingCoupon
                              ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                              : const Text('Apply'),
                          ),
                        ],
                      ),
                ),
                const SizedBox(height: 12),

                // Also show coupon browse link
                GestureDetector(
                  onTap: () => Navigator.pushNamed(context, '/coupons'),
                  child: const Row(
                    children: [
                      Icon(Icons.discount_outlined, size: 14, color: Color(AppColors.primary)),
                      SizedBox(width: 4),
                      Text('Browse available coupons',
                        style: TextStyle(color: Color(AppColors.primary), fontSize: 13, fontWeight: FontWeight.w600,
                          decoration: TextDecoration.underline)),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Bill summary
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Bill Summary', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                      const SizedBox(height: 12),
                      PriceRow(label: 'Subtotal', amount: cart.subtotal),
                      if (cart.discount > 0) ...[
                        const SizedBox(height: 6),
                        PriceRow(label: 'Discount', amount: -cart.discount, color: const Color(AppColors.success)),
                      ],
                      const SizedBox(height: 6),
                      PriceRow(label: 'Delivery Fee', amount: cart.deliveryFee),
                      const SizedBox(height: 6),
                      PriceRow(label: 'Tax (5%)', amount: cart.tax),
                      const Divider(height: 20),
                      PriceRow(label: 'Total', amount: cart.total, isBold: true),
                    ],
                  ),
                ),
                const SizedBox(height: 100),
              ],
            ),
          ),
          // Checkout bar
          Container(
            padding: EdgeInsets.fromLTRB(16, 12, 16, MediaQuery.of(context).padding.bottom + 12),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 16, offset: const Offset(0, -4))],
            ),
            child: ElevatedButton(
              onPressed: () => Navigator.pushNamed(context, '/checkout'),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Proceed to Checkout', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                  const SizedBox(width: 8),
                  Text('₹${cart.total.toStringAsFixed(0)}',
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
