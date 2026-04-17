// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pluto_grid/pluto_grid.dart';
import 'package:collection/collection.dart';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import '../../provider/purchase_request_provider.dart';
import '../../provider/purchase_order.dart';
import '../../provider/store_inward_provider.dart';
import '../../provider/supplier_provider.dart';
import '../../provider/bill_of_preparation_provider.dart';
import '../../models/purchase_request.dart';
import '../../models/purchase_order.dart';
import '../../models/store_inward.dart';
import '../../models/bill_of_preparation.dart';
import '../../models/pr_item.dart';
import '../../services/pdf_service.dart';
import '../../widgets/pluto_grid_configuration.dart';
import 'add_purchase_request_page.dart';
import 'package:dropdown_button2/dropdown_button2.dart';

class PurchaseRequestListPage extends ConsumerStatefulWidget {
  const PurchaseRequestListPage({super.key});

  @override
  ConsumerState<PurchaseRequestListPage> createState() =>
      _PurchaseRequestListPageState();
}

class _PurchaseRequestListPageState
    extends ConsumerState<PurchaseRequestListPage>
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
  final TextEditingController _dropdownSearchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

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
              ref.read(purchaseOrderListProvider),
              ref.read(storeInwardProvider)));
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
              ref.read(purchaseOrderListProvider),
              ref.read(storeInwardProvider)));
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
          return MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onSecondaryTapDown: (details) {
                // Extract PO numbers from the poDetails string
                final poNumbers = poDetails
                    .split('\n')
                    .where((line) => line.trim().isNotEmpty && !line.contains('('))
                    .map((line) => line.trim())
                    .toList();
                
                if (poNumbers.isNotEmpty) {
                  _showPOContextMenu(context, details.globalPosition, poNumbers);
                }
              },
              child: Container(
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
          final partNo = rendererContext.row.cells['partNo']?.value as String;
          final description =
              rendererContext.row.cells['description']?.value as String;
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
                  icon: Icon(Icons.delete, color: Colors.grey[200], size: 20),
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
    _fromQtyController?.dispose();
    _toQtyController?.dispose();
    _dropdownSearchController.dispose();
    super.dispose();
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

      // Get accessible directory and create MPT_IMS folder structure
      Directory? baseDirectory;
      if (Platform.isAndroid) {
        baseDirectory = Directory('/storage/emulated/0/Download');
      } else {
        // For other platforms, try downloads first, fallback to documents
        try {
          baseDirectory = await getDownloadsDirectory();
        } catch (e) {
          baseDirectory = await getApplicationDocumentsDirectory();
        }
      }

      if (baseDirectory == null) {
        throw Exception('Unable to access storage directory');
      }

      final mptImsDirectory = Directory('${baseDirectory.path}/MPT_IMS');
      final reportDirectory =
          Directory('${mptImsDirectory.path}/Purchase_Requests');

      if (!await mptImsDirectory.exists()) {
        await mptImsDirectory.create(recursive: true);
      }
      if (!await reportDirectory.exists()) {
        await reportDirectory.create(recursive: true);
      }

      final now = DateTime.now();
      final fileName =
          'purchase_requests_${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}_${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}.csv';
      final filePath = '${reportDirectory.path}/$fileName';

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

  Widget _buildHeader() {
    final allRequests = ref.read(purchaseRequestListProvider);
    // Filter out CFI PRs for autocomplete options
    final requests = allRequests.where((pr) => !pr.prNo.startsWith('CFI')).toList();
    final purchaseOrders = ref.read(purchaseOrderListProvider);
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
                // Update controller text when switching modes
                _fromQtyController?.text = '';
                _toQtyController?.text = '';
                if (stateManager != null) {
                  stateManager!.removeAllRows();
                  stateManager!.appendRows(_getRows(
                      ref.read(purchaseRequestListProvider),
                      ref.read(purchaseOrderListProvider),
                      ref.read(storeInwardProvider)));
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
                child: Builder(
                  builder: (context) {
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

                    return DropdownButtonHideUnderline(
                      child: DropdownButton2<String>(
                        isExpanded: true,
                        hint: Text(
                          _getSearchLabel(),
                          style: const TextStyle(color: Colors.white70),
                          overflow: TextOverflow.ellipsis,
                        ),
                        items: opts
                            .map((item) => DropdownMenuItem<String>(
                                  value: item,
                                  child: Text(
                                    item,
                                    style: const TextStyle(color: Colors.white),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ))
                            .toList(),
                        value: _searchQuery.isEmpty ? null : _searchQuery,
                        onChanged: (value) {
                          if (value == null) return;
                          setState(() => _searchQuery = value);
                          if (stateManager != null) {
                            stateManager!.removeAllRows();
                            stateManager!.appendRows(_getRows(
                                ref.read(purchaseRequestListProvider),
                                ref.read(purchaseOrderListProvider),
                                ref.read(storeInwardProvider)));
                          }
                        },
                        buttonStyleData: ButtonStyleData(
                          height: 52,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: Colors.grey[800],
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: Colors.grey[600]!),
                          ),
                        ),
                        dropdownStyleData: DropdownStyleData(
                          maxHeight: 320,
                          decoration: BoxDecoration(
                            color: Colors.grey[850],
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        dropdownSearchData: DropdownSearchData(
                          searchController: _dropdownSearchController,
                          searchInnerWidgetHeight: 56,
                          searchInnerWidget: Container(
                            height: 56,
                            padding: const EdgeInsets.all(8),
                            child: TextField(
                              controller: _dropdownSearchController,
                              style: const TextStyle(color: Colors.white),
                              decoration: InputDecoration(
                                hintText: 'Search...',
                                hintStyle: const TextStyle(color: Colors.white54),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(6),
                                  borderSide: BorderSide(color: Colors.grey[600]!),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(6),
                                  borderSide: const BorderSide(color: Colors.blue),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 8),
                              ),
                            ),
                          ),
                          searchMatchFn: (item, searchValue) {
                            return (item.value ?? '')
                                .toLowerCase()
                                .contains(searchValue.toLowerCase());
                          },
                        ),
                        onMenuStateChange: (isOpen) {
                          if (!isOpen) {
                            _dropdownSearchController.clear();
                          }
                        },
                      ),
                    );
                  },
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
                      stateManager!.appendRows(_getRows(
                          ref.read(purchaseRequestListProvider),
                          ref.read(purchaseOrderListProvider),
                          ref.read(storeInwardProvider)));
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
                decoration: InputDecoration(
                  labelText: 'From Date',
                  border: const OutlineInputBorder(),
                  suffixIcon: _startDate != null
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            setState(() => _startDate = null);
                            if (stateManager != null) {
                              stateManager!.removeAllRows();
                              stateManager!.appendRows(_getRows(
                                  ref.read(purchaseRequestListProvider),
                                  ref.read(purchaseOrderListProvider),
                                  ref.read(storeInwardProvider)));
                            }
                          },
                        )
                      : null,
                ),
                controller: TextEditingController(text: _startDate == null ? '' : _startDate!.toIso8601String().split('T').first),
                onTap: () async {
                  final picked = await showDatePicker(context: context, initialDate: _startDate ?? DateTime.now(), firstDate: DateTime(2000), lastDate: DateTime(2100));
                  if (picked != null) {
                    setState(() => _startDate = DateTime(picked.year, picked.month, picked.day));
                    if (stateManager != null) {
                      stateManager!.removeAllRows();
                      stateManager!.appendRows(_getRows(
                          ref.read(purchaseRequestListProvider),
                          ref.read(purchaseOrderListProvider),
                          ref.read(storeInwardProvider)));
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
                decoration: InputDecoration(
                  labelText: 'To Date',
                  border: const OutlineInputBorder(),
                  suffixIcon: _endDate != null
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            setState(() => _endDate = null);
                            if (stateManager != null) {
                              stateManager!.removeAllRows();
                              stateManager!.appendRows(_getRows(
                                  ref.read(purchaseRequestListProvider),
                                  ref.read(purchaseOrderListProvider),
                                  ref.read(storeInwardProvider)));
                            }
                          },
                        )
                      : null,
                ),
                controller: TextEditingController(text: _endDate == null ? '' : _endDate!.toIso8601String().split('T').first),
                onTap: () async {
                  final picked = await showDatePicker(context: context, initialDate: _endDate ?? DateTime.now(), firstDate: DateTime(2000), lastDate: DateTime(2100));
                  if (picked != null) {
                    setState(() => _endDate = DateTime(picked.year, picked.month, picked.day));
                    if (stateManager != null) {
                      stateManager!.removeAllRows();
                      stateManager!.appendRows(_getRows(
                          ref.read(purchaseRequestListProvider),
                          ref.read(purchaseOrderListProvider),
                          ref.read(storeInwardProvider)));
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
                    stateManager!.appendRows(_getRows(
                        ref.read(purchaseRequestListProvider),
                        ref.read(purchaseOrderListProvider),
                        ref.read(storeInwardProvider)));
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
                    stateManager!.appendRows(_getRows(
                        ref.read(purchaseRequestListProvider),
                        ref.read(purchaseOrderListProvider),
                        ref.read(storeInwardProvider)));
                  }
                },
              ),
            ),
            const Spacer(),
            FilledButton.icon(onPressed: _showExportOptions, icon: const Icon(Icons.download), label: const Text('Export')),
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
    final allRequests = ref.read(purchaseRequestListProvider);
    // Filter out CFI PRs from export
    final requests = allRequests.where((pr) => !pr.prNo.startsWith('CFI')).toList();
    final purchaseOrders = ref.read(purchaseOrderListProvider);
    final storeInwards = ref.read(storeInwardProvider);
    _exportToExcel(requests, purchaseOrders, storeInwards);
  }

  void _showFilterDialog() {
    DateTime? startDate;
    DateTime? endDate;
    String jobNumberFilter = '';
    String partNumberFilter = '';
    double? fromQty;
    double? toQty;

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
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        decoration: InputDecoration(
                          labelText: 'From Qty',
                          labelStyle: TextStyle(color: Colors.grey[300]),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          fillColor: Colors.grey[800],
                          filled: true,
                        ),
                        style: const TextStyle(color: Colors.white),
                        keyboardType: TextInputType.number,
                        onChanged: (value) {
                          fromQty = value.isEmpty ? null : double.tryParse(value);
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        decoration: InputDecoration(
                          labelText: 'To Qty',
                          labelStyle: TextStyle(color: Colors.grey[300]),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          fillColor: Colors.grey[800],
                          filled: true,
                        ),
                        style: const TextStyle(color: Colors.white),
                        keyboardType: TextInputType.number,
                        onChanged: (value) {
                          toQty = value.isEmpty ? null : double.tryParse(value);
                        },
                      ),
                    ),
                  ],
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
                    startDate, endDate, jobNumberFilter, partNumberFilter, fromQty, toQty);
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

  void _exportWithFilters(
    DateTime? startDate,
    DateTime? endDate,
    String jobNumberFilter,
    String partNumberFilter,
    double? fromQty,
    double? toQty,
  ) {
    final allRequests = ref.read(purchaseRequestListProvider);
    final purchaseOrders = ref.read(purchaseOrderListProvider);
    final storeInwards = ref.read(storeInwardProvider);

    // Apply filters
    final filteredRequests = allRequests.where((request) {
      // Exclude CFI PRs - they should only show in Customer Free Issue List
      if (request.prNo.startsWith('CFI')) return false;
      
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
      if (partNumberFilter.isNotEmpty || fromQty != null || toQty != null) {
        final q = partNumberFilter.toLowerCase();
        bool hasMatch = false;

        for (var item in request.items) {
          final matchesPart = partNumberFilter.isEmpty ||
              item.materialCode.toLowerCase().contains(q) ||
              item.materialDescription.toLowerCase().contains(q);

          final itemQty = double.tryParse(item.quantity) ?? 0.0;
          final matchesQty = (fromQty == null || itemQty >= fromQty) &&
              (toQty == null || itemQty <= toQty);

          if (matchesPart && matchesQty) {
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
    // Apply status and date filters
    var filteredRequests = requests.where((pr) {
      // Exclude CFI PRs - they should only show in Customer Free Issue List
      if (pr.prNo.startsWith('CFI')) return false;
      
      if (_selectedStatus == 'Active' && pr.status == 'Completed') return false;
      if (_selectedStatus != 'All' &&
          _selectedStatus != 'Active' &&
          pr.status != _selectedStatus) return false;
      // Date filter on PR date
      try {
        final prDate = DateTime.parse(pr.date);
        if (_startDate != null && prDate.isBefore(_startDate!)) return false;
        if (_endDate != null && prDate.isAfter(_endDate!)) return false;
      } catch (_) {}
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
          final matchesJob = (request.jobNo ?? '').toLowerCase().contains(_searchQuery.toLowerCase());
          if (!matchesJob) continue;
        }

        // Apply quantity filter (works with any search mode)
        if (_fromQty != null || _toQty != null) {
          final itemQty = double.tryParse(item.quantity) ?? 0.0;
          final matchesQty = (_fromQty == null || itemQty >= _fromQty!) &&
                             (_toQty == null || itemQty <= _toQty!);
          if (!matchesQty) continue;
        }

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
                : 'Pending';

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
    BuildContext context,
    WidgetRef ref,
    PurchaseRequest request,
    PRItem item,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[850],
        title: Text('Delete Purchase Request',
            style: TextStyle(color: Colors.grey[200])),
        content: Text(
          'Choose delete option for PR ${request.prNo}:\n\nItem: ${item.materialCode} - ${item.materialDescription}',
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
                  final storeInwards = ref.read(storeInwardProvider);
                  stateManager!.removeAllRows();
                  stateManager!.appendRows(
                      _getRows(requests, purchaseOrders, storeInwards));
                }

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Item removed from PR ${request.prNo}',
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
            child: const Text('Delete PR'),
          ),
        ],
      ),
    );
  }

  void _showPOContextMenu(BuildContext context, Offset position, List<String> poNumbers) {
    showMenu(
      context: context,
      position: RelativeRect.fromLTRB(
        position.dx,
        position.dy,
        position.dx + 1,
        position.dy + 1,
      ),
      items: [
        if (poNumbers.length == 1) ...[
          PopupMenuItem(
            child: Row(
              children: [
                Icon(Icons.copy, size: 18, color: Colors.grey[300]),
                const SizedBox(width: 8),
                const Text('Copy PO Number'),
              ],
            ),
            onTap: () => _copyPONumber(poNumbers.first),
          ),
          PopupMenuItem(
            child: Row(
              children: [
                Icon(Icons.picture_as_pdf, size: 18, color: Colors.grey[300]),
                const SizedBox(width: 8),
                const Text('Open PDF'),
              ],
            ),
            onTap: () => _openPOPDF(poNumbers.first),
          ),
        ] else ...[
          PopupMenuItem(
            enabled: false,
            child: Text(
              'Select PO:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey[400],
              ),
            ),
          ),
          ...poNumbers.map((poNo) => PopupMenuItem(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Divider(height: 1),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Text(poNo),
                ),
              ],
            ),
            onTap: () {
              // Show submenu for this PO
              Future.delayed(const Duration(milliseconds: 100), () {
                _showPOContextMenu(context, position, [poNo]);
              });
            },
          )),
        ],
      ],
    );
  }

  void _copyPONumber(String poNumber) {
    Clipboard.setData(ClipboardData(text: poNumber));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('PO Number "$poNumber" copied to clipboard'),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _openPOPDF(String poNumber) async {
    try {
      final purchaseOrders = ref.read(purchaseOrderListProvider);
      final po = purchaseOrders.firstWhereOrNull((p) => p.poNo == poNumber);
      
      if (po == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Purchase Order $poNumber not found'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final suppliers = ref.read(supplierListProvider);
      final supplier = suppliers.firstWhereOrNull((s) => s.name == po.supplierName);
      
      if (supplier == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Supplier not found for PO $poNumber'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

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
                  'Opening PDF...',
                  style: TextStyle(color: Colors.grey[200]),
                ),
              ],
            ),
          ),
        ),
      );

      final success = await PDFService.savePurchaseOrderToDownloads(po, supplier);

      Navigator.pop(context); // Close loading dialog

      if (success) {
        // Construct the file path
        Directory? baseDirectory;
        try {
          baseDirectory = await getDownloadsDirectory();
        } catch (e) {
          baseDirectory = await getApplicationDocumentsDirectory();
        }

        final poTypeDirectoryName = po.isServiceBill ? 'Service_Bill_PO' : 'Material_PO';
        final filePath =
            '${baseDirectory?.path}/MPT_IMS/Purchase_Orders/$poTypeDirectoryName/PurchaseOrder_$poNumber.pdf';
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('PDF for $poNumber saved and opened'),
            backgroundColor: Colors.green,
          ),
        );
        
        // Auto-open the PDF
        try {
          final file = File(filePath);
          if (await file.exists()) {
            // Open the file with default PDF viewer
            await Process.run('cmd', ['/c', 'start', '', filePath], runInShell: true);
          }
        } catch (e) {
          print('Error opening PDF: $e');
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to save PDF'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      Navigator.pop(context); // Close loading dialog if still open
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error opening PDF: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildBopTab(List<BillOfPreparation> bops) {
    // Collect all BOP materials with source == 'material_master'
    final bopItems = <Map<String, dynamic>>[];
    for (final bop in bops) {
      for (final mat in bop.materials) {
        if (mat.materialSource == 'material_master') {
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
              'Materials added to Bills of Preparation with source\n"Material Master" will appear here for approval.',
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
                              color: Colors.orange.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: Colors.orange.withOpacity(0.5)),
                            ),
                            child: const Text(
                              'Material Master',
                              style: TextStyle(color: Colors.orange, fontSize: 12),
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
                        builder: (_) => AddPurchaseRequestPage(
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
    final storeInwards = ref.watch(storeInwardProvider);
    final bops = ref.watch(billOfPreparationProvider);

    return Scaffold(
      backgroundColor: Colors.grey[900],
      appBar: AppBar(
        title: const Text('Purchase Requests'),
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: 'Purchase Requests (${requests.where((pr) => !pr.prNo.startsWith('CFI')).length})'),
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('BOP Materials'),
                  const SizedBox(width: 6),
                  Builder(builder: (ctx) {
                    final count = bops.fold<int>(0, (sum, b) => sum + b.materials.where((m) => m.materialSource == 'material_master').length);
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
        actions: [
          // Add refresh button
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () async {
              try {
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (context) => const Center(
                    child: CircularProgressIndicator(),
                  ),
                );

                await Future.wait([
                  ref.read(purchaseRequestListProvider.notifier).refresh(),
                  ref.read(purchaseOrderListProvider.notifier).refresh(),
                  ref.read(storeInwardProvider.notifier).refresh(),
                ]);

                if (mounted) {
                  Navigator.pop(context); // close loading
                }

                if (stateManager != null) {
                  final requests = ref.read(purchaseRequestListProvider);
                  final purchaseOrders = ref.read(purchaseOrderListProvider);
                  final storeInwards = ref.read(storeInwardProvider);
                  stateManager!.removeAllRows();
                  stateManager!.appendRows(
                      _getRows(requests, purchaseOrders, storeInwards));
                }

                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Refreshed from server'),
                      backgroundColor: Colors.grey[850],
                      duration: const Duration(seconds: 1),
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  Navigator.pop(context); // close loading if open
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Refresh failed: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            tooltip: 'Refresh Page',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Tab 1: Regular Purchase Requests
          requests.where((pr) => !pr.prNo.startsWith('CFI')).isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.shopping_cart_outlined, size: 64, color: Colors.grey[300]),
                      const SizedBox(height: 16),
                      Text('No purchase requests found', style: TextStyle(fontSize: 18, color: Colors.grey[600])),
                      const SizedBox(height: 8),
                      FilledButton(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const AddPurchaseRequestPage(existingRequest: null, index: null)),
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
                        '${requests.where((pr) => !pr.prNo.startsWith('CFI')).length} Purchase Requests',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 16),
                      _buildHeader(),
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
          // Tab 2: BOP Materials
          _buildBopTab(bops),
        ],
      ),
      floatingActionButton: AnimatedBuilder(
        animation: _tabController,
        builder: (context, _) {
          if (_tabController.index != 0) return const SizedBox.shrink();
          return FloatingActionButton(
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
              if (stateManager != null) {
                final requests = ref.read(purchaseRequestListProvider);
                final purchaseOrders = ref.read(purchaseOrderListProvider);
                final storeInwards = ref.read(storeInwardProvider);
                stateManager!.removeAllRows();
                stateManager!.appendRows(_getRows(requests, purchaseOrders, storeInwards));
              }
            },
            child: const Icon(Icons.add),
          );
        },
      ),
    );
  }
}
