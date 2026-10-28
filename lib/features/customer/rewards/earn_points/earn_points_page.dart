import 'package:flutter/material.dart';
import 'package:shadow_shop_mobile/theme/app_theme.dart';
import 'package:provider/provider.dart';
import 'package:shadow_shop_mobile/state/shop_state.dart';

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
    _summary = context.read<ShopState>().service.rewards();
  }

  Future<void> _checkIn() async {
    setState(() => _checkingIn = true);
    try {
      final result = await context.read<ShopState>().service.checkIn();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('${result['detail'] ?? 'Check-in complete'}')));
        setState(() => _summary = context.read<ShopState>().service.rewards());
      }
    } catch (error) {
      if (mounted)
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error.toString())));
    } finally {
      if (mounted) setState(() => _checkingIn = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Earn points')),
        body: FutureBuilder<Map<String, dynamic>>(
            future: _summary,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting)
                return const Center(child: CircularProgressIndicator());
              if (snapshot.hasError)
                return Center(child: Text(snapshot.error.toString()));
              final data = snapshot.data ?? {};
              final rules = data['earning_rules'] is Map
                  ? Map<String, dynamic>.from(data['earning_rules'])
                  : <String, dynamic>{};
              return ListView(padding: const EdgeInsets.all(16), children: [
                Card(
                    child: Padding(
                        padding: const EdgeInsets.all(18),
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Daily check-in',
                                  style: TextStyle(
                                      fontSize: 19,
                                      fontWeight: FontWeight.bold)),
                              const SizedBox(height: 6),
                              const Text(
                                  'Come back each day to collect available points.'),
                              const SizedBox(height: 12),
                              FilledButton.icon(
                                  onPressed: _checkingIn ? null : _checkIn,
                                  icon: const Icon(Icons.calendar_month),
                                  label: Text(_checkingIn
                                      ? 'Checking in…'
                                      : 'Check in today')),
                            ]))),
                const Padding(
                    padding: EdgeInsets.fromLTRB(4, 16, 4, 8),
                    child: Text('Ways to earn',
                        style: TextStyle(
                            fontSize: 19, fontWeight: FontWeight.bold))),
                if (rules.isEmpty)
                  const Card(
                      child: ListTile(
                          title: Text(
                              'Points are earned through eligible purchases and promotions.'))),
                for (final entry in rules.entries)
                  Card(
                      child: ListTile(
                          leading: const Icon(Icons.stars_outlined,
                              color: brandColor),
                          title: Text(entry.key.replaceAll('_', ' ')),
                          trailing: Text('${entry.value}'))),
              ]);
            }),
      );
}
