import 'package:flutter/material.dart';
import '../../config/app_config.dart';

class OrderConfirmScreen extends StatelessWidget {
  final int orderId;
  final String orderNumber;
  final double total;
  final int coinsRedeemed;

  const OrderConfirmScreen({
    super.key, required this.orderId, required this.orderNumber,
    required this.total, this.coinsRedeemed = 0,
  });

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(AppColors.background),
    body: SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 120, height: 120,
                decoration: BoxDecoration(
                  color: const Color(AppColors.success).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Center(child: Text('🎉', style: TextStyle(fontSize: 60))),
              ),
              const SizedBox(height: 28),
              const Text('Order Placed!', style: TextStyle(fontSize: 30, fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              const Text(
                'Your delicious pizza is being prepared 🍕',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 15, color: Color(AppColors.textSecondary), height: 1.5),
              ),
              const SizedBox(height: 28),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white, borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 12)],
                ),
                child: Column(children: [
                  _infoRow('Order Number', orderNumber),
                  const Divider(height: 20),
                  _infoRow('Amount Paid', '₹${total.toStringAsFixed(0)}'),
                  if (coinsRedeemed > 0) ...[
                    const Divider(height: 20),
                    _infoRow('🪙 Coins Used', '$coinsRedeemed coins (₹$coinsRedeemed off)'),
                  ],
                  const Divider(height: 20),
                  _infoRow('Estimated Time', '30–45 mins'),
                ]),
              ),

              // Coins earning hint
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(AppColors.coins).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  const Text('🪙', style: TextStyle(fontSize: 16)),
                  const SizedBox(width: 8),
                  Text(
                    'You\'ll earn ${(total / 10).floor()} coins after delivery!',
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Color(AppColors.coins)),
                  ),
                ]),
              ),

              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () => Navigator.pushNamedAndRemoveUntil(
                  context, '/order-detail', (r) => r.settings.name == '/home',
                  arguments: orderId,
                ),
                child: const Text('Track Order'),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () => Navigator.pushNamedAndRemoveUntil(context, '/home', (_) => false),
                child: const Text('Back to Home'),
              ),
            ],
          ),
        ),
      ),
    ),
  );

  Widget _infoRow(String label, String value) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(label, style: const TextStyle(fontSize: 14, color: Color(AppColors.textSecondary))),
      Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
    ],
  );
}
