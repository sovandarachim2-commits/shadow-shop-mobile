import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shadow_shop_mobile/state/shop_state.dart';
import 'package:shadow_shop_mobile/theme/app_theme.dart';

class OrderDetailScreen extends StatelessWidget {
  const OrderDetailScreen({super.key, required this.orderId});
  final int orderId;

  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: AppBar(title: const Text('Order details')),
      body: FutureBuilder<Map<String, dynamic>>(
          future: context.read<ShopState>().service.orderDetail(orderId),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text(friendlyError(snapshot.error)));
            }
            final order = snapshot.data ?? {};
            final items = order['items'] as List? ?? const [];
            final history = order['status_history'] as List? ?? const [];
            return ListView(padding: const EdgeInsets.all(16), children: [
              Card(
                  child: ListTile(
                      leading:
                          const CircleAvatar(child: Icon(Icons.receipt_long)),
                      title: Text('#${order['order_number'] ?? order['id']}',
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(
                          '${order['status'] ?? 'New'} · ${order['payment_status'] ?? 'unpaid'}'))),
              const Padding(
                  padding: EdgeInsets.fromLTRB(4, 18, 4, 8),
                  child: Text('Items',
                      style: TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold))),
              for (final raw in items)
                Builder(builder: (context) {
                  final item = Map<String, dynamic>.from(raw as Map);
                  return Card(
                      child: ListTile(
                          title: Text(item['product_name']?.toString() ??
                              item['product_code']?.toString() ??
                              'Product'),
                          subtitle: Text('Qty ${item['quantity'] ?? 1}'),
                          trailing: Text(
                              '\$${formatPrice(item['total_price'] ?? item['unit_price'])}')));
                }),
              Card(
                  child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(children: [
                        summaryLine('Subtotal', order['subtotal']),
                        summaryLine('Delivery', order['delivery_fee']),
                        summaryLine('Discount', order['discount']),
                        const Divider(),
                        summaryLine('Total', order['grand_total'], bold: true)
                      ]))),
              const Padding(
                  padding: EdgeInsets.fromLTRB(4, 18, 4, 8),
                  child: Text('Status updates',
                      style: TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold))),
              for (final raw in history)
                Builder(builder: (context) {
                  final event = Map<String, dynamic>.from(raw as Map);
                  return ListTile(
                      leading: const Icon(Icons.radio_button_checked,
                          color: brandColor),
                      title: Text(event['status']?.toString() ?? 'Updated'),
                      subtitle: Text(
                          '${event['note'] ?? ''} ${event['created_at'] ?? ''}'));
                })
            ]);
          }));
}

Widget summaryLine(String label, dynamic raw, {bool bold = false}) {
  final value = raw is num ? raw.toDouble() : double.tryParse('$raw') ?? 0;
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(children: [
      Expanded(
        child: Text(label,
            style: TextStyle(fontWeight: bold ? FontWeight.bold : null)),
      ),
      Text('\$${value.toStringAsFixed(2)}',
          style: TextStyle(
              fontWeight: bold ? FontWeight.bold : null,
              color: bold ? brandColor : null)),
    ]),
  );
}
