import 'package:flutter/material.dart';
import 'package:shadow_shop_mobile/theme/app_theme.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shadow_shop_mobile/state/shop_state.dart';

class MyCouponsPage extends StatefulWidget {
  const MyCouponsPage({super.key});
  @override
  State<MyCouponsPage> createState() => _MyCouponsPageState();
}

class _MyCouponsPageState extends State<MyCouponsPage> {
  late Future<Map<String, dynamic>> _summary;
  @override
  void initState() {
    super.initState();
    _summary = context.read<ShopState>().service.rewards();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('My coupons')),
        body: FutureBuilder<Map<String, dynamic>>(
            future: _summary,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting)
                return const Center(child: CircularProgressIndicator());
              if (snapshot.hasError)
                return Center(child: Text(snapshot.error.toString()));
              final redemptions =
                  (snapshot.data?['redemptions'] as List? ?? const [])
                      .whereType<Map>()
                      .map((row) => Map<String, dynamic>.from(row))
                      .toList();
              final coupons = redemptions
                  .where((row) =>
                      row['coupon_code'] != null || row['promo_code'] != null)
                  .toList();
              if (coupons.isEmpty)
                return const Center(
                    child: Padding(
                        padding: EdgeInsets.all(24),
                        child: Text(
                            'You do not have any reward coupons yet. Redeem a reward to get started.',
                            textAlign: TextAlign.center)));
              return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: coupons.length,
                  itemBuilder: (context, index) {
                    final coupon = coupons[index];
                    final code =
                        '${coupon['coupon_code'] ?? coupon['promo_code']}';
                    return Card(
                        child: ListTile(
                            leading: const Icon(
                                Icons.confirmation_number_outlined,
                                color: brandColor),
                            title: Text(code,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold)),
                            subtitle:
                                Text('${coupon['status'] ?? 'Available'}'),
                            trailing: IconButton(
                                tooltip: 'Copy coupon',
                                icon: const Icon(Icons.copy),
                                onPressed: () {
                                  Clipboard.setData(ClipboardData(text: code));
                                  ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                          content:
                                              Text('Coupon code copied.')));
                                })));
                  });
            }),
      );
}
