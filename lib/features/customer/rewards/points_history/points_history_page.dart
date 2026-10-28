import 'package:flutter/material.dart';
import 'package:shadow_shop_mobile/theme/app_theme.dart';
import 'package:provider/provider.dart';
import 'package:shadow_shop_mobile/state/shop_state.dart';

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
    _history = context.read<ShopState>().service.pointsHistory();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Points history')),
        body: FutureBuilder<List<Map<String, dynamic>>>(
            future: _history,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting)
                return const Center(child: CircularProgressIndicator());
              if (snapshot.hasError)
                return Center(child: Text(snapshot.error.toString()));
              final rows = snapshot.data ?? [];
              final filtered = rows.where((row) {
                final points =
                    int.tryParse('${row['points'] ?? row['amount'] ?? 0}') ?? 0;
                return _filter == 'All' ||
                    (_filter == 'Earned' && points > 0) ||
                    (_filter == 'Used' && points < 0);
              }).toList();
              return Column(children: [
                Padding(
                    padding: const EdgeInsets.all(12),
                    child: SegmentedButton<String>(
                        segments: const [
                          ButtonSegment(value: 'All', label: Text('All')),
                          ButtonSegment(value: 'Earned', label: Text('Earned')),
                          ButtonSegment(value: 'Used', label: Text('Used'))
                        ],
                        selected: {
                          _filter
                        },
                        onSelectionChanged: (value) =>
                            setState(() => _filter = value.first))),
                Expanded(
                    child: filtered.isEmpty
                        ? const Center(child: Text('No points activity yet.'))
                        : ListView.builder(
                            itemCount: filtered.length,
                            itemBuilder: (context, index) {
                              final row = filtered[index];
                              final points = int.tryParse(
                                      '${row['points'] ?? row['amount'] ?? 0}') ??
                                  0;
                              return ListTile(
                                  leading: CircleAvatar(
                                      child: Icon(points >= 0
                                          ? Icons.add
                                          : Icons.remove)),
                                  title: Text(
                                      '${row['description'] ?? row['reason'] ?? 'Points activity'}'),
                                  subtitle: Text(
                                      '${row['created_at'] ?? row['date'] ?? ''}'),
                                  trailing: Text(
                                      '${points > 0 ? '+' : ''}$points pts',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: points >= 0
                                              ? Colors.green
                                              : brandColor)));
                            })),
              ]);
            }),
      );
}
