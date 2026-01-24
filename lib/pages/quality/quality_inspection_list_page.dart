// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:pluto_grid/pluto_grid.dart';
import 'package:path_provider/path_provider.dart';
import 'package:csv/csv.dart';
import 'dart:io';
import 'dart:async';
import 'package:dropdown_button2/dropdown_button2.dart';
import '../../models/quality_inspection.dart';
import '../../provider/quality_inspection_provider.dart';
import '../../provider/universal_parameter_provider.dart';
import 'add_quality_inspection_page.dart';
import '../../widgets/pluto_grid_configuration.dart';

class QualityInspectionListPage extends ConsumerStatefulWidget {
  const QualityInspectionListPage({super.key});

  @override
  ConsumerState<QualityInspectionListPage> createState() =>
      _QualityInspectionListPageState();
}

class _QualityInspectionListPageState
    extends ConsumerState<QualityInspectionListPage> {
  PlutoGridStateManager? stateManager;

  int _gridRebuildToken = 0;
  Timer? _refreshDebounce;

  String _searchMode = 'all';
  String _searchQuery = '';
  final TextEditingController _dropdownSearchController =
      TextEditingController();

  void _navigateToAddInspection(BuildContext context) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AddQualityInspectionPage(),
      ),
    );
    if (stateManager != null) {
      final inspections = ref.read(qualityInspectionProvider);
      stateManager!.removeAllRows();
      stateManager!.appendRows(_getRows(inspections));
    }

  }

  @override
  void dispose() {
    _refreshDebounce?.cancel();
    _dropdownSearchController.dispose();
    super.dispose();
  }

  void _scheduleGridRefresh() {
    _refreshDebounce?.cancel();
    _refreshDebounce = Timer(const Duration(milliseconds: 180), () {
      if (!mounted) return;
      setState(() {
        _gridRebuildToken++;
      });
    });
  }

  String _getSearchLabel() {
    switch (_searchMode) {
      case 'inspectionNo':
        return 'Search Inspection No';
      case 'grnNo':
        return 'Search GRN No';
      case 'poNo':
        return 'Search PO No';
      case 'billNo':
        return 'Search Bill No';
      case 'billDate':
        return 'Search Bill Date';
      case 'grDate':
        return 'Search GR Date';
      case 'receivedDate':
        return 'Search Received Date';
      case 'supplier':
        return 'Search Supplier';
      case 'part':
        return 'Search Part No';
      default:
        return 'Search';
    }
  }

  Widget _buildHeader(List<QualityInspection> inspections) {
    final inspectionNoOptions = {
      for (final i in inspections) i.inspectionNo,
    }.where((v) => v.trim().isNotEmpty).toList()
      ..sort();

    final grnNoOptions = {
      for (final i in inspections) i.grnNo,
    }.where((v) => v.trim().isNotEmpty).toList()
      ..sort();

    final poNoOptions = {
      for (final i in inspections) i.poNo,
    }.where((v) => v.trim().isNotEmpty).toList()
      ..sort();

    final billNoOptions = {
      for (final i in inspections) i.billNo,
    }.where((v) => v.trim().isNotEmpty).toList()
      ..sort();

    final billDateOptions = {
      for (final i in inspections) i.billDate,
    }.where((v) => v.trim().isNotEmpty).toList()
      ..sort();

    final grDateOptions = {
      for (final i in inspections) i.grnDate,
    }.where((v) => v.trim().isNotEmpty).toList()
      ..sort();

    final receivedDateOptions = {
      for (final i in inspections)
        if (i.items.isNotEmpty) i.items.first.receivedDate,
    }.where((v) => v.trim().isNotEmpty).toList()
      ..sort();

    final supplierOptions = {
      for (final i in inspections) i.supplierName,
    }.where((v) => v.trim().isNotEmpty).toList()
      ..sort();

    final partOptions = {
      for (final i in inspections)
        if (i.items.isNotEmpty) i.items.first.materialCode,
    }.where((v) => v.trim().isNotEmpty).toList()
      ..sort();

    List<String> optionsForMode() {
      switch (_searchMode) {
        case 'inspectionNo':
          return inspectionNoOptions;
        case 'grnNo':
          return grnNoOptions;
        case 'poNo':
          return poNoOptions;
        case 'billNo':
          return billNoOptions;
        case 'billDate':
          return billDateOptions;
        case 'grDate':
          return grDateOptions;
        case 'receivedDate':
          return receivedDateOptions;
        case 'supplier':
          return supplierOptions;
        case 'part':
          return partOptions;
        default:
          return [];
      }
    }

    Widget buildSearchableDropdown(List<String> options) {
      return DropdownButtonHideUnderline(
        child: DropdownButton2<String>(
          isExpanded: true,
          hint: Text(
            _getSearchLabel(),
            style: const TextStyle(color: Colors.white70),
            overflow: TextOverflow.ellipsis,
          ),
          items: options
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
            _scheduleGridRefresh();
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
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
    }

    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.grey[900],
      child: Row(
        children: [
          const Text('Search Mode:', style: TextStyle(color: Colors.white)),
          const SizedBox(width: 12),
          ToggleButtons(
            isSelected: [
              _searchMode == 'all',
              _searchMode == 'inspectionNo',
              _searchMode == 'grnNo',
              _searchMode == 'poNo',
              _searchMode == 'billNo',
              _searchMode == 'billDate',
              _searchMode == 'grDate',
              _searchMode == 'receivedDate',
              _searchMode == 'supplier',
              _searchMode == 'part',
            ],
            onPressed: (index) {
              setState(() {
                _searchMode = [
                  'all',
                  'inspectionNo',
                  'grnNo',
                  'poNo',
                  'billNo',
                  'billDate',
                  'grDate',
                  'receivedDate',
                  'supplier',
                  'part',
                ][index];
                _searchQuery = '';
              });
              _scheduleGridRefresh();
            },
            children: const [
              Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: Text('All')),
              Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: Text('Insp')),
              Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: Text('GRN')),
              Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: Text('PO')),
              Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: Text('Bill No')),
              Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: Text('Bill Date')),
              Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: Text('GR Date')),
              Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: Text('Rec Date')),
              Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: Text('Supplier')),
              Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: Text('Part')),
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
              width: 360,
              child: buildSearchableDropdown(optionsForMode()),
            ),
        ],
      ),
    );
  }

  Future<void> _exportToExcel() async {
    try {
      final exportRows = _getRows(ref.read(qualityInspectionProvider));

      final baseColumns = _getColumns()
          .where((col) => col.field != 'actions')
          .where((col) => col.field != 'inspection')
          .where((col) => col.field != 'parameters')
          .toList();

      final parameterNames = <String>{};
      for (final row in exportRows) {
        final inspection = row.cells['inspection']!.value as QualityInspection;
        if (inspection.items.isEmpty) continue;
        for (final p in inspection.items.first.parameters) {
          if (p.parameter.trim().isNotEmpty) {
            parameterNames.add(p.parameter.trim());
          }
        }
      }
      final parameterColumns = parameterNames.toList()..sort();

      final headers = [
        ...baseColumns.map((c) => c.title),
        ...parameterColumns,
      ];

      final csvData = <List<String>>[headers];

      for (final row in exportRows) {
        final rowData = <String>[];
        for (final col in baseColumns) {
          rowData.add(row.cells[col.field]?.value.toString() ?? '');
        }

        final inspection = row.cells['inspection']!.value as QualityInspection;
        final observationsByParam = <String, String>{};
        if (inspection.items.isNotEmpty) {
          for (final p in inspection.items.first.parameters) {
            final key = p.parameter.trim();
            if (key.isEmpty) continue;
            observationsByParam[key] = (p.observation ?? '').toString();
          }
        }

        for (final paramName in parameterColumns) {
          rowData.add(observationsByParam[paramName] ?? '');
        }

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
          Directory('${mptImsDirectory.path}/Quality_Inspections');

      if (!await mptImsDirectory.exists()) {
        await mptImsDirectory.create(recursive: true);
      }
      if (!await reportDirectory.exists()) {
        await reportDirectory.create(recursive: true);
      }

      final now = DateTime.now();
      final fileName =
          'quality_inspections_${now.year}${now.month}${now.day}_${now.hour}${now.minute}.csv';
      final filePath = '${reportDirectory.path}/$fileName';

      final file = File(filePath);
      await file.writeAsString(csvString);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Report exported successfully to $filePath'),
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

  List<PlutoColumn> _getColumns() {
    ref.watch(universalParameterProvider);

    return [
      PlutoColumn(
        title: 'GRN No',
        field: 'grnNo',
        type: PlutoColumnType.text(),
        width: 120,
        enableEditingMode: false,
      ),
      PlutoColumn(
        title: 'PO No',
        field: 'poNo',
        type: PlutoColumnType.text(),
        width: 120,
        enableEditingMode: false,
      ),
      PlutoColumn(
        title: 'Supplier',
        field: 'supplier',
        type: PlutoColumnType.text(),
        width: 150,
        enableEditingMode: false,
      ),
      PlutoColumn(
        title: 'Part No',
        field: 'partNo',
        type: PlutoColumnType.text(),
        width: 120,
        enableEditingMode: false,
      ),
      PlutoColumn(
        title: 'Description',
        field: 'description',
        type: PlutoColumnType.text(),
        width: 200,
        enableEditingMode: false,
      ),
      PlutoColumn(
        title: 'Received Qty',
        field: 'receivedQty',
        type: PlutoColumnType.number(),
        width: 120,
        enableEditingMode: false,
      ),
      PlutoColumn(
        title: 'Accepted Qty',
        field: 'acceptedQty',
        type: PlutoColumnType.number(),
        width: 120,
        enableEditingMode: false,
      ),
      PlutoColumn(
        title: 'Rejected Qty',
        field: 'rejectedQty',
        type: PlutoColumnType.number(),
        width: 120,
        enableEditingMode: false,
      ),
      PlutoColumn(
        title: 'Pending Qty',
        field: 'pendingQty',
        type: PlutoColumnType.number(),
        width: 120,
        enableEditingMode: false,
      ),
      PlutoColumn(
        title: 'Usage Decision',
        field: 'usageDecision',
        type: PlutoColumnType.text(),
        width: 150,
        enableEditingMode: false,
        renderer: (rendererContext) {
          final item = rendererContext.row.cells['inspection']!.value
              as QualityInspection;
          final inspItem = item.items.first;
          // Get the usage decision from GRN quantities
          String displayText = '';
          Color? textColor;

          if (inspItem.grnQuantities.isNotEmpty) {
            // First check if it's a direct rejection or acceptance
            if (inspItem.usageDecision == 'Rejected') {
              displayText = 'Rejected';
              textColor = Colors.red;
            } else if (inspItem.usageDecision == 'Lot Accepted') {
              displayText = 'Lot Accepted';
              textColor = Colors.green;
            }
            // Only show recheck statuses if it was actually a recheck case
            else if (inspItem.usageDecision == '100% Recheck') {
              displayText = '100% Recheck';
              if (inspItem.recheckType != null) {
                displayText += ' - ${inspItem.recheckType}';
              }
              textColor = Colors.orange;
            } else if (inspItem.usageDecision ==
                'Accepted After 100% Recheck') {
              displayText = 'Accepted After 100% Recheck';
              textColor = Colors.green;
            } else if (inspItem.usageDecision ==
                'Partially Accepted After 100% Recheck') {
              displayText = 'Partially Accepted After 100% Recheck';
              textColor = Colors.orange;
            }
          } else {
            // Fallback to inspection item's usage decision
            displayText = inspItem.usageDecision;
            if (displayText == 'Lot Accepted') {
              textColor = Colors.green;
            } else if (displayText == 'Rejected') {
              textColor = Colors.red;
            }
          }

          // Add CAPA Required if applicable
          if (inspItem.capaRequired == true) {
            displayText += ' - CAPA Required';
            textColor = Colors.red;
          }

          return Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              displayText,
              style: TextStyle(
                fontSize: 12,
                color: textColor,
                fontWeight: textColor != null ? FontWeight.bold : null,
              ),
            ),
          );
        },
      ),
      PlutoColumn(
        title: 'Unit',
        field: 'unit',
        type: PlutoColumnType.text(),
        width: 80,
        enableEditingMode: false,
      ),
      PlutoColumn(
        title: 'Cost/Unit',
        field: 'costPerUnit',
        type: PlutoColumnType.number(),
        width: 120,
        enableEditingMode: false,
        renderer: (rendererContext) {
          final value = rendererContext.cell.value as num;
          return Text('₹${value.toStringAsFixed(2)}');
        },
      ),
      PlutoColumn(
        title: 'Total Cost',
        field: 'totalCost',
        type: PlutoColumnType.number(),
        width: 120,
        enableEditingMode: false,
        renderer: (rendererContext) {
          final value = rendererContext.cell.value as num;
          return Text('₹${value.toStringAsFixed(2)}');
        },
      ),
      PlutoColumn(
        title: 'Bill No',
        field: 'billNo',
        type: PlutoColumnType.text(),
        width: 120,
        enableEditingMode: false,
      ),
      PlutoColumn(
        title: 'Bill Date',
        field: 'billDate',
        type: PlutoColumnType.text(),
        width: 120,
        enableEditingMode: false,
      ),
      PlutoColumn(
        title: 'Received Date',
        field: 'receivedDate',
        type: PlutoColumnType.text(),
        width: 120,
        enableEditingMode: false,
      ),
      PlutoColumn(
        title: 'GR Date',
        field: 'grDate',
        type: PlutoColumnType.text(),
        width: 120,
        enableEditingMode: false,
      ),
      PlutoColumn(
        title: 'Category',
        field: 'category',
        type: PlutoColumnType.text(),
        width: 120,
        enableEditingMode: false,
      ),
      PlutoColumn(
        title: 'Sample Size',
        field: 'sampleSize',
        type: PlutoColumnType.number(),
        width: 120,
        enableEditingMode: false,
      ),
      PlutoColumn(
        title: 'Expiry Date',
        field: 'expiryDate',
        type: PlutoColumnType.text(),
        width: 120,
        enableEditingMode: false,
        renderer: (rendererContext) {
          final item = rendererContext.row.cells['inspection']!.value
              as QualityInspection;
          final expiryDate = item.items.first.expirationDate;

          if (expiryDate.isEmpty) {
            return const Text('-');
          }

          return Text(expiryDate);
        },
      ),
      PlutoColumn(
        title: 'Parameters',
        field: 'parameters',
        type: PlutoColumnType.text(),
        width: 200,
        enableEditingMode: false,
        renderer: (rendererContext) {
          final item = rendererContext.row.cells['inspection']!.value
              as QualityInspection;
          final parameters = item.items.first.parameters;

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: parameters.map((param) {
                return Row(
                  children: [
                    Expanded(
                      child: Text(
                        param.parameter,
                        style: const TextStyle(fontSize: 12),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Icon(
                      param.isAcceptable ? Icons.check_circle : Icons.cancel,
                      color: param.isAcceptable ? Colors.green : Colors.red,
                      size: 16,
                    ),
                  ],
                );
              }).toList(),
            ),
          );
        },
      ),
      PlutoColumn(
        title: 'Actions',
        field: 'actions',
        type: PlutoColumnType.text(),
        width: 100,
        enableEditingMode: false,
        renderer: (rendererContext) {
          final inspection = rendererContext.row.cells['inspection']!.value
              as QualityInspection;

          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.delete_outline, size: 20),
                onPressed: () {
                  _showDeleteConfirmation(context, ref, inspection);
                },
                color: Colors.red[400],
                tooltip: 'Delete',
                constraints: const BoxConstraints(
                  minWidth: 32,
                  minHeight: 32,
                ),
              ),
            ],
          );
        },
      ),
    ];
  }

  List<PlutoRow> _getRows(List<QualityInspection> inspections) {
    final rows = <PlutoRow>[];

    for (var inspection in inspections) {
      if (_searchMode != 'all' && _searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final item = inspection.items.isNotEmpty ? inspection.items.first : null;
        switch (_searchMode) {
          case 'inspectionNo':
            if (!inspection.inspectionNo.toLowerCase().contains(q)) continue;
            break;
          case 'grnNo':
            if (!inspection.grnNo.toLowerCase().contains(q)) continue;
            break;
          case 'poNo':
            if (!inspection.poNo.toLowerCase().contains(q)) continue;
            break;
          case 'billNo':
            if (!inspection.billNo.toLowerCase().contains(q)) continue;
            break;
          case 'billDate':
            if (!inspection.billDate.toLowerCase().contains(q)) continue;
            break;
          case 'grDate':
            if (!inspection.grnDate.toLowerCase().contains(q)) continue;
            break;
          case 'receivedDate':
            if (item == null || !item.receivedDate.toLowerCase().contains(q)) {
              continue;
            }
            break;
          case 'supplier':
            if (!inspection.supplierName.toLowerCase().contains(q)) continue;
            break;
          case 'part':
            if (item == null || !item.materialCode.toLowerCase().contains(q)) {
              continue;
            }
            break;
        }
      }

      // Skip if no items
      if (inspection.items.isEmpty) continue;

      final item = inspection.items.first;

      // Calculate total quantities from all GRNs
      double totalAcceptedQty = 0.0;
      double totalRejectedQty = 0.0;
      for (var grnQty in item.grnQuantities.values) {
        totalAcceptedQty += grnQty.acceptedQty;
        totalRejectedQty += grnQty.rejectedQty;
      }

      // Calculate pending quantity
      double pendingQty =
          item.receivedQty - (totalAcceptedQty + totalRejectedQty);

      String usageDecision = item.usageDecision;
      if (item.grnQuantities.isNotEmpty) {
        final grnQty = item.grnQuantities.values.first;
        // Use the GRN's usage decision directly instead of checking quantities
        usageDecision = grnQty.usageDecision;
      }

      rows.add(
        PlutoRow(
          cells: {
            'inspection': PlutoCell(value: inspection),
            'grnNo': PlutoCell(value: inspection.grnNo),
            'poNo': PlutoCell(value: inspection.poNo),
            'supplier': PlutoCell(value: inspection.supplierName),
            'partNo': PlutoCell(value: item.materialCode),
            'description': PlutoCell(value: item.materialDescription),
            'receivedQty': PlutoCell(value: item.receivedQty),
            'acceptedQty': PlutoCell(value: totalAcceptedQty),
            'rejectedQty': PlutoCell(value: totalRejectedQty),
            'pendingQty': PlutoCell(value: pendingQty),
            'usageDecision': PlutoCell(value: usageDecision),
            'unit': PlutoCell(value: item.unit),
            'costPerUnit': PlutoCell(value: item.costPerUnit),
            'totalCost': PlutoCell(value: item.totalCost),
            'billNo': PlutoCell(value: inspection.billNo),
            'billDate': PlutoCell(value: inspection.billDate),
            'receivedDate': PlutoCell(value: item.receivedDate),
            'grDate': PlutoCell(value: inspection.grnDate),
            'category': PlutoCell(value: item.category),
            'sampleSize': PlutoCell(value: item.sampleSize),
            'expiryDate': PlutoCell(value: item.expirationDate),
            'parameters': PlutoCell(value: item.parameters),
            'actions': PlutoCell(value: ''),
          },
        ),
      );
    }

    return rows;
  }

  void _showDeleteConfirmation(
    BuildContext context,
    WidgetRef ref,
    QualityInspection inspection,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Inspection'),
        content: Text(
          'Are you sure you want to delete inspection ${inspection.inspectionNo}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              // Attempt to delete the inspection
              final success = await ref
                  .read(qualityInspectionProvider.notifier)
                  .deleteInspection(inspection);
              Navigator.pop(context);

              if (success) {
                // Refresh grid rows
                if (stateManager != null) {
                  final inspections = ref.read(qualityInspectionProvider);
                  stateManager!.removeAllRows();
                  stateManager!.appendRows(_getRows(inspections));
                }

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Inspection deleted successfully'),
                    duration: Duration(seconds: 2),
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                        'Cannot delete inspection ${inspection.inspectionNo} - Quality inspections cannot be deleted once created'),
                    backgroundColor: Colors.red,
                    duration: const Duration(seconds: 3),
                  ),
                );
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final inspections = ref.watch(qualityInspectionProvider);
    // Debug: Print all quality inspections when data is loaded
    if (inspections.isNotEmpty) {
      print('==== ALL Quality Inspections (from provider) ====');
      for (var inspection in inspections) {
        print(inspection.toString());
      }
      print('==== END Quality Inspections ====');
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Quality Inspection List'),
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToAddInspection(context),
        child: const Icon(Icons.add),
      ),
      body: inspections.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.fact_check_outlined,
                    size: 64,
                    color: Colors.grey[300],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No quality inspections yet',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  FilledButton(
                    onPressed: () => _navigateToAddInspection(context),
                    child: const Text('Add New Inspection'),
                  ),
                ],
              ),
            )
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(inspections),
                  const SizedBox(height: 16),
                  Expanded(
                    child: Card(
                      elevation: 2,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: PlutoGrid(
                          key: ValueKey(_gridRebuildToken),
                          columns: _getColumns(),
                          rows: _getRows(inspections),
                          onLoaded: (PlutoGridOnLoadedEvent event) {
                            stateManager = event.stateManager;
                            stateManager?.setShowColumnFilter(true);
                          },
                          configuration: PlutoGridConfigurations.darkMode(),
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
