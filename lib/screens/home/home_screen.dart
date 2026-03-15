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
            // ── App Bar ──────────────────────────────────────────
            SliverAppBar(
              expandedHeight: 140,
              floating: false,
              pinned: true,
              snap: false,
              elevation: 0,
              backgroundColor: const Color(AppColors.primaryDark),
              flexibleSpace: FlexibleSpaceBar(
                collapseMode: CollapseMode.pin,
                background: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(AppColors.primaryDark), Color(AppColors.primary)],
                    ),
                  ),
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Hey $firstName! 👋',
                                      style: const TextStyle(
                                        color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w600),
                                    ),
                                    const SizedBox(height: 2),
                                    const Text(
                                      "What's your craving?",
                                      style: TextStyle(
                                        color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800),
                                    ),
                                  ],
                                ),
                              ),
                              // Cart icon
                              GestureDetector(
                                onTap: () => Navigator.pushNamed(context, '/cart'),
                                child: Stack(
                                  clipBehavior: Clip.none,
                                  children: [
                                    Container(
                                      width: 42, height: 42,
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Icon(Icons.shopping_bag_outlined,
                                        color: Colors.white, size: 22),
                                    ),
                                    if (cart.itemCount > 0)
                                      Positioned(
                                        top: -4, right: -4,
                                        child: Container(
                                          padding: const EdgeInsets.all(4),
                                          decoration: const BoxDecoration(
                                            color: Color(AppColors.accent),
                                            shape: BoxShape.circle,
                                          ),
                                          child: Text(
                                            '${cart.itemCount}',
                                            style: const TextStyle(
                                              color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          // Branch chip
                          if (cart.selectedLocationName != null)
                            GestureDetector(
                              onTap: () => Navigator.pushNamed(context, '/branch-selection'),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.location_on, color: Colors.white70, size: 14),
                                  const SizedBox(width: 4),
                                  Text(
                                    cart.selectedLocationName!,
                                    style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600),
                                  ),
                                  const SizedBox(width: 4),
                                  const Icon(Icons.keyboard_arrow_down, color: Colors.white54, size: 16),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              // Search bar pinned at bottom of appbar
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(52),
                child: Container(
                  color: Colors.white,
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  child: GestureDetector(
                    onTap: () => Navigator.pushNamed(context, '/menu'),
                    child: Container(
                      height: 40,
                      decoration: BoxDecoration(
                        color: const Color(AppColors.background),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Row(
                        children: [
                          const SizedBox(width: 12),
                          Icon(Icons.search, color: Colors.grey.shade400, size: 18),
                          const SizedBox(width: 8),
                          Text('Search pizzas, sides...', style: TextStyle(color: Colors.grey.shade400, fontSize: 13)),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // ── Content ──────────────────────────────────────────
            SliverToBoxAdapter(
              child: menu.loading
                ? _Shimmer()
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Promo banner
                      _PromoBanner(),
                      const SizedBox(height: 24),

                      // Categories
                      if (menu.categories.isNotEmpty) ...[
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: SectionHeader(
                            title: 'Categories',
                            onSeeAll: () => Navigator.pushNamed(context, '/menu'),
                          ),
                        ),
                        const SizedBox(height: 12),
                        _CategoriesRow(categories: menu.categories),
                        const SizedBox(height: 24),
                      ],

                      // Featured
                      if (menu.featuredProducts.isNotEmpty) ...[
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: SectionHeader(
                            title: '🔥 Featured',
                            subtitle: 'Our best-sellers',
                            onSeeAll: () => Navigator.pushNamed(context, '/menu'),
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          height: 270,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            itemCount: menu.featuredProducts.length,
                            separatorBuilder: (_, __) => const SizedBox(width: 12),
                            itemBuilder: (ctx, i) {
                              final p = menu.featuredProducts[i];
                              return SizedBox(
                                width: 185,
                                child: ProductCard(
                                  product: p,
                                  onTap: () => Navigator.pushNamed(context, '/product', arguments: p.id),
                                  onAddToCart: () => Navigator.pushNamed(context, '/product', arguments: p.id),
                                ),
                              );
                            },
                          ),
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
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Row(
                          children: [
                            _QuickAction(emoji: '📦', label: 'My Orders',
                              onTap: () => Navigator.pushNamed(context, '/orders')),
                            const SizedBox(width: 10),
                            _QuickAction(emoji: '🎫', label: 'Coupons',
                              onTap: () => Navigator.pushNamed(context, '/coupons')),
                            const SizedBox(width: 10),
                            _QuickAction(emoji: '🆘', label: 'Support',
                              onTap: () => Navigator.pushNamed(context, '/support')),
                          ],
                        ),
                      ),
                      const SizedBox(height: 100),
                    ],
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PromoBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.fromLTRB(20, 20, 20, 0),
    height: 130,
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(18),
      gradient: const LinearGradient(
        colors: [Color(0xFF991515), Color(AppColors.accent)],
        begin: Alignment.topLeft, end: Alignment.bottomRight,
      ),
      boxShadow: [BoxShadow(
        color: const Color(AppColors.primary).withOpacity(0.25),
        blurRadius: 14, offset: const Offset(0, 5),
      )],
    ),
    child: Stack(
      clipBehavior: Clip.hardEdge,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 130, 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.25),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text('🎉 Special Offer',
                  style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
              ),
              const SizedBox(height: 8),
              const Text('Free delivery on\norders above ₹300!',
                style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w800, height: 1.3)),
            ],
          ),
        ),
        const Positioned(
          right: -8, bottom: -12,
          child: Text('🍕', style: TextStyle(fontSize: 100)),
        ),
      ],
    ),
  );
}

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
  Widget build(BuildContext context) => SizedBox(
    height: 88,
    child: ListView.separated(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: categories.length,
      separatorBuilder: (_, __) => const SizedBox(width: 12),
      itemBuilder: (ctx, i) {
        final c = categories[i];
        return GestureDetector(
          onTap: () => Navigator.pushNamed(context, '/menu', arguments: c.id),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56, height: 56,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.07), blurRadius: 8)],
                ),
                child: c.imageUrl != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: PizzaNetImage(url: c.imageUrl, width: 56, height: 56),
                    )
                  : Center(child: Text(_emoji(c.name), style: const TextStyle(fontSize: 26))),
              ),
              const SizedBox(height: 6),
              SizedBox(
                width: 60,
                child: Text(c.name,
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
                  maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center),
              ),
            ],
          ),
        );
      },
    ),
  );
}

class _QuickAction extends StatelessWidget {
  final String emoji, label;
  final VoidCallback onTap;
  const _QuickAction({required this.emoji, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) => Expanded(
    child: GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 24)),
            const SizedBox(height: 5),
            Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
              textAlign: TextAlign.center),
          ],
        ),
      ),
    ),
  );
}

class _Shimmer extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(20),
    child: Shimmer.fromColors(
      baseColor: Colors.grey.shade200,
      highlightColor: Colors.grey.shade100,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(height: 130, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18))),
          const SizedBox(height: 24),
          Container(height: 16, width: 100, color: Colors.white),
          const SizedBox(height: 12),
          Row(children: List.generate(5, (_) => Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Container(width: 56, height: 80, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14))),
          ))),
          const SizedBox(height: 24),
          Container(height: 16, width: 120, color: Colors.white),
          const SizedBox(height: 12),
          Row(children: List.generate(2, (_) => Expanded(child: Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Container(height: 240, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16))),
          )))),
        ],
      ),
    ),
  );
}
