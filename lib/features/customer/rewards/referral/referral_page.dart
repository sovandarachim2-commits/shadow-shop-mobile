import 'package:flutter/material.dart';
import 'package:shadow_shop_mobile/theme/app_theme.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shadow_shop_mobile/state/shop_state.dart';

class ReferralPage extends StatefulWidget {
  const ReferralPage({super.key});
  @override
  State<ReferralPage> createState() => _ReferralPageState();
}

class _ReferralPageState extends State<ReferralPage> {
  final _friendCode = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _friendCode.dispose();
    super.dispose();
  }

  Future<void> _applyCode() async {
    final code = _friendCode.text.trim();
    if (code.isEmpty) return;
    setState(() => _saving = true);
    try {
      await context
          .read<ShopState>()
          .updateProfile({'friend_referral_code': code});
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Referral code saved.')));
    } catch (error) {
      if (mounted)
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error.toString())));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<ShopState>().user ?? {};
    final code = '${user['referral_code'] ?? '—'}';
    return Scaffold(
      appBar: AppBar(title: const Text('Refer a friend')),
      body: ListView(padding: const EdgeInsets.all(20), children: [
        Card(
            child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Share your code',
                          style: TextStyle(
                              fontSize: 20, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      const Text(
                          'Invite friends to Shadow Shop and share your referral code.'),
                      const SizedBox(height: 16),
                      SelectableText(code,
                          style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              color: brandColor)),
                      Align(
                          alignment: Alignment.centerRight,
                          child: IconButton(
                              onPressed: code == '—'
                                  ? null
                                  : () {
                                      Clipboard.setData(
                                          ClipboardData(text: code));
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(const SnackBar(
                                              content: Text('Code copied.')));
                                    },
                              icon: const Icon(Icons.copy))),
                      Text(
                          'Successful referrals: ${user['successful_referrals_count'] ?? 0}'),
                    ]))),
        const SizedBox(height: 20),
        const Text('Have a friend’s code?',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        const SizedBox(height: 8),
        TextField(
            controller: _friendCode,
            textCapitalization: TextCapitalization.characters,
            decoration: const InputDecoration(
                labelText: 'Referral code',
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(14))))),
        const SizedBox(height: 12),
        FilledButton(
            onPressed: _saving ? null : _applyCode,
            child: Text(_saving ? 'Saving…' : 'Apply code')),
      ]),
    );
  }
}
