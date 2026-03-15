import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/providers.dart';
import '../../config/app_config.dart';
import '../../services/api_service.dart';
import '../../widgets/widgets.dart';
import '../../models/models.dart';

// ═══════════════════════════════════════════
// NOTIFICATIONS SCREEN
// ═══════════════════════════════════════════

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});
  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NotificationProvider>().load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<NotificationProvider>();
    return Scaffold(
      backgroundColor: const Color(AppColors.background),
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          if (prov.unreadCount > 0)
            TextButton(
              onPressed: () => prov.markAllRead(),
              child: const Text('Mark all read', style: TextStyle(color: Color(AppColors.primary), fontWeight: FontWeight.w700)),
            ),
        ],
      ),
      body: prov.loading
        ? const Center(child: CircularProgressIndicator(color: Color(AppColors.primary)))
        : prov.notifications.isEmpty
          ? const EmptyState(emoji: '🔔', title: 'No notifications yet')
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: prov.notifications.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (ctx, i) {
                final n = prov.notifications[i];
                return Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: n.isRead ? Colors.white : const Color(AppColors.primary).withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: n.isRead ? Colors.grey.shade100 : const Color(AppColors.primary).withOpacity(0.2),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 36, height: 36,
                        decoration: BoxDecoration(
                          color: const Color(AppColors.primary).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Center(child: Text(_notifEmoji(n.type), style: const TextStyle(fontSize: 18))),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(n.title, style: TextStyle(fontWeight: n.isRead ? FontWeight.w600 : FontWeight.w800, fontSize: 14)),
                            const SizedBox(height: 3),
                            Text(n.message, style: TextStyle(fontSize: 13, color: Colors.grey.shade600, height: 1.4)),
                          ],
                        ),
                      ),
                      if (!n.isRead)
                        Container(width: 8, height: 8, decoration: const BoxDecoration(color: Color(AppColors.primary), shape: BoxShape.circle)),
                    ],
                  ),
                );
              },
            ),
    );
  }

  String _notifEmoji(String? type) {
    switch (type) {
      case 'order': return '📦';
      case 'payment': return '💳';
      case 'promo': return '🎫';
      default: return '🔔';
    }
  }
}

// ═══════════════════════════════════════════
// COUPONS SCREEN
// ═══════════════════════════════════════════

class CouponsScreen extends StatefulWidget {
  const CouponsScreen({super.key});
  @override
  State<CouponsScreen> createState() => _CouponsScreenState();
}

class _CouponsScreenState extends State<CouponsScreen> {
  List<Coupon> _coupons = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      _coupons = await ApiService.getCoupons();
    } catch (_) {}
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(AppColors.background),
    appBar: AppBar(title: const Text('Available Coupons')),
    body: _loading
      ? const Center(child: CircularProgressIndicator(color: Color(AppColors.primary)))
      : _coupons.isEmpty
        ? const EmptyState(emoji: '🎫', title: 'No active coupons', subtitle: 'Check back later for offers!')
        : ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: _coupons.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (ctx, i) => _CouponCard(coupon: _coupons[i]),
          ),
  );
}

class _CouponCard extends StatelessWidget {
  final Coupon coupon;
  const _CouponCard({required this.coupon});

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
    ),
    child: Stack(
      children: [
        Row(
          children: [
            // Left colored strip
            Container(
              width: 8,
              height: 100,
              decoration: const BoxDecoration(
                color: Color(AppColors.primary),
                borderRadius: BorderRadius.only(topLeft: Radius.circular(16), bottomLeft: Radius.circular(16)),
              ),
            ),
            // Dashed divider (simulated)
            Container(
              width: 1, height: 100,
              color: Colors.grey.shade200,
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(AppColors.primary).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(coupon.code,
                            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: Color(AppColors.primary))),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(AppColors.success).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(coupon.displayDiscount,
                            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: Color(AppColors.success))),
                        ),
                      ],
                    ),
                    if (coupon.description != null) ...[
                      const SizedBox(height: 6),
                      Text(coupon.description!, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                    ],
                    const SizedBox(height: 6),
                    Text('Min. order: ₹${coupon.minOrderValue.toStringAsFixed(0)}',
                      style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                  ],
                ),
              ),
            ),
          ],
        ),
        // Copy button
        Positioned(
          right: 12, bottom: 12,
          child: GestureDetector(
            onTap: () => showSnack(context, 'Code ${coupon.code} copied!'),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                border: Border.all(color: const Color(AppColors.primary)),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text('Copy', style: TextStyle(color: Color(AppColors.primary), fontWeight: FontWeight.w700, fontSize: 12)),
            ),
          ),
        ),
      ],
    ),
  );
}

// ═══════════════════════════════════════════
// SUPPORT SCREEN
// ═══════════════════════════════════════════

class SupportScreen extends StatefulWidget {
  const SupportScreen({super.key});
  @override
  State<SupportScreen> createState() => _SupportScreenState();
}

class _SupportScreenState extends State<SupportScreen> {
  List<SupportTicket> _tickets = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      _tickets = await ApiService.getTickets();
    } catch (_) {}
    setState(() => _loading = false);
  }

  void _createTicket() {
    final subjectCtrl = TextEditingController();
    final messageCtrl = TextEditingController();
    String category = 'other';
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setModalState) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('New Support Ticket', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
              const SizedBox(height: 16),
              const Text('Category', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: category,
                decoration: const InputDecoration(),
                items: ['order_issue', 'payment', 'refund', 'delivery', 'other'].map((c) =>
                  DropdownMenuItem(value: c, child: Text(c.replaceAll('_', ' ').toUpperCase()))
                ).toList(),
                onChanged: (v) => setModalState(() => category = v!),
              ),
              const SizedBox(height: 12),
              const Text('Subject', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
              const SizedBox(height: 8),
              TextFormField(controller: subjectCtrl, decoration: const InputDecoration(hintText: 'Brief subject')),
              const SizedBox(height: 12),
              const Text('Message', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
              const SizedBox(height: 8),
              TextFormField(controller: messageCtrl, maxLines: 3, decoration: const InputDecoration(hintText: 'Describe your issue...')),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () async {
                  if (subjectCtrl.text.isEmpty || messageCtrl.text.isEmpty) return;
                  Navigator.pop(ctx);
                  try {
                    await ApiService.createTicket({
                      'subject': subjectCtrl.text, 'message': messageCtrl.text, 'category': category,
                    });
                    if (!mounted) return;
                    showSnack(context, 'Support ticket created!');
                    _load();
                  } on ApiException catch (e) {
                    if (!mounted) return;
                    showSnack(context, e.message, isError: true);
                  }
                },
                child: const Text('Submit Ticket'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(AppColors.background),
    appBar: AppBar(title: const Text('Support')),
    floatingActionButton: FloatingActionButton.extended(
      onPressed: _createTicket,
      backgroundColor: const Color(AppColors.primary),
      icon: const Icon(Icons.add, color: Colors.white),
      label: const Text('New Ticket', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
    ),
    body: _loading
      ? const Center(child: CircularProgressIndicator(color: Color(AppColors.primary)))
      : _tickets.isEmpty
        ? EmptyState(
            emoji: '🆘',
            title: 'No support tickets',
            subtitle: 'Need help? Create a ticket and we\'ll respond shortly.',
            buttonText: 'Create Ticket',
            onButton: _createTicket,
          )
        : ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            itemCount: _tickets.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (ctx, i) {
              final t = _tickets[i];
              return GestureDetector(
                onTap: () => Navigator.pushNamed(context, '/ticket-detail', arguments: t.id).then((_) => _load()),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(AppColors.primary).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Text('🎫', style: TextStyle(fontSize: 20)),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(t.subject, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                              maxLines: 1, overflow: TextOverflow.ellipsis),
                            Text(t.ticketNumber, style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      _statusBadge(t.status),
                    ],
                  ),
                ),
              );
            },
          ),
  );

  Widget _statusBadge(String status) {
    Color color;
    switch (status) {
      case 'open': color = Colors.blue; break;
      case 'in_progress': color = const Color(AppColors.warning); break;
      case 'resolved': color = const Color(AppColors.success); break;
      case 'closed': color = Colors.grey; break;
      default: color = Colors.grey;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
      child: Text(status.replaceAll('_', ' '), style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w700)),
    );
  }
}

// ═══════════════════════════════════════════
// TICKET DETAIL SCREEN
// ═══════════════════════════════════════════

class TicketDetailScreen extends StatefulWidget {
  final int ticketId;
  const TicketDetailScreen({super.key, required this.ticketId});
  @override
  State<TicketDetailScreen> createState() => _TicketDetailScreenState();
}

class _TicketDetailScreenState extends State<TicketDetailScreen> {
  SupportTicket? _ticket;
  bool _loading = true;
  final _replyCtrl = TextEditingController();
  bool _replying = false;

  @override
  void initState() { super.initState(); _load(); }

  @override
  void dispose() { _replyCtrl.dispose(); super.dispose(); }

  Future<void> _load() async {
    try {
      final t = await ApiService.getTicket(widget.ticketId);
      setState(() { _ticket = t; _loading = false; });
    } catch (_) { setState(() => _loading = false); }
  }

  Future<void> _reply() async {
    if (_replyCtrl.text.trim().isEmpty) return;
    setState(() => _replying = true);
    try {
      await ApiService.replyToTicket(widget.ticketId, _replyCtrl.text.trim());
      _replyCtrl.clear();
      await _load();
    } on ApiException catch (e) {
      if (!mounted) return;
      showSnack(context, e.message, isError: true);
    } finally {
      if (mounted) setState(() => _replying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Scaffold(body: Center(child: CircularProgressIndicator(color: Color(AppColors.primary))));
    if (_ticket == null) return const Scaffold(body: Center(child: Text('Ticket not found')));
    final t = _ticket!;

    return Scaffold(
      backgroundColor: const Color(AppColors.background),
      appBar: AppBar(title: Text(t.ticketNumber)),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(t.subject, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                      const SizedBox(height: 4),
                      Text(t.category.toUpperCase(), style: TextStyle(fontSize: 11, color: Colors.grey.shade500, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                // Messages
                ...t.messages.map((m) => _MessageBubble(message: m)),
              ],
            ),
          ),
          // Reply bar
          if (t.status != 'closed')
            Container(
              padding: EdgeInsets.fromLTRB(16, 12, 16, MediaQuery.of(context).padding.bottom + 12),
              color: Colors.white,
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _replyCtrl,
                      decoration: const InputDecoration(hintText: 'Write a reply...', isDense: true),
                    ),
                  ),
                  const SizedBox(width: 10),
                  GestureDetector(
                    onTap: _replying ? null : _reply,
                    child: Container(
                      width: 44, height: 44,
                      decoration: const BoxDecoration(color: Color(AppColors.primary), shape: BoxShape.circle),
                      child: _replying
                        ? const Center(child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)))
                        : const Icon(Icons.send, color: Colors.white, size: 20),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final SupportMessage message;
  const _MessageBubble({required this.message});

  bool get _isUser => message.senderRole == 'user';

  @override
  Widget build(BuildContext context) => Align(
    alignment: _isUser ? Alignment.centerRight : Alignment.centerLeft,
    child: Container(
      margin: const EdgeInsets.only(bottom: 10),
      constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _isUser ? const Color(AppColors.primary) : Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(14),
          topRight: const Radius.circular(14),
          bottomLeft: Radius.circular(_isUser ? 14 : 4),
          bottomRight: Radius.circular(_isUser ? 4 : 14),
        ),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 6)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!_isUser && message.senderName != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text('Support Agent', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.grey.shade600)),
            ),
          Text(message.message, style: TextStyle(color: _isUser ? Colors.white : const Color(AppColors.textPrimary), fontSize: 14, height: 1.4)),
        ],
      ),
    ),
  );
}

// ═══════════════════════════════════════════
// REFUNDS SCREEN
// ═══════════════════════════════════════════

class RefundsScreen extends StatefulWidget {
  const RefundsScreen({super.key});
  @override
  State<RefundsScreen> createState() => _RefundsScreenState();
}

class _RefundsScreenState extends State<RefundsScreen> {
  List<dynamic> _refunds = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    try {
      _refunds = await ApiService.getMyRefunds();
    } catch (_) {}
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(AppColors.background),
    appBar: AppBar(title: const Text('My Refunds')),
    body: _loading
      ? const Center(child: CircularProgressIndicator(color: Color(AppColors.primary)))
      : _refunds.isEmpty
        ? const EmptyState(emoji: '💸', title: 'No refund requests', subtitle: 'Your refund requests will appear here')
        : ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: _refunds.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (ctx, i) {
              final r = _refunds[i];
              return Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white, borderRadius: BorderRadius.circular(12),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Order #${r['order_number'] ?? '-'}',
                          style: const TextStyle(fontWeight: FontWeight.w700)),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: _refundStatusColor(r['status']).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(r['status'] ?? '', style: TextStyle(
                            color: _refundStatusColor(r['status']), fontSize: 12, fontWeight: FontWeight.w700)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text('₹${r['amount']}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(AppColors.primary))),
                    const SizedBox(height: 4),
                    Text(r['reason'] ?? '', style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
                  ],
                ),
              );
            },
          ),
  );

  Color _refundStatusColor(String? status) {
    switch (status) {
      case 'pending': return const Color(AppColors.warning);
      case 'processing': return Colors.blue;
      case 'completed': return const Color(AppColors.success);
      case 'failed': return const Color(AppColors.error);
      default: return Colors.grey;
    }
  }
}
