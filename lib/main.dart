import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'providers/providers.dart';
import 'utils/app_theme.dart';

import 'screens/auth/splash_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/auth/branch_selection_screen.dart';

import 'screens/main_shell.dart';
import 'screens/menu/menu_screen.dart';
import 'screens/menu/product_detail_screen.dart';
import 'screens/cart/cart_screen.dart';
import 'screens/cart/checkout_screen.dart';
import 'screens/orders/orders_screen.dart';
import 'screens/orders/order_detail_screen.dart';
import 'screens/orders/order_confirm_screen.dart';
import 'screens/orders/coins_screen.dart';
import 'screens/support/support_screens.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
  ));
  runApp(const PizzaHapApp());
}

class PizzaHapApp extends StatelessWidget {
  const PizzaHapApp({super.key});

  @override
  Widget build(BuildContext context) => MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (_) => AuthProvider()),
      ChangeNotifierProvider(create: (_) => CartProvider()),
      ChangeNotifierProvider(create: (_) => MenuProvider()),
      ChangeNotifierProvider(create: (_) => OrderProvider()),
      ChangeNotifierProvider(create: (_) => CoinsProvider()),
      ChangeNotifierProvider(create: (_) => NotificationProvider()),
    ],
    child: MaterialApp(
      title: 'PizzaHap',
      theme: AppTheme.theme,
      debugShowCheckedModeBanner: false,
      navigatorKey: navigatorKey,
      initialRoute: '/splash',
      onGenerateRoute: _generateRoute,
    ),
  );

  static Route<dynamic> _generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case '/splash':      return _fade(const SplashScreen());
      case '/login':       return _slide(const LoginScreen());
      case '/register':    return _slide(const RegisterScreen());
      case '/branch-selection': return _slide(const BranchSelectionScreen());

      case '/home':        return _fade(const MainShell());
      case '/cart':
        final cartArgs = settings.arguments;
        if (cartArgs is Map && cartArgs['autoCoupon'] != null) {
          return _slide(CartScreen(autoCoupon: cartArgs['autoCoupon'] as String));
        }
        return _fade(const MainShell(initialTab: 2));
      case '/menu':
        final catId = settings.arguments as int?;
        return _slide(MenuScreen(initialCategoryId: catId));
      case '/product':
        return _slide(ProductDetailScreen(productId: settings.arguments as int));
      case '/checkout':    return _slide(const CheckoutScreen());
      case '/order-confirm':
        final args = settings.arguments as Map<String, dynamic>;
        return _slide(OrderConfirmScreen(
          orderId: args['order_id'],
          orderNumber: args['order_number'],
          total: (args['total'] ?? 0).toDouble(),
          coinsRedeemed: args['coins_redeemed'] ?? 0,
        ));
      case '/orders':      return _slide(const OrdersScreen());
      case '/order-detail':
        return _slide(OrderDetailScreen(orderId: settings.arguments as int));
      case '/coins':       return _slide(const CoinsScreen());
      case '/support':     return _slide(const SupportScreen());
      case '/notifications': return _slide(const NotificationsScreen());
      case '/ticket-detail':
        return _slide(TicketDetailScreen(ticketId: settings.arguments as int));
      case '/refunds':     return _slide(const RefundsScreen());
      case '/coupons':     return _slide(const CouponsScreen());
      default:             return _fade(const MainShell());
    }
  }

  static PageRoute _slide(Widget page) => PageRouteBuilder(
    pageBuilder: (_, __, ___) => page,
    transitionsBuilder: (_, anim, __, child) => SlideTransition(
      position: Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero)
          .animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
      child: child,
    ),
    transitionDuration: const Duration(milliseconds: 280),
  );

  static PageRoute _fade(Widget page) => PageRouteBuilder(
    pageBuilder: (_, __, ___) => page,
    transitionsBuilder: (_, anim, __, child) => FadeTransition(opacity: anim, child: child),
    transitionDuration: const Duration(milliseconds: 220),
  );
}
