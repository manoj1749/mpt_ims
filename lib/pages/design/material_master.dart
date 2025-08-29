// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mpt_ims/pages/design/add_material_page.dart';
import 'package:mpt_ims/provider/material_provider.dart';
import 'package:mpt_ims/models/material_item.dart';

import 'package:pluto_grid/pluto_grid.dart';
import 'package:collection/collection.dart';
import 'package:file_picker/file_picker.dart';
import 'package:csv/csv.dart';
import 'dart:io';
import '../../widgets/pluto_grid_configuration.dart';
import '../../provider/stock_maintenance_provider.dart';
import '../../models/stock_maintenance.dart';

class MaterialMasterPage extends ConsumerStatefulWidget {
  const MaterialMasterPage({super.key});

  @override
  ConsumerState<MaterialMasterPage> createState() => _MaterialMasterPageState();
}

class _MaterialMasterPageState extends ConsumerState<MaterialMasterPage> {
  PlutoGridStateManager? stateManager;
  bool _isLoading = true;

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
        title: 'Preferred Vendor',
        field: 'preferredVendor',
        type: PlutoColumnType.text(),
        width: 150,
        enableEditingMode: false,
      ),
      PlutoColumn(
        title: 'Purchase Rate',
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
    return materials.map((m) {
      return PlutoRow(
        cells: {
          'slNo': PlutoCell(value: m.slNo),
          'partNo': PlutoCell(value: m.partNo),
          'description': PlutoCell(value: m.description),
          'category': PlutoCell(value: m.category),
          'subCategory': PlutoCell(value: m.subCategory),
          'unit': PlutoCell(value: m.unit),
          'actualWeight': PlutoCell(value: m.actualWeight),
          'storageLocation': PlutoCell(value: m.storageLocation),
          'rackNumber': PlutoCell(value: m.rackNumber),
          'binNumber': PlutoCell(
              value: m.binNumber?.isEmpty ?? true ? '-' : m.binNumber),
          'hsnCode':
              PlutoCell(value: m.hsnCode?.isEmpty ?? true ? '-' : m.hsnCode),
          'preferredVendor': PlutoCell(value: m.getPreferredVendorName()),
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

    // Rebuild the grid rows when either materials or vendor rates change
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && stateManager?.rows.isNotEmpty == true) {
        stateManager?.removeAllRows();
        stateManager?.appendRows(_getRows(materials, ref));
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Material Master'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.upload_file),
            onPressed: () => _showBulkUploadDialog(),
            tooltip: 'Bulk Stock Upload',
          ),
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              // TODO: Implement search
            },
            tooltip: 'Search Materials',
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
                          Text(
                            '${materials.length} Materials',
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
      builder: (context) => AlertDialog(
        title: const Text('Bulk Stock Upload'),
        content: SizedBox(
          width: 500,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Upload an Excel/CSV file with the following columns:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              const Text('Required columns:'),
              const SizedBox(height: 8),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('• Part Number (Material Code)'),
                  Text('• Description'),
                  Text('• Quantity'),
                  Text('• Unit'),
                  Text('• HSN Code'),
                  Text('• Stock Number (optional)'),
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
                  Text('• If material exists, quantity will be added to General stock'),
                  Text('• If material doesn\'t exist, it will be created'),
                  Text('• All other details must match for existing materials'),
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
            onPressed: () {
              Navigator.pop(context);
              _pickAndProcessFile();
            },
            child: const Text('Select File'),
          ),
        ],
      ),
    );
  }

  Future<void> _pickAndProcessFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv', 'xlsx'],
        allowMultiple: false,
      );

      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);
        final extension = result.files.single.extension?.toLowerCase();
        
        if (extension == 'csv') {
          await _processCsvFile(file);
        } else if (extension == 'xlsx') {
          // For now, show message to convert to CSV
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please convert Excel file to CSV format and try again'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error picking file: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _processCsvFile(File file) async {
    try {
      final input = await file.readAsString();
      final fields = const CsvToListConverter().convert(input);
      
      if (fields.isEmpty) {
        throw Exception('File is empty');
      }

      final headers = fields[0].map((e) => e.toString().toLowerCase()).toList();
      final dataRows = fields.sublist(1);

      // Find required column indices
      final partNoIndex = _findColumnIndex(headers, ['part number', 'material code', 'partno', 'part_number']);
      final descriptionIndex = _findColumnIndex(headers, ['description', 'desc', 'material description']);
      final quantityIndex = _findColumnIndex(headers, ['quantity', 'qty', 'stock quantity']);
      final unitIndex = _findColumnIndex(headers, ['unit', 'uom', 'unit of measure']);
      final hsnIndex = _findColumnIndex(headers, ['hsn code', 'hsn', 'hsncode', 'hsn_code']);
      final stockNoIndex = _findColumnIndex(headers, ['stock number', 'stock no', 'stockno', 'stock_number']);

      if (partNoIndex == -1 || descriptionIndex == -1 || quantityIndex == -1 || unitIndex == -1) {
        throw Exception('Required columns not found. Please ensure your file has: Part Number, Description, Quantity, and Unit columns');
      }

      await _showUploadPreview(dataRows, partNoIndex, descriptionIndex, quantityIndex, unitIndex, hsnIndex, stockNoIndex);

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
    int quantityIndex,
    int unitIndex,
    int hsnIndex,
    int stockNoIndex,
  ) async {
    final previewData = <Map<String, dynamic>>[];
    final existingMaterials = ref.read(materialListProvider);
    
    for (int i = 0; i < dataRows.length && i < 10; i++) { // Show first 10 rows for preview
      final row = dataRows[i];
      if (row.length <= [partNoIndex, descriptionIndex, quantityIndex, unitIndex].reduce((a, b) => a > b ? a : b)) {
        continue;
      }

      final partNo = row[partNoIndex]?.toString().trim() ?? '';
      final description = row[descriptionIndex]?.toString().trim() ?? '';
      final quantity = double.tryParse(row[quantityIndex]?.toString() ?? '0') ?? 0.0;
      final unit = row[unitIndex]?.toString().trim() ?? '';
      final hsnCode = hsnIndex != -1 ? (row[hsnIndex]?.toString().trim() ?? '') : '';
      final stockNo = stockNoIndex != -1 ? (row[stockNoIndex]?.toString().trim() ?? '') : '';

      final existingMaterial = existingMaterials.firstWhereOrNull((m) => m.partNo == partNo);
      final status = existingMaterial != null ? 'Update' : 'New';

      previewData.add({
        'partNo': partNo,
        'description': description,
        'quantity': quantity,
        'unit': unit,
        'hsnCode': hsnCode,
        'stockNo': stockNo,
        'status': status,
      });
    }

    if (mounted) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Upload Preview (${dataRows.length} total rows)'),
          content: SizedBox(
            width: 800,
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
                        3: FlexColumnWidth(1),
                        4: FlexColumnWidth(1),
                        5: FlexColumnWidth(1),
                        6: FlexColumnWidth(1),
                      },
                      children: [
                        const TableRow(
                          decoration: BoxDecoration(color: Colors.grey),
                          children: [
                            Padding(padding: EdgeInsets.all(8), child: Text('Part No', style: TextStyle(fontWeight: FontWeight.bold))),
                            Padding(padding: EdgeInsets.all(8), child: Text('Description', style: TextStyle(fontWeight: FontWeight.bold))),
                            Padding(padding: EdgeInsets.all(8), child: Text('Qty', style: TextStyle(fontWeight: FontWeight.bold))),
                            Padding(padding: EdgeInsets.all(8), child: Text('Unit', style: TextStyle(fontWeight: FontWeight.bold))),
                            Padding(padding: EdgeInsets.all(8), child: Text('HSN', style: TextStyle(fontWeight: FontWeight.bold))),
                            Padding(padding: EdgeInsets.all(8), child: Text('Stock No', style: TextStyle(fontWeight: FontWeight.bold))),
                            Padding(padding: EdgeInsets.all(8), child: Text('Status', style: TextStyle(fontWeight: FontWeight.bold))),
                          ],
                        ),
                        ...previewData.map((data) => TableRow(
                          children: [
                            Padding(padding: const EdgeInsets.all(8), child: Text(data['partNo'])),
                            Padding(padding: const EdgeInsets.all(8), child: Text(data['description'])),
                            Padding(padding: const EdgeInsets.all(8), child: Text(data['quantity'].toString())),
                            Padding(padding: const EdgeInsets.all(8), child: Text(data['unit'])),
                            Padding(padding: const EdgeInsets.all(8), child: Text(data['hsnCode'])),
                            Padding(padding: const EdgeInsets.all(8), child: Text(data['stockNo'])),
                            Padding(
                              padding: const EdgeInsets.all(8), 
                              child: Text(
                                data['status'],
                                style: TextStyle(
                                  color: data['status'] == 'New' ? Colors.green : Colors.blue,
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
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(context);
                _processUpload(dataRows, partNoIndex, descriptionIndex, quantityIndex, unitIndex, hsnIndex, stockNoIndex);
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
    int quantityIndex,
    int unitIndex,
    int hsnIndex,
    int stockNoIndex,
  ) async {
    try {
      final materialNotifier = ref.read(materialListProvider.notifier);
      final stockNotifier = ref.read(stockMaintenanceProvider.notifier);
      final existingMaterials = ref.read(materialListProvider);
      
      int processed = 0;
      int created = 0;
      int updated = 0;
      int errors = 0;

      for (final row in dataRows) {
        try {
          if (row.length <= [partNoIndex, descriptionIndex, quantityIndex, unitIndex].reduce((a, b) => a > b ? a : b)) {
            continue;
          }

          final partNo = row[partNoIndex]?.toString().trim() ?? '';
          final description = row[descriptionIndex]?.toString().trim() ?? '';
          final quantity = double.tryParse(row[quantityIndex]?.toString() ?? '0') ?? 0.0;
          final unit = row[unitIndex]?.toString().trim() ?? '';
          final hsnCode = hsnIndex != -1 ? (row[hsnIndex]?.toString().trim() ?? '') : '';
          final stockNo = stockNoIndex != -1 ? (row[stockNoIndex]?.toString().trim() ?? '') : '';

          if (partNo.isEmpty || description.isEmpty || quantity <= 0 || unit.isEmpty) {
            errors++;
            continue;
          }

          // Check if material exists
          final existingMaterial = existingMaterials.firstWhereOrNull((m) => m.partNo == partNo);
          
          if (existingMaterial != null) {
            // Material exists - verify details match and update stock
            if (existingMaterial.description != description || existingMaterial.unit != unit) {
              print('Warning: Material $partNo details don\'t match. Skipping.');
              errors++;
              continue;
            }
            
            // Add to general stock
            await _addToGeneralStock(partNo, quantity, stockNotifier);
            updated++;
          } else {
            // Create new material
            final newSlNo = (existingMaterials.length + 1).toString();
            final newMaterial = MaterialItem(
              slNo: newSlNo,
              partNo: partNo,
              description: description,
              unit: unit,
              category: 'General', // Default category for bulk upload
              subCategory: 'General', // Default subcategory for bulk upload
              rackNumber: '',
              binNumber: stockNo.isNotEmpty ? stockNo : '-',
              hsnCode: hsnCode.isNotEmpty ? hsnCode : '-',
              saleRate: '',
              actualWeight: '',
              vendorRates: [],
            );
            
            await materialNotifier.addMaterial(newMaterial);
            
            // Add to general stock
            await _addToGeneralStock(partNo, quantity, stockNotifier);
            created++;
          }
          
          processed++;
        } catch (e) {
          print('Error processing row: $e');
          errors++;
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Upload completed!\nProcessed: $processed\nCreated: $created\nUpdated: $updated\nErrors: $errors'
            ),
            backgroundColor: errors > 0 ? Colors.orange : Colors.green,
            duration: const Duration(seconds: 4),
          ),
        );
      }

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error during upload: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _addToGeneralStock(String partNo, double quantity, StockMaintenanceNotifier stockNotifier) async {
    try {
      // Check if stock record exists
      final existingStocks = ref.read(stockMaintenanceProvider);
      final existingStock = existingStocks.firstWhereOrNull((s) => s.materialCode == partNo);
      
      if (existingStock != null) {
        // Update existing stock
        existingStock.currentStock += quantity;
        await stockNotifier.update(existingStock);
      } else {
        // Create new stock record
        final material = ref.read(materialListProvider).firstWhere((m) => m.partNo == partNo);
        final newStock = StockMaintenance(
          materialCode: partNo,
          materialDescription: material.description,
          unit: material.unit,
          storageLocation: '',
          rackNumber: material.rackNumber ?? '',
          currentStock: quantity,
          stockUnderInspection: 0.0,
          totalStockValue: 0.0,
          grnDetails: {},
          poDetails: {},
          prDetails: {},
          jobDetails: {},
          vendorDetails: {},
        );
        
        await stockNotifier.add(newStock);
      }
    } catch (e) {
      print('Error adding to general stock for $partNo: $e');
      rethrow;
    }
  }
}
