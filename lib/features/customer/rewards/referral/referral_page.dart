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
      await context.read<ShopState>().updateProfile({'friend_referral_code': code});
      if (!mounted) return;
      showStoreMessage(
        context,
        'Referral code applied successfully!',
        icon: Icons.check_circle_rounded,
      );
      _friendCode.clear();
    } catch (error) {
      if (!mounted) return;
      showStoreMessage(
        context,
        friendlyError(error),
        icon: Icons.info_outline_rounded,
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _copyToClipboard(String text, String message) {
    Clipboard.setData(ClipboardData(text: text));
    showStoreMessage(
      context,
      message,
      icon: Icons.copy_rounded,
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<ShopState>().user ?? {};
    final referralCode = '${user['referral_code'] ?? '—'}';
    final hasReferredBy = user['referred_by_code'] != null && '${user['referred_by_code']}'.isNotEmpty;
    final totalInvited = int.tryParse('${user['referrals_count']}') ?? 0;
    final successfulReferrals = int.tryParse('${user['successful_referrals_count']}') ?? 0;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Refer a Friend'),
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
        children: [
          // A. Referral Hero Summary Card (Clean, Professional, Non-AI)
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Referral Program',
                      style: TextStyle(
                        color: _textMuted,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFDF2F8),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.group_add_outlined, color: _primaryPink, size: 17),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'Invite Friends, Earn Rewards',
                  style: TextStyle(
                    color: _textDark,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Share your referral code. Both you and your friend will receive loyalty points when they make their first purchase.',
                  style: TextStyle(
                    color: _textMuted,
                    fontSize: 12,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _borderColor),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatColumn('Invited', '$totalInvited'),
                      Container(height: 24, width: 1, color: _borderColor),
                      _buildStatColumn('Successful', '$successfulReferrals'),
                      Container(height: 24, width: 1, color: _borderColor),
                      _buildStatColumn('Status', 'Active'),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // B. Your Unique Referral Code
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: _cardBg,
              borderRadius: BorderRadius.circular(20),
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
                const Text(
                  'Your Referral Code',
                  style: TextStyle(
                    color: _textDark,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Tap code or button to copy to your clipboard.',
                  style: TextStyle(color: _textMuted, fontSize: 12),
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFDF2F8),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFFBCFE8)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          referralCode,
                          style: const TextStyle(
                            color: _primaryPink,
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 2,
                          ),
                        ),
                      ),
                      IconButton.filledTonal(
                        onPressed: referralCode == '—'
                            ? null
                            : () => _copyToClipboard(referralCode, 'Referral code copied!'),
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: _primaryPink,
                        ),
                        icon: const Icon(Icons.copy_rounded, size: 18),
                        tooltip: 'Copy Code',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: FilledButton.icon(
                    onPressed: referralCode == '—'
                        ? null
                        : () {
                            final shareMessage =
                                'Join me on Shadow Shop! Use my referral code "$referralCode" to get bonus loyalty points on your orders.';
                            _copyToClipboard(shareMessage, 'Invitation message copied to clipboard!');
                          },
                    style: FilledButton.styleFrom(
                      backgroundColor: _primaryPink,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: const Icon(Icons.share_rounded, size: 18),
                    label: const Text(
                      'Copy Invitation Message',
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // C. How It Works
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: _cardBg,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _borderColor),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'How It Works',
                  style: TextStyle(
                    color: _textDark,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 14),
                _buildStep(
                  step: '1',
                  title: 'Share your code',
                  description: 'Send your referral code or invitation link to friends and family.',
                ),
                const SizedBox(height: 12),
                _buildStep(
                  step: '2',
                  title: 'Friend joins',
                  description: 'Your friend registers an account and enters your code.',
                ),
                const SizedBox(height: 12),
                _buildStep(
                  step: '3',
                  title: 'Earn rewards',
                  description: 'Both of you receive reward points when they place their first order!',
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // D. Enter a Friend's Code
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: _cardBg,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _borderColor),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Have a Friend’s Code?',
                  style: TextStyle(
                    color: _textDark,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  hasReferredBy
                      ? 'You joined using referral code: ${user['referred_by_code']}'
                      : 'Enter a friend\'s referral code below to link your account.',
                  style: const TextStyle(color: _textMuted, fontSize: 12),
                ),
                if (!hasReferredBy) ...[
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _friendCode,
                          textCapitalization: TextCapitalization.characters,
                          decoration: InputDecoration(
                            hintText: 'e.g. FRIEND20',
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Color(0xFFD0D5DD)),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      FilledButton(
                        onPressed: _saving ? null : _applyCode,
                        style: FilledButton.styleFrom(
                          backgroundColor: _primaryPink,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
                        ),
                        child: Text(
                          _saving ? 'Applying…' : 'Apply',
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatColumn(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.8),
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildStep({
    required String step,
    required String title,
    required String description,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 26,
          height: 26,
          decoration: const BoxDecoration(
            color: Color(0xFFFDF2F8),
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Text(
            step,
            style: const TextStyle(
              color: _primaryPink,
              fontWeight: FontWeight.w900,
              fontSize: 12,
            ),
          ),
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
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                description,
                style: const TextStyle(color: _textMuted, fontSize: 11, height: 1.3),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
