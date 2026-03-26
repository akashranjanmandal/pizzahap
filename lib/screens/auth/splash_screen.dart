import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../config/app_config.dart';
import '../../providers/providers.dart';
import '../../widgets/app_loader.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _bgController;
  late AnimationController _logoController;
  late AnimationController _textController;
  late AnimationController _loaderController;

  late Animation<double> _bgOpacity;
  late Animation<double> _logoScale;
  late Animation<double> _logoOpacity;
  late Animation<double> _textFade;
  late Animation<Offset> _textSlide;
  late Animation<double> _loaderFade;

  @override
  void initState() {
    super.initState();
    // Force status bar dark icons on white bg
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ));

    _bgController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400));
    _logoController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800));
    _textController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _loaderController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400));

    _bgOpacity = CurvedAnimation(parent: _bgController, curve: Curves.easeOut);

    _logoScale = Tween<double>(begin: 0.25, end: 1.0).animate(
        CurvedAnimation(parent: _logoController, curve: Curves.elasticOut));
    _logoOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(
        parent: _logoController,
        curve: const Interval(0, 0.35, curve: Curves.easeOut)));

    _textFade = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _textController, curve: Curves.easeOut));
    _textSlide = Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero)
        .animate(CurvedAnimation(
            parent: _textController, curve: Curves.easeOutCubic));

    _loaderFade = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _loaderController, curve: Curves.easeIn));

    _runSequence();
    _init();
  }

  Future<void> _runSequence() async {
    if (!mounted) return;
    // BG fades in instantly to cover the native splash
    await _bgController.forward();
    if (!mounted) return;
    // Logo bounces in
    _logoController.forward();
    await Future.delayed(const Duration(milliseconds: 450));
    if (!mounted) return;
    // App name slides up
    _textController.forward();
    await Future.delayed(const Duration(milliseconds: 250));
    if (!mounted) return;
    // Loader appears
    _loaderController.forward();
  }

  Future<void> _init() async {
    // Wait at least 1.8s so the animation is fully visible
    await Future.delayed(const Duration(milliseconds: 1800));
    if (!mounted) return;
    await context.read<AuthProvider>().init();
    if (!mounted) return;
    // Give a small buffer after auth init
    await Future.delayed(const Duration(milliseconds: 300));
    if (!mounted) return;

    // Restore normal status bar
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ));

    final auth = context.read<AuthProvider>();
    if (auth.isLoggedIn) {
      final cart = context.read<CartProvider>();
      if (cart.selectedLocationId == null) {
        Navigator.pushReplacementNamed(context, '/branch-selection');
      } else {
        Navigator.pushReplacementNamed(context, '/home');
      }
    } else {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  @override
  void dispose() {
    _bgController.dispose();
    _logoController.dispose();
    _textController.dispose();
    _loaderController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // White background as requested
      backgroundColor: Colors.white,
      body: FadeTransition(
        opacity: _bgOpacity,
        child: Container(
          width: double.infinity,
          height: double.infinity,
          color: Colors.white,
          child: Stack(
            children: [
              // Subtle decorative accent — soft brand colored circles
              Positioned(
                top: -80,
                right: -60,
                child: Container(
                  width: 240,
                  height: 240,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(AppColors.primary).withValues(alpha: 0.06),
                  ),
                ),
              ),
              Positioned(
                bottom: -100,
                left: -70,
                child: Container(
                  width: 300,
                  height: 300,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(AppColors.primary).withValues(alpha: 0.04),
                  ),
                ),
              ),

              // Main content
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Logo with bounce animation
                    AnimatedBuilder(
                      animation: _logoController,
                      builder: (_, child) => Opacity(
                        opacity: _logoOpacity.value,
                        child: Transform.scale(
                          scale: _logoScale.value,
                          child: child,
                        ),
                      ),
                      child: Image.asset(
                        'assets/images/logo.png',
                        width: double.infinity,
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => const Center(
                          child: Icon(
                            Icons.local_pizza_rounded,
                            size: 120,
                            color: Color(AppColors.primary),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 28),

                    // App name + tagline
                    SlideTransition(
                      position: _textSlide,
                      child: FadeTransition(
                        opacity: _textFade,
                        child: Column(
                          children: [
                            const Text(
                              AppConfig.appName,
                              style: TextStyle(
                                color: Color(AppColors.primary),
                                fontSize: 42,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -1.0,
                                height: 1.0,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Hot, fresh & delivered with love',
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                                letterSpacing: 0.2,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 60),

                    // Loader
                    FadeTransition(
                      opacity: _loaderFade,
                      child: const PizzaSpinner(size: 40),
                    ),
                  ],
                ),
              ),

              // Footer
              Positioned(
                bottom: 32,
                left: 0,
                right: 0,
                child: FadeTransition(
                  opacity: _loaderFade,
                  child: Text(
                    'Developed by GOBT',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.grey.shade400,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

