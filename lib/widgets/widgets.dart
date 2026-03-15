import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import '../config/app_config.dart';
import '../models/models.dart';

// ─── PIZZA NET IMAGE ──────────────────────────────────────────────

class PizzaNetImage extends StatelessWidget {
  final String? url;
  final double? width, height;
  final BoxFit fit;
  final BorderRadius? borderRadius;

  const PizzaNetImage({
    super.key, this.url, this.width, this.height,
    this.fit = BoxFit.cover, this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final widget = url != null && url!.isNotEmpty
      ? CachedNetworkImage(
          imageUrl: url!,
          width: width, height: height, fit: fit,
          placeholder: (ctx, url) => _shimmer(),
          errorWidget: (ctx, url, err) => _placeholder(),
        )
      : _placeholder();

    if (borderRadius != null) {
      return ClipRRect(borderRadius: borderRadius!, child: widget);
    }
    return widget;
  }

  Widget _shimmer() => Shimmer.fromColors(
    baseColor: Colors.grey.shade200,
    highlightColor: Colors.grey.shade100,
    child: Container(width: width, height: height, color: Colors.white),
  );

  Widget _placeholder() => Container(
    width: width, height: height,
    color: const Color(0xFFFFF0EE),
    child: const Center(child: Text('🍕', style: TextStyle(fontSize: 32))),
  );
}

// ─── VEG BADGE ────────────────────────────────────────────────────

class VegBadge extends StatelessWidget {
  final bool isVeg;
  const VegBadge({super.key, required this.isVeg});

  @override
  Widget build(BuildContext context) => Container(
    width: 18, height: 18,
    decoration: BoxDecoration(
      border: Border.all(
        color: isVeg ? const Color(AppColors.vegGreen) : const Color(AppColors.nonVegRed),
        width: 1.5,
      ),
      borderRadius: BorderRadius.circular(3),
    ),
    child: Center(
      child: Container(
        width: 10, height: 10,
        decoration: BoxDecoration(
          color: isVeg ? const Color(AppColors.vegGreen) : const Color(AppColors.nonVegRed),
          shape: BoxShape.circle,
        ),
      ),
    ),
  );
}

// ─── PRODUCT CARD ─────────────────────────────────────────────────

class ProductCard extends StatelessWidget {
  final Product product;
  final VoidCallback onTap;
  final VoidCallback? onAddToCart;

  const ProductCard({super.key, required this.product, required this.onTap, this.onAddToCart});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              PizzaNetImage(
                url: product.imageUrl, height: 140, width: double.infinity,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16), topRight: Radius.circular(16),
                ),
              ),
              Positioned(top: 10, left: 10, child: VegBadge(isVeg: product.isVeg)),
              if (product.isFeatured)
                Positioned(
                  top: 10, right: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(AppColors.accent),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text('⭐ Featured', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700)),
                  ),
                ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(product.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                  maxLines: 1, overflow: TextOverflow.ellipsis),
                if (product.description != null) ...[
                  const SizedBox(height: 2),
                  Text(product.description!, style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    maxLines: 2, overflow: TextOverflow.ellipsis),
                ],
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('₹${product.basePrice.toStringAsFixed(0)}',
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: Color(AppColors.primary))),
                    GestureDetector(
                      onTap: onAddToCart ?? onTap,
                      child: Container(
                        width: 32, height: 32,
                        decoration: const BoxDecoration(color: Color(AppColors.primary), shape: BoxShape.circle),
                        child: const Icon(Icons.add, color: Colors.white, size: 18),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

// ─── ORDER STATUS CHIP ────────────────────────────────────────────

class OrderStatusChip extends StatelessWidget {
  final String status;
  const OrderStatusChip({super.key, required this.status});

  Color get _color {
    switch (status) {
      case 'pending': return const Color(AppColors.warning);
      case 'confirmed': return Colors.blue;
      case 'preparing': return Colors.orange;
      case 'out_for_delivery': return Colors.indigo;
      case 'delivered': return const Color(AppColors.success);
      case 'cancelled': return const Color(AppColors.error);
      default: return Colors.grey;
    }
  }

  String get _label {
    switch (status) {
      case 'pending': return '⏳ Pending';
      case 'confirmed': return '✅ Confirmed';
      case 'preparing': return '👨‍🍳 Preparing';
      case 'out_for_delivery': return '🛵 On the way';
      case 'delivered': return '🎉 Delivered';
      case 'cancelled': return '❌ Cancelled';
      default: return status;
    }
  }

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      color: _color.withOpacity(0.12),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(_label, style: TextStyle(color: _color, fontSize: 12, fontWeight: FontWeight.w700)),
  );
}

// ─── SECTION HEADER ───────────────────────────────────────────────

class SectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final VoidCallback? onSeeAll;

  const SectionHeader({super.key, required this.title, this.subtitle, this.onSeeAll});

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            if (subtitle != null)
              Text(subtitle!, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
          ],
        ),
      ),
      if (onSeeAll != null)
        TextButton(
          onPressed: onSeeAll,
          child: const Text('See all', style: TextStyle(color: Color(AppColors.primary), fontWeight: FontWeight.w700)),
        ),
    ],
  );
}

// ─── EMPTY STATE ──────────────────────────────────────────────────

class EmptyState extends StatelessWidget {
  final String emoji;
  final String title;
  final String? subtitle;
  final String? buttonText;
  final VoidCallback? onButton;

  const EmptyState({
    super.key, required this.emoji, required this.title,
    this.subtitle, this.buttonText, this.onButton,
  });

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 64)),
          const SizedBox(height: 16),
          Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800), textAlign: TextAlign.center),
          if (subtitle != null) ...[
            const SizedBox(height: 8),
            Text(subtitle!, style: TextStyle(fontSize: 14, color: Colors.grey.shade600), textAlign: TextAlign.center),
          ],
          if (buttonText != null && onButton != null) ...[
            const SizedBox(height: 24),
            SizedBox(
              width: 200,
              child: ElevatedButton(onPressed: onButton, child: Text(buttonText!)),
            ),
          ],
        ],
      ),
    ),
  );
}

// ─── PRICE ROW ────────────────────────────────────────────────────

class PriceRow extends StatelessWidget {
  final String label;
  final double amount;
  final bool isBold;
  final Color? color;

  const PriceRow({super.key, required this.label, required this.amount, this.isBold = false, this.color});

  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(label, style: TextStyle(
        fontSize: isBold ? 16 : 14,
        fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
        color: color ?? (isBold ? const Color(AppColors.textPrimary) : Colors.grey.shade700),
      )),
      Text('₹${amount.toStringAsFixed(2)}', style: TextStyle(
        fontSize: isBold ? 18 : 14,
        fontWeight: isBold ? FontWeight.w800 : FontWeight.w600,
        color: color ?? (isBold ? const Color(AppColors.primary) : const Color(AppColors.textPrimary)),
      )),
    ],
  );
}

// ─── LOADING OVERLAY ──────────────────────────────────────────────

class LoadingOverlay extends StatelessWidget {
  final bool loading;
  final Widget child;
  const LoadingOverlay({super.key, required this.loading, required this.child});

  @override
  Widget build(BuildContext context) => Stack(
    children: [
      child,
      if (loading)
        Container(
          color: Colors.black26,
          child: const Center(child: CircularProgressIndicator(color: Color(AppColors.primary))),
        ),
    ],
  );
}

// ─── QUANTITY STEPPER ─────────────────────────────────────────────

class QuantityStepper extends StatelessWidget {
  final int value;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;

  const QuantityStepper({super.key, required this.value, required this.onIncrement, required this.onDecrement});

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      _btn(Icons.remove, onDecrement),
      Container(
        width: 36, alignment: Alignment.center,
        child: Text('$value', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
      ),
      _btn(Icons.add, onIncrement),
    ],
  );

  Widget _btn(IconData icon, VoidCallback onTap) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: 32, height: 32,
      decoration: BoxDecoration(
        color: const Color(AppColors.primary).withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(icon, color: const Color(AppColors.primary), size: 18),
    ),
  );
}

// ─── SNACK HELPER ─────────────────────────────────────────────────

void showSnack(BuildContext context, String message, {bool isError = false}) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor: isError ? const Color(AppColors.error) : const Color(0xFF1A1A1A),
    ),
  );
}
