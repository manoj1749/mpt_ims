// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pluto_grid/pluto_grid.dart';
import 'package:collection/collection.dart';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
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

  Future<void> _exportToExcel(
    List<PurchaseRequest> requests,
    List<PurchaseOrder> purchaseOrders,
    List<StoreInward> storeInwards,
  ) async {
    try {
      final headers = [
        'Sl.No',
        'Sale Order No',
        'Job No',
        'PR No',
        'PR Date',
        'Part No',
        'Description',
        'PR Qty',
        'Unit',
        'Requested By',
        'Stock Transfer Qty & Date',
        'PO No & Date',
        'PO Qty',
        'Pending PR Qty',
        'Status'
      ];

      final rows = _getRows(requests, purchaseOrders, storeInwards);
      final csvData = [headers];

      for (var row in rows) {
        final rowData = <String>[];

        // Extract data in the order of headers
        rowData.add(row.cells['serialNo']?.value.toString() ?? '');
        rowData.add(''); // Sale Order No - not available in current model
        rowData.add(row.cells['jobNo']?.value.toString() ?? '');
        rowData.add(row.cells['prNo']?.value.toString() ?? '');
        rowData.add(row.cells['prDate']?.value.toString() ?? '');
        rowData.add(row.cells['partNo']?.value.toString() ?? '');
        rowData.add(row.cells['description']?.value.toString() ?? '');
        rowData.add(row.cells['prQty']?.value.toString() ?? '');
        rowData.add(row.cells['unit']?.value.toString() ?? '');
        rowData.add(row.cells['requestedBy']?.value.toString() ?? '');
        rowData.add(row.cells['stockTransfer']?.value
                .toString()
                .replaceAll('\n', '; ') ??
            '');
        rowData.add(
            row.cells['poDetails']?.value.toString().replaceAll('\n', '; ') ??
                '');
        rowData.add(row.cells['orderedQty']?.value.toString() ?? '');
        rowData.add(row.cells['pendingQty']?.value.toString() ?? '');
        rowData.add(row.cells['status']?.value.toString() ?? '');

        csvData.add(rowData);
      }

      final csvString = const ListToCsvConverter().convert(csvData);

      // Get the documents directory
      final directory = await getApplicationDocumentsDirectory();
      final now = DateTime.now();
      final fileName =
          'purchase_requests_${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}_${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}.csv';
      final filePath = '${directory.path}/$fileName';

      // Save the file
      final file = File(filePath);
      await file.writeAsString(csvString);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('PR Report exported successfully to $filePath'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to export PR report: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildExportButton() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Status Filter Dropdown
        SizedBox(
          width: 200,
          child: DropdownButtonFormField<String>(
            decoration: InputDecoration(
              labelText: 'Status Filter',
              labelStyle: TextStyle(color: Colors.grey[300]),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              fillColor: Colors.grey[800],
              filled: true,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            style: const TextStyle(color: Colors.white),
            dropdownColor: Colors.grey[800],
            value: _selectedStatus,
            items: ['Active', 'Completed', 'All']
                .map((status) => DropdownMenuItem(
                      value: status,
                      child: Text(status,
                          style: const TextStyle(color: Colors.white)),
                    ))
                .toList(),
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  _selectedStatus = value;
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
        // Export Button
        FilledButton.icon(
          onPressed: _showExportOptions,
          icon: const Icon(Icons.download),
          label: const Text('Export Report'),
        ),
      ],
    );
  }

  void _showExportOptions() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[850],
        title: Text(
          'Export Purchase Request Report',
          style: TextStyle(color: Colors.grey[200]),
        ),
        content: Text(
          'Choose export option:',
          style: TextStyle(color: Colors.grey[200]),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: Colors.grey[200])),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _quickExport();
            },
            child:
                Text('Quick Export', style: TextStyle(color: Colors.grey[200])),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _showFilterDialog();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
            ),
            child: const Text('Filter'),
          ),
        ],
      ),
    );
  }

  void _quickExport() {
    final requests = ref.read(purchaseRequestListProvider);
    final purchaseOrders = ref.read(purchaseOrderListProvider);
    final storeInwards = ref.read(storeInwardProvider);
    _exportToExcel(requests, purchaseOrders, storeInwards);
  }

  void _showFilterDialog() {
    DateTime? startDate;
    DateTime? endDate;
    String jobNumberFilter = '';
    String partNumberFilter = '';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: Colors.grey[850],
          title: Text(
            'Filter Purchase Requests',
            style: TextStyle(color: Colors.grey[200]),
          ),
          content: SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  decoration: InputDecoration(
                    labelText: 'Job Number',
                    labelStyle: TextStyle(color: Colors.grey[300]),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    fillColor: Colors.grey[800],
                    filled: true,
                  ),
                  style: const TextStyle(color: Colors.white),
                  onChanged: (value) => jobNumberFilter = value,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  decoration: InputDecoration(
                    labelText: 'Part Number/Description',
                    labelStyle: TextStyle(color: Colors.grey[300]),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    fillColor: Colors.grey[800],
                    filled: true,
                  ),
                  style: const TextStyle(color: Colors.white),
                  onChanged: (value) => partNumberFilter = value,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  decoration: InputDecoration(
                    labelText: 'Start Date (YYYY-MM-DD)',
                    labelStyle: TextStyle(color: Colors.grey[300]),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    fillColor: Colors.grey[800],
                    filled: true,
                  ),
                  style: const TextStyle(color: Colors.white),
                  onChanged: (value) {
                    try {
                      startDate = DateTime.parse(value);
                    } catch (e) {
                      startDate = null;
                    }
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  decoration: InputDecoration(
                    labelText: 'End Date (YYYY-MM-DD)',
                    labelStyle: TextStyle(color: Colors.grey[300]),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    fillColor: Colors.grey[800],
                    filled: true,
                  ),
                  style: const TextStyle(color: Colors.white),
                  onChanged: (value) {
                    try {
                      endDate = DateTime.parse(value);
                    } catch (e) {
                      endDate = null;
                    }
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel', style: TextStyle(color: Colors.grey[200])),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _exportWithFilters(
                    startDate, endDate, jobNumberFilter, partNumberFilter);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
              ),
              child: const Text('Export'),
            ),
          ],
        ),
      ),
    );
  }

  void _exportWithFilters(DateTime? startDate, DateTime? endDate,
      String jobNumberFilter, String partNumberFilter) {
    final allRequests = ref.read(purchaseRequestListProvider);
    final purchaseOrders = ref.read(purchaseOrderListProvider);
    final storeInwards = ref.read(storeInwardProvider);

    // Apply filters
    final filteredRequests = allRequests.where((request) {
      // Date filter
      if (startDate != null) {
        final requestDate = DateTime.parse(request.date);
        if (requestDate.isBefore(startDate)) return false;
      }
      if (endDate != null) {
        final requestDate = DateTime.parse(request.date);
        if (requestDate.isAfter(endDate)) return false;
      }

      // Job number filter
      if (jobNumberFilter.isNotEmpty) {
        if (!(request.jobNo
                ?.toLowerCase()
                .contains(jobNumberFilter.toLowerCase()) ??
            false)) {
          return false;
        }
      }

      // Part number/description filter
      if (partNumberFilter.isNotEmpty) {
        bool hasMatch = false;
        for (var item in request.items) {
          if (item.materialCode
                  .toLowerCase()
                  .contains(partNumberFilter.toLowerCase()) ||
              item.materialDescription
                  .toLowerCase()
                  .contains(partNumberFilter.toLowerCase())) {
            hasMatch = true;
            break;
          }
        }
        if (!hasMatch) return false;
      }

      return true;
    }).toList();

    _exportToExcel(filteredRequests, purchaseOrders, storeInwards);
  }

  List<PlutoRow> _getRows(
    List<PurchaseRequest> requests,
    List<PurchaseOrder> purchaseOrders,
    List<StoreInward> storeInwards,
  ) {
    // Apply status filter only
    var filteredRequests = requests.where((pr) {
      if (_selectedStatus == 'Active' && pr.status == 'Completed') return false;
      if (_selectedStatus != 'All' &&
          _selectedStatus != 'Active' &&
          pr.status != _selectedStatus) return false;
      return true;
    }).toList();

    final rows = <PlutoRow>[];
    var serialNo = 1;

    for (var request in filteredRequests) {
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
                  _buildExportButton(),
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
