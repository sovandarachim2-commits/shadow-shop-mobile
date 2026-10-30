import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shadow_shop_mobile/state/shop_state.dart';
import 'package:shadow_shop_mobile/theme/app_theme.dart';

const Color _primaryPink = Color(0xFFEC4899);
const Color _cardBg = Colors.white;
const Color _textDark = Color(0xFF0F172A);
const Color _textMuted = Color(0xFF64748B);
const Color _borderColor = Color(0xFFF1F5F9);

class MyCouponsPage extends StatefulWidget {
  const MyCouponsPage({super.key});

  @override
  State<MyCouponsPage> createState() => _MyCouponsPageState();
}

class _MyCouponsPageState extends State<MyCouponsPage> {
  late Future<Map<String, dynamic>> _summary;
  String _filter = 'All';

  @override
  void initState() {
    super.initState();
    _summary = _loadSummary();
  }

  Future<Map<String, dynamic>> _loadSummary() {
    return context.read<ShopState>().service.rewards();
  }

  void _copyCouponCode(String code) {
    Clipboard.setData(ClipboardData(text: code));
    showStoreMessage(
      context,
      'Coupon code "$code" copied to clipboard!',
      icon: Icons.copy_rounded,
    );
  }

  String _formatDate(dynamic value) {
    if (value == null) return '';
    try {
      final dt = DateTime.parse('$value').toLocal();
      const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
    } catch (_) {
      return '$value'.split('T').first;
    }
  }

  String _couponDiscountLabel(Map<String, dynamic> coupon) {
    final type = coupon['coupon_discount_type']?.toString();
    final value = coupon['coupon_value'];
    final rewardType = coupon['reward_type']?.toString();

    if (rewardType == 'free_delivery') {
      return 'FREE DELIVERY';
    }
    if (type == 'percent') {
      final numVal = double.tryParse('$value') ?? 0;
      return '${numVal.toStringAsFixed(numVal.truncateToDouble() == numVal ? 0 : 2)}% OFF';
    }
    if (value != null) {
      final numVal = double.tryParse('$value') ?? 0;
      return '\$${numVal.toStringAsFixed(2)} OFF';
    }
    return coupon['reward_name']?.toString() ?? 'PROMO';
  }

  void _showCouponDetails(Map<String, dynamic> coupon) {
    final code = '${coupon['coupon_code'] ?? coupon['promo_code'] ?? '—'}';
    final name = coupon['reward_name']?.toString() ?? 'Discount Coupon';
    final discountLabel = _couponDiscountLabel(coupon);
    final minSpend = coupon['minimum_order_amount'];
    final expires = _formatDate(coupon['expires_at'] ?? coupon['ends_at']);
    final status = (coupon['status'] ?? 'active').toString().toLowerCase();

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      backgroundColor: Colors.white,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFDF2F8),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(Icons.confirmation_number_rounded, color: _primaryPink, size: 28),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        discountLabel,
                        style: const TextStyle(
                          color: _primaryPink,
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        name,
                        style: const TextStyle(color: _textDark, fontSize: 13, fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('COUPON CODE', style: TextStyle(color: _textMuted, fontSize: 10, fontWeight: FontWeight.w700)),
                        const SizedBox(height: 2),
                        Text(
                          code,
                          style: const TextStyle(
                            color: _textDark,
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  FilledButton.tonalIcon(
                    onPressed: () {
                      Navigator.pop(ctx);
                      _copyCouponCode(code);
                    },
                    icon: const Icon(Icons.copy_rounded, size: 16),
                    label: const Text('Copy'),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFFFDF2F8),
                      foregroundColor: _primaryPink,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            _buildDetailRow(
              'Minimum Spend',
              minSpend != null && (double.tryParse('$minSpend') ?? 0) > 0
                  ? '\$${double.parse('$minSpend').toStringAsFixed(2)}'
                  : 'No minimum order',
            ),
            const SizedBox(height: 10),
            _buildDetailRow('Status', status.toUpperCase(), valueColor: status == 'active' ? const Color(0xFF10B981) : _textMuted),
            if (expires.isNotEmpty) ...[
              const SizedBox(height: 10),
              _buildDetailRow('Valid Until', expires),
            ],
            const SizedBox(height: 22),
            SizedBox(
              width: double.infinity,
              height: 44,
              child: OutlinedButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Close'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: _textMuted, fontSize: 13)),
        Text(
          value,
          style: TextStyle(
            color: valueColor ?? _textDark,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('My Coupons'),
        elevation: 0,
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _summary,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: _primaryPink));
          }
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline_rounded, size: 44, color: Color(0xFFEF4444)),
                    const SizedBox(height: 12),
                    Text(friendlyError(snapshot.error), textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                    OutlinedButton(
                      onPressed: () => setState(() => _summary = _loadSummary()),
                      child: const Text('Try Again'),
                    ),
                  ],
                ),
              ),
            );
          }

          final redemptions = (snapshot.data?['redemptions'] as List? ?? const [])
              .whereType<Map>()
              .map((row) => Map<String, dynamic>.from(row))
              .toList();

          final allCoupons = redemptions
              .where((row) => row['coupon_code'] != null || row['promo_code'] != null)
              .toList();

          final filtered = allCoupons.where((row) {
            final status = (row['status'] ?? 'active').toString().toLowerCase();
            if (_filter == 'Available') return status == 'active';
            if (_filter == 'Used') return status == 'used';
            if (_filter == 'Expired') return status == 'expired';
            return true;
          }).toList();

          final availableCount = allCoupons.where((r) => (r['status'] ?? 'active').toString().toLowerCase() == 'active').length;
          final usedCount = allCoupons.where((r) => (r['status'] ?? '').toString().toLowerCase() == 'used').length;
          final expiredCount = allCoupons.where((r) => (r['status'] ?? '').toString().toLowerCase() == 'expired').length;

          return RefreshIndicator(
            color: _primaryPink,
            onRefresh: () async {
              setState(() => _summary = _loadSummary());
              await _summary;
            },
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 36),
              children: [
                // Filter Tabs
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      _buildFilterTab('All', allCoupons.length),
                      _buildFilterTab('Available', availableCount),
                      _buildFilterTab('Used', usedCount),
                      _buildFilterTab('Expired', expiredCount),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                if (filtered.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 20),
                    decoration: BoxDecoration(
                      color: _cardBg,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: _borderColor),
                    ),
                    child: Column(
                      children: [
                        const Icon(Icons.confirmation_number_outlined, size: 52, color: Color(0xFFCBD5E1)),
                        const SizedBox(height: 14),
                        Text(
                          _filter == 'All'
                              ? 'No coupons in your wallet'
                              : 'No $_filter coupons',
                          style: const TextStyle(
                            color: _textDark,
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Redeem reward points on the Rewards page to receive exclusive discount vouchers.',
                          style: TextStyle(color: _textMuted, fontSize: 12),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  )
                else
                  ...filtered.map((coupon) => _buildCouponCard(coupon)),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildCouponCard(Map<String, dynamic> coupon) {
    final code = '${coupon['coupon_code'] ?? coupon['promo_code'] ?? '—'}';
    final name = coupon['reward_name']?.toString() ?? 'Reward Voucher';
    final discountLabel = _couponDiscountLabel(coupon);
    final minSpend = coupon['minimum_order_amount'];
    final expires = _formatDate(coupon['expires_at'] ?? coupon['ends_at']);
    final status = (coupon['status'] ?? 'active').toString().toLowerCase();
    final isAvailable = status == 'active';

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isAvailable ? const Color(0xFFFBCFE8) : _borderColor,
          width: isAvailable ? 1.2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isAvailable ? _primaryPink.withValues(alpha: 0.06) : Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showCouponDetails(coupon),
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Left Ticket Notch / Accent
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    color: isAvailable ? const Color(0xFFFDF2F8) : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    Icons.confirmation_number_rounded,
                    color: isAvailable ? _primaryPink : const Color(0xFF94A3B8),
                    size: 26,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              discountLabel,
                              style: TextStyle(
                                color: isAvailable ? _primaryPink : _textMuted,
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: isAvailable ? const Color(0xFFECFDF5) : const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              isAvailable ? 'Available' : status.toUpperCase(),
                              style: TextStyle(
                                color: isAvailable ? const Color(0xFF059669) : _textMuted,
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: _textDark,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: const Color(0xFFE2E8F0)),
                            ),
                            child: Text(
                              code,
                              style: const TextStyle(
                                color: _textDark,
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.8,
                              ),
                            ),
                          ),
                          if (minSpend != null && (double.tryParse('$minSpend') ?? 0) > 0) ...[
                            const SizedBox(width: 8),
                            Text(
                              'Min. \$${double.parse('$minSpend').toStringAsFixed(0)}',
                              style: const TextStyle(color: _textMuted, fontSize: 11),
                            ),
                          ],
                        ],
                      ),
                      if (expires.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Expires: $expires',
                          style: const TextStyle(color: _textMuted, fontSize: 10),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: () => _copyCouponCode(code),
                  tooltip: 'Copy Code',
                  icon: const Icon(Icons.copy_rounded, color: _primaryPink, size: 20),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFilterTab(String label, int count) {
    final selected = _filter == label;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _filter = label),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: selected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: selected ? _primaryPink : _textMuted,
                  fontSize: 11,
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '$count',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: selected ? _primaryPink : _textMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
