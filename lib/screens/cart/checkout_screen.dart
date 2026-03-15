import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/providers.dart';
import '../../config/app_config.dart';
import '../../services/api_service.dart';
import '../../widgets/widgets.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});
  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  String _deliveryType = 'delivery';
  String _paymentMethod = 'cash_on_delivery';
  final _addressCtrl = TextEditingController();
  final _instructionsCtrl = TextEditingController();
  bool _placingOrder = false;

  @override
  void dispose() {
    _addressCtrl.dispose();
    _instructionsCtrl.dispose();
    super.dispose();
  }

  Future<void> _placeOrder() async {
    final cart = context.read<CartProvider>();

    if (cart.selectedLocationId == null) {
      showSnack(context, 'No branch selected. Please restart and pick a branch.', isError: true);
      return;
    }
    if (_deliveryType == 'delivery' && _addressCtrl.text.trim().isEmpty) {
      showSnack(context, 'Please enter your delivery address', isError: true);
      return;
    }

    setState(() => _placingOrder = true);
    final orderProvider = context.read<OrderProvider>();

    final orderData = <String, dynamic>{
      'items': cart.toOrderItems(),
      'location_id': cart.selectedLocationId,
      'delivery_type': _deliveryType,
      if (_deliveryType == 'delivery') 'delivery_address': _addressCtrl.text.trim(),
      if (cart.couponCode != null) 'coupon_code': cart.couponCode,
      if (_instructionsCtrl.text.trim().isNotEmpty)
        'special_instructions': _instructionsCtrl.text.trim(),
      'payment_method': _paymentMethod,
    };

    final result = await orderProvider.placeOrder(orderData);
    setState(() => _placingOrder = false);
    if (!mounted) return;

    if (result != null) {
      final orderId = result['order_id'];
      try {
        await ApiService.createPaymentOrder(orderId, _paymentMethod);
      } catch (_) {}
      cart.clear();
      Navigator.pushNamedAndRemoveUntil(
        context, '/order-confirm', (r) => r.settings.name == '/home',
        arguments: {
          'order_id': orderId,
          'order_number': result['order_number'],
          'total': result['total_amount'],
        },
      );
    } else {
      showSnack(context, orderProvider.error ?? 'Failed to place order', isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    return LoadingOverlay(
      loading: _placingOrder,
      child: Scaffold(
        backgroundColor: const Color(AppColors.background),
        appBar: AppBar(title: const Text('Checkout')),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          children: [

            // ── Selected branch (read-only) ──────────────────────
            _SectionCard(
              title: '📍 Branch',
              child: Row(
                children: [
                  Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(
                      color: const Color(AppColors.primary).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.store_rounded, color: Color(AppColors.primary), size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          cart.selectedLocationName ?? 'No branch selected',
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                        ),
                        Text(
                          'Tap to change branch',
                          style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                        ),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pushNamed(context, '/branch-selection'),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      minimumSize: Size.zero,
                    ),
                    child: const Text('Change', style: TextStyle(fontSize: 12)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // ── Delivery type ────────────────────────────────────
            _SectionCard(
              title: '🚚 Delivery Type',
              child: Row(
                children: [
                  Expanded(child: _TypeButton(
                    label: '🛵 Delivery',
                    selected: _deliveryType == 'delivery',
                    onTap: () => setState(() => _deliveryType = 'delivery'),
                  )),
                  const SizedBox(width: 10),
                  Expanded(child: _TypeButton(
                    label: '🏪 Pickup',
                    selected: _deliveryType == 'pickup',
                    onTap: () => setState(() => _deliveryType = 'pickup'),
                  )),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // ── Delivery address ─────────────────────────────────
            if (_deliveryType == 'delivery') ...[
              _SectionCard(
                title: '🏠 Delivery Address',
                child: TextFormField(
                  controller: _addressCtrl,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    hintText: 'Enter your full delivery address',
                    contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],

            // ── Special instructions ─────────────────────────────
            _SectionCard(
              title: '📝 Special Instructions',
              subtitle: 'Optional',
              child: TextFormField(
                controller: _instructionsCtrl,
                maxLines: 2,
                decoration: const InputDecoration(
                  hintText: 'E.g. Extra spicy, no onions...',
                  contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // ── Payment method ───────────────────────────────────
            _SectionCard(
              title: '💳 Payment Method',
              child: Column(
                children: [
                  _PaymentOption(
                    value: 'cash_on_delivery',
                    selected: _paymentMethod,
                    title: '💵 Cash on Delivery',
                    subtitle: 'Pay when delivered',
                    onTap: () => setState(() => _paymentMethod = 'cash_on_delivery'),
                  ),
                  const SizedBox(height: 4),
                  _PaymentOption(
                    value: 'payu',
                    selected: _paymentMethod,
                    title: '🏦 Online Payment',
                    subtitle: 'UPI, Card, Net Banking',
                    onTap: () => setState(() => _paymentMethod = 'payu'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // ── Order summary ────────────────────────────────────
            _SectionCard(
              title: '🧾 Order Summary',
              child: Column(
                children: [
                  _SummaryRow(label: 'Subtotal (${cart.itemCount} items)', amount: cart.subtotal),
                  const SizedBox(height: 8),
                  if (cart.discount > 0) ...[
                    _SummaryRow(
                      label: 'Discount',
                      amount: -cart.discount,
                      color: const Color(AppColors.success),
                    ),
                    const SizedBox(height: 8),
                  ],
                  _SummaryRow(
                    label: _deliveryType == 'pickup' ? 'Pickup (free)' : 'Delivery Fee',
                    amount: cart.deliveryFee,
                    note: _deliveryType == 'delivery' && cart.subtotal >= 300 ? 'Free!' : null,
                  ),
                  const SizedBox(height: 8),
                  _SummaryRow(label: 'Tax (5%)', amount: cart.tax),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Divider(color: Colors.grey.shade200, height: 1),
                  ),
                  _SummaryRow(
                    label: 'Total',
                    amount: cart.total,
                    isBold: true,
                    fontSize: 16,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // ── Place order button ────────────────────────────────
            SizedBox(
              height: 54,
              child: ElevatedButton(
                onPressed: _placingOrder ? null : _placeOrder,
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: Text(
                  _paymentMethod == 'cash_on_delivery'
                    ? 'Place Order  •  ₹${cart.total.toStringAsFixed(0)}'
                    : 'Pay  ₹${cart.total.toStringAsFixed(0)}',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Reusable section card ──────────────────────────────────────────
class _SectionCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget child;
  const _SectionCard({required this.title, this.subtitle, required this.child});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
          if (subtitle != null) ...[
            const SizedBox(width: 6),
            Text(subtitle!, style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
          ],
        ]),
        const SizedBox(height: 12),
        child,
      ],
    ),
  );
}

class _TypeButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _TypeButton({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: selected ? const Color(AppColors.primary) : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Center(
        child: Text(label, style: TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 13,
          color: selected ? Colors.white : const Color(AppColors.textPrimary),
        )),
      ),
    ),
  );
}

class _PaymentOption extends StatelessWidget {
  final String value, selected, title, subtitle;
  final VoidCallback onTap;
  const _PaymentOption({
    required this.value, required this.selected,
    required this.title, required this.subtitle, required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = value == selected;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? const Color(AppColors.primary).withOpacity(0.05) : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? const Color(AppColors.primary) : Colors.grey.shade200,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(children: [
          Radio<String>(
            value: value, groupValue: selected,
            onChanged: (_) => onTap(),
            activeColor: const Color(AppColors.primary),
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            visualDensity: VisualDensity.compact,
          ),
          const SizedBox(width: 6),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
            Text(subtitle, style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
          ]),
        ]),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final double amount;
  final Color? color;
  final bool isBold;
  final double fontSize;
  final String? note;
  const _SummaryRow({
    required this.label, required this.amount,
    this.color, this.isBold = false, this.fontSize = 13, this.note,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? (amount < 0 ? const Color(AppColors.success) : const Color(AppColors.textPrimary));
    return Row(children: [
      Expanded(child: Text(label, style: TextStyle(
        fontSize: fontSize,
        fontWeight: isBold ? FontWeight.w800 : FontWeight.w500,
        color: isBold ? const Color(AppColors.textPrimary) : Colors.grey.shade700,
      ))),
      if (note != null) ...[
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: const Color(AppColors.success).withOpacity(0.1),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(note!, style: const TextStyle(color: Color(AppColors.success), fontSize: 10, fontWeight: FontWeight.w700)),
        ),
        const SizedBox(width: 8),
      ],
      Text(
        amount == 0 ? '₹0' : '${amount < 0 ? "-" : ""}₹${amount.abs().toStringAsFixed(0)}',
        style: TextStyle(fontSize: fontSize, fontWeight: isBold ? FontWeight.w800 : FontWeight.w600, color: c),
      ),
    ]);
  }
}
