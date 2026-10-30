import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shadow_shop_mobile/config/app_config.dart';
import 'package:shadow_shop_mobile/features/customer/cart/cart_screen.dart';
import 'package:shadow_shop_mobile/features/customer/rewards/coupons/coupons_page.dart';
import 'package:shadow_shop_mobile/state/shop_state.dart';
import 'package:shadow_shop_mobile/theme/app_theme.dart';

const Color _primaryPink = Color(0xFFEC4899);
const Color _bodyBg = Color(0xFFF8FAFC);
const Color _textDark = Color(0xFF0F172A);
const Color _textMuted = Color(0xFF64748B);
const Color _borderColor = Color(0xFFF1F5F9);

class RedeemRewardsPage extends StatefulWidget {
  const RedeemRewardsPage({super.key});

  @override
  State<RedeemRewardsPage> createState() => _RedeemRewardsPageState();
}

class _RedeemRewardsPageState extends State<RedeemRewardsPage> {
  late Future<Map<String, dynamic>> _summary;
  String _activeFilter = 'all';
  int? _redeemingId;

  final List<Map<String, String>> _filterTabs = const [
    {'key': 'all', 'label': 'All'},
    {'key': 'vouchers', 'label': 'Vouchers'},
    {'key': 'products', 'label': 'Products'},
    {'key': 'discounts', 'label': 'Discounts'},
    {'key': 'shipping', 'label': 'Shipping'},
  ];

  @override
  void initState() {
    super.initState();
    _summary = _loadRewards();
  }

  Future<Map<String, dynamic>> _loadRewards() {
    return context.read<ShopState>().service.rewards();
  }

  Future<void> _refresh() async {
    setState(() {
      _summary = _loadRewards();
    });
    await _summary;
  }

  String? _resolveImageUrl(dynamic path) {
    if (path == null) return null;
    final url = path.toString().trim();
    if (url.isEmpty) return null;
    if (url.startsWith('http://') || url.startsWith('https://')) return url;
    try {
      final base = Uri.parse(AppConfig.apiBaseUrl);
      final scheme = base.scheme.isNotEmpty ? base.scheme : 'http';
      final host = base.host.isNotEmpty ? base.host : '127.0.0.1';
      final port = base.hasPort ? ':${base.port}' : (base.port == 8000 ? ':8000' : '');
      final cleanPath = url.startsWith('/') ? url : '/$url';
      return '$scheme://$host$port$cleanPath';
    } catch (_) {
      return url;
    }
  }

  IconData _getTypeIcon(String type) {
    switch (type) {
      case 'voucher':
        return Icons.confirmation_number_outlined;
      case 'discount':
        return Icons.percent_rounded;
      case 'free_delivery':
        return Icons.local_shipping_outlined;
      case 'gift':
        return Icons.card_giftcard_rounded;
      case 'lucky_box':
        return Icons.inventory_2_outlined;
      default:
        return Icons.redeem_rounded;
    }
  }

  Color _getTypeTone(String type) {
    switch (type) {
      case 'discount':
      case 'voucher':
        return const Color(0xFFFDF2F8);
      case 'free_delivery':
        return const Color(0xFFF0F9FF);
      case 'gift':
        return const Color(0xFFFFFBEB);
      default:
        return const Color(0xFFF5F3FF);
    }
  }

  Color _getTypeIconColor(String type) {
    switch (type) {
      case 'discount':
      case 'voucher':
        return _primaryPink;
      case 'free_delivery':
        return const Color(0xFF0284C7);
      case 'gift':
        return const Color(0xFFF59E0B);
      default:
        return const Color(0xFF7C3AED);
    }
  }

  List<Map<String, dynamic>> _filterCatalog(List<dynamic> rawCatalog) {
    final catalog = rawCatalog.cast<Map<String, dynamic>>();
    if (_activeFilter == 'all') return catalog;
    if (_activeFilter == 'vouchers') {
      return catalog.where((r) => ['voucher', 'discount', 'free_delivery'].contains(r['type'])).toList();
    }
    if (_activeFilter == 'products') {
      return catalog.where((r) => ['gift', 'lucky_box'].contains(r['type'])).toList();
    }
    if (_activeFilter == 'discounts') {
      return catalog.where((r) => ['voucher', 'discount'].contains(r['type'])).toList();
    }
    if (_activeFilter == 'shipping') {
      return catalog.where((r) => r['type'] == 'free_delivery').toList();
    }
    return catalog;
  }

  Future<void> _handleRedeem(Map<String, dynamic> item, int currentPoints) async {
    final rewardId = item['id'];
    if (rewardId == null) return;

    final pointsReq = int.tryParse('${item['points_required']}') ?? 0;
    final rewardName = item['name']?.toString() ?? 'Reward';

    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFFDF2F8),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.card_giftcard_rounded, color: _primaryPink, size: 22),
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                'Confirm Exchange',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: _textDark),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Are you sure you want to exchange $pointsReq points for "$rewardName"?',
              style: const TextStyle(fontSize: 13, color: _textMuted, height: 1.4),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _borderColor),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Remaining Points:', style: TextStyle(fontSize: 12, color: _textMuted)),
                  Text(
                    '${(currentPoints - pointsReq).clamp(0, 9999999)} pts',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: _textDark),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx, false),
            child: const Text('Cancel', style: TextStyle(color: _textMuted, fontWeight: FontWeight.w600)),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogCtx, true),
            style: FilledButton.styleFrom(
              backgroundColor: _primaryPink,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Exchange', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    setState(() => _redeemingId = rewardId as int?);
    try {
      final res = await context.read<ShopState>().service.exchangeReward(rewardId as int);
      if (!mounted) return;

      final redemption = res['redemption'] as Map<String, dynamic>?;
      _refresh();

      if (redemption != null && redemption['coupon_code'] != null) {
        _showRedeemedDialog(redemption);
      } else {
        showStoreMessage(
          context,
          'Successfully exchanged for $rewardName!',
          icon: Icons.check_circle_rounded,
        );
      }
    } catch (e) {
      if (!mounted) return;
      String msg = 'Failed to exchange reward.';
      if (e is DioException) {
        final data = e.response?.data;
        if (data is Map && data['detail'] != null) {
          msg = data['detail'].toString();
        }
      }
      showStoreMessage(
        context,
        msg,
        icon: Icons.error_outline_rounded,
      );
    } finally {
      if (mounted) setState(() => _redeemingId = null);
    }
  }

  void _showRedeemedDialog(Map<String, dynamic> redemption) {
    final code = redemption['coupon_code']?.toString() ?? '';
    final name = redemption['reward_name']?.toString() ?? 'Reward Voucher';

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (dialogCtx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(dialogCtx),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Color(0xFFF1F5F9),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.close_rounded, size: 18, color: _textMuted),
                    ),
                  ),
                ],
              ),
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: const Color(0xFFFDF2F8),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(Icons.card_giftcard_rounded, color: _primaryPink, size: 32),
              ),
              const SizedBox(height: 14),
              const Text(
                'Redeemed!',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: _textDark,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Your coupon for "$name" is ready. Use it now or find it in My Coupons.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 12,
                  color: _textMuted,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFDF2F8),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFFCE7F3)),
                ),
                child: Column(
                  children: [
                    const Text(
                      'COUPON CODE',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                        color: _primaryPink,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.03),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.confirmation_number_rounded, color: _primaryPink, size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              code,
                              style: const TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: _textDark,
                                letterSpacing: 1.1,
                              ),
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              Clipboard.setData(ClipboardData(text: code));
                              showStoreMessage(
                                context,
                                'Coupon code "$code" copied!',
                                icon: Icons.copy_rounded,
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.copy_rounded, size: 16, color: _textMuted),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 46,
                child: ElevatedButton.icon(
                  onPressed: () {
                    context.read<ShopState>().couponCode = code;
                    Navigator.pop(dialogCtx);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const CartView()),
                    );
                    showStoreMessage(
                      context,
                      'Coupon $code applied to Cart!',
                      icon: Icons.check_circle_rounded,
                    );
                  },
                  icon: const Icon(Icons.shopping_cart_outlined, size: 18),
                  label: const Text('Use Now', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primaryPink,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                height: 44,
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.pop(dialogCtx);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const MyCouponsPage()),
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _textDark,
                    side: const BorderSide(color: Color(0xFFE2E8F0)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('My Coupons', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showRewardDetailSheet(Map<String, dynamic> reward, int currentPoints) {
    final pointsReq = int.tryParse('${reward['points_required']}') ?? 0;
    final hasStock = reward['stock'] == null || (int.tryParse('${reward['stock']}') ?? 1) > 0;
    final canExchange = (reward['can_exchange'] == true || currentPoints >= pointsReq) && hasStock;
    final name = reward['name']?.toString() ?? 'Reward';
    final description = reward['description']?.toString() ?? '';
    final type = reward['type']?.toString() ?? 'manual';
    final imageUrl = _resolveImageUrl(reward['reward_image_url'] ?? reward['gift_product_image']);
    final expiryDays = reward['expiry_days']?.toString();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: AspectRatio(
                  aspectRatio: 1.6,
                  child: Container(
                    color: const Color(0xFFF8FAFC),
                    child: imageUrl != null
                        ? Image.network(
                            imageUrl,
                            fit: BoxFit.contain,
                            errorBuilder: (_, __, ___) => Icon(
                              _getTypeIcon(type),
                              size: 48,
                              color: _getTypeIconColor(type),
                            ),
                          )
                        : Icon(
                            _getTypeIcon(type),
                            size: 48,
                            color: _getTypeIconColor(type),
                          ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                name,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: _textDark,
                ),
              ),
              if (description.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  description,
                  style: const TextStyle(fontSize: 13, color: _textMuted, height: 1.4),
                ),
              ],
              const SizedBox(height: 14),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF3C7),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.star_rounded, size: 14, color: Color(0xFFD97706)),
                        const SizedBox(width: 4),
                        Text(
                          '$pointsReq pts',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFFB45309),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (expiryDays != null && expiryDays.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'Valid for $expiryDays days',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: _textMuted,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: FilledButton(
                  onPressed: (!canExchange || _redeemingId != null)
                      ? null
                      : () {
                          Navigator.pop(sheetCtx);
                          _handleRedeem(reward, currentPoints);
                        },
                  style: FilledButton.styleFrom(
                    backgroundColor: _primaryPink,
                    disabledBackgroundColor: const Color(0xFFF1F5F9),
                    disabledForegroundColor: const Color(0xFF94A3B8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(
                    canExchange ? 'Redeem for $pointsReq pts' : (currentPoints < pointsReq ? 'More Points Needed' : 'Unavailable'),
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cartCount = context.watch<ShopState>().itemCount;

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
        title: const Text(
          'Redeem Rewards',
          style: TextStyle(
            color: _textDark,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        centerTitle: true,
        actions: [
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.shopping_cart_outlined, color: _textDark, size: 22),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CartView()),
                ),
              ),
              if (cartCount > 0)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                    decoration: const BoxDecoration(
                      color: _primaryPink,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                    child: Center(
                      child: Text(
                        cartCount > 9 ? '9+' : '$cartCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 4),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: _borderColor, height: 1),
        ),
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _summary,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: _primaryPink));
          }
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline_rounded, color: Color(0xFFEF4444), size: 40),
                  const SizedBox(height: 10),
                  const Text('Failed to load rewards', style: TextStyle(fontWeight: FontWeight.w700, color: _textDark)),
                  const SizedBox(height: 6),
                  TextButton(onPressed: _refresh, child: const Text('Try Again', style: TextStyle(color: _primaryPink))),
                ],
              ),
            );
          }

          final data = snapshot.data ?? {};
          final currentPoints = int.tryParse('${data['current_points']}') ?? 0;
          final catalog = (data['catalog'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>();
          final filtered = _filterCatalog(catalog);

          return RefreshIndicator(
            color: _primaryPink,
            onRefresh: _refresh,
            child: CustomScrollView(
              slivers: [
                // Points Balance Banner (Clean, Professional, Non-AI)
                SliverToBoxAdapter(
                  child: Container(
                    margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: _borderColor),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x080F172A),
                          blurRadius: 10,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Available Balance',
                              style: TextStyle(
                                color: _textMuted,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.baseline,
                              textBaseline: TextBaseline.alphabetic,
                              children: [
                                Text(
                                  currentPoints.toString().replaceAllMapped(
                                    RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
                                    (Match m) => '${m[1]},',
                                  ),
                                  style: const TextStyle(
                                    color: _textDark,
                                    fontSize: 24,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                const Text(
                                  'PTS',
                                  style: TextStyle(
                                    color: _primaryPink,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        OutlinedButton.icon(
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const MyCouponsPage()),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: _textDark,
                            side: const BorderSide(color: Color(0xFFE2E8F0)),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          icon: const Icon(Icons.confirmation_number_outlined, size: 14, color: _primaryPink),
                          label: const Text('My Coupons', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                        ),
                      ],
                    ),
                  ),
                ),

                // Category Filter Tabs
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: 48,
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      scrollDirection: Axis.horizontal,
                      itemCount: _filterTabs.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (context, index) {
                        final tab = _filterTabs[index];
                        final isSelected = _activeFilter == tab['key'];
                        return GestureDetector(
                          onTap: () => setState(() => _activeFilter = tab['key']!),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                            decoration: BoxDecoration(
                              color: isSelected ? _primaryPink : Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected ? _primaryPink : _borderColor,
                              ),
                              boxShadow: isSelected
                                  ? [
                                      BoxShadow(
                                        color: _primaryPink.withValues(alpha: 0.25),
                                        blurRadius: 6,
                                        offset: const Offset(0, 2),
                                      ),
                                    ]
                                  : null,
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              tab['label']!,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                color: isSelected ? Colors.white : _textMuted,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),

                // Section header
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _activeFilter == 'all'
                              ? 'Catalog Rewards'
                              : '${_filterTabs.firstWhere((t) => t['key'] == _activeFilter)['label']} Rewards',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: _textDark,
                          ),
                        ),
                        Text(
                          '${filtered.length} items',
                          style: const TextStyle(fontSize: 12, color: _textMuted, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ),

                // Empty State
                if (filtered.isEmpty)
                  SliverToBoxAdapter(
                    child: Container(
                      margin: const EdgeInsets.all(16),
                      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: _borderColor),
                      ),
                      child: const Column(
                        children: [
                          Icon(Icons.card_giftcard_rounded, size: 48, color: Color(0xFFCBD5E1)),
                          SizedBox(height: 12),
                          Text(
                            'No rewards in this category',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: _textDark),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Check another tab or visit again soon!',
                            style: TextStyle(fontSize: 12, color: _textMuted),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  // Grid matching the website 2-column RewardTile
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                    sliver: SliverGrid(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 0.67,
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final item = filtered[index];
                          final pointsReq = int.tryParse('${item['points_required']}') ?? 0;
                          final hasStock = item['stock'] == null || (int.tryParse('${item['stock']}') ?? 1) > 0;
                          final canRedeem = item['can_exchange'] == true && hasStock && currentPoints >= pointsReq;
                          final isBusy = _redeemingId == item['id'];
                          final type = item['type']?.toString() ?? 'voucher';
                          final imageUrl = _resolveImageUrl(item['reward_image_url'] ?? item['gift_product_image']);
                          final name = item['name']?.toString() ?? 'Reward';
                          final subtitle = item['gift_product_name']?.toString() ?? item['description']?.toString() ?? 'Redeem this reward';

                          return Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: _borderColor),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.03),
                                  blurRadius: 10,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                // Thumbnail
                                GestureDetector(
                                  onTap: () => _showRewardDetailSheet(item, currentPoints),
                                  child: Container(
                                    height: 110,
                                    decoration: BoxDecoration(
                                      color: _getTypeTone(type),
                                      borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
                                    ),
                                    child: imageUrl != null
                                        ? ClipRRect(
                                            borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
                                            child: Image.network(
                                              imageUrl,
                                              fit: BoxFit.contain,
                                              errorBuilder: (_, __, ___) => Center(
                                                child: Icon(_getTypeIcon(type), size: 40, color: _getTypeIconColor(type)),
                                              ),
                                            ),
                                          )
                                        : Center(
                                            child: Icon(_getTypeIcon(type), size: 40, color: _getTypeIconColor(type)),
                                          ),
                                  ),
                                ),

                                // Details
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.all(10),
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
                                          subtitle,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w500,
                                            color: _textMuted,
                                          ),
                                        ),
                                        const Spacer(),
                                        // Points pill
                                        Row(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.all(3),
                                              decoration: const BoxDecoration(
                                                color: Color(0xFFFBBF24),
                                                shape: BoxShape.circle,
                                              ),
                                              child: const Icon(Icons.star_rounded, size: 10, color: Colors.white),
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              '$pointsReq Pts',
                                              style: const TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w900,
                                                color: _textDark,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        // Redeem Button
                                        SizedBox(
                                          width: double.infinity,
                                          height: 32,
                                          child: FilledButton(
                                            onPressed: (!canRedeem || isBusy)
                                                ? null
                                                : () => _handleRedeem(item, currentPoints),
                                            style: FilledButton.styleFrom(
                                              backgroundColor: _primaryPink,
                                              disabledBackgroundColor: const Color(0xFFF1F5F9),
                                              disabledForegroundColor: const Color(0xFF94A3B8),
                                              padding: EdgeInsets.zero,
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                            ),
                                            child: isBusy
                                                ? const SizedBox(
                                                    width: 14,
                                                    height: 14,
                                                    child: CircularProgressIndicator(
                                                      strokeWidth: 2,
                                                      color: Colors.white,
                                                    ),
                                                  )
                                                : Text(
                                                    canRedeem
                                                        ? 'Redeem'
                                                        : (currentPoints < pointsReq
                                                            ? 'Need Pts'
                                                            : 'Unavailable'),
                                                    style: const TextStyle(
                                                      fontSize: 11,
                                                      fontWeight: FontWeight.w800,
                                                    ),
                                                  ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                        childCount: filtered.length,
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
