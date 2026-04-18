import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../app.dart';
import '../../providers/order_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/order.dart';

class OrdersScreen extends StatelessWidget {
  const OrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final orders = context.watch<OrderProvider>();

    return RefreshIndicator(
      color: kOrange,
      onRefresh: orders.fetchOrders,
      child: orders.orders.isEmpty
          ? ListView(
              children: [
                SizedBox(height: MediaQuery.of(context).size.height * 0.25),
                Center(
                  child: Container(
                    margin: const EdgeInsets.all(24),
                    padding: const EdgeInsets.all(40),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.receipt_long_outlined,
                            size: 64, color: Colors.grey.shade300),
                        const SizedBox(height: 12),
                        const Text('No orders yet',
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        const Text('Place an order from the menu',
                            style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                  ),
                ),
              ],
            )
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: orders.orders.length,
              itemBuilder: (ctx, i) =>
                  _OrderCard(order: orders.orders[i]),
            ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  final Order order;
  const _OrderCard({required this.order});

  Color _statusColor() {
    switch (order.status) {
      case 'pending':
        return Colors.orange;
      case 'preparing':
        return Colors.blue;
      case 'ready':
        return kGreen;
      case 'completed':
        return Colors.grey;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _statusIcon() {
    switch (order.status) {
      case 'pending':
        return Icons.pending_actions;
      case 'preparing':
        return Icons.soup_kitchen;
      case 'ready':
        return Icons.check_circle;
      case 'completed':
        return Icons.check_circle_outline;
      case 'cancelled':
        return Icons.cancel;
      default:
        return Icons.info;
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final isSeller = auth.user?.isSeller == true;
    final color = _statusColor();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status header
          Container(
            width: double.infinity,
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                Icon(_statusIcon(), size: 18, color: color),
                const SizedBox(width: 6),
                Text(order.statusLabel,
                    style: TextStyle(
                        color: color, fontWeight: FontWeight.bold)),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Order number + pickup badge + total
                Row(
                  children: [
                    Text(
                      'Order #${order.id.substring(0, 8).toUpperCase()}',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.store_outlined,
                              size: 12, color: Colors.grey),
                          SizedBox(width: 3),
                          Text('Pickup',
                              style: TextStyle(
                                  fontSize: 11, color: Colors.grey)),
                        ],
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '\$${order.total.toStringAsFixed(2)}',
                      style: const TextStyle(
                          color: kOrange,
                          fontWeight: FontWeight.bold,
                          fontSize: 16),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Placed at ${DateFormat('h:mm a').format(order.createdAt.toLocal())}',
                  style:
                      const TextStyle(color: Colors.grey, fontSize: 12),
                ),

                // Status message
                if (order.status == 'completed') ...[
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.check_circle_outline,
                            size: 16, color: Colors.grey),
                        SizedBox(width: 6),
                        Text('Order completed. Thank you! 🙏',
                            style: TextStyle(
                                color: Colors.grey, fontSize: 13)),
                      ],
                    ),
                  ),
                ],

                if (isSeller) ...[
                  const SizedBox(height: 4),
                  Text('Customer: ${order.studentName}',
                      style: const TextStyle(fontSize: 13)),
                ],

                // ORDER DETAILS section
                const SizedBox(height: 14),
                const Text('ORDER DETAILS',
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey,
                        letterSpacing: 0.8)),
                const SizedBox(height: 8),

                // Shop label
                Row(
                  children: [
                    Text(
                      order.items.isNotEmpty
                          ? 'Shop ${order.items.first.name.split('-').first}'
                          : '',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        border:
                            Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text('RUPP',
                          style: TextStyle(
                              fontSize: 10, color: Colors.grey)),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Items
                ...order.items.map((item) => Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        border:
                            Border.all(color: Colors.grey.shade100),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                                '${item.quantity}× ${item.name}',
                                style: const TextStyle(fontSize: 13)),
                          ),
                          Text(
                            '\$${(item.price * item.quantity).toStringAsFixed(2)}',
                            style: const TextStyle(
                                fontWeight: FontWeight.w500,
                                fontSize: 13),
                          ),
                        ],
                      ),
                    )),

                const Divider(height: 20),

                // Total
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Total',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    Text(
                      '\$${order.total.toStringAsFixed(2)}',
                      style: const TextStyle(
                          color: kOrange,
                          fontWeight: FontWeight.bold,
                          fontSize: 16),
                    ),
                  ],
                ),

                if (order.cancelReason != null) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline,
                            color: Colors.red, size: 16),
                        const SizedBox(width: 6),
                        Expanded(
                            child: Text(order.cancelReason!,
                                style: const TextStyle(
                                    color: Colors.red, fontSize: 12))),
                      ],
                    ),
                  ),
                ],

                if (isSeller &&
                    order.status != 'completed' &&
                    order.status != 'cancelled') ...[
                  const SizedBox(height: 12),
                  _SellerActions(order: order),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SellerActions extends StatelessWidget {
  final Order order;
  const _SellerActions({required this.order});

  @override
  Widget build(BuildContext context) {
    final orders = context.read<OrderProvider>();

    if (order.status == 'pending') {
      return Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => _cancelDialog(context, orders),
              icon: const Icon(Icons.cancel, color: Colors.red, size: 16),
              label: const Text('Cancel',
                  style: TextStyle(color: Colors.red)),
              style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.red)),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () =>
                  orders.updateStatus(order.id, 'preparing'),
              icon: const Icon(Icons.soup_kitchen, size: 16),
              label: const Text('Start Preparing'),
              style: ElevatedButton.styleFrom(backgroundColor: kOrange),
            ),
          ),
        ],
      );
    }

    if (order.status == 'preparing') {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: () => orders.updateStatus(order.id, 'ready'),
          icon: const Icon(Icons.check_circle, size: 16),
          label: const Text('Mark as Ready'),
          style: ElevatedButton.styleFrom(backgroundColor: kGreen),
        ),
      );
    }

    if (order.status == 'ready') {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: () => orders.updateStatus(order.id, 'completed'),
          icon: const Icon(Icons.done_all, size: 16),
          label: const Text('Mark Completed'),
          style:
              ElevatedButton.styleFrom(backgroundColor: Colors.grey),
        ),
      );
    }

    return const SizedBox.shrink();
  }

  Future<void> _cancelDialog(
      BuildContext context, OrderProvider orders) async {
    final reasonCtrl = TextEditingController();
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel Order'),
        content: TextField(
          controller: reasonCtrl,
          decoration: const InputDecoration(
            labelText: 'Reason (optional)',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Back')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Confirm Cancel',
                  style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirm == true) {
      await orders.updateStatus(order.id, 'cancelled',
          cancelReason:
              reasonCtrl.text.isNotEmpty ? reasonCtrl.text : null);
    }
  }
}
