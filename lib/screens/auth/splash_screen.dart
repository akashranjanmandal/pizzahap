import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../config/app_config.dart';
import '../../providers/providers.dart';

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
    // Force status bar transparent with light icons on dark bg
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
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
    // BG fades in instantly to cover the native splash
    await _bgController.forward();
    // Logo bounces in
    _logoController.forward();
    await Future.delayed(const Duration(milliseconds: 450));
    // App name slides up
    _textController.forward();
    await Future.delayed(const Duration(milliseconds: 250));
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
      // Scaffold bg matches the gradient so there's no white flash
      backgroundColor: const Color(AppColors.primaryDark),
      body: FadeTransition(
        opacity: _bgOpacity,
        child: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(AppColors.primaryDark),
                Color(AppColors.primary),
                Color(AppColors.primaryLight),
              ],
              stops: [0.0, 0.55, 1.0],
            ),
          ),
          child: Stack(
            children: [
              // Decorative circles  subtle depth
              Positioned(
                top: -80,
                right: -60,
                child: Container(
                  width: 240,
                  height: 240,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.05),
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
                    color: Colors.white.withValues(alpha: 0.04),
                  ),
                ),
              ),
              Positioned(
                top: 120,
                left: -30,
                child: Container(
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.03),
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
                      child: Container(
                        width: 128,
                        height: 128,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(32),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.3),
                              blurRadius: 32,
                              offset: const Offset(0, 12),
                            ),
                            BoxShadow(
                              color: Colors.white.withValues(alpha: 0.15),
                              blurRadius: 2,
                              offset: const Offset(0, -1),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(32),
                          child: Image.asset(
                            'assets/images/logo.png',
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const Center(
                              child: Icon(
                                Icons.local_pizza_rounded,
                                size: 72,
                                color: Color(AppColors.primary),
                              ),
                            ),
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
                                color: Colors.white,
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
                                color: Colors.white.withValues(alpha: 0.75),
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
                      child: _SplashLoader(),
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
                      color: Colors.white.withValues(alpha: 0.45),
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

/// Spinning ring loader matching the brand
class _SplashLoader extends StatefulWidget {
  @override
  State<_SplashLoader> createState() => _SplashLoaderState();
}

class _SplashLoaderState extends State<_SplashLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController _spin;

  @override
  void initState() {
    super.initState();
    _spin = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1000))
      ..repeat();
  }

  @override
  void dispose() {
    _spin.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RotationTransition(
      turns: _spin,
      child: SizedBox(
        width: 30,
        height: 30,
        child: CircularProgressIndicator(
          color: Colors.white.withValues(alpha: 0.85),
          strokeWidth: 2.8,
          backgroundColor: Colors.white.withValues(alpha: 0.15),
        ),
      ),
    );
  }
}
