// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mpt_ims/pages/design/add_material_page.dart';
import 'package:mpt_ims/provider/material_provider.dart';
import 'package:mpt_ims/provider/supplier_provider.dart';
import 'package:mpt_ims/models/material_item.dart';

import 'package:pluto_grid/pluto_grid.dart';
import 'package:collection/collection.dart';
import 'package:file_picker/file_picker.dart';
import 'package:csv/csv.dart';
import 'dart:io';
import '../../widgets/pluto_grid_configuration.dart';
import '../../provider/stock_maintenance_provider.dart';
import '../../models/stock_maintenance.dart';

import 'dart:async';

class MaterialMasterPage extends ConsumerStatefulWidget {
  const MaterialMasterPage({super.key});

  @override
  ConsumerState<MaterialMasterPage> createState() => _MaterialMasterPageState();
}

class _MaterialMasterPageState extends ConsumerState<MaterialMasterPage> {
  PlutoGridStateManager? stateManager;
  bool _isLoading = true;

  // Track selected classification filter
  String? _selectedClassification;
  final List<String> _classifications = ['A', 'B', 'C', 'D', 'E'];

  String? _selectedCategory;
  String? _selectedSubCategory;
  DateTime? _startDate;
  DateTime? _endDate;
  String _partNoQuery = '';
  String _descriptionQuery = '';

  int _gridRebuildToken = 0;
  Timer? _refreshDebounce;

  // Search functionality
  String _searchMode = 'all'; // 'all', 'part', 'description', 'supplier', 'qty'
  String _searchQuery = '';
  double? _fromQty;
  double? _toQty;

  @override
  void initState() {
    super.initState();
    // Set loading to false after the first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _refreshDebounce?.cancel();
    super.dispose();
  }

  void _scheduleGridRefresh() {
    _refreshDebounce?.cancel();
    _refreshDebounce = Timer(const Duration(milliseconds: 180), () {
      if (!mounted) return;
      setState(() {
        _gridRebuildToken++;
      });

      if (stateManager != null) {
        final materials = ref.read(materialListProvider);
        stateManager!.removeAllRows();
        stateManager!.appendRows(_getRows(materials, ref));
      }
    });
  }

  DateTime? _getMaterialReferenceDate(MaterialItem material) {
    final preferred = material.vendorRates.firstWhereOrNull((r) => r.isPreferred);
    final rate = preferred ?? material.vendorRates.firstOrNull;
    final dateStr = rate?.lastPurchaseDate;
    if (dateStr == null || dateStr.isEmpty) return null;
    try {
      return DateTime.parse(dateStr);
    } catch (_) {
      return null;
    }
  }

  Future<void> _exportMaterialMaster() async {
    try {
      final materials = ref.read(materialListProvider);
      final rows = _getRows(materials, ref);

      final headers = [
        'SL No',
        'Date',
        'Part No',
        'Description',
        'Category',
        'Sub Category',
        'Inventory Class',
        'Unit',
        'Actual Weight',
        'Storage Location',
        'Rack Number',
        'BIN Number',
        'HSN Code',
        'Supplier Code',
        'Supplier Name',
        'Best Rate',
        '# of Vendors',
        'Sale Rate',
      ];

      final csvData = <List<String>>[headers];
      for (final row in rows) {
        csvData.add([
          row.cells['slNo']?.value.toString() ?? '',
          row.cells['date']?.value.toString() ?? '',
          row.cells['partNo']?.value.toString() ?? '',
          row.cells['description']?.value.toString() ?? '',
          row.cells['category']?.value.toString() ?? '',
          row.cells['subCategory']?.value.toString() ?? '',
          row.cells['inventoryClass']?.value.toString() ?? '',
          row.cells['unit']?.value.toString() ?? '',
          row.cells['actualWeight']?.value.toString() ?? '',
          row.cells['storageLocation']?.value.toString() ?? '',
          row.cells['rackNumber']?.value.toString() ?? '',
          row.cells['binNumber']?.value.toString() ?? '',
          row.cells['hsnCode']?.value.toString() ?? '',
          row.cells['supplierCode']?.value.toString() ?? '',
          row.cells['supplierName']?.value.toString() ?? '',
          row.cells['bestRate']?.value.toString() ?? '',
          row.cells['vendorCount']?.value.toString() ?? '',
          row.cells['saleRate']?.value.toString() ?? '',
        ]);
      }

      final csvString = const ListToCsvConverter().convert(csvData);

      String? outputFile = await FilePicker.platform.saveFile(
        dialogTitle: 'Save Material Master Export',
        fileName: 'material_master_export.csv',
        type: FileType.any,
      );

      if (outputFile == null) {
        return;
      }

      if (!outputFile.toLowerCase().endsWith('.csv')) {
        outputFile = '$outputFile.csv';
      }

      final file = File(outputFile);
      await file.writeAsString(csvString);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Material Master exported successfully to $outputFile'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to export Material Master: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildFilters(List<MaterialItem> materials) {
    final categories = {
      for (final m in materials) m.category
    }.where((c) => c.isNotEmpty).toList()
      ..sort();

    final subCategories = {
      for (final m in materials)
        if (_selectedCategory == null || m.category == _selectedCategory)
          m.subCategory
    }.where((s) => s.isNotEmpty).toList()
      ..sort();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SizedBox(
                width: 220,
                child: DropdownButtonFormField<String>(
                  value: _selectedCategory,
                  decoration: const InputDecoration(
                    labelText: 'Category',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('All')),
                    ...categories.map((c) => DropdownMenuItem(
                          value: c,
                          child: Text(c),
                        )),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedCategory = value;
                      _selectedSubCategory = null;
                    });
                    _scheduleGridRefresh();
                  },
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 220,
                child: DropdownButtonFormField<String>(
                  value: _selectedSubCategory,
                  decoration: const InputDecoration(
                    labelText: 'Sub Category',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('All')),
                    ...subCategories.map((s) => DropdownMenuItem(
                          value: s,
                          child: Text(s),
                        )),
                  ],
                  onChanged: (value) {
                    setState(() => _selectedSubCategory = value);
                    _scheduleGridRefresh();
                  },
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 220,
                child: DropdownButtonFormField<String>(
                  value: _selectedClassification,
                  decoration: const InputDecoration(
                    labelText: 'Inventory Class',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('All')),
                    ..._classifications.map((c) => DropdownMenuItem(
                          value: c,
                          child: Text(c),
                        )),
                  ],
                  onChanged: (value) {
                    setState(() => _selectedClassification = value);
                    _scheduleGridRefresh();
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
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
                              _scheduleGridRefresh();
                            },
                          )
                        : null,
                  ),
                  controller: TextEditingController(
                    text: _startDate == null
                        ? ''
                        : _startDate!.toIso8601String().split('T').first,
                  ),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _startDate ?? DateTime.now(),
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2100),
                    );
                    if (picked != null) {
                      setState(() => _startDate =
                          DateTime(picked.year, picked.month, picked.day));
                      _scheduleGridRefresh();
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
                              _scheduleGridRefresh();
                            },
                          )
                        : null,
                  ),
                  controller: TextEditingController(
                    text: _endDate == null
                        ? ''
                        : _endDate!.toIso8601String().split('T').first,
                  ),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _endDate ?? DateTime.now(),
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2100),
                    );
                    if (picked != null) {
                      setState(() => _endDate =
                          DateTime(picked.year, picked.month, picked.day));
                      _scheduleGridRefresh();
                    }
                  },
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 220,
                child: TextField(
                  decoration: const InputDecoration(
                    labelText: 'Part No',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (v) {
                    _partNoQuery = v;
                    _scheduleGridRefresh();
                  },
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 260,
                child: TextField(
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (v) {
                    _descriptionQuery = v;
                    _scheduleGridRefresh();
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _onPlutoGridLoaded(PlutoGridOnLoadedEvent event) {
    stateManager = event.stateManager;
    stateManager?.setShowColumnFilter(true);
  }

  Future<void> _downloadBulkTemplate() async {
    try {
      final headers = [
        'Part Number',
        'Description',
        'Unit',
        'Category',
        'Sub Category',
        'HSN Code',
        'Storage Location',
        'Rack Number',
        'BIN Number',
        'Actual Weight',
        'Inventory Class',
      ];
      final csvData = const ListToCsvConverter().convert([headers]);

      String? outputFile = await FilePicker.platform.saveFile(
        dialogTitle: 'Save Material Master Bulk Template',
        fileName: 'material_master_bulk_template.csv',
        type: FileType.any,
      );

      if (outputFile == null) {
        return;
      }

      if (!outputFile.toLowerCase().endsWith('.csv')) {
        outputFile = '$outputFile.csv';
      }

      final file = File(outputFile);
      await file.writeAsString(csvData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Template saved successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save template: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  List<PlutoColumn> _getColumns(BuildContext context, WidgetRef ref) {
    return [
      PlutoColumn(
        title: 'SL No',
        field: 'slNo',
        type: PlutoColumnType.text(),
        width: 100,
        enableEditingMode: false,
      ),
      PlutoColumn(
        title: 'Date',
        field: 'date',
        type: PlutoColumnType.text(),
        width: 120,
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
        title: 'Category',
        field: 'category',
        type: PlutoColumnType.text(),
        width: 120,
        enableEditingMode: false,
      ),
      PlutoColumn(
        title: 'Sub Category',
        field: 'subCategory',
        type: PlutoColumnType.text(),
        width: 120,
        enableEditingMode: false,
      ),
      PlutoColumn(
        title: 'Inventory Class',
        field: 'inventoryClass',
        type: PlutoColumnType.text(),
        width: 100,
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
        title: 'Actual Weight',
        field: 'actualWeight',
        type: PlutoColumnType.text(),
        width: 120,
        backgroundColor: Colors.grey[850],
        titleTextAlign: PlutoColumnTextAlign.center,
        textAlign: PlutoColumnTextAlign.center,
        enableEditingMode: false,
      ),
      PlutoColumn(
        title: 'Storage Location',
        field: 'storageLocation',
        type: PlutoColumnType.text(),
        width: 120,
        backgroundColor: Colors.grey[850],
        titleTextAlign: PlutoColumnTextAlign.center,
        textAlign: PlutoColumnTextAlign.center,
        enableEditingMode: false,
      ),
      PlutoColumn(
        title: 'Rack Number',
        field: 'rackNumber',
        type: PlutoColumnType.text(),
        width: 120,
        backgroundColor: Colors.grey[850],
        titleTextAlign: PlutoColumnTextAlign.center,
        textAlign: PlutoColumnTextAlign.center,
        enableEditingMode: false,
      ),
      PlutoColumn(
        title: 'BIN Number',
        field: 'binNumber',
        type: PlutoColumnType.text(),
        width: 120,
        backgroundColor: Colors.grey[850],
        titleTextAlign: PlutoColumnTextAlign.center,
        textAlign: PlutoColumnTextAlign.center,
        enableEditingMode: false,
      ),
      PlutoColumn(
        title: 'HSN Code',
        field: 'hsnCode',
        type: PlutoColumnType.text(),
        width: 120,
        backgroundColor: Colors.grey[850],
        titleTextAlign: PlutoColumnTextAlign.center,
        textAlign: PlutoColumnTextAlign.center,
        enableEditingMode: false,
      ),
      PlutoColumn(
        title: 'Supplier Code',
        field: 'supplierCode',
        type: PlutoColumnType.text(),
        width: 140,
        enableEditingMode: false,
      ),
      PlutoColumn(
        title: 'Supplier Name',
        field: 'supplierName',
        type: PlutoColumnType.text(),
        width: 180,
        enableEditingMode: false,
      ),
      PlutoColumn(
        title: 'Best Rate',
        field: 'bestRate',
        type: PlutoColumnType.text(),
        width: 120,
        enableEditingMode: false,
      ),
      PlutoColumn(
        title: '# of Vendors',
        field: 'vendorCount',
        type: PlutoColumnType.number(),
        width: 120,
        enableEditingMode: false,
      ),
      PlutoColumn(
        title: 'Sale Rate',
        field: 'saleRate',
        type: PlutoColumnType.text(),
        width: 120,
        enableEditingMode: false,
      ),
      PlutoColumn(
        title: 'Stock',
        field: 'stock',
        type: PlutoColumnType.text(),
        width: 120,
        enableEditingMode: false,
      ),
      PlutoColumn(
        title: 'Inspection Stock',
        field: 'inspectionStock',
        type: PlutoColumnType.text(),
        width: 120,
        enableEditingMode: false,
      ),
      PlutoColumn(
        title: 'Stock Value',
        field: 'stockValue',
        type: PlutoColumnType.text(),
        width: 120,
        enableEditingMode: false,
      ),
      PlutoColumn(
        title: 'Total Received',
        field: 'totalReceived',
        type: PlutoColumnType.text(),
        width: 120,
        enableEditingMode: false,
      ),
      PlutoColumn(
        title: 'Vendor Issued',
        field: 'vendorIssued',
        type: PlutoColumnType.text(),
        width: 120,
        enableEditingMode: false,
      ),
      PlutoColumn(
        title: 'Vendor Received',
        field: 'vendorReceived',
        type: PlutoColumnType.text(),
        width: 120,
        enableEditingMode: false,
      ),
      PlutoColumn(
        title: 'Board Issue',
        field: 'boardIssue',
        type: PlutoColumnType.text(),
        width: 120,
        enableEditingMode: false,
      ),
      PlutoColumn(
        title: 'Cost Diff',
        field: 'costDiff',
        type: PlutoColumnType.text(),
        width: 120,
        enableEditingMode: false,
      ),
      PlutoColumn(
        title: 'Actions',
        field: 'actions',
        type: PlutoColumnType.text(),
        width: 200,
        enableEditingMode: false,
        renderer: (rendererContext) {
          final materials = ref.read(materialListProvider);
          final material = materials
              .where((m) => m.slNo == rendererContext.row.cells['slNo']!.value)
              .firstOrNull;

          if (material == null) {
            return const SizedBox.shrink();
          }

          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.edit_outlined, size: 20),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AddMaterialPage(
                        materialToEdit: material,
                        index: materials.indexOf(material),
                      ),
                    ),
                  );
                },
                color: Colors.blue,
                tooltip: 'Edit',
                constraints: const BoxConstraints(
                  minWidth: 32,
                  minHeight: 32,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.people_outline, size: 20),
                onPressed: () => _showVendorDetails(
                  context,
                  material,
                  ref,
                ),
                tooltip: 'Vendor Details',
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, size: 20),
                onPressed: () => _confirmDelete(
                  context,
                  ref,
                  material,
                ),
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

  List<PlutoRow> _getRows(List<MaterialItem> materials, WidgetRef ref) {
    final suppliers = ref.read(supplierListProvider);

    // Filter materials by selected classification if any
    var filteredMaterials = materials;
    if (_selectedClassification != null && _selectedClassification!.isNotEmpty) {
      filteredMaterials = materials.where((m) => 
        (m.inventoryClassification ?? '') == _selectedClassification
      ).toList();
    }

    if (_selectedCategory != null && _selectedCategory!.isNotEmpty) {
      filteredMaterials = filteredMaterials
          .where((m) => m.category == _selectedCategory)
          .toList();
    }

    if (_selectedSubCategory != null && _selectedSubCategory!.isNotEmpty) {
      filteredMaterials = filteredMaterials
          .where((m) => m.subCategory == _selectedSubCategory)
          .toList();
    }

    if (_startDate != null || _endDate != null) {
      filteredMaterials = filteredMaterials.where((m) {
        final d = _getMaterialReferenceDate(m);
        if (d == null) return false;
        if (_startDate != null && d.isBefore(_startDate!)) return false;
        if (_endDate != null && d.isAfter(_endDate!)) return false;
        return true;
      }).toList();
    }

    if (_partNoQuery.isNotEmpty) {
      final q = _partNoQuery.toLowerCase();
      filteredMaterials = filteredMaterials
          .where((m) => m.partNo.toLowerCase().contains(q))
          .toList();
    }

    if (_descriptionQuery.isNotEmpty) {
      final q = _descriptionQuery.toLowerCase();
      filteredMaterials = filteredMaterials
          .where((m) => m.description.toLowerCase().contains(q))
          .toList();
    }

    // Apply search filtering
    if (_searchQuery.isNotEmpty) {
      filteredMaterials = filteredMaterials.where((m) {
        switch (_searchMode) {
          case 'part':
            return m.partNo.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                   m.slNo.toLowerCase().contains(_searchQuery.toLowerCase());
          case 'description':
            return m.description.toLowerCase().contains(_searchQuery.toLowerCase());
          case 'supplier':
            return m.getPreferredVendorName().toLowerCase().contains(_searchQuery.toLowerCase()) ||
                   m.vendorRates.any((v) => v.vendorId.toLowerCase().contains(_searchQuery.toLowerCase()));
          case 'qty':
            // For future use when quantity fields are added to Material model
            // Currently no quantity field exists in MaterialItem
            return true;
          default:
            // 'all' mode - search in part, description, and supplier
            return m.partNo.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                   m.slNo.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                   m.description.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                   m.getPreferredVendorName().toLowerCase().contains(_searchQuery.toLowerCase()) ||
                   m.vendorRates.any((v) => v.vendorId.toLowerCase().contains(_searchQuery.toLowerCase()));
        }
      }).toList();
    } else if (_searchMode == 'qty' && (_fromQty != null || _toQty != null)) {
      // Quantity range filtering (for future use when quantity fields are added)
      filteredMaterials = filteredMaterials.where((m) {
        // Currently no quantity field exists in MaterialItem to filter on
        // This is a placeholder for future implementation
        return true;
      }).toList();
    }
    
    return filteredMaterials.map((m) {
      final preferredSupplierName = m.getPreferredVendorName();
      final supplier = preferredSupplierName.isEmpty
          ? null
          : suppliers.firstWhereOrNull((s) =>
              s.name.toLowerCase() == preferredSupplierName.toLowerCase());
      final supplierCode = supplier?.vendorCode ?? '-';
      final supplierName =
          preferredSupplierName.isEmpty ? '-' : preferredSupplierName;

      final refDate = _getMaterialReferenceDate(m);
      final dateText = refDate == null ? '-' : refDate.toIso8601String().split('T').first;

      return PlutoRow(
        cells: {
          'slNo': PlutoCell(value: m.slNo),
          'date': PlutoCell(value: dateText),
          'partNo': PlutoCell(value: m.partNo),
          'description': PlutoCell(value: m.description),
          'category': PlutoCell(value: m.category),
          'subCategory': PlutoCell(value: m.subCategory),
          'inventoryClass': PlutoCell(value: (m.inventoryClassification ?? '').isEmpty ? '-' : m.inventoryClassification!),
          'unit': PlutoCell(value: m.unit),
          'actualWeight': PlutoCell(value: m.actualWeight),
          'storageLocation': PlutoCell(value: m.storageLocation),
          'rackNumber': PlutoCell(value: m.rackNumber),
          'binNumber': PlutoCell(
              value: m.binNumber?.isEmpty ?? true ? '-' : m.binNumber),
          'hsnCode':
              PlutoCell(value: m.hsnCode?.isEmpty ?? true ? '-' : m.hsnCode),
          'supplierCode': PlutoCell(value: supplierCode),
          'supplierName': PlutoCell(value: supplierName),
          'bestRate': PlutoCell(
              value: m.getLowestPurchaseRate().isEmpty
                  ? '-'
                  : '₹${m.getLowestPurchaseRate()}'),
          'vendorCount': PlutoCell(value: m.getVendorCount()),
          'saleRate':
              PlutoCell(value: m.saleRate.isEmpty ? '-' : '₹${m.saleRate}'),
          'stock':
              PlutoCell(value: '-'), // Stock info moved to stock maintenance
          'inspectionStock':
              PlutoCell(value: '-'), // Inspection stock moved to quality
          'stockValue':
              PlutoCell(value: '-'), // Stock value moved to stock maintenance
          'totalReceived': PlutoCell(value: '-'), // Moved to stock maintenance
          'vendorIssued': PlutoCell(value: '-'), // Moved to stock maintenance
          'vendorReceived': PlutoCell(value: '-'), // Moved to stock maintenance
          'boardIssue': PlutoCell(value: '-'), // Moved to stock maintenance
          'costDiff': PlutoCell(value: '-'), // Simplified structure
          'actions': PlutoCell(value: ''),
        },
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    // Watch the materials list to ensure UI updates
    final materials = ref.watch(materialListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Material Master'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh Material Master',
            onPressed: () async {
              try {
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (context) => const Center(
                    child: CircularProgressIndicator(),
                  ),
                );

                await ref.read(materialListProvider.notifier).refresh();

                if (mounted) {
                  Navigator.pop(context); // close loading
                }

                if (stateManager != null) {
                  final materials = ref.read(materialListProvider);
                  stateManager!.removeAllRows();
                  stateManager!.appendRows(_getRows(materials, ref));
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
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddMaterialPage()),
          );
        },
        child: const Icon(Icons.add),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : materials.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.inventory_2_outlined,
                        size: 64,
                        color: Colors.grey[300],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No materials yet',
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
                              builder: (_) => const AddMaterialPage()),
                        ),
                        child: const Text('Add New Material'),
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
                          Expanded(
                            child: Text(
                              '${materials.length} Materials',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ),
                          OutlinedButton.icon(
                            onPressed: _downloadBulkTemplate,
                            icon: const Icon(Icons.file_download_outlined, size: 18),
                            label: const Text('Download Template'),
                          ),
                          const SizedBox(width: 8),
                          OutlinedButton.icon(
                            onPressed: () => _showBulkUploadDialog(),
                            icon: const Icon(Icons.upload_file, size: 18),
                            label: const Text('Bulk Entry'),
                          ),
                          const SizedBox(width: 8),
                          OutlinedButton.icon(
                            onPressed: _exportMaterialMaster,
                            icon: const Icon(Icons.ios_share, size: 18),
                            label: const Text('Export'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _buildFilters(materials),
                      const SizedBox(height: 16),
                      Expanded(
                        child: PlutoGrid(
                          key: ValueKey(_gridRebuildToken),
                          columns: _getColumns(context, ref),
                          rows: _getRows(materials, ref),
                          onLoaded: _onPlutoGridLoaded,
                          configuration: PlutoGridConfigurations.darkMode(),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }

  void _showSearchDialog() {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Search Materials'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ToggleButtons(
                isSelected: [
                  _searchMode == 'all',
                  _searchMode == 'part',
                  _searchMode == 'description',
                  _searchMode == 'supplier',
                  _searchMode == 'qty',
                ],
                onPressed: (index) {
                  setDialogState(() {
                    _searchMode = ['all', 'part', 'description', 'supplier', 'qty'][index];
                  });
                },
                children: const [
                  Padding(padding: EdgeInsets.symmetric(horizontal: 8), child: Text('All')),
                  Padding(padding: EdgeInsets.symmetric(horizontal: 8), child: Text('Part No')),
                  Padding(padding: EdgeInsets.symmetric(horizontal: 8), child: Text('Description')),
                  Padding(padding: EdgeInsets.symmetric(horizontal: 8), child: Text('Supplier')),
                  Padding(padding: EdgeInsets.symmetric(horizontal: 8), child: Text('Qty')),
                ],
                borderColor: Colors.grey,
                selectedBorderColor: Colors.blue,
                selectedColor: Colors.white,
                fillColor: Colors.blueAccent,
                color: Colors.white70,
              ),
              const SizedBox(height: 16),
              _searchMode == 'qty'
                  ? Row(
                      children: [
                        Expanded(
                          child: TextField(
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'From Qty',
                              border: OutlineInputBorder(),
                            ),
                            onChanged: (value) {
                              setDialogState(() {
                                _fromQty = value.isEmpty ? null : double.tryParse(value);
                              });
                            },
                            controller: TextEditingController(text: _fromQty?.toString() ?? ''),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'To Qty',
                              border: OutlineInputBorder(),
                            ),
                            onChanged: (value) {
                              setDialogState(() {
                                _toQty = value.isEmpty ? null : double.tryParse(value);
                              });
                            },
                            controller: TextEditingController(text: _toQty?.toString() ?? ''),
                          ),
                        ),
                      ],
                    )
                  : TextField(
                      decoration: InputDecoration(
                        labelText: _getSearchLabel(),
                        border: const OutlineInputBorder(),
                      ),
                      onChanged: (value) {
                        setDialogState(() {
                          _searchQuery = value;
                        });
                      },
                      controller: TextEditingController(text: _searchQuery),
                    ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                setState(() {
                  _searchQuery = '';
                  _searchMode = 'all';
                  _fromQty = null;
                  _toQty = null;
                });
                if (stateManager != null) {
                  stateManager!.removeAllRows();
                  final materials = ref.read(materialListProvider);
                  stateManager!.appendRows(_getRows(materials, ref));
                }
                Navigator.pop(context);
              },
              child: const Text('Clear'),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  // Apply search
                });
                if (stateManager != null) {
                  stateManager!.removeAllRows();
                  final materials = ref.read(materialListProvider);
                  stateManager!.appendRows(_getRows(materials, ref));
                }
                Navigator.pop(context);
              },
              child: const Text('Search'),
            ),
          ],
        ),
      ),
    );
  }

  String _getSearchLabel() {
    switch (_searchMode) {
      case 'part':
        return 'Search Part Number';
      case 'description':
        return 'Search Description';
      case 'supplier':
        return 'Search Supplier';
      case 'qty':
        return 'Quantity Range';
      default:
        return 'Search All Fields';
    }
  }

  void _confirmDelete(
      BuildContext context, WidgetRef ref, MaterialItem material) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Material'),
        content:
            const Text('Are you sure you want to delete this material item?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton.tonal(
            onPressed: () async {
              try {
                Navigator.pop(context); // Close dialog first

                // Delete the material (vendor rates are included)
                await ref
                    .read(materialListProvider.notifier)
                    .deleteMaterial(material);

                // The UI will automatically update due to the provider changes
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error deleting material: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
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

  void _showVendorDetails(
      BuildContext context, MaterialItem material, WidgetRef ref) {
    final rates = material.vendorRates;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Vendors for ${material.description}'),
        content: SizedBox(
          width: 800,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const ListTile(
                title: Row(
                  children: [
                    Expanded(child: Text('Vendor')),
                    Expanded(child: Text('Base Rate')),
                    Expanded(child: Text('Purchase Rate')),
                    Expanded(child: Text('Last Purchase')),
                    Expanded(child: Text('Preferred')),
                    Expanded(child: Text('Remarks')),
                  ],
                ),
              ),
              const Divider(),
              ...rates.map((rate) {
                return ListTile(
                  title: Row(
                    children: [
                      Expanded(child: Text(rate.vendorId)),
                      Expanded(child: Text('₹${rate.baseRate}')),
                      Expanded(child: Text('₹${rate.purchaseRate}')),
                      Expanded(child: Text(rate.lastPurchaseDate)),
                      Expanded(
                          child: Icon(
                        rate.isPreferred ? Icons.star : Icons.star_border,
                        color: rate.isPreferred ? Colors.amber : Colors.grey,
                      )),
                      Expanded(child: Text(rate.remarks)),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showBulkUploadDialog() {
    showDialog(
      context: context,
      barrierDismissible: false, // Prevent dismissing by tapping outside
      builder: (context) => AlertDialog(
        title: const Text('Bulk Material Upload'),
        content: SizedBox(
          width: 500,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Upload a CSV file with the following columns:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              const Text('Required columns:'),
              const SizedBox(height: 8),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('• Part Number'),
                  Text('• Description'),
                  Text('• Unit'),
                  Text('• Category'),
                  Text('• Sub Category'),
                  Text('• Inventory Classification'),
                ],
              ),
              const SizedBox(height: 16),
              const Text(
                'Notes:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('• All fields are mandatory except HSN Code'),
                  Text('• Errors will be shown for each invalid part number'),
                  Text('• Duplicate part numbers will be rejected'),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(context); // Close initial dialog
              try {
                await _pickAndProcessFile();
              } catch (e) {
                print('Error in file processing: $e');
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error processing file: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('Select File'),
          ),
        ],
      ),
    );
  }

  Future<void> _pickAndProcessFile() async {
    try {
      print('Starting file picker...');
      print('Platform: ${Theme.of(context).platform}');
      
      // Try with the simplest approach first
      FilePickerResult? result;
      
      // Try different approaches
      try {
        print('Attempting file picker with FileType.any...');
        result = await FilePicker.platform.pickFiles(
          type: FileType.any,
          allowMultiple: false,
        );
        print('FileType.any result: $result');
      } catch (e) {
        print('FileType.any failed: $e');
        
        try {
          print('Attempting file picker with custom extensions...');
          result = await FilePicker.platform.pickFiles(
            type: FileType.custom,
            allowedExtensions: ['csv', 'xlsx', 'xls'],
            allowMultiple: false,
          );
          print('Custom extensions result: $result');
        } catch (e2) {
          print('Custom extensions failed: $e2');
          throw Exception('All file picker methods failed. Last error: $e2');
        }
      }

      print('File picker result: $result');

      if (result != null) {
        print('File selected: ${result.files.single.name}');
        print('File path: ${result.files.single.path}');
        
        if (result.files.single.path != null) {
          final file = File(result.files.single.path!);
          final extension = result.files.single.extension?.toLowerCase();
          
          print('File extension: $extension');
          
          if (extension == 'csv') {
            await _processCsvFile(file);
          } else if (extension == 'xlsx' || extension == 'xls') {
            // For now, show message to convert to CSV
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Please convert Excel file to CSV format and try again'),
                  backgroundColor: Colors.orange,
                ),
              );
            }
          } else {
            // Check if the file might be a CSV without extension
            final fileName = result.files.single.name.toLowerCase();
            if (fileName.endsWith('.csv') || 
                (extension == null && fileName.contains('csv'))) {
              await _processCsvFile(file);
            } else {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Unsupported file type: $extension. Please select a CSV file.'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            }
          }
        } else {
          print('File path is null');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Could not access the selected file. Please try again.'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      } else {
        print('No file selected or file picker was cancelled');
        // User cancelled file selection - this is normal, don't show error
      }
    } catch (e) {
      print('Error in file picker: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error picking file: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _processCsvFile(File file) async {
    try {
      print('=== Processing CSV File ===');
      print('File path: ${file.path}');
      
      print('Reading file content...');
      final input = await file.readAsString();
      print('File content length: ${input.length} characters');
      
      print('Converting CSV to list...');
      final fields = const CsvToListConverter().convert(input);
      print('CSV fields parsed: ${fields.length} rows');
      
      if (fields.isEmpty) {
        throw Exception('File is empty');
      }

      print('Processing headers...');
      final headers = fields[0].map((e) => e.toString().toLowerCase()).toList();
      print('Headers: $headers');
      
      final dataRows = fields.sublist(1);
      print('Data rows: ${dataRows.length}');

      print('Finding column indices...');
      // Find required column indices
      final partNoIndex = _findColumnIndex(headers, ['part number', 'material code', 'partno', 'part_number']);
      final descriptionIndex = _findColumnIndex(headers, ['description', 'desc', 'material description']);
      final unitIndex = _findColumnIndex(headers, ['unit', 'uom', 'unit of measure']);
      final categoryIndex = _findColumnIndex(headers, ['category']);
      final subCategoryIndex = _findColumnIndex(headers, ['sub category', 'subcategory', 'sub_category']);
      final hsnIndex = _findColumnIndex(headers, ['hsn code', 'hsn', 'hsncode']);
      final invClassIndex = _findColumnIndex(headers, ['inventory classification', 'inventory class', 'inv class']);
      final storageIndex = _findColumnIndex(headers, ['storage location', 'storage', 'location']);
      final rackIndex = _findColumnIndex(headers, ['rack number', 'rack no', 'rack']);
      final weightIndex = _findColumnIndex(headers, ['actual weight', 'weight', 'net weight']);

      print('Column indices - Part: $partNoIndex, Description: $descriptionIndex, Unit: $unitIndex, Category: $categoryIndex, SubCategory: $subCategoryIndex, HSN: $hsnIndex, InvClass: $invClassIndex, Storage: $storageIndex, Rack: $rackIndex, Weight: $weightIndex');

      if (partNoIndex == -1 || descriptionIndex == -1 || unitIndex == -1 || categoryIndex == -1 || subCategoryIndex == -1 || invClassIndex == -1) {
        throw Exception('Required columns not found. Please ensure your file has: Part Number, Description, Unit, Category, Sub Category, and Inventory Classification columns');
      }

      print('Showing upload preview...');
      await _showUploadPreview(dataRows, partNoIndex, descriptionIndex, unitIndex, categoryIndex, subCategoryIndex, hsnIndex, invClassIndex, storageIndex, rackIndex, weightIndex);
      print('=== CSV Processing Complete ===');

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error processing file: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  int _findColumnIndex(List<String> headers, List<String> possibleNames) {
    for (int i = 0; i < headers.length; i++) {
      final header = headers[i].toLowerCase().trim();
      if (possibleNames.any((name) => header.contains(name.toLowerCase()))) {
        return i;
      }
    }
    return -1;
  }

  Future<void> _showUploadPreview(
    List<List<dynamic>> dataRows,
    int partNoIndex,
    int descriptionIndex,
    int unitIndex,
    int categoryIndex,
    int subCategoryIndex,
    int hsnIndex,
    int invClassIndex,
    int storageIndex,
    int rackIndex,
    int weightIndex,
  ) async {
    print('=== Showing Upload Preview ===');
    print('Data rows count: ${dataRows.length}');
    
    final previewData = <Map<String, dynamic>>[];
    print('Getting existing materials...');
    final existingMaterials = ref.read(materialListProvider);
    print('Found ${existingMaterials.length} existing materials');
    
    print('Processing preview data...');
    final seenPartNumbers = <String>{};
    
    for (int i = 0; i < dataRows.length && i < 10; i++) { // Show first 10 rows for preview
      print('Processing row $i of ${dataRows.length}');
      final row = dataRows[i];
      final requiredMaxIndex = [partNoIndex, descriptionIndex, unitIndex, categoryIndex, subCategoryIndex, invClassIndex].reduce((a, b) => a > b ? a : b);
      
      if (row.length <= requiredMaxIndex) {
        print('Row $i has insufficient columns: ${row.length} <= $requiredMaxIndex');
        previewData.add({
          'partNo': 'Row ${i + 1}',
          'description': 'ERROR',
          'unit': '',
          'category': '',
          'subCategory': '',
          'hsnCode': '',
          'invClass': '',
          'storageLocation': '',
          'rackNumber': '',
          'actualWeight': '',
          'status': 'Insufficient columns',
          'error': true,
          'warning': false,
        });
        continue;
      }

      final partNo = row[partNoIndex]?.toString().trim() ?? '';
      final description = row[descriptionIndex]?.toString().trim() ?? '';
      final unit = row[unitIndex]?.toString().trim() ?? '';
      final category = row[categoryIndex]?.toString().trim() ?? '';
      final subCategory = row[subCategoryIndex]?.toString().trim() ?? '';
      final hsnCode = hsnIndex != -1 && hsnIndex < row.length
          ? (row[hsnIndex]?.toString().trim() ?? '')
          : '';
      final invClass = row[invClassIndex]?.toString().trim() ?? '';
      final storageLocation = storageIndex != -1 && storageIndex < row.length
          ? (row[storageIndex]?.toString().trim() ?? '')
          : '';
      final rackNumber = rackIndex != -1 && rackIndex < row.length
          ? (row[rackIndex]?.toString().trim() ?? '')
          : '';
      final actualWeight = weightIndex != -1 && weightIndex < row.length
          ? (row[weightIndex]?.toString().trim() ?? '')
          : '';

      print('Row $i data: Part=$partNo, Desc=$description, Unit=$unit, Cat=$category, SubCat=$subCategory, HSN=$hsnCode, InvClass=$invClass, Storage=$storageLocation, Rack=$rackNumber, Weight=$actualWeight');

      // Validation
      String? error;
      bool warning = false;
      if (partNo.isEmpty) {
        error = 'Missing Part Number';
      } else if (description.isEmpty) {
        error = 'Missing Description';
      } else if (unit.isEmpty) {
        error = 'Missing Unit';
      } else if (category.isEmpty) {
        error = 'Missing Category';
      } else if (subCategory.isEmpty) {
        error = 'Missing Sub Category';
      } else if (invClass.isEmpty) {
        error = 'Missing Inventory Classification';
      } else if (seenPartNumbers.contains(partNo)) {
        error = 'Duplicate Part Number';
      } else if (existingMaterials.any((m) => m.partNo == partNo)) {
        error = 'Part Number already exists';
      }

      if (error == null && hsnCode.isEmpty) {
        warning = true;
      }
      
      seenPartNumbers.add(partNo);
      final status = error != null
          ? error
          : warning
              ? 'HSN Code Missing (GR cannot be created)'
              : 'Valid';

      previewData.add({
        'partNo': partNo.isEmpty ? 'Row ${i + 1}' : partNo,
        'description': description,
        'unit': unit,
        'category': category,
        'subCategory': subCategory,
        'hsnCode': hsnCode,
        'invClass': invClass,
        'storageLocation': storageLocation,
        'rackNumber': rackNumber,
        'actualWeight': actualWeight,
        'status': status,
        'error': error != null,
        'warning': warning,
      });
    }
    
    print('Preview data prepared: ${previewData.length} items');

    if (mounted) {
      print('Showing preview dialog...');
      
      showDialog(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text('Upload Preview (${dataRows.length} total rows)'),
          content: SizedBox(
            width: 1000,
            height: 400,
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    child: Table(
                      border: TableBorder.all(),
                      columnWidths: const {
                        0: FlexColumnWidth(1.5),
                        1: FlexColumnWidth(2),
                        2: FlexColumnWidth(1),
                        3: FlexColumnWidth(1.2),
                        4: FlexColumnWidth(1.2),
                        5: FlexColumnWidth(1),
                        6: FlexColumnWidth(1),
                        7: FlexColumnWidth(1),
                        8: FlexColumnWidth(1),
                        9: FlexColumnWidth(1),
                        10: FlexColumnWidth(1.5),
                      },
                      children: [
                        const TableRow(
                          decoration: BoxDecoration(color: Colors.grey),
                          children: [
                            Padding(padding: EdgeInsets.all(8), child: Text('Part No', style: TextStyle(fontWeight: FontWeight.bold))),
                            Padding(padding: EdgeInsets.all(8), child: Text('Description', style: TextStyle(fontWeight: FontWeight.bold))),
                            Padding(padding: EdgeInsets.all(8), child: Text('Unit', style: TextStyle(fontWeight: FontWeight.bold))),
                            Padding(padding: EdgeInsets.all(8), child: Text('Category', style: TextStyle(fontWeight: FontWeight.bold))),
                            Padding(padding: EdgeInsets.all(8), child: Text('Sub Category', style: TextStyle(fontWeight: FontWeight.bold))),
                            Padding(padding: EdgeInsets.all(8), child: Text('HSN', style: TextStyle(fontWeight: FontWeight.bold))),
                            Padding(padding: EdgeInsets.all(8), child: Text('Inv Class', style: TextStyle(fontWeight: FontWeight.bold))),
                            Padding(padding: EdgeInsets.all(8), child: Text('Storage', style: TextStyle(fontWeight: FontWeight.bold))),
                            Padding(padding: EdgeInsets.all(8), child: Text('Rack', style: TextStyle(fontWeight: FontWeight.bold))),
                            Padding(padding: EdgeInsets.all(8), child: Text('Weight', style: TextStyle(fontWeight: FontWeight.bold))),
                            Padding(padding: EdgeInsets.all(8), child: Text('Status', style: TextStyle(fontWeight: FontWeight.bold))),
                          ],
                        ),
                        ...previewData.map((data) => TableRow(
                          children: [
                            Padding(padding: const EdgeInsets.all(8), child: Text(data['partNo'])),
                            Padding(padding: const EdgeInsets.all(8), child: Text(data['description'])),
                            Padding(padding: const EdgeInsets.all(8), child: Text(data['unit'])),
                            Padding(padding: const EdgeInsets.all(8), child: Text(data['category'])),
                            Padding(padding: const EdgeInsets.all(8), child: Text(data['subCategory'])),
                            Padding(padding: const EdgeInsets.all(8), child: Text(data['hsnCode'] ?? '')),
                            Padding(padding: const EdgeInsets.all(8), child: Text(data['invClass'])),
                            Padding(padding: const EdgeInsets.all(8), child: Text(data['storageLocation'] ?? '')),
                            Padding(padding: const EdgeInsets.all(8), child: Text(data['rackNumber'] ?? '')),
                            Padding(padding: const EdgeInsets.all(8), child: Text(data['actualWeight'] ?? '')),
                            Padding(
                              padding: const EdgeInsets.all(8), 
                              child: Text(
                                data['status'],
                                style: TextStyle(
                                  color: data['error'] == true
                                      ? Colors.red
                                      : (data['warning'] == true
                                          ? Colors.orange
                                          : Colors.green),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        )),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                print('Upload button pressed in preview dialog');
                
                // Store the main context before closing dialog
                final mainContext = context;
                Navigator.pop(dialogContext); // Close preview dialog
                
                // Show processing dialog
                BuildContext? processingDialogContext;
                showDialog(
                  context: mainContext,
                  barrierDismissible: false,
                  builder: (context) {
                    processingDialogContext = context;
                    return WillPopScope(
                      onWillPop: () async => false,
                      child: const AlertDialog(
                        content: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CircularProgressIndicator(),
                            SizedBox(width: 16),
                            Text('Processing upload...'),
                          ],
                        ),
                      ),
                    );
                  },
                );
                
                try {
                  await _processUpload(dataRows, partNoIndex, descriptionIndex, unitIndex, categoryIndex, subCategoryIndex, hsnIndex, invClassIndex, storageIndex, rackIndex, weightIndex);
                  
                  // Close processing dialog
                  if (processingDialogContext != null && Navigator.canPop(processingDialogContext!)) {
                    Navigator.pop(processingDialogContext!);
                  }
                } catch (e) {
                  // Close processing dialog
                  if (processingDialogContext != null && Navigator.canPop(processingDialogContext!)) {
                    Navigator.pop(processingDialogContext!);
                  }
                  
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Upload failed: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              child: const Text('Upload'),
            ),
          ],
        ),
      );
    }
  }

  Future<void> _processUpload(
    List<List<dynamic>> dataRows,
    int partNoIndex,
    int descriptionIndex,
    int unitIndex,
    int categoryIndex,
    int subCategoryIndex,
    int hsnIndex,
    int invClassIndex,
    int storageIndex,
    int rackIndex,
    int weightIndex,
  ) async {
    
    try {
      print('=== Starting Upload Process ===');
      print('Data rows to process: ${dataRows.length}');
      
      final materialNotifier = ref.read(materialListProvider.notifier);
      final existingMaterials = ref.read(materialListProvider);
      
      print('Got notifiers and existing materials: ${existingMaterials.length}');
      
      int created = 0;
      int skipped = 0;
      final errors = <String>[];
      final seenPartNumbers = <String>{};

      // If any row is missing HSN, behave like Add Material page: warn + ask to continue.
      bool anyMissingHsn = false;
      int missingHsnCount = 0;
      for (int i = 0; i < dataRows.length; i++) {
        final row = dataRows[i];
        final requiredMaxIndex = [partNoIndex, descriptionIndex, unitIndex, categoryIndex, subCategoryIndex, invClassIndex].reduce((a, b) => a > b ? a : b);
        if (row.length <= requiredMaxIndex) {
          continue;
        }

        final hsn = hsnIndex != -1 && hsnIndex < row.length
            ? (row[hsnIndex]?.toString().trim() ?? '')
            : '';
        if (hsn.isEmpty) {
          anyMissingHsn = true;
          missingHsnCount++;
        }
      }

      if (anyMissingHsn && mounted) {
        final shouldContinue = await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 28),
                SizedBox(width: 8),
                Expanded(child: Text('HSN Code Not Available')),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$missingHsnCount row(s) do not have HSN Code.',
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Warning: Without HSN Code, you will not be able to create Goods Receipt (GR) for these materials.',
                    style: TextStyle(color: Colors.red),
                  ),
                  const SizedBox(height: 12),
                  const Text('Do you want to continue uploading without HSN Code?'),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                ),
                child: const Text('Continue Without HSN', style: TextStyle(color: Colors.black)),
              ),
            ],
          ),
        );

        if (shouldContinue != true) {
          return;
        }
      }

      for (int i = 0; i < dataRows.length; i++) {
        final row = dataRows[i];
        final rowNum = i + 1;
        
        try {
          print('Processing row $rowNum: $row');
          
          final maxIndex = [partNoIndex, descriptionIndex, unitIndex, categoryIndex, subCategoryIndex, invClassIndex].reduce((a, b) => a > b ? a : b);
          
          if (row.length <= maxIndex) {
            errors.add('Row $rowNum: Insufficient columns');
            skipped++;
            continue;
          }

          final partNo = row[partNoIndex]?.toString().trim() ?? '';
          final description = row[descriptionIndex]?.toString().trim() ?? '';
          final unit = row[unitIndex]?.toString().trim() ?? '';
          final category = row[categoryIndex]?.toString().trim() ?? '';
          final subCategory = row[subCategoryIndex]?.toString().trim() ?? '';
          final hsnCode = hsnIndex != -1 && hsnIndex < row.length
              ? (row[hsnIndex]?.toString().trim() ?? '')
              : '';
          final invClass = row[invClassIndex]?.toString().trim() ?? '';
          final storageLocation = storageIndex != -1 && storageIndex < row.length
              ? (row[storageIndex]?.toString().trim() ?? '')
              : '';
          final rackNumber = rackIndex != -1 && rackIndex < row.length
              ? (row[rackIndex]?.toString().trim() ?? '')
              : '';
          final actualWeight = weightIndex != -1 && weightIndex < row.length
              ? (row[weightIndex]?.toString().trim() ?? '')
              : '';

          print('Row $rowNum data: Part=$partNo, Desc=$description, Unit=$unit, Cat=$category, SubCat=$subCategory, HSN=$hsnCode, InvClass=$invClass, Storage=$storageLocation, Rack=$rackNumber, Weight=$actualWeight');

          // Validation
          if (partNo.isEmpty) {
            errors.add('Row $rowNum: Missing Part Number');
            skipped++;
            continue;
          }
          if (description.isEmpty) {
            errors.add('Row $rowNum (Part: $partNo): Missing Description');
            skipped++;
            continue;
          }
          if (unit.isEmpty) {
            errors.add('Row $rowNum (Part: $partNo): Missing Unit');
            skipped++;
            continue;
          }
          if (category.isEmpty) {
            errors.add('Row $rowNum (Part: $partNo): Missing Category');
            skipped++;
            continue;
          }
          if (subCategory.isEmpty) {
            errors.add('Row $rowNum (Part: $partNo): Missing Sub Category');
            skipped++;
            continue;
          }
          if (invClass.isEmpty) {
            errors.add('Row $rowNum (Part: $partNo): Missing Inventory Classification');
            skipped++;
            continue;
          }
          
          // Check for duplicates in file
          if (seenPartNumbers.contains(partNo)) {
            errors.add('Row $rowNum (Part: $partNo): Duplicate Part Number in file');
            skipped++;
            continue;
          }
          seenPartNumbers.add(partNo);
          
          // Check if material already exists
          if (existingMaterials.any((m) => m.partNo == partNo)) {
            errors.add('Row $rowNum (Part: $partNo): Part Number already exists in database');
            skipped++;
            continue;
          }

          // Create new material
          print('Row $rowNum: Creating new material $partNo');
          final newSlNo = (existingMaterials.length + created + 1).toString();
          final newMaterial = MaterialItem(
            slNo: newSlNo,
            partNo: partNo,
            description: description,
            unit: unit,
            category: category,
            subCategory: subCategory,
            inventoryClassification: invClass,
            storageLocation: storageLocation,
            rackNumber: rackNumber,
            binNumber: '',
            hsnCode: hsnCode,
            saleRate: '0',
            actualWeight: actualWeight,
            vendorRates: [],
          );
          
          print('Row $rowNum: Adding material to database...');
          await materialNotifier.addMaterial(newMaterial);
          print('Row $rowNum: Material added successfully');
          created++;
          
        } catch (e) {
          print('Error processing row $rowNum: $e');
          errors.add('Row $rowNum: Error - $e');
          skipped++;
        }
      }

      print('=== Upload Process Complete ===');
      print('Created: $created, Skipped: $skipped, Errors: ${errors.length}');

      // Show completion message
      if (mounted) {
        if (errors.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Upload completed successfully!\nCreated: $created materials'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 3),
            ),
          );
        } else {
          // Show error dialog with details
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: Text('Upload Complete with Errors'),
              content: SizedBox(
                width: 600,
                height: 400,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Created: $created materials', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                    Text('Skipped: $skipped rows', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange)),
                    const SizedBox(height: 16),
                    const Text('Errors:', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: errors.map((e) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 2),
                            child: Text('• $e', style: TextStyle(color: Colors.red[700])),
                          )).toList(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Close'),
                ),
              ],
            ),
          );
        }
        
        // Force a rebuild of the material master page
        setState(() {});
      }

    } catch (e) {
      print('Error during upload process: $e');
      
      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error during upload: $e'),
            backgroundColor: Colors.red,
          ),
        );
        
        // Force a rebuild of the material master page
        setState(() {});
      }
    }
  }

  Future<void> _addToGeneralStock(String partNo, double quantity, StockMaintenanceNotifier stockNotifier) async {
    try {
      print('\n=== Adding to General Stock ===');
      print('Part No: $partNo');
      print('Quantity: $quantity');
      
      // Check if stock record exists
      final existingStocks = ref.read(stockMaintenanceProvider);
      final existingStock = existingStocks.firstWhereOrNull((s) => s.materialCode == partNo);
      
      if (existingStock != null) {
        print('Found existing stock record');
        print('Current stock: ${existingStock.currentStock}');
        
        // Create synthetic records for the additional uploaded stock
        await _createSyntheticStockRecords(existingStock, quantity);
        await stockNotifier.update(existingStock);
        
        print('Updated stock to: ${existingStock.currentStock}');
      } else {
        print('Creating new stock record');
        
        // Create new stock record
        final materials = ref.read(materialListProvider);
        print('Found ${materials.length} materials');
        
        final material = materials.firstWhere(
          (m) => m.partNo == partNo,
          orElse: () {
            print('Material not found by partNo, searching by slNo');
            return materials.firstWhere(
              (m) => m.slNo == partNo,
              orElse: () {
                print('Material not found by slNo either');
                throw Exception('Material not found: $partNo');
              },
            );
          },
        );
        
        print('Found material: ${material.partNo} (${material.description})');
        
        // Create stock record with synthetic GRN/PO/PR records
        final newStock = await _createStockWithSyntheticRecords(material, quantity);
        
        print('Adding new stock record with quantity: $quantity');
        await stockNotifier.add(newStock);
        print('Stock record added successfully');
      }
      
      print('=== Stock Update Complete ===');
    } catch (e) {
      print('Error adding to general stock for $partNo: $e');
      rethrow;
    }
  }

  Future<StockMaintenance> _createStockWithSyntheticRecords(dynamic material, double quantity) async {
    final now = DateTime.now();
    final dateStr = now.toIso8601String();
    final timestamp = now.millisecondsSinceEpoch.toString();
    
    // Generate synthetic IDs
    final grnNo = 'GRN_UPLOAD_$timestamp';
    final poNo = 'PO_UPLOAD_$timestamp';
    final prNo = 'PR_UPLOAD_$timestamp';
    
    print('Creating synthetic records:');
    print('  GRN: $grnNo');
    print('  PO: $poNo');
    print('  PR: $prNo');
    
    // Create synthetic GRN details
    final grnDetails = {
      grnNo: StockGRNDetails(
        grnNo: grnNo,
        grnDate: dateStr,
        receivedQuantity: quantity,
        acceptedQuantity: quantity,
        rejectedQuantity: 0.0,
        vendorId: 'UPLOADED_STOCK',
        rate: _getMaterialRate(material),
        issuedQuantity: 0.0,
        issuedQuantities: {},
      ),
    };
    
    // Create synthetic PO details
    final poDetails = {
      poNo: StockPODetails(
        poNo: poNo,
        poDate: dateStr,
        orderedQuantity: quantity,
        receivedQuantity: quantity,
        vendorId: 'UPLOADED_STOCK',
        rate: _getMaterialRate(material),
        receivedQuantities: {
          grnNo: {'General': quantity}
        },
        issuedQuantity: 0.0,
        issuedQuantities: {},
      ),
    };
    
    // Create synthetic PR details
    final prDetails = {
      'General': StockPRDetails(
        prNo: 'General',
        prDate: dateStr,
        requestedQuantity: quantity,
        orderedQuantity: quantity,
        receivedQuantity: quantity,
        issuedQuantity: 0.0,
        jobNo: 'General',
      ),
    };
    
    // Create synthetic job details
    final jobDetails = {
      'General': StockJobDetails(
        jobNo: 'General',
        allocatedQuantity: quantity,
        consumedQuantity: 0.0,
        prNo: 'General',
      ),
    };
    
    // Create synthetic vendor details
    final vendorDetails = {
      'UPLOADED_STOCK': StockVendorDetails(
        vendorId: 'UPLOADED_STOCK',
        vendorName: 'Uploaded Stock',
        quantity: quantity,
        rate: _getMaterialRate(material),
        lastPurchaseDate: dateStr,
      ),
    };
    
    final newStock = StockMaintenance(
      materialCode: material.partNo,
      materialDescription: material.description,
      unit: material.unit,
      storageLocation: '',
      rackNumber: material.rackNumber ?? '',
      currentStock: quantity,
      stockUnderInspection: 0.0,
      totalStockValue: quantity * _getMaterialRate(material),
      grnDetails: grnDetails,
      poDetails: poDetails,
      prDetails: prDetails,
      jobDetails: jobDetails,
      vendorDetails: vendorDetails,
    );
    
    print('Created stock with synthetic records');
    return newStock;
  }

  Future<void> _createSyntheticStockRecords(StockMaintenance existingStock, double quantity) async {
    final now = DateTime.now();
    final dateStr = now.toIso8601String();
    final timestamp = now.millisecondsSinceEpoch.toString();
    
    // Generate synthetic IDs
    final grnNo = 'GRN_UPLOAD_$timestamp';
    final poNo = 'PO_UPLOAD_$timestamp';
    
    print('Adding synthetic records to existing stock:');
    print('  GRN: $grnNo');
    print('  PO: $poNo');
    
    // Get material details for rate
    final materials = ref.read(materialListProvider);
    final material = materials.firstWhereOrNull((m) => m.partNo == existingStock.materialCode);
    final rate = material != null ? _getMaterialRate(material) : 0.0;
    
    // Add synthetic GRN details
    existingStock.grnDetails[grnNo] = StockGRNDetails(
      grnNo: grnNo,
      grnDate: dateStr,
      receivedQuantity: quantity,
      acceptedQuantity: quantity,
      rejectedQuantity: 0.0,
      vendorId: 'UPLOADED_STOCK',
      rate: rate,
      issuedQuantity: 0.0,
      issuedQuantities: {},
    );
    
    // Add synthetic PO details
    existingStock.poDetails[poNo] = StockPODetails(
      poNo: poNo,
      poDate: dateStr,
      orderedQuantity: quantity,
      receivedQuantity: quantity,
      vendorId: 'UPLOADED_STOCK',
      rate: rate,
      receivedQuantities: {
        grnNo: {'General': quantity}
      },
      issuedQuantity: 0.0,
      issuedQuantities: {},
    );
    
    // Update or create General PR details
    if (existingStock.prDetails.containsKey('General')) {
      final generalPR = existingStock.prDetails['General']!;
      generalPR.requestedQuantity += quantity;
      generalPR.orderedQuantity += quantity;
      generalPR.receivedQuantity += quantity;
    } else {
      existingStock.prDetails['General'] = StockPRDetails(
        prNo: 'General',
        prDate: dateStr,
        requestedQuantity: quantity,
        orderedQuantity: quantity,
        receivedQuantity: quantity,
        issuedQuantity: 0.0,
        jobNo: 'General',
      );
    }
    
    // Update or create General job details
    if (existingStock.jobDetails.containsKey('General')) {
      final generalJob = existingStock.jobDetails['General']!;
      generalJob.allocatedQuantity += quantity;
    } else {
      existingStock.jobDetails['General'] = StockJobDetails(
        jobNo: 'General',
        allocatedQuantity: quantity,
        consumedQuantity: 0.0,
        prNo: 'General',
      );
    }
    
    // Update or create vendor details for uploaded stock
    if (existingStock.vendorDetails.containsKey('UPLOADED_STOCK')) {
      final uploadedVendor = existingStock.vendorDetails['UPLOADED_STOCK']!;
      uploadedVendor.quantity += quantity;
      uploadedVendor.lastPurchaseDate = dateStr;
    } else {
      existingStock.vendorDetails['UPLOADED_STOCK'] = StockVendorDetails(
        vendorId: 'UPLOADED_STOCK',
        vendorName: 'Uploaded Stock',
        quantity: quantity,
        rate: rate,
        lastPurchaseDate: dateStr,
      );
    }
    
    // Update current stock and total stock value
    existingStock.currentStock += quantity;
    existingStock.totalStockValue += quantity * rate;
    
    print('Added synthetic records to existing stock');
  }

  double _getMaterialRate(dynamic material) {
    // Try to get purchase rate first, then sale rate, then default to 100.0
    if (material.purchaseRate != null && material.purchaseRate is num && (material.purchaseRate as num) > 0) {
      return (material.purchaseRate as num).toDouble();
    }
    if (material.saleRate != null && material.saleRate is num && (material.saleRate as num) > 0) {
      return (material.saleRate as num).toDouble();
    }
    // Default rate for uploaded materials
    return 100.0;
  }


}
