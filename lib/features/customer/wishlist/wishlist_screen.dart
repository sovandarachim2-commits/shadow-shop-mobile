import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shadow_shop_mobile/models/product.dart';
import 'package:shadow_shop_mobile/state/shop_state.dart';
import 'package:shadow_shop_mobile/theme/app_theme.dart';
import 'package:shadow_shop_mobile/features/customer/products/widgets/product_card.dart';
import 'package:shadow_shop_mobile/features/customer/cart/cart_screen.dart';
import 'package:shadow_shop_mobile/features/auth/auth_modal_sheet.dart';

class WishlistView extends StatefulWidget {
  const WishlistView({super.key});
  @override
  State<WishlistView> createState() => _WishlistViewState();
}

class _WishlistViewState extends State<WishlistView> {
  late Future<List<Product>> _items;

  @override
  void initState() {
    super.initState();
    _items = _load();
  }

  Future<List<Product>> _load() async {
    final state = context.read<ShopState>();
    if (state.user == null) return [];
    await state.loadWishlist();
    final ids = state.wishlistIds.toSet();
    final products = await state.service.products();
    return products.where((item) => ids.contains(item.id)).toList();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('Wishlist'),
          actions: [
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
                isLabelVisible: context.watch<ShopState>().itemCount > 0,
                label: Text('${context.watch<ShopState>().itemCount}'),
                child: const Icon(Icons.shopping_bag_outlined),
              ),
            ),
          ],
        ),
        body: FutureBuilder<List<Product>>(
          future: _items,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        friendlyError(snapshot.error),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton(
                        onPressed: () => setState(() => _items = _load()),
                        child: const Text('Try again'),
                      ),
                    ],
                  ),
                ),
              );
            }
            final products = snapshot.data ?? [];
            if (context.read<ShopState>().user == null) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(28),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(18),
                        decoration: const BoxDecoration(
                          color: Color(0xFFFCE7F3),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.favorite_border_rounded, size: 48, color: brandColor),
                      ),
                      const SizedBox(height: 18),
                      const Text(
                        'Save your favorite items',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Sign in to sync your wishlist across all your devices.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Color(0xFF64748B), height: 1.4),
                      ),
                      const SizedBox(height: 22),
                      FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: brandColor,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        onPressed: () => showAuthModal(context),
                        icon: const Icon(Icons.login_rounded, size: 20),
                        label: const Text('Sign In / Register', style: TextStyle(fontWeight: FontWeight.w800)),
                      ),
                    ],
                  ),
                ),
              );
            }
            if (products.isEmpty) {
              return const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.favorite_border, size: 50, color: brandColor),
                    SizedBox(height: 10),
                    Text('Your saved products will appear here.'),
                  ],
                ),
              );
            }
            return GridView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: products.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: .58,
              ),
              itemBuilder: (_, index) => ProductCard(product: products[index]),
            );
          },
        ),
      );
}
