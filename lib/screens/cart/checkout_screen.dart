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

  // Structured address controllers
  final _houseCtrl        = TextEditingController();
  final _townCtrl         = TextEditingController();
  final _stateCtrl        = TextEditingController();
  final _pincodeCtrl      = TextEditingController();
  final _instructionsCtrl = TextEditingController();

  bool _placingOrder = false;
  bool _useCoins = false;

  @override
  void initState() {
    super.initState();
    // Pre-fill saved address from user profile
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = context.read<AuthProvider>().user;
      if (user != null) {
        _houseCtrl.text   = user.addressHouse ?? '';
        _townCtrl.text    = user.addressTown ?? '';
        _stateCtrl.text   = user.addressState ?? '';
        _pincodeCtrl.text = user.addressPincode ?? '';
        // Set available coins in cart
        context.read<CartProvider>().setAvailableCoins(user.coinBalance);
      }
    });
  }

  @override
  void dispose() {
    _houseCtrl.dispose(); _townCtrl.dispose();
    _stateCtrl.dispose(); _pincodeCtrl.dispose();
    _instructionsCtrl.dispose();
    super.dispose();
  }

  bool get _hasAddress =>
    _houseCtrl.text.trim().isNotEmpty &&
    _townCtrl.text.trim().isNotEmpty &&
    _pincodeCtrl.text.trim().isNotEmpty;

  Future<void> _placeOrder() async {
    final cart = context.read<CartProvider>();
    if (cart.selectedLocationId == null) {
      showSnack(context, 'No branch selected.', isError: true); return;
    }
    if (_deliveryType == 'delivery' && !_hasAddress) {
      showSnack(context, 'Please fill in your delivery address (house, town, pincode)', isError: true);
      return;
    }

    setState(() => _placingOrder = true);
    final orderProvider = context.read<OrderProvider>();

    final deliveryAddr = _deliveryType == 'delivery'
        ? [_houseCtrl.text.trim(), _townCtrl.text.trim(), _stateCtrl.text.trim(), _pincodeCtrl.text.trim()]
            .where((s) => s.isNotEmpty).join(', ')
        : null;

    final orderData = <String, dynamic>{
      'items': cart.toOrderItems(),
      'location_id': cart.selectedLocationId,
      'delivery_type': _deliveryType,
      if (deliveryAddr != null) 'delivery_address': deliveryAddr,
      if (cart.couponCode != null) 'coupon_code': cart.couponCode,
      if (_instructionsCtrl.text.trim().isNotEmpty)
        'special_instructions': _instructionsCtrl.text.trim(),
      'payment_method': _paymentMethod,
      if (_useCoins && cart.coinsToRedeem > 0) 'coins_to_redeem': cart.coinsToRedeem,
    };

    final result = await orderProvider.placeOrder(orderData);
    setState(() => _placingOrder = false);
    if (!mounted) return;

    if (result != null) {
      final orderId = result['order_id'];
      if (_paymentMethod == 'online') {
        try { await ApiService.createPaymentOrder(orderId, _paymentMethod); } catch (_) {}
      }
      cart.clear();
      // Refresh coin balance
      context.read<AuthProvider>().refreshUser();
      Navigator.pushNamedAndRemoveUntil(
        context, '/order-confirm', (r) => r.settings.name == '/home',
        arguments: {
          'order_id': orderId,
          'order_number': result['order_number'],
          'total': result['total_amount'],
          'coins_redeemed': result['coins_redeemed'] ?? 0,
        },
      );
    } else {
      showSnack(context, orderProvider.error ?? 'Failed to place order', isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    final user = context.watch<AuthProvider>().user;
    final coinBalance = user?.coinBalance ?? 0;
    final coinsDiscount = _useCoins ? cart.coinsToRedeem.toDouble() : 0.0;

    return LoadingOverlay(
      loading: _placingOrder,
      child: Scaffold(
        backgroundColor: const Color(AppColors.background),
        appBar: AppBar(title: const Text('Checkout')),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          children: [

            // ── Branch ──────────────────────────────────────────
            _SectionCard(
              title: '📍 Branch',
              child: Row(children: [
                Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(
                    color: const Color(AppColors.primary).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.store_rounded, color: Color(AppColors.primary), size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(cart.selectedLocationName ?? 'No branch selected',
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                ])),
                TextButton(
                  onPressed: () => Navigator.pushNamed(context, '/branch-selection'),
                  style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), minimumSize: Size.zero),
                  child: const Text('Change', style: TextStyle(fontSize: 12)),
                ),
              ]),
            ),
            const SizedBox(height: 12),

            // ── Delivery type ────────────────────────────────────
            _SectionCard(
              title: '🚚 Delivery Type',
              child: Row(children: [
                Expanded(child: _TypeButton(label: '🛵 Delivery', selected: _deliveryType == 'delivery',
                  onTap: () => setState(() => _deliveryType = 'delivery'))),
                const SizedBox(width: 10),
                Expanded(child: _TypeButton(label: '🏪 Pickup', selected: _deliveryType == 'pickup',
                  onTap: () => setState(() => _deliveryType = 'pickup'))),
              ]),
            ),
            const SizedBox(height: 12),

            // ── Structured delivery address ───────────────────────
            if (_deliveryType == 'delivery') ...[
              _SectionCard(
                title: '🏠 Delivery Address',
                child: Column(children: [
                  TextFormField(
                    controller: _houseCtrl,
                    decoration: const InputDecoration(
                      labelText: 'House / Flat No. & Building *',
                      hintText: 'e.g. Flat 4B, Sunrise Apartments',
                      contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _townCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Town / Area *',
                      hintText: 'e.g. Indiranagar',
                      contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(children: [
                    Expanded(
                      child: TextFormField(
                        controller: _stateCtrl,
                        decoration: const InputDecoration(
                          labelText: 'State',
                          hintText: 'e.g. Karnataka',
                          contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextFormField(
                        controller: _pincodeCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Pincode *',
                          hintText: '560038',
                          contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        ),
                      ),
                    ),
                  ]),
                ]),
              ),
              const SizedBox(height: 12),
            ],

            // ── Special instructions ──────────────────────────────
            _SectionCard(
              title: '📝 Special Instructions', subtitle: 'Optional',
              child: TextFormField(
                controller: _instructionsCtrl, maxLines: 2,
                decoration: const InputDecoration(
                  hintText: 'E.g. Extra spicy, no onions...',
                  contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // ── Coins redemption ─────────────────────────────────
            if (coinBalance > 0)
              _SectionCard(
                title: '🪙 Loyalty Coins',
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: const Color(AppColors.coins).withOpacity(0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text('$coinBalance coins available',
                        style: const TextStyle(fontWeight: FontWeight.w700, color: Color(AppColors.coins), fontSize: 13)),
                    ),
                    const Spacer(),
                    Switch(
                      value: _useCoins,
                      activeColor: const Color(AppColors.coins),
                      onChanged: (val) {
                        setState(() => _useCoins = val);
                        if (val) {
                          // Redeem up to total
                          final maxRedeem = coinBalance.clamp(0, cart.total.floor());
                          cart.setCoinsToRedeem(maxRedeem);
                        } else {
                          cart.setCoinsToRedeem(0);
                        }
                      },
                    ),
                  ]),
                  if (_useCoins) ...[
                    const SizedBox(height: 6),
                    Text(
                      'Using ${cart.coinsToRedeem} coins = ₹${cart.coinsToRedeem} off',
                      style: const TextStyle(color: Color(AppColors.success), fontWeight: FontWeight.w600, fontSize: 13),
                    ),
                    Text('1 coin = ₹1  •  Earn 1 coin per ₹10 spent',
                      style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                  ] else
                    Text('Use coins for instant discount (1 coin = ₹1)',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                ]),
              ),
            if (coinBalance > 0) const SizedBox(height: 12),

            // ── Payment method ────────────────────────────────────
            _SectionCard(
              title: '💳 Payment Method',
              child: Column(children: [
                _PaymentOption(
                  value: 'cash_on_delivery', selected: _paymentMethod,
                  title: '💵 Cash on Delivery', subtitle: 'Pay when delivered',
                  onTap: () => setState(() => _paymentMethod = 'cash_on_delivery'),
                ),
                const SizedBox(height: 4),
                _PaymentOption(
                  value: 'online', selected: _paymentMethod,
                  title: '🏦 Online Payment', subtitle: 'UPI, Card, Net Banking',
                  onTap: () => setState(() => _paymentMethod = 'online'),
                ),
              ]),
            ),
            const SizedBox(height: 12),

            // ── Order summary ─────────────────────────────────────
            _SectionCard(
              title: '🧾 Order Summary',
              child: Column(children: [
                _SummaryRow(label: 'Subtotal (${cart.itemCount} items)', amount: cart.subtotal),
                const SizedBox(height: 8),
                if (cart.discount > 0) ...[
                  _SummaryRow(label: 'Coupon Discount', amount: -cart.discount, color: const Color(AppColors.success)),
                  const SizedBox(height: 8),
                ],
                if (_useCoins && cart.coinsToRedeem > 0) ...[
                  _SummaryRow(label: '🪙 Coins Redeemed (${cart.coinsToRedeem})', amount: -coinsDiscount, color: const Color(AppColors.coins)),
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
                _SummaryRow(label: 'Total', amount: cart.total, isBold: true, fontSize: 16),
              ]),
            ),
            const SizedBox(height: 24),

            // ── Place order ───────────────────────────────────────
            SizedBox(
              height: 54,
              child: ElevatedButton(
                onPressed: _placingOrder ? null : _placeOrder,
                style: ElevatedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
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

class _SectionCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget child;
  const _SectionCard({required this.title, this.subtitle, required this.child});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white, borderRadius: BorderRadius.circular(14),
      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
        if (subtitle != null) ...[
          const SizedBox(width: 6),
          Text(subtitle!, style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
        ],
      ]),
      const SizedBox(height: 12),
      child,
    ]),
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
      child: Center(child: Text(label, style: TextStyle(
        fontWeight: FontWeight.w700, fontSize: 13,
        color: selected ? Colors.white : const Color(AppColors.textPrimary),
      ))),
    ),
  );
}

class _PaymentOption extends StatelessWidget {
  final String value, selected, title, subtitle;
  final VoidCallback onTap;
  const _PaymentOption({required this.value, required this.selected, required this.title, required this.subtitle, required this.onTap});

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
          border: Border.all(color: isSelected ? const Color(AppColors.primary) : Colors.grey.shade200, width: isSelected ? 1.5 : 1),
        ),
        child: Row(children: [
          Radio<String>(value: value, groupValue: selected, onChanged: (_) => onTap(),
            activeColor: const Color(AppColors.primary),
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            visualDensity: VisualDensity.compact),
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
  const _SummaryRow({required this.label, required this.amount, this.color, this.isBold = false, this.fontSize = 13, this.note});

  @override
  Widget build(BuildContext context) {
    final c = color ?? (amount < 0 ? const Color(AppColors.success) : const Color(AppColors.textPrimary));
    return Row(children: [
      Expanded(child: Text(label, style: TextStyle(
        fontSize: fontSize, fontWeight: isBold ? FontWeight.w800 : FontWeight.w500,
        color: isBold ? const Color(AppColors.textPrimary) : Colors.grey.shade700))),
      if (note != null) ...[
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(color: const Color(AppColors.success).withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
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
