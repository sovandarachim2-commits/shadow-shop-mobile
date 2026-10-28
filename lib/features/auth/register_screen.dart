import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shadow_shop_mobile/state/shop_state.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _form = GlobalKey<FormState>();
  final _first = TextEditingController();
  final _last = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  final _code = TextEditingController();
  bool _codeSent = false;
  bool _busy = false;

  @override
  void dispose() {
    _first.dispose();
    _last.dispose();
    _email.dispose();
    _phone.dispose();
    _password.dispose();
    _confirm.dispose();
    _code.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_busy) return;
    if (!_codeSent && !_form.currentState!.validate()) return;
    setState(() => _busy = true);
    try {
      final service = context.read<ShopState>().service;
      if (!_codeSent) {
        final result = await service.register({
          'first_name': _first.text.trim(),
          'last_name': _last.text.trim(),
          'email': _email.text.trim(),
          'phone': _phone.text.trim(),
          'password': _password.text,
          'confirm_password': _confirm.text,
        });
        setState(() => _codeSent = true);
        if (mounted && result['detail'] != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${result['detail']}')),
          );
        }
      } else {
        await service.confirmRegistration(
            _email.text.trim(), _code.text.trim());
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Account verified. Please sign in.')),
          );
          Navigator.pop(context);
        }
      }
    } on DioException catch (error) {
      final body = error.response?.data;
      final message = body is Map
          ? (body['detail'] ?? body.values.first).toString()
          : 'Registration could not be completed.';
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(message)));
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error.toString())));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Create customer account')),
        body: Form(
          key: _form,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              if (!_codeSent) ...[
                TextFormField(
                  controller: _first,
                  decoration: const InputDecoration(labelText: 'First name'),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Enter your first name'
                      : null,
                ),
                TextFormField(
                  controller: _last,
                  decoration: const InputDecoration(labelText: 'Last name'),
                ),
                TextFormField(
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(labelText: 'Email'),
                  validator: (value) => value == null || !value.contains('@')
                      ? 'Enter a valid email'
                      : null,
                ),
                TextFormField(
                  controller: _phone,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(labelText: 'Phone'),
                ),
                TextFormField(
                  controller: _password,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'Password'),
                  validator: (value) => value == null || value.length < 8
                      ? 'Use at least 8 characters'
                      : null,
                ),
                TextFormField(
                  controller: _confirm,
                  obscureText: true,
                  decoration:
                      const InputDecoration(labelText: 'Confirm password'),
                  validator: (value) =>
                      value != _password.text ? 'Passwords do not match' : null,
                ),
              ] else ...[
                Text('Enter the verification code sent to ${_email.text}.'),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _code,
                  keyboardType: TextInputType.number,
                  maxLength: 4,
                  decoration:
                      const InputDecoration(labelText: 'Verification code'),
                  validator: (value) =>
                      value == null || value.trim().length != 4
                          ? 'Enter the 4 digit code'
                          : null,
                ),
              ],
              const SizedBox(height: 18),
              FilledButton(
                onPressed: _busy ? null : _submit,
                child: Text(_busy
                    ? 'Please wait…'
                    : _codeSent
                        ? 'Verify email'
                        : 'Create account'),
              ),
            ],
          ),
        ),
      );
}
