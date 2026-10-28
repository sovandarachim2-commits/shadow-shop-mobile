import 'package:flutter/material.dart';
import 'package:shadow_shop_mobile/theme/app_theme.dart';

class LuckyBoxPage extends StatelessWidget {
  const LuckyBoxPage({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: AppBar(title: const Text('Lucky Box')),
      body: Center(
          child: Padding(
              padding: const EdgeInsets.all(28),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Container(
                    width: 92,
                    height: 92,
                    decoration: BoxDecoration(
                        color: brandColor,
                        borderRadius: BorderRadius.circular(28)),
                    child: const Icon(Icons.card_giftcard,
                        color: Colors.white, size: 44)),
                const SizedBox(height: 20),
                const Text('Coming Soon',
                    style:
                        TextStyle(fontSize: 28, fontWeight: FontWeight.w900)),
                const SizedBox(height: 8),
                const Text(
                    'We are preparing this feature for customers. You can continue shopping products now.',
                    textAlign: TextAlign.center),
                const SizedBox(height: 20),
                FilledButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Continue shopping'))
              ]))));
}
