import 'package:flutter/material.dart';
import '../../services/admin_api_service.dart';
import '../../config/app_config.dart';
import '../../services/api_service.dart';
import '../../widgets/widgets.dart';

class AdminRefundsScreen extends StatefulWidget {
  const AdminRefundsScreen({super.key});
  @override
  State<AdminRefundsScreen> createState() => _AdminRefundsScreenState();
}

class _AdminRefundsScreenState extends State<AdminRefundsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  final _statusFilters = [null, 'pending', 'processing', 'completed', 'failed'];
  final _tabLabels = ['All', 'Pending', 'Processing', 'Done', 'Failed'];
  List<dynamic> _refunds = [];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: _statusFilters.length, vsync: this);
    _tabCtrl.addListener(() { if (!_tabCtrl.indexIsChanging) _load(); });
    _load();
  }

  @override
  void dispose() { _tabCtrl.dispose(); super.dispose(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      _refunds = await AdminApiService.getRefunds(status: _statusFilters[_tabCtrl.index]);
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _process(int id, String action) async {
    final noteCtrl = TextEditingController();
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(action == 'approve' ? '✅ Approve Refund' : '❌ Reject Refund'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(action == 'approve'
              ? 'This will initiate the refund via PayU. Confirm?'
              : 'Reason for rejection?'),
            const SizedBox(height: 10),
            TextField(controller: noteCtrl, decoration: const InputDecoration(hintText: 'Optional note...')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: action == 'approve' ? const Color(AppColors.success) : const Color(AppColors.error),
            ),
            child: Text(action == 'approve' ? 'Approve' : 'Reject', style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await AdminApiService.processRefund(id, action, notes: noteCtrl.text.isEmpty ? null : noteCtrl.text);
      if (mounted) { showSnack(context, 'Refund ${action}d successfully'); _load(); }
    } on ApiException catch (e) {
      if (mounted) showSnack(context, e.message, isError: true);
    }
  }

  Color _statusColor(String? s) {
    switch (s) {
      case 'pending': return const Color(AppColors.warning);
      case 'processing': return Colors.blue;
      case 'completed': return const Color(AppColors.success);
      case 'failed': return const Color(AppColors.error);
      default: return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(AppColors.background),
    appBar: AppBar(
      title: const Text('Refunds'),
      bottom: TabBar(
        controller: _tabCtrl, isScrollable: true,
        labelColor: const Color(AppColors.primary), unselectedLabelColor: Colors.grey,
        indicatorColor: const Color(AppColors.primary),
        tabs: _tabLabels.map((l) => Tab(text: l)).toList(),
      ),
    ),
    body: TabBarView(
      controller: _tabCtrl,
      children: List.generate(_statusFilters.length, (_) {
        if (_loading) return const Center(child: CircularProgressIndicator(color: Color(AppColors.primary)));
        if (_refunds.isEmpty) return const EmptyState(emoji: '💸', title: 'No refund requests');
        return ListView.separated(
          padding: const EdgeInsets.all(12),
          itemCount: _refunds.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (ctx, i) {
            final r = _refunds[i];
            final status = r['status'] as String?;
            final isPending = status == 'pending';
            return Container(
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
                      Text('Order #${r['order_number'] ?? '-'}',
                        style: const TextStyle(fontWeight: FontWeight.w800)),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: _statusColor(status).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(status ?? '', style: TextStyle(
                          color: _statusColor(status), fontSize: 11, fontWeight: FontWeight.w700)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text('${r['user_name'] ?? ''} • ${r['user_email'] ?? ''}',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                  Text(r['reason'] ?? '', style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                  const Divider(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('₹${r['amount']?.toString() ?? '0'}',
                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: Color(AppColors.primary))),
                      if (isPending)
                        Row(children: [
                          OutlinedButton(
                            onPressed: () => _process(r['id'], 'reject'),
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size(72, 32),
                              foregroundColor: const Color(AppColors.error),
                              side: const BorderSide(color: Color(AppColors.error)),
                              padding: const EdgeInsets.symmetric(horizontal: 10),
                            ),
                            child: const Text('Reject'),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: () => _process(r['id'], 'approve'),
                            style: ElevatedButton.styleFrom(
                              minimumSize: const Size(72, 32),
                              backgroundColor: const Color(AppColors.success),
                              padding: const EdgeInsets.symmetric(horizontal: 10),
                            ),
                            child: const Text('Approve', style: TextStyle(color: Colors.white)),
                          ),
                        ]),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      }),
    ),
  );
}
