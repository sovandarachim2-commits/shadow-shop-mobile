import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shadow_shop_mobile/features/customer/products/widgets/product_card.dart';
import 'package:shadow_shop_mobile/features/customer/cart/cart_screen.dart';
import 'package:shadow_shop_mobile/models/product.dart';
import 'package:shadow_shop_mobile/state/shop_state.dart';
import 'package:shadow_shop_mobile/theme/app_theme.dart';

class ProductDetailScreen extends StatefulWidget {
  const ProductDetailScreen({super.key, required this.product});
  final Product product;

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  late Future<List<Product>> _recommendations;
  int _selectedQuantity = 1;

  Product get product => widget.product;

  @override
  void initState() {
    super.initState();
    _recommendations = _loadRecommendations();
  }

  Future<List<Product>> _loadRecommendations() async {
    final service = context.read<ShopState>().service;
    if (product.categoryId != null) {
      final categoryProducts = await service.products(
        categoryId: product.categoryId,
        limit: 9,
      );
      final sameCategory = categoryProducts
          .where((item) => item.id != product.id)
          .take(8)
          .toList();
      if (sameCategory.isNotEmpty) return sameCategory;
    }

    final recommended = await service.products(limit: 12);
    return recommended.where((item) => item.id != product.id).take(8).toList();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<ShopState>();
    final quantity = state.cartLines
            .where((line) => line.product.id == product.id)
            .firstOrNull
            ?.quantity ??
        0;
    final orderLimit = product.maxOrderQuantity;
    final remainingQuantity = orderLimit == null
        ? null
        : (orderLimit - quantity).clamp(0, orderLimit);
    final canAddSelected = product.canAddMore(quantity) &&
        (remainingQuantity == null || _selectedQuantity <= remainingQuantity);
    final displayedQuantity = remainingQuantity == 0
        ? 1
        : remainingQuantity == null || _selectedQuantity <= remainingQuantity
            ? _selectedQuantity
            : remainingQuantity;
    final saved = state.wishlistIds.contains(product.id);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Product'),
        actions: [
          IconButton(
            onPressed: () async {
              try {
                await context.read<ShopState>().toggleWishlist(product);
                if (!context.mounted) return;
                showStoreMessage(
                  context,
                  saved ? 'Removed from wishlist' : 'Added to wishlist',
                  icon: saved
                      ? Icons.favorite_border_rounded
                      : Icons.favorite_rounded,
                );
              } catch (error) {
                if (!context.mounted) return;
                ScaffoldMessenger.of(context)
                  ..hideCurrentSnackBar()
                  ..showSnackBar(
                    SnackBar(content: Text(friendlyError(error))),
                  );
              }
            },
            icon: Icon(saved ? Icons.favorite : Icons.favorite_border,
                color: saved ? brandColor : null),
            tooltip: 'Wishlist',
          ),
          IconButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => Scaffold(
                  appBar: AppBar(title: const Text('Cart')),
                  body: const CartView(),
                ),
              ),
            ),
            tooltip: 'Cart',
            icon: Badge(
              isLabelVisible: state.itemCount > 0,
              label: Text('${state.itemCount}'),
              child: const Icon(Icons.shopping_bag_outlined),
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: Color(0xFFF2E8ED))),
          ),
          child: Row(
            children: [
              Container(
                height: 52,
                padding: const EdgeInsets.symmetric(horizontal: 6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: const Color(0xFFE4E7EC)),
                  borderRadius: BorderRadius.circular(28),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _quantityButton(
                      icon: Icons.remove_rounded,
                      tooltip: 'Decrease quantity',
                      onPressed: _selectedQuantity > 1
                          ? () => setState(() => _selectedQuantity--)
                          : null,
                    ),
                    SizedBox(
                      width: 34,
                      child: Text(
                        '$displayedQuantity',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    _quantityButton(
                      icon: Icons.add_rounded,
                      tooltip: 'Increase quantity',
                      onPressed: remainingQuantity == null ||
                              _selectedQuantity < remainingQuantity
                          ? () => setState(() => _selectedQuantity++)
                          : null,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SizedBox(
                  height: 52,
                  child: FilledButton(
                    onPressed: canAddSelected
                        ? () {
                            context.read<ShopState>().setQuantity(
                                  product,
                                  quantity + displayedQuantity,
                                );
                            showStoreMessage(
                              context,
                              'Added to cart',
                              icon: Icons.check_circle_rounded,
                            );
                            setState(() => _selectedQuantity = 1);
                          }
                        : null,
                    style: FilledButton.styleFrom(
                      backgroundColor: brandColor,
                      disabledBackgroundColor: const Color(0xFFEAECF0),
                      foregroundColor: Colors.white,
                      disabledForegroundColor: const Color(0xFF98A2B3),
                      shape: const StadiumBorder(),
                      textStyle: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.add_shopping_cart_rounded, size: 19),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            canAddSelected
                                ? 'Add to cart · \$${(product.price * displayedQuantity).toStringAsFixed(2)}'
                                : 'Out of stock',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      body: ListView(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: AspectRatio(
            aspectRatio: 1,
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFBFD),
                borderRadius: BorderRadius.circular(24),
              ),
              child: product.imageUrl == null
                  ? const Icon(
                      Icons.spa_outlined,
                      size: 80,
                      color: brandColor,
                    )
                  : Image.network(
                      product.imageUrl!,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => const Icon(
                        Icons.image_not_supported_outlined,
                        size: 70,
                      ),
                    ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                product.brandName.isNotEmpty
                    ? product.brandName
                    : product.categoryName,
                style: const TextStyle(
                  color: Color(0xFF667085),
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                product.name,
                style: const TextStyle(
                  fontSize: 25,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  if (product.rating > 0) ...[
                    const Icon(Icons.star_rounded,
                        color: Color(0xFFFFC107), size: 20),
                    const SizedBox(width: 4),
                    Text(
                      product.rating.toStringAsFixed(1),
                      style: const TextStyle(
                        color: Color(0xFF475467),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                  _availabilityBadge(product),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 10,
                runSpacing: 8,
                children: [
                  Text(
                    '\$${product.price.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 30,
                      color: brandColor,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  if (product.oldPrice != null &&
                      product.oldPrice! > product.price) ...[
                    Text(
                      '\$${product.oldPrice!.toStringAsFixed(2)}',
                      style: const TextStyle(
                        color: Color(0xFF98A2B3),
                        fontSize: 16,
                        decoration: TextDecoration.lineThrough,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFDF2F8),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'Save \$${(product.oldPrice! - product.price).toStringAsFixed(2)}',
                        style: const TextStyle(
                          color: brandColor,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 16),
              const Divider(height: 1),
              if (product.description.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(product.description, style: const TextStyle(height: 1.5)),
              ],
              const SizedBox(height: 28),
              _recommendationsSection(),
            ],
          ),
        )
      ]),
    );
  }

  Widget _recommendationsSection() => FutureBuilder<List<Product>>(
        future: _recommendations,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'You may also like',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Recommendations could not be loaded.',
                        style: TextStyle(color: Color(0xFF667085)),
                      ),
                    ),
                    TextButton(
                      onPressed: () => setState(
                          () => _recommendations = _loadRecommendations()),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ],
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const SizedBox(
              height: 245,
              child: Center(child: CircularProgressIndicator()),
            );
          }

          final recommendations = snapshot.data ?? const <Product>[];
          if (recommendations.isEmpty) return const SizedBox.shrink();
          final sectionTitle = product.categoryName.isNotEmpty
              ? 'More from ${product.categoryName}'
              : 'You may also like';

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                sectionTitle,
                style:
                    const TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 270,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: recommendations.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (context, index) => SizedBox(
                    width: 170,
                    child: ProductCard(product: recommendations[index]),
                  ),
                ),
              ),
            ],
          );
        },
      );

  Widget _availabilityBadge(Product product) {
    final inStock = product.canAddMore(0);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
      decoration: BoxDecoration(
        color: inStock ? const Color(0xFFECFDF3) : const Color(0xFFFEF3F2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.circle,
            size: 7,
            color: inStock ? const Color(0xFF12B76A) : const Color(0xFFF04438),
          ),
          const SizedBox(width: 6),
          Text(
            inStock ? 'IN STOCK' : 'OUT OF STOCK',
            style: TextStyle(
              color:
                  inStock ? const Color(0xFF039855) : const Color(0xFFD92D20),
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _quantityButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback? onPressed,
  }) =>
      SizedBox(
        width: 38,
        height: 40,
        child: IconButton(
          onPressed: onPressed,
          tooltip: tooltip,
          padding: EdgeInsets.zero,
          visualDensity: VisualDensity.compact,
          color: brandColor,
          disabledColor: const Color(0xFFD0D5DD),
          icon: Icon(icon, size: 21),
        ),
      );
}
