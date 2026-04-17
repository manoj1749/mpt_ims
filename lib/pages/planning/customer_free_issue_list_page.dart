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
import '../../provider/bill_of_preparation_provider.dart';
import '../../models/purchase_request.dart';
import '../../models/purchase_order.dart';
import '../../models/store_inward.dart';
import '../../models/bill_of_preparation.dart';
import '../../models/pr_item.dart';
import '../../widgets/pluto_grid_configuration.dart';
import 'add_customer_free_issue_page.dart';

class CustomerFreeIssueListPage extends ConsumerStatefulWidget {
  const CustomerFreeIssueListPage({super.key});

  @override
  ConsumerState<CustomerFreeIssueListPage> createState() => _CustomerFreeIssueListPageState();
}

class _CustomerFreeIssueListPageState extends ConsumerState<CustomerFreeIssueListPage>
    with SingleTickerProviderStateMixin {
  late final List<PlutoColumn> columns;
  PlutoGridStateManager? stateManager;
  late TabController _tabController;
  String _selectedStatus = 'Active'; // Default to Active view
  String _searchMode = 'all'; // 'all', 'part', 'supplier', 'description', 'job', 'qty'
  String _searchQuery = '';
  double? _fromQty;
  double? _toQty;
  DateTime? _startDate;
  DateTime? _endDate;

  // Controllers for quantity inputs to prevent focus loss
  TextEditingController? _fromQtyController;
  TextEditingController? _toQtyController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    Future.microtask(() async {
      try {
        await ref.read(purchaseRequestListProvider.notifier).loadData();
      } catch (_) {}
      try {
        await ref.read(purchaseOrderListProvider.notifier).loadData();
      } catch (_) {}

      if (!mounted) return;
      if (stateManager != null) {
        stateManager!.removeAllRows();
        stateManager!.appendRows(_getRows(
          ref.read(purchaseRequestListProvider),
          ref.read(purchaseOrderListProvider),
        ));
      } else {
        setState(() {});
      }
    });

    // Initialize controllers
    _fromQtyController = TextEditingController(text: _fromQty?.toString() ?? '');
    _toQtyController = TextEditingController(text: _toQty?.toString() ?? '');

    // Add listeners to update state variables when text changes
    _fromQtyController!.addListener(() {
      final value = _fromQtyController!.text;
      _fromQty = value.isEmpty ? null : double.tryParse(value);
      // Refresh grid when quantity changes (defer to next frame)
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (stateManager != null) {
          stateManager!.removeAllRows();
          stateManager!.appendRows(_getRows(
              ref.read(purchaseRequestListProvider),
              ref.read(purchaseOrderListProvider)));
        }
      });
    });

    _toQtyController!.addListener(() {
      final value = _toQtyController!.text;
      _toQty = value.isEmpty ? null : double.tryParse(value);
      // Refresh grid when quantity changes (defer to next frame)
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (stateManager != null) {
          stateManager!.removeAllRows();
          stateManager!.appendRows(_getRows(
              ref.read(purchaseRequestListProvider),
              ref.read(purchaseOrderListProvider)));
        }
      });
    });

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
        title: 'CFI No',
        field: 'prNo',
        type: PlutoColumnType.text(),
        width: 140,
        backgroundColor: Colors.grey[850],
        titleTextAlign: PlutoColumnTextAlign.center,
        textAlign: PlutoColumnTextAlign.center,
        enableEditingMode: false,
      ),
      PlutoColumn(
        title: 'Date',
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
        width: 240,
        backgroundColor: Colors.grey[850],
        titleTextAlign: PlutoColumnTextAlign.center,
        textAlign: PlutoColumnTextAlign.start,
        enableEditingMode: false,
      ),
      PlutoColumn(
        title: 'Qty',
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
        width: 140,
        backgroundColor: Colors.grey[850],
        titleTextAlign: PlutoColumnTextAlign.center,
        textAlign: PlutoColumnTextAlign.center,
        enableEditingMode: false,
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
              child: Text('-', style: TextStyle(color: Colors.grey[200])),
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
        width: 120,
        backgroundColor: Colors.grey[850],
        titleTextAlign: PlutoColumnTextAlign.center,
        textAlign: PlutoColumnTextAlign.center,
        enableEditingMode: false,
        renderer: (rendererContext) {
          final prNo = rendererContext.row.cells['prNo']?.value as String;
          final partNo = rendererContext.row.cells['partNo']?.value as String;
          final description = rendererContext.row.cells['description']?.value as String;
          final unit = rendererContext.row.cells['unit']?.value as String;
          final prQtyVal = rendererContext.row.cells['prQty']?.value;
          final prQty = prQtyVal is num ? prQtyVal.toString() : prQtyVal.toString();
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
                  icon: Icon(Icons.edit, color: Colors.blue[200], size: 20),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AddCustomerFreeIssuePage(
                          existingRequest: request,
                          index: null,
                        ),
                      ),
                    ).then((_) {
                      // Refresh grid after returning from edit
                      if (stateManager != null) {
                        final requests = ref.read(purchaseRequestListProvider);
                        final purchaseOrders = ref.read(purchaseOrderListProvider);
                        stateManager!.removeAllRows();
                        stateManager!.appendRows(_getRows(requests, purchaseOrders));
                      }
                    });
                  },
                ),
              ),
              SizedBox(
                width: 40,
                height: 40,
                child: IconButton(
                  padding: EdgeInsets.zero,
                  icon: Icon(Icons.delete, color: Colors.red[200], size: 20),
                  onPressed: () {
                    final item = PRItem(
                      materialCode: partNo,
                      materialDescription: description,
                      unit: unit,
                      quantity: prQty,
                      prNo: prNo,
                    );
                    _showDeleteConfirmation(context, ref, request, item);
                  },
                ),
              ),
            ],
          );
        },
      ),
    ];
  }

  @override
  void dispose() {
    _tabController.dispose();
    _fromQtyController!.dispose();
    _toQtyController!.dispose();
    super.dispose();
  }

  void _showDeleteConfirmation(
    BuildContext context,
    WidgetRef ref,
    PurchaseRequest request,
    PRItem item,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[850],
        title: Text('Delete Customer Free Issue',
            style: TextStyle(color: Colors.grey[200])),
        content: Text(
          'Choose delete option for CFI ${request.prNo}:\n\nItem: ${item.materialCode} - ${item.materialDescription}',
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
                  .deleteRequestItem(request, item);
              Navigator.pop(context);

              if (success) {
                if (stateManager != null) {
                  final requests = ref.read(purchaseRequestListProvider);
                  final purchaseOrders = ref.read(purchaseOrderListProvider);
                  stateManager!.removeAllRows();
                  stateManager!.appendRows(
                      _getRows(requests, purchaseOrders));
                }

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Item removed from CFI ${request.prNo}',
                      style: const TextStyle(color: Colors.white),
                    ),
                    backgroundColor: Colors.black,
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Cannot delete item - it has active Purchase Orders',
                      style: const TextStyle(color: Colors.black),
                    ),
                    backgroundColor: Colors.white,
                  ),
                );
              }
            },
            child: const Text('Delete Item'),
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
                  stateManager!.removeAllRows();
                  stateManager!.appendRows(
                      _getRows(requests, purchaseOrders));
                }

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Customer Free Issue ${request.prNo} deleted successfully',
                      style: const TextStyle(color: Colors.white),
                    ),
                    backgroundColor: Colors.black,
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Cannot delete CFI ${request.prNo} - It has active Purchase Orders',
                      style: const TextStyle(color: Colors.black),
                    ),
                    backgroundColor: Colors.white,
                  ),
                );
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete CFI'),
          ),
        ],
      ),
    );
  }

  List<PlutoRow> _getRows(
    List<PurchaseRequest> allRequests,
    List<PurchaseOrder> purchaseOrders,
  ) {
    // Only include CFI entries (prNo starting with CFI)
    final base = allRequests.where((r) => r.prNo.startsWith('CFI')).toList();
    // Apply status and date filters on requests
    final requests = base.where((pr) {
      if (_selectedStatus == 'Active' && pr.status == 'Completed') return false;
      if (_selectedStatus != 'All' && _selectedStatus != 'Active' && pr.status != _selectedStatus) return false;
      try {
        final prDate = DateTime.parse(pr.date);
        if (_startDate != null && prDate.isBefore(_startDate!)) return false;
        if (_endDate != null && prDate.isAfter(_endDate!)) return false;
      } catch (_) {}
      return true;
    }).toList();

    // Apply status filter only
    var filteredRequests = requests.where((pr) {
      if (_selectedStatus == 'Active' && pr.status == 'Completed') return false;
      if (_selectedStatus != 'All' && _selectedStatus != 'Active' && pr.status != _selectedStatus) return false;
      return true;
    }).toList();

    final rows = <PlutoRow>[];
    var serialNo = 1;

    for (var request in filteredRequests) {
      for (var item in request.items) {
        // Part/Supplier search filters
        if (_searchMode == 'part' && _searchQuery.isNotEmpty) {
          final matchesPart = item.materialCode.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              item.materialDescription.toLowerCase().contains(_searchQuery.toLowerCase());
          if (!matchesPart) continue;
        }

        final totalOrderedQty = item.totalOrderedQuantity;

        final relatedPOs = purchaseOrders
            .where((po) => po.items.any((poItem) =>
                poItem.materialCode == item.materialCode &&
                poItem.prDetails.values.any((detail) => detail.prNo == request.prNo)))
            .map((po) => '${po.poNo}\n(${po.poDate})')
            .join('\n\n');

        String _getFallbackJobNo() {
          for (final po in purchaseOrders) {
            for (final poItem in po.items) {
              if (poItem.materialCode != item.materialCode) continue;
              for (final detail in poItem.prDetails.values) {
                if (detail.prNo == request.prNo) {
                  final j = detail.jobNo.trim();
                  if (j.isNotEmpty) return j;
                }
              }
            }
          }
          return '-';
        }

        final displayJobNo = (request.jobNo ?? '').trim().isNotEmpty
            ? request.jobNo!.trim()
            : _getFallbackJobNo();

        if (_searchMode == 'supplier' && _searchQuery.isNotEmpty) {
          final matchesSupplier = purchaseOrders.any((po) =>
              po.supplierName.toLowerCase().contains(_searchQuery.toLowerCase()) &&
              po.items.any((poItem) => poItem.materialCode == item.materialCode &&
                  poItem.prDetails.values.any((d) => d.prNo == request.prNo)));
          if (!matchesSupplier) continue;
        }

        if (_searchMode == 'description' && _searchQuery.isNotEmpty) {
          final matchesDesc = item.materialDescription.toLowerCase().contains(_searchQuery.toLowerCase());
          if (!matchesDesc) continue;
        }

        if (_searchMode == 'job' && _searchQuery.isNotEmpty) {
          final matchesJob = displayJobNo
              .toLowerCase()
              .contains(_searchQuery.toLowerCase());
          if (!matchesJob) continue;
        }

        // Apply quantity filter (works with any search mode)
        if (_fromQty != null || _toQty != null) {
          final itemQty = double.tryParse(item.quantity) ?? 0.0;
          final matchesQty = (_fromQty == null || itemQty >= _fromQty!) &&
                             (_toQty == null || itemQty <= _toQty!);
          if (!matchesQty) continue;
        }

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
              'jobNo': PlutoCell(value: displayJobNo),
              'prNo': PlutoCell(value: request.prNo),
              'prDate': PlutoCell(value: request.date),
              'partNo': PlutoCell(value: item.materialCode),
              'description': PlutoCell(value: item.materialDescription),
              'prQty': PlutoCell(value: double.parse(item.quantity)),
              'unit': PlutoCell(value: item.unit),
              'requestedBy': PlutoCell(value: request.requiredBy),
              'poDetails': PlutoCell(value: relatedPOs.isEmpty ? '-' : relatedPOs),
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

  Future<void> _exportToExcel(List<PurchaseRequest> allRequests, List<PurchaseOrder> purchaseOrders) async {
    try {
      final requests = allRequests.where((r) => r.prNo.startsWith('CFI')).toList();
      final headers = [
        'Sl.No',
        'Job No',
        'CFI No',
        'Date',
        'Part No',
        'Description',
        'Qty',
        'Unit',
        'Requested By',
        'PO No & Date',
        'PO Qty',
        'Pending Qty',
        'Status'
      ];

      final rows = _getRows(requests, purchaseOrders);
      final csvData = [headers];

      for (var row in rows) {
        final rowData = <String>[];
        rowData.add(row.cells['serialNo']?.value.toString() ?? '');
        rowData.add(row.cells['jobNo']?.value.toString() ?? '');
        rowData.add(row.cells['prNo']?.value.toString() ?? '');
        rowData.add(row.cells['prDate']?.value.toString() ?? '');
        rowData.add(row.cells['partNo']?.value.toString() ?? '');
        rowData.add(row.cells['description']?.value.toString() ?? '');
        rowData.add(row.cells['prQty']?.value.toString() ?? '');
        rowData.add(row.cells['unit']?.value.toString() ?? '');
        rowData.add(row.cells['requestedBy']?.value.toString() ?? '');
        rowData.add(row.cells['poDetails']?.value.toString().replaceAll('\n', '; ') ?? '');
        rowData.add(row.cells['orderedQty']?.value.toString() ?? '');
        rowData.add(row.cells['pendingQty']?.value.toString() ?? '');
        rowData.add(row.cells['status']?.value.toString() ?? '');
        csvData.add(rowData);
      }

      final csvString = const ListToCsvConverter().convert(csvData);
      final directory = await getApplicationDocumentsDirectory();
      final now = DateTime.now();
      final fileName =
          'customer_free_issues_${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}_${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}.csv';
      final filePath = '${directory.path}/$fileName';

      final file = File(filePath);
      await file.writeAsString(csvString);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Customer Free Issue report exported to $filePath'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to export report: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildHeader(List<PurchaseRequest> requests, List<PurchaseOrder> purchaseOrders) {
    // Build dynamic autocomplete options
    final partOptions = {
      for (final r in requests) ...r.items.map((i) => i.materialCode)
    }.toList()
      ..sort();
    final supplierOptions = {
      for (final po in purchaseOrders) po.supplierName
    }.toList()
      ..sort();
    final descriptionOptions = {
      for (final r in requests) ...r.items.map((i) => i.materialDescription)
    }.toList()
      ..sort();
    final jobOptions = {
      for (final r in requests) r.jobNo ?? ''
    }.where((job) => job.isNotEmpty).toList()
      ..sort();
    final qtyOptions = {
      for (final r in requests) ...r.items.map((i) => i.quantity)
    }.toList()
      ..sort();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Row 1: Search mode + search bar
        Row(
          children: [
            const Text('Search Mode:', style: TextStyle(color: Colors.white)),
            const SizedBox(width: 12),
            ToggleButtons(
              isSelected: [
                _searchMode == 'all',
                _searchMode == 'part',
                _searchMode == 'supplier',
                _searchMode == 'description',
                _searchMode == 'job'
              ],
              onPressed: (index) {
                setState(() {
                  _searchMode = ['all', 'part', 'supplier', 'description', 'job'][index];
                  _searchQuery = '';
                  _fromQty = null;
                  _toQty = null;
                  _startDate = null;
                  _endDate = null;
                });
                _fromQtyController?.text = '';
                _toQtyController?.text = '';
                if (stateManager != null) {
                  stateManager!.removeAllRows();
                  stateManager!.appendRows(_getRows(requests, purchaseOrders));
                }
              },
              children: const [
                Padding(padding: EdgeInsets.symmetric(horizontal: 8), child: Text('All')),
                Padding(padding: EdgeInsets.symmetric(horizontal: 8), child: Text('Part')),
                Padding(padding: EdgeInsets.symmetric(horizontal: 8), child: Text('Supplier')),
                Padding(padding: EdgeInsets.symmetric(horizontal: 8), child: Text('Desc')),
                Padding(padding: EdgeInsets.symmetric(horizontal: 8), child: Text('Job')),
              ],
              borderColor: Colors.grey,
              selectedBorderColor: Colors.blue,
              selectedColor: Colors.white,
              fillColor: Colors.blueAccent,
              color: Colors.white70,
            ),
            const SizedBox(width: 16),
            if (_searchMode != 'all')
              SizedBox(
                width: 320,
                child: Autocomplete<String>(
                          optionsBuilder: (TextEditingValue tev) {
                            List<String> opts;
                            switch (_searchMode) {
                              case 'part':
                                opts = partOptions;
                                break;
                              case 'supplier':
                                opts = supplierOptions;
                                break;
                              case 'description':
                                opts = descriptionOptions;
                                break;
                              case 'job':
                                opts = jobOptions;
                                break;
                              default:
                                opts = [];
                            }
                            if (tev.text.isEmpty) return opts;
                            return opts.where((o) => o.toLowerCase().contains(tev.text.toLowerCase()));
                          },
                          onSelected: (selection) {
                            setState(() => _searchQuery = selection);
                            if (stateManager != null) {
                              stateManager!.removeAllRows();
                              stateManager!.appendRows(_getRows(requests, purchaseOrders));
                            }
                          },
                          fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) => TextField(
                            controller: controller,
                            focusNode: focusNode,
                            decoration: InputDecoration(
                              labelText: _getSearchLabel(),
                              border: const OutlineInputBorder(),
                              filled: true,
                              fillColor: Colors.grey[800],
                              labelStyle: const TextStyle(color: Colors.white),
                            ),
                            style: const TextStyle(color: Colors.white),
                            onChanged: (v) {
                              setState(() => _searchQuery = v);
                              if (stateManager != null) {
                                stateManager!.removeAllRows();
                                stateManager!.appendRows(_getRows(requests, purchaseOrders));
                              }
                            },
                          ),
                        ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Row 2: Status on left, From/To in middle, Export on right
        Row(
          children: [
            SizedBox(
              width: 220,
              child: DropdownButtonFormField<String>(
                decoration: InputDecoration(
                  labelText: 'Status Filter',
                  labelStyle: TextStyle(color: Colors.grey[300]),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  fillColor: Colors.grey[800],
                  filled: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                style: const TextStyle(color: Colors.white),
                dropdownColor: Colors.grey[800],
                value: _selectedStatus,
                items: ['Active', 'Completed', 'All']
                    .map((status) => DropdownMenuItem(value: status, child: Text(status, style: const TextStyle(color: Colors.white))))
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _selectedStatus = value);
                    if (stateManager != null) {
                      stateManager!.removeAllRows();
                      stateManager!.appendRows(_getRows(requests, purchaseOrders));
                    }
                  }
                },
              ),
            ),
            const SizedBox(width: 16),
            SizedBox(
              width: 180,
              child: TextFormField(
                readOnly: true,
                decoration: const InputDecoration(labelText: 'From Date', border: OutlineInputBorder()),
                controller: TextEditingController(text: _startDate == null ? '' : _startDate!.toIso8601String().split('T').first),
                onTap: () async {
                  final picked = await showDatePicker(context: context, initialDate: _startDate ?? DateTime.now(), firstDate: DateTime(2000), lastDate: DateTime(2100));
                  if (picked != null) {
                    setState(() => _startDate = DateTime(picked.year, picked.month, picked.day));
                    if (stateManager != null) {
                      stateManager!.removeAllRows();
                      stateManager!.appendRows(_getRows(requests, purchaseOrders));
                    }
                  }
                },
              ),
            ),
            const SizedBox(width: 12),
            SizedBox(
              width: 180,
              child: TextFormField(
                readOnly: true,
                decoration: const InputDecoration(labelText: 'To Date', border: OutlineInputBorder()),
                controller: TextEditingController(text: _endDate == null ? '' : _endDate!.toIso8601String().split('T').first),
                onTap: () async {
                  final picked = await showDatePicker(context: context, initialDate: _endDate ?? DateTime.now(), firstDate: DateTime(2000), lastDate: DateTime(2100));
                  if (picked != null) {
                    setState(() => _endDate = DateTime(picked.year, picked.month, picked.day));
                    if (stateManager != null) {
                      stateManager!.removeAllRows();
                      stateManager!.appendRows(_getRows(requests, purchaseOrders));
                    }
                  }
                },
              ),
            ),
            const SizedBox(width: 12),
            SizedBox(
              width: 120,
              child: TextFormField(
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'From Qty',
                  border: OutlineInputBorder(),
                  filled: true,
                  fillColor: Color(0xFF424242),
                  labelStyle: TextStyle(color: Colors.white),
                ),
                style: const TextStyle(color: Colors.white),
                controller: _fromQtyController,
                onChanged: (value) {
                  setState(() {
                    _fromQty = double.tryParse(value);
                  });
                  if (stateManager != null) {
                    stateManager!.removeAllRows();
                    stateManager!.appendRows(_getRows(requests, purchaseOrders));
                  }
                },
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 120,
              child: TextFormField(
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'To Qty',
                  border: OutlineInputBorder(),
                  filled: true,
                  fillColor: Color(0xFF424242),
                  labelStyle: TextStyle(color: Colors.white),
                ),
                style: const TextStyle(color: Colors.white),
                controller: _toQtyController,
                onChanged: (value) {
                  setState(() {
                    _toQty = double.tryParse(value);
                  });
                  if (stateManager != null) {
                    stateManager!.removeAllRows();
                    stateManager!.appendRows(_getRows(requests, purchaseOrders));
                  }
                },
              ),
            ),
            const Spacer(),
            FilledButton.icon(onPressed: () => _exportToExcel(requests, purchaseOrders), icon: const Icon(Icons.download), label: const Text('Export')),
          ],
        ),
      ],
    );
  }

  String _getSearchLabel() {
    switch (_searchMode) {
      case 'part':
        return 'Search Part No';
      case 'supplier':
        return 'Search Supplier';
      case 'description':
        return 'Search Description';
      case 'job':
        return 'Search Job No';
      case 'qty':
        return 'Search Quantity';
      default:
        return 'Search';
    }
  }

  Widget _buildBopTab(List<BillOfPreparation> bops) {
    final bopItems = <Map<String, dynamic>>[];
    for (final bop in bops) {
      for (final mat in bop.materials) {
        if (mat.materialSource == 'customer_scope') {
          bopItems.add({
            'jobNo': bop.jobNo,
            'materialCode': mat.materialCode,
            'materialDescription': mat.materialDescription,
            'bop': bop,
            'mat': mat,
          });
        }
      }
    }

    if (bopItems.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey[600]),
            const SizedBox(height: 16),
            Text(
              'No BOP materials pending approval',
              style: TextStyle(fontSize: 16, color: Colors.grey[400]),
            ),
            const SizedBox(height: 8),
            Text(
              'Materials added to Bills of Preparation with source\n"Customer Free Issue" will appear here for approval.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: bopItems.length,
      itemBuilder: (context, index) {
        final item = bopItems[index];
        final jobNo = item['jobNo'] as String;
        final materialCode = item['materialCode'] as String;
        final materialDescription = item['materialDescription'] as String;
        final bop = item['bop'] as BillOfPreparation;
        final mat = item['mat'] as BopMaterial;
        final finalQty = mat.cktTypes.isNotEmpty ? mat.cktTypes.first.materialQuantity : 0.0;

        return Card(
          color: Colors.grey[850],
          margin: const EdgeInsets.only(bottom: 10),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.blue.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: Colors.blue.withOpacity(0.5)),
                            ),
                            child: Text(
                              'Job: $jobNo',
                              style: const TextStyle(color: Colors.blue, fontSize: 12, fontWeight: FontWeight.w600),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.purple.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: Colors.purple.withOpacity(0.5)),
                            ),
                            child: const Text(
                              'Customer Free Issue',
                              style: TextStyle(color: Colors.purple, fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        materialCode,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        materialDescription,
                        style: TextStyle(color: Colors.grey[400], fontSize: 13),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Final Qty: ${finalQty.toStringAsFixed(2)}',
                        style: TextStyle(color: Colors.grey[300], fontSize: 12),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                FilledButton.icon(
                  onPressed: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AddCustomerFreeIssuePage(
                          existingRequest: null,
                          index: null,
                          initialJobNo: jobNo,
                          initialMaterialCode: materialCode,
                          initialMaterialDescription: materialDescription,
                          sourceBop: bop,
                          sourceBopMaterial: mat,
                        ),
                      ),
                    );
                    setState(() {});
                  },
                  icon: const Icon(Icons.check, size: 16),
                  label: const Text('Approve'),
                  style: FilledButton.styleFrom(backgroundColor: Colors.green[700]),
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  onPressed: () => _showRejectBopDialog(context, bop, mat),
                  icon: const Icon(Icons.close, size: 16),
                  label: const Text('Reject'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red[300],
                    side: BorderSide(color: Colors.red[300]!),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showRejectBopDialog(BuildContext context, BillOfPreparation bop, BopMaterial mat) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[850],
        title: Text('Reject BOP Material', style: TextStyle(color: Colors.grey[200])),
        content: Text(
          'Remove "${mat.materialCode} - ${mat.materialDescription}" from BOP for Job ${bop.jobNo}?\n\nThis will delete it from the BOP materials list.',
          style: TextStyle(color: Colors.grey[300]),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: Colors.grey[400])),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(context);
              final updatedBop = bop.copyWith(
                materials: bop.materials.where((m) => m.materialCode != mat.materialCode).toList(),
              );
              await ref.read(billOfPreparationProvider.notifier).updateBillOfPreparation(
                ref.read(billOfPreparationProvider).indexOf(bop),
                updatedBop,
                ref,
              );
              setState(() {});
            },
            child: const Text('Reject'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final requests = ref.watch(purchaseRequestListProvider);
    final purchaseOrders = ref.watch(purchaseOrderListProvider);
    final bops = ref.watch(billOfPreparationProvider);

    return Scaffold(
      backgroundColor: Colors.grey[900],
      appBar: AppBar(
        title: const Text('Customer Free Issue List'),
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: 'CFI List (${requests.where((r) => r.prNo.startsWith('CFI')).length})'),
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('BOP Materials'),
                  const SizedBox(width: 6),
                  Builder(builder: (ctx) {
                    final count = bops.fold<int>(0, (sum, b) => sum + b.materials.where((m) => m.materialSource == 'customer_scope').length);
                    if (count == 0) return const SizedBox.shrink();
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(color: Colors.orange, borderRadius: BorderRadius.circular(10)),
                      child: Text('$count', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                    );
                  }),
                ],
              ),
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Tab 1: Regular CFI list
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${requests.where((r) => r.prNo.startsWith('CFI')).length} Customer Free Issue Requests',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 16),
                _buildHeader(requests, purchaseOrders),
                const SizedBox(height: 16),
                Expanded(
                  child: PlutoGrid(
                    columns: columns,
                    rows: _getRows(requests, purchaseOrders),
                    onLoaded: (PlutoGridOnLoadedEvent event) {
                      stateManager = event.stateManager;
                    },
                    configuration: PlutoGridConfigurations.darkMode(),
                  ),
                ),
              ],
            ),
          ),
          // Tab 2: BOP Materials (Customer Free Issue source)
          _buildBopTab(bops),
        ],
      ),
      floatingActionButton: AnimatedBuilder(
        animation: _tabController,
        builder: (context, _) {
          if (_tabController.index != 0) return const SizedBox.shrink();
          return FloatingActionButton(
            tooltip: 'New CFI',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const AddCustomerFreeIssuePage(
                    existingRequest: null,
                    index: null,
                  ),
                ),
              );
            },
            child: const Icon(Icons.add),
          );
        },
      ),
    );
  }
}
