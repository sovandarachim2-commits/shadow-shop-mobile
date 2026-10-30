import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shadow_shop_mobile/state/shop_state.dart';
import 'package:shadow_shop_mobile/theme/app_theme.dart';
import 'widgets/auth_widgets.dart';
import 'widgets/google_auth_button.dart';
import 'widgets/telegram_auth_button.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _usernameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  final _codeCtrl = TextEditingController();

  bool _agreeTerms = false;
  bool _codeSent = false;
  bool _busy = false;
  int _resendCountdown = 0;
  Timer? _countdownTimer;

  @override
  void dispose() {
    _fullNameCtrl.dispose();
    _phoneCtrl.dispose();
    _usernameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    _codeCtrl.dispose();
    _countdownTimer?.cancel();
    super.dispose();
  }

  void _startResendTimer([int seconds = 45]) {
    _countdownTimer?.cancel();
    setState(() => _resendCountdown = seconds);
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_resendCountdown > 1) {
        setState(() => _resendCountdown--);
      } else {
        setState(() => _resendCountdown = 0);
        timer.cancel();
      }
    });
  }

  Future<void> _handleRegister() async {
    if (_busy) return;
    if (!_formKey.currentState!.validate()) return;
    if (!_agreeTerms) {
      showStoreMessage(
        context,
        'Please agree to the Terms & Conditions to continue.',
        icon: Icons.info_outline_rounded,
      );
      return;
    }

    setState(() => _busy = true);
    try {
      final service = context.read<ShopState>().service;
      final nameParts = _fullNameCtrl.text.trim().split(RegExp(r'\s+'));
      final firstName = nameParts.first;
      final lastName = nameParts.length > 1 ? nameParts.skip(1).join(' ') : firstName;

      final result = await service.register({
        'first_name': firstName,
        'last_name': lastName,
        'phone': _phoneCtrl.text.trim(),
        'username': _usernameCtrl.text.trim(),
        'email': _emailCtrl.text.trim(),
        'password': _passwordCtrl.text,
        'confirm_password': _confirmCtrl.text,
      });

      if (!mounted) return;
      _startResendTimer(45);
      setState(() => _codeSent = true);
      showStoreMessage(
        context,
        result['detail']?.toString() ?? 'Verification code sent to your email.',
        icon: Icons.check_circle_rounded,
      );
    } on DioException catch (error) {
      final body = error.response?.data;
      String message = 'Registration failed. Please try again.';
      if (body is Map) {
        if (body['detail'] != null) {
          message = body['detail'].toString();
        } else if (body.isNotEmpty) {
          final firstVal = body.values.first;
          if (firstVal is List && firstVal.isNotEmpty) {
            message = '${body.keys.first}: ${firstVal.first}';
          } else {
            message = '$firstVal';
          }
        }
      }
      if (mounted) {
        showStoreMessage(context, message, icon: Icons.error_outline_rounded);
      }
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

    setState(() => _busy = true);
    try {
      final state = context.read<ShopState>();
      await state.service.confirmRegistration(_emailCtrl.text.trim(), code);
      if (!mounted) return;

      // Automatically sign in with credentials after verification
      final autoLoginOk = await state.login(_emailCtrl.text.trim(), _passwordCtrl.text);
      if (!mounted) return;

      if (autoLoginOk) {
        Navigator.pop(context); // back to home
        showStoreMessage(context, 'Account created and verified successfully!', icon: Icons.celebration_rounded);
      } else {
        showStoreMessage(context, 'Account verified! Please sign in.', icon: Icons.check_circle_rounded);
        Navigator.pop(context);
      }
    } on DioException catch (error) {
      final body = error.response?.data;
      final msg = body is Map ? (body['detail'] ?? body.values.first).toString() : 'Invalid verification code.';
      if (mounted) {
        showStoreMessage(context, msg, icon: Icons.error_outline_rounded);
      }
    } catch (error) {
      if (mounted) {
        showStoreMessage(context, friendlyError(error), icon: Icons.error_outline_rounded);
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _handleResend() async {
    if (_resendCountdown > 0 || _busy) return;
    setState(() => _busy = true);
    try {
      final service = context.read<ShopState>().service;
      final res = await service.resendRegistrationCode(_emailCtrl.text.trim());
      if (!mounted) return;
      _startResendTimer(45);
      showStoreMessage(
        context,
        res['detail']?.toString() ?? 'New code sent to your email.',
        icon: Icons.check_circle_rounded,
      );
    } on DioException catch (e) {
      final body = e.response?.data;
      final msg = body is Map ? body['detail']?.toString() : null;
      if (mounted) {
        showStoreMessage(context, msg ?? 'Could not resend code.', icon: Icons.error_outline_rounded);
      }
    } catch (e) {
      if (mounted) {
        showStoreMessage(context, friendlyError(e), icon: Icons.error_outline_rounded);
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: kAuthTextDark, size: 18),
          onPressed: () {
            if (_codeSent) {
              setState(() => _codeSent = false);
            } else {
              Navigator.pop(context);
            }
          },
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: _codeSent ? _buildVerifyStep() : _buildRegisterStep(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRegisterStep() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const AuthHeader(
            title: 'Create Account',
            subtitle: 'Join Shadow Shop for exclusive member pricing, vouchers, and rewards.',
            showLogo: false,
          ),
          const SizedBox(height: 28),

          // Full Name
          CustomTextField(
            controller: _fullNameCtrl,
            label: 'Full Name',
            hintText: 'John Doe',
            prefixIcon: Icons.person_outline_rounded,
            validator: (v) => AuthValidator.required(v, 'Enter your full name'),
            autofillHints: const [AutofillHints.name],
          ),
          const SizedBox(height: 16),

          // Phone Number
          CustomTextField(
            controller: _phoneCtrl,
            label: 'Phone Number',
            hintText: '012 345 678',
            prefixIcon: Icons.phone_outlined,
            keyboardType: TextInputType.phone,
            validator: AuthValidator.phone,
            autofillHints: const [AutofillHints.telephoneNumber],
          ),
          const SizedBox(height: 16),

          // Username (after Phone Number)
          CustomTextField(
            controller: _usernameCtrl,
            label: 'Username',
            hintText: 'Enter your username',
            prefixIcon: Icons.alternate_email_rounded,
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Enter your username';
              if (v.trim().length < 3) return 'Username must be at least 3 characters';
              return null;
            },
            autofillHints: const [AutofillHints.username],
          ),
          const SizedBox(height: 16),

          // Email
          CustomTextField(
            controller: _emailCtrl,
            label: 'Email Address',
            hintText: 'name@example.com',
            prefixIcon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
            validator: AuthValidator.email,
            autofillHints: const [AutofillHints.email],
          ),
          const SizedBox(height: 16),

          // Password
          PasswordTextField(
            controller: _passwordCtrl,
            label: 'Password',
            hintText: 'Minimum 8 characters',
            validator: (v) => AuthValidator.password(v, minLength: 8),
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 16),

          // Confirm Password
          PasswordTextField(
            controller: _confirmCtrl,
            label: 'Confirm Password',
            hintText: 'Re-enter your password',
            validator: (v) => AuthValidator.confirmPassword(v, _passwordCtrl.text),
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => _handleRegister(),
          ),
          const SizedBox(height: 16),

          // Terms and Conditions checkbox
          InkWell(
            onTap: () => setState(() => _agreeTerms = !_agreeTerms),
            borderRadius: BorderRadius.circular(6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 24,
                  height: 24,
                  child: Checkbox(
                    value: _agreeTerms,
                    activeColor: kAuthPrimary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                    onChanged: (val) => setState(() => _agreeTerms = val ?? true),
                  ),
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text.rich(
                    TextSpan(
                      text: 'I agree to the ',
                      style: TextStyle(fontSize: 13, color: kAuthTextMuted, height: 1.4),
                      children: [
                        TextSpan(
                          text: 'Terms of Service',
                          style: TextStyle(
                            color: kAuthPrimary,
                            fontWeight: FontWeight.w700,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                        TextSpan(text: ' and '),
                        TextSpan(
                          text: 'Privacy Policy',
                          style: TextStyle(
                            color: kAuthPrimary,
                            fontWeight: FontWeight.w700,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Create Account Button
          PrimaryAuthButton(
            label: 'Create Account',
            isLoading: _busy,
            onPressed: _handleRegister,
          ),
          const SizedBox(height: 24),

          // Divider
          const AuthDivider(),
          const SizedBox(height: 20),

          // Social registration options
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
          const SizedBox(height: 28),

          // Navigate to Login
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Already have an account?',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: kAuthTextMuted,
                ),
              ),
              const SizedBox(width: 6),
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: const Text(
                  'Sign In',
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
    );
  }

  Widget _buildVerifyStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AuthHeader(
          title: 'Check Your Email',
          subtitle: 'We sent a 4-digit verification code to ${_emailCtrl.text.trim()}. Enter it below to activate your account.',
          badgeIcon: Icons.mark_email_read_outlined,
        ),
        const SizedBox(height: 32),
        CustomTextField(
          controller: _codeCtrl,
          label: '4-Digit Verification Code',
          hintText: '1234',
          prefixIcon: Icons.pin_rounded,
          keyboardType: TextInputType.number,
          validator: (val) {
            if (val == null || val.trim().length != 4) {
              return 'Enter the 4-digit code';
            }
            return null;
          },
          onFieldSubmitted: (_) => _handleVerifyCode(),
        ),
        const SizedBox(height: 14),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Didn\'t receive code?',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
            ),
            TextButton(
              onPressed: _resendCountdown > 0 || _busy ? null : _handleResend,
              child: Text(
                _resendCountdown > 0 ? 'Resend in ${_resendCountdown}s' : 'Resend Code',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: _resendCountdown > 0 ? Colors.grey : kAuthPrimary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        PrimaryAuthButton(
          label: 'Verify & Continue',
          isLoading: _busy,
          onPressed: _handleVerifyCode,
        ),
        const SizedBox(height: 16),
        Center(
          child: TextButton.icon(
            onPressed: () => setState(() => _codeSent = false),
            icon: const Icon(Icons.edit_outlined, size: 16, color: kAuthPrimary),
            label: const Text(
              'Change Registration Details',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: kAuthPrimary,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
