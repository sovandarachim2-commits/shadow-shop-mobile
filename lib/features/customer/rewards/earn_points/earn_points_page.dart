import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shadow_shop_mobile/features/customer/rewards/referral/referral_page.dart';
import 'package:shadow_shop_mobile/state/shop_state.dart';
import 'package:shadow_shop_mobile/theme/app_theme.dart';

const Color _primaryPink = Color(0xFFEC4899);
const Color _secondaryPurple = Color(0xFF7C3AED);
const Color _cardBg = Colors.white;
const Color _textDark = Color(0xFF0F172A);
const Color _textMuted = Color(0xFF64748B);
const Color _borderColor = Color(0xFFF1F5F9);

class EarnPointsPage extends StatefulWidget {
  const EarnPointsPage({super.key});

  @override
  State<EarnPointsPage> createState() => _EarnPointsPageState();
}

class _EarnPointsPageState extends State<EarnPointsPage> {
  late Future<Map<String, dynamic>> _summary;
  bool _checkingIn = false;

  @override
  void initState() {
    super.initState();
    _summary = _fetchSummary();
  }

  Future<Map<String, dynamic>> _fetchSummary() {
    return context.read<ShopState>().service.rewards();
  }

  Future<void> _checkIn() async {
    setState(() => _checkingIn = true);
    try {
      final result = await context.read<ShopState>().service.checkIn();
      if (!mounted) return;
      showStoreMessage(
        context,
        result['detail']?.toString() ?? 'Daily check-in complete! Points added.',
        icon: Icons.check_circle_rounded,
      );
      setState(() => _summary = _fetchSummary());
    } catch (error) {
      if (!mounted) return;
      showStoreMessage(
        context,
        friendlyError(error),
        icon: Icons.info_outline_rounded,
      );
    } finally {
      if (mounted) setState(() => _checkingIn = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Ways to Earn Points'),
        elevation: 0,
        actions: [
          FutureBuilder<Map<String, dynamic>>(
            future: _summary,
            builder: (context, snapshot) {
              final pts = int.tryParse('${snapshot.data?['current_points']}') ?? 0;
              return Container(
                margin: const EdgeInsets.only(right: 16),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFFDF2F8),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFFBCFE8)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.stars_rounded, color: _primaryPink, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      '$pts pts',
                      style: const TextStyle(
                        color: _primaryPink,
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
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
                      onPressed: () => setState(() => _summary = _fetchSummary()),
                      child: const Text('Try Again'),
                    ),
                  ],
                ),
              ),
            );
          }

          final data = snapshot.data ?? {};
          final rules = data['earning_rules'] is Map
              ? Map<String, dynamic>.from(data['earning_rules'])
              : <String, dynamic>{};
          final checkedInToday = data['checked_in_today'] == true;
          final checkinBonus = int.tryParse('${rules['daily_checkin_bonus']}') ?? 10;
          final pointsPerDollar = int.tryParse('${rules['points_per_dollar']}') ?? 10;
          final referralBonus = int.tryParse('${rules['referral_bonus']}') ?? 100;
          final reviewBonus = int.tryParse('${rules['review_bonus']}') ?? 20;
          final signupBonus = int.tryParse('${rules['signup_bonus']}') ?? 50;
          final birthdayBonus = int.tryParse('${rules['birthday_bonus']}') ?? 100;

          return RefreshIndicator(
            color: _primaryPink,
            onRefresh: () async {
              setState(() => _summary = _fetchSummary());
              await _summary;
            },
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 36),
              children: [
                // Highlight Banner (Clean, Professional, Non-AI)
                Container(
                  padding: const EdgeInsets.all(18),
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
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFDF2F8),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.auto_awesome_outlined, color: _primaryPink, size: 22),
                      ),
                      const SizedBox(width: 14),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Earn Points on Every Order',
                              style: TextStyle(
                                color: _textDark,
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            SizedBox(height: 3),
                            Text(
                              'Shop, review, and complete daily tasks to earn points for vouchers and exclusive gifts.',
                              style: TextStyle(
                                color: _textMuted,
                                fontSize: 11,
                                height: 1.35,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                const Text(
                  'Available Activities',
                  style: TextStyle(
                    color: _textDark,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 12),

                // 1. Daily Check-in Card
                _buildActivityCard(
                  icon: Icons.calendar_today_rounded,
                  iconColor: _primaryPink,
                  iconBg: const Color(0xFFFDF2F8),
                  title: 'Daily Check-in',
                  pointsTag: '+$checkinBonus pts',
                  description: 'Visit Shadow Shop every day and claim your daily check-in points bonus.',
                  actionWidget: SizedBox(
                    height: 36,
                    child: checkedInToday
                        ? Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFECFDF5),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: const Color(0xFFA7F3D0)),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 16),
                                SizedBox(width: 6),
                                Text(
                                  'Claimed Today',
                                  style: TextStyle(
                                    color: Color(0xFF059669),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : FilledButton.icon(
                            onPressed: _checkingIn ? null : _checkIn,
                            style: FilledButton.styleFrom(
                              backgroundColor: _primaryPink,
                              padding: const EdgeInsets.symmetric(horizontal: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            icon: const Icon(Icons.touch_app_rounded, size: 16),
                            label: Text(
                              _checkingIn ? 'Claiming…' : 'Claim Now',
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                            ),
                          ),
                  ),
                ),

                // 2. Shopping Rewards
                _buildActivityCard(
                  icon: Icons.shopping_bag_rounded,
                  iconColor: _secondaryPurple,
                  iconBg: const Color(0xFFF5F3FF),
                  title: 'Shopping Rewards',
                  pointsTag: '$pointsPerDollar pts / \$1',
                  description: 'Earn $pointsPerDollar points for every \$1 spent on eligible items. Points are awarded automatically when your order completes.',
                ),

                // 3. Refer a Friend
                _buildActivityCard(
                  icon: Icons.group_add_rounded,
                  iconColor: const Color(0xFF0284C7),
                  iconBg: const Color(0xFFF0F9FF),
                  title: 'Refer a Friend',
                  pointsTag: '+$referralBonus pts',
                  description: 'Share your referral code. Earn $referralBonus points when your invited friends sign up and make their first purchase.',
                  actionWidget: SizedBox(
                    height: 36,
                    child: OutlinedButton.icon(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const ReferralPage()),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF0284C7),
                        side: const BorderSide(color: Color(0xFFBAE6FD)),
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      icon: const Icon(Icons.share_rounded, size: 15),
                      label: const Text('Invite Friends', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                    ),
                  ),
                ),

                // 4. Product Reviews
                if (rules['review_bonus_enabled'] != false)
                  _buildActivityCard(
                    icon: Icons.rate_review_rounded,
                    iconColor: const Color(0xFFF59E0B),
                    iconBg: const Color(0xFFFFFBEB),
                    title: 'Leave Product Reviews',
                    pointsTag: '+$reviewBonus pts',
                    description: 'Help other shoppers by reviewing products you purchased and earn $reviewBonus loyalty points per approved review.',
                  ),

                // 5. Birthday Bonus
                if (rules['birthday_bonus_enabled'] != false)
                  _buildActivityCard(
                    icon: Icons.cake_rounded,
                    iconColor: const Color(0xFFE11D48),
                    iconBg: const Color(0xFFFFF1F2),
                    title: 'Birthday Gift',
                    pointsTag: '+$birthdayBonus pts',
                    description: 'Celebrate your birthday with Shadow Shop and receive a special bonus of $birthdayBonus points on your birthday month.',
                  ),

                // 6. Sign-up Bonus
                if (rules['signup_bonus_enabled'] != false)
                  _buildActivityCard(
                    icon: Icons.celebration_rounded,
                    iconColor: const Color(0xFF10B981),
                    iconBg: const Color(0xFFECFDF5),
                    title: 'Welcome Gift',
                    pointsTag: '+$signupBonus pts',
                    description: 'New members receive $signupBonus welcome points directly upon creating their customer account.',
                  ),

                const SizedBox(height: 12),
                // Helpful notice
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: const Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.info_outline_rounded, size: 18, color: _textMuted),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Points are credited after order completion or verification. You can check all historical points transactions at any time in Points History.',
                          style: TextStyle(color: _textMuted, fontSize: 11, height: 1.4),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildActivityCard({
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required String title,
    required String pointsTag,
    required String description,
    Widget? actionWidget,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.025),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: _textDark,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      pointsTag,
                      style: TextStyle(
                        color: iconColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            description,
            style: const TextStyle(
              color: _textMuted,
              fontSize: 12,
              height: 1.35,
            ),
          ),
          if (actionWidget != null) ...[
            const SizedBox(height: 12),
            actionWidget,
          ],
        ],
      ),
    );
  }
}
