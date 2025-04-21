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
                        child: PaginatedDataTable(
                          source: _PurchaseRequestDataSource(
                            requests: requests,
                            context: context,
                            ref: ref,
                            onDelete: (request) => _confirmDelete(context, ref, request),
                          ),
                          header: null,
                          rowsPerPage: requests.length,
                          showFirstLastButtons: true,
                          showCheckboxColumn: false,
                          horizontalMargin: 16,
                          columnSpacing: 20,
                          availableRowsPerPage: const [20, 50, 100, 200],
                          columns: const [
                            DataColumn(label: Text('PR No')),
                            DataColumn(label: Text('Date')),
                            DataColumn(label: Text('Material Code')),
                            DataColumn(label: Text('Description')),
                            DataColumn(label: Text('Unit')),
                            DataColumn(label: Text('Quantity')),
                            DataColumn(label: Text('Required By')),
                            DataColumn(label: Text('Supplier')),
                            DataColumn(label: Text('Ordered')),
                            DataColumn(label: Text('Remaining')),
                            DataColumn(label: Text('Status')),
                            DataColumn(label: Text('Actions')),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

class _PurchaseRequestDataSource extends DataTableSource {
  final List<PurchaseRequest> requests;
  final BuildContext context;
  final WidgetRef ref;
  final Function(PurchaseRequest) onDelete;

  _PurchaseRequestDataSource({
    required this.requests,
    required this.context,
    required this.ref,
    required this.onDelete,
  });

  @override
  DataRow? getRow(int index) {
    if (index >= requests.length) return null;
    final pr = requests[index];
    
    final totalOrdered = pr.orderedQuantities.values.fold<double>(
      0.0,
      (sum, qty) => sum + qty,
    );
    final remainingQty = (double.tryParse(pr.quantity) ?? 0) - totalOrdered;
    final progress = totalOrdered / (double.tryParse(pr.quantity) ?? 1);

    return DataRow(
      cells: [
        DataCell(
          Text(
            pr.prNo,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
        ),
        DataCell(Text(pr.date)),
        DataCell(Text(pr.materialCode)),
        DataCell(
          Text(
            pr.materialDescription,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        DataCell(Text(pr.unit)),
        DataCell(
          Text(
            pr.quantity,
            style: const TextStyle(fontWeight: FontWeight.w500),
                                ),
        ),
        DataCell(Text(pr.requiredBy)),
        DataCell(Text(pr.supplierName)),
        DataCell(
          Text(
            totalOrdered.toStringAsFixed(2),
            style: TextStyle(
              color: progress >= 1 ? Colors.green : Colors.orange,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        DataCell(
          Text(
            remainingQty.toStringAsFixed(2),
            style: TextStyle(
              color: remainingQty > 0 ? Colors.red : Colors.green,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        DataCell(
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: progress >= 1
                  ? Colors.green.withOpacity(0.1)
                  : progress > 0
                      ? Colors.orange.withOpacity(0.1)
                      : Colors.grey.withOpacity(0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              progress >= 1
                  ? 'Completed'
                  : progress > 0
                      ? 'Partial'
                      : 'Pending',
              style: TextStyle(
                color: progress >= 1
                    ? Colors.green
                    : progress > 0
                        ? Colors.orange
                        : Colors.grey,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
        DataCell(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.edit_outlined, size: 20),
                onPressed: () {
                  // TODO: Implement inline editing
                },
                color: Colors.blue,
                tooltip: 'Edit',
                constraints: const BoxConstraints(
                  minWidth: 32,
                  minHeight: 32,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, size: 20),
                onPressed: () => onDelete(pr),
                            color: Colors.red[400],
                tooltip: 'Delete',
                constraints: const BoxConstraints(
                  minWidth: 32,
                  minHeight: 32,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  bool get isRowCountApproximate => false;

  @override
  int get rowCount => requests.length;

  @override
  int get selectedRowCount => 0;
}

void _confirmDelete(BuildContext context, WidgetRef ref, PurchaseRequest pr) {
                              showDialog(
                                context: context,
                                builder: (_) => AlertDialog(
                                  title: const Text('Delete Purchase Request'),
      content: const Text('Are you sure you want to delete this request?'),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: const Text('Cancel'),
                                    ),
        FilledButton.tonal(
                                      onPressed: () {
            ref.read(purchaseRequestListProvider.notifier).deleteRequest(pr);
                                        Navigator.pop(context);
                                      },
          style: FilledButton.styleFrom(
            foregroundColor: Colors.red,
          ),
                                      child: const Text('Delete'),
                                    ),
                                  ],
                                ),
                              );
}
