import 'package:flutter/material.dart';
import 'auth_widgets.dart';
import 'telegram_auth_sheet.dart';

class TelegramAuthButton extends StatelessWidget {
  const TelegramAuthButton({
    super.key,
    this.botName = 'invoicesheets_bot',
    this.label = 'Telegram',
  });

  final String botName;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: () {
          showTelegramAuthSheet(context);
        },
        borderRadius: BorderRadius.circular(14),
        child: Container(
          height: 48,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: kAuthBorder),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Real Official Telegram Logo
              Image.asset(
                'assets/icons/telegram.png',
                width: 22,
                height: 22,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const Icon(
                  Icons.send_rounded,
                  size: 20,
                  color: Color(0xFF229ED9),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: kAuthTextDark,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
