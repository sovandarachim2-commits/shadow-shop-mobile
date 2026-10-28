import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shadow_shop_mobile/state/shop_state.dart';
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
    if (_loaded) return;
    final user = context.read<ShopState>().user ?? {};
    _first.text = user['first_name']?.toString() ?? '';
    _last.text = user['last_name']?.toString() ?? '';
    _email.text = user['email']?.toString() ?? '';
    _phone.text = user['phone']?.toString() ?? '';
    _loaded = true;
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
      if (mounted)
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Profile updated.')));
    } on DioException catch (error) {
      if (mounted)
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(friendlyError(error))));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _editAddress() async {
    final state = context.read<ShopState>();
    await state.loadAddresses();
    if (!mounted) return;
    final fullName = TextEditingController(
        text: _first.text.trim() +
            (_last.text.trim().isEmpty ? '' : ' ${_last.text.trim()}'));
    final phone = TextEditingController(text: _phone.text);
    final line1 = TextEditingController();
    final city = TextEditingController();
    final province = TextEditingController(text: 'Phnom Penh');
    final saved = await showModalBottomSheet<bool>(
        context: context,
        isScrollControlled: true,
        showDragHandle: true,
        builder: (sheet) => Padding(
            padding: EdgeInsets.fromLTRB(
                20, 12, 20, MediaQuery.of(sheet).viewInsets.bottom + 24),
            child: SingleChildScrollView(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                  const Text('Add delivery address',
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  TextField(
                      controller: fullName,
                      decoration:
                          const InputDecoration(labelText: 'Receiver name')),
                  TextField(
                      controller: phone,
                      decoration: const InputDecoration(labelText: 'Phone')),
                  TextField(
                      controller: line1,
                      decoration:
                          const InputDecoration(labelText: 'Address line')),
                  TextField(
                      controller: city,
                      decoration:
                          const InputDecoration(labelText: 'City / district')),
                  TextField(
                      controller: province,
                      decoration:
                          const InputDecoration(labelText: 'Province / state')),
                  const SizedBox(height: 14),
                  FilledButton(
                      onPressed: () async {
                        try {
                          await state.addAddress({
                            'label': 'home',
                            'full_name': fullName.text.trim(),
                            'phone': phone.text.trim(),
                            'address_line1': line1.text.trim(),
                            'city': city.text.trim(),
                            'state': province.text.trim(),
                            'country': 'Cambodia',
                            'is_default': state.savedAddresses.isEmpty
                          });
                          if (sheet.mounted) Navigator.pop(sheet, true);
                        } on DioException catch (error) {
                          if (sheet.mounted)
                            ScaffoldMessenger.of(sheet).showSnackBar(
                                SnackBar(content: Text(friendlyError(error))));
                        }
                      },
                      child: const Text('Save address'))
                ]))));
    fullName.dispose();
    phone.dispose();
    line1.dispose();
    city.dispose();
    province.dispose();
    if (saved == true && mounted)
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Address saved.')));
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<ShopState>().user ?? {};
    final state = context.read<ShopState>();
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
            onTap: _editAddress),
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
