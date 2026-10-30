import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:provider/provider.dart';
import 'package:shadow_shop_mobile/state/shop_state.dart';
import 'package:shadow_shop_mobile/theme/app_theme.dart';
import 'auth_widgets.dart';

class GoogleAuthButton extends StatelessWidget {
  const GoogleAuthButton({super.key, this.label = 'Google'});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: () async {
          try {
            final googleSignIn = GoogleSignIn(
              serverClientId:
                  '668763540471-idel487efgtbu4900h8uh5ph6ptoap4m.apps.googleusercontent.com',
            );
            final account = await googleSignIn.signIn();
            if (account == null) return;
            final auth = await account.authentication;
            final idToken = auth.idToken;
            if (idToken == null || idToken.isEmpty) {
              if (context.mounted) {
                showStoreMessage(
                  context,
                  'Google authentication token was not received. Please try again.',
                  icon: Icons.error_outline_rounded,
                );
              }
              return;
            }
            if (!context.mounted) return;
            final state = context.read<ShopState>();
            final success = await state.loginWithGoogle(idToken);
            if (!context.mounted) return;
            if (success) {
              Navigator.of(context, rootNavigator: true).maybePop(true);
              showStoreMessage(
                context,
                'Welcome, ${state.user?['first_name'] ?? state.user?['username'] ?? 'Customer'}!',
                icon: Icons.check_circle_rounded,
              );
            } else {
              showStoreMessage(
                context,
                state.error ?? 'Google Sign-In failed.',
                icon: Icons.error_outline_rounded,
              );
            }
          } catch (e) {
            if (context.mounted) {
              showStoreMessage(
                context,
                friendlyError(e),
                icon: Icons.error_outline_rounded,
              );
            }
          }
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
              // Real Official Google Logo
              Image.asset(
                'assets/icons/google.png',
                width: 20,
                height: 20,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const Icon(
                  Icons.g_mobiledata_rounded,
                  size: 26,
                  color: Color(0xFF4285F4),
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
