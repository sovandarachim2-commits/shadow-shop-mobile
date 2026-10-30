import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shadow_shop_mobile/state/shop_state.dart';
import 'package:shadow_shop_mobile/theme/app_theme.dart';
import 'widgets/auth_widgets.dart';

enum ResetStep { requestEmail, verifyCode, setNewPassword, completed }

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key, this.initialEmail});

  final String? initialEmail;

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _codeCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  ResetStep _currentStep = ResetStep.requestEmail;
  bool _loading = false;
  int _resendCountdown = 0;
  Timer? _countdownTimer;

  @override
  void initState() {
    super.initState();
    if (widget.initialEmail != null && widget.initialEmail!.isNotEmpty) {
      _emailCtrl.text = widget.initialEmail!;
    }
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _codeCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
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

  Future<void> _handleRequestCode() async {
    if (!_formKey.currentState!.validate()) return;
    final email = _emailCtrl.text.trim();
    setState(() => _loading = true);
    try {
      final service = context.read<ShopState>().service;
      final result = await service.requestPasswordReset(email);
      if (!mounted) return;
      showStoreMessage(
        context,
        result['detail']?.toString() ?? 'Verification code sent to $email',
        icon: Icons.check_circle_rounded,
      );
      _startResendTimer(45);
      setState(() => _currentStep = ResetStep.verifyCode);
    } on DioException catch (e) {
      if (!mounted) return;
      final body = e.response?.data;
      final msg = body is Map ? body['detail']?.toString() : null;
      showStoreMessage(
        context,
        msg ?? 'Could not send verification code. Please check your email.',
        icon: Icons.error_outline_rounded,
      );
    } catch (e) {
      if (!mounted) return;
      showStoreMessage(context, e.toString(), icon: Icons.error_outline_rounded);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _handleVerifyCode() async {
    final code = _codeCtrl.text.trim();
    if (code.length != 4) {
      showStoreMessage(context, 'Please enter the 4-digit code.', icon: Icons.error_outline_rounded);
      return;
    }
    setState(() => _loading = true);
    try {
      final service = context.read<ShopState>().service;
      await service.verifyPasswordResetCode(_emailCtrl.text.trim(), code);
      if (!mounted) return;
      showStoreMessage(context, 'Code verified successfully.', icon: Icons.check_circle_rounded);
      setState(() => _currentStep = ResetStep.setNewPassword);
    } on DioException catch (e) {
      if (!mounted) return;
      final body = e.response?.data;
      final msg = body is Map ? body['detail']?.toString() : null;
      showStoreMessage(context, msg ?? 'Invalid verification code.', icon: Icons.error_outline_rounded);
    } catch (e) {
      if (!mounted) return;
      showStoreMessage(context, e.toString(), icon: Icons.error_outline_rounded);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _handleResetPassword() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final service = context.read<ShopState>().service;
      await service.resetPassword(
        email: _emailCtrl.text.trim(),
        code: _codeCtrl.text.trim(),
        password: _passwordCtrl.text,
        confirmPassword: _confirmCtrl.text,
      );
      if (!mounted) return;
      setState(() => _currentStep = ResetStep.completed);
    } on DioException catch (e) {
      if (!mounted) return;
      final body = e.response?.data;
      final msg = body is Map ? body['detail']?.toString() : null;
      showStoreMessage(context, msg ?? 'Failed to reset password.', icon: Icons.error_outline_rounded);
    } catch (e) {
      if (!mounted) return;
      showStoreMessage(context, e.toString(), icon: Icons.error_outline_rounded);
    } finally {
      if (mounted) setState(() => _loading = false);
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
            if (_currentStep == ResetStep.verifyCode) {
              setState(() => _currentStep = ResetStep.requestEmail);
            } else if (_currentStep == ResetStep.setNewPassword) {
              setState(() => _currentStep = ResetStep.verifyCode);
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
              child: Form(
                key: _formKey,
                child: _buildStepContent(),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStepContent() {
    switch (_currentStep) {
      case ResetStep.requestEmail:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const AuthHeader(
              title: 'Forgot Password',
              subtitle: 'Enter your registered email address and we will send you a 4-digit verification code to reset your password.',
              badgeIcon: Icons.lock_reset_rounded,
            ),
            const SizedBox(height: 32),
            CustomTextField(
              controller: _emailCtrl,
              label: 'Email Address',
              hintText: 'name@example.com',
              prefixIcon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
              validator: AuthValidator.email,
              onFieldSubmitted: (_) => _handleRequestCode(),
            ),
            const SizedBox(height: 24),
            PrimaryAuthButton(
              label: 'Send Verification Code',
              isLoading: _loading,
              onPressed: _handleRequestCode,
            ),
            const SizedBox(height: 20),
            Center(
              child: TextButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back_rounded, size: 16, color: kAuthPrimary),
                label: const Text(
                  'Back to Sign In',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: kAuthPrimary,
                  ),
                ),
              ),
            ),
          ],
        );

      case ResetStep.verifyCode:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AuthHeader(
              title: 'Check Your Email',
              subtitle: 'We sent a 4-digit code to ${_emailCtrl.text.trim()}. Enter it below to proceed.',
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
                  return 'Enter the 4-digit verification code';
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
                  onPressed: _resendCountdown > 0 || _loading ? null : _handleRequestCode,
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
            const SizedBox(height: 20),
            PrimaryAuthButton(
              label: 'Verify Code',
              isLoading: _loading,
              onPressed: _handleVerifyCode,
            ),
          ],
        );

      case ResetStep.setNewPassword:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const AuthHeader(
              title: 'Create New Password',
              subtitle: 'Your new password must be at least 8 characters long and different from previous passwords.',
              badgeIcon: Icons.security_rounded,
            ),
            const SizedBox(height: 32),
            PasswordTextField(
              controller: _passwordCtrl,
              label: 'New Password',
              hintText: 'Minimum 8 characters',
              validator: (v) => AuthValidator.password(v, minLength: 8),
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 16),
            PasswordTextField(
              controller: _confirmCtrl,
              label: 'Confirm New Password',
              hintText: 'Re-enter your password',
              validator: (v) => AuthValidator.confirmPassword(v, _passwordCtrl.text),
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _handleResetPassword(),
            ),
            const SizedBox(height: 24),
            PrimaryAuthButton(
              label: 'Reset Password',
              isLoading: _loading,
              onPressed: _handleResetPassword,
            ),
          ],
        );

      case ResetStep.completed:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              width: 80,
              height: 80,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                color: Color(0xFFECFDF5),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 52),
            ),
            const SizedBox(height: 24),
            const Text(
              'Password Reset Done!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w900,
                color: kAuthTextDark,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Your password has been changed successfully. You can now sign in with your new credentials.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600, height: 1.4),
            ),
            const SizedBox(height: 32),
            PrimaryAuthButton(
              label: 'Sign In to Your Account',
              onPressed: () => Navigator.pop(context),
            ),
          ],
        );
    }
  }
}

