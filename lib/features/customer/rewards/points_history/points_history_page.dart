import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shadow_shop_mobile/state/shop_state.dart';
import 'package:shadow_shop_mobile/theme/app_theme.dart';

const Color _primaryPink = Color(0xFFEC4899);
const Color _cardBg = Colors.white;
const Color _textDark = Color(0xFF0F172A);
const Color _textMuted = Color(0xFF64748B);
const Color _borderColor = Color(0xFFF1F5F9);

class PointsHistoryPage extends StatefulWidget {
  const PointsHistoryPage({super.key});

  @override
  State<PointsHistoryPage> createState() => _PointsHistoryPageState();
}

class _PointsHistoryPageState extends State<PointsHistoryPage> {
  late Future<List<Map<String, dynamic>>> _history;
  String _filter = 'All';

  @override
  void initState() {
    super.initState();
    _history = _loadHistory();
  }

  Future<List<Map<String, dynamic>>> _loadHistory() {
    return context.read<ShopState>().service.pointsHistory();
  }

  String _formatDateTime(dynamic value) {
    if (value == null) return '';
    try {
      final dt = DateTime.parse('$value').toLocal();
      final now = DateTime.now();
      final isToday = dt.year == now.year && dt.month == now.month && dt.day == now.day;
      final isYesterday = dt.year == now.year && dt.month == now.month && dt.day == now.day - 1;

      final hour = dt.hour == 0 ? 12 : (dt.hour > 12 ? dt.hour - 12 : dt.hour);
      final amPm = dt.hour >= 12 ? 'PM' : 'AM';
      final minute = dt.minute.toString().padLeft(2, '0');
      final timeStr = '$hour:$minute $amPm';

      if (isToday) return 'Today · $timeStr';
      if (isYesterday) return 'Yesterday · $timeStr';

      const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      return '${months[dt.month - 1]} ${dt.day}, ${dt.year} · $timeStr';
    } catch (_) {
      return '$value';
    }
  }

  void _showTransactionDetails(Map<String, dynamic> row) {
    final points = int.tryParse('${row['points'] ?? row['amount'] ?? 0}') ?? 0;
    final isEarn = points >= 0;
    final note = row['description'] ?? row['note'] ?? row['reason'] ?? (isEarn ? 'Points Earned' : 'Reward Redemption');
    final dateStr = _formatDateTime(row['created_at'] ?? row['date']);
    final orderNum = row['order_number']?.toString();
    final activityType = row['type']?.toString() ?? (isEarn ? 'Points Earned' : 'Reward Redeemed');

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
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: isEarn ? const Color(0xFFECFDF5) : const Color(0xFFFDF2F8),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    isEarn ? Icons.add_circle_rounded : Icons.card_giftcard_rounded,
                    color: isEarn ? const Color(0xFF10B981) : _primaryPink,
                    size: 26,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isEarn ? '$note' : (note.toString().toLowerCase().contains('redeem') ? '$note' : 'Redeemed: $note'),
                        style: const TextStyle(
                          color: _textDark,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        dateStr,
                        style: const TextStyle(color: _textMuted, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                Text(
                  '${isEarn ? '+' : ''}$points pts',
                  style: TextStyle(
                    color: isEarn ? const Color(0xFF10B981) : _primaryPink,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Divider(height: 1, color: _borderColor),
            const SizedBox(height: 16),
            _buildDetailRow('Activity Type', activityType),
            const SizedBox(height: 10),
            _buildDetailRow('Timestamp', dateStr),
            if (orderNum != null && orderNum.isNotEmpty) ...[
              const SizedBox(height: 10),
              _buildDetailRow('Order Reference', '#$orderNum'),
            ],
            const SizedBox(height: 10),
            _buildDetailRow('Status', 'Completed', valueColor: const Color(0xFF10B981)),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 46,
              child: OutlinedButton(
                onPressed: () => Navigator.pop(ctx),
                style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
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
        title: const Text('Points History'),
        elevation: 0,
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _history,
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
                      onPressed: () => setState(() => _history = _loadHistory()),
                      child: const Text('Try Again'),
                    ),
                  ],
                ),
              ),
            );
          }

          final allRows = snapshot.data ?? [];
          var totalEarned = 0;
          var totalRedeemed = 0;

          for (final row in allRows) {
            final pts = int.tryParse('${row['points'] ?? row['amount'] ?? 0}') ?? 0;
            if (pts > 0) {
              totalEarned += pts;
            } else {
              totalRedeemed += pts.abs();
            }
          }

          final currentBalance = totalEarned - totalRedeemed;

          final filtered = allRows.where((row) {
            final pts = int.tryParse('${row['points'] ?? row['amount'] ?? 0}') ?? 0;
            if (_filter == 'Earned') return pts > 0;
            if (_filter == 'Redeemed') return pts < 0;
            return true;
          }).toList();

          return RefreshIndicator(
            color: _primaryPink,
            onRefresh: () async {
              setState(() => _history = _loadHistory());
              await _history;
            },
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 36),
              children: [
                // B. Points Summary Cards (Clean, Professional, Non-AI)
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
                    children: [
                      const Text(
                        'Points Balance',
                        style: TextStyle(
                          color: _textMuted,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            currentBalance.toString().replaceAllMapped(
                              RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
                              (Match m) => '${m[1]},',
                            ),
                            style: const TextStyle(
                              color: _textDark,
                              fontSize: 30,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Text(
                            'PTS',
                            style: TextStyle(
                              color: _primaryPink,
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: _borderColor),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            Column(
                              children: [
                                const Text(
                                  'Total Earned',
                                  style: TextStyle(color: _textMuted, fontSize: 11, fontWeight: FontWeight.w500),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '+$totalEarned',
                                  style: const TextStyle(
                                    color: Color(0xFF16A34A),
                                    fontSize: 13,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                            Container(width: 1, height: 24, color: _borderColor),
                            Column(
                              children: [
                                const Text(
                                  'Total Redeemed',
                                  style: TextStyle(color: _textMuted, fontSize: 11, fontWeight: FontWeight.w500),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '-$totalRedeemed',
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
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // C. Filter Tabs: All / Earned / Redeemed
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      _buildFilterTab('All', allRows.length),
                      _buildFilterTab('Earned', allRows.where((r) => (int.tryParse('${r['points'] ?? r['amount']}') ?? 0) > 0).length),
                      _buildFilterTab('Redeemed', allRows.where((r) => (int.tryParse('${r['points'] ?? r['amount']}') ?? 0) < 0).length),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // D. Transaction List
                if (filtered.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
                    decoration: BoxDecoration(
                      color: _cardBg,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: _borderColor),
                    ),
                    child: Column(
                      children: [
                        const Icon(Icons.history_toggle_off_rounded, size: 44, color: Color(0xFFCBD5E1)),
                        const SizedBox(height: 12),
                        Text(
                          _filter == 'Redeemed'
                              ? 'No reward redemptions yet'
                              : 'No $_filter transactions found',
                          style: const TextStyle(
                            color: _textDark,
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _filter == 'Redeemed'
                              ? 'When you exchange points for vouchers or gifts, they will appear here.'
                              : 'Transactions matching this filter will show up here.',
                          style: const TextStyle(color: _textMuted, fontSize: 12),
                          textAlign: TextAlign.center,
                        ),
                      ],
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
                          color: Colors.black.withValues(alpha: 0.025),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) => const Divider(
                        height: 1,
                        color: _borderColor,
                        indent: 64,
                      ),
                      itemBuilder: (context, index) {
                        final row = filtered[index];
                        final points = int.tryParse('${row['points'] ?? row['amount'] ?? 0}') ?? 0;
                        final isEarn = points >= 0;
                        final rawNote = row['description'] ?? row['note'] ?? row['reason'] ?? (isEarn ? 'Points activity' : 'Reward Redemption');
                        final displayNote = isEarn ? '$rawNote' : (rawNote.toString().toLowerCase().contains('redeem') ? '$rawNote' : 'Redeemed: $rawNote');
                        final dateStr = _formatDateTime(row['created_at'] ?? row['date']);

                        return Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () => _showTransactionDetails(row),
                            borderRadius: BorderRadius.circular(18),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                              child: Row(
                                children: [
                                  Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: isEarn ? const Color(0xFFECFDF5) : const Color(0xFFFDF2F8),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Icon(
                                      isEarn ? Icons.add_circle_rounded : Icons.card_giftcard_rounded,
                                      color: isEarn ? const Color(0xFF10B981) : _primaryPink,
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          displayNote,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            color: _textDark,
                                            fontSize: 13,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          dateStr,
                                          style: const TextStyle(color: _textMuted, fontSize: 11),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        '${isEarn ? '+' : ''}$points pts',
                                        style: TextStyle(
                                          color: isEarn ? const Color(0xFF10B981) : _primaryPink,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      const Icon(Icons.chevron_right_rounded, color: Color(0xFF94A3B8), size: 14),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
              ],
            ),
          );
        },
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
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: selected ? _primaryPink : _textMuted,
                  fontSize: 12,
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                ),
              ),
              const SizedBox(width: 5),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: selected ? const Color(0xFFFDF2F8) : const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$count',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: selected ? _primaryPink : _textMuted,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
