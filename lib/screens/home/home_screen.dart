import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import '../../providers/providers.dart';
import '../../config/app_config.dart';
import '../../widgets/widgets.dart';
import '../../models/models.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MenuProvider>().loadHomeData();
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final menu = context.watch<MenuProvider>();
    final cart = context.watch<CartProvider>();
    final firstName = auth.user?.name.split(' ').first ?? 'there';

    return Scaffold(
      backgroundColor: const Color(AppColors.background),
      body: RefreshIndicator(
        color: const Color(AppColors.primary),
        onRefresh: () => context.read<MenuProvider>().loadHomeData(),
        child: CustomScrollView(
          slivers: [
            // ── App Bar ────────────────────────────────────────
// ── App Bar ────────────────────────────────────────
            SliverAppBar(
              expandedHeight: 120,
              floating: false,
              pinned: true,
              snap: false,
              elevation: 0,
              backgroundColor: const Color(AppColors.primaryDark),
              automaticallyImplyLeading: false,
              flexibleSpace: FlexibleSpaceBar(
                collapseMode: CollapseMode.pin,
                background: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(AppColors.primaryDark),
                        Color(AppColors.primary)
                      ],
                    ),
                  ),
                  // Add padding that accounts for status bar AND ensures content stays at top
                  child: Padding(
                    padding: EdgeInsets.only(
                      top: MediaQuery.of(context).padding.top + 10, // Status bar + small padding
                      left: 20,
                      right: 20,
                      bottom: 10, // Add bottom padding to prevent content from being pushed down
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start, // Changed to start
                      children: [
                        Expanded(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.start, // Align to start
                            children: [
                              Text(
                                'Hey $firstName! 👋',
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 2),
                              if (cart.selectedLocationName != null) ...[
                                const SizedBox(height: 2),
                                GestureDetector(
                                  onTap: () => Navigator.pushNamed(
                                      context, '/branch-selection'),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.location_on,
                                        color: Colors.white70,
                                        size: 12,
                                      ),
                                      const SizedBox(width: 3),
                                      Flexible(
                                        child: Text(
                                          cart.selectedLocationName!,
                                          style: const TextStyle(
                                            color: Colors.white70,
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      const Icon(
                                        Icons.keyboard_arrow_down,
                                        color: Colors.white54,
                                        size: 13,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Cart icon
                        GestureDetector(
                          onTap: () => Navigator.pushNamed(context, '/cart'),
                          child: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.shopping_bag_outlined,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                              if (cart.itemCount > 0)
                                Positioned(
                                  top: -4,
                                  right: -4,
                                  child: Container(
                                    width: 18,
                                    height: 18,
                                    decoration: const BoxDecoration(
                                      color: Color(AppColors.accent),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Center(
                                      child: Text(
                                        '${cart.itemCount}',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 10,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              // Search bar pinned at bottom of appbar
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(50),
                child: Container(
                  color: Colors.white,
                  height: 50, // Explicit height
                  padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
                  child: GestureDetector(
                    onTap: () => Navigator.pushNamed(context, '/menu'),
                    child: Container(
                      height: 38,
                      decoration: BoxDecoration(
                        color: const Color(AppColors.background),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Row(
                        children: [
                          const SizedBox(width: 10),
                          Icon(
                            Icons.search,
                            color: Colors.grey.shade400,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Search pizzas, sides...',
                            style: TextStyle(
                                color: Colors.grey.shade400,
                                fontSize: 13
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            // ── Content ──────────────────────────────────────
            SliverPadding(
              padding: const EdgeInsets.only(bottom: 100),
              sliver: SliverToBoxAdapter(
                child: menu.loading
                    ? const _Shimmer()
                    : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 20),

                    // ── Auto-sliding promo banner ──────
                    const _PromoBannerSlider(),
                    const SizedBox(height: 24),

                    // Categories
                    if (menu.categories.isNotEmpty) ...[
                      Padding(
                        padding:
                        const EdgeInsets.symmetric(horizontal: 20),
                        child: SectionHeader(
                          title: 'Categories',
                          onSeeAll: () =>
                              Navigator.pushNamed(context, '/menu'),
                        ),
                      ),
                      const SizedBox(height: 12),
                      _CategoriesRow(categories: menu.categories),
                      const SizedBox(height: 24),
                    ],

                    // Featured
                    if (menu.featuredProducts.isNotEmpty) ...[
                      Padding(
                        padding:
                        const EdgeInsets.symmetric(horizontal: 20),
                        child: SectionHeader(
                          title: '🔥 Featured',
                          subtitle: 'Our best-sellers',
                          onSeeAll: () =>
                              Navigator.pushNamed(context, '/menu'),
                        ),
                      ),
                      const SizedBox(height: 12),
                      LayoutBuilder(
                        builder: (ctx, constraints) {
                          final cardW = constraints.maxWidth * 0.47;
                          return SizedBox(
                            height: cardW * 1.5,
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 20),
                              itemCount: menu.featuredProducts.length,
                              separatorBuilder: (_, __) =>
                              const SizedBox(width: 12),
                              itemBuilder: (ctx, i) {
                                final p = menu.featuredProducts[i];
                                return SizedBox(
                                  width: cardW,
                                  child: ProductCard(
                                    product: p,
                                    onTap: () => Navigator.pushNamed(
                                        context, '/product',
                                        arguments: p.id),
                                    onAddToCart: () =>
                                        Navigator.pushNamed(
                                            context, '/product',
                                            arguments: p.id),
                                  ),
                                );
                              },
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 24),
                    ],

                    // Quick actions
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20),
                      child: SectionHeader(title: '⚡ Quick Actions'),
                    ),
                    const SizedBox(height: 12),
                    Padding(
                      padding:
                      const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        children: [
                          _QuickAction(
                            emoji: '📦',
                            label: 'My Orders',
                            onTap: () =>
                                Navigator.pushNamed(context, '/orders'),
                          ),
                          const SizedBox(width: 10),
                          _QuickAction(
                            emoji: '🎫',
                            label: 'Coupons',
                            onTap: () =>
                                Navigator.pushNamed(context, '/coupons'),
                          ),
                          const SizedBox(width: 10),
                          _QuickAction(
                            emoji: '🆘',
                            label: 'Support',
                            onTap: () => Navigator.pushNamed(
                                context, '/support'),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── AUTO-SLIDING PROMO BANNER SLIDER ────────────────────────────

class _PromoBannerSlider extends StatefulWidget {
  const _PromoBannerSlider();
  @override
  State<_PromoBannerSlider> createState() => _PromoBannerSliderState();
}

class _PromoBannerSliderState extends State<_PromoBannerSlider> {
  final _pageCtrl = PageController(viewportFraction: 0.9);
  int _currentPage = 0;
  Timer? _timer;

  static const _banners = [
    _BannerData(
      gradient: [Color(0xFF991515), Color(AppColors.accent)],
      emoji: '🍕',
      badge: '🎉 Special Offer',
      title: 'Free delivery on\norders above ₹300!',
    ),
    _BannerData(
      gradient: [Color(0xFF1A1A8C), Color(0xFF4040E0)],
      emoji: '🤩',
      badge: '🔥 New Arrivals',
      title: 'Try our new\nsignature pizzas!',
    ),
    _BannerData(
      gradient: [Color(0xFF166534), Color(0xFF22C55E)],
      emoji: '🥗',
      badge: '🥦 Healthy Choice',
      title: 'Fresh veg pizzas\nwith extra toppings!',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted) return;
      final next = (_currentPage + 1) % _banners.length;
      _pageCtrl.animateToPage(
        next,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 140,
          child: PageView.builder(
            controller: _pageCtrl,
            itemCount: _banners.length,
            onPageChanged: (i) => setState(() => _currentPage = i),
            itemBuilder: (ctx, i) {
              final b = _banners[i];
              return _BannerCard(data: b);
            },
          ),
        ),
        const SizedBox(height: 10),
        // Dot indicators
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            _banners.length,
                (i) => AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: _currentPage == i ? 20 : 6,
              height: 6,
              decoration: BoxDecoration(
                color: _currentPage == i
                    ? const Color(AppColors.primary)
                    : Colors.grey.shade300,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _BannerData {
  final List<Color> gradient;
  final String emoji, badge, title;
  const _BannerData({
    required this.gradient,
    required this.emoji,
    required this.badge,
    required this.title,
  });
}

class _BannerCard extends StatelessWidget {
  final _BannerData data;
  const _BannerCard({required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: LinearGradient(
          colors: data.gradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: data.gradient.first.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 5),
          )
        ],
      ),
      child: Stack(
        clipBehavior: Clip.hardEdge,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 110, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.25),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    data.badge,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w700),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  data.title,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      height: 1.3),
                ),
              ],
            ),
          ),
          Positioned(
            right: -8,
            bottom: -10,
            child: Text(
              data.emoji,
              style: const TextStyle(fontSize: 88),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── CATEGORIES ROW ──────────────────────────────────────────────

class _CategoriesRow extends StatelessWidget {
  final List<Category> categories;
  const _CategoriesRow({required this.categories});

  String _emoji(String name) {
    final n = name.toLowerCase();
    if (n.contains('pizza')) return '🍕';
    if (n.contains('pasta') || n.contains('noodle')) return '🍝';
    if (n.contains('burger')) return '🍔';
    if (n.contains('dessert') || n.contains('sweet')) return '🍰';
    if (n.contains('drink') || n.contains('bev')) return '🥤';
    if (n.contains('salad')) return '🥗';
    if (n.contains('side') || n.contains('starter')) return '🧆';
    return '🍽️';
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 90,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (ctx, i) {
          final c = categories[i];
          return GestureDetector(
            onTap: () => Navigator.pushNamed(context, '/menu',
                arguments: c.id),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withOpacity(0.07),
                          blurRadius: 8)
                    ],
                  ),
                  child: c.imageUrl != null
                      ? ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: PizzaNetImage(
                        url: c.imageUrl!, width: 56, height: 56),
                  )
                      : Center(
                    child: Text(
                      _emoji(c.name),
                      style: const TextStyle(fontSize: 26),
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                SizedBox(
                  width: 64,
                  child: Text(
                    c.name,
                    style: const TextStyle(
                        fontSize: 11, fontWeight: FontWeight.w700),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ─── QUICK ACTION ────────────────────────────────────────────────

class _QuickAction extends StatelessWidget {
  final String emoji, label;
  final VoidCallback onTap;
  const _QuickAction({
    required this.emoji,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2))
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                emoji,
                style: const TextStyle(fontSize: 24),
              ),
              const SizedBox(height: 5),
              Text(
                label,
                style: const TextStyle(
                    fontSize: 11, fontWeight: FontWeight.w700),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── SHIMMER ─────────────────────────────────────────────────────

class _Shimmer extends StatelessWidget {
  const _Shimmer();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Shimmer.fromColors(
        baseColor: Colors.grey.shade300,
        highlightColor: Colors.grey.shade100,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 140,
              decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18)),
            ),
            const SizedBox(height: 24),
            Container(
              height: 16,
              width: 100,
              color: Colors.white,
            ),
            const SizedBox(height: 12),
            Row(
              children: List.generate(
                5,
                    (_) => Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: Container(
                    width: 56,
                    height: 80,
                    decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Container(
              height: 16,
              width: 120,
              color: Colors.white,
            ),
            const SizedBox(height: 12),
            Row(
              children: List.generate(
                2,
                    (_) => Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: AspectRatio(
                      aspectRatio: 0.75,
                      child: Container(
                        decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16)),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}