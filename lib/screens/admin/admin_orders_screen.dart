import 'package:flutter/material.dart';
import '../../services/admin_api_service.dart';
import '../../config/app_config.dart';
import '../../services/api_service.dart';
import '../../widgets/widgets.dart';

class AdminOrdersScreen extends StatefulWidget {
  const AdminOrdersScreen({super.key});
  @override
  State<AdminOrdersScreen> createState() => _AdminOrdersScreenState();
}

class _AdminOrdersScreenState extends State<AdminOrdersScreen> with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  final _statusFilters = [null, 'pending', 'confirmed', 'preparing', 'out_for_delivery', 'delivered', 'cancelled'];
  final _tabLabels = ['All', 'Pending', 'Confirmed', 'Preparing', 'On Way', 'Delivered', 'Cancelled'];
  List<dynamic> _orders = [];
  bool _loading = false;
  Map<String, dynamic>? _pagination;
  int _page = 1;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: _statusFilters.length, vsync: this);
    _tabCtrl.addListener(() { if (!_tabCtrl.indexIsChanging) { _page = 1; _load(); } });
    _load();
  }

  @override
  void dispose() { _tabCtrl.dispose(); super.dispose(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final result = await AdminApiService.getOrders(
        status: _statusFilters[_tabCtrl.index], page: _page);
      _orders = result['orders'] ?? [];
      _pagination = result['pagination'];
    } catch (e) {
      if (mounted) showSnack(context, 'Failed to load orders', isError: true);
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _updateStatus(int orderId, String currentStatus) async {
    final transitions = {
      'pending': ['confirmed', 'cancelled'],
      'confirmed': ['preparing', 'cancelled'],
      'preparing': ['out_for_delivery', 'cancelled'],
      'out_for_delivery': ['delivered'],
      'delivered': [],
      'cancelled': [],
    };
    final options = transitions[currentStatus] ?? [];
    if (options.isEmpty) { showSnack(context, 'No further transitions available'); return; }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Update Order Status', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
            const SizedBox(height: 16),
            ...options.map((s) => ListTile(
              leading: _statusIcon(s),
              title: Text(s.replaceAll('_', ' ').toUpperCase(),
                style: const TextStyle(fontWeight: FontWeight.w700)),
              onTap: () async {
                Navigator.pop(context);
                try {
                  await AdminApiService.updateOrderStatus(orderId, s);
                  if (mounted) { showSnack(context, 'Status updated to $s'); _load(); }
                } on ApiException catch (e) {
                  if (mounted) showSnack(context, e.message, isError: true);
                }
              },
            )),
          ],
        ),
      ),
    );
  }

  Widget _statusIcon(String s) {
    const map = {
      'confirmed': '✅', 'preparing': '👨‍🍳', 'out_for_delivery': '🛵',
      'delivered': '🎉', 'cancelled': '❌',
    };
    return Text(map[s] ?? '📦', style: const TextStyle(fontSize: 20));
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(AppColors.background),
    appBar: AppBar(
      title: const Text('Orders'),
      bottom: TabBar(
        controller: _tabCtrl,
        isScrollable: true,
        labelColor: const Color(AppColors.primary),
        unselectedLabelColor: Colors.grey,
        indicatorColor: const Color(AppColors.primary),
        tabs: _tabLabels.map((l) => Tab(text: l)).toList(),
      ),
    ),
    body: TabBarView(
      controller: _tabCtrl,
      children: List.generate(_statusFilters.length, (_) {
        if (_loading) return const Center(child: CircularProgressIndicator(color: Color(AppColors.primary)));
        if (_orders.isEmpty) return const EmptyState(emoji: '📦', title: 'No orders found');
        return RefreshIndicator(
          color: const Color(AppColors.primary),
          onRefresh: _load,
          child: ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: _orders.length + (_pagination?['hasNext'] == true ? 1 : 0),
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (ctx, i) {
              if (i == _orders.length) {
                return Center(
                  child: TextButton(
                    onPressed: () { _page++; _load(); },
                    child: const Text('Load More'),
                  ),
                );
              }
              final o = _orders[i];
              return _AdminOrderCard(order: o, onUpdateStatus: () => _updateStatus(o['id'], o['status']));
            },
          ),
        );
      }),
    ),
  );
}

class _AdminOrderCard extends StatelessWidget {
  final Map<String, dynamic> order;
  final VoidCallback onUpdateStatus;
  const _AdminOrderCard({required this.order, required this.onUpdateStatus});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: Colors.white, borderRadius: BorderRadius.circular(12),
      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6)],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(order['order_number'] ?? '', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
            OrderStatusChip(status: order['status'] ?? ''),
          ],
        ),
        const SizedBox(height: 6),
        Text('${order['user_name'] ?? 'Unknown'} • ${order['user_mobile'] ?? '-'}',
          style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
        Text(order['location_name'] ?? '', style: TextStyle(color: Colors.grey.shade500, fontSize: 11)),
        const Divider(height: 14),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('₹${(double.tryParse(order['total_amount']?.toString() ?? '0') ?? 0).toStringAsFixed(0)}',
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: Color(AppColors.primary))),
            ElevatedButton(
              onPressed: onUpdateStatus,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(100, 32),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
              ),
              child: const Text('Update Status'),
            ),
          ],
        ),
      ],
    ),
  );
}
