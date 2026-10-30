import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shadow_shop_mobile/state/shop_state.dart';
import 'package:shadow_shop_mobile/features/customer/address/address_book_screen.dart';
import 'package:shadow_shop_mobile/features/customer/rewards/redeem/redeem_page.dart';
import 'package:shadow_shop_mobile/theme/app_theme.dart';

const Color _primaryPink = Color(0xFFEC4899);
const Color _bodyBg = Color(0xFFF8FAFC);
const Color _cardBg = Colors.white;
const Color _textDark = Color(0xFF0F172A);
const Color _textMuted = Color(0xFF64748B);
const Color _borderColor = Color(0xFFF1F5F9);

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
  int? _selectedAddressId;
  String? _selectedAddressLabel;

  Future<void> _openAddressBookPicker() async {
    final selected = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (_) => AddressBookScreen(
          isPicker: true,
          selectedAddressId: _selectedAddressId,
        ),
      ),
    );
    if (!mounted) return;
    if (selected != null) {
      _applySelectedAddress(selected);
    } else {
      final state = context.read<ShopState>();
      final addresses = state.savedAddresses;
      if (_selectedAddressId != null) {
        final current = addresses.where((a) => a['id'] == _selectedAddressId).firstOrNull;
        if (current != null) {
          _applySelectedAddress(current);
          return;
        }
      }
      final def = addresses.where((a) => a['is_default'] == true).firstOrNull ?? addresses.firstOrNull;
      if (def != null) {
        _applySelectedAddress(def);
      }
    }
  }

  void _applySelectedAddress(Map<String, dynamic> selected) {
    setState(() {
      _selectedAddressId = int.tryParse('${selected['id']}');
      _selectedAddressLabel = selected['label']?.toString();
      _name.text = selected['full_name']?.toString() ?? '';
      _phone.text = selected['phone']?.toString() ?? '';
      _address.text = selected['address_line1']?.toString() ?? '';
      _province = _matchDeliveryZone(selected['state']?.toString()) ?? _defaultDeliveryZone;
      _deliveryFee = _feeFor(_province);
    });
    if (_couponApplied) _applyCoupon();
  }

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
    if (state.couponCode.isNotEmpty) {
      _coupon.text = state.couponCode;
    }
    _loadDelivery().then((_) {
      if (state.couponCode.isNotEmpty && mounted) {
        _applyCoupon();
      }
    });
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
      final savedAddress = addresses.where((item) => item['is_default'] == true).firstOrNull ?? addresses.firstOrNull;
      setState(() {
        _siteSettings = settings;
        if (savedAddress != null) {
          _selectedAddressId = int.tryParse('${savedAddress['id']}');
          _selectedAddressLabel = savedAddress['label']?.toString();
          _name.text = savedAddress['full_name']?.toString() ?? _name.text;
          _phone.text = savedAddress['phone']?.toString() ?? _phone.text;
          _address.text = savedAddress['address_line1']?.toString() ?? '';
          _addressLine2.text = savedAddress['address_line2']?.toString() ?? '';
          _district.text = savedAddress['city']?.toString() ?? '';
          _province = _matchDeliveryZone(savedAddress['state']?.toString()) ?? _defaultDeliveryZone;
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
    final configured = _siteSettings?['delivery_zones'];
    if (configured is Map && configured.isNotEmpty) {
      return Map<String, dynamic>.from(configured);
    }
    return _defaultDeliveryFees;
  }

  List<MapEntry<String, dynamic>> get _enabledDeliveryZones => _deliveryZones.entries.where((entry) {
        final value = entry.value;
        return value is! Map || value['enabled'] != false;
      }).toList();

  String get _defaultDeliveryZone {
    final zones = _enabledDeliveryZones;
    return zones.where((entry) => entry.value is Map && entry.value['is_default'] == true).firstOrNull?.key ??
        zones.firstOrNull?.key ??
        'phnom_penh';
  }

  String _zoneLabel(String key) {
    final value = _deliveryZones[key];
    if (value is Map && value['label'] != null) {
      return value['label'].toString();
    }
    return _provinceLabels[key] ??
        key.split('_').map((part) => part.isEmpty ? part : '${part[0].toUpperCase()}${part.substring(1)}').join(' ');
  }

  String? _matchDeliveryZone(String? addressState) {
    final state = addressState?.trim().toLowerCase();
    if (state == null || state.isEmpty) return null;
    for (final entry in _enabledDeliveryZones) {
      if (entry.key.toLowerCase() == state || _zoneLabel(entry.key).toLowerCase() == state) {
        return entry.key;
      }
    }
    final normalizedState = state.replaceAll(RegExp(r'[^a-z0-9]+'), '_');
    return _enabledDeliveryZones.where((entry) => entry.key.toLowerCase() == normalizedState).firstOrNull?.key;
  }

  double _feeFor(String province) {
    final value = _deliveryZones[province];
    final fee = value is Map ? value['fee'] : value;
    return double.tryParse('$fee') ?? 0;
  }

  bool get _hasDeliveryAddress =>
      _name.text.trim().isNotEmpty && _phone.text.trim().isNotEmpty && _address.text.trim().isNotEmpty;

  double get _checkoutDeliveryFee => _hasDeliveryAddress ? _deliveryFee : 0;

  String get _orderDeliveryNote {
    final location = _zoneLabel(_province);
    final customNote = _notes.text.trim();
    return [
      'Home delivery${location.isEmpty ? '' : '. $location'}',
      if (customNote.isNotEmpty) 'Delivery note: $customNote',
    ].join('. ');
  }

  List<(String, String, String)> get _availablePayments {
    const methods = <(String, String, String)>[
      ('bakong', 'Bakong KHQR', 'Scan and pay with Bakong'),
      ('aba', 'ABA KHQR', 'Scan to pay with any banking app'),
      ('cod', 'Cash On Delivery', 'Pay when you receive'),
      ('acleda', 'ACLEDA Bank', 'Pay with ACLEDA Mobile'),
      ('wing', 'Wing', 'Pay with Wing'),
      ('contact_sales', 'Contact Sales', 'Our sales team will contact you'),
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
    if (code.isEmpty) {
      setState(() {
        _couponDiscount = 0;
        _couponApplied = false;
        _couponError = null;
      });
      return;
    }
    final state = context.read<ShopState>();
    try {
      final subtotal = state.subtotal;
      final result = await state.service.validateCoupon(
        code,
        subtotal,
        _checkoutDeliveryFee,
      );
      if (!mounted) return;
      setState(() {
        _couponDiscount = double.tryParse('${result['discount'] ?? 0}') ?? 0;
        _couponApplied = true;
        _couponError = null;
      });
      showStoreMessage(context, 'Coupon applied successfully!', icon: Icons.check_circle_rounded);
    } on DioException catch (error) {
      if (!mounted) return;
      final body = error.response?.data;
      final message = body is Map ? body['detail'] ?? body['coupon_code'] : null;
      setState(() {
        _couponDiscount = 0;
        _couponApplied = false;
        _couponError = message?.toString() ?? 'Invalid coupon code';
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _couponDiscount = 0;
        _couponApplied = false;
        _couponError = 'Could not validate coupon';
      });
    }
  }

  Future<void> _openMyCouponsSheet() async {
    final state = context.read<ShopState>();
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) => DraggableScrollableSheet(
        initialChildSize: 0.65,
        minChildSize: 0.4,
        maxChildSize: 0.85,
        expand: false,
        builder: (_, scrollController) => Column(
          children: [
            const SizedBox(height: 12),
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 16, 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'MY COUPONS',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.8,
                          color: _primaryPink,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Coupons & Vouchers',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                          color: _textDark,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: _textMuted, size: 22),
                    onPressed: () => Navigator.pop(sheetContext),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: _borderColor),
            Expanded(
              child: FutureBuilder<Map<String, dynamic>>(
                future: state.service.rewards(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(color: _primaryPink),
                    );
                  }
                  if (snapshot.hasError) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          friendlyError(snapshot.error),
                          style: const TextStyle(color: _textMuted, fontSize: 13),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    );
                  }

                  final redemptions = (snapshot.data?['redemptions'] as List? ?? const [])
                      .whereType<Map>()
                      .map((row) => Map<String, dynamic>.from(row))
                      .toList();

                  final activeCoupons = redemptions.where((row) {
                    final code = (row['coupon_code'] ?? row['promo_code'])?.toString().trim();
                    if (code == null || code.isEmpty) return false;
                    final status = (row['status'] ?? 'active').toString().toLowerCase();
                    if (status == 'used') return false;
                    final endsAt = row['ends_at'] ?? row['expires_at'];
                    if (endsAt != null) {
                      final exp = DateTime.tryParse('$endsAt');
                      if (exp != null && exp.isBefore(DateTime.now())) return false;
                    }
                    return true;
                  }).toList();

                  if (activeCoupons.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 64,
                              height: 64,
                              decoration: const BoxDecoration(
                                color: Color(0xFFFDF2F8),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.confirmation_number_outlined,
                                size: 32,
                                color: _primaryPink,
                              ),
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'No Available Coupons',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: _textDark,
                              ),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'Redeem your reward points to earn discount vouchers and delivery coupons.',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 12, color: _textMuted),
                            ),
                            const SizedBox(height: 20),
                            FilledButton.icon(
                              onPressed: () {
                                Navigator.pop(sheetContext);
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => const RedeemRewardsPage()),
                                );
                              },
                              style: FilledButton.styleFrom(
                                backgroundColor: _primaryPink,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                              ),
                              icon: const Icon(Icons.card_giftcard_rounded, size: 18),
                              label: const Text('Redeem Rewards', style: TextStyle(fontWeight: FontWeight.w800)),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  return ListView.separated(
                    controller: scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: activeCoupons.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final coupon = activeCoupons[index];
                      final code = '${coupon['coupon_code'] ?? coupon['promo_code'] ?? ''}'.trim();
                      final isApplied = _couponApplied && _coupon.text.trim().toUpperCase() == code.toUpperCase();
                      final rewardType = coupon['reward_type']?.toString().toLowerCase();
                      final discountType = coupon['coupon_discount_type']?.toString().toLowerCase();
                      final val = coupon['coupon_value'];
                      final minSpend = coupon['minimum_order_amount'];
                      final name = coupon['reward_name']?.toString() ?? 'Discount Coupon';

                      IconData icon = Icons.confirmation_number_outlined;
                      Color iconBg = const Color(0xFFFDF2F8);
                      Color iconColor = _primaryPink;
                      String discountDesc = '';

                      if (rewardType == 'free_delivery' || discountType == 'free_delivery') {
                        icon = Icons.local_shipping_outlined;
                        iconBg = const Color(0xFFEFF6FF);
                        iconColor = const Color(0xFF2563EB);
                        discountDesc = 'Free Delivery';
                      } else if (discountType == 'percent') {
                        icon = Icons.percent_rounded;
                        discountDesc = '${val ?? 0}% OFF';
                      } else {
                        icon = Icons.confirmation_number_outlined;
                        discountDesc = '\$${double.tryParse('$val')?.toStringAsFixed(2) ?? val} OFF';
                      }

                      if (minSpend != null && (double.tryParse('$minSpend') ?? 0) > 0) {
                        discountDesc += ' · Min \$${double.tryParse('$minSpend')?.toStringAsFixed(0)}';
                      }

                      return Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: isApplied ? const Color(0xFFFDF2F8) : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isApplied ? _primaryPink : _borderColor,
                            width: isApplied ? 1.5 : 1.0,
                          ),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x060F172A),
                              blurRadius: 8,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: iconBg,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(icon, size: 22, color: iconColor),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w800,
                                      color: _textDark,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    discountDesc,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: _textMuted,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF1F5F9),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      code,
                                      style: const TextStyle(
                                        fontFamily: 'monospace',
                                        fontSize: 11,
                                        fontWeight: FontWeight.w900,
                                        color: _primaryPink,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 10),
                            if (isApplied)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFECFDF5),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.check_rounded, size: 14, color: Color(0xFF10B981)),
                                    SizedBox(width: 2),
                                    Text(
                                      'Applied',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w900,
                                        color: Color(0xFF10B981),
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            else
                              FilledButton(
                                onPressed: () {
                                  Navigator.pop(sheetContext);
                                  _coupon.text = code;
                                  _applyCoupon();
                                },
                                style: FilledButton.styleFrom(
                                  backgroundColor: _primaryPink,
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                  minimumSize: Size.zero,
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                ),
                                child: const Text(
                                  'Apply',
                                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
                                ),
                              ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    if (_payment.isEmpty) {
      showStoreMessage(context, 'Please select a payment method.', icon: Icons.payment_rounded);
      return;
    }
    if (!_hasDeliveryAddress) {
      await _openAddressBookPicker();
      if (!_hasDeliveryAddress && mounted) {
        showStoreMessage(context, 'Please select or add a delivery address first.', icon: Icons.location_on_outlined);
      }
      return;
    }

    final state = context.read<ShopState>();
    setState(() => _submitting = true);
    try {
      final items = state.cartLines.map((line) {
        final p = line.product;
        return {
          if (p.isProductSet)
            'product_set': p.productSetId ?? p.id
          else
            'product': p.id,
          'product_id': p.id,
          'quantity': line.quantity,
          'unit_price': p.price,
          'cost_price': 0,
          'discount': 0,
        };
      }).toList();

      final nameVal = _name.text.trim();
      final phoneVal = _phone.text.trim();
      final addressVal = _address.text.trim().isNotEmpty ? _address.text.trim() : _zoneLabel(_province);

      final payload = {
        'items': items,
        'name': nameVal,
        'phone': phoneVal,
        'address': addressVal,
        'address_detail': _address.text.trim(),
        'province': _province,
        'district': _district.text.trim(),
        'payment_method': _payment,
        'payment_status': 'unpaid',
        'delivery_fee': _checkoutDeliveryFee,
        'notes': _notes.text.trim(),
        if (_couponApplied && _coupon.text.trim().isNotEmpty) 'coupon_code': _coupon.text.trim(),

        // Compatibility aliases
        'customer_name': nameVal,
        'customer_phone': phoneVal,
        'address_line1': addressVal,
        'state': _province,
        'delivery_notes': _orderDeliveryNote,
      };

      final result = await state.service.checkout(payload);
      if (!mounted) return;

      if (['bakong', 'aba'].contains(_payment) && result['pending_checkout'] != null) {
        final pending = Map<String, dynamic>.from(result['pending_checkout']);
        final bakong = result['bakong_payment'] is Map
            ? Map<String, dynamic>.from(result['bakong_payment'])
            : <String, dynamic>{};
        final qrData = (bakong['qr_image'] ?? pending['qr_image'])?.toString();

        await showDialog<void>(
          context: context,
          barrierDismissible: false,
          builder: (dialogContext) => Dialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            backgroundColor: Colors.white,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Scan to Pay', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: _textDark)),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, size: 20),
                        onPressed: () => Navigator.pop(dialogContext),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (qrData != null)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: _borderColor),
                      ),
                      child: qrData.startsWith('data:image')
                          ? Image.memory(base64Decode(qrData.split(',').last), height: 180)
                          : Image.network(qrData, height: 180),
                    ),
                  const SizedBox(height: 12),
                  const Text(
                    'Scan the KHQR with your banking app to finish payment.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: _textMuted),
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      style: FilledButton.styleFrom(backgroundColor: _primaryPink),
                      onPressed: () async {
                        try {
                          final status = await state.service.verifyOrder('${pending['reference']}');
                          if (!dialogContext.mounted) return;
                          final paid = status['status'] == 'paid';
                          showStoreMessage(
                            dialogContext,
                            paid ? 'Payment confirmed by Shadow Shop.' : 'Status: ${status['status'] ?? 'pending'}',
                            icon: paid ? Icons.check_circle_rounded : Icons.info_outline_rounded,
                          );
                          if (paid) Navigator.pop(dialogContext);
                        } catch (e) {
                          if (dialogContext.mounted) {
                            showStoreMessage(dialogContext, friendlyError(e), icon: Icons.error_outline_rounded);
                          }
                        }
                      },
                      child: const Text('Check Payment Status'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
        return;
      }

      await showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          backgroundColor: Colors.white,
          icon: const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 48),
          title: const Text('Order Placed!', style: TextStyle(fontWeight: FontWeight.w800, color: _textDark)),
          content: Text(
            'Order #${result['order_number'] ?? ''} has been sent successfully.',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 13, color: _textMuted),
          ),
          actions: [
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: _primaryPink),
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Done'),
            ),
          ],
        ),
      );
      state.clearCart();
      if (mounted) Navigator.pop(context);
    } on DioException catch (error) {
      final body = error.response?.data;
      String message = 'Checkout failed.';
      if (body is Map) {
        if (body['detail'] != null) {
          message = '${body['detail']}';
        } else if (body.isNotEmpty) {
          final firstVal = body.values.first;
          if (firstVal is List && firstVal.isNotEmpty) {
            message = '${firstVal.first}';
          } else {
            message = '$firstVal';
          }
        }
      } else if (body is String && body.isNotEmpty) {
        message = body;
      }
      if (mounted) {
        showStoreMessage(context, message, icon: Icons.error_outline_rounded);
      }
    } catch (error) {
      if (mounted) {
        showStoreMessage(context, friendlyError(error), icon: Icons.error_outline_rounded);
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<ShopState>();
    final subtotal = state.subtotal;
    final total = subtotal + _checkoutDeliveryFee - _couponDiscount;

    return Scaffold(
      backgroundColor: _bodyBg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: _textDark, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Column(
          children: [
            Text(
              'CHECKOUT',
              style: TextStyle(
                color: _primaryPink,
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.0,
              ),
            ),
            SizedBox(height: 2),
            Text(
              'Secure Checkout',
              style: TextStyle(
                color: _textDark,
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: _borderColor, height: 1),
        ),
      ),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
          children: [
            // 1. Delivery Address Card (Website Style)
            _buildCardContainer(
              title: 'Delivery Address',
              trailing: TextButton(
                onPressed: _openAddressBookPicker,
                style: TextButton.styleFrom(
                  foregroundColor: _primaryPink,
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  _hasDeliveryAddress ? 'Change' : '+ Add Address',
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: _primaryPink),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (_deliveryError != null)
                    Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEE4E2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(_deliveryError!,
                          style: const TextStyle(
                              color: Color(0xFFB42318), fontSize: 12)),
                    ),

                  if (!_hasDeliveryAddress)
                    InkWell(
                      onTap: _openAddressBookPicker,
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 46,
                              height: 46,
                              decoration: const BoxDecoration(
                                color: Color(0xFFFDF2F8),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.add_location_alt_outlined,
                                size: 24,
                                color: _primaryPink,
                              ),
                            ),
                            const SizedBox(height: 10),
                            const Text(
                              'No Delivery Address Selected',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                color: _textDark,
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Please select or add a delivery address to proceed',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 12,
                                color: _textMuted,
                              ),
                            ),
                            const SizedBox(height: 12),
                            FilledButton.icon(
                              onPressed: _openAddressBookPicker,
                              icon: const Icon(Icons.add_rounded, size: 16),
                              label: const Text('Add / Select Address'),
                              style: FilledButton.styleFrom(
                                backgroundColor: _primaryPink,
                                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    // Website soft-pink delivery address card
                    InkWell(
                      onTap: _openAddressBookPicker,
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFDF2F8),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFFCE7F3)),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 38,
                              height: 38,
                              decoration: const BoxDecoration(
                                color: Color(0xFFFBCFE8),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.location_on_rounded, size: 20, color: _primaryPink),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Wrap(
                                    crossAxisAlignment: WrapCrossAlignment.center,
                                    spacing: 8,
                                    runSpacing: 4,
                                    children: [
                                      Text(
                                        _name.text.isNotEmpty ? _name.text : 'Select Delivery Address',
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w900,
                                          color: _textDark,
                                        ),
                                      ),
                                      if (_phone.text.isNotEmpty)
                                        Text(
                                          _phone.text,
                                          style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: _textMuted,
                                          ),
                                        ),
                                      if (_selectedAddressLabel != null && _selectedAddressLabel!.isNotEmpty)
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFFCE7F3),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            _selectedAddressLabel!.toUpperCase(),
                                            style: const TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.w900,
                                              color: _primaryPink,
                                              letterSpacing: 0.5,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    "${_address.text}, ${_zoneLabel(_province)}",
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                      color: Color(0xFF334155),
                                      height: 1.3,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _notes,
                    decoration: _inputDecoration('Delivery note (optional)', Icons.edit_note_rounded),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 2. Voucher / Coupon Code Card
            _buildCardContainer(
              title: 'Voucher / Coupon Code',
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_couponApplied) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFECFDF5),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'SAVED \$${_couponDiscount.toStringAsFixed(2)}',
                        style: const TextStyle(
                          color: Color(0xFF10B981),
                          fontWeight: FontWeight.w900,
                          fontSize: 10,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  InkWell(
                    onTap: _openMyCouponsSheet,
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFDF2F8),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFFCE7F3)),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.confirmation_number_outlined, size: 13, color: _primaryPink),
                          SizedBox(width: 4),
                          Text(
                            'My Coupons',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                              color: _primaryPink,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _coupon,
                          textCapitalization: TextCapitalization.characters,
                          decoration: InputDecoration(
                            hintText: 'Enter promo code',
                            hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            filled: true,
                            fillColor: const Color(0xFFF8FAFC),
                            errorText: _couponError,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: _borderColor),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: _borderColor),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: _primaryPink),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      FilledButton(
                        onPressed: _applyCoupon,
                        style: FilledButton.styleFrom(
                          backgroundColor: _primaryPink,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                        ),
                        child: const Text('Apply', style: TextStyle(fontWeight: FontWeight.w800)),
                      ),
                    ],
                  ),
                  if (_couponApplied) ...[
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 16),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Coupon applied: ${_coupon.text.toUpperCase()}',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF10B981)),
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              _coupon.clear();
                              _couponDiscount = 0;
                              _couponApplied = false;
                              _couponError = null;
                            });
                          },
                          child: const Text(
                            'Remove',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFFEF4444)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 3. Payment Method Card (Website Style)
            _buildCardContainer(
              title: 'Payment Method',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final method in _availablePayments) ...[
                    GestureDetector(
                      onTap: () => setState(() => _payment = method.$1),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: _payment == method.$1
                              ? (method.$1 == 'aba' ? const Color(0xFFEFF6FF) : const Color(0xFFFDF2F8))
                              : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: _payment == method.$1
                                ? (method.$1 == 'aba' ? const Color(0xFF2563EB) : _primaryPink)
                                : _borderColor,
                            width: _payment == method.$1 ? 2.0 : 1.0,
                          ),
                        ),
                        child: Row(
                          children: [
                            _buildPaymentLogo(method.$1),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    method.$2,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w800,
                                      color: _textDark,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    method.$3,
                                    style: const TextStyle(fontSize: 12, color: _textMuted),
                                  ),
                                ],
                              ),
                            ),
                            if (_payment == method.$1)
                              Icon(
                                Icons.check_circle_rounded,
                                size: 20,
                                color: method.$1 == 'aba' ? const Color(0xFF2563EB) : _primaryPink,
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                  if (_payment.isEmpty)
                    const Padding(
                      padding: EdgeInsets.only(top: 4, left: 2),
                      child: Text(
                        'Please select a payment method.',
                        style: TextStyle(
                          color: _primaryPink,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  if (_payment == 'contact_sales')
                    Container(
                      margin: const EdgeInsets.only(top: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFDF2F8),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFFCE7F3)),
                      ),
                      child: const Text(
                        'Our sales team will contact you to confirm payment and order details.',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: _primaryPink,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 4. Order Items Preview Card
            _buildCardContainer(
              title: 'Order Items',
              icon: Icons.shopping_bag_outlined,
              child: Column(
                children: [
                  for (final line in state.cartLines)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              width: 44,
                              height: 44,
                              color: const Color(0xFFF8FAFC),
                              child: line.product.imageUrl != null
                                  ? Image.network(line.product.imageUrl!, fit: BoxFit.cover)
                                  : const Icon(Icons.spa_outlined, color: _primaryPink, size: 20),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  line.product.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: _textDark),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Qty: ${line.quantity} × \$${line.product.price.toStringAsFixed(2)}',
                                  style: const TextStyle(fontSize: 11, color: _textMuted),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            '\$${line.total.toStringAsFixed(2)}',
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: _textDark),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            const SizedBox(height: 16),

            // 5. Order Summary Card
            _buildCardContainer(
              title: 'Order Summary',
              icon: Icons.receipt_long_outlined,
              child: Column(
                children: [
                  _summaryRow('Subtotal', subtotal),
                  const SizedBox(height: 8),
                  _summaryRow('Delivery Fee', _checkoutDeliveryFee),
                  if (_couponDiscount > 0) ...[
                    const SizedBox(height: 8),
                    _summaryRow('Coupon Discount', -_couponDiscount, isDiscount: true),
                  ],
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 10),
                    child: Divider(color: _borderColor, height: 1),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Total Amount',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: _textDark),
                      ),
                      Text(
                        '\$${total.toStringAsFixed(2)}',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: _primaryPink),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        decoration: BoxDecoration(
          color: Colors.white,
          border: const Border(top: BorderSide(color: _borderColor, width: 1.5)),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0F172A).withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, -3),
            ),
          ],
        ),
        child: SafeArea(
          child: Row(
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '\$${total.toStringAsFixed(2)}',
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: _textDark),
                  ),
                  Text(
                    '${state.cartLines.length} ${state.cartLines.length == 1 ? 'item' : 'items'}',
                    style: const TextStyle(fontSize: 12, color: _textMuted, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
              const Spacer(),
              ElevatedButton(
                onPressed: _submitting || _loadingDelivery ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primaryPink,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 12),
                  shape: const StadiumBorder(),
                ),
                child: _submitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text(
                        'Place Order',
                        style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentLogo(String key) {
    final logoUrls = _siteSettings?['payment_methods']?['logo_urls'];
    final dynamic customUrl = logoUrls is Map ? logoUrls[key] : null;

    if (customUrl is String && customUrl.trim().isNotEmpty) {
      return Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Colors.white,
          border: Border.all(color: const Color(0xFFF1F5F9)),
        ),
        clipBehavior: Clip.antiAlias,
        child: Image.network(
          customUrl,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _buildDefaultPaymentLogo(key),
        ),
      );
    }
    return _buildDefaultPaymentLogo(key);
  }

  Widget _buildDefaultPaymentLogo(String key) {
    switch (key) {
      case 'aba':
        return Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: const Color(0xFF003764),
            borderRadius: BorderRadius.circular(12),
            boxShadow: const [
              BoxShadow(color: Color(0x0A0F172A), blurRadius: 4, offset: Offset(0, 2)),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              const Expanded(
                child: Center(
                  child: Text(
                    'ABA',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 12.5,
                      letterSpacing: 0.5,
                      height: 1.0,
                    ),
                  ),
                ),
              ),
              Container(
                width: double.infinity,
                height: 14,
                color: const Color(0xFFE1232E),
                child: const Center(
                  child: Text(
                    'KHQR',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 7.5,
                      letterSpacing: 0.8,
                      height: 1.0,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );

      case 'bakong':
        return Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFF1F5F9)),
            boxShadow: const [
              BoxShadow(color: Color(0x080F172A), blurRadius: 4, offset: Offset(0, 2)),
            ],
          ),
          child: Center(
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFFDC2626), width: 2.2),
                borderRadius: BorderRadius.circular(9),
              ),
              child: Center(
                child: Container(
                  width: 17,
                  height: 17,
                  decoration: BoxDecoration(
                    border: Border.all(color: const Color(0xFFDC2626), width: 2.0),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Center(
                    child: Container(
                      width: 5,
                      height: 5,
                      decoration: const BoxDecoration(
                        color: Color(0xFFDC2626),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );

      case 'cod':
        return Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: const Color(0xFFE0F2FE),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Center(
            child: Icon(
              Icons.delivery_dining_rounded,
              size: 26,
              color: Color(0xFF0284C7),
            ),
          ),
        );

      case 'acleda':
        return Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: const Color(0xFF0C2040),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Center(
            child: Text(
              'ACLEDA',
              style: TextStyle(
                color: Color(0xFFE5A823),
                fontWeight: FontWeight.w900,
                fontSize: 8,
                letterSpacing: 0.5,
              ),
            ),
          ),
        );

      case 'wing':
        return Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: const Color(0xFF8DC63F),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Center(
            child: Text(
              'WING',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 10,
                letterSpacing: 0.5,
              ),
            ),
          ),
        );

      case 'contact_sales':
      default:
        return Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: const Color(0xFFF3E8FF),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Center(
            child: Icon(
              Icons.support_agent_rounded,
              size: 22,
              color: Color(0xFF9333EA),
            ),
          ),
        );
    }
  }

  Widget _buildCardContainer({required String title, IconData? icon, required Widget child, Widget? trailing}) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _borderColor),
        boxShadow: const [
          BoxShadow(
            color: Color(0x060F172A),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                  color: _textDark,
                ),
              ),
              if (trailing != null) ...[
                const Spacer(),
                trailing,
              ],
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: _textMuted, fontSize: 13),
      prefixIcon: Icon(icon, color: const Color(0xFF94A3B8), size: 18),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      filled: true,
      fillColor: const Color(0xFFF8FAFC),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: _borderColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: _borderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: _primaryPink),
      ),
    );
  }

  Widget _summaryRow(String label, double value, {bool isDiscount = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, color: _textMuted)),
        Text(
          isDiscount ? '-\$${value.abs().toStringAsFixed(2)}' : '\$${value.toStringAsFixed(2)}',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: isDiscount ? const Color(0xFF16A34A) : _textDark,
          ),
        ),
      ],
    );
  }
}
