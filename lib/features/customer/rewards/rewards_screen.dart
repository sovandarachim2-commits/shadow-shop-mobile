import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shadow_shop_mobile/config/app_config.dart';
import 'package:shadow_shop_mobile/features/customer/rewards/coupons/coupons_page.dart';
import 'package:shadow_shop_mobile/features/customer/rewards/earn_points/earn_points_page.dart';
import 'package:shadow_shop_mobile/features/customer/rewards/points_history/points_history_page.dart';
import 'package:shadow_shop_mobile/features/customer/rewards/redeem/redeem_page.dart';
import 'package:shadow_shop_mobile/state/shop_state.dart';
import 'package:shadow_shop_mobile/theme/app_theme.dart';

const Color _primaryPink = Color(0xFFEC4899);
const Color _cardBg = Colors.white;
const Color _textDark = Color(0xFF0F172A);
const Color _textMuted = Color(0xFF64748B);
const Color _borderColor = Color(0xFFF1F5F9);

class RewardsView extends StatefulWidget {
  const RewardsView({super.key});

  @override
  State<RewardsView> createState() => _RewardsViewState();
}

class _RewardsViewState extends State<RewardsView> {
  late Future<Map<String, dynamic>> _summary;
  bool _isCheckingIn = false;
  bool _isExchanging = false;
  final GlobalKey _redeemSectionKey = GlobalKey();

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


  Future<void> _checkIn() async {
    if (_isCheckingIn) return;
    setState(() => _isCheckingIn = true);
    try {
      final data = await context.read<ShopState>().service.checkIn();
      if (!mounted) return;
      setState(() {
        _summary = Future.value(data);
        _isCheckingIn = false;
      });
      showStoreMessage(
        context,
        'Daily check-in complete! Points added.',
        icon: Icons.check_circle_rounded,
      );
    } on DioException catch (error) {
      if (!mounted) return;
      setState(() => _isCheckingIn = false);
      showStoreMessage(
        context,
        friendlyError(error),
        icon: Icons.info_outline_rounded,
      );
    } catch (error) {
      if (!mounted) return;
      setState(() => _isCheckingIn = false);
      showStoreMessage(
        context,
        friendlyError(error),
        icon: Icons.info_outline_rounded,
      );
    }
  }

  Future<void> _confirmAndExchange(Map<String, dynamic> item) async {
    if (_isExchanging) return;
    final name = item['name']?.toString() ?? 'Reward';
    final pointsReq = int.tryParse('${item['points_required']}') ?? 0;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.card_giftcard_rounded, color: _primaryPink, size: 24),
            SizedBox(width: 8),
            Text('Redeem Reward', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
          ],
        ),
        content: Text(
          'Are you sure you want to redeem "$name" for $pointsReq points?',
          style: const TextStyle(color: _textDark, fontSize: 14),
        ),
        actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(false),
            child: const Text('Cancel', style: TextStyle(color: _textMuted, fontWeight: FontWeight.w600)),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogCtx).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: _primaryPink,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Confirm', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final rewardId = int.tryParse('${item['id']}') ?? 0;
      await _exchange(rewardId, name);
    }
  }

  Future<void> _exchange(int rewardId, String rewardName) async {
    setState(() => _isExchanging = true);
    try {
      final data = await context.read<ShopState>().service.exchangeReward(rewardId);
      if (!mounted) return;
      setState(() {
        _summary = Future.value(data);
        _isExchanging = false;
      });
      showStoreMessage(
        context,
        'Successfully redeemed $rewardName!',
        icon: Icons.check_circle_rounded,
      );
    } on DioException catch (error) {
      if (!mounted) return;
      setState(() => _isExchanging = false);
      showStoreMessage(
        context,
        friendlyError(error),
        icon: Icons.info_outline_rounded,
      );
    } catch (error) {
      if (!mounted) return;
      setState(() => _isExchanging = false);
      showStoreMessage(
        context,
        friendlyError(error),
        icon: Icons.info_outline_rounded,
      );
    }
  }

  String? _resolveImageUrl(dynamic rawUrl) {
    if (rawUrl == null) return null;
    final str = rawUrl.toString().trim();
    if (str.isEmpty) return null;
    if (str.startsWith('http://') || str.startsWith('https://')) return str;
    final base = AppConfig.apiBaseUrl.replaceFirst(RegExp(r'/api/?$'), '');
    return '$base${str.startsWith('/') ? '' : '/'}$str';
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

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _summary,
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
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline_rounded, size: 48, color: Color(0xFFEF4444)),
                  const SizedBox(height: 12),
                  Text(
                    friendlyError(snapshot.error),
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: _textDark, fontSize: 14),
                  ),
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    onPressed: _refresh,
                    icon: const Icon(Icons.refresh_rounded, size: 18),
                    label: const Text('Try Again'),
                  ),
                ],
              ),
            ),
          );
        }

        final data = snapshot.data ?? {};
        final catalog = (data['catalog'] as List? ?? const [])
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
        final rules = data['earning_rules'] is Map
            ? Map<String, dynamic>.from(data['earning_rules'])
            : <String, dynamic>{};
        final points = int.tryParse('${data['current_points']}') ?? 0;
        final memberLevel = (data['member_level'] ?? 'Member').toString();
        final nextTierPoints = int.tryParse('${data['next_tier_points']}') ?? 0;
        final pointsToNext = int.tryParse('${data['points_to_next_level']}') ?? 0;
        final progressPct = (int.tryParse('${data['progress_pct']}') ?? 0).clamp(0, 100);
        final checkedInToday = data['checked_in_today'] == true;
        final dailyCheckinEnabled = rules['daily_checkin_enabled'] != false;
        final dailyBonus = int.tryParse('${rules['daily_checkin_bonus']}') ?? 10;
        final transactions = (data['transactions'] as List? ?? const [])
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList();

        return RefreshIndicator(
          color: _primaryPink,
          onRefresh: _refresh,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
            children: [
              _buildSummaryCard(
                points: points,
                memberLevel: memberLevel,
                nextTierPoints: nextTierPoints,
                pointsToNext: pointsToNext,
                progressPct: progressPct,
              ),
              const SizedBox(height: 16),
              _buildRewardsMenu(),
              const SizedBox(height: 16),
              _buildDailyCheckInCard(
                checkedInToday: checkedInToday,
                enabled: dailyCheckinEnabled,
                bonus: dailyBonus,
              ),
              const SizedBox(height: 20),
              _buildRedeemSection(catalog: catalog, currentPoints: points),
              const SizedBox(height: 20),
              _buildRecentPointsSection(transactions: transactions),
            ],
          ),
        );
      },
    );
  }

  // --- COMPONENT B: REWARDS SUMMARY CARD ---
  Widget _buildSummaryCard({
    required int points,
    required String memberLevel,
    required int nextTierPoints,
    required int pointsToNext,
    required int progressPct,
  }) {
    final String currentTier = memberLevel.trim().isEmpty ? 'Silver' : memberLevel;
    final String nextTier = currentTier.toLowerCase() == 'silver'
        ? 'Gold'
        : (currentTier.toLowerCase() == 'gold' ? 'Platinum' : 'Top Tier');

    final bool isGold = currentTier.toLowerCase() == 'gold';
    final bool isPlatinum = currentTier.toLowerCase() == 'platinum';

    final Color tierAccentColor = isPlatinum
        ? const Color(0xFF0284C7)
        : (isGold ? const Color(0xFFD97706) : const Color(0xFF64748B));

    final Color tierBgColor = isPlatinum
        ? const Color(0xFFF0F9FF)
        : (isGold ? const Color(0xFFFFFBEB) : const Color(0xFFF8FAFC));

    final Color tierBorderColor = isPlatinum
        ? const Color(0xFFBAE6FD)
        : (isGold ? const Color(0xFFFDE68A) : const Color(0xFFE2E8F0));

    final Color tierTextColor = isPlatinum
        ? const Color(0xFF0369A1)
        : (isGold ? const Color(0xFF92400E) : const Color(0xFF334155));

    final IconData tierIcon = isPlatinum
        ? Icons.diamond_outlined
        : (isGold ? Icons.workspace_premium_rounded : Icons.shield_outlined);


    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A0F172A),
            blurRadius: 12,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Label & 3. Membership / Gift Icon
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Text(
                'Shadow Shop Rewards',
                style: TextStyle(
                  color: _textMuted,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.2,
                ),
              ),
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: const Color(0xFFFDF2F8),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.card_giftcard_outlined,
                  size: 17,
                  color: _primaryPink,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // 2. Large points balance with PTS
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                points.toString().replaceAllMapped(
                  RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
                  (Match m) => '${m[1]},',
                ),
                style: const TextStyle(
                  color: _textDark,
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                  height: 1.1,
                ),
              ),
              const SizedBox(width: 6),
              const Text(
                'PTS',
                style: TextStyle(
                  color: _primaryPink,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // 4. Current membership tier with distinctive badge & 5. Next membership tier
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: tierBgColor,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: tierBorderColor),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      tierIcon,
                      size: 14,
                      color: tierAccentColor,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      '$currentTier Tier',
                      style: TextStyle(
                        color: tierTextColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    nextTier == 'Top Tier' ? 'Highest Tier' : 'Next: $nextTier',
                    style: const TextStyle(
                      color: _textMuted,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (nextTier != 'Top Tier') ...[
                    const SizedBox(width: 4),
                    Icon(
                      nextTier.toLowerCase() == 'gold' ? Icons.workspace_premium_outlined : Icons.diamond_outlined,
                      size: 13,
                      color: nextTier.toLowerCase() == 'gold' ? const Color(0xFFD97706) : const Color(0xFF0284C7),
                    ),
                  ],
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),

          // 6. Thin progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: (progressPct / 100.0).clamp(0.0, 1.0),
              minHeight: 4,
              backgroundColor: const Color(0xFFF1F5F9),
              valueColor: const AlwaysStoppedAnimation<Color>(_primaryPink),
            ),
          ),
          const SizedBox(height: 8),

          // 7. Points remaining to reach the next tier
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                pointsToNext > 0
                    ? '$pointsToNext pts to reach $nextTier'
                    : 'You have achieved maximum tier status',
                style: const TextStyle(
                  color: _textMuted,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                '$progressPct%',
                style: const TextStyle(
                  color: _textDark,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- COMPONENT C: REWARDS MENU (Matching website quickActions) ---
  Widget _buildRewardsMenu() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildMenuCard(
                title: 'Earn Points',
                subtitle: 'See how to earn',
                icon: Icons.star_rounded,
                iconColor: _primaryPink,
                iconBg: const Color(0xFFFDF2F8),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const EarnPointsPage()),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildMenuCard(
                title: 'Redeem Points',
                subtitle: 'Use your points',
                icon: Icons.card_giftcard_rounded,
                iconColor: _primaryPink,
                iconBg: const Color(0xFFFDF2F8),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const RedeemRewardsPage()),
                ).then((_) => _refresh()),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _buildMenuCard(
                title: 'My Coupons',
                subtitle: 'View your coupons',
                icon: Icons.confirmation_number_outlined,
                iconColor: _primaryPink,
                iconBg: const Color(0xFFFDF2F8),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const MyCouponsPage()),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildMenuCard(
                title: 'Point History',
                subtitle: 'View your activity',
                icon: Icons.history_rounded,
                iconColor: _primaryPink,
                iconBg: const Color(0xFFFDF2F8),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const PointsHistoryPage()),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMenuCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          decoration: BoxDecoration(
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
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor, size: 22),
              ),
              const SizedBox(height: 8),
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: _textDark,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: _textMuted,
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- COMPONENT D: DAILY CHECK-IN ---
  Widget _buildDailyCheckInCard({
    required bool checkedInToday,
    required bool enabled,
    required int bonus,
  }) {
    return Container(
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
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Minimal Calendar / Gift icon
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: checkedInToday ? const Color(0xFFF0FDF4) : const Color(0xFFFDF2F8),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: checkedInToday ? const Color(0xFFDCFCE7) : const Color(0xFFFCE7F3),
              ),
            ),
            child: Icon(
              checkedInToday ? Icons.check_circle_outline_rounded : Icons.calendar_today_outlined,
              size: 20,
              color: checkedInToday ? const Color(0xFF16A34A) : _primaryPink,
            ),
          ),
          const SizedBox(width: 12),

          // Title & Status
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    const Text(
                      'Daily Check-in',
                      style: TextStyle(
                        color: _textDark,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFFBEB),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: const Color(0xFFFEF3C7)),
                      ),
                      child: Text(
                        '+$bonus PTS',
                        style: const TextStyle(
                          color: Color(0xFFD97706),
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  checkedInToday
                      ? 'Already claimed today'
                      : 'Claim +$bonus bonus points',
                  style: const TextStyle(
                    color: _textMuted,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),

          // Action Button: Clean, responsive "Claim" button
          SizedBox(
            height: 36,
            child: checkedInToday
                ? Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check_rounded, color: Color(0xFF64748B), size: 14),
                        SizedBox(width: 4),
                        Text(
                          'Claimed',
                          style: TextStyle(
                            color: Color(0xFF64748B),
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  )
                : FilledButton(
                    onPressed: (_isCheckingIn || !enabled) ? null : _checkIn,
                    style: FilledButton.styleFrom(
                      backgroundColor: _primaryPink,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: _isCheckingIn
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'Claim',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                  ),
          ),
        ],
      ),
    );
  }

  // --- COMPONENT E: REDEEM REWARDS SECTION ---
  Widget _buildRedeemSection({
    required List<Map<String, dynamic>> catalog,
    required int currentPoints,
  }) {
    return Container(
      key: _redeemSectionKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Redeem Rewards',
                style: TextStyle(
                  color: _textDark,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              if (catalog.isNotEmpty)
                GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const RedeemRewardsPage()),
                  ).then((_) => _refresh()),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'View All',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: _primaryPink,
                        ),
                      ),
                      SizedBox(width: 2),
                      Icon(Icons.chevron_right_rounded, size: 16, color: _primaryPink),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (catalog.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
              decoration: BoxDecoration(
                color: _cardBg,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: _borderColor),
              ),
              child: const Column(
                children: [
                  Icon(Icons.card_giftcard_rounded, size: 48, color: Color(0xFFCBD5E1)),
                  SizedBox(height: 12),
                  Text(
                    'No rewards available right now',
                    style: TextStyle(
                      color: _textDark,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Check back later for exclusive vouchers and gifts.',
                    style: TextStyle(color: _textMuted, fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
          else
            ...catalog.map((item) => _buildRewardCard(item, currentPoints)),
        ],
      ),
    );
  }

  Widget _buildRewardCard(Map<String, dynamic> item, int currentPoints) {
    final pointsReq = int.tryParse('${item['points_required']}') ?? 0;
    final canExchange = item['can_exchange'] == true && currentPoints >= pointsReq;
    final name = item['name']?.toString() ?? 'Reward';
    final description = item['description']?.toString() ?? item['type_label']?.toString() ?? '';
    final typeLabel = item['type_label']?.toString() ?? '';
    final imageUrl = _resolveImageUrl(item['reward_image_url'] ?? item['gift_product_image']);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Reward image / icon thumbnail
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Container(
              width: 68,
              height: 68,
              color: const Color(0xFFFDF2F8),
              child: imageUrl != null && imageUrl.isNotEmpty
                  ? Image.network(
                      imageUrl,
                      width: 68,
                      height: 68,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Center(
                        child: Icon(Icons.card_giftcard_rounded, color: _primaryPink, size: 28),
                      ),
                    )
                  : const Center(
                      child: Icon(Icons.card_giftcard_rounded, color: _primaryPink, size: 28),
                    ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (typeLabel.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(bottom: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Text(
                      typeLabel,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: _textMuted,
                      ),
                    ),
                  ),
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _textDark,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (description.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    description,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: _textMuted, fontSize: 11),
                  ),
                ],
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.stars_rounded, size: 16, color: _primaryPink),
                    const SizedBox(width: 4),
                    Text(
                      '$pointsReq pts',
                      style: const TextStyle(
                        color: _primaryPink,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            height: 38,
            child: FilledButton(
              onPressed: canExchange ? () => _confirmAndExchange(item) : null,
              style: FilledButton.styleFrom(
                backgroundColor: _primaryPink,
                disabledBackgroundColor: const Color(0xFFF1F5F9),
                padding: const EdgeInsets.symmetric(horizontal: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(
                canExchange ? 'Redeem' : 'Locked',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: canExchange ? Colors.white : const Color(0xFF94A3B8),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- COMPONENT F: RECENT POINTS TRANSACTION HISTORY ---
  Widget _buildRecentPointsSection({
    required List<Map<String, dynamic>> transactions,
  }) {
    final recentList = transactions.take(6).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Recent Points',
              style: TextStyle(
                color: _textDark,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            TextButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const PointsHistoryPage()),
              ),
              style: TextButton.styleFrom(foregroundColor: _primaryPink),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('View All', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                  SizedBox(width: 2),
                  Icon(Icons.arrow_forward_ios_rounded, size: 12),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (recentList.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
            decoration: BoxDecoration(
              color: _cardBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _borderColor),
            ),
            child: const Center(
              child: Text(
                'No points transactions yet.',
                style: TextStyle(color: _textMuted, fontSize: 13),
              ),
            ),
          )
        else
          Container(
            decoration: BoxDecoration(
              color: _cardBg,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: _borderColor),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: recentList.length,
              separatorBuilder: (_, __) => const Divider(
                height: 1,
                thickness: 1,
                color: _borderColor,
                indent: 60,
              ),
              itemBuilder: (context, index) {
                final item = recentList[index];
                final delta = int.tryParse('${item['points'] ?? item['amount'] ?? 0}') ?? 0;
                final isPositive = delta > 0;
                final isNegative = delta < 0;
                final rawNote = item['note']?.toString() ??
                    item['description'] ??
                    item['type']?.toString() ??
                    (isPositive ? 'Points activity' : 'Reward Redemption');
                final note = isPositive ? '$rawNote' : (rawNote.toString().toLowerCase().contains('redeem') ? '$rawNote' : 'Redeemed: $rawNote');
                final dateStr = _formatDate(item['created_at'] ?? item['date']);

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  child: Row(
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: isPositive
                              ? const Color(0xFFECFDF5)
                              : (isNegative ? const Color(0xFFFDF2F8) : const Color(0xFFF1F5F9)),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isPositive
                              ? Icons.add_rounded
                              : (isNegative ? Icons.card_giftcard_rounded : Icons.swap_horiz_rounded),
                          color: isPositive
                              ? const Color(0xFF10B981)
                              : (isNegative ? _primaryPink : const Color(0xFF64748B)),
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              note,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: _textDark,
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            if (dateStr.isNotEmpty) ...[
                              const SizedBox(height: 2),
                              Text(
                                dateStr,
                                style: const TextStyle(color: _textMuted, fontSize: 11),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${isPositive ? '+' : ''}$delta pts',
                        style: TextStyle(
                          color: isPositive
                              ? const Color(0xFF10B981)
                              : (isNegative ? _primaryPink : _textMuted),
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}
