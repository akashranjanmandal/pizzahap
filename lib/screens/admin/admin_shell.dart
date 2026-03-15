import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/admin_provider.dart';
import '../../config/app_config.dart';
import 'admin_dashboard_screen.dart';
import 'admin_orders_screen.dart';
import 'admin_users_screen.dart';
import 'admin_menu_screen.dart';
import 'admin_refunds_screen.dart';
import 'admin_support_screen.dart';
import 'admin_notifications_screen.dart';

class AdminShell extends StatefulWidget {
  const AdminShell({super.key});
  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  int _idx = 0;

  final _screens = const [
    AdminDashboardScreen(),
    AdminOrdersScreen(),
    AdminMenuScreen(),
    AdminUsersScreen(),
    AdminRefundsScreen(),
    AdminSupportScreen(),
    AdminNotificationsScreen(),
  ];

  static const _navItems = [
    _Item(Icons.dashboard_outlined,      Icons.dashboard,      'Dashboard'),
    _Item(Icons.receipt_long_outlined,   Icons.receipt_long,   'Orders'),
    _Item(Icons.restaurant_menu_outlined,Icons.restaurant_menu,'Menu'),
    _Item(Icons.people_outline,          Icons.people,         'Users'),
    _Item(Icons.replay_outlined,         Icons.replay,         'Refunds'),
    _Item(Icons.support_agent_outlined,  Icons.support_agent,  'Support'),
    _Item(Icons.notifications_outlined,  Icons.notifications,  'Push'),
  ];

  // Intercept Android back button — never go back to user flow accidentally
  Future<bool> _onWillPop() async {
    if (_idx != 0) {
      setState(() => _idx = 0);
      return false; // handled
    }
    // On dashboard, show confirm dialog before leaving admin
    final leave = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Leave Admin Panel?'),
        content: const Text('Go back to the customer app?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Stay')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Leave', style: TextStyle(color: Color(AppColors.error))),
          ),
        ],
      ),
    ) ?? false;
    if (leave && mounted) {
      Navigator.pushReplacementNamed(context, '/home');
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final admin = context.watch<AdminProvider>();
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: const Color(AppColors.background),
        drawer: _buildDrawer(admin),
        body: IndexedStack(index: _idx, children: _screens),
        bottomNavigationBar: _BottomNav(
          currentIndex: _idx,
          items: _navItems,
          onTap: (i) => setState(() => _idx = i),
        ),
      ),
    );
  }

  Widget _buildDrawer(AdminProvider admin) => Drawer(
    child: Container(
      color: const Color(0xFF0F0F0F),
      child: SafeArea(
        child: Column(
          children: [
            // Admin info header
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(children: [
                Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(
                    color: const Color(AppColors.primary),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      admin.adminName.isNotEmpty ? admin.adminName[0].toUpperCase() : 'A',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 20),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(admin.adminName,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15)),
                    Text(admin.adminRole.replaceAll('_', ' ').toUpperCase(),
                      style: TextStyle(color: Colors.grey.shade500, fontSize: 11)),
                    if (admin.adminLocationName != null)
                      Text('📍 ${admin.adminLocationName}',
                        style: TextStyle(color: Colors.grey.shade400, fontSize: 11)),
                  ]),
                ),
              ]),
            ),
            Divider(color: Colors.grey.shade800),
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: _navItems.asMap().entries.map((e) {
                  final isActive = _idx == e.key;
                  return ListTile(
                    leading: Icon(e.value.icon,
                      color: isActive ? const Color(AppColors.primary) : Colors.grey.shade500),
                    title: Text(e.value.label,
                      style: TextStyle(
                        color: isActive ? const Color(AppColors.primary) : Colors.white,
                        fontSize: 14, fontWeight: isActive ? FontWeight.w700 : FontWeight.w400,
                      )),
                    selected: isActive,
                    onTap: () { setState(() => _idx = e.key); Navigator.pop(context); },
                  );
                }).toList(),
              ),
            ),
            Divider(color: Colors.grey.shade800),
            ListTile(
              leading: Icon(Icons.phone_android, color: Colors.grey.shade500),
              title: Text('Back to App', style: TextStyle(color: Colors.grey.shade400)),
              onTap: () => Navigator.pushReplacementNamed(context, '/home'),
            ),
            ListTile(
              leading: const Icon(Icons.exit_to_app, color: Color(AppColors.error)),
              title: const Text('Sign Out', style: TextStyle(color: Color(AppColors.error))),
              onTap: () {
                admin.logout();
                Navigator.pushReplacementNamed(context, '/login');
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    ),
  );
}

class _BottomNav extends StatelessWidget {
  final int currentIndex;
  final List<_Item> items;
  final ValueChanged<int> onTap;
  const _BottomNav({required this.currentIndex, required this.items, required this.onTap});

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: Colors.white,
      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 12, offset: const Offset(0, -3))],
    ),
    child: SafeArea(
      child: SizedBox(
        height: 58,
        child: Row(
          children: items.asMap().entries.map((e) {
            final active = currentIndex == e.key;
            return Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => onTap(e.key),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(active ? e.value.activeIcon : e.value.icon,
                      size: 22,
                      color: active ? const Color(AppColors.primary) : Colors.grey.shade400),
                    const SizedBox(height: 2),
                    Text(e.value.label,
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                        color: active ? const Color(AppColors.primary) : Colors.grey.shade400,
                      )),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ),
    ),
  );
}

class _Item {
  final IconData icon, activeIcon;
  final String label;
  const _Item(this.icon, this.activeIcon, this.label);
}
