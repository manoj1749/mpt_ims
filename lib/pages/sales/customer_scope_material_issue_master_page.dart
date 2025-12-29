import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mpt_ims/pages/sales/add_customer_scope_material_issue_master_page.dart';
import 'package:mpt_ims/provider/customer_scope_material_issue_master_provider.dart';
import 'package:mpt_ims/models/customer_scope_material_issue_master.dart';

import 'package:pluto_grid/pluto_grid.dart';
import 'package:collection/collection.dart';
import 'package:file_picker/file_picker.dart';
import 'package:csv/csv.dart';
import 'dart:io';
import '../../widgets/pluto_grid_configuration.dart';

class CustomerScopeMaterialIssueMasterPage extends ConsumerStatefulWidget {
  const CustomerScopeMaterialIssueMasterPage({super.key});

  @override
  ConsumerState<CustomerScopeMaterialIssueMasterPage> createState() => _CustomerScopeMaterialIssueMasterPageState();
}

class _CustomerScopeMaterialIssueMasterPageState extends ConsumerState<CustomerScopeMaterialIssueMasterPage> {
  PlutoGridStateManager? stateManager;
  bool _isLoading = true;

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
        dialogTitle: 'Save Customer Free Issue Material Master Bulk Template',
        fileName: 'customer_free_issue_material_master_bulk_template.csv',
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

  void _onPlutoGridLoaded(PlutoGridOnLoadedEvent event) {
    stateManager = event.stateManager;
    stateManager?.setShowColumnFilter(true);
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
        enableEditingMode: false,
      ),
      PlutoColumn(
        title: 'Actual Weight',
        field: 'actualWeight',
        type: PlutoColumnType.text(),
        width: 120,
        enableEditingMode: false,
      ),
      PlutoColumn(
        title: 'Storage Location',
        field: 'storageLocation',
        type: PlutoColumnType.text(),
        width: 120,
        enableEditingMode: false,
      ),
      PlutoColumn(
        title: 'Rack Number',
        field: 'rackNumber',
        type: PlutoColumnType.text(),
        width: 120,
        enableEditingMode: false,
      ),
      PlutoColumn(
        title: 'BIN Number',
        field: 'binNumber',
        type: PlutoColumnType.text(),
        width: 120,
        enableEditingMode: false,
      ),
      PlutoColumn(
        title: 'HSN Code',
        field: 'hsnCode',
        type: PlutoColumnType.text(),
        width: 120,
        enableEditingMode: false,
      ),
      PlutoColumn(
        title: 'Actions',
        field: 'actions',
        type: PlutoColumnType.text(),
        width: 150,
        enableEditingMode: false,
        renderer: (rendererContext) {
          final materials = ref.read(customerScopeMaterialIssueMasterListProvider);
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
                      builder: (_) => AddCustomerScopeMaterialIssueMasterPage(
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

  List<PlutoRow> _getRows(List<CustomerScopeMaterialIssueMaster> materials, WidgetRef ref) {
    return materials.map((m) {
      return PlutoRow(
        cells: {
          'slNo': PlutoCell(value: m.slNo),
          'partNo': PlutoCell(value: m.partNo),
          'description': PlutoCell(value: m.description),
          'category': PlutoCell(value: m.category),
          'subCategory': PlutoCell(value: m.subCategory),
          'inventoryClass': PlutoCell(value: (m.inventoryClassification ?? '').isEmpty ? '-' : m.inventoryClassification!),
          'unit': PlutoCell(value: m.unit),
          'actualWeight': PlutoCell(value: m.actualWeight),
          'storageLocation': PlutoCell(value: m.storageLocation),
          'rackNumber': PlutoCell(value: m.rackNumber),
          'binNumber':
              PlutoCell(value: m.binNumber?.isEmpty ?? true ? '-' : m.binNumber),
          'hsnCode':
              PlutoCell(value: m.hsnCode?.isEmpty ?? true ? '-' : m.hsnCode),
          'actions': PlutoCell(value: ''),
        },
      );
    }).toList();
  }

  void _showBulkUploadDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Bulk Master Upload'),
        content: const SizedBox(
          width: 500,
          child: Text('Upload CSV with columns: Part Number, Description, Unit, Category, Sub Category, HSN Code, Storage Location, Rack Number, BIN Number, Actual Weight, Inventory Class'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(context);
              await _pickAndProcessFile();
            },
            child: const Text('Select File'),
          ),
        ],
      ),
    );
  }

  Future<void> _pickAndProcessFile() async {
    try {
      FilePickerResult? result;
      try {
        result = await FilePicker.platform.pickFiles(type: FileType.any, allowMultiple: false);
      } catch (_) {
        result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['csv'], allowMultiple: false);
      }

      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);
        final ext = result.files.single.extension?.toLowerCase();
        if (ext == 'csv' || ext == null) {
          await _processCsvFile(file);
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Unsupported file type: $ext. Please select a CSV file.'), backgroundColor: Colors.red),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking file: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _processCsvFile(File file) async {
    try {
      final input = await file.readAsString();
      final fields = const CsvToListConverter().convert(input);
      if (fields.isEmpty) throw Exception('File is empty');

      final headers = fields[0].map((e) => e.toString().toLowerCase()).toList();
      final dataRows = fields.sublist(1);

      final partNoIndex = _findColumnIndex(headers, ['part number', 'material code', 'partno', 'part_number']);
      final descriptionIndex = _findColumnIndex(headers, ['description', 'desc', 'material description']);
      final unitIndex = _findColumnIndex(headers, ['unit', 'uom', 'unit of measure']);
      final categoryIndex = _findColumnIndex(headers, ['category']);
      final subCategoryIndex = _findColumnIndex(headers, ['sub category', 'subcategory', 'sub_category']);
      final hsnIndex = _findColumnIndex(headers, ['hsn code', 'hsn', 'hsncode', 'hsn_code']);
      final storageIndex = _findColumnIndex(headers, ['storage location', 'storage']);
      final rackIndex = _findColumnIndex(headers, ['rack number', 'rack']);
      final binIndex = _findColumnIndex(headers, ['bin number', 'bin']);
      final weightIndex = _findColumnIndex(headers, ['actual weight', 'weight']);
      final invClassIndex = _findColumnIndex(headers, ['inventory class', 'inventory classification']);

      if (partNoIndex == -1 || descriptionIndex == -1 || unitIndex == -1) {
        throw Exception('Required columns not found. Need Part Number, Description, Unit');
      }

      await _showUploadPreview(
        dataRows,
        partNoIndex,
        descriptionIndex,
        unitIndex,
        categoryIndex,
        subCategoryIndex,
        hsnIndex,
        storageIndex,
        rackIndex,
        binIndex,
        weightIndex,
        invClassIndex,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error processing file: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  int _findColumnIndex(List<String> headers, List<String> possible) {
    for (int i = 0; i < headers.length; i++) {
      final h = headers[i].toLowerCase().trim();
      for (final p in possible) {
        if (h.contains(p.toLowerCase())) return i;
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
    int storageIndex,
    int rackIndex,
    int binIndex,
    int weightIndex,
    int invClassIndex,
  ) async {
    final preview = <List<String>>[];
    for (int i = 0; i < dataRows.length && i < 10; i++) {
      final r = dataRows[i];
      final get = (int idx) => idx != -1 && idx < r.length ? (r[idx]?.toString().trim() ?? '') : '';
      preview.add([
        get(partNoIndex),
        get(descriptionIndex),
        get(unitIndex),
        get(categoryIndex),
        get(subCategoryIndex),
        get(hsnIndex),
        get(storageIndex),
        get(rackIndex),
        get(binIndex),
        get(weightIndex),
        get(invClassIndex),
      ]);
    }

    if (!mounted) return;
    showDialog(
      context: context,
      builder: (dctx) => AlertDialog(
        title: Text('Upload Preview (${dataRows.length} rows)'),
        content: SizedBox(
          width: 900,
          height: 400,
          child: SingleChildScrollView(
            child: Table(
              border: TableBorder.all(),
              columnWidths: const {0: FlexColumnWidth(1.2), 1: FlexColumnWidth(2), 2: FlexColumnWidth(1), 3: FlexColumnWidth(1), 4: FlexColumnWidth(1), 5: FlexColumnWidth(1), 6: FlexColumnWidth(1), 7: FlexColumnWidth(1), 8: FlexColumnWidth(1), 9: FlexColumnWidth(1), 10: FlexColumnWidth(1)},
              children: [
                const TableRow(children: [
                  Padding(padding: EdgeInsets.all(8), child: Text('Part No', style: TextStyle(fontWeight: FontWeight.bold))),
                  Padding(padding: EdgeInsets.all(8), child: Text('Description', style: TextStyle(fontWeight: FontWeight.bold))),
                  Padding(padding: EdgeInsets.all(8), child: Text('Unit', style: TextStyle(fontWeight: FontWeight.bold))),
                  Padding(padding: EdgeInsets.all(8), child: Text('Category', style: TextStyle(fontWeight: FontWeight.bold))),
                  Padding(padding: EdgeInsets.all(8), child: Text('Sub Category', style: TextStyle(fontWeight: FontWeight.bold))),
                  Padding(padding: EdgeInsets.all(8), child: Text('HSN', style: TextStyle(fontWeight: FontWeight.bold))),
                  Padding(padding: EdgeInsets.all(8), child: Text('Storage', style: TextStyle(fontWeight: FontWeight.bold))),
                  Padding(padding: EdgeInsets.all(8), child: Text('Rack', style: TextStyle(fontWeight: FontWeight.bold))),
                  Padding(padding: EdgeInsets.all(8), child: Text('BIN', style: TextStyle(fontWeight: FontWeight.bold))),
                  Padding(padding: EdgeInsets.all(8), child: Text('Weight', style: TextStyle(fontWeight: FontWeight.bold))),
                  Padding(padding: EdgeInsets.all(8), child: Text('Inv Class', style: TextStyle(fontWeight: FontWeight.bold))),
                ]),
                ...preview.map((row) => TableRow(children: [
                  for (final c in row) Padding(padding: const EdgeInsets.all(8), child: Text(c)),
                ])),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              final outer = context;
              Navigator.pop(dctx);
              BuildContext? processing;
              showDialog(
                context: outer,
                barrierDismissible: false,
                builder: (c) {
                  processing = c;
                  return const AlertDialog(content: Row(mainAxisSize: MainAxisSize.min, children: [CircularProgressIndicator(), SizedBox(width: 16), Text('Processing upload...')]));
                },
              );
              try {
                await _processUpload(dataRows, partNoIndex, descriptionIndex, unitIndex, categoryIndex, subCategoryIndex, hsnIndex, storageIndex, rackIndex, binIndex, weightIndex, invClassIndex);
              } finally {
                if (processing != null && Navigator.canPop(processing!)) Navigator.pop(processing!);
              }
            },
            child: const Text('Upload'),
          ),
        ],
      ),
    );
  }

  Future<void> _processUpload(
    List<List<dynamic>> dataRows,
    int partNoIndex,
    int descriptionIndex,
    int unitIndex,
    int categoryIndex,
    int subCategoryIndex,
    int hsnIndex,
    int storageIndex,
    int rackIndex,
    int binIndex,
    int weightIndex,
    int invClassIndex,
  ) async {
    try {
      final notifier = ref.read(customerScopeMaterialIssueMasterListProvider.notifier);
      final existing = ref.read(customerScopeMaterialIssueMasterListProvider);
      int processed = 0, created = 0, updated = 0, errors = 0;

      for (final row in dataRows) {
        final maxIdx = [partNoIndex, descriptionIndex, unitIndex].reduce((a, b) => a > b ? a : b);
        if (row.length <= maxIdx) { errors++; continue; }

        final get = (int idx) => (idx != -1 && idx < row.length) ? (row[idx]?.toString().trim() ?? '') : '';
        final partNo = get(partNoIndex);
        final description = get(descriptionIndex);
        final unit = get(unitIndex);
        if (partNo.isEmpty || description.isEmpty || unit.isEmpty) { errors++; continue; }

        final category = get(categoryIndex);
        final subCategory = get(subCategoryIndex);
        final hsnCode = get(hsnIndex);
        final storage = get(storageIndex);
        final rack = get(rackIndex);
        final bin = get(binIndex);
        final weight = get(weightIndex);
        final invClass = get(invClassIndex);

        final existingItem = existing.firstWhereOrNull((m) => m.partNo.toLowerCase() == partNo.toLowerCase());
        if (existingItem != null) {
          final updatedItem = CustomerScopeMaterialIssueMaster(
            slNo: existingItem.slNo,
            description: description,
            partNo: partNo,
            unit: unit,
            category: category,
            subCategory: subCategory,
            storageLocation: storage,
            rackNumber: rack,
            binNumber: bin,
            hsnCode: hsnCode,
            actualWeight: weight,
            inventoryClassification: invClass,
          );
          await notifier.updateCustomerScopeMaterialIssueMaster(existing.indexOf(existingItem), updatedItem);
          updated++;
        } else {
          final newItem = CustomerScopeMaterialIssueMaster(
            slNo: (existing.length + created + 1).toString(),
            description: description,
            partNo: partNo,
            unit: unit,
            category: category,
            subCategory: subCategory,
            storageLocation: storage,
            rackNumber: rack,
            binNumber: bin,
            hsnCode: hsnCode,
            actualWeight: weight,
            inventoryClassification: invClass,
          );
          await notifier.addCustomerScopeMaterialIssueMaster(newItem);
          created++;
        }
        processed++;
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Upload completed! Processed: $processed, Created: $created, Updated: $updated, Errors: $errors'),
            backgroundColor: errors > 0 ? Colors.orange : Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Upload failed: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _confirmDelete(
      BuildContext context, WidgetRef ref, CustomerScopeMaterialIssueMaster material) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
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

                // Delete the material
                await ref
                    .read(customerScopeMaterialIssueMasterListProvider.notifier)
                    .deleteCustomerScopeMaterialIssueMaster(material);

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

  @override
  Widget build(BuildContext context) {
    final materials = ref.watch(customerScopeMaterialIssueMasterListProvider);

    // Rebuild the grid rows when materials change
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && stateManager?.rows.isNotEmpty == true) {
        stateManager?.removeAllRows();
        stateManager?.appendRows(_getRows(materials, ref));
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Customer Scope Material Issue Master'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: _downloadBulkTemplate,
            tooltip: 'Download Template',
          ),
          IconButton(
            icon: const Icon(Icons.upload_file),
            onPressed: () => _showBulkUploadDialog(),
            tooltip: 'Bulk Upload',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddCustomerScopeMaterialIssueMasterPage()),
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
                              builder: (_) => const AddCustomerScopeMaterialIssueMasterPage()),
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
                      Text(
                        '${materials.length} Materials',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        child: PlutoGrid(
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
}
