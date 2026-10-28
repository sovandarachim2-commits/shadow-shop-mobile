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
    return InkWell(
        onTap: () => Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => ProductDetailScreen(product: product))),
        borderRadius: BorderRadius.circular(18),
        child: Card(
          margin: EdgeInsets.zero,
          color: Colors.white,
          elevation: 1.5,
          shadowColor: const Color(0x0F101828),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: const BorderSide(color: Color(0xFFF2E8ED)),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Container(
                  width: double.infinity,
                  color: const Color(0xFFFFFBFD),
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
                                padding: const EdgeInsets.all(5),
                                child: Image.network(
                                  product.imageUrl!,
                                  fit: BoxFit.contain,
                                  filterQuality: FilterQuality.medium,
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
                                horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                                color: brandColor,
                                borderRadius: BorderRadius.circular(20)),
                            child: Text(
                                '-${((1 - product.price / product.oldPrice!) * 100).round()}%',
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w900)),
                          ),
                        ),
                      if (!product.available || product.maxOrderQuantity == 0)
                        Positioned(
                          left: 10,
                          bottom: 10,
                          child: _stockBadge(
                            label: 'Out of stock',
                            background: const Color(0xFFFEE4E2),
                            foreground: const Color(0xFFB42318),
                          ),
                        )
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(13, 10, 13, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            product.brandName.isEmpty
                                ? 'No brand'
                                : product.brandName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF667085),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        if (product.rating > 0) ...[
                          const SizedBox(width: 4),
                          const Icon(Icons.star_rounded,
                              size: 14, color: Color(0xFFF4B400)),
                          const SizedBox(width: 2),
                          Text(
                            product.rating.toStringAsFixed(1),
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade600,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      product.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        height: 1.12,
                      ),
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
                                      fontSize: 18)),
                              if (product.oldPrice != null &&
                                  product.oldPrice! > product.price)
                                Text(product.oldPrice!.toStringAsFixed(2),
                                    style: TextStyle(
                                        color: Colors.grey.shade500,
                                        fontSize: 11,
                                        decoration:
                                            TextDecoration.lineThrough)),
                            ],
                          ),
                        ),
                        if (line == null)
                          SizedBox(
                            width: 44,
                            height: 44,
                            child: IconButton(
                              onPressed: product.canAddMore(0)
                                  ? () {
                                      context.read<ShopState>().add(product);
                                      showStoreMessage(
                                        context,
                                        'Added to cart',
                                        icon: Icons.check_circle_rounded,
                                      );
                                    }
                                  : null,
                              style: IconButton.styleFrom(
                                  foregroundColor: const Color(0xFFD81B60)),
                              tooltip: 'Add to cart',
                              icon: const Icon(Icons.add_rounded, size: 24),
                            ),
                          )
                        else
                          _quantityControl(context, line.quantity),
                      ],
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
          _quantityButton(
            icon: Icons.remove,
            onPressed: () =>
                context.read<ShopState>().setQuantity(product, quantity - 1),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Text('$quantity',
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
          ),
          _quantityButton(
            icon: Icons.add,
            onPressed: product.canAddMore(quantity)
                ? () {
                    context
                        .read<ShopState>()
                        .setQuantity(product, quantity + 1);
                    showStoreMessage(
                      context,
                      'Added to cart',
                      icon: Icons.check_circle_rounded,
                    );
                  }
                : null,
          ),
        ],
      );

  Widget _stockBadge({
    required String label,
    required Color background,
    required Color foreground,
  }) =>
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: foreground,
            fontSize: 10,
            fontWeight: FontWeight.w800,
          ),
        ),
      );

  Widget _quantityButton({
    required IconData icon,
    required VoidCallback? onPressed,
  }) =>
      SizedBox(
        width: 30,
        height: 34,
        child: IconButton(
          onPressed: onPressed,
          padding: EdgeInsets.zero,
          icon: Icon(icon, size: 19),
          color: brandColor,
          disabledColor: const Color(0xFFD0D5DD),
          visualDensity: VisualDensity.compact,
        ),
      );
}
