import 'package:flutter/material.dart';
import '../../services/admin_api_service.dart';
import '../../config/app_config.dart';
import '../../services/api_service.dart';
import '../../widgets/widgets.dart';

class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});
  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  List<dynamic> _users = [];
  bool _loading = false;
  final _searchCtrl = TextEditingController();

  @override
  void initState() { super.initState(); _load(); }

  @override
  void dispose() { _searchCtrl.dispose(); super.dispose(); }

  Future<void> _load({String? search}) async {
    setState(() => _loading = true);
    try {
      final result = await AdminApiService.getUsers(search: search);
      _users = result['users'] ?? [];
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _toggleBlock(int id, bool currentlyBlocked) async {
    try {
      await AdminApiService.blockUser(id, !currentlyBlocked);
      if (mounted) {
        showSnack(context, currentlyBlocked ? 'User unblocked' : 'User blocked');
        _load(search: _searchCtrl.text.trim().isEmpty ? null : _searchCtrl.text.trim());
      }
    } on ApiException catch (e) {
      if (mounted) showSnack(context, e.message, isError: true);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(AppColors.background),
    appBar: AppBar(title: const Text('Users')),
    body: Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
          child: TextField(
            controller: _searchCtrl,
            decoration: InputDecoration(
              hintText: 'Search by name, email, mobile...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchCtrl.text.isNotEmpty
                ? IconButton(icon: const Icon(Icons.clear), onPressed: () { _searchCtrl.clear(); _load(); setState(() {}); })
                : null,
            ),
            onChanged: (v) {
              setState(() {});
              Future.delayed(const Duration(milliseconds: 500), () {
                _load(search: v.trim().isEmpty ? null : v.trim());
              });
            },
          ),
        ),
        Expanded(
          child: _loading
            ? const Center(child: CircularProgressIndicator(color: Color(AppColors.primary)))
            : _users.isEmpty
              ? const EmptyState(emoji: '👤', title: 'No users found')
              : RefreshIndicator(
                  color: const Color(AppColors.primary),
                  onRefresh: () => _load(),
                  child: ListView.separated(
                    padding: const EdgeInsets.all(12),
                    itemCount: _users.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (ctx, i) {
                      final u = _users[i];
                      final blocked = u['is_blocked'] == 1 || u['is_blocked'] == true;
                      return Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: blocked ? const Color(AppColors.error).withOpacity(0.04) : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: blocked ? const Color(AppColors.error).withOpacity(0.2) : Colors.grey.shade100),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: const Color(AppColors.primary).withOpacity(0.12),
                              child: Text(
                                (u['name'] ?? '?')[0].toUpperCase(),
                                style: const TextStyle(color: Color(AppColors.primary), fontWeight: FontWeight.w800),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(children: [
                                    Text(u['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                                    if (blocked) ...[
                                      const SizedBox(width: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(color: const Color(AppColors.error).withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
                                        child: const Text('BLOCKED', style: TextStyle(color: Color(AppColors.error), fontSize: 9, fontWeight: FontWeight.w800)),
                                      ),
                                    ],
                                  ]),
                                  Text(u['email'] ?? '', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                                  if (u['mobile'] != null)
                                    Text(u['mobile'], style: TextStyle(color: Colors.grey.shade500, fontSize: 11)),
                                ],
                              ),
                            ),
                            PopupMenuButton<String>(
                              itemBuilder: (_) => [
                                PopupMenuItem(value: 'block', child: Text(blocked ? '✅ Unblock' : '🚫 Block')),
                              ],
                              onSelected: (v) { if (v == 'block') _toggleBlock(u['id'], blocked); },
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
        ),
      ],
    ),
  );
}
