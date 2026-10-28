import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shadow_shop_mobile/state/shop_state.dart';
import 'package:shadow_shop_mobile/theme/app_theme.dart';
import 'package:shadow_shop_mobile/features/customer/cart/checkout_screen.dart';

class CartView extends StatelessWidget {
  const CartView({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<ShopState>();
    if (state.cartLines.isEmpty)
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.shopping_bag_outlined, size: 56, color: brandColor),
            SizedBox(height: 12),
            Text(
              'Your cart is empty',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text('Add products from the shop to get started.'),
          ],
        ),
      );
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        for (final line in state.cartLines)
          Card(
            child: ListTile(
              leading: SizedBox(
                width: 48,
                height: 48,
                child: line.product.imageUrl == null
                    ? const Icon(Icons.spa_outlined)
                    : Image.network(
                        line.product.imageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            const Icon(Icons.spa_outlined),
                      ),
              ),
              title: Text(
                line.product.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Text('${line.total.toStringAsFixed(2)}'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    onPressed: () =>
                        state.setQuantity(line.product, line.quantity - 1),
                    icon: const Icon(Icons.remove_circle_outline),
                  ),
                  Text('${line.quantity}'),
                  IconButton(
                    onPressed: () =>
                        state.setQuantity(line.product, line.quantity + 1),
                    icon: const Icon(Icons.add_circle_outline),
                  ),
                ],
              ),
            ),
          ),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Subtotal',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
                Text(
                  '${state.subtotal.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                    color: brandColor,
                  ),
                ),
              ],
            ),
          ),
        ),
        FilledButton.icon(
          onPressed: () => Navigator.of(context)
              .push(MaterialPageRoute(builder: (_) => const CheckoutScreen())),
          icon: const Icon(Icons.lock_outline),
          label: const Text('Continue to checkout'),
        ),
      ],
    );
  }
}
