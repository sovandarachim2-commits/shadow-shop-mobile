import 'package:flutter/material.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:provider/provider.dart';
import 'package:shadow_shop_mobile/state/shop_state.dart';
import 'package:url_launcher/url_launcher.dart';

class TelegramAuthButton extends StatelessWidget {
  final String botName;
  const TelegramAuthButton({super.key, required this.botName});

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: () {
        final uri = Uri.parse('https://t.me/$botName');
        launchUrl(uri, mode: LaunchMode.externalApplication);
      },
      icon: const Icon(Icons.telegram, size: 28),
      label: const Text('Telegram'),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 12),
      ),
    );
  }
}
