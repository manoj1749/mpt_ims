import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mpt_ims/provider/purchase_request_provider.dart';
import 'add_purchase_request_page.dart';

class PurchaseRequestListPage extends ConsumerWidget {
  const PurchaseRequestListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final requests = ref.watch(purchaseRequestListProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Purchase Requests')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AddPurchaseRequestPage()),
        ),
        child: const Icon(Icons.add),
      ),
      body: requests.isEmpty
          ? const Center(child: Text('No purchase requests found.'))
          : ListView.builder(
              itemCount: requests.length,
              itemBuilder: (context, index) {
                final r = requests[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: ListTile(
                    title: Text('${r.materialDescription} (${r.materialCode})'),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Qty: ${r.quantity} ${r.unit}'),
                        Text('Required By: ${r.requiredBy}'),
                        Text('Remarks: ${r.remarks}'),
                        Text('PR No: ${r.prNo}'),
                        Text('Date: ${r.date}'),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
