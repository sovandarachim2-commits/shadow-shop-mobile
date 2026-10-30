import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shadow_shop_mobile/state/shop_state.dart';
import 'package:shadow_shop_mobile/theme/app_theme.dart';
import 'package:shadow_shop_mobile/features/customer/orders/order_detail_screen.dart';

class OrdersView extends StatefulWidget {
  const OrdersView({super.key});

  @override
  State<OrdersView> createState() => _OrdersViewState();
}

class _OrdersViewState extends State<OrdersView> {
  late Future<List<Map<String, dynamic>>> _orders;
  bool _showCompleted = false;

  @override
  void initState() {
    super.initState();
    _orders = context.read<ShopState>().service.myOrders();
  }

  bool _isCompleted(Map<String, dynamic> order) {
    final status = '${order['status'] ?? ''}'.toLowerCase();
    return const {'completed', 'delivered', 'cancelled'}.contains(status);
  }

  @override
  Widget build(BuildContext context) =>
      FutureBuilder<List<Map<String, dynamic>>>(
        future: _orders,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(friendlyError(snapshot.error),
                    textAlign: TextAlign.center),
              ),
            );
          }

          final allOrders = snapshot.data ?? [];
          final orders = allOrders
              .where((order) => _isCompleted(order) == _showCompleted)
              .toList();

          return RefreshIndicator(
            onRefresh: () async {
              setState(
                  () => _orders = context.read<ShopState>().service.myOrders());
              await _orders;
            },
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 18, 16, 10),
                  sliver: SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('My Orders',
                            style: TextStyle(
                                fontSize: 25,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -.4)),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                              color: const Color(0xFFF0EFF1),
                              borderRadius: BorderRadius.circular(12)),
                          child: Row(children: [
                            _tabButton('Ongoing', false),
                            _tabButton('Completed', true),
                          ]),
                        ),
                      ],
                    ),
                  ),
                ),
                if (orders.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 14, 24, 30),
                      child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 76,
                              height: 76,
                              decoration: const BoxDecoration(
                                  color: Color(0xFFFFEDF4),
                                  shape: BoxShape.circle),
                              child: const Icon(Icons.receipt_long_rounded,
                                  color: brandColor, size: 34),
                            ),
                            const SizedBox(height: 14),
                            Text(
                                _showCompleted
                                    ? 'No completed orders yet'
                                    : 'No ongoing orders',
                                style: const TextStyle(
                                    fontSize: 17, fontWeight: FontWeight.w800)),
                            const SizedBox(height: 5),
                            Text(
                                _showCompleted
                                    ? 'Your completed orders will appear here.'
                                    : 'Your active orders will appear here.',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Colors.grey.shade600)),
                          ]),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                    sliver: SliverList.separated(
                      itemCount: orders.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final order = orders[index];
                        final status = '${order['status'] ?? 'New'}';
                        final normalized = status.toLowerCase();
                        final isDone = const {'completed', 'delivered'}
                            .contains(normalized);
                        final isCancelled = normalized == 'cancelled';
                        final statusColor = isCancelled
                            ? const Color(0xFFB42318)
                            : isDone
                                ? const Color(0xFF067647)
                                : brandColor;
                        final statusBackground = isCancelled
                            ? const Color(0xFFFEF3F2)
                            : isDone
                                ? const Color(0xFFECFDF3)
                                : const Color(0xFFFFEDF4);
                        return Card(
                          margin: EdgeInsets.zero,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: () => Navigator.of(context).push(
                                MaterialPageRoute(
                                    builder: (_) => OrderDetailScreen(
                                        orderId:
                                            int.tryParse('${order['id']}') ??
                                                0))),
                            child: Padding(
                              padding: const EdgeInsets.all(14),
                              child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(children: [
                                      Expanded(
                                          child: Text(
                                              'Order #${order['order_number'] ?? order['id']}',
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                  fontWeight: FontWeight.w800,
                                                  fontSize: 14))),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 10, vertical: 5),
                                        decoration: BoxDecoration(
                                            color: statusBackground,
                                            borderRadius:
                                                BorderRadius.circular(7)),
                                        child: Text(status,
                                            style: TextStyle(
                                                color: statusColor,
                                                fontSize: 11,
                                                fontWeight: FontWeight.w800)),
                                      ),
                                    ]),
                                    const SizedBox(height: 12),
                                    const Divider(height: 1),
                                    const SizedBox(height: 10),
                                    Row(children: [
                                      Icon(Icons.payment_rounded,
                                          size: 17,
                                          color: Colors.grey.shade600),
                                      const SizedBox(width: 6),
                                      Expanded(
                                          child: Text(
                                              'Payment: ${order['payment_status'] ?? 'unpaid'}',
                                              style: TextStyle(
                                                  color: Colors.grey.shade700,
                                                  fontSize: 12,
                                                  fontWeight:
                                                      FontWeight.w600))),
                                      Text(formatPrice(order['grand_total']),
                                          style: const TextStyle(
                                              color: brandColor,
                                              fontSize: 15,
                                              fontWeight: FontWeight.w900)),
                                    ]),
                                    const SizedBox(height: 10),
                                    Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.end,
                                        children: [
                                          Text('View order',
                                              style: TextStyle(
                                                  color: brandColor,
                                                  fontWeight: FontWeight.w800,
                                                  fontSize: 12)),
                                          const SizedBox(width: 4),
                                          const Icon(
                                              Icons.arrow_forward_rounded,
                                              color: brandColor,
                                              size: 16),
                                        ]),
                                  ]),
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
      );

  Widget _tabButton(String label, bool completed) {
    final selected = _showCompleted == completed;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _showCompleted = completed),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(vertical: 11),
          decoration: BoxDecoration(
              color: selected ? brandColor : Colors.transparent,
              borderRadius: BorderRadius.circular(9),
              boxShadow: selected
                  ? const [
                      BoxShadow(
                          color: Color(0x22EC2F83),
                          blurRadius: 8,
                          offset: Offset(0, 3))
                    ]
                  : null),
          child: Text(label,
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: selected ? Colors.white : const Color(0xFF667085),
                  fontSize: 13,
                  fontWeight: FontWeight.w800)),
        ),
      ),
    );
  }
}
