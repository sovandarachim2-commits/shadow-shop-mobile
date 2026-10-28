import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shadow_shop_mobile/models/product.dart';
import 'package:shadow_shop_mobile/state/shop_state.dart';
import 'package:shadow_shop_mobile/theme/app_theme.dart';

class ProductDetailScreen extends StatelessWidget {
  const ProductDetailScreen({super.key, required this.product});
  final Product product;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<ShopState>();
    final quantity = state.cartLines
            .where((line) => line.product.id == product.id)
            .firstOrNull
            ?.quantity ??
        0;
    final saved = state.wishlistIds.contains(product.id);
    return Scaffold(
      appBar: AppBar(title: const Text('Product'), actions: [
        IconButton(
            onPressed: () async {
              try {
                await context.read<ShopState>().toggleWishlist(product);
              } catch (_) {}
            },
            icon: Icon(saved ? Icons.favorite : Icons.favorite_border,
                color: saved ? brandColor : null))
      ]),
      bottomNavigationBar: SafeArea(
          child: Padding(
              padding: const EdgeInsets.all(16),
              child: FilledButton.icon(
                  onPressed: product.available && product.stock > quantity
                      ? () => context.read<ShopState>().add(product)
                      : null,
                  icon: const Icon(Icons.shopping_bag_outlined),
                  label: Text(quantity > 0
                      ? 'Add another · $quantity in cart'
                      : 'Add to cart')))),
      body: ListView(children: [
        AspectRatio(
            aspectRatio: 1,
            child: Container(
                color: const Color(0xFFF9FAFB),
                child: product.imageUrl == null
                    ? const Icon(Icons.spa_outlined,
                        size: 80, color: brandColor)
                    : Image.network(product.imageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Icon(
                            Icons.image_not_supported_outlined,
                            size: 70)))),
        Padding(
            padding: const EdgeInsets.all(20),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(product.categoryName.toUpperCase(),
                  style:
                      TextStyle(color: Colors.grey.shade600, letterSpacing: 1)),
              const SizedBox(height: 8),
              Text(product.name,
                  style: const TextStyle(
                      fontSize: 24, fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              Text('\$${product.price.toStringAsFixed(2)}',
                  style: const TextStyle(
                      fontSize: 22,
                      color: brandColor,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Text(
                  product.available && product.stock > 0
                      ? 'In stock · ${product.stock} available'
                      : 'Currently out of stock',
                  style: TextStyle(
                      color: product.available && product.stock > 0
                          ? Colors.green
                          : Colors.red)),
              const Divider(height: 28),
              Text(
                  product.description.isEmpty
                      ? 'Product details are available from the Shadow Shop team.'
                      : product.description,
                  style: const TextStyle(height: 1.5))
            ]))
      ]),
    );
  }
}
