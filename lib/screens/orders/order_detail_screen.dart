import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/providers.dart';
import '../../config/app_config.dart';
import '../../services/api_service.dart';
import '../../widgets/widgets.dart';
import '../../models/models.dart';

class OrderDetailScreen extends StatefulWidget {
  final int orderId;
  const OrderDetailScreen({super.key, required this.orderId});
  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<OrderProvider>().loadOrder(widget.orderId);
    });
  }

  final _statusSteps = ['pending', 'confirmed', 'preparing', 'out_for_delivery', 'delivered'];

  int _stepIndex(String status) {
    final idx = _statusSteps.indexOf(status);
    return idx >= 0 ? idx : 0;
  }

  String _stepLabel(String s) {
    switch (s) {
      case 'pending': return '⏳ Order Placed';
      case 'confirmed': return '✅ Confirmed';
      case 'preparing': return '👨‍🍳 Preparing';
      case 'out_for_delivery': return '🛵 Out for Delivery';
      case 'delivered': return '🎉 Delivered';
      default: return s;
    }
  }

  void _reorder(Order order) async {
    try {
      final items = await ApiService.reorder(order.id);
      if (!mounted) return;
      showSnack(context, 'Items added to cart!');
      Navigator.pushNamed(context, '/cart');
    } catch (e) {
      if (!mounted) return;
      showSnack(context, 'Failed to reorder', isError: true);
    }
  }

  void _requestRefund(Order order) {
    final reasonCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Request Refund'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Why are you requesting a refund?'),
            const SizedBox(height: 12),
            TextField(controller: reasonCtrl, maxLines: 3,
              decoration: const InputDecoration(hintText: 'Please explain the issue...')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await ApiService.requestRefund(order.id, reasonCtrl.text);
                if (!mounted) return;
                showSnack(context, 'Refund request submitted!');
              } on ApiException catch (e) {
                if (!mounted) return;
                showSnack(context, e.message, isError: true);
              }
            },
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<OrderProvider>();
    if (provider.loading) return const Scaffold(body: Center(child: CircularProgressIndicator(color: Color(AppColors.primary))));
    final order = provider.currentOrder;
    if (order == null) return const Scaffold(body: Center(child: Text('Order not found')));

    final isCancelled = order.status == 'cancelled';
    final currentStep = isCancelled ? -1 : _stepIndex(order.status);

    return Scaffold(
      backgroundColor: const Color(AppColors.background),
      appBar: AppBar(
        title: Text(order.orderNumber),
        actions: [
          if (order.status == 'delivered')
            TextButton(
              onPressed: () => _reorder(order),
              child: const Text('Reorder', style: TextStyle(color: Color(AppColors.primary), fontWeight: FontWeight.w700)),
            ),
        ],
      ),
      body: RefreshIndicator(
        color: const Color(AppColors.primary),
        onRefresh: () => context.read<OrderProvider>().loadOrder(widget.orderId),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Status card
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Order Status', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                      OrderStatusChip(status: order.status),
                    ],
                  ),
                  if (!isCancelled) ...[
                    const SizedBox(height: 20),
                    // Progress stepper
                    ...List.generate(_statusSteps.length, (i) {
                      final done = i <= currentStep;
                      final active = i == currentStep;
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Column(
                            children: [
                              Container(
                                width: 28, height: 28,
                                decoration: BoxDecoration(
                                  color: done ? const Color(AppColors.primary) : Colors.grey.shade200,
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: done
                                    ? const Icon(Icons.check, color: Colors.white, size: 16)
                                    : Text('${i + 1}', style: TextStyle(
                                        color: Colors.grey.shade500, fontSize: 12, fontWeight: FontWeight.w700)),
                                ),
                              ),
                              if (i < _statusSteps.length - 1)
                                Container(width: 2, height: 28, color: done && i < currentStep ? const Color(AppColors.primary) : Colors.grey.shade200),
                            ],
                          ),
                          const SizedBox(width: 12),
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Text(_stepLabel(_statusSteps[i]),
                              style: TextStyle(
                                fontWeight: active ? FontWeight.w800 : FontWeight.w500,
                                fontSize: active ? 15 : 13,
                                color: done ? const Color(AppColors.textPrimary) : Colors.grey.shade400,
                              )),
                          ),
                        ],
                      );
                    }),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Items
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white, borderRadius: BorderRadius.circular(14),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Items Ordered', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                  const SizedBox(height: 12),
                  ...order.items.map((item) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      children: [
                        PizzaNetImage(url: item.imageUrl, width: 56, height: 56, borderRadius: BorderRadius.circular(8)),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(item.productName, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                              Text('${item.sizeName}${item.crustName != null ? ' • ${item.crustName}' : ''} × ${item.quantity}',
                                style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                            ],
                          ),
                        ),
                        Text('₹${item.totalPrice}',
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                      ],
                    ),
                  )),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Bill
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white, borderRadius: BorderRadius.circular(14),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Bill Details', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                  const SizedBox(height: 12),
                  PriceRow(label: 'Subtotal', amount: order.subtotal),
                  if (order.discountAmount > 0) ...[
                    const SizedBox(height: 6),
                    PriceRow(label: 'Discount', amount: -order.discountAmount, color: const Color(AppColors.success)),
                  ],
                  const SizedBox(height: 6),
                  PriceRow(label: 'Delivery Fee', amount: order.deliveryFee),
                  const SizedBox(height: 6),
                  PriceRow(label: 'Tax', amount: order.taxAmount),
                  const Divider(height: 16),
                  PriceRow(label: 'Total Paid', amount: order.totalAmount, isBold: true),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Delivery info
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white, borderRadius: BorderRadius.circular(14),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Delivery Info', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                  const SizedBox(height: 10),
                  if (order.locationName != null)
                    _infoRow(Icons.store_outlined, 'Branch', order.locationName!),
                  _infoRow(Icons.delivery_dining_outlined, 'Type',
                    order.deliveryType == 'delivery' ? 'Home Delivery' : 'Pickup'),
                  if (order.deliveryAddress != null)
                    _infoRow(Icons.location_on_outlined, 'Address', order.deliveryAddress!),
                ],
              ),
            ),

            // Action buttons
            if (order.status == 'delivered') ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.replay, size: 18),
                      label: const Text('Reorder'),
                      onPressed: () => _reorder(order),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.refresh, size: 18),
                      label: const Text('Refund'),
                      onPressed: () => _requestRefund(order),
                      style: OutlinedButton.styleFrom(foregroundColor: const Color(AppColors.warning)),
                    ),
                  ),
                ],
              ),
            ],
            if (order.canCancel) ...[
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () async {
                  final ok = await context.read<OrderProvider>().cancelOrder(order.id);
                  if (ok && mounted) showSnack(context, 'Order cancelled');
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(AppColors.error),
                  side: const BorderSide(color: Color(AppColors.error)),
                ),
                child: const Text('Cancel Order'),
              ),
            ],
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: Colors.grey.shade500),
        const SizedBox(width: 8),
        Text('$label: ', style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
        Expanded(child: Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600))),
      ],
    ),
  );
}
