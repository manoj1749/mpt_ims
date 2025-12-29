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
import 'add_customer_free_issue_page.dart';

class CustomerFreeIssueListPage extends ConsumerStatefulWidget {
  const CustomerFreeIssueListPage({super.key});

  @override
  ConsumerState<CustomerFreeIssueListPage> createState() => _CustomerFreeIssueListPageState();
}

class _CustomerFreeIssueListPageState extends ConsumerState<CustomerFreeIssueListPage> {
  late final List<PlutoColumn> columns;
  PlutoGridStateManager? stateManager;
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
    ];
  }

  @override
  void dispose() {
    _fromQtyController!.dispose();
    _toQtyController!.dispose();
    super.dispose();
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

  @override
  Widget build(BuildContext context) {
    final requests = ref.watch(purchaseRequestListProvider);
    final purchaseOrders = ref.watch(purchaseOrderListProvider);

    return Scaffold(
      backgroundColor: Colors.grey[900],
      appBar: AppBar(
        title: const Text('Customer Free Issue List'),
        elevation: 0,
      ),
      body: Padding(
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
      floatingActionButton: FloatingActionButton(
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
      ),
    );
  }
}
