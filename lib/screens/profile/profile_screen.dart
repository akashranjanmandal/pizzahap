import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/providers.dart';
import '../../config/app_config.dart';
import '../../widgets/widgets.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _editing = false;
  final _nameCtrl = TextEditingController();
  final _mobileCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();


  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().user;
    _nameCtrl.text = user?.name ?? '';
    _mobileCtrl.text = user?.mobile ?? '';
    _addressCtrl.text = user?.address ?? '';
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _mobileCtrl.dispose();
    _addressCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final auth = context.read<AuthProvider>();
    final ok = await auth.updateProfile({
      'name': _nameCtrl.text.trim(),
      if (_mobileCtrl.text.trim().isNotEmpty) 'mobile': _mobileCtrl.text.trim(),
      if (_addressCtrl.text.trim().isNotEmpty) 'address': _addressCtrl.text.trim(),
    });
    if (!mounted) return;
    if (ok) {
      setState(() => _editing = false);
      showSnack(context, 'Profile updated!');
    } else {
      showSnack(context, auth.error ?? 'Failed to update', isError: true);
    }
  }

  void _logout() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Log Out?'),
        content: const Text('You will be signed out of your account.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await context.read<AuthProvider>().logout();
              if (mounted) Navigator.pushReplacementNamed(context, '/login');
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(AppColors.error)),
            child: const Text('Log Out', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }



  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;
    if (user == null) return const SizedBox();

    return Scaffold(
      backgroundColor: const Color(AppColors.background),
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            icon: Icon(_editing ? Icons.close : Icons.edit_outlined),
            onPressed: () => setState(() {
              if (_editing) {
                _nameCtrl.text = user.name;
                _mobileCtrl.text = user.mobile ?? '';
                _addressCtrl.text = user.address ?? '';
              }
              _editing = !_editing;
            }),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Avatar
          Center(
            child: Container(
              width: 90, height: 90,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(AppColors.primary), Color(AppColors.accent)],
                ),
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(
                  color: const Color(AppColors.primary).withOpacity(0.3),
                  blurRadius: 16, offset: const Offset(0, 6),
                )],
              ),
              child: Center(
                child: Text(
                  user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                  style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.w800),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Center(child: Text(user.name,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800))),
          Center(child: Text(user.email,
            style: TextStyle(fontSize: 14, color: Colors.grey.shade600))),
          const SizedBox(height: 28),

          if (_editing) ...[
            _label('Full Name'),
            const SizedBox(height: 8),
            TextFormField(controller: _nameCtrl,
              decoration: const InputDecoration(hintText: 'Full name')),
            const SizedBox(height: 16),
            _label('Mobile Number'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _mobileCtrl,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(hintText: '9876543210', prefixText: '+91  '),
            ),
            const SizedBox(height: 16),
            _label('Address'),
            const SizedBox(height: 8),
            TextFormField(controller: _addressCtrl, maxLines: 2,
              decoration: const InputDecoration(hintText: 'Your delivery address')),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: auth.loading ? null : _save,
              child: auth.loading
                ? const SizedBox(height: 20, width: 20,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Text('Save Changes'),
            ),
          ] else ...[
            _infoCard([
              _infoTile(Icons.email_outlined, 'Email', user.email),
              if (user.mobile != null)
                _infoTile(Icons.phone_outlined, 'Mobile', '+91 ${user.mobile}'),
              if (user.address != null)
                _infoTile(Icons.location_on_outlined, 'Address', user.address!),
            ]),
          ],

          const SizedBox(height: 24),

          // Quick links
          _menuCard([
            _menuItem(Icons.shopping_bag_outlined, 'My Orders',
              () => Navigator.pushNamed(context, '/orders')),
            _menuItem(Icons.local_offer_outlined, 'Coupons',
              () => Navigator.pushNamed(context, '/coupons')),
            _menuItem(Icons.support_agent_outlined, 'Support',
              () => Navigator.pushNamed(context, '/support')),
            _menuItem(Icons.assignment_return_outlined, 'My Refunds',
              () => Navigator.pushNamed(context, '/refunds')),
            _menuItem(Icons.notifications_outlined, 'Notifications',
              () => Navigator.pushNamed(context, '/notifications')),
          ]),

          const SizedBox(height: 24),

          OutlinedButton.icon(
            onPressed: _logout,
            icon: const Icon(Icons.logout, color: Color(AppColors.error)),
            label: const Text('Log Out',
              style: TextStyle(color: Color(AppColors.error))),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Color(AppColors.error))),
          ),

          const SizedBox(height: 32),

    
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _label(String text) =>
    Text(text, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14));

  Widget _infoCard(List<Widget> children) => Container(
    decoration: BoxDecoration(
      color: Colors.white, borderRadius: BorderRadius.circular(14),
      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)],
    ),
    child: Column(children: children),
  );

  Widget _infoTile(IconData icon, String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    child: Row(children: [
      Icon(icon, size: 20, color: const Color(AppColors.primary)),
      const SizedBox(width: 12),
      Expanded(child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 11, color: Colors.grey.shade500,
            fontWeight: FontWeight.w600)),
          Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
        ],
      )),
    ]),
  );

  Widget _menuCard(List<Widget> items) => Container(
    decoration: BoxDecoration(
      color: Colors.white, borderRadius: BorderRadius.circular(14),
      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)],
    ),
    child: Column(children: items),
  );

  Widget _menuItem(IconData icon, String label, VoidCallback onTap) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(14),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(children: [
        Icon(icon, size: 20, color: const Color(AppColors.primary)),
        const SizedBox(width: 12),
        Expanded(child: Text(label,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14))),
        Icon(Icons.chevron_right, size: 20, color: Colors.grey.shade400),
      ]),
    ),
  );
}
