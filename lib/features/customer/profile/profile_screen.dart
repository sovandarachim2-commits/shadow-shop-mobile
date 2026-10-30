import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shadow_shop_mobile/features/customer/address/address_book_screen.dart';
import 'package:shadow_shop_mobile/state/shop_state.dart';
import 'package:shadow_shop_mobile/features/auth/auth_modal_sheet.dart';
import 'package:shadow_shop_mobile/features/auth/widgets/auth_widgets.dart';
import 'package:shadow_shop_mobile/theme/app_theme.dart';
import 'package:shadow_shop_mobile/features/customer/home/home_screen.dart';

class ProfileView extends StatefulWidget {
  const ProfileView({super.key});
  @override
  State<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<ProfileView> {
  final _first = TextEditingController();
  final _last = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  bool _loaded = false;
  bool _saving = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final user = context.read<ShopState>().user;
    if (user != null) {
      if (!_loaded) {
        _first.text = user['first_name']?.toString() ?? '';
        _last.text = user['last_name']?.toString() ?? '';
        _email.text = user['email']?.toString() ?? '';
        _phone.text = user['phone']?.toString() ?? '';
        _loaded = true;
      }
    } else {
      _loaded = false;
      _first.clear();
      _last.clear();
      _email.clear();
      _phone.clear();
    }
  }

  @override
  void dispose() {
    _first.dispose();
    _last.dispose();
    _email.dispose();
    _phone.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await context.read<ShopState>().updateProfile({
        'first_name': _first.text.trim(),
        'last_name': _last.text.trim(),
        'email': _email.text.trim(),
        'phone': _phone.text.trim()
      });
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Profile updated.')));
      }
    } on DioException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(friendlyError(error))));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }



  Widget _buildGuestProfile(BuildContext context) => ListView(
        padding: const EdgeInsets.all(18),
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 26),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFFF1F2), Color(0xFFFCE7F3)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFFBCFE8)),
            ),
            child: Column(
              children: [
                Container(
                  width: 76,
                  height: 76,
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: brandColor.withValues(alpha: 0.2),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const StoreLogo(size: 70, isCircle: true, fit: BoxFit.cover),
                ),
                const SizedBox(height: 14),
                const Text(
                  'Welcome to Shadow Shop',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Sign in to access your orders, delivery addresses, rewards, and exclusive discounts.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    color: Color(0xFF64748B),
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: brandColor,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: () => showAuthModal(context),
                    icon: const Icon(Icons.login_rounded, size: 20),
                    label: const Text(
                      'Sign In / Create Account',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.card_giftcard_outlined, color: brandColor),
                  title: const Text('Rewards & Points', style: TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: const Text('Sign in to view and redeem points'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => showAuthModal(context),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.favorite_border_rounded, color: brandColor),
                  title: const Text('Saved Wishlist', style: TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: const Text('Sign in to view saved items'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => showAuthModal(context),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.help_outline_rounded, color: Color(0xFF64748B)),
                  title: const Text('Help & Support', style: TextStyle(fontWeight: FontWeight.w600)),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () {
                    showStoreMessage(
                      context,
                      'Contact Telegram: @ShadowShopSupport',
                      icon: Icons.support_agent_rounded,
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      );

  @override
  Widget build(BuildContext context) {
    final state = context.watch<ShopState>();
    final user = state.user;
    if (user == null) {
      return _buildGuestProfile(context);
    }
    return ListView(padding: const EdgeInsets.all(18), children: [
      Card(
          child: Padding(
              padding: const EdgeInsets.all(18),
              child: Row(children: [
                const CircleAvatar(
                    radius: 30,
                    backgroundColor: Color(0xFFFCE7E8),
                    child: Icon(Icons.person, size: 32, color: brandColor)),
                const SizedBox(width: 14),
                Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      Text(
                          user['full_name']?.toString() ??
                              user['username']?.toString() ??
                              'Customer',
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold)),
                      Text(user['email']?.toString() ?? '',
                          style: TextStyle(color: Colors.grey.shade600))
                    ]))
              ]))),
      const Padding(
          padding: EdgeInsets.fromLTRB(4, 18, 4, 8),
          child: Text('Personal information',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
      TextField(
          controller: _first,
          decoration: const InputDecoration(
              labelText: 'First name',
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(14))))),
      const SizedBox(height: 10),
      TextField(
          controller: _last,
          decoration: const InputDecoration(
              labelText: 'Last name',
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(14))))),
      const SizedBox(height: 10),
      TextField(
          controller: _email,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(
              labelText: 'Email',
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(14))))),
      const SizedBox(height: 10),
      TextField(
          controller: _phone,
          keyboardType: TextInputType.phone,
          decoration: const InputDecoration(
              labelText: 'Phone',
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(14))))),
      const SizedBox(height: 12),
      FilledButton(
          onPressed: _saving ? null : _save,
          child: _saving
              ? const CircularProgressIndicator()
              : const Text('Save profile')),
      const SizedBox(height: 18),
      Card(
          child: Column(children: [
        ListTile(
            leading: const Icon(Icons.location_on_outlined),
            title: const Text('Delivery addresses'),
            subtitle: Text('${state.savedAddresses.length} saved'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AddressBookScreen()))),
        ListTile(
            leading: const Icon(Icons.receipt_long_outlined),
            title: const Text('My orders'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () =>
                context.findAncestorStateOfType<StoreScreenState>()?.setTab(1)),
        ListTile(
            leading: const Icon(Icons.card_giftcard_outlined),
            title: const Text('Rewards & points'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () =>
                context.findAncestorStateOfType<StoreScreenState>()?.setTab(3)),
        ListTile(
            leading: const Icon(Icons.favorite_border),
            title: const Text('Wishlist'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () =>
                context.findAncestorStateOfType<StoreScreenState>()?.setTab(4)),
        ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Sign out'),
            onTap: () => state.logout())
      ]))
    ]);
  }
}
