import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shadow_shop_mobile/state/shop_state.dart';
import 'package:shadow_shop_mobile/theme/app_theme.dart';
import 'dart:convert';
import 'package:dio/dio.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});
  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _address = TextEditingController();
  final _district = TextEditingController();
  final _notes = TextEditingController();
  final _coupon = TextEditingController();
  String? _couponError;
  double _couponDiscount = 0;
  String _province = 'phnom_penh';
  String _payment = 'cod';
  double _deliveryFee = 3;
  bool _submitting = false;
  Map<String, dynamic>? _siteSettings;

  static const _provinces = <String, String>{
    'phnom_penh': 'Phnom Penh',
    'kandal': 'Kandal',
    'takeo': 'Takeo',
    'kampong_cham': 'Kampong Cham',
    'siem_reap': 'Siem Reap',
    'battambang': 'Battambang',
    'kampong_speu': 'Kampong Speu',
    'prey_veng': 'Prey Veng',
    'svay_rieng': 'Svay Rieng',
    'kampong_thom': 'Kampong Thom',
    'kampot': 'Kampot',
    'preah_sihanouk': 'Preah Sihanouk',
    'pursat': 'Pursat',
    'banteay_meanchey': 'Banteay Meanchey',
    'oddar_meanchey': 'Oddar Meanchey',
    'pailin': 'Pailin',
    'koh_kong': 'Koh Kong',
    'kratie': 'Kratie',
    'stung_treng': 'Stung Treng',
    'ratanakiri': 'Ratanakiri',
    'mondulkiri': 'Mondulkiri',
    'preah_vihear': 'Preah Vihear',
    'kampong_chhnang': 'Kampong Chhnang',
    'tbong_khmum': 'Tbong Khmum',
  };

  @override
  void initState() {
    super.initState();
    final state = context.read<ShopState>();
    final user = state.user ?? {};
    _name.text = user['full_name']?.toString() ?? '';
    _phone.text = user['phone']?.toString() ?? '';
    _coupon.text = state.couponCode;
    _loadDelivery();
  }

  Future<void> _loadDelivery() async {
    try {
      final settings = await context.read<ShopState>().service.siteSettings();
      if (!mounted) return;
      final feeMap = settings['delivery_fees'] is Map
          ? Map<String, dynamic>.from(settings['delivery_fees'])
          : <String, dynamic>{};
      setState(() {
        _siteSettings = settings;
        final value = feeMap[_province];
        if (value is Map)
          _deliveryFee = double.tryParse('${value['fee']}') ?? 3;
        else if (value != null) _deliveryFee = double.tryParse('$value') ?? 3;
        final paymentMap = settings['payment_methods'];
        if (paymentMap is Map && paymentMap[_payment] == false)
          _payment = 'cod';
      });
      await context.read<ShopState>().loadAddresses();
      final defaultAddress = context
          .read<ShopState>()
          .savedAddresses
          .where((item) => item['is_default'] == true)
          .firstOrNull;
      if (defaultAddress != null && mounted) {
        setState(() {
          _name.text = defaultAddress['full_name']?.toString() ?? _name.text;
          _phone.text = defaultAddress['phone']?.toString() ?? _phone.text;
          _address.text = [
            defaultAddress['address_line1'],
            defaultAddress['address_line2'],
            defaultAddress['city']
          ].where((item) => item != null && '$item'.isNotEmpty).join(', ');
          _district.text = defaultAddress['city']?.toString() ?? '';
          final province = defaultAddress['state']?.toString();
          if (province != null) {
            final key = _provinces.keys
                .where((item) =>
                    _provinces[item]?.toLowerCase() == province.toLowerCase())
                .firstOrNull;
            if (key != null) _province = key;
          }
        });
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _address.dispose();
    _district.dispose();
    _notes.dispose();
    _coupon.dispose();
    super.dispose();
  }

  double _feeFor(String province) {
    final fees = _siteSettings?['delivery_fees'];
    if (fees is Map) {
      final value = fees[province];
      if (value is Map) return double.tryParse('${value['fee']}') ?? 3;
      if (value != null) return double.tryParse('$value') ?? 3;
    }
    const defaults = {
      'phnom_penh': 3,
      'kandal': 4,
      'takeo': 4,
      'kampong_cham': 5,
      'siem_reap': 6,
      'battambang': 6
    };
    return (defaults[province] ?? 5).toDouble();
  }

  List<(String, String, IconData)> get _availablePayments {
    const methods = <(String, String, IconData)>[
      ('cod', 'Cash on Delivery', Icons.local_shipping_outlined),
      ('bakong', 'Bakong KHQR', Icons.qr_code_2),
      ('aba', 'ABA PayWay', Icons.account_balance),
      ('acleda', 'ACLEDA', Icons.account_balance_wallet_outlined),
      ('wing', 'Wing', Icons.account_balance_wallet),
      ('contact_sales', 'Contact Sales', Icons.support_agent),
    ];
    final settings = _siteSettings?['payment_methods'];
    final allowedZones = settings is Map && settings['allowed_zones'] is Map
        ? Map<String, dynamic>.from(settings['allowed_zones'])
        : <String, dynamic>{};
    return methods.where((method) {
      if (settings is Map && settings[method.$1] == false) return false;
      final zones = allowedZones[method.$1];
      if (zones is List && zones.isNotEmpty && !zones.contains(_province)) {
        return false;
      }
      return true;
    }).toList();
  }

  Future<void> _applyCoupon() async {
    final code = _coupon.text.trim();
    if (code.isEmpty) return;
    try {
      final data = await context.read<ShopState>().service.validateCoupon(
            code,
            context.read<ShopState>().subtotal,
            _deliveryFee,
          );
      if (!mounted) return;
      setState(() {
        _coupon.text = '${data['coupon_code'] ?? code}';
        _couponDiscount = (double.tryParse('') ?? 0);
        _couponError = null;
      });
    } on DioException catch (error) {
      if (!mounted) return;
      final body = error.response?.data;
      setState(() {
        _couponDiscount = 0;
        _couponError = body is Map
            ? '${body['detail'] ?? body.values.first}'
            : 'Coupon could not be applied.';
      });
    }
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    final state = context.read<ShopState>();
    if (state.cartLines.isEmpty) return;
    setState(() => _submitting = true);
    try {
      final payload = {
        'name': _name.text.trim(),
        'phone': _phone.text.trim(),
        'email': state.user?['email'] ?? '',
        'address': _address.text.trim(),
        'address_detail': _address.text.trim(),
        'province': _province,
        'district': _district.text.trim(),
        'notes': _notes.text.trim(),
        'payment_method': _payment,
        'payment_status': 'unpaid',
        'delivery_fee': _deliveryFee,
        'coupon_code': _couponDiscount > 0 ? _coupon.text.trim() : '',
        'items': state.cartLines
            .map((line) => {
                  if (!line.product.isProductSet) 'product': line.product.id,
                  if (line.product.isProductSet)
                    'product_set': line.product.productSetId,
                  'quantity': line.quantity,
                  'unit_price': line.product.price,
                  'cost_price': 0,
                })
            .toList(),
      };
      final result = await state.service.checkout(payload);
      if (!mounted) return;
      if (result['pending_checkout'] is Map) {
        final pending = Map<String, dynamic>.from(result['pending_checkout']);
        final bakong = result['bakong_payment'] is Map
            ? Map<String, dynamic>.from(result['bakong_payment'])
            : <String, dynamic>{};
        final qrData = (bakong['qr_image'] ?? pending['qr_image'])?.toString();
        final paymentLink =
            pending['deeplink'] ?? result['aba_payment']?['endpoint'];
        await showDialog<void>(
            context: context,
            barrierDismissible: false,
            builder: (dialogContext) => AlertDialog(
                  title: const Text('Payment started'),
                  content: Column(mainAxisSize: MainAxisSize.min, children: [
                    const Text(
                        'Complete payment in the returned payment app or scan the QR. Your order remains pending until the server confirms payment.'),
                    if (qrData != null)
                      Padding(
                          padding: const EdgeInsets.all(12),
                          child: qrData.startsWith('data:image')
                              ? Image.memory(
                                  base64Decode(qrData.split(',').last),
                                  height: 190,
                                  errorBuilder: (_, __, ___) =>
                                      const Text('QR image is unavailable.'))
                              : Image.network(qrData,
                                  height: 190,
                                  errorBuilder: (_, __, ___) =>
                                      const Text('QR image is unavailable.'))),
                    if (paymentLink != null)
                      SelectableText('Payment gateway: $paymentLink'),
                    if (pending['reference'] != null)
                      SelectableText('Reference: ${pending['reference']}'),
                    if (pending['status'] != null)
                      Text('Server status: ${pending['status']}'),
                  ]),
                  actions: [
                    TextButton(
                        onPressed: () async {
                          try {
                            final status = await state.service
                                .verifyOrder('${pending['reference']}');
                            if (!dialogContext.mounted) return;
                            final paid = status['status'] == 'paid';
                            ScaffoldMessenger.of(dialogContext).showSnackBar(
                                SnackBar(
                                    content: Text(paid
                                        ? 'Payment confirmed by Shadow Shop.'
                                        : 'Payment status: ${status['status'] ?? 'pending'}')));
                            if (paid) Navigator.pop(dialogContext);
                          } on DioException catch (error) {
                            if (dialogContext.mounted)
                              ScaffoldMessenger.of(dialogContext).showSnackBar(
                                  SnackBar(
                                      content: Text(friendlyError(error))));
                          }
                        },
                        child: const Text('Check payment')),
                    TextButton(
                        onPressed: () => Navigator.pop(dialogContext),
                        child: const Text('Close')),
                  ],
                ));
        return;
      }
      await showDialog<void>(
          context: context,
          builder: (dialogContext) => AlertDialog(
                icon: const Icon(Icons.check_circle,
                    color: Colors.green, size: 42),
                title: const Text('Order placed'),
                content: Text(
                    'Order ${result['order_number'] ?? ''} was sent to Shadow Shop.'),
                actions: [
                  FilledButton(
                      onPressed: () => Navigator.pop(dialogContext),
                      child: const Text('Done'))
                ],
              ));
      state.clearCart();
      if (mounted) Navigator.pop(context);
    } on DioException catch (error) {
      final body = error.response?.data;
      final detail = body is Map ? body['detail'] ?? body.values.first : body;
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(detail?.toString() ?? 'Checkout failed.')));
    } catch (error) {
      if (mounted)
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error.toString())));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<ShopState>();
    final subtotal = state.subtotal;
    return Scaffold(
      appBar: AppBar(title: const Text('Checkout')),
      body: Form(
          key: _form,
          child: ListView(padding: const EdgeInsets.all(18), children: [
            const Text('Delivery information',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            TextFormField(
                controller: _name,
                decoration: const InputDecoration(
                    labelText: 'Full name',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(14)))),
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Enter the receiver name'
                    : null),
            const SizedBox(height: 12),
            TextFormField(
                controller: _phone,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                    labelText: 'Phone number',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(14)))),
                validator: (value) => value == null || value.trim().length < 8
                    ? 'Enter a valid phone number'
                    : null),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
                initialValue: _province,
                decoration: const InputDecoration(
                    labelText: 'Province',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(14)))),
                items: _provinces.entries
                    .map((item) => DropdownMenuItem(
                        value: item.key, child: Text(item.value)))
                    .toList(),
                onChanged: (value) {
                  if (value != null)
                    setState(() {
                      _province = value;
                      _deliveryFee = _feeFor(value);
                      if (!_availablePayments
                          .any((method) => method.$1 == _payment)) {
                        _payment = _availablePayments.firstOrNull?.$1 ?? 'cod';
                      }
                    });
                }),
            const SizedBox(height: 12),
            TextFormField(
                controller: _district,
                decoration: const InputDecoration(
                    labelText: 'District / area',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(14))))),
            const SizedBox(height: 12),
            TextFormField(
                controller: _address,
                minLines: 2,
                maxLines: 3,
                decoration: const InputDecoration(
                    labelText: 'Delivery address',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(14)))),
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Enter the delivery address'
                    : null),
            const SizedBox(height: 12),
            TextFormField(
                controller: _notes,
                decoration: const InputDecoration(
                    labelText: 'Delivery notes (optional)',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(14))))),
            const SizedBox(height: 22),
            const Text('Payment method',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Row(children: [
              Expanded(
                  child: TextField(
                      controller: _coupon,
                      textCapitalization: TextCapitalization.characters,
                      decoration: InputDecoration(
                          labelText: 'Coupon code',
                          errorText: _couponError,
                          border: const OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.all(Radius.circular(14)))))),
              const SizedBox(width: 8),
              OutlinedButton(
                  onPressed: _applyCoupon, child: const Text('Apply'))
            ]),
            for (final method in _availablePayments)
              RadioListTile<String>(
                  value: method.$1,
                  groupValue: _payment,
                  onChanged: (value) => setState(() => _payment = value!),
                  title: Text(method.$2),
                  secondary: Icon(method.$3),
                  contentPadding: EdgeInsets.zero),
            Card(
                child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(children: [
                      _summaryRow('Subtotal', subtotal),
                      _summaryRow('Delivery', _deliveryFee),
                      if (_couponDiscount > 0)
                        _summaryRow('Coupon discount', -_couponDiscount),
                      const Divider(),
                      _summaryRow(
                          'Total', subtotal + _deliveryFee - _couponDiscount,
                          strong: true)
                    ]))),
            const SizedBox(height: 12),
            FilledButton(
                onPressed: _submitting ? null : _submit,
                style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16)),
                child: _submitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Place order')),
            const SizedBox(height: 10),
            Text(
                'Online payment is only complete when the backend confirms the gateway status.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
          ])),
    );
  }

  Widget _summaryRow(String label, double value, {bool strong = false}) =>
      Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(children: [
            Expanded(
                child: Text(label,
                    style: TextStyle(
                        fontWeight:
                            strong ? FontWeight.bold : FontWeight.normal))),
            Text('\$${value.toStringAsFixed(2)}',
                style: TextStyle(
                    fontWeight: strong ? FontWeight.bold : FontWeight.normal,
                    color: strong ? brandColor : null))
          ]));
}
