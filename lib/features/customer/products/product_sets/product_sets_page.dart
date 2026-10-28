import 'package:flutter/material.dart';
import 'package:shadow_shop_mobile/theme/app_theme.dart';
import 'package:provider/provider.dart';
import 'package:shadow_shop_mobile/models/product.dart';
import 'package:shadow_shop_mobile/state/shop_state.dart';

class ProductSetsPage extends StatefulWidget {
  const ProductSetsPage({super.key});
  @override
  State<ProductSetsPage> createState() => _ProductSetsPageState();
}

class _ProductSetsPageState extends State<ProductSetsPage> {
  late Future<List<Map<String, dynamic>>> _sets;

  @override
  void initState() {
    super.initState();
    _sets = context.read<ShopState>().service.productSets();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Product sets')),
        body: FutureBuilder<List<Map<String, dynamic>>>(
          future: _sets,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text(snapshot.error.toString()));
            }
            final sets = snapshot.data ?? [];
            if (sets.isEmpty)
              return const Center(
                  child: Text('No product sets available yet.'));
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: sets.length,
              itemBuilder: (context, index) {
                final item = sets[index];
                final id = int.tryParse('${item['id']}') ?? 0;
                final price = double.tryParse('${item['display_price']}') ?? 0;
                final product = Product(
                  id: id,
                  productSetId: id,
                  isProductSet: true,
                  name: '${item['name'] ?? 'Product set'}',
                  description: '${item['description'] ?? ''}',
                  imageUrl: item['image_url']?.toString(),
                  price: price,
                  stock: int.tryParse('${item['current_stock']}') ?? 0,
                );
                return Card(
                  clipBehavior: Clip.antiAlias,
                  margin: const EdgeInsets.only(bottom: 14),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (product.imageUrl != null)
                          Image.network(product.imageUrl!,
                              height: 190,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => const SizedBox(
                                  height: 100,
                                  child: Icon(Icons.inventory_2_outlined,
                                      size: 40))),
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(product.name,
                                    style: const TextStyle(
                                        fontSize: 19,
                                        fontWeight: FontWeight.bold)),
                                if (product.description.isNotEmpty) ...[
                                  const SizedBox(height: 6),
                                  Text(product.description),
                                ],
                                const SizedBox(height: 10),
                                Row(children: [
                                  Expanded(
                                      child: Text(
                                          '\$${price.toStringAsFixed(2)}',
                                          style: const TextStyle(
                                              color: brandColor,
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold))),
                                  FilledButton.icon(
                                    onPressed: product.stock > 0
                                        ? () {
                                            context
                                                .read<ShopState>()
                                                .add(product);
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(const SnackBar(
                                                    content: Text(
                                                        'Product set added to cart.')));
                                          }
                                        : null,
                                    icon: const Icon(Icons.add_shopping_cart),
                                    label: const Text('Add to cart'),
                                  ),
                                ]),
                              ]),
                        ),
                      ]),
                );
              },
            );
          },
        ),
      );
}
