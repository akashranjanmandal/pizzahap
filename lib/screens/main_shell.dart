import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/providers.dart';
import '../config/app_config.dart';
import 'home/home_screen.dart';
import 'menu/menu_screen.dart';
import 'cart/cart_screen.dart';
import 'orders/orders_screen.dart';
import 'profile/profile_screen.dart';

class MainShell extends StatefulWidget {
  final int initialTab;
  const MainShell({super.key, this.initialTab = 0});
  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  late int _currentIndex;
  DateTime? _lastBackPressed;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialTab;
  }

  // These are kept alive via IndexedStack - state is preserved across tab switches
  final List<Widget> _screens = const [
    HomeScreen(),
    MenuScreen(),
    CartScreen(),
    OrdersScreen(),
    ProfileScreen(),
  ];

  Future<bool> _onWillPop() async {
    // If not on home tab → go home tab (no back button visible)
    if (_currentIndex != 0) {
      setState(() => _currentIndex = 0);
      return false;
    }
    // On home tab: double-back to exit
    final now = DateTime.now();
    if (_lastBackPressed == null ||
        now.difference(_lastBackPressed!) > const Duration(seconds: 2)) {
      _lastBackPressed = now;
      showSnackTop(context, 'Press back again to exit');
      return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        // No appBar here - each child screen controls its own
        body: IndexedStack(
          index: _currentIndex,
          children: _screens,
        ),
        bottomNavigationBar: _BottomBar(
          currentIndex: _currentIndex,
          cartCount: cart.itemCount,
          onTap: (i) => setState(() => _currentIndex = i),
        ),
      ),
    );
  }
}

// ─── BOTTOM BAR ───────────────────────────────────────────────────

class _BottomBar extends StatelessWidget {
  final int currentIndex;
  final int cartCount;
  final ValueChanged<int> onTap;

  const _BottomBar({
    required this.currentIndex,
    required this.cartCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            children: [
              _tab(context, 0, Icons.home_outlined, Icons.home_rounded, 'Home'),
              _tab(context, 1, Icons.restaurant_menu_outlined, Icons.restaurant_menu_rounded, 'Menu'),
              _cartTab(context),
              _tab(context, 3, Icons.shopping_bag_outlined, Icons.shopping_bag_rounded, 'Orders'),
              _tab(context, 4, Icons.person_outline_rounded, Icons.person_rounded, 'Profile'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _tab(BuildContext ctx, int idx, IconData icon, IconData activeIcon, String label) {
    final active = currentIndex == idx;
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => onTap(idx),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
              decoration: BoxDecoration(
                color: active
                    ? const Color(AppColors.primary).withOpacity(0.12)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Icon(
                active ? activeIcon : icon,
                size: 22,
                color: active
                    ? const Color(AppColors.primary)
                    : const Color(AppColors.textHint),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                color: active
                    ? const Color(AppColors.primary)
                    : const Color(AppColors.textHint),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _cartTab(BuildContext ctx) {
    final active = currentIndex == 2;
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => onTap(2),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                  decoration: BoxDecoration(
                    color: active
                        ? const Color(AppColors.primary)
                        : const Color(AppColors.primary).withOpacity(0.08),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Icon(
                    Icons.shopping_cart_rounded,
                    size: 22,
                    color: active ? Colors.white : const Color(AppColors.primary),
                  ),
                ),
                if (cartCount > 0)
                  Positioned(
                    top: -4,
                    right: -4,
                    child: Container(
                      width: 17,
                      height: 17,
                      decoration: const BoxDecoration(
                        color: Color(AppColors.accent),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          cartCount > 9 ? '9+' : '$cartCount',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              'Cart',
              style: TextStyle(
                fontSize: 10,
                fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                color: active
                    ? const Color(AppColors.primary)
                    : const Color(AppColors.textHint),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Simple top snack used by MainShell (no overlay needed here, uses ScaffoldMessenger)
void showSnackTop(BuildContext context, String message, {bool isError = false}) {
  ScaffoldMessenger.of(context)
    ..clearSnackBars()
    ..showSnackBar(SnackBar(
      content: Text(message,
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
      backgroundColor:
          isError ? const Color(AppColors.error) : const Color(0xFF1A1A1A),
      behavior: SnackBarBehavior.floating,
      margin: EdgeInsets.only(
        left: 16,
        right: 16,
        bottom: MediaQuery.of(context).size.height - 160,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      duration: const Duration(seconds: 2),
    ));
}
