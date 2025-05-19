import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mpt_ims/provider/purchase_request_provider.dart';
import 'package:mpt_ims/models/purchase_request.dart';
import 'add_purchase_request_page.dart';

class PurchaseRequestListPage extends ConsumerWidget {
  const PurchaseRequestListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final requests = ref.watch(purchaseRequestListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Purchase Requests'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              // TODO: Implement search
            },
            tooltip: 'Search Requests',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const AddPurchaseRequestPage(
              existingRequest: null,
              index: null,
            ),
          ),
        ),
        child: const Icon(Icons.add),
      ),
      body: requests.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.assignment_outlined,
                    size: 64,
                    color: Colors.grey[300],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No purchase requests yet',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  FilledButton(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const AddPurchaseRequestPage(
                          existingRequest: null,
                          index: null,
                        ),
                      ),
                    ),
                    child: const Text('Create New Request'),
                  ),
                ],
              ),
            )
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        '${requests.length} Purchase Requests',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(width: 16),
                      FilledButton.tonal(
                        onPressed: () {
                          // TODO: Implement filtering
                        },
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.filter_list, size: 20),
                            SizedBox(width: 8),
                            Text('Filter'),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: Card(
                      elevation: 0,
                      margin: EdgeInsets.zero,
                      child: SizedBox(
                        width: MediaQuery.of(context).size.width - 32,
                        child: ListView.builder(
                          itemCount: requests.length,
                          itemBuilder: (context, index) {
                            final pr = requests[index];
                            return Card(
                              margin: const EdgeInsets.symmetric(vertical: 8),
                              child: ExpansionTile(
                                title: Row(
                                  children: [
                                    Text(
                                      pr.prNo,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold),
                                    ),
                                    const SizedBox(width: 16),
                                    Text(pr.date),
                                    const SizedBox(width: 16),
                                    Text('Required By: ${pr.requiredBy}'),
                                    const SizedBox(width: 16),
                                    if (pr.jobNo != null) ...[
                                      Text('Job No: ${pr.jobNo}'),
                                      const SizedBox(width: 16),
                                    ],
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: pr.isFullyOrdered
                                            ? Colors.green.withOpacity(0.1)
                                            : Colors.orange.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        pr.status,
                                        style: TextStyle(
                                          color: pr.isFullyOrdered
                                              ? Colors.green
                                              : Colors.orange,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                children: [
                                  SingleChildScrollView(
                                    scrollDirection: Axis.horizontal,
                                    child: DataTable(
                                      columns: const [
                                        DataColumn(
                                            label: Text('Material Code')),
                                        DataColumn(label: Text('Description')),
                                        DataColumn(label: Text('Unit')),
                                        DataColumn(label: Text('Quantity')),
                                        DataColumn(label: Text('Ordered')),
                                        DataColumn(label: Text('Remaining')),
                                        DataColumn(label: Text('Remarks')),
                                      ],
                                      rows: pr.items.map((item) {
                                        return DataRow(
                                          cells: [
                                            DataCell(Text(item.materialCode)),
                                            DataCell(
                                                Text(item.materialDescription)),
                                            DataCell(Text(item.unit)),
                                            DataCell(Text(item.quantity)),
                                            DataCell(
                                              Text(
                                                item.totalOrderedQuantity
                                                    .toStringAsFixed(2),
                                                style: TextStyle(
                                                  color: item.isFullyOrdered
                                                      ? Colors.green
                                                      : Colors.orange,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ),
                                            DataCell(
                                              Text(
                                                item.remainingQuantity
                                                    .toStringAsFixed(2),
                                                style: TextStyle(
                                                  color:
                                                      item.remainingQuantity > 0
                                                          ? Colors.red
                                                          : Colors.green,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ),
                                            DataCell(Text(item.remarks ?? '')),
                                          ],
                                        );
                                      }).toList(),
                                    ),
                                  ),
                                  OverflowBar(
                                    children: [
                                      TextButton.icon(
                                        icon: const Icon(Icons.edit_outlined),
                                        label: const Text('Edit'),
                                        onPressed: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) =>
                                                  AddPurchaseRequestPage(
                                                existingRequest: pr,
                                                index: index,
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                      TextButton.icon(
                                        icon: const Icon(Icons.delete_outline),
                                        label: const Text('Delete'),
                                        onPressed: () =>
                                            _confirmDelete(context, ref, pr),
                                        style: TextButton.styleFrom(
                                          foregroundColor: Colors.red,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Future<void> _confirmDelete(
      BuildContext context, WidgetRef ref, PurchaseRequest request) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: Text('Are you sure you want to delete PR ${request.prNo}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      ref.read(purchaseRequestListProvider.notifier).deleteRequest(request);
    }
  }
}
