import 'package:flutter/material.dart';
import '../../services/admin_api_service.dart';
import '../../services/api_service.dart';
import '../../config/app_config.dart';
import '../../widgets/widgets.dart';
import '../../models/models.dart';

class AdminSupportScreen extends StatefulWidget {
  const AdminSupportScreen({super.key});
  @override
  State<AdminSupportScreen> createState() => _AdminSupportScreenState();
}

class _AdminSupportScreenState extends State<AdminSupportScreen> {
  List<dynamic> _tickets = [];
  bool _loading = false;
  String? _statusFilter;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final result = await AdminApiService.getTickets(status: _statusFilter);
      _tickets = result['tickets'] ?? [];
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  Color _statusColor(String s) {
    switch (s) {
      case 'open': return Colors.blue;
      case 'in_progress': return const Color(AppColors.warning);
      case 'resolved': return const Color(AppColors.success);
      case 'closed': return Colors.grey;
      default: return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(AppColors.background),
    appBar: AppBar(
      title: const Text('Support Tickets'),
      actions: [
        PopupMenuButton<String?>(
          icon: const Icon(Icons.filter_list),
          onSelected: (v) { setState(() => _statusFilter = v); _load(); },
          itemBuilder: (_) => [
            const PopupMenuItem(value: null, child: Text('All')),
            const PopupMenuItem(value: 'open', child: Text('Open')),
            const PopupMenuItem(value: 'in_progress', child: Text('In Progress')),
            const PopupMenuItem(value: 'resolved', child: Text('Resolved')),
            const PopupMenuItem(value: 'closed', child: Text('Closed')),
          ],
        ),
      ],
    ),
    body: _loading
      ? const Center(child: CircularProgressIndicator(color: Color(AppColors.primary)))
      : _tickets.isEmpty
        ? const EmptyState(emoji: '🎫', title: 'No tickets found')
        : RefreshIndicator(
            color: const Color(AppColors.primary),
            onRefresh: _load,
            child: ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: _tickets.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (ctx, i) {
                final t = _tickets[i];
                return GestureDetector(
                  onTap: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => AdminTicketDetailScreen(ticketId: t['id']))
                  ).then((_) => _load()),
                  child: Container(
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
                            Text(t['ticket_number'] ?? '', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: _statusColor(t['status'] ?? '').withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(t['status']?.toString().replaceAll('_', ' ') ?? '',
                                style: TextStyle(color: _statusColor(t['status'] ?? ''), fontSize: 11, fontWeight: FontWeight.w700)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(t['subject'] ?? '', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                        const SizedBox(height: 2),
                        Text('${t['user_name'] ?? ''} • ${t['user_email'] ?? ''}',
                          style: TextStyle(color: Colors.grey.shade500, fontSize: 11)),
                        if (t['order_number'] != null)
                          Text('Order: ${t['order_number']}', style: TextStyle(color: Colors.grey.shade500, fontSize: 11)),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
  );
}

class AdminTicketDetailScreen extends StatefulWidget {
  final int ticketId;
  const AdminTicketDetailScreen({super.key, required this.ticketId});
  @override
  State<AdminTicketDetailScreen> createState() => _AdminTicketDetailScreenState();
}

class _AdminTicketDetailScreenState extends State<AdminTicketDetailScreen> {
  SupportTicket? _ticket;
  bool _loading = true;
  final _replyCtrl = TextEditingController();
  String? _newStatus;
  bool _replying = false;

  @override
  void initState() { super.initState(); _load(); }
  @override
  void dispose() { _replyCtrl.dispose(); super.dispose(); }

  Future<void> _load() async {
    try {
      final r = await ApiService.getTicket(widget.ticketId);
      setState(() { _ticket = r; _loading = false; });
    } catch (_) { setState(() => _loading = false); }
  }

  Future<void> _reply() async {
    if (_replyCtrl.text.trim().isEmpty) return;
    setState(() => _replying = true);
    try {
      await AdminApiService.replyTicket(widget.ticketId, _replyCtrl.text.trim(), status: _newStatus);
      _replyCtrl.clear();
      setState(() => _newStatus = null);
      await _load();
    } on ApiException catch (e) {
      if (mounted) showSnack(context, e.message, isError: true);
    } finally {
      if (mounted) setState(() => _replying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Scaffold(body: Center(child: CircularProgressIndicator(color: Color(AppColors.primary))));
    if (_ticket == null) return const Scaffold(body: Center(child: Text('Not found')));

    return Scaffold(
      backgroundColor: const Color(AppColors.background),
      appBar: AppBar(
        title: Text(_ticket!.ticketNumber),
        actions: [
          DropdownButtonHideUnderline(
            child: DropdownButton<String?>(
              value: _newStatus,
              hint: const Padding(
                padding: EdgeInsets.only(right: 8),
                child: Text('Status', style: TextStyle(fontSize: 12)),
              ),
              items: ['open','in_progress','resolved','closed'].map((s) =>
                DropdownMenuItem(value: s, child: Text(s))).toList(),
              onChanged: (v) => setState(() => _newStatus = v),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            color: Colors.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_ticket!.subject, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                const SizedBox(height: 4),
                Row(children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(AppColors.primary).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(_ticket!.category.toUpperCase(),
                      style: const TextStyle(color: Color(AppColors.primary), fontSize: 10, fontWeight: FontWeight.w700)),
                  ),
                  const SizedBox(width: 8),
                  Text(_ticket!.status.replaceAll('_', ' '),
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                ]),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: _ticket!.messages.length,
              itemBuilder: (ctx, i) {
                final m = _ticket!.messages[i];
                final isUser = m.senderRole == 'user';
                return Align(
                  alignment: isUser ? Alignment.centerLeft : Alignment.centerRight,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isUser ? Colors.white : const Color(AppColors.primary),
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(14), topRight: const Radius.circular(14),
                        bottomLeft: Radius.circular(isUser ? 4 : 14),
                        bottomRight: Radius.circular(isUser ? 14 : 4),
                      ),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4)],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(isUser ? (m.senderName ?? 'User') : '👨‍💼 You (Admin)',
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700,
                            color: isUser ? Colors.grey.shade500 : Colors.white70)),
                        const SizedBox(height: 3),
                        Text(m.message, style: TextStyle(
                          color: isUser ? const Color(AppColors.textPrimary) : Colors.white,
                          fontSize: 13, height: 1.4)),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          if (_ticket!.status != 'closed')
            Container(
              padding: EdgeInsets.fromLTRB(12, 10, 12, MediaQuery.of(context).padding.bottom + 10),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 8, offset: const Offset(0, -2))],
              ),
              child: Row(children: [
                Expanded(
                  child: TextField(
                    controller: _replyCtrl,
                    decoration: const InputDecoration(hintText: 'Reply as admin...', isDense: true),
                    maxLines: 3, minLines: 1,
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _replying ? null : _reply,
                  child: Container(
                    width: 44, height: 44,
                    decoration: const BoxDecoration(color: Color(AppColors.primary), shape: BoxShape.circle),
                    child: _replying
                      ? const Center(child: SizedBox(width: 16, height: 16,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)))
                      : const Icon(Icons.send, color: Colors.white, size: 20),
                  ),
                ),
              ]),
            ),
        ],
      ),
    );
  }
}
