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
    if (state.cartLines.isEmpty) {
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
    }
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        for (final line in state.cartLines)
          Card(
            child: Column(
              children: [
                ListTile(
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
                  subtitle: Text(
                    line.total.toStringAsFixed(2),
                    style: const TextStyle(
                      color: brandColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        onPressed: () =>
                            state.setQuantity(line.product, line.quantity - 1),
                        color: brandColor,
                        icon: const Icon(Icons.remove_rounded),
                      ),
                      Text(
                        line.quantity.toString(),
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      IconButton(
                        onPressed: line.product.canAddMore(line.quantity)
                            ? () => state.setQuantity(
                                line.product, line.quantity + 1)
                            : null,
                        color: brandColor,
                        disabledColor: const Color(0xFFD0D5DD),
                        icon: const Icon(Icons.add_rounded),
                      ),
                    ],
                  ),
                ),
                if (!line.product.available ||
                    line.product.maxOrderQuantity == 0)
                  const Padding(
                    padding: EdgeInsets.fromLTRB(16, 0, 16, 12),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Currently out of stock. Remove this item or try again later.',
                        style: TextStyle(
                          color: Color(0xFFB42318),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  )
                else if (line.product.maxOrderQuantity != null &&
                    line.quantity >= line.product.maxOrderQuantity!)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Maximum available quantity: ${line.product.maxOrderQuantity}',
                        style: const TextStyle(
                          color: Color(0xFF667085),
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
              ],
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
                  state.subtotal.toStringAsFixed(2),
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
