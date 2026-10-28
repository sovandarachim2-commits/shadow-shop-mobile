import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shadow_shop_mobile/models/product.dart';
import 'package:shadow_shop_mobile/state/shop_state.dart';
import 'package:shadow_shop_mobile/theme/app_theme.dart';
import 'package:shadow_shop_mobile/features/customer/products/widgets/product_card.dart';

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
    final ids = state.wishlistIds.toSet();
    final products = await state.service.products();
    return products.where((item) => ids.contains(item.id)).toList();
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<List<Product>>(
        future: _items,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting)
            return const Center(child: CircularProgressIndicator());
          if (snapshot.hasError)
            return Center(child: Text(friendlyError(snapshot.error)));
          final products = snapshot.data ?? [];
          if (products.isEmpty)
            return const Center(
                child: Column(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.favorite_border, size: 50, color: brandColor),
              SizedBox(height: 10),
              Text('Your saved products will appear here.')
            ]));
          return GridView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: products.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: .66),
              itemBuilder: (_, index) => ProductCard(product: products[index]));
        },
      );
}
