// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pluto_grid/pluto_grid.dart';
import 'package:collection/collection.dart';
import '../../provider/purchase_request_provider.dart';
import '../../provider/purchase_order.dart';
import '../../provider/store_inward_provider.dart';
import '../../models/purchase_request.dart';
import '../../models/purchase_order.dart';
import '../../models/store_inward.dart';
import '../../widgets/pluto_grid_configuration.dart';
import 'add_purchase_request_page.dart';

class PurchaseRequestListPage extends ConsumerStatefulWidget {
  const PurchaseRequestListPage({super.key});

  @override
  ConsumerState<PurchaseRequestListPage> createState() =>
      _PurchaseRequestListPageState();
}

class _PurchaseRequestListPageState
    extends ConsumerState<PurchaseRequestListPage> {
  late final List<PlutoColumn> columns;
  PlutoGridStateManager? stateManager;
  String _selectedStatus = 'Active'; // Default to Active view

  @override
  void initState() {
    super.initState();
    columns = [
      PlutoColumn(
        title: 'S.No',
        field: 'serialNo',
        type: PlutoColumnType.number(),
        width: 60,
        backgroundColor: Colors.grey[850],
        titleTextAlign: PlutoColumnTextAlign.center,
        textAlign: PlutoColumnTextAlign.center,
        enableEditingMode: false,
      ),
      PlutoColumn(
        title: 'Job No',
        field: 'jobNo',
        type: PlutoColumnType.text(),
        width: 120,
        backgroundColor: Colors.grey[850],
        titleTextAlign: PlutoColumnTextAlign.center,
        textAlign: PlutoColumnTextAlign.center,
        enableEditingMode: false,
      ),
      PlutoColumn(
        title: 'PR No',
        field: 'prNo',
        type: PlutoColumnType.text(),
        width: 120,
        backgroundColor: Colors.grey[850],
        titleTextAlign: PlutoColumnTextAlign.center,
        textAlign: PlutoColumnTextAlign.center,
        enableEditingMode: false,
      ),
      PlutoColumn(
        title: 'PR Date',
        field: 'prDate',
        type: PlutoColumnType.date(),
        width: 120,
        backgroundColor: Colors.grey[850],
        titleTextAlign: PlutoColumnTextAlign.center,
        textAlign: PlutoColumnTextAlign.center,
        enableEditingMode: false,
      ),
      PlutoColumn(
        title: 'Part No',
        field: 'partNo',
        type: PlutoColumnType.text(),
        width: 120,
        backgroundColor: Colors.grey[850],
        titleTextAlign: PlutoColumnTextAlign.center,
        textAlign: PlutoColumnTextAlign.center,
        enableEditingMode: false,
      ),
      PlutoColumn(
        title: 'Description',
        field: 'description',
        type: PlutoColumnType.text(),
        width: 200,
        backgroundColor: Colors.grey[850],
        titleTextAlign: PlutoColumnTextAlign.center,
        textAlign: PlutoColumnTextAlign.start,
        enableEditingMode: false,
      ),
      PlutoColumn(
        title: 'PR Qty',
        field: 'prQty',
        type: PlutoColumnType.number(),
        width: 100,
        backgroundColor: Colors.grey[850],
        titleTextAlign: PlutoColumnTextAlign.center,
        textAlign: PlutoColumnTextAlign.right,
        enableEditingMode: false,
      ),
      PlutoColumn(
        title: 'Unit',
        field: 'unit',
        type: PlutoColumnType.text(),
        width: 80,
        backgroundColor: Colors.grey[850],
        titleTextAlign: PlutoColumnTextAlign.center,
        textAlign: PlutoColumnTextAlign.center,
        enableEditingMode: false,
      ),
      PlutoColumn(
        title: 'Requested By',
        field: 'requestedBy',
        type: PlutoColumnType.text(),
        width: 120,
        backgroundColor: Colors.grey[850],
        titleTextAlign: PlutoColumnTextAlign.center,
        textAlign: PlutoColumnTextAlign.center,
        enableEditingMode: false,
      ),
      PlutoColumn(
        title: 'Stock Transfer',
        field: 'stockTransfer',
        type: PlutoColumnType.text(),
        width: 150,
        backgroundColor: Colors.grey[850],
        titleTextAlign: PlutoColumnTextAlign.center,
        textAlign: PlutoColumnTextAlign.start,
        enableEditingMode: false,
        renderer: (rendererContext) {
          final transfers = rendererContext.cell.value.toString();
          if (transfers == '-') {
            return Container(
              padding: const EdgeInsets.all(8),
              child: Text(
                '-',
                style: TextStyle(color: Colors.grey[200]),
              ),
            );
          }
          return Container(
            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: transfers
                    .split('\n')
                    .map((transfer) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Text(
                            transfer.trim(),
                            style: TextStyle(
                              color: Colors.grey[200],
                              fontSize: 13,
                              height: 1.3,
                            ),
                          ),
                        ))
                    .toList(),
              ),
            ),
          );
        },
      ),
      PlutoColumn(
        title: 'PO Details',
        field: 'poDetails',
        type: PlutoColumnType.text(),
        width: 300,
        backgroundColor: Colors.grey[850],
        titleTextAlign: PlutoColumnTextAlign.center,
        textAlign: PlutoColumnTextAlign.start,
        enableEditingMode: false,
        renderer: (rendererContext) {
          final poDetails = rendererContext.cell.value.toString();
          if (poDetails == '-') {
            return Container(
              padding: const EdgeInsets.all(8),
              child: Text(
                '-',
                style: TextStyle(color: Colors.grey[200]),
              ),
            );
          }
          return Container(
            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: poDetails
                    .split('\n')
                    .map((po) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Text(
                            po.trim(),
                            style: TextStyle(
                              color: Colors.grey[200],
                              fontSize: 13,
                              height: 1.3,
                            ),
                          ),
                        ))
                    .toList(),
              ),
            ),
          );
        },
      ),
      PlutoColumn(
        title: 'Ordered Qty',
        field: 'orderedQty',
        type: PlutoColumnType.number(),
        width: 120,
        backgroundColor: Colors.grey[850],
        titleTextAlign: PlutoColumnTextAlign.center,
        textAlign: PlutoColumnTextAlign.right,
        enableEditingMode: false,
      ),
      PlutoColumn(
        title: 'Pending Qty',
        field: 'pendingQty',
        type: PlutoColumnType.number(),
        width: 120,
        backgroundColor: Colors.grey[850],
        titleTextAlign: PlutoColumnTextAlign.center,
        textAlign: PlutoColumnTextAlign.right,
        enableEditingMode: false,
      ),
      PlutoColumn(
        title: 'Status',
        field: 'status',
        type: PlutoColumnType.text(),
        width: 120,
        backgroundColor: Colors.grey[850],
        titleTextAlign: PlutoColumnTextAlign.center,
        textAlign: PlutoColumnTextAlign.center,
        enableEditingMode: false,
      ),
      PlutoColumn(
        title: 'Actions',
        field: 'actions',
        type: PlutoColumnType.text(),
        width: 140,
        backgroundColor: Colors.grey[850],
        titleTextAlign: PlutoColumnTextAlign.center,
        textAlign: PlutoColumnTextAlign.center,
        enableEditingMode: false,
        renderer: (rendererContext) {
          final prNo = rendererContext.row.cells['prNo']?.value as String;
          final request = ref
              .watch(purchaseRequestListProvider)
              .firstWhereOrNull((pr) => pr.prNo == prNo);

          if (request == null) {
            return const SizedBox.shrink();
          }

          return Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 40,
                height: 40,
                child: IconButton(
                  padding: EdgeInsets.zero,
                  icon: Icon(Icons.delete, color: Colors.grey[200], size: 20),
                  onPressed: () {
                    _showDeleteConfirmation(context, ref, request);
                  },
                ),
              ),
            ],
          );
        },
      ),
    ];
  }

  List<PlutoRow> _getRows(
    List<PurchaseRequest> requests,
    List<PurchaseOrder> purchaseOrders,
    List<StoreInward> storeInwards,
  ) {
    // Filter based on selected status
    if (_selectedStatus == 'Active') {
      requests = requests.where((pr) => pr.status != 'Completed').toList();
    } else if (_selectedStatus != 'All') {
      requests = requests.where((pr) => pr.status == _selectedStatus).toList();
    }

    final rows = <PlutoRow>[];
    var serialNo = 1;

    for (var request in requests) {
      for (var item in request.items) {
        // Calculate total ordered quantity for this PR item
        final totalOrderedQty = item.totalOrderedQuantity;

        // Get PO details
        final relatedPOs = purchaseOrders
            .where((po) => po.items.any((poItem) =>
                poItem.materialCode == item.materialCode &&
                poItem.prDetails.values
                    .any((detail) => detail.prNo == request.prNo)))
            .map((po) => '${po.poNo}\n(${po.poDate})')
            .join('\n\n');

        // Get stock transfer details
        final transfers = storeInwards
            .where((si) => si.items.any((siItem) =>
                siItem.materialCode == item.materialCode &&
                siItem.prQuantities.keys.any((poNo) => purchaseOrders.any(
                    (po) =>
                        po.poNo == poNo &&
                        po.items.any((poItem) =>
                            poItem.materialCode == item.materialCode &&
                            poItem.prDetails.values.any(
                                (detail) => detail.prNo == request.prNo))))))
            .map((si) {
              final matchingItems = si.items
                  .where((siItem) => siItem.materialCode == item.materialCode);
              if (matchingItems.isNotEmpty) {
                return '${matchingItems.fold<double>(0, (sum, item) => sum + item.acceptedQty)} (${si.grnDate})';
              }
              return '';
            })
            .where((s) => s.isNotEmpty)
            .join('\n');

        final pendingQty = double.parse(item.quantity) - totalOrderedQty;
        final status = pendingQty <= 0
            ? 'Completed'
            : totalOrderedQty > 0
                ? 'Partially Ordered'
                : 'Placed';

        rows.add(
          PlutoRow(
            cells: {
              'serialNo': PlutoCell(value: serialNo++),
              'jobNo': PlutoCell(value: request.jobNo ?? '-'),
              'prNo': PlutoCell(value: request.prNo),
              'prDate': PlutoCell(value: request.date),
              'partNo': PlutoCell(value: item.materialCode),
              'description': PlutoCell(value: item.materialDescription),
              'prQty': PlutoCell(value: double.parse(item.quantity)),
              'unit': PlutoCell(value: item.unit),
              'requestedBy': PlutoCell(value: request.requiredBy),
              'stockTransfer':
                  PlutoCell(value: transfers.isEmpty ? '-' : transfers),
              'poDetails':
                  PlutoCell(value: relatedPOs.isEmpty ? '-' : relatedPOs),
              'orderedQty': PlutoCell(value: totalOrderedQty),
              'pendingQty': PlutoCell(value: pendingQty),
              'status': PlutoCell(value: status),
              'actions': PlutoCell(value: ''),
            },
          ),
        );
      }
    }

    return rows;
  }

  void _showDeleteConfirmation(
      BuildContext context, WidgetRef ref, PurchaseRequest request) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[850],
        title: Text('Delete Purchase Request',
            style: TextStyle(color: Colors.grey[200])),
        content: Text(
          'Are you sure you want to delete purchase request ${request.prNo}?',
          style: TextStyle(color: Colors.grey[200]),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: Colors.grey[200])),
          ),
          TextButton(
            onPressed: () async {
              final success = await ref
                  .read(purchaseRequestListProvider.notifier)
                  .deleteRequest(request);
              Navigator.pop(context);

              if (success) {
                // Refresh grid rows if deletion was successful
                if (stateManager != null) {
                  final requests = ref.read(purchaseRequestListProvider);
                  final purchaseOrders = ref.read(purchaseOrderListProvider);
                  final storeInwards = ref.read(storeInwardProvider);
                  stateManager!.removeAllRows();
                  stateManager!.appendRows(
                      _getRows(requests, purchaseOrders, storeInwards));
                }

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Purchase request ${request.prNo} deleted successfully',
                      style: const TextStyle(color: Colors.white),
                    ),
                    backgroundColor: Colors.black,
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Cannot delete PR ${request.prNo} - It has active Purchase Orders',
                      style: const TextStyle(color: Colors.black),
                    ),
                    backgroundColor: Colors.white,
                  ),
                );
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final requests = ref.watch(purchaseRequestListProvider);
    final purchaseOrders = ref.watch(purchaseOrderListProvider);
    final storeInwards = ref.watch(storeInwardProvider);

    return Scaffold(
      backgroundColor: Colors.grey[900],
      appBar: AppBar(
        title: const Text('Purchase Requests'),
        elevation: 0,
        actions: [
          // Add filter dropdown in the app bar
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: DropdownButton<String>(
              value: _selectedStatus,
              dropdownColor: Colors.grey[850],
              style: TextStyle(color: Colors.grey[200]),
              icon: Icon(Icons.filter_list, color: Colors.grey[200]),
              underline: Container(),
              items: const [
                DropdownMenuItem(
                  value: 'Active',
                  child: Text('Active'),
                ),
                DropdownMenuItem(
                  value: 'Completed',
                  child: Text('Completed'),
                ),
                DropdownMenuItem(
                  value: 'All',
                  child: Text('All'),
                ),
              ],
              onChanged: (String? newValue) {
                if (newValue != null) {
                  setState(() {
                    _selectedStatus = newValue;
                  });
                  // Refresh grid when filter changes
                  if (stateManager != null) {
                    final requests = ref.read(purchaseRequestListProvider);
                    final purchaseOrders = ref.read(purchaseOrderListProvider);
                    final storeInwards = ref.read(storeInwardProvider);
                    stateManager!.removeAllRows();
                    stateManager!.appendRows(
                        _getRows(requests, purchaseOrders, storeInwards));
                  }
                }
              },
            ),
          ),
          // Add refresh button
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              // Refresh the grid
              if (stateManager != null) {
                final requests = ref.read(purchaseRequestListProvider);
                final purchaseOrders = ref.read(purchaseOrderListProvider);
                final storeInwards = ref.read(storeInwardProvider);
                stateManager!.removeAllRows();
                stateManager!.appendRows(
                    _getRows(requests, purchaseOrders, storeInwards));
                // Show a snackbar to confirm refresh
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Page refreshed'),
                    backgroundColor: Colors.grey[850],
                    duration: const Duration(seconds: 1),
                  ),
                );
              }
            },
            tooltip: 'Refresh Page',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: requests.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.shopping_cart_outlined,
                    size: 64,
                    color: Colors.grey[300],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No purchase requests found',
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
                    child: const Text('Add New Request'),
                  ),
                ],
              ),
            )
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${requests.length} Purchase Requests',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: PlutoGrid(
                      columns: columns,
                      rows: _getRows(requests, purchaseOrders, storeInwards),
                      onLoaded: (PlutoGridOnLoadedEvent event) {
                        stateManager = event.stateManager;
                        stateManager?.setShowColumnFilter(true);
                      },
                      configuration: PlutoGridConfigurations.darkMode(),
                    ),
                  ),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const AddPurchaseRequestPage(
                existingRequest: null,
                index: null,
              ),
            ),
          );
          // Refresh the grid after returning from add page
          if (stateManager != null) {
            final requests = ref.read(purchaseRequestListProvider);
            final purchaseOrders = ref.read(purchaseOrderListProvider);
            final storeInwards = ref.read(storeInwardProvider);
            stateManager!.removeAllRows();
            stateManager!
                .appendRows(_getRows(requests, purchaseOrders, storeInwards));
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
