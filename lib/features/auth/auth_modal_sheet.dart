import 'dart:async';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shadow_shop_mobile/services/api_client.dart';
import 'package:shadow_shop_mobile/state/shop_state.dart';
import 'package:shadow_shop_mobile/theme/app_theme.dart';
import 'forgot_password_screen.dart';
import 'widgets/auth_widgets.dart';
import 'widgets/google_auth_button.dart';
import 'widgets/telegram_auth_button.dart';

Future<bool?> showAuthModal(BuildContext context, {String initialView = 'login'}) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.55),
    builder: (modalContext) => AuthModalSheet(initialView: initialView),
  );
}

class AuthModalSheet extends StatefulWidget {
  const AuthModalSheet({super.key, this.initialView = 'login'});

  final String initialView;

  @override
  State<AuthModalSheet> createState() => _AuthModalSheetState();
}

class _AuthModalSheetState extends State<AuthModalSheet> {
  late bool _isLogin;

  // Login form controllers
  final _loginFormKey = GlobalKey<FormState>();
  final _loginIdentifierCtrl = TextEditingController();
  final _loginPasswordCtrl = TextEditingController();
  bool _rememberMe = true;

  // Register form controllers
  final _regFormKey = GlobalKey<FormState>();
  final _fullNameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _regPasswordCtrl = TextEditingController();
  final _confirmPasswordCtrl = TextEditingController();
  bool _agreeTerms = false;

  // Registration OTP step
  bool _codeSent = false;
  final _codeCtrl = TextEditingController();
  int _resendCountdown = 0;
  Timer? _resendTimer;
  bool _busy = false;

  static const _rememberMeKey = 'shadow_shop_remember_me';
  static const _savedUsernameKey = 'shadow_shop_saved_username';

  @override
  void initState() {
    super.initState();
    _isLogin = widget.initialView == 'login';
    _loadRememberedUser();
  }

  @override
  void dispose() {
    _resendTimer?.cancel();
    _loginIdentifierCtrl.dispose();
    _loginPasswordCtrl.dispose();
    _fullNameCtrl.dispose();
    _emailCtrl.dispose();
    _regPasswordCtrl.dispose();
    _confirmPasswordCtrl.dispose();
    _codeCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadRememberedUser() async {
    try {
      final rememberVal = await ApiClient.storage.read(key: _rememberMeKey);
      final savedUsername = await ApiClient.storage.read(key: _savedUsernameKey);
      if (mounted) {
        setState(() {
          _rememberMe = rememberVal != 'false';
          if (_rememberMe && savedUsername != null && savedUsername.isNotEmpty) {
            _loginIdentifierCtrl.text = savedUsername;
          }
        });
      }
    } catch (_) {}
  }

  Future<void> _saveRememberMe() async {
    try {
      await ApiClient.storage.write(key: _rememberMeKey, value: _rememberMe.toString());
      if (_rememberMe) {
        await ApiClient.storage.write(
          key: _savedUsernameKey,
          value: _loginIdentifierCtrl.text.trim(),
        );
      } else {
        await ApiClient.storage.delete(key: _savedUsernameKey);
      }
    } catch (_) {}
  }

  Future<void> _handleLogin() async {
    if (!_loginFormKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();

    final state = context.read<ShopState>();
    await _saveRememberMe();

    final success = await state.login(
      _loginIdentifierCtrl.text.trim(),
      _loginPasswordCtrl.text,
    );

    if (!mounted) return;
    if (success) {
      Navigator.of(context).pop(true);
    } else {
      showStoreMessage(
        context,
        state.error ?? 'Unable to sign in. Please check your credentials.',
        icon: Icons.error_outline_rounded,
      );
    }
  }

  Future<void> _handleRegister() async {
    if (!_regFormKey.currentState!.validate()) return;

    if (!_agreeTerms) {
      showStoreMessage(
        context,
        'Please accept the Terms & Conditions to create an account.',
        icon: Icons.info_outline_rounded,
      );
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() => _busy = true);

    try {
      final names = _fullNameCtrl.text.trim().split(' ');
      final firstName = names.isNotEmpty ? names.first : '';
      final lastName = names.length > 1 ? names.sublist(1).join(' ') : '';

      final payload = {
        'email': _emailCtrl.text.trim(),
        'first_name': firstName,
        'last_name': lastName,
        'password': _regPasswordCtrl.text,
        'confirm_password': _confirmPasswordCtrl.text,
        'role': 'customer',
      };

      final service = context.read<ShopState>().service;
      final result = await service.register(payload);

      if (!mounted) return;
      setState(() => _codeSent = true);
      showStoreMessage(
        context,
        result['detail']?.toString() ?? 'Verification code sent to your email.',
        icon: Icons.mark_email_read_rounded,
      );
      _startResendTimer(60);
    } catch (error) {
      if (mounted) {
        showStoreMessage(context, friendlyError(error), icon: Icons.error_outline_rounded);
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _handleVerifyCode() async {
    final code = _codeCtrl.text.trim();
    if (code.length != 4) {
      showStoreMessage(context, 'Please enter the 4-digit code.', icon: Icons.error_outline_rounded);
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() => _busy = true);

    try {
      final service = context.read<ShopState>().service;
      await service.confirmRegistration(_emailCtrl.text.trim(), code);

      if (!mounted) return;
      final state = context.read<ShopState>();
      final autoLoggedIn = await state.login(_emailCtrl.text.trim(), _regPasswordCtrl.text);

      if (!mounted) return;
      if (autoLoggedIn) {
        Navigator.of(context).pop(true);
        showStoreMessage(context, 'Account created and verified successfully!', icon: Icons.celebration_rounded);
      } else {
        setState(() {
          _isLogin = true;
          _codeSent = false;
        });
        showStoreMessage(context, 'Account verified! Please sign in.', icon: Icons.check_circle_rounded);
      }
    } catch (error) {
      if (mounted) {
        showStoreMessage(context, friendlyError(error), icon: Icons.error_outline_rounded);
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _startResendTimer(int seconds) {
    _resendTimer?.cancel();
    setState(() => _resendCountdown = seconds);
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return timer.cancel();
      if (_resendCountdown <= 1) {
        timer.cancel();
        setState(() => _resendCountdown = 0);
      } else {
        setState(() => _resendCountdown--);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<ShopState>();
    final isGlobalBusy = state.busy || _busy;
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    final maxHeight = MediaQuery.of(context).size.height * 0.90;

    // Auto-pop if authenticated via Google / Telegram
    if (state.user != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && Navigator.canPop(context)) {
          Navigator.pop(context, true);
        }
      });
    }

    return Container(
      constraints: BoxConstraints(maxHeight: maxHeight),
      padding: EdgeInsets.only(bottom: keyboardHeight),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 20,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 44,
              height: 4.5,
              decoration: BoxDecoration(
                color: const Color(0xFFE2E8F0),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),

          // Header with Logo & Close button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
            child: Row(
              children: [
                const StoreLogo(size: 32, isCircle: false, borderRadius: BorderRadius.all(Radius.circular(8)), fit: BoxFit.cover),
                const SizedBox(width: 10),
                const Text(
                  'Shadow Shop',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: kAuthTextDark,
                    letterSpacing: -0.3,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 24, color: Color(0xFF64748B)),
                  tooltip: 'Close',
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          // Segmented Tabs: Sign In / Create Account
          if (!_codeSent)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Container(
                height: 44,
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _isLogin = true),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          decoration: BoxDecoration(
                            color: _isLogin ? Colors.white : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: _isLogin
                                ? [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.06),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ]
                                : null,
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            'Sign In',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: _isLogin ? FontWeight.w800 : FontWeight.w600,
                              color: _isLogin ? brandColor : const Color(0xFF64748B),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _isLogin = false),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          decoration: BoxDecoration(
                            color: !_isLogin ? Colors.white : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: !_isLogin
                                ? [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.06),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ]
                                : null,
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            'Create Account',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: !_isLogin ? FontWeight.w800 : FontWeight.w600,
                              color: !_isLogin ? brandColor : const Color(0xFF64748B),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Scrollable Form Body
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              child: _codeSent
                  ? _buildOtpVerificationView(isGlobalBusy)
                  : (_isLogin
                      ? _buildLoginForm(isGlobalBusy)
                      : _buildRegisterForm(isGlobalBusy)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoginForm(bool isBusy) {
    return Form(
      key: _loginFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 6),
          CustomTextField(
            controller: _loginIdentifierCtrl,
            label: 'Email, Phone Number, or Username',
            hintText: 'Enter email, phone, or username',
            prefixIcon: Icons.person_outline_rounded,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            validator: AuthValidator.emailOrPhone,
          ),
          const SizedBox(height: 14),
          PasswordTextField(
            controller: _loginPasswordCtrl,
            label: 'Password',
            hintText: 'Enter your password',
            textInputAction: TextInputAction.done,
            validator: (v) => AuthValidator.required(v, 'Enter your password'),
            onFieldSubmitted: (_) => _handleLogin(),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              SizedBox(
                height: 24,
                width: 24,
                child: Checkbox(
                  value: _rememberMe,
                  activeColor: brandColor,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                  onChanged: (val) => setState(() => _rememberMe = val ?? true),
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'Remember me',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: kAuthTextDark),
              ),
              const Spacer(),
              TextButton(
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(0, 0),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ForgotPasswordScreen()),
                  );
                },
                child: const Text(
                  'Forgot Password?',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: brandColor),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          PrimaryAuthButton(
            label: 'Sign In',
            isLoading: isBusy,
            onPressed: _handleLogin,
          ),
          const SizedBox(height: 18),
          const AuthDivider(),
          const SizedBox(height: 16),
          const Row(
            children: [
              Expanded(child: GoogleAuthButton(label: 'Google')),
              SizedBox(width: 12),
              Expanded(child: TelegramAuthButton(botName: 'ShadowShopBot', label: 'Telegram')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRegisterForm(bool isBusy) {
    return Form(
      key: _regFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 6),
          CustomTextField(
            controller: _fullNameCtrl,
            label: 'Full Name',
            hintText: 'e.g. Sok Chan',
            prefixIcon: Icons.badge_outlined,
            textInputAction: TextInputAction.next,
            validator: (v) => AuthValidator.required(v, 'Enter your full name'),
          ),

          const SizedBox(height: 12),
          CustomTextField(
            controller: _emailCtrl,
            label: 'Email Address',
            hintText: 'name@example.com',
            prefixIcon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            validator: AuthValidator.email,
          ),
          const SizedBox(height: 12),
          PasswordTextField(
            controller: _regPasswordCtrl,
            label: 'Password',
            hintText: 'Min 6 characters',
            textInputAction: TextInputAction.next,
            validator: AuthValidator.password,
          ),
          const SizedBox(height: 12),
          PasswordTextField(
            controller: _confirmPasswordCtrl,
            label: 'Confirm Password',
            hintText: 'Re-enter your password',
            textInputAction: TextInputAction.done,
            validator: (v) => AuthValidator.confirmPassword(v, _regPasswordCtrl.text),
            onFieldSubmitted: (_) => _handleRegister(),
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: 22,
                width: 22,
                child: Checkbox(
                  value: _agreeTerms,
                  activeColor: brandColor,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                  onChanged: (val) => setState(() => _agreeTerms = val ?? false),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: RichText(
                  text: TextSpan(
                    style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), height: 1.4),
                    children: [
                      const TextSpan(text: 'I agree to the '),
                      TextSpan(
                        text: 'Terms of Service',
                        style: const TextStyle(color: brandColor, fontWeight: FontWeight.w700),
                        recognizer: TapGestureRecognizer()
                          ..onTap = () {
                            showStoreMessage(context, 'Terms: All purchases follow standard return policies.', icon: Icons.description_outlined);
                          },
                      ),
                      const TextSpan(text: ' and '),
                      TextSpan(
                        text: 'Privacy Policy',
                        style: const TextStyle(color: brandColor, fontWeight: FontWeight.w700),
                        recognizer: TapGestureRecognizer()
                          ..onTap = () {
                            showStoreMessage(context, 'Privacy: Your personal information is kept secure.', icon: Icons.privacy_tip_outlined);
                          },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          PrimaryAuthButton(
            label: 'Create Account',
            isLoading: isBusy,
            onPressed: _handleRegister,
          ),
          const SizedBox(height: 18),
          const AuthDivider(),
          const SizedBox(height: 16),
          const Row(
            children: [
              Expanded(child: GoogleAuthButton(label: 'Google')),
              SizedBox(width: 12),
              Expanded(child: TelegramAuthButton(botName: 'ShadowShopBot', label: 'Telegram')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOtpVerificationView(bool isBusy) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFFDF2F8),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFFBCFE8)),
          ),
          child: Column(
            children: [
              const Icon(Icons.mark_email_read_rounded, size: 40, color: brandColor),
              const SizedBox(height: 10),
              const Text(
                'Verify Your Email',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: kAuthTextDark),
              ),
              const SizedBox(height: 6),
              Text(
                'We sent a 4-digit code to ${_emailCtrl.text.trim()}',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        CustomTextField(
          controller: _codeCtrl,
          label: '4-Digit Code',
          hintText: 'Enter code',
          prefixIcon: Icons.pin_outlined,
          keyboardType: TextInputType.number,
          textInputAction: TextInputAction.done,
          onFieldSubmitted: (_) => _handleVerifyCode(),
        ),
        const SizedBox(height: 18),
        PrimaryAuthButton(
          label: 'Verify & Continue',
          isLoading: isBusy,
          onPressed: _handleVerifyCode,
        ),
        const SizedBox(height: 14),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextButton(
              onPressed: _resendCountdown > 0
                  ? null
                  : () async {
                      try {
                        final service = context.read<ShopState>().service;
                        final res = await service.resendRegistrationCode(_emailCtrl.text.trim());
                        if (!mounted) return;
                        _startResendTimer(60);
                        showStoreMessage(
                          context,
                          res['detail']?.toString() ?? 'New code sent to your email.',
                          icon: Icons.check_circle_rounded,
                        );
                      } catch (e) {
                        if (mounted) {
                          showStoreMessage(context, friendlyError(e), icon: Icons.error_outline_rounded);
                        }
                      }
                    },
              child: Text(
                _resendCountdown > 0 ? 'Resend code in ${_resendCountdown}s' : 'Resend Code',
                style: TextStyle(
                  color: _resendCountdown > 0 ? const Color(0xFF94A3B8) : brandColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
