import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shadow_shop_mobile/state/shop_state.dart';
import 'package:shadow_shop_mobile/theme/app_theme.dart';
import 'package:shadow_shop_mobile/features/customer/rewards/referral/referral_page.dart';
import 'package:shadow_shop_mobile/features/customer/rewards/points_history/points_history_page.dart';
import 'package:shadow_shop_mobile/features/customer/rewards/coupons/coupons_page.dart';
import 'package:shadow_shop_mobile/features/customer/rewards/earn_points/earn_points_page.dart';

class RewardsView extends StatefulWidget {
  const RewardsView({super.key});
  @override
  State<RewardsView> createState() => _RewardsViewState();
}

class _RewardsViewState extends State<RewardsView> {
  late Future<Map<String, dynamic>> _summary;
  @override
  void initState() {
    super.initState();
    _summary = context.read<ShopState>().service.rewards();
  }

  Future<void> _checkIn() async {
    try {
      final data = await context.read<ShopState>().service.checkIn();
      if (!mounted) return;
      setState(() => _summary = Future.value(data));
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Daily check-in complete.')));
    } on DioException catch (error) {
      if (mounted)
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(friendlyError(error))));
    }
  }

  Future<void> _exchange(int id) async {
    try {
      final data = await context.read<ShopState>().service.exchangeReward(id);
      if (mounted) setState(() => _summary = Future.value(data));
    } on DioException catch (error) {
      if (mounted)
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(friendlyError(error))));
    }
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<Map<String, dynamic>>(
        future: _summary,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting)
            return const Center(child: CircularProgressIndicator());
          if (snapshot.hasError)
            return Center(
                child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(friendlyError(snapshot.error),
                        textAlign: TextAlign.center)));
          final data = snapshot.data ?? {};
          final catalog = data['catalog'] as List? ?? const [];
          final rules = data['earning_rules'] is Map
              ? Map<String, dynamic>.from(data['earning_rules'])
              : <String, dynamic>{};
          final points = int.tryParse('${data['current_points']}') ?? 0;
          return RefreshIndicator(
              onRefresh: () async => setState(
                  () => _summary = context.read<ShopState>().service.rewards()),
              child: ListView(padding: const EdgeInsets.all(16), children: [
                Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                        gradient: const LinearGradient(
                            colors: [Color(0xFF822B48), Color(0xFFCC5B71)]),
                        borderRadius: BorderRadius.circular(22)),
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('YOUR REWARDS',
                              style: TextStyle(
                                  color: Colors.white70, letterSpacing: 1)),
                          const SizedBox(height: 8),
                          Text('$points points',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 30,
                                  fontWeight: FontWeight.w800)),
                          const SizedBox(height: 4),
                          Text(
                              '${data['member_level'] ?? 'Member'} · ${data['points_to_next_level'] ?? 0} points to next tier',
                              style: const TextStyle(color: Colors.white))
                        ])),
                const SizedBox(height: 10),
                Card(
                    child: Column(children: [
                  ListTile(
                      leading: const Icon(Icons.auto_awesome_outlined,
                          color: brandColor),
                      title: const Text('Ways to earn points'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const EarnPointsPage()))),
                  ListTile(
                      leading:
                          const Icon(Icons.people_outline, color: brandColor),
                      title: const Text('Refer a friend'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const ReferralPage()))),
                  ListTile(
                      leading: const Icon(Icons.history, color: brandColor),
                      title: const Text('Points history'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const PointsHistoryPage()))),
                  ListTile(
                      leading: const Icon(Icons.confirmation_number_outlined,
                          color: brandColor),
                      title: const Text('My coupons'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const MyCouponsPage()))),
                ])),
                const SizedBox(height: 12),
                Card(
                    child: ListTile(
                        leading: const CircleAvatar(
                            child: Icon(Icons.calendar_month)),
                        title: Text(data['checked_in_today'] == true
                            ? 'You checked in today'
                            : 'Daily check-in'),
                        subtitle: Text(
                            'Earn ${rules['daily_checkin_bonus'] ?? 0} points'),
                        trailing: FilledButton(
                            onPressed: data['checked_in_today'] == true ||
                                    rules['daily_checkin_enabled'] != true
                                ? null
                                : _checkIn,
                            child: const Text('Check in')))),
                const Padding(
                    padding: EdgeInsets.fromLTRB(4, 18, 4, 8),
                    child: Text('Redeem rewards',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold))),
                if (catalog.isEmpty)
                  const Card(
                      child: Padding(
                          padding: EdgeInsets.all(18),
                          child: Text('No rewards are available right now.'))),
                for (final raw in catalog) ...[
                  Builder(builder: (context) {
                    final item = Map<String, dynamic>.from(raw as Map);
                    final can = item['can_exchange'] == true;
                    return Card(
                        child: ListTile(
                            leading: const CircleAvatar(
                                backgroundColor: Color(0xFFFCE7E8),
                                child: Icon(Icons.card_giftcard,
                                    color: brandColor)),
                            title: Text(item['name']?.toString() ?? 'Reward'),
                            subtitle: Text(
                                '${item['points_required'] ?? 0} points · ${item['description'] ?? item['type_label'] ?? ''}'),
                            trailing: FilledButton.tonal(
                                onPressed: can
                                    ? () => _exchange(
                                        int.tryParse('${item['id']}') ?? 0)
                                    : null,
                                child: Text(can ? 'Redeem' : 'Locked'))));
                  }),
                ],
                const Padding(
                    padding: EdgeInsets.fromLTRB(4, 18, 4, 8),
                    child: Text('Recent points',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold))),
                for (final raw
                    in (data['transactions'] as List? ?? const []).take(8))
                  Builder(builder: (context) {
                    final item = Map<String, dynamic>.from(raw as Map);
                    final delta = int.tryParse('${item['points']}') ?? 0;
                    return ListTile(
                        dense: true,
                        leading: Icon(
                            delta >= 0
                                ? Icons.add_circle_outline
                                : Icons.remove_circle_outline,
                            color: delta >= 0 ? Colors.green : Colors.red),
                        title: Text(item['note']?.toString() ??
                            item['type']?.toString() ??
                            'Points'),
                        trailing: Text('${delta > 0 ? '+' : ''}$delta'));
                  }),
              ]));
        },
      );
}
