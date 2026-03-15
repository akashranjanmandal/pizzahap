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
    _Item(Icons.dashboard_outlined,       Icons.dashboard_rounded,       'Dashboard'),
    _Item(Icons.receipt_long_outlined,    Icons.receipt_long_rounded,    'Orders'),
    _Item(Icons.restaurant_menu_outlined, Icons.restaurant_menu_rounded, 'Menu'),
    _Item(Icons.people_outline,           Icons.people_rounded,          'Users'),
    _Item(Icons.replay_outlined,          Icons.replay_rounded,          'Refunds'),
    _Item(Icons.support_agent_outlined,   Icons.support_agent_rounded,   'Support'),
    _Item(Icons.notifications_outlined,   Icons.notifications_rounded,   'Notifs'),
  ];

  Future<bool> _onWillPop() async {
    // If on a sub-tab, go back to dashboard
    if (_idx != 0) {
      setState(() => _idx = 0);
      return false;
    }
    // On dashboard: back → confirm logout to /login (NOT user home)
    final result = await showDialog<String>(
      context: context,
      barrierColor: Colors.black54,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56, height: 56,
                decoration: BoxDecoration(
                  color: const Color(AppColors.primary).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.admin_panel_settings_rounded,
                  color: Color(AppColors.primary), size: 28),
              ),
              const SizedBox(height: 16),
              const Text('Leave Admin Panel?',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
              const SizedBox(height: 8),
              Text('Sign out of admin or go to customer app?',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                textAlign: TextAlign.center),
              const SizedBox(height: 20),
              Column(children: [
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => Navigator.pop(context, 'logout'),
                    icon: const Icon(Icons.logout_rounded, size: 18),
                    label: const Text('Sign Out'),
                    style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(AppColors.error)),
                  ),
                ),
                const SizedBox(height: 8),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => Navigator.pop(context, 'stay'),
                  child: Text('Stay in Admin',
                    style: TextStyle(color: Colors.grey.shade500)),
                ),
              ]),
            ],
          ),
        ),
      ),
    );

    if (!mounted) return false;
    if (result == 'logout') {
      context.read<AdminProvider>().logout();
      Navigator.pushReplacementNamed(context, '/login');
    } else if (result == 'home') {
      Navigator.pushReplacementNamed(context, '/home');
    }
    return false;
  }

  void _confirmLogout() {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 52, height: 52,
                decoration: BoxDecoration(
                  color: const Color(AppColors.error).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.logout_rounded,
                  color: Color(AppColors.error), size: 26),
              ),
              const SizedBox(height: 14),
              const Text('Sign Out?',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
              const SizedBox(height: 8),
              Text('You will be signed out of the admin panel.',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                textAlign: TextAlign.center),
              const SizedBox(height: 20),
              Row(children: [
                Expanded(child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                )),
                const SizedBox(width: 12),
                Expanded(child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    context.read<AdminProvider>().logout();
                    Navigator.pushReplacementNamed(context, '/login');
                  },
                  style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(AppColors.error)),
                  child: const Text('Sign Out'),
                )),
              ]),
            ],
          ),
        ),
      ),
    );
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
        bottomNavigationBar: _buildBottomNav(),
      ),
    );
  }

  Widget _buildBottomNav() => Container(
    decoration: BoxDecoration(
      color: Colors.white,
      boxShadow: [BoxShadow(
        color: Colors.black.withOpacity(0.06),
        blurRadius: 12, offset: const Offset(0, -3),
      )],
    ),
    child: SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: _navItems.asMap().entries.map((e) {
            final active = _idx == e.key;
            return Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => setState(() => _idx = e.key),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: active
                            ? const Color(AppColors.primary).withOpacity(0.12)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Icon(
                        active ? e.value.activeIcon : e.value.icon,
                        size: 20,
                        color: active
                            ? const Color(AppColors.primary)
                            : Colors.grey.shade400,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(e.value.label,
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight:
                            active ? FontWeight.w700 : FontWeight.w500,
                        color: active
                            ? const Color(AppColors.primary)
                            : Colors.grey.shade400,
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

  Widget _buildDrawer(AdminProvider admin) {
    return Drawer(
      width: MediaQuery.of(context).size.width * 0.78,
      child: Container(
        color: const Color(0xFF0F0F0F),
        child: SafeArea(
          child: Column(children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(children: [
                Container(
                  width: 48, height: 48,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(AppColors.primaryDark), Color(AppColors.primary)],
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Center(
                    child: Text(
                      admin.adminName.isNotEmpty
                          ? admin.adminName[0].toUpperCase()
                          : 'A',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 22,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(admin.adminName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 2),
                      Text(
                        admin.adminRole.replaceAll('_', ' ').toUpperCase(),
                        style: const TextStyle(
                          color: Color(AppColors.primary),
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        )),
                      if (admin.adminLocationName != null)
                        Text('📍 ${admin.adminLocationName}',
                          style: TextStyle(
                            color: Colors.grey.shade400, fontSize: 11),
                          maxLines: 1, overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
              ]),
            ),
            Divider(color: Colors.grey.shade800, height: 1),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: _navItems.asMap().entries.map((e) {
                  final isActive = _idx == e.key;
                  return Container(
                    margin: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 2),
                    decoration: BoxDecoration(
                      color: isActive
                          ? const Color(AppColors.primary).withOpacity(0.15)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: ListTile(
                      dense: true,
                      leading: Icon(
                        isActive ? e.value.activeIcon : e.value.icon,
                        color: isActive
                            ? const Color(AppColors.primary)
                            : Colors.grey.shade500,
                        size: 20,
                      ),
                      title: Text(e.value.label,
                        style: TextStyle(
                          color: isActive
                              ? const Color(AppColors.primary)
                              : Colors.white,
                          fontSize: 14,
                          fontWeight: isActive ? FontWeight.w700 : FontWeight.w400,
                        )),
                      onTap: () {
                        setState(() => _idx = e.key);
                        Navigator.pop(context);
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
            Divider(color: Colors.grey.shade800, height: 1),
            // Customer App
            Container(
              margin: const EdgeInsets.fromLTRB(10, 4, 10, 2),
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(10)),
              child: ListTile(
                dense: true,
                leading: Icon(Icons.phone_android_rounded,
                  color: Colors.grey.shade400, size: 20),
                title: Text('Customer App',
                  style: TextStyle(color: Colors.grey.shade400, fontSize: 14)),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushReplacementNamed(context, '/home');
                },
              ),
            ),
            // Sign Out
            Container(
              margin: const EdgeInsets.fromLTRB(10, 2, 10, 8),
              decoration: BoxDecoration(
                color: const Color(AppColors.error).withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: ListTile(
                dense: true,
                leading: const Icon(Icons.logout_rounded,
                  color: Color(AppColors.error), size: 20),
                title: const Text('Sign Out',
                  style: TextStyle(
                    color: Color(AppColors.error),
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  )),
                onTap: () {
                  Navigator.pop(context);
                  _confirmLogout();
                },
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

class _Item {
  final IconData icon, activeIcon;
  final String label;
  const _Item(this.icon, this.activeIcon, this.label);
}
