import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/providers.dart';
import '../../config/app_config.dart';
import '../../widgets/widgets.dart';
import '../../services/api_service.dart';

class CartScreen extends StatefulWidget {
  // autoCoupon is passed when navigating from the Coupons screen
  final String? autoCoupon;
  const CartScreen({super.key, this.autoCoupon});
  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final _couponCtrl = TextEditingController();
  bool _validatingCoupon = false;

  @override
  void initState() {
    super.initState();
    // If an autoCoupon was passed, pre-fill & validate it
    if (widget.autoCoupon != null && widget.autoCoupon!.isNotEmpty) {
      _couponCtrl.text = widget.autoCoupon!;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _validateCoupon();
      });
    }
  }

  @override
  void dispose() {
    _couponCtrl.dispose();
    super.dispose();
  }

  Future<void> _validateCoupon() async {
    final cart = context.read<CartProvider>();
    if (_couponCtrl.text.trim().isEmpty) return;
    setState(() => _validatingCoupon = true);
    try {
      final coupon =
          await ApiService.validateCoupon(_couponCtrl.text.trim(), cart.subtotal);
      if (!mounted) return;
      cart.applyCoupon(coupon);
      showSnack(context,
          '🎉 Coupon applied! You save ₹${coupon.calculatedDiscount?.toStringAsFixed(0)}');
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
        backgroundColor: const Color(AppColors.background),
        appBar: AppBar(
          // Only show back button if this is a pushed route, not a shell tab
          automaticallyImplyLeading: ModalRoute.of(context)?.canPop ?? false,
          title: const Text('My Cart'),
        ),
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
        automaticallyImplyLeading: ModalRoute.of(context)?.canPop ?? false,
        title: Text('Cart (${cart.itemCount} items)'),
        actions: [
          TextButton.icon(
            onPressed: () => _showClearDialog(cart),
            icon: const Icon(Icons.delete_outline, size: 18),
            label: const Text('Clear'),
            style: TextButton.styleFrom(
                foregroundColor: const Color(AppColors.error)),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
              children: [
                // Cart items
                ...cart.items.asMap().entries.map((entry) {
                  final idx = entry.key;
                  final item = entry.value;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 8)
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: PizzaNetImage(
                                url: item.product.imageUrl,
                                width: 72,
                                height: 72),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    VegBadge(isVeg: item.product.isVeg),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(item.product.name,
                                          style: const TextStyle(
                                              fontWeight: FontWeight.w700,
                                              fontSize: 14),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis),
                                    ),
                                    const SizedBox(width: 4),
                                    GestureDetector(
                                      onTap: () => cart.removeItem(idx),
                                      child: Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: BoxDecoration(
                                          color: const Color(AppColors.error)
                                              .withOpacity(0.08),
                                          borderRadius:
                                              BorderRadius.circular(6),
                                        ),
                                        child: const Icon(
                                            Icons.close_rounded,
                                            color: Color(AppColors.error),
                                            size: 16),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 3),
                                Text(item.size.sizeName,
                                    style: TextStyle(
                                        color: Colors.grey.shade600,
                                        fontSize: 12)),
                                if (item.crust != null)
                                  Text('${item.crust!.name} crust',
                                      style: TextStyle(
                                          color: Colors.grey.shade600,
                                          fontSize: 12)),
                                if (item.selectedToppings.isNotEmpty)
                                  Text(
                                      '+${item.selectedToppings.map((t) => t.name).join(', ')}',
                                      style: TextStyle(
                                          color: Colors.grey.shade500,
                                          fontSize: 11),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis),
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                        '₹${item.totalPrice.toStringAsFixed(0)}',
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w800,
                                            fontSize: 15,
                                            color:
                                                Color(AppColors.primary))),
                                    QuantityStepper(
                                      value: item.quantity,
                                      onDecrement: () => cart.updateQuantity(
                                          idx, item.quantity - 1),
                                      onIncrement: () => cart.updateQuantity(
                                          idx, item.quantity + 1),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),

                const SizedBox(height: 4),

                // Coupon section
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 8)
                    ],
                  ),
                  child: cart.appliedCoupon != null
                      ? Row(
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: const Color(AppColors.success)
                                    .withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.local_offer_rounded,
                                  color: Color(AppColors.success), size: 18),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(cart.appliedCoupon!.code,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w800,
                                          color: Color(AppColors.success),
                                          fontSize: 14)),
                                  Text(
                                      'Saving ₹${cart.appliedCoupon!.calculatedDiscount?.toStringAsFixed(0)}',
                                      style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey.shade600)),
                                ],
                              ),
                            ),
                            TextButton(
                              onPressed: () {
                                cart.removeCoupon();
                                _couponCtrl.clear();
                              },
                              style: TextButton.styleFrom(
                                  foregroundColor:
                                      const Color(AppColors.error)),
                              child: const Text('Remove'),
                            ),
                          ],
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(children: [
                              Icon(Icons.local_offer_outlined,
                                  size: 16, color: Color(AppColors.primary)),
                              SizedBox(width: 6),
                              Text('Have a coupon?',
                                  style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 14)),
                            ]),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: _couponCtrl,
                                    textCapitalization:
                                        TextCapitalization.characters,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 1),
                                    decoration: const InputDecoration(
                                      hintText: 'ENTER CODE',
                                      contentPadding: EdgeInsets.symmetric(
                                          horizontal: 12, vertical: 10),
                                      isDense: true,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                SizedBox(
                                  height: 44,
                                  child: ElevatedButton(
                                    onPressed: _validatingCoupon
                                        ? null
                                        : _validateCoupon,
                                    style: ElevatedButton.styleFrom(
                                      minimumSize: Size.zero,
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 20),
                                    ),
                                    child: _validatingCoupon
                                        ? const SizedBox(
                                            height: 16,
                                            width: 16,
                                            child: CircularProgressIndicator(
                                                color: Colors.white,
                                                strokeWidth: 2))
                                        : const Text('Apply'),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            GestureDetector(
                              onTap: () =>
                                  Navigator.pushNamed(context, '/coupons'),
                              child: const Row(children: [
                                Icon(Icons.discount_outlined,
                                    size: 13, color: Color(AppColors.primary)),
                                SizedBox(width: 4),
                                Text('Browse coupons',
                                    style: TextStyle(
                                        color: Color(AppColors.primary),
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        decoration: TextDecoration.underline)),
                              ]),
                            ),
                          ],
                        ),
                ),

                const SizedBox(height: 10),

                // Bill summary
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 8)
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(children: [
                        Icon(Icons.receipt_long_outlined,
                            size: 18,
                            color: Color(AppColors.textPrimary)),
                        SizedBox(width: 8),
                        Text('Bill Summary',
                            style: TextStyle(
                                fontWeight: FontWeight.w800, fontSize: 16)),
                      ]),
                      const SizedBox(height: 14),
                      PriceRow(label: 'Subtotal', amount: cart.subtotal),
                      if (cart.discount > 0) ...[
                        const SizedBox(height: 6),
                        PriceRow(
                            label:
                                'Discount (${cart.appliedCoupon?.code ?? ''})',
                            amount: -cart.discount,
                            color: const Color(AppColors.success)),
                      ],
                      const SizedBox(height: 6),
                      PriceRow(
                        label: cart.deliveryType == 'pickup'
                            ? 'Delivery Fee (Pickup)'
                            : cart.deliveryFee == 0
                                ? 'Delivery Fee (Free!)'
                                : 'Delivery Fee',
                        amount: cart.deliveryFee,
                        color: cart.deliveryFee == 0
                            ? const Color(AppColors.success)
                            : null,
                      ),
                      const SizedBox(height: 6),
                      PriceRow(label: 'Tax (5%)', amount: cart.tax),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Divider(color: Colors.grey.shade100),
                      ),
                      PriceRow(
                          label: 'Total', amount: cart.total, isBold: true),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Checkout button bar
          Container(
            padding: EdgeInsets.fromLTRB(
              16,
              12,
              16,
              MediaQuery.of(context).padding.bottom + 12,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 16,
                    offset: const Offset(0, -4))
              ],
            ),
            child: ElevatedButton(
              onPressed: () => Navigator.pushNamed(context, '/checkout'),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.shopping_bag_outlined, size: 18),
                  const SizedBox(width: 8),
                  const Text('Proceed to Checkout',
                      style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w700)),
                  const SizedBox(width: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.25),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text('₹${cart.total.toStringAsFixed(0)}',
                        style: const TextStyle(
                            fontWeight: FontWeight.w800, fontSize: 14)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showClearDialog(CartProvider cart) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: const Color(AppColors.error).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.delete_outline_rounded,
                    color: Color(AppColors.error), size: 26),
              ),
              const SizedBox(height: 14),
              const Text('Clear Cart?',
                  style: TextStyle(
                      fontWeight: FontWeight.w800, fontSize: 18)),
              const SizedBox(height: 8),
              Text('Remove all ${cart.itemCount} items from cart?',
                  style: TextStyle(
                      color: Colors.grey.shade600, fontSize: 14),
                  textAlign: TextAlign.center),
              const SizedBox(height: 20),
              Row(children: [
                Expanded(
                    child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel'))),
                const SizedBox(width: 12),
                Expanded(
                    child: ElevatedButton(
                  onPressed: () {
                    cart.clear();
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(AppColors.error)),
                  child: const Text('Clear'),
                )),
              ]),
            ],
          ),
        ),
      ),
    );
  }
}
