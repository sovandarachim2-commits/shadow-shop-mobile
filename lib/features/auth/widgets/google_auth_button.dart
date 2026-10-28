import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:provider/provider.dart';
import 'package:shadow_shop_mobile/state/shop_state.dart';

class GoogleAuthButton extends StatelessWidget {
  const GoogleAuthButton({super.key});

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: () async {
        try {
          final googleSignIn = GoogleSignIn();
          final account = await googleSignIn.signIn();
          if (account == null) return;
          final auth = await account.authentication;
          if (auth.idToken != null) {
            final state = context.read<ShopState>();
            final success = await state.loginWithGoogle(auth.idToken!);
            if (!success && context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(state.error ?? 'Google Sign-In failed')));
            }
          }
        } catch (e) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Google Sign-In error: $e')));
          }
        }
      },
      icon: const Icon(Icons.g_mobiledata, size: 28),
      label: const Text('Google'),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 12),
      ),
    );
  }
}
