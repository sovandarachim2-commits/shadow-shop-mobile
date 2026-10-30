import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shadow_shop_mobile/services/api_client.dart';
import 'package:shadow_shop_mobile/state/shop_state.dart';
import 'package:shadow_shop_mobile/theme/app_theme.dart';
import 'forgot_password_screen.dart';
import 'register_screen.dart';
import 'widgets/auth_widgets.dart';
import 'widgets/google_auth_button.dart';
import 'widgets/telegram_auth_button.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _rememberMe = true;

  static const _rememberMeKey = 'shadow_shop_remember_me';
  static const _savedUsernameKey = 'shadow_shop_saved_username';

  @override
  void initState() {
    super.initState();
    _loadRememberedUser();
  }

  Future<void> _loadRememberedUser() async {
    try {
      final rememberVal = await ApiClient.storage.read(key: _rememberMeKey);
      final savedUsername = await ApiClient.storage.read(key: _savedUsernameKey);
      if (mounted) {
        setState(() {
          _rememberMe = rememberVal != 'false';
          if (_rememberMe && savedUsername != null && savedUsername.isNotEmpty) {
            _usernameCtrl.text = savedUsername;
          }
        });
      }
    } catch (_) {}
  }

  Future<void> _saveRememberMe() async {
    try {
      await ApiClient.storage.write(key: _rememberMeKey, value: _rememberMe ? 'true' : 'false');
      if (_rememberMe) {
        await ApiClient.storage.write(key: _savedUsernameKey, value: _usernameCtrl.text.trim());
      } else {
        await ApiClient.storage.delete(key: _savedUsernameKey);
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _usernameCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    final state = context.read<ShopState>();
    await _saveRememberMe();

    final success = await state.login(_usernameCtrl.text.trim(), _passwordCtrl.text);
    if (!success && mounted) {
      showStoreMessage(
        context,
        state.error ?? 'Unable to sign in. Please check your credentials.',
        icon: Icons.error_outline_rounded,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isBusy = context.watch<ShopState>().busy;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const AuthHeader(
                      title: 'Welcome Back',
                      subtitle: 'Sign in to access your rewards, cart, and exclusive orders.',
                    ),
                    const SizedBox(height: 32),

                    // Username / Email / Phone input
                    CustomTextField(
                      controller: _usernameCtrl,
                      label: 'Email, Phone Number, or Username',
                      hintText: 'Enter email, phone, or username',
                      prefixIcon: Icons.person_outline_rounded,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      validator: AuthValidator.emailOrPhone,
                      autofillHints: const [AutofillHints.username, AutofillHints.email],
                    ),
                    const SizedBox(height: 18),

                    // Password input with visibility toggle
                    PasswordTextField(
                      controller: _passwordCtrl,
                      label: 'Password',
                      hintText: 'Enter your password',
                      textInputAction: TextInputAction.done,
                      validator: (v) => AuthValidator.required(v, 'Enter your password'),
                      onFieldSubmitted: (_) => _handleLogin(),
                    ),
                    const SizedBox(height: 12),

                    // Remember Me & Forgot Password Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        InkWell(
                          onTap: () => setState(() => _rememberMe = !_rememberMe),
                          borderRadius: BorderRadius.circular(6),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: Checkbox(
                                    value: _rememberMe,
                                    activeColor: kAuthPrimary,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                                    onChanged: (val) => setState(() => _rememberMe = val ?? true),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Text(
                                  'Remember me',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: kAuthTextDark,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ForgotPasswordScreen(
                                  initialEmail: _usernameCtrl.text.contains('@') ? _usernameCtrl.text.trim() : null,
                                ),
                              ),
                            );
                          },
                          style: TextButton.styleFrom(
                            foregroundColor: kAuthPrimary,
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: const Text(
                            'Forgot Password?',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: kAuthPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Primary Sign In Button
                    PrimaryAuthButton(
                      label: 'Sign In',
                      isLoading: isBusy,
                      onPressed: _handleLogin,
                    ),
                    const SizedBox(height: 24),

                    // Divider
                    const AuthDivider(),
                    const SizedBox(height: 20),

                    // Social login buttons
                    const Row(
                      children: [
                        Expanded(child: GoogleAuthButton(label: 'Google')),
                        SizedBox(width: 12),
                        Expanded(
                          child: TelegramAuthButton(
                            botName: 'ShadowShopBot',
                            label: 'Telegram',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),

                    // Navigate to Register
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          "Don't have an account?",
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: kAuthTextMuted,
                          ),
                        ),
                        const SizedBox(width: 6),
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const RegisterScreen()),
                            );
                          },
                          child: const Text(
                            'Create Account',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                              color: kAuthSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
