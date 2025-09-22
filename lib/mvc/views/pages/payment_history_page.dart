import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:weight_calculator/mvc/controllers/payment_history_controller.dart';

class PaymentHistoryPage extends StatelessWidget {
  PaymentHistoryPage({super.key});

  final PaymentHistoryController controller = Get.find<PaymentHistoryController>();

  String _formatDate(DateTime dt) => DateFormat('yyyy-MM-dd HH:mm').format(dt);

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'success':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'failed':
        return Colors.red;
      default:
        return Colors.blueGrey;
    }
  }

  Future<void> _showDetailsDialog(BuildContext context, dynamic p) async {
    final statusColor = _statusColor(p.status);
    await showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(
          'Payment Details',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: const Color.fromARGB(255, 1, 104, 51),
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _kv('Package', p.packageName),
            const SizedBox(height: 6),
            _kv('Amount', '${p.amount}৳'),
            const SizedBox(height: 6),
            Row(
              children: [
                const Text('Status: ',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: statusColor.withOpacity(0.35)),
                  ),
                  child: Text(
                    p.status.toLowerCase() == 'success'
                        ? 'Successful'
                        : p.status[0].toUpperCase() + p.status.substring(1).toLowerCase(),
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            _kv('Date', _formatDate(p.createdAt)),
            const SizedBox(height: 6),
            GestureDetector(
              onLongPress: () {
                Clipboard.setData(ClipboardData(text: p.uuid));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Transaction ID copied')),
                );
              },
              child: _kv('Transaction ID', p.uuid, wrap: true),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'OK',
              style: TextStyle(
                color: const Color.fromARGB(255, 1, 104, 51),
                fontWeight: FontWeight.w600,
                fontSize: 18,
              ),
            ),
          ),
        ],
      ),
    );
  }

  static Widget _kv(String k, String v, {bool wrap = false}) {
    final value = Text(
      v,
      style: const TextStyle(fontWeight: FontWeight.w500),
      overflow: wrap ? TextOverflow.visible : TextOverflow.ellipsis,
      maxLines: wrap ? null : 1,
      softWrap: wrap,
    );
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('$k: ', style: const TextStyle(fontWeight: FontWeight.w600)),
        Expanded(child: value),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        if (controller.error.isNotEmpty) {
          // ignore: avoid_print
          print("Error: ${controller.error.value}");
          return RefreshIndicator(
            onRefresh: controller.fetchPaymentHistory,
            child: ListView(
              children: [
                const SizedBox(height: 140),
                Icon(Icons.error_outline, size: 42, color: Colors.red.shade400),
                const SizedBox(height: 12),
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Text(
                      controller.error.value,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 15),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Center(
                  child: OutlinedButton.icon(
                    onPressed: controller.fetchPaymentHistory,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Try again'),
                  ),
                ),
              ],
            ),
          );
        }

        if (controller.payments.isEmpty) {
          return RefreshIndicator(
            onRefresh: controller.fetchPaymentHistory,
            child: ListView(
              children: const [
                SizedBox(height: 160),
                Icon(Icons.receipt_long, size: 44, color: Colors.grey),
                SizedBox(height: 12),
                Center(child: Text("No payments found")),
              ],
            ),
          );
        }

        // Main list with pull-to-refresh
        return RefreshIndicator(
          onRefresh: controller.fetchPaymentHistory,
          child: ListView.builder(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: controller.payments.length,
            itemBuilder: (context, index) {
              final p = controller.payments[index];

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                elevation: 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                child: ListTile(
                  onTap: () => _showDetailsDialog(context, p), // <-- show dialog
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: 14,
                    horizontal: 18,
                  ),
                  leading: CircleAvatar(
                    radius: 24,
                    backgroundColor: _statusColor(p.status).withOpacity(0.15),
                    child: Icon(
                      p.status.toLowerCase() == 'success'
                          ? Icons.check_circle
                          : (p.status.toLowerCase() == 'pending'
                              ? Icons.pending
                              : Icons.error_outline),
                      color: _statusColor(p.status),
                      size: 28,
                    ),
                  ),
                  title: Text(
                    p.packageName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 17,
                      color: Color.fromARGB(255, 1, 104, 51),
                    ),
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Amount: ${p.amount}৳",
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: _statusColor(p.status).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: _statusColor(p.status).withOpacity(0.35),
                                ),
                              ),
                              child: Text(
                                p.status.toLowerCase() == 'success'
                                    ? 'Successful'
                                    : p.status[0].toUpperCase() +
                                        p.status.substring(1).toLowerCase(),
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                  color: _statusColor(p.status),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _formatDate(p.createdAt),
                              style: const TextStyle(
                                fontSize: 13,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "Txn: ${p.uuid}",
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12.5,
                            color: Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  ),
                  tileColor: Colors.white,
                ),
              );
            },
          ),
        );
      }),
    );
  }
}
