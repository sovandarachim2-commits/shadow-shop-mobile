import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shadow_shop_mobile/models/product.dart';
import 'package:shadow_shop_mobile/state/shop_state.dart';
import 'package:shadow_shop_mobile/theme/app_theme.dart';
import 'package:shadow_shop_mobile/features/customer/products/product_detail_screen.dart';

class ProductCard extends StatelessWidget {
  const ProductCard({super.key, required this.product});
  final Product product;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<ShopState>();
    final line = state.cartLines
        .where((item) => item.product.cartKey == product.cartKey)
        .firstOrNull;
    final favorite = state.wishlistIds.contains(product.id);
    return InkWell(
        onTap: () => Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => ProductDetailScreen(product: product))),
        borderRadius: BorderRadius.circular(18),
        child: Card(
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Container(
                  width: double.infinity,
                  color: const Color(0xFFF9FAFB),
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: product.imageUrl == null
                            ? const Center(
                                child: Icon(
                                  Icons.spa_outlined,
                                  size: 44,
                                  color: brandColor,
                                ),
                              )
                            : Padding(
                                padding: const EdgeInsets.all(8),
                                child: Image.network(
                                  product.imageUrl!,
                                  fit: BoxFit.contain,
                                  errorBuilder: (_, __, ___) => const Center(
                                    child: Icon(
                                      Icons.image_not_supported_outlined,
                                      size: 40,
                                    ),
                                  ),
                                )),
                      ),
                      if (product.oldPrice != null &&
                          product.oldPrice! > product.price)
                        Positioned(
                          left: 8,
                          top: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 9, vertical: 5),
                            decoration: BoxDecoration(
                                color: brandColor,
                                borderRadius: BorderRadius.circular(20)),
                            child: Text(
                                '-${((1 - product.price / product.oldPrice!) * 100).round()}%',
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w900)),
                          ),
                        ),
                      Positioned(
                        right: 6,
                        top: 6,
                        child: IconButton.filledTonal(
                          onPressed: () async {
                            try {
                              await context
                                  .read<ShopState>()
                                  .toggleWishlist(product);
                            } catch (_) {}
                          },
                          style: IconButton.styleFrom(
                              backgroundColor: const Color(0xFFFFDFEA),
                              foregroundColor: brandColor),
                          icon: Icon(
                              favorite
                                  ? Icons.favorite_rounded
                                  : Icons.favorite_border_rounded,
                              color: favorite
                                  ? const Color(0xFFE11D68)
                                  : const Color(0xFF725A66)),
                          visualDensity: VisualDensity.compact,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 9, 10, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.brandName.isEmpty
                          ? product.categoryName.isEmpty
                              ? 'SHADOW SHOP'
                              : product.categoryName.toUpperCase()
                          : product.brandName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 9,
                        color: Colors.grey.shade600,
                        letterSpacing: .8,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      product.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        height: 1.15,
                      ),
                    ),
                    if (product.rating > 0)
                      Padding(
                        padding: const EdgeInsets.only(top: 5),
                        child: Row(children: [
                          const Icon(Icons.star_rounded,
                              size: 14, color: Color(0xFFF4B400)),
                          const SizedBox(width: 3),
                          Text(product.rating.toStringAsFixed(1),
                              style: TextStyle(
                                  fontSize: 11, color: Colors.grey.shade600)),
                        ]),
                      ),
                    const SizedBox(height: 7),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(product.price.toStringAsFixed(2),
                                  style: const TextStyle(
                                      color: brandColor,
                                      fontWeight: FontWeight.w900,
                                      fontSize: 16)),
                              if (product.oldPrice != null &&
                                  product.oldPrice! > product.price)
                                Text(product.oldPrice!.toStringAsFixed(2),
                                    style: TextStyle(
                                        color: Colors.grey.shade500,
                                        fontSize: 10,
                                        decoration:
                                            TextDecoration.lineThrough)),
                            ],
                          ),
                        ),
                        if (line == null)
                          IconButton.filledTonal(
                            onPressed: product.available && product.stock > 0
                                ? () => context.read<ShopState>().add(product)
                                : null,
                            style: IconButton.styleFrom(
                                backgroundColor: const Color(0xFFFFDCE8),
                                foregroundColor: const Color(0xFFD81B60)),
                            icon: const Icon(Icons.add_rounded, size: 22),
                            visualDensity: VisualDensity.compact,
                          )
                        else
                          _quantityControl(context, line.quantity),
                      ],
                    ),
                    if (!product.available || product.stock < 1)
                      Text(
                        'Out of stock',
                        style:
                            TextStyle(color: Colors.red.shade700, fontSize: 11),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ));
  }

  Widget _quantityControl(BuildContext context, int quantity) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            onPressed: () =>
                context.read<ShopState>().setQuantity(product, quantity - 1),
            icon: const Icon(Icons.remove, size: 18),
            visualDensity: VisualDensity.compact,
          ),
          Text('$quantity',
              style: const TextStyle(fontWeight: FontWeight.bold)),
          IconButton(
            onPressed: product.stock > quantity
                ? () =>
                    context.read<ShopState>().setQuantity(product, quantity + 1)
                : null,
            icon: const Icon(Icons.add, size: 18),
            visualDensity: VisualDensity.compact,
          ),
        ],
      );
}
