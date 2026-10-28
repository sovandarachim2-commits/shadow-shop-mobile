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
        backgroundColor: const Color(0xFFFCFAFB),
        appBar: AppBar(
          title: const Text(
            'Product sets',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
        ),
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
            if (sets.isEmpty) {
              return const Center(
                  child: Text('No product sets available yet.'));
            }
            return GridView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: sets.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: .66,
              ),
              itemBuilder: (context, index) => _productSetCard(sets[index]),
            );
          },
        ),
      );

  Widget _productSetCard(Map<String, dynamic> item) {
    final id = int.tryParse('${item['id']}') ?? 0;
    final price = double.tryParse('${item['display_price']}') ?? 0;
    final setItems = item['items'] is List ? item['items'] as List : const [];
    final brands = setItems
        .whereType<Map>()
        .map((setItem) => '${setItem['brand_name'] ?? ''}'.trim())
        .where((brand) => brand.isNotEmpty)
        .toSet()
        .join(', ');
    final product = Product(
      id: id,
      productSetId: id,
      isProductSet: true,
      name: '${item['name'] ?? 'Product set'}',
      description: '${item['description'] ?? ''}',
      imageUrl: item['image_url']?.toString(),
      price: price,
      oldPrice: double.tryParse('${item['old_price']}'),
      stock: int.tryParse('${item['current_stock']}') ?? 0,
      available: item['is_available_for_sale'] != false,
      availabilityStatus: (item['availability_status'] ?? 'auto').toString(),
      isFlashSale: item['is_flash_sale_active'] == true,
      flashSaleMaxOrderQty: int.tryParse('${item['flash_sale_max_order_qty']}'),
    );

    return Card(
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
              padding: const EdgeInsets.all(5),
              child: product.imageUrl == null
                  ? const Icon(
                      Icons.inventory_2_outlined,
                      size: 44,
                      color: brandColor,
                    )
                  : Image.network(
                      product.imageUrl!,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => const Icon(
                        Icons.inventory_2_outlined,
                        size: 40,
                        color: brandColor,
                      ),
                    ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(13, 10, 13, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  brands.isEmpty ? 'Product set' : brands,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF667085),
                    fontWeight: FontWeight.w700,
                  ),
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
                if (product.description.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    product.description,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF667085),
                      fontSize: 11,
                    ),
                  ),
                ],
                const SizedBox(height: 7),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '\$${product.price.toStringAsFixed(2)}',
                        style: const TextStyle(
                          color: brandColor,
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 40,
                      height: 40,
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
                          foregroundColor: brandColor,
                          disabledForegroundColor: const Color(0xFFD0D5DD),
                          padding: EdgeInsets.zero,
                        ),
                        tooltip: 'Add product set to cart',
                        icon: const Icon(Icons.add_rounded, size: 24),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
