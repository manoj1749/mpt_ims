// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pluto_grid/pluto_grid.dart';
import '../../models/customer_scope_stock_maintenance.dart';
import '../../provider/customer_scope_stock_maintenance_provider.dart';
import '../../widgets/pluto_grid_configuration.dart';
import 'package:file_picker/file_picker.dart';
import 'package:csv/csv.dart';
import 'dart:io';

class CustomerScopeStockMaintenancePage extends ConsumerStatefulWidget {
  const CustomerScopeStockMaintenancePage({super.key});

  @override
  CustomerScopeStockMaintenancePageState createState() => CustomerScopeStockMaintenancePageState();
}

class CustomerScopeStockMaintenancePageState extends ConsumerState<CustomerScopeStockMaintenancePage> {
  PlutoGridStateManager? stateManager;
  
  // Search functionality
  String _searchMode = 'all'; // 'all', 'part', 'customer'
  String _searchQuery = '';
  List<String> _availablePartNumbers = [];
  List<String> _availableCustomers = [];
  List<CustomerScopeStockMaintenance> _filteredStocks = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeSearchData();
    });
  }

  void _initializeSearchData() {
    final stocks = ref.read(customerScopeStockMaintenanceProvider);
    _availablePartNumbers = stocks.map((s) => s.materialCode).toSet().toList()..sort();
    _availableCustomers = stocks.map((s) => s.customerName).toSet().toList()..sort();
    _filteredStocks = stocks;
  }

  void _performSearch(String query) {
    setState(() {
      _searchQuery = query;
      final allStocks = ref.read(customerScopeStockMaintenanceProvider);
      
      if (_searchMode == 'all' || query.isEmpty) {
        _filteredStocks = allStocks;
      } else if (_searchMode == 'part') {
        // Search by part number
        _filteredStocks = allStocks.where((stock) => 
          stock.materialCode.toLowerCase().contains(query.toLowerCase()) ||
          stock.materialDescription.toLowerCase().contains(query.toLowerCase())
        ).toList();
      } else if (_searchMode == 'customer') {
        // Search by customer
        _filteredStocks = allStocks.where((stock) =>
          stock.customerName.toLowerCase().contains(query.toLowerCase())
        ).toList();
      }
    });
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.grey[900],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Search mode selector
          Row(
            children: [
              const Text('Search Mode:', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              const SizedBox(width: 16),
              ToggleButtons(
                isSelected: [_searchMode == 'all', _searchMode == 'part', _searchMode == 'customer'],
                onPressed: (index) {
                  setState(() {
                    _searchMode = ['all', 'part', 'customer'][index];
                    _searchQuery = '';
                    _performSearch('');
                  });
                },
                children: const [
                  Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: Text('All')),
                  Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: Text('Part Number')),
                  Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: Text('Customer')),
                ],
                borderColor: Colors.grey[600],
                selectedBorderColor: Colors.blue,
                selectedColor: Colors.white,
                fillColor: Colors.blue[900],
                color: Colors.grey[300],
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Search input
          if (_searchMode != 'all') ...[
            Row(
              children: [
                Expanded(
                  child: Autocomplete<String>(
                    optionsBuilder: (TextEditingValue textEditingValue) {
                      if (textEditingValue.text.isEmpty) {
                        return _searchMode == 'part' ? _availablePartNumbers : _availableCustomers;
                      }
                      final options = _searchMode == 'part' ? _availablePartNumbers : _availableCustomers;
                      return options.where((option) =>
                        option.toLowerCase().contains(textEditingValue.text.toLowerCase())
                      );
                    },
                    onSelected: (String selection) {
                      _performSearch(selection);
                    },
                    fieldViewBuilder: (context, textEditingController, focusNode, onFieldSubmitted) {
                      return TextField(
                        controller: textEditingController,
                        focusNode: focusNode,
                        decoration: InputDecoration(
                          labelText: _searchMode == 'part' ? 'Search Part Number' : 'Search Customer',
                          hintText: _searchMode == 'part' ? 'Enter part number or description' : 'Enter customer name',
                          border: const OutlineInputBorder(),
                          filled: true,
                          fillColor: Colors.grey[800],
                          labelStyle: const TextStyle(color: Colors.white),
                          hintStyle: const TextStyle(color: Colors.grey),
                        ),
                        style: const TextStyle(color: Colors.white),
                        onChanged: (value) {
                          _performSearch(value);
                        },
                      );
                    },
                  ),
                ),
                if (_searchQuery.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.clear, color: Colors.white),
                    onPressed: () {
                      _performSearch('');
                    },
                    tooltip: 'Clear search',
                  ),
                ],
              ],
            ),
          ],
          // Results summary
          if (_searchMode != 'all' && _searchQuery.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'Found ${_filteredStocks.length} result${_filteredStocks.length != 1 ? 's' : ''} for "${_searchQuery}"',
              style: const TextStyle(color: Colors.white70, fontSize: 14),
            ),
          ],
        ],
      ),
    );
  }

  List<PlutoRow> _buildRows(List<CustomerScopeStockMaintenance> stocks) {
    return stocks.map((stock) {
      double currentStock = stock.currentStock;
      double totalStock = stock.totalStock;

      return PlutoRow(
        cells: {
          'materialCode': PlutoCell(value: stock.materialCode),
          'description': PlutoCell(value: stock.materialDescription),
          'customerName': PlutoCell(value: stock.customerName),
          'currentStock': PlutoCell(value: currentStock),
          'underInspection': PlutoCell(value: stock.calculatedUnderInspection),
          'totalStock': PlutoCell(value: totalStock),
          'unit': PlutoCell(value: stock.unit),
          'location': PlutoCell(value: stock.storageLocation),
          'rack': PlutoCell(value: stock.rackNumber),
          'stockValue': PlutoCell(
              value: currentStock > 0 ? currentStock * stock.averageRate : 0),
          'avgRate': PlutoCell(value: stock.averageRate),
          'actions': PlutoCell(value: stock),
        },
      );
    }).toList();
  }

  List<PlutoColumn> _getColumns() {
    return [
      PlutoColumn(
        title: 'Material Code',
        field: 'materialCode',
        type: PlutoColumnType.text(),
        width: 120,
        titleTextAlign: PlutoColumnTextAlign.center,
        textAlign: PlutoColumnTextAlign.center,
        enableEditingMode: false,
      ),
      PlutoColumn(
        title: 'Description',
        field: 'description',
        type: PlutoColumnType.text(),
        width: 200,
        titleTextAlign: PlutoColumnTextAlign.center,
        textAlign: PlutoColumnTextAlign.left,
        enableEditingMode: false,
      ),
      PlutoColumn(
        title: 'Customer',
        field: 'customerName',
        type: PlutoColumnType.text(),
        width: 150,
        titleTextAlign: PlutoColumnTextAlign.center,
        textAlign: PlutoColumnTextAlign.left,
        enableEditingMode: false,
      ),
      PlutoColumn(
        title: 'Current Stock',
        field: 'currentStock',
        type: PlutoColumnType.number(),
        width: 120,
        titleTextAlign: PlutoColumnTextAlign.center,
        textAlign: PlutoColumnTextAlign.right,
        enableEditingMode: false,
      ),
      PlutoColumn(
        title: 'Under Inspection',
        field: 'underInspection',
        type: PlutoColumnType.number(),
        width: 120,
        titleTextAlign: PlutoColumnTextAlign.center,
        textAlign: PlutoColumnTextAlign.right,
        enableEditingMode: false,
      ),
      PlutoColumn(
        title: 'Total Stock',
        field: 'totalStock',
        type: PlutoColumnType.number(),
        width: 120,
        titleTextAlign: PlutoColumnTextAlign.center,
        textAlign: PlutoColumnTextAlign.right,
        enableEditingMode: false,
      ),
      PlutoColumn(
        title: 'Unit',
        field: 'unit',
        type: PlutoColumnType.text(),
        width: 80,
        titleTextAlign: PlutoColumnTextAlign.center,
        textAlign: PlutoColumnTextAlign.center,
        enableEditingMode: false,
      ),
      PlutoColumn(
        title: 'Location',
        field: 'location',
        type: PlutoColumnType.text(),
        width: 120,
        titleTextAlign: PlutoColumnTextAlign.center,
        textAlign: PlutoColumnTextAlign.center,
        enableEditingMode: false,
      ),
      PlutoColumn(
        title: 'Rack',
        field: 'rack',
        type: PlutoColumnType.text(),
        width: 100,
        titleTextAlign: PlutoColumnTextAlign.center,
        textAlign: PlutoColumnTextAlign.center,
        enableEditingMode: false,
      ),
      PlutoColumn(
        title: 'Stock Value',
        field: 'stockValue',
        type: PlutoColumnType.text(),
        width: 120,
        titleTextAlign: PlutoColumnTextAlign.center,
        textAlign: PlutoColumnTextAlign.right,
        enableEditingMode: false,
        formatter: (value) {
          if (value == null || value == 0) return '₹0.00';
          return '₹${value.toStringAsFixed(2)}';
        },
      ),
      PlutoColumn(
        title: 'Avg. Rate',
        field: 'avgRate',
        type: PlutoColumnType.text(),
        width: 120,
        titleTextAlign: PlutoColumnTextAlign.center,
        textAlign: PlutoColumnTextAlign.right,
        enableEditingMode: false,
        formatter: (value) {
          if (value == null || value == 0) return '₹0.00';
          return '₹${value.toStringAsFixed(2)}';
        },
      ),
      PlutoColumn(
        title: 'Actions',
        field: 'actions',
        type: PlutoColumnType.text(),
        width: 200,
        enableEditingMode: false,
        renderer: (rendererContext) {
          final stock = rendererContext.row.cells['actions']!.value as CustomerScopeStockMaintenance;
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.info_outline, size: 20),
                onPressed: () => _showStockDetails(context, stock),
                color: Colors.blue,
                tooltip: 'View Details',
                constraints: const BoxConstraints(
                  minWidth: 32,
                  minHeight: 32,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.edit_outlined, size: 20),
                onPressed: () => _editLocation(stock),
                color: Colors.green,
                tooltip: 'Edit Location',
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

  void _showStockDetails(BuildContext context, CustomerScopeStockMaintenance stock) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          width: MediaQuery.of(context).size.width * 0.8,
          height: MediaQuery.of(context).size.height * 0.8,
          padding: const EdgeInsets.all(16.0),
          child: CustomerScopeStockDetailsView(stock: stock),
        ),
      ),
    );
  }

  Future<void> _editLocation(CustomerScopeStockMaintenance stock) async {
    final locationController = TextEditingController(text: stock.storageLocation);
    final rackController = TextEditingController(text: stock.rackNumber);

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit Location - ${stock.materialDescription}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: locationController,
              decoration: const InputDecoration(labelText: 'Storage Location'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: rackController,
              decoration: const InputDecoration(labelText: 'Rack Number'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              await ref
                  .read(customerScopeStockMaintenanceProvider.notifier)
                  .updateStockLocation(
                    stock.materialCode,
                    stock.customerId,
                    locationController.text,
                    rackController.text,
                  );
              Navigator.of(context).pop();
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showBulkStockUploadDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Bulk Stock Upload (Customer Scope)'),
        content: const SizedBox(
          width: 520,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Upload a CSV with the following columns:'),
              SizedBox(height: 8),
              Text('• Material Code (as shown in this page)'),
              Text('• Customer (name)'),
              Text('• Quantity'),
              SizedBox(height: 12),
              Text('Optional columns:'),
              SizedBox(height: 8),
              Text('• Rate'),
              Text('• Storage Location'),
              Text('• Rack Number'),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              Navigator.pop(context);
              await _pickAndProcessStockFile();
            },
            child: const Text('Select File'),
          ),
        ],
      ),
    );
  }

  Future<void> _pickAndProcessStockFile() async {
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
          await _processStockCsvFile(file);
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

  Future<void> _processStockCsvFile(File file) async {
    try {
      final input = await file.readAsString();
      final rows = const CsvToListConverter().convert(input);
      if (rows.isEmpty) throw Exception('File is empty');

      final headers = rows[0].map((e) => e.toString().toLowerCase()).toList();
      final dataRows = rows.sublist(1);

      final codeIdx = _findHeader(headers, ['material code', 'part number', 'partno', 'code']);
      final custIdx = _findHeader(headers, ['customer', 'customer name']);
      final qtyIdx = _findHeader(headers, ['quantity', 'qty']);
      final rateIdx = _findHeader(headers, ['rate', 'price']);
      final locIdx = _findHeader(headers, ['storage location', 'location']);
      final rackIdx = _findHeader(headers, ['rack number', 'rack']);

      if (codeIdx == -1 || custIdx == -1 || qtyIdx == -1) {
        throw Exception('Required columns missing. Need: Material Code, Customer, Quantity');
      }

      await _showStockUploadPreview(dataRows, codeIdx, custIdx, qtyIdx, rateIdx, locIdx, rackIdx);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error processing file: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  int _findHeader(List<String> headers, List<String> names) {
    for (int i = 0; i < headers.length; i++) {
      final h = headers[i];
      if (names.any((n) => h.contains(n))) return i;
    }
    return -1;
  }

  Future<void> _showStockUploadPreview(
    List<List<dynamic>> dataRows,
    int codeIdx,
    int custIdx,
    int qtyIdx,
    int rateIdx,
    int locIdx,
    int rackIdx,
  ) async {
    final preview = <List<String>>[];
    for (int i = 0; i < dataRows.length && i < 10; i++) {
      final r = dataRows[i];
      String get(int idx) => (idx != -1 && idx < r.length) ? (r[idx]?.toString().trim() ?? '') : '';
      preview.add([
        get(codeIdx),
        get(custIdx),
        get(qtyIdx),
        get(rateIdx),
        get(locIdx),
        get(rackIdx),
      ]);
    }

    if (!mounted) return;
    showDialog(
      context: context,
      builder: (dctx) => AlertDialog(
        title: Text('Stock Upload Preview (${dataRows.length} rows)'),
        content: SizedBox(
          width: 800,
          height: 380,
          child: SingleChildScrollView(
            child: Table(
              border: TableBorder.all(),
              columnWidths: const {
                0: FlexColumnWidth(1.2),
                1: FlexColumnWidth(1.6),
                2: FlexColumnWidth(1),
                3: FlexColumnWidth(1),
                4: FlexColumnWidth(1.2),
                5: FlexColumnWidth(1),
              },
              children: [
                const TableRow(children: [
                  Padding(padding: EdgeInsets.all(8), child: Text('Material Code', style: TextStyle(fontWeight: FontWeight.bold))),
                  Padding(padding: EdgeInsets.all(8), child: Text('Customer', style: TextStyle(fontWeight: FontWeight.bold))),
                  Padding(padding: EdgeInsets.all(8), child: Text('Qty', style: TextStyle(fontWeight: FontWeight.bold))),
                  Padding(padding: EdgeInsets.all(8), child: Text('Rate', style: TextStyle(fontWeight: FontWeight.bold))),
                  Padding(padding: EdgeInsets.all(8), child: Text('Location', style: TextStyle(fontWeight: FontWeight.bold))),
                  Padding(padding: EdgeInsets.all(8), child: Text('Rack', style: TextStyle(fontWeight: FontWeight.bold))),
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
                await _processStockUpload(dataRows, codeIdx, custIdx, qtyIdx, rateIdx, locIdx, rackIdx);
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

  Future<void> _processStockUpload(
    List<List<dynamic>> dataRows,
    int codeIdx,
    int custIdx,
    int qtyIdx,
    int rateIdx,
    int locIdx,
    int rackIdx,
  ) async {
    try {
      final notifier = ref.read(customerScopeStockMaintenanceProvider.notifier);
      final current = ref.read(customerScopeStockMaintenanceProvider);
      int processed = 0, created = 0, updated = 0, errors = 0;

      for (final row in dataRows) {
        int minIdx = [codeIdx, custIdx, qtyIdx].reduce((a, b) => a > b ? a : b);
        if (row.length <= minIdx) { errors++; continue; }

        String get(int idx) => (idx != -1 && idx < row.length) ? (row[idx]?.toString().trim() ?? '') : '';
        final materialCode = get(codeIdx);
        final customerName = get(custIdx);
        final qtyStr = get(qtyIdx);
        if (materialCode.isEmpty || customerName.isEmpty || qtyStr.isEmpty) { errors++; continue; }
        final qty = double.tryParse(qtyStr) ?? 0.0;
        if (qty <= 0) { errors++; continue; }
        final rate = double.tryParse(get(rateIdx)) ?? 0.0;
        final location = get(locIdx);
        final rack = get(rackIdx);

        // Use customer name as ID if no separate ID mapping is available
        final customerId = customerName.toLowerCase().replaceAll(' ', '_');

        // Find or create stock
        var stock = current.firstWhere(
          (s) => s.materialCode.toLowerCase() == materialCode.toLowerCase() && s.customerId == customerId,
          orElse: () => CustomerScopeStockMaintenance(
            materialCode: materialCode,
            materialDescription: materialCode,
            unit: '',
            storageLocation: location,
            rackNumber: rack,
            customerName: customerName,
            customerId: customerId,
            currentStock: 0,
            stockUnderInspection: 0,
          ),
        );

        final isNew = !current.any((s) => s.materialCode.toLowerCase() == materialCode.toLowerCase() && s.customerId == customerId);

        // Create synthetic GRN entry key
        final grnKey = 'BULK-${DateTime.now().millisecondsSinceEpoch}-${processed + 1}';
        stock.grnDetails[grnKey] = CustomerScopeGRNDetails(
          grnNo: grnKey,
          grnDate: DateTime.now().toIso8601String().substring(0, 10),
          receivedQuantity: qty,
          acceptedQuantity: qty,
          rejectedQuantity: 0,
          rate: rate,
          issuedQuantity: 0,
          issuedQuantities: {},
        );

        // Recalculate aggregates
        double totalCurrent = 0.0;
        double totalUnderInsp = 0.0;
        for (final d in stock.grnDetails.values) {
          totalCurrent += d.acceptedQuantity - d.issuedQuantity;
          totalUnderInsp += d.receivedQuantity - (d.acceptedQuantity + d.rejectedQuantity);
        }
        stock.updateCurrentStock(totalCurrent);
        stock.updateStockUnderInspection(totalUnderInsp);

        // Update optional fields if provided
        if (location.isNotEmpty) stock.storageLocation = location;
        if (rack.isNotEmpty) stock.rackNumber = rack;

        if (isNew) {
          await notifier.add(stock);
          created++;
        } else {
          await notifier.update(stock);
          updated++;
        }
        processed++;
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Stock upload completed! Processed: $processed, Created: $created, Updated: $updated, Errors: $errors'),
            backgroundColor: errors > 0 ? Colors.orange : Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Stock upload failed: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Use filtered stocks for display
    final displayStocks = _searchMode == 'all' ? ref.watch(customerScopeStockMaintenanceProvider) : _filteredStocks;

    // Update filtered stocks when provider changes
    if (_searchMode == 'all') {
      _filteredStocks = displayStocks;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Customer Scope Stock Maintenance'),
        actions: [
          TextButton.icon(
            onPressed: _showBulkStockUploadDialog,
            icon: const Icon(Icons.upload_file, color: Colors.white),
            label: const Text('Bulk Stock Upload', style: TextStyle(color: Colors.white)),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() {
                _initializeSearchData();
              });
            },
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          Expanded(
            child: PlutoGrid(
              columns: _getColumns(),
              rows: _buildRows(displayStocks),
              onLoaded: (event) => stateManager = event.stateManager,
              configuration: PlutoGridConfigurations.darkMode(),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey[100],
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  'Total Stock Value: ₹${ref.read(customerScopeStockMaintenanceProvider.notifier).getTotalStockValue().toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class CustomerScopeStockDetailsView extends StatelessWidget {
  final CustomerScopeStockMaintenance stock;

  const CustomerScopeStockDetailsView({
    super.key, 
    required this.stock,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Customer Scope Stock Details - ${stock.materialDescription}',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        Text(
          'Code: ${stock.materialCode} | Customer: ${stock.customerName} | Unit: ${stock.unit}',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 16),
        Expanded(
          child: _buildGRNDetailsView(),
        ),
        const SizedBox(height: 16),
        Align(
          alignment: Alignment.bottomRight,
          child: TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ),
      ],
    );
  }

  Widget _buildGRNDetailsView() {
    return SingleChildScrollView(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'GRN-wise Stock Details',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              const Divider(),
              ...stock.grnDetails.entries.map((grnEntry) {
                final grnNo = grnEntry.key;
                final grn = grnEntry.value;
                final available = grn.acceptedQuantity - grn.issuedQuantity;

                return ExpansionTile(
                  title: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'GRN: $grnNo',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(left: 16.0),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Date:'),
                                Text(grn.grnDate),
                              ],
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Received:'),
                                Text('${grn.receivedQuantity.toStringAsFixed(2)} ${stock.unit}'),
                              ],
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Accepted:'),
                                Text('${grn.acceptedQuantity.toStringAsFixed(2)} ${stock.unit}'),
                              ],
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Rejected:'),
                                Text('${grn.rejectedQuantity.toStringAsFixed(2)} ${stock.unit}'),
                              ],
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Issued:'),
                                Text('${grn.issuedQuantity.toStringAsFixed(2)} ${stock.unit}'),
                              ],
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Available:'),
                                Text(
                                  '${available.toStringAsFixed(2)} ${stock.unit}',
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Rate:'),
                                Text('₹${grn.rate.toStringAsFixed(2)}'),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  children: [
                    if (grn.issuedQuantities.isNotEmpty) ...[
                      const Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Text(
                          'Issue Details:',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      ...grn.issuedQuantities.entries.map((issueEntry) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Issue No: ${issueEntry.key}'),
                              Text('${issueEntry.value.toStringAsFixed(2)} ${stock.unit}'),
                            ],
                          ),
                        );
                      }),
                    ],
                  ],
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}
