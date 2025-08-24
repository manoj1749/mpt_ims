// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:pluto_grid/pluto_grid.dart';
import '../../models/purchase_order.dart';
import '../../provider/purchase_order.dart';
import '../../provider/purchase_request_provider.dart';
import '../../provider/supplier_provider.dart';
import '../../services/pdf_service.dart';
import 'add_purchase_order_page.dart';

class PurchaseOrderListPage extends ConsumerStatefulWidget {
  const PurchaseOrderListPage({super.key});

  @override
  ConsumerState<PurchaseOrderListPage> createState() =>
      _PurchaseOrderListPageState();
}

class _PurchaseOrderListPageState extends ConsumerState<PurchaseOrderListPage> {
  String _selectedStatus = 'Active';
  final Set<String> _expandedPOs = {};
  final Set<String> _fullyExpandedPOs = {};
  PlutoGridStateManager? stateManager;

  List<PurchaseOrder> _filterOrders(List<PurchaseOrder> orders) {
    return orders.where((order) {
      // Status filter only
      return _matchesStatus(order);
    }).toList();
  }

  bool _matchesStatus(PurchaseOrder order) {
    return _selectedStatus == 'All' ||
        (_selectedStatus == 'Active' &&
            (order.status == 'Placed' ||
                order.status == 'Partially Received')) ||
        order.status.toLowerCase() == _selectedStatus.toLowerCase();
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    switch (status.toLowerCase()) {
      case 'completed':
        color = Colors.green;
        break;
      case 'partially received':
        color = Colors.orange;
        break;
      case 'placed':
        color = Colors.blue;
        break;
      default:
        color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        border: Border.all(color: color.withOpacity(0.5)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Future<void> _exportToExcel(List<PurchaseOrder> orders) async {
    try {
      final headers = [
        'Sl No',
        'PO No',
        'PO Date',
        'Supplier',
        'Part No',
        'Description',
        'Qty',
        'Unit',
        'Cost/Unit',
        'Total Cost',
        'Pending Qty',
        'Status'
      ];

      final csvData = [headers];
      var serialNo = 1;

      for (var order in orders) {
        for (var item in order.items) {
          final rowData = <String>[];

          // Calculate pending quantity
          final orderedQty = double.tryParse(item.quantity) ?? 0.0;
          final receivedQty = item.totalReceivedQuantity;
          final pendingQty = orderedQty - receivedQty;

          rowData.add(serialNo.toString());
          rowData.add(order.poNo);
          rowData.add(order.poDate);
          rowData.add(order.supplierName);
          rowData.add(item.materialCode);
          rowData.add(item.materialDescription);
          rowData.add(item.quantity);
          rowData.add(item.unit);
          rowData.add(item.costPerUnit);
          rowData.add(item.totalCost);
          rowData.add(pendingQty.toString());
          rowData.add(order.status);

          csvData.add(rowData);
          serialNo++;
        }
      }

      final csvString = const ListToCsvConverter().convert(csvData);

      // Get the documents directory
      final directory = await getApplicationDocumentsDirectory();
      final now = DateTime.now();
      final fileName =
          'purchase_orders_${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}_${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}.csv';
      final filePath = '${directory.path}/$fileName';

      // Save the file
      final file = File(filePath);
      await file.writeAsString(csvString);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('PO Report exported successfully to $filePath'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to export PO report: $e'),
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
            items:
                ['Active', 'Placed', 'Partially Received', 'Completed', 'All']
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
          'Export Purchase Order Report',
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
    final orders = ref.read(purchaseOrderListProvider);
    _exportToExcel(orders);
  }

  void _showFilterDialog() {
    DateTime? startDate;
    DateTime? endDate;
    String supplierFilter = '';
    String partNumberFilter = '';
    String statusFilter = 'All';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: Colors.grey[850],
          title: Text(
            'Filter Purchase Orders',
            style: TextStyle(color: Colors.grey[200]),
          ),
          content: SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  decoration: InputDecoration(
                    labelText: 'Status',
                    labelStyle: TextStyle(color: Colors.grey[300]),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    fillColor: Colors.grey[800],
                    filled: true,
                  ),
                  style: const TextStyle(color: Colors.white),
                  dropdownColor: Colors.grey[800],
                  value: statusFilter,
                  items: [
                    'All',
                    'Active',
                    'Placed',
                    'Partially Received',
                    'Completed'
                  ]
                      .map((status) => DropdownMenuItem(
                            value: status,
                            child: Text(status,
                                style: const TextStyle(color: Colors.white)),
                          ))
                      .toList(),
                  onChanged: (value) => statusFilter = value ?? 'All',
                ),
                const SizedBox(height: 16),
                TextFormField(
                  decoration: InputDecoration(
                    labelText: 'Supplier',
                    labelStyle: TextStyle(color: Colors.grey[300]),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    fillColor: Colors.grey[800],
                    filled: true,
                  ),
                  style: const TextStyle(color: Colors.white),
                  onChanged: (value) => supplierFilter = value,
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
                _exportWithFilters(startDate, endDate, supplierFilter,
                    partNumberFilter, statusFilter);
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
      String supplierFilter, String partNumberFilter, String statusFilter) {
    final allOrders = ref.read(purchaseOrderListProvider);

    // Apply filters
    final filteredOrders = allOrders.where((order) {
      // Status filter
      if (statusFilter != 'All') {
        if (statusFilter == 'Active' && order.status == 'Completed')
          return false;
        if (statusFilter != 'Active' && order.status != statusFilter)
          return false;
      }

      // Date filter
      if (startDate != null) {
        final orderDate = DateTime.parse(order.poDate);
        if (orderDate.isBefore(startDate)) return false;
      }
      if (endDate != null) {
        final orderDate = DateTime.parse(order.poDate);
        if (orderDate.isAfter(endDate)) return false;
      }

      // Supplier filter
      if (supplierFilter.isNotEmpty) {
        if (!order.supplierName
            .toLowerCase()
            .contains(supplierFilter.toLowerCase())) {
          return false;
        }
      }

      // Part number/description filter
      if (partNumberFilter.isNotEmpty) {
        bool hasMatch = false;
        for (var item in order.items) {
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

    _exportToExcel(filteredOrders);
  }

  Widget _buildPOCard(PurchaseOrder order, int index) {
    final isExpanded = _expandedPOs.contains(order.poNo);
    final isFullyExpanded = _fullyExpandedPOs.contains(order.poNo);

    // Get only PRs that are actually referenced in this PO's items
    final relatedPRs = ref
        .watch(purchaseRequestListProvider)
        .where((pr) => order.items.any((poItem) =>
            poItem.prDetails.values.any((detail) => detail.prNo == pr.prNo)))
        .toList();

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      color: Colors.grey[850],
      child: Column(
        children: [
          ListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            dense: true,
            title: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  order.poNo,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 8),
                _buildStatusBadge(order.status),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Supplier: ${order.supplierName}',
                    style: TextStyle(fontSize: 13, color: Colors.grey[300]),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  NumberFormat.currency(
                    symbol: '₹',
                    locale: 'en_IN',
                    decimalDigits: 2,
                  ).format(order.grandTotal),
                  style: TextStyle(fontSize: 13, color: Colors.grey[300]),
                ),
              ],
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Date: ${order.poDate}',
                  style: TextStyle(fontSize: 12, color: Colors.grey[400]),
                ),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(Icons.picture_as_pdf, color: Colors.grey[300]),
                  iconSize: 20,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 32,
                    minHeight: 32,
                  ),
                  onPressed: () => _showPDFOptions(order),
                  tooltip: 'Generate PDF',
                ),
                IconButton(
                  icon: Icon(Icons.delete, color: Colors.grey[300]),
                  iconSize: 20,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 32,
                    minHeight: 32,
                  ),
                  onPressed: () =>
                      _showDeleteConfirmation(context, ref, index, order),
                ),
                IconButton(
                  icon: Icon(
                    !isExpanded
                        ? Icons.expand_more
                        : (isFullyExpanded
                            ? Icons.expand_less
                            : Icons.more_horiz),
                    color: Colors.grey[300],
                  ),
                  iconSize: 20,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 32,
                    minHeight: 32,
                  ),
                  onPressed: () {
                    setState(() {
                      if (!isExpanded) {
                        _expandedPOs.add(order.poNo);
                        _fullyExpandedPOs.remove(order.poNo);
                      } else if (!isFullyExpanded) {
                        _fullyExpandedPOs.add(order.poNo);
                      } else {
                        _expandedPOs.remove(order.poNo);
                        _fullyExpandedPOs.remove(order.poNo);
                      }
                    });
                  },
                ),
              ],
            ),
          ),
          if (isExpanded) ...[
            Divider(height: 0, thickness: 1, color: Colors.grey[700]),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Items',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  if (!isFullyExpanded) ...[
                    ...order.items.map((item) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Row(
                            children: [
                              Expanded(
                                flex: 3,
                                child: Text(
                                  item.materialDescription,
                                  style: TextStyle(
                                      fontSize: 12, color: Colors.grey[300]),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '${item.quantity} ${item.unit}',
                                style: TextStyle(
                                    fontSize: 12, color: Colors.grey[300]),
                              ),
                            ],
                          ),
                        )),
                  ] else ...[
                    ...order.items.map((item) => Card(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          color: Colors.grey[900],
                          child: Padding(
                            padding: const EdgeInsets.all(8),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.materialDescription,
                                  style: const TextStyle(
                                      fontSize: 12, color: Colors.white),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Quantity: ${item.quantity} ${item.unit}',
                                      style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[300]),
                                    ),
                                    Text(
                                      'Rate: ₹${item.costPerUnit}',
                                      style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[300]),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Total Cost: ₹${item.totalCost}',
                                      style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[300]),
                                    ),
                                  ],
                                ),
                                if (item.prDetails.isNotEmpty) ...[
                                  const SizedBox(height: 8),
                                  const Divider(),
                                  const SizedBox(height: 4),
                                  Text(
                                    'PR References:',
                                    style: TextStyle(
                                        fontSize: 12, color: Colors.grey[400]),
                                  ),
                                  const SizedBox(height: 4),
                                  ...item.prDetails.entries.map(
                                    (entry) => Text(
                                      entry.key == 'General'
                                          ? 'General Stock (${entry.value.quantity} ${item.unit})'
                                          : '${entry.value.prNo} (Job: ${entry.value.jobNo}) - ${entry.value.quantity} ${item.unit}',
                                      style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[300]),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        )),
                    if (relatedPRs.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      const Text(
                        'Related Purchase Requests',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...relatedPRs.map((pr) => Card(
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            color: Colors.grey[800],
                            child: ListTile(
                              title: Text(
                                pr.prNo == 'General'
                                    ? 'General Stock'
                                    : 'PR No: ${pr.prNo}${pr.jobNo != null && pr.jobNo!.isNotEmpty ? ' (Job: ${pr.jobNo})' : ''}',
                                style: TextStyle(
                                    fontSize: 13, color: Colors.grey[300]),
                              ),
                              subtitle: Text(
                                'Status: ${pr.status}',
                                style: TextStyle(
                                    fontSize: 12, color: Colors.grey[400]),
                              ),
                              trailing: Text(
                                'Items: ${pr.items.length}',
                                style: TextStyle(
                                    fontSize: 12, color: Colors.grey[400]),
                              ),
                            ),
                          )),
                    ],
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showDeleteConfirmation(
      BuildContext context, WidgetRef ref, int index, PurchaseOrder order) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[850],
        title: Text('Delete Purchase Order',
            style: TextStyle(color: Colors.grey[200])),
        content: Text(
          'Are you sure you want to delete purchase order ${order.poNo}?',
          style: TextStyle(color: Colors.grey[200]),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: Colors.grey[200])),
          ),
          FilledButton(
            onPressed: () async {
              final success = await ref
                  .read(purchaseOrderListProvider.notifier)
                  .deleteOrder(order);
              Navigator.pop(context);

              if (success) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Purchase order ${order.poNo} deleted successfully',
                      style: const TextStyle(color: Colors.black),
                    ),
                    backgroundColor: Colors.white,
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Cannot delete PO ${order.poNo} - It has received items',
                      style: const TextStyle(color: Colors.black),
                    ),
                    backgroundColor: Colors.white,
                  ),
                );
              }
            },
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showPDFOptions(PurchaseOrder order) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[850],
        title: Text(
          'Generate PDF for ${order.poNo}',
          style: TextStyle(color: Colors.grey[200]),
        ),
        content: Text(
          'Choose how to save the PDF:',
          style: TextStyle(color: Colors.grey[200]),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: Colors.grey[200])),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _generateAndSaveToDownloads(order);
            },
            child:
                Text('Quick Save', style: TextStyle(color: Colors.grey[200])),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _generateAndSavePDF(order);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
            ),
            child: const Text('Choose Location'),
          ),
        ],
      ),
    );
  }

  Future<void> _generateAndSavePDF(PurchaseOrder order) async {
    try {
      final suppliers = ref.read(supplierListProvider);
      final supplier = suppliers.firstWhere(
        (s) => s.name == order.supplierName,
        orElse: () =>
            throw Exception('Supplier not found: ${order.supplierName}'),
      );

      // Show loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Center(
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.grey[850],
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 16),
                Text(
                  'Preparing PDF...',
                  style: TextStyle(color: Colors.grey[200]),
                ),
              ],
            ),
          ),
        ),
      );

      final success = await PDFService.savePurchaseOrder(order, supplier);

      Navigator.pop(context); // Close loading dialog

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('PDF saved successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Save cancelled by user'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      Navigator.pop(context); // Close loading dialog
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving PDF: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _generateAndSaveToDownloads(PurchaseOrder order) async {
    try {
      final suppliers = ref.read(supplierListProvider);
      final supplier = suppliers.firstWhere(
        (s) => s.name == order.supplierName,
        orElse: () =>
            throw Exception('Supplier not found: ${order.supplierName}'),
      );

      // Show loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Center(
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.grey[850],
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 16),
                Text(
                  'Saving to Downloads...',
                  style: TextStyle(color: Colors.grey[200]),
                ),
              ],
            ),
          ),
        ),
      );

      final success =
          await PDFService.savePurchaseOrderToDownloads(order, supplier);

      Navigator.pop(context); // Close loading dialog

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(Platform.isMacOS || Platform.isIOS
                ? 'PDF saved to Documents folder successfully!'
                : 'PDF saved to Downloads folder successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to save PDF to Downloads'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      Navigator.pop(context); // Close loading dialog
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving PDF: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final purchaseOrders = ref.watch(purchaseOrderListProvider);
    final filteredOrders = _filterOrders(purchaseOrders);

    return Scaffold(
      backgroundColor: Colors.grey[900],
      appBar: AppBar(
        title: const Text('Purchase Orders'),
        elevation: 0,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: _buildExportButton(),
          ),
          Expanded(
            child: filteredOrders.isEmpty
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
                          'No purchase orders found',
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
                              builder: (_) => const AddPurchaseOrderPage(),
                            ),
                          ),
                          child: const Text('Add New Order'),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: filteredOrders.length,
                    padding: const EdgeInsets.only(bottom: 72),
                    itemBuilder: (context, index) {
                      final order = filteredOrders[index];
                      return _buildPOCard(
                        order,
                        purchaseOrders.indexOf(order),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AddPurchaseOrderPage()),
        ),
        icon: const Icon(Icons.add),
        label: const Text('New PO'),
      ),
    );
  }
}
