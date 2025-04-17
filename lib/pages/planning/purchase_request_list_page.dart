import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mpt_ims/models/purchase_request.dart';
import 'package:mpt_ims/provider/purchase_request_provider.dart';
import 'add_purchase_request_page.dart';

class PurchaseRequestListPage extends ConsumerWidget {
  const PurchaseRequestListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final requests = ref.watch(purchaseRequestListProvider);
    final notifier = ref.read(purchaseRequestListProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('Purchase Requests')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => const AddPurchaseRequestPage(
                    existingRequest: null,
                    index: null,
                  )),
        ),
        child: const Icon(Icons.add),
      ),
      body: requests.isEmpty
          ? const Center(child: Text('No purchase requests found.'))
          : SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: const [
                  DataColumn(label: Text('PR No')),
                  DataColumn(label: Text('Date')),
                  DataColumn(label: Text('Material')),
                  DataColumn(label: Text('Code')),
                  DataColumn(label: Text('Unit')),
                  DataColumn(label: Text('Qty')),
                  DataColumn(label: Text('Required By')),
                  DataColumn(label: Text('Remarks')),
                  DataColumn(label: Text('Status')),
                  DataColumn(label: Text('Actions')),
                ],
                rows: List.generate(requests.length, (index) {
                  final r = requests[index];
                  return DataRow(cells: [
                    DataCell(Text(r.prNo)),
                    DataCell(Text(r.date)),
                    DataCell(Text(r.materialDescription)),
                    DataCell(Text(r.materialCode)),
                    DataCell(Text(r.unit)),
                    DataCell(Text(r.quantity)),
                    DataCell(Text(r.requiredBy)),
                    DataCell(Text(r.remarks)),
                    DataCell(Text(r.status)),
                    DataCell(Row(
                      children: [
                        Tooltip(
                          message: 'Edit',
                          child: IconButton(
                            icon: const Icon(Icons.edit),
                            color: Colors.teal[600],
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => AddPurchaseRequestPage(
                                    existingRequest: r,
                                    index: index,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 6),
                        Tooltip(
                          message: 'Delete',
                          child: IconButton(
                            icon: const Icon(Icons.delete),
                            color: Colors.red[400],
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (_) => AlertDialog(
                                  title: const Text('Delete Purchase Request'),
                                  content: const Text(
                                      'Are you sure you want to delete this request?'),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: const Text('Cancel'),
                                    ),
                                    TextButton(
                                      onPressed: () {
                                        notifier.deleteRequest(index);
                                        Navigator.pop(context);
                                      },
                                      child: const Text('Delete'),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    )),
                  ]);
                }),
              ),
            ),
    );
  }
}
