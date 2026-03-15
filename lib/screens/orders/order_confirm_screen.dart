import 'package:flutter/material.dart';
import '../../config/app_config.dart';

class OrderConfirmScreen extends StatelessWidget {
  final int orderId;
  final String orderNumber;
  final double total;

  const OrderConfirmScreen({
    super.key, required this.orderId, required this.orderNumber, required this.total,
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
              // Success animation placeholder
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

              // Order info card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 12)],
                ),
                child: Column(
                  children: [
                    _infoRow('Order Number', orderNumber),
                    const Divider(height: 20),
                    _infoRow('Amount Paid', '₹${total.toStringAsFixed(0)}'),
                    const Divider(height: 20),
                    _infoRow('Estimated Time', '30-45 mins'),
                  ],
                ),
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
