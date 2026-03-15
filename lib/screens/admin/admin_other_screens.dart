import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../services/admin_api_service.dart';
import '../../services/api_service.dart';
import '../../widgets/widgets.dart';

// ═══════════════════════════════════════════
// ADMIN REFUNDS SCREEN
// ═══════════════════════════════════════════

class AdminRefundsScreen extends StatefulWidget {
  const AdminRefundsScreen({super.key});
  @override
  State<AdminRefundsScreen> createState() => _AdminRefundsScreenState();
}

class _AdminRefundsScreenState extends State<AdminRefundsScreen> {
  List<dynamic> _refunds = [];
  bool _loading = true;
  String? _statusFilter;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      _refunds = await AdminApiService.getRefunds(status: _statusFilter);
    } on ApiException catch (e) {
      if (mounted) showSnack(context, e.message, isError: true);
    } finally {
      setState(() => _loading = false);
    }
  }

  void _showProcessDialog(Map<String, dynamic> refund) {
    final notesCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Process Refund #${refund['id']}'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('Amount: ₹${refund['amount']}', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
          const SizedBox(height: 4),
          Text('Reason: ${refund['reason']}', style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
          const SizedBox(height: 16),
          TextField(controller: notesCtrl, decoration: const InputDecoration(labelText: 'Admin Notes (optional)', isDense: true)),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          OutlinedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await AdminApiService.processRefund(refund['id'], 'reject', notes: notesCtrl.text);
                _load();
                if (mounted) showSnack(context, 'Refund rejected');
              } on ApiException catch (e) {
                if (mounted) showSnack(context, e.message, isError: true);
              }
            },
            style: OutlinedButton.styleFrom(foregroundColor: Colors.red, side: const BorderSide(color: Colors.red)),
            child: const Text('Reject'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await AdminApiService.processRefund(refund['id'], 'approve', notes: notesCtrl.text);
                _load();
                if (mounted) showSnack(context, 'Refund approved — processing via PayU');
              } on ApiException catch (e) {
                if (mounted) showSnack(context, e.message, isError: true);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Approve'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Column(children: [
    // Filter chips
    SizedBox(
      height: 48,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        children: [null, 'pending', 'processing', 'completed', 'failed'].map((s) {
          final active = _statusFilter == s;
          final label = s == null ? 'All' : s[0].toUpperCase() + s.substring(1);
          return GestureDetector(
            onTap: () { setState(() => _statusFilter = s); _load(); },
            child: Container(
              margin: const EdgeInsets.only(right: 6),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: active ? const Color(0xFF1A1A2E) : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: active ? Colors.transparent : Colors.grey.shade200),
              ),
              child: Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: active ? Colors.white : Colors.grey.shade600)),
            ),
          );
        }).toList(),
      ),
    ),
    Expanded(
      child: _loading
        ? const Center(child: CircularProgressIndicator(color: Color(0xFF4ECDC4)))
        : _refunds.isEmpty
          ? const Center(child: Text('No refund requests'))
          : RefreshIndicator(
              color: const Color(0xFF4ECDC4),
              onRefresh: _load,
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: _refunds.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (ctx, i) {
                  final r = _refunds[i];
                  final isPending = r['status'] == 'pending';
                  return Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white, borderRadius: BorderRadius.circular(12),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)],
                    ),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(children: [
                        Expanded(child: Text('Order #${r['order_number']}', style: const TextStyle(fontWeight: FontWeight.w800))),
                        _statusBadge(r['status']),
                      ]),
                      const SizedBox(height: 4),
                      Text('${r['user_name']} · ${r['user_email']}', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                      const SizedBox(height: 6),
                      Text('₹${r['amount']}', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: Color(0xFF1A1A2E))),
                      const SizedBox(height: 4),
                      Text(r['reason'] ?? '', style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
                      if (isPending) ...[
                        const SizedBox(height: 10),
                        ElevatedButton(
                          onPressed: () => _showProcessDialog(r),
                          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1A1A2E), minimumSize: const Size(double.infinity, 36)),
                          child: const Text('Process Refund', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                        ),
                      ],
                    ]),
                  );
                },
              ),
            ),
    ),
  ]);

  Widget _statusBadge(String? s) {
    final colors = {'pending': const Color(0xFFFFBE0B), 'processing': Colors.blue, 'completed': Colors.green, 'failed': Colors.red};
    final c = colors[s] ?? Colors.grey;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: c.withOpacity(0.12), borderRadius: BorderRadius.circular(20)),
      child: Text(s ?? '', style: TextStyle(color: c, fontSize: 11, fontWeight: FontWeight.w700)),
    );
  }
}

// ═══════════════════════════════════════════
// ADMIN SUPPORT SCREEN
// ═══════════════════════════════════════════

class AdminSupportScreen extends StatefulWidget {
  const AdminSupportScreen({super.key});
  @override
  State<AdminSupportScreen> createState() => _AdminSupportScreenState();
}

class _AdminSupportScreenState extends State<AdminSupportScreen> {
  List<dynamic> _tickets = [];
  Map<String, dynamic>? _pagination;
  String? _statusFilter;
  int _page = 1;
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load({bool reset = false}) async {
    if (reset) _page = 1;
    setState(() => _loading = true);
    try {
      final result = await AdminApiService.getTickets(status: _statusFilter, page: _page);
      setState(() { _tickets = result['tickets']; _pagination = result['pagination']; });
    } on ApiException catch (e) {
      if (mounted) showSnack(context, e.message, isError: true);
    } finally {
      setState(() => _loading = false);
    }
  }

  void _openTicket(Map<String, dynamic> ticket) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => _AdminTicketDetailScreen(ticketId: ticket['id'])));
  }

  @override
  Widget build(BuildContext context) => Column(children: [
    SizedBox(
      height: 48,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        children: [null, 'open', 'in_progress', 'resolved', 'closed'].map((s) {
          final active = _statusFilter == s;
          final label = s == null ? 'All' : s.replaceAll('_', ' ').split(' ').map((w) => w[0].toUpperCase() + w.substring(1)).join(' ');
          return GestureDetector(
            onTap: () { setState(() => _statusFilter = s); _load(reset: true); },
            child: Container(
              margin: const EdgeInsets.only(right: 6),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: active ? const Color(0xFF1A1A2E) : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: active ? Colors.transparent : Colors.grey.shade200),
              ),
              child: Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: active ? Colors.white : Colors.grey.shade600)),
            ),
          );
        }).toList(),
      ),
    ),
    Expanded(
      child: _loading
        ? const Center(child: CircularProgressIndicator(color: Color(0xFF4ECDC4)))
        : _tickets.isEmpty
          ? const Center(child: Text('No tickets'))
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
              itemCount: _tickets.length + 1,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (ctx, i) {
                if (i == _tickets.length) {
                  final total = _pagination?['totalPages'] ?? 1;
                  return Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    IconButton(onPressed: _page > 1 ? () { setState(() => _page--); _load(); } : null, icon: const Icon(Icons.chevron_left)),
                    Text('Page $_page of $total'),
                    IconButton(onPressed: _page < total ? () { setState(() => _page++); _load(); } : null, icon: const Icon(Icons.chevron_right)),
                  ]);
                }
                final t = _tickets[i];
                return GestureDetector(
                  onTap: () => _openTicket(t),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)]),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(children: [
                        Expanded(child: Text(t['ticket_number'] ?? '', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13))),
                        _badge(t['status']),
                      ]),
                      const SizedBox(height: 4),
                      Text(t['subject'] ?? '', style: const TextStyle(fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 2),
                      Text('${t['user_name']} · ${t['category']?.replaceAll('_', ' ')}', style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                    ]),
                  ),
                );
              },
            ),
    ),
  ]);

  Widget _badge(String? s) {
    final colors = {'open': Colors.blue, 'in_progress': const Color(0xFFFFBE0B), 'resolved': Colors.green, 'closed': Colors.grey};
    final c = colors[s] ?? Colors.grey;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: c.withOpacity(0.12), borderRadius: BorderRadius.circular(20)),
      child: Text((s ?? '').replaceAll('_', ' '), style: TextStyle(color: c, fontSize: 11, fontWeight: FontWeight.w700)),
    );
  }
}

class _AdminTicketDetailScreen extends StatefulWidget {
  final int ticketId;
  const _AdminTicketDetailScreen({required this.ticketId});
  @override
  State<_AdminTicketDetailScreen> createState() => _AdminTicketDetailScreenState();
}

class _AdminTicketDetailScreenState extends State<_AdminTicketDetailScreen> {
  Map<String, dynamic>? _ticket;
  List<dynamic> _messages = [];
  bool _loading = true;
  final _replyCtrl = TextEditingController();
  String? _newStatus;

  @override
  void initState() { super.initState(); _load(); }

  @override
  void dispose() { _replyCtrl.dispose(); super.dispose(); }

  Future<void> _load() async {
    // Use regular support ticket detail endpoint (admin can view all)
    setState(() => _loading = true);
    try {
      // Fetch via admin token using the base support detail endpoint is unavailable directly
      // So we load from the user-side endpoint using the admin token as Bearer
      final response = await _fetchTicket();
      setState(() { _ticket = response; _messages = response['messages'] ?? []; });
    } catch (_) {}
    setState(() => _loading = false);
  }

  Future<Map<String, dynamic>> _fetchTicket() async {
    // Direct fetch using admin token
    final r = await http.get(
      Uri.parse('http://13.232.73.121/api/support/tickets/${widget.ticketId}'),
      headers: {'Authorization': 'Bearer', 'Content-Type': 'application/json'},
    );
    final body = jsonDecode(r.body);
    return body['data'];
  }

  Future<void> _reply() async {
    if (_replyCtrl.text.trim().isEmpty) return;
    try {
      await AdminApiService.replyTicket(widget.ticketId, _replyCtrl.text.trim(), status: _newStatus);
      _replyCtrl.clear();
      setState(() => _newStatus = null);
      _load();
    } on ApiException catch (e) {
      if (mounted) showSnack(context, e.message, isError: true);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFF4F6FA),
    appBar: AppBar(
      backgroundColor: const Color(0xFF1A1A2E),
      title: Text(_ticket?['ticket_number'] ?? 'Ticket', style: const TextStyle(color: Colors.white)),
      iconTheme: const IconThemeData(color: Colors.white),
    ),
    body: _loading
      ? const Center(child: CircularProgressIndicator(color: Color(0xFF4ECDC4)))
      : Column(children: [
          // Header
          Container(
            padding: const EdgeInsets.all(14),
            color: Colors.white,
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(_ticket?['subject'] ?? '', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
              const SizedBox(height: 4),
              Text('${_ticket?['category']?.replaceAll('_', ' ')} · ${_ticket?['user_name']}',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
            ]),
          ),
          // Messages
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (ctx, i) {
                final m = _messages[i];
                final isAdmin = m['sender_role'] == 'admin';
                return Align(
                  alignment: isAdmin ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isAdmin ? const Color(0xFF1A1A2E) : Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(14), topRight: const Radius.circular(14),
                        bottomLeft: Radius.circular(isAdmin ? 14 : 4),
                        bottomRight: Radius.circular(isAdmin ? 4 : 14),
                      ),
                    ),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      if (isAdmin)
                        const Text('Admin', style: TextStyle(color: Color(0xFF4ECDC4), fontSize: 10, fontWeight: FontWeight.w800)),
                      Text(m['message'] ?? '', style: TextStyle(color: isAdmin ? Colors.white : Colors.black87, fontSize: 14)),
                    ]),
                  ),
                );
              },
            ),
          ),
          // Reply bar
          Container(
            padding: EdgeInsets.fromLTRB(16, 8, 16, MediaQuery.of(context).padding.bottom + 8),
            color: Colors.white,
            child: Column(children: [
              // Status selector
              DropdownButtonFormField<String?>(
                initialValue: _newStatus,
                decoration: const InputDecoration(labelText: 'Update Status (optional)', isDense: true, contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
                items: [
                  const DropdownMenuItem(value: null, child: Text('Keep current status')),
                  ...['open','in_progress','resolved','closed'].map((s) => DropdownMenuItem(value: s, child: Text(s.replaceAll('_', ' ')))),
                ],
                onChanged: (v) => setState(() => _newStatus = v),
              ),
              const SizedBox(height: 8),
              Row(children: [
                Expanded(child: TextField(controller: _replyCtrl, decoration: const InputDecoration(hintText: 'Reply as admin...', isDense: true))),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _reply,
                  child: Container(
                    width: 44, height: 44,
                    decoration: const BoxDecoration(color: Color(0xFF1A1A2E), shape: BoxShape.circle),
                    child: const Icon(Icons.send, color: Colors.white, size: 20),
                  ),
                ),
              ]),
            ]),
          ),
        ]),
  );
}

// ═══════════════════════════════════════════
// ADMIN COUPONS SCREEN
// ═══════════════════════════════════════════

class AdminCouponsScreen extends StatefulWidget {
  const AdminCouponsScreen({super.key});
  @override
  State<AdminCouponsScreen> createState() => _AdminCouponsScreenState();
}

class _AdminCouponsScreenState extends State<AdminCouponsScreen> {
  List<dynamic> _coupons = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      _coupons = await ApiService.getCoupons();
    } catch (_) {}
    setState(() => _loading = false);
  }

  void _showCreateCoupon() {
    final codeCtrl = TextEditingController();
    final valueCtrl = TextEditingController();
    final minOrderCtrl = TextEditingController(text: '0');
    final descCtrl = TextEditingController();
    String discountType = 'flat';
    DateTime validFrom = DateTime.now();
    DateTime validUntil = DateTime.now().add(const Duration(days: 30));

    showModalBottomSheet(
      context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
      builder: (_) => StatefulBuilder(builder: (ctx, setS) => Container(
        decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
        padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
        child: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Create Coupon', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            const SizedBox(height: 16),
            TextField(controller: codeCtrl, textCapitalization: TextCapitalization.characters, decoration: const InputDecoration(labelText: 'Coupon Code', hintText: 'PIZZA20', isDense: true)),
            const SizedBox(height: 10),
            Row(children: [
              Expanded(child: TextField(controller: valueCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Discount Value', isDense: true))),
              const SizedBox(width: 10),
              Expanded(child: DropdownButtonFormField<String>(
                initialValue: discountType,
                decoration: const InputDecoration(labelText: 'Type', isDense: true),
                items: const [DropdownMenuItem(value: 'flat', child: Text('₹ Flat')), DropdownMenuItem(value: 'percentage', child: Text('% Percent'))],
                onChanged: (v) => setS(() => discountType = v!),
              )),
            ]),
            const SizedBox(height: 10),
            TextField(controller: minOrderCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Min Order Value (₹)', isDense: true)),
            const SizedBox(height: 10),
            TextField(controller: descCtrl, decoration: const InputDecoration(labelText: 'Description (optional)', isDense: true)),
            const SizedBox(height: 10),
            Row(children: [
              Expanded(child: GestureDetector(
                onTap: () async {
                  final d = await showDatePicker(context: ctx, initialDate: validFrom, firstDate: DateTime.now(), lastDate: DateTime.now().add(const Duration(days: 365)));
                  if (d != null) setS(() => validFrom = d);
                },
                child: Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(8)),
                  child: Text('From: ${validFrom.toString().substring(0, 10)}', style: const TextStyle(fontSize: 12))),
              )),
              const SizedBox(width: 8),
              Expanded(child: GestureDetector(
                onTap: () async {
                  final d = await showDatePicker(context: ctx, initialDate: validUntil, firstDate: DateTime.now(), lastDate: DateTime.now().add(const Duration(days: 365)));
                  if (d != null) setS(() => validUntil = d);
                },
                child: Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(8)),
                  child: Text('Until: ${validUntil.toString().substring(0, 10)}', style: const TextStyle(fontSize: 12))),
              )),
            ]),
            const SizedBox(height: 16),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1A1A2E), minimumSize: const Size(double.infinity, 48)),
              onPressed: () async {
                if (codeCtrl.text.isEmpty || valueCtrl.text.isEmpty) return;
                Navigator.pop(ctx);
                try {
                  await AdminApiService.createCoupon({
                    'code': codeCtrl.text.toUpperCase(),
                    'discount_type': discountType,
                    'discount_value': double.parse(valueCtrl.text),
                    'min_order_value': double.tryParse(minOrderCtrl.text) ?? 0,
                    'description': descCtrl.text.isEmpty ? null : descCtrl.text,
                    'valid_from': validFrom.toIso8601String(),
                    'valid_until': validUntil.toIso8601String(),
                  });
                  _load();
                  if (mounted) showSnack(context, 'Coupon created!');
                } on ApiException catch (e) {
                  if (mounted) showSnack(context, e.message, isError: true);
                }
              },
              child: const Text('Create Coupon', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
            ),
          ]),
        ),
      )),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFF4F6FA),
    floatingActionButton: FloatingActionButton.extended(
      onPressed: _showCreateCoupon,
      backgroundColor: const Color(0xFF1A1A2E),
      icon: const Icon(Icons.add, color: Colors.white),
      label: const Text('New Coupon', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
    ),
    body: _loading
      ? const Center(child: CircularProgressIndicator(color: Color(0xFF4ECDC4)))
      : _coupons.isEmpty
        ? const Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Text('🎫', style: TextStyle(fontSize: 48)),
            SizedBox(height: 12),
            Text('No active coupons', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
          ]))
        : ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            itemCount: _coupons.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (ctx, i) {
              final c = _coupons[i];
              return Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)]),
                child: Row(children: [
                  Container(width: 8, height: 70, decoration: BoxDecoration(
                    color: const Color(0xFF1A1A2E), borderRadius: BorderRadius.circular(4))),
                  const SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(c['code'] ?? '', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: Color(0xFF1A1A2E))),
                    if (c['description'] != null) Text(c['description'], style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                    const SizedBox(height: 4),
                    Text('Min order: ₹${c['min_order_value']}', style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                  ])),
                  Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(color: const Color(0xFF06D6A0).withOpacity(0.12), borderRadius: BorderRadius.circular(20)),
                      child: Text(
                        c['discount_type'] == 'percentage' ? '${c['discount_value']}% OFF' : '₹${c['discount_value']} OFF',
                        style: const TextStyle(color: Color(0xFF06D6A0), fontWeight: FontWeight.w800, fontSize: 13),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text('Until ${(c['valid_until'] ?? '').toString().substring(0, 10)}',
                      style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                  ]),
                ]),
              );
            },
          ),
  );
}
