import 'dart:convert';
import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shadow_shop_mobile/state/shop_state.dart';
import 'package:shadow_shop_mobile/theme/app_theme.dart';

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
  final _addressLine2 = TextEditingController();
  final _district = TextEditingController();
  final _notes = TextEditingController();
  final _coupon = TextEditingController();
  String? _couponError;
  double _couponDiscount = 0;
  bool _couponApplied = false;
  String _province = 'phnom_penh';
  String _payment = 'cod';
  double _deliveryFee = 3;
  bool _submitting = false;
  bool _loadingDelivery = true;
  String? _deliveryError;
  Map<String, dynamic>? _siteSettings;
  Timer? _couponDebounce;

  static const Map<String, dynamic> _defaultDeliveryFees = {
    'phnom_penh': 3,
    'kandal': 4,
    'takeo': 4,
    'kampong_cham': 5,
    'siem_reap': 6,
    'battambang': 6,
  };

  static const _provinceLabels = <String, String>{
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
    'kep': 'Kep',
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
    final state = context.read<ShopState>();
    setState(() {
      _loadingDelivery = true;
      _deliveryError = null;
    });
    try {
      final settings = await state.service.siteSettings();
      await state.loadAddresses();
      if (!mounted) return;
      final addresses = state.savedAddresses;
      final savedAddress =
          addresses.where((item) => item['is_default'] == true).firstOrNull ??
              addresses.firstOrNull;
      setState(() {
        _siteSettings = settings;
        if (savedAddress != null) {
          _name.text = savedAddress['full_name']?.toString() ?? _name.text;
          _phone.text = savedAddress['phone']?.toString() ?? _phone.text;
          _address.text = savedAddress['address_line1']?.toString() ?? '';
          _addressLine2.text = savedAddress['address_line2']?.toString() ?? '';
          _district.text = savedAddress['city']?.toString() ?? '';
          _province = _matchDeliveryZone(savedAddress['state']?.toString()) ??
              _defaultDeliveryZone;
        } else {
          _province = _defaultDeliveryZone;
        }
        _deliveryFee = _feeFor(_province);
        _loadingDelivery = false;
        _payment = _availablePayments.any((method) => method.$1 == _payment)
            ? _payment
            : _availablePayments.firstOrNull?.$1 ?? 'cod';
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loadingDelivery = false;
        _deliveryError = friendlyError(error);
      });
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _address.dispose();
    _addressLine2.dispose();
    _district.dispose();
    _notes.dispose();
    _coupon.dispose();
    _couponDebounce?.cancel();
    super.dispose();
  }

  Map<String, dynamic> get _deliveryZones {
    final settings = _siteSettings?['delivery_fees'];
    if (settings is Map && settings.isNotEmpty) {
      return Map<String, dynamic>.from(settings);
    }
    return _defaultDeliveryFees;
  }

  List<MapEntry<String, dynamic>> get _enabledDeliveryZones =>
      _deliveryZones.entries.where((entry) {
        final value = entry.value;
        return value is! Map || value['enabled'] != false;
      }).toList();

  String get _defaultDeliveryZone {
    final zones = _enabledDeliveryZones;
    return zones
            .where((entry) =>
                entry.value is Map && entry.value['is_default'] == true)
            .firstOrNull
            ?.key ??
        zones.firstOrNull?.key ??
        'phnom_penh';
  }

  String _zoneLabel(String key) {
    final value = _deliveryZones[key];
    if (value is Map && value['label'] != null) {
      return value['label'].toString();
    }
    return _provinceLabels[key] ??
        key
            .split('_')
            .map((part) => part.isEmpty
                ? part
                : '${part[0].toUpperCase()}${part.substring(1)}')
            .join(' ');
  }

  String? _matchDeliveryZone(String? addressState) {
    final state = addressState?.trim().toLowerCase();
    if (state == null || state.isEmpty) return null;
    for (final entry in _enabledDeliveryZones) {
      if (entry.key.toLowerCase() == state ||
          _zoneLabel(entry.key).toLowerCase() == state) {
        return entry.key;
      }
    }
    final normalizedState = state.replaceAll(RegExp(r'[^a-z0-9]+'), '_');
    return _enabledDeliveryZones
        .where((entry) => entry.key.toLowerCase() == normalizedState)
        .firstOrNull
        ?.key;
  }

  double _feeFor(String province) {
    final value = _deliveryZones[province];
    final fee = value is Map ? value['fee'] : value;
    return double.tryParse('$fee') ?? 0;
  }

  bool get _hasDeliveryAddress =>
      _name.text.trim().isNotEmpty &&
      _phone.text.trim().isNotEmpty &&
      _address.text.trim().isNotEmpty;

  double get _checkoutDeliveryFee => _hasDeliveryAddress ? _deliveryFee : 0;

  void _onDeliveryDetailsChanged() {
    final revalidateCoupon = _couponApplied;
    setState(() {});
    if (revalidateCoupon) {
      _couponDebounce?.cancel();
      _couponDebounce = Timer(const Duration(milliseconds: 350), () {
        if (mounted) _applyCoupon();
      });
    }
  }

  String get _orderDeliveryNote {
    final location = [
      if (_district.text.trim().isNotEmpty) _district.text.trim(),
      _zoneLabel(_province),
    ].join(', ');
    final customNote = _notes.text.trim();
    return [
      'Home delivery${location.isEmpty ? '' : '. $location'}',
      if (customNote.isNotEmpty) 'Delivery note: $customNote',
    ].join('. ');
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
            _checkoutDeliveryFee,
          );
      if (!mounted) return;
      setState(() {
        _coupon.text = '${data['coupon_code'] ?? code}';
        _couponDiscount = double.tryParse('${data['discount']}') ?? 0;
        _couponApplied = true;
        _couponError = null;
      });
    } on DioException catch (error) {
      if (!mounted) return;
      final body = error.response?.data;
      setState(() {
        _couponDiscount = 0;
        _couponApplied = false;
        _couponError = body is Map
            ? '${body['detail'] ?? body.values.first}'
            : 'Coupon could not be applied.';
      });
    }
  }

  Future<void> _submit() async {
    if (_loadingDelivery || _deliveryError != null) {
      showStoreMessage(
        context,
        'Load delivery settings before placing your order',
        icon: Icons.local_shipping_outlined,
      );
      return;
    }
    if (!_form.currentState!.validate()) return;
    if (_enabledDeliveryZones.isEmpty) {
      showStoreMessage(
        context,
        'No delivery zones are available',
        icon: Icons.location_off_outlined,
      );
      return;
    }
    if (!_availablePayments.any((method) => method.$1 == _payment)) {
      showStoreMessage(
        context,
        'No payment methods are available for this delivery zone',
        icon: Icons.payment_outlined,
      );
      return;
    }
    final state = context.read<ShopState>();
    if (state.cartLines.isEmpty) return;
    setState(() => _submitting = true);
    try {
      final payload = {
        'name': _name.text.trim(),
        'phone': _phone.text.trim(),
        'email': state.user?['email'] ?? '',
        'address': [
          if (_addressLine2.text.trim().isNotEmpty) _addressLine2.text.trim(),
          if (_district.text.trim().isNotEmpty) _district.text.trim(),
          _zoneLabel(_province),
        ].join(', '),
        'address_detail': _address.text.trim(),
        'province': _province,
        'district': _district.text.trim(),
        'notes': _orderDeliveryNote,
        'payment_method': _payment,
        'payment_status': 'unpaid',
        'delivery_fee': _checkoutDeliveryFee,
        'coupon_code': _couponApplied ? _coupon.text.trim() : '',
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
            if (_deliveryError != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3F2),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Delivery settings could not be loaded: $_deliveryError',
                        style: const TextStyle(
                          color: Color(0xFFB42318),
                          fontSize: 13,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: _loadingDelivery ? null : _loadDelivery,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ],
            if (_loadingDelivery) ...[
              const SizedBox(height: 10),
              const LinearProgressIndicator(),
            ],
            const SizedBox(height: 12),
            TextFormField(
                controller: _name,
                decoration: const InputDecoration(
                    labelText: 'Full name',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(14)))),
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Enter the receiver name'
                    : null,
                onChanged: (_) => _onDeliveryDetailsChanged()),
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
                    : null,
                onChanged: (_) => _onDeliveryDetailsChanged()),
            const SizedBox(height: 12),
            if (_enabledDeliveryZones.isEmpty)
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3F2),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Text(
                  'No delivery zones are enabled. Please contact the store.',
                  style: TextStyle(color: Color(0xFFB42318)),
                ),
              )
            else
              DropdownButtonFormField<String>(
                  initialValue: _province,
                  decoration: const InputDecoration(
                      labelText: 'Province',
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(14)))),
                  items: _enabledDeliveryZones
                      .map((item) => DropdownMenuItem(
                          value: item.key, child: Text(_zoneLabel(item.key))))
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _province = value;
                        _deliveryFee = _feeFor(value);
                        _payment = _availablePayments
                                .any((method) => method.$1 == _payment)
                            ? _payment
                            : _availablePayments.firstOrNull?.$1 ?? '';
                      });
                      if (_couponApplied) _applyCoupon();
                    }
                  }),
            const SizedBox(height: 12),
            TextFormField(
                controller: _district,
                decoration: const InputDecoration(
                    labelText: 'District / area',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(14)))),
                onChanged: (_) => _onDeliveryDetailsChanged()),
            const SizedBox(height: 12),
            TextFormField(
                controller: _addressLine2,
                decoration: const InputDecoration(
                    labelText: 'Village / commune (optional)',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(14)))),
                onChanged: (_) => _onDeliveryDetailsChanged()),
            const SizedBox(height: 12),
            TextFormField(
                controller: _address,
                minLines: 2,
                maxLines: 3,
                decoration: const InputDecoration(
                    labelText: 'Street address',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(14)))),
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Enter the delivery address'
                    : null,
                onChanged: (_) => _onDeliveryDetailsChanged()),
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
                      _summaryRow('Delivery', _checkoutDeliveryFee),
                      if (_couponDiscount > 0)
                        _summaryRow('Coupon discount', -_couponDiscount),
                      const Divider(),
                      _summaryRow('Total',
                          subtotal + _checkoutDeliveryFee - _couponDiscount,
                          strong: true)
                    ]))),
            const SizedBox(height: 12),
            FilledButton(
                onPressed:
                    _submitting || _loadingDelivery || _deliveryError != null
                        ? null
                        : _submit,
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
