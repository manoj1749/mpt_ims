// ignore_for_file: use_build_context_synchronously, unnecessary_type_check, avoid_print

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:mpt_ims/models/stock_maintenance.dart';
import 'package:mpt_ims/provider/stock_maintenance_provider.dart';
import 'package:pluto_grid/pluto_grid.dart';
import 'package:mpt_ims/widgets/pluto_grid_configuration.dart';
import 'package:dropdown_button2/dropdown_button2.dart';

class StockMaintenancePage extends ConsumerStatefulWidget {
  const StockMaintenancePage({super.key});

  @override
  StockMaintenancePageState createState() => StockMaintenancePageState();
}

class StockMaintenancePageState extends ConsumerState<StockMaintenancePage> {
  PlutoGridStateManager? stateManager;
  
  // Search functionality
  String _searchMode = 'all'; // 'all', 'part', 'supplier'
  String _searchQuery = '';
  List<String> _availablePartNumbers = [];
  List<String> _availableSuppliers = [];
  List<StockMaintenance> _filteredStocks = [];

  String _selectedStatus = 'All';
  double? _fromQty;
  double? _toQty;
  TextEditingController? _fromQtyController;
  TextEditingController? _toQtyController;

  int _gridRebuildToken = 0;
  Timer? _refreshDebounce;

  final TextEditingController _dropdownSearchController = TextEditingController();

  @override
  void initState() {
    super.initState();

    _fromQtyController = TextEditingController(text: _fromQty?.toString() ?? '');
    _toQtyController = TextEditingController(text: _toQty?.toString() ?? '');

    _fromQtyController!.addListener(() {
      final value = _fromQtyController!.text;
      _fromQty = value.isEmpty ? null : double.tryParse(value);
      _scheduleGridRefresh();
    });

    _toQtyController!.addListener(() {
      final value = _toQtyController!.text;
      _toQty = value.isEmpty ? null : double.tryParse(value);
      _scheduleGridRefresh();
    });

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (Hive.isBoxOpen('stock_maintenance')) {
        final box = Hive.box<StockMaintenance>('stock_maintenance');
        print('==== ALL StockMaintenance in stock_maintenance box ====');
        for (var stock in box.values) {
          print(stock.toString());
        }
        print('==== END StockMaintenance ====');
      } else {
        print('stock_maintenance box not open yet');
      }
      _initializeSearchData();
    });
  }

  @override
  void dispose() {
    _refreshDebounce?.cancel();
    _fromQtyController?.dispose();
    _toQtyController?.dispose();
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

  List<StockMaintenance> _applyAllFilters() {
    final baseStocks = _searchMode == 'all'
        ? ref.read(stockMaintenanceProvider)
        : _filteredStocks;

    Iterable<StockMaintenance> result = baseStocks;

    // Status-like filter
    switch (_selectedStatus) {
      case 'Low Stock':
        result = result.where((s) => s.currentStock > 0 && s.currentStock <= 10);
        break;
      case 'Zero Stock':
        result = result.where((s) => s.currentStock == 0);
        break;
      case 'Under Inspection':
        result = result.where((s) => s.stockUnderInspection > 0);
        break;
      case 'All':
      default:
        break;
    }

    // Qty filter (Current/Available stock)
    if (_fromQty != null || _toQty != null) {
      result = result.where((s) {
        final qty = s.currentStock;
        if (_fromQty != null && qty < _fromQty!) return false;
        if (_toQty != null && qty > _toQty!) return false;
        return true;
      });
    }

    return result.toList();
  }

  void _initializeSearchData() {
    final stocks = ref.read(stockMaintenanceProvider);
    _availablePartNumbers = stocks.map((s) => s.materialCode).toSet().toList()..sort();
    _availableSuppliers = stocks.expand((s) => s.vendorDetails.values.map((v) => v.vendorName)).toSet().toList()..sort();
    _filteredStocks = stocks;
  }

  void _performSearch(String query) {
    setState(() {
      _searchQuery = query;
      final allStocks = ref.read(stockMaintenanceProvider);
      
      if (_searchMode == 'all' || query.isEmpty) {
        _filteredStocks = allStocks;
      } else if (_searchMode == 'part') {
        // Search by part number
        _filteredStocks = allStocks.where((stock) => 
          stock.materialCode.toLowerCase().contains(query.toLowerCase()) ||
          stock.materialDescription.toLowerCase().contains(query.toLowerCase())
        ).toList();
      } else if (_searchMode == 'supplier') {
        // Search by supplier - show all stocks that have this supplier
        _filteredStocks = allStocks.where((stock) =>
          stock.vendorDetails.values.any((vendor) => 
            vendor.vendorName.toLowerCase().contains(query.toLowerCase())
          )
        ).toList();
      }
    });

    // PlutoGrid does not automatically rebuild its internal rows when the widget rebuilds.
    // Explicitly refresh so the table reflects the filtered results.
    _scheduleGridRefresh();
  }

  Widget _buildSearchBar() {
    Widget buildSearchableDropdown(List<String> options) {
      return DropdownButtonHideUnderline(
        child: DropdownButton2<String>(
          isExpanded: true,
          hint: Text(
            _searchMode == 'part' ? 'Select Part Number' : 'Select Supplier',
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
            _performSearch(value);
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Search mode selector
          Row(
            children: [
              const Text('Search Mode:', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              const SizedBox(width: 16),
              ToggleButtons(
                isSelected: [_searchMode == 'all', _searchMode == 'part', _searchMode == 'supplier'],
                onPressed: (index) {
                  setState(() {
                    _searchMode = ['all', 'part', 'supplier'][index];
                    _searchQuery = '';
                    _performSearch('');
                  });
                },
                children: const [
                  Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: Text('All')),
                  Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: Text('Part Number')),
                  Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: Text('Supplier')),
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
                  child: buildSearchableDropdown(
                    _searchMode == 'part'
                        ? _availablePartNumbers
                        : _availableSuppliers,
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

          const SizedBox(height: 12),
          Row(
            children: [
              SizedBox(
                width: 220,
                child: DropdownButtonFormField<String>(
                  decoration: InputDecoration(
                    labelText: 'Status Filter',
                    labelStyle: TextStyle(color: Colors.grey[300]),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8)),
                    fillColor: Colors.grey[800],
                    filled: true,
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  style: const TextStyle(color: Colors.white),
                  dropdownColor: Colors.grey[800],
                  value: _selectedStatus,
                  items: ['All', 'Low Stock', 'Zero Stock', 'Under Inspection']
                      .map((s) => DropdownMenuItem(
                            value: s,
                            child: Text(s,
                                style: const TextStyle(color: Colors.white)),
                          ))
                      .toList(),
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() => _selectedStatus = value);
                    _scheduleGridRefresh();
                  },
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 140,
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
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 140,
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
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  List<PlutoRow> _buildRows(List<StockMaintenance> stocks) {
    return stocks.map((stock) {
      // Use the stock's current values which are already net of issued quantities
      double currentStock = stock.currentStock;
      double totalStock = stock.totalStock;

      return PlutoRow(
        cells: {
          'materialCode': PlutoCell(value: stock.materialCode),
          'description': PlutoCell(value: stock.materialDescription),
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
    if (_searchMode == 'supplier' && _searchQuery.isNotEmpty) {
      // When searching by supplier, show part numbers
      return [
        PlutoColumn(
          title: 'Part Number',
          field: 'materialCode',
          type: PlutoColumnType.text(),
          width: 150,
          titleTextAlign: PlutoColumnTextAlign.center,
          textAlign: PlutoColumnTextAlign.center,
          enableEditingMode: false,
        ),
        PlutoColumn(
          title: 'Description',
          field: 'description',
          type: PlutoColumnType.text(),
          width: 250,
          titleTextAlign: PlutoColumnTextAlign.center,
          textAlign: PlutoColumnTextAlign.left,
          enableEditingMode: false,
        ),
        PlutoColumn(
          title: 'Available Stock',
          field: 'currentStock',
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
          title: 'Actions',
          field: 'actions',
          type: PlutoColumnType.text(),
          width: 100,
          enableEditingMode: false,
          renderer: (rendererContext) {
            final materialCode = rendererContext.row.cells['materialCode']!.value as String;
            return IconButton(
              icon: const Icon(Icons.info_outline, size: 20),
              onPressed: () => _showStockDetails(context, materialCode),
              color: Colors.blue,
              tooltip: 'View Stock Details',
              constraints: const BoxConstraints(
                minWidth: 32,
                minHeight: 32,
              ),
            );
          },
        ),
      ];
    }

    // Default columns for other search modes
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
          final stock = rendererContext.row.cells['actions']!.value as StockMaintenance;
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.info_outline, size: 20),
                onPressed: () => _showStockDetails(context, stock.materialCode),
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

  void _showStockDetails(BuildContext context, String materialCode) {
    final stock = ref
        .read(stockMaintenanceProvider.notifier)
        .getStockForMaterial(materialCode);
    if (stock == null) return;

    if (_searchMode == 'supplier') {
      // For supplier search, show part number details with stock price by job number
      _showSupplierPartDetails(context, stock);
    } else {
      // For part number search or all, show regular stock details
      showDialog(
        context: context,
        builder: (context) => Dialog(
          child: Container(
            width: MediaQuery.of(context).size.width * 0.8,
            height: MediaQuery.of(context).size.height * 0.8,
            padding: const EdgeInsets.all(16.0),
            child: StockDetailsView(stock: stock, searchMode: _searchMode, searchQuery: _searchQuery),
          ),
        ),
      );
    }
  }

  void _showSupplierPartDetails(BuildContext context, StockMaintenance stock) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          width: MediaQuery.of(context).size.width * 0.6,
          height: MediaQuery.of(context).size.height * 0.6,
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Stock Details for ${stock.materialDescription}',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              Text('Part Number: ${stock.materialCode}', style: Theme.of(context).textTheme.titleMedium),
              Text('Supplier: ${_searchQuery}', style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 16),
              Expanded(
                child: _buildStockPriceByJobNumber(stock),
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
          ),
        ),
      ),
    );
  }

  Widget _buildStockPriceByJobNumber(StockMaintenance stock) {
    // Group stock by job number and show prices
    Map<String, Map<String, dynamic>> jobStockData = {};

    // Calculate stock distribution by job
    for (var prEntry in stock.prDetails.entries) {
      final prNo = prEntry.key;
      final pr = prEntry.value;
      final jobNo = pr.jobNo.isEmpty ? 'General' : pr.jobNo;

      if (!jobStockData.containsKey(jobNo)) {
        jobStockData[jobNo] = {
          'received': 0.0,
          'issued': 0.0,
          'available': 0.0,
          'averageRate': 0.0,
          'totalValue': 0.0,
        };
      }

      jobStockData[jobNo]!['received'] = (jobStockData[jobNo]!['received'] as double) + pr.receivedQuantity;
      jobStockData[jobNo]!['issued'] = (jobStockData[jobNo]!['issued'] as double) + pr.issuedQuantity;
      jobStockData[jobNo]!['available'] = jobStockData[jobNo]!['received'] - jobStockData[jobNo]!['issued'];
    }

    // Calculate average rates for each job
    for (var jobNo in jobStockData.keys) {
      double totalValue = 0.0;
      double totalQty = 0.0;

      // Find rates from GRN details
      for (var grnEntry in stock.grnDetails.entries) {
        final grn = grnEntry.value;
        // Check if this GRN is associated with the job
        bool isForJob = false;
        for (var poEntry in stock.poDetails.entries) {
          if (poEntry.value.receivedQuantities.containsKey(grnEntry.key)) {
            final prQtys = poEntry.value.receivedQuantities[grnEntry.key]!;
            for (var prNo in prQtys.keys) {
              final prDetail = stock.prDetails[prNo];
              if (prDetail != null) {
                final prJobNo = prDetail.jobNo.isEmpty ? 'General' : prDetail.jobNo;
                if (prJobNo == jobNo) {
                  isForJob = true;
                  final qty = prQtys[prNo]!;
                  totalValue += qty * grn.rate;
                  totalQty += qty;
                  break;
                }
              }
            }
            if (isForJob) break;
          }
        }
      }

      if (totalQty > 0) {
        jobStockData[jobNo]!['averageRate'] = totalValue / totalQty;
        jobStockData[jobNo]!['totalValue'] = jobStockData[jobNo]!['available'] * (totalValue / totalQty);
      }
    }

    return ListView(
      children: jobStockData.entries.map((entry) {
        final jobNo = entry.key;
        final data = entry.value;
        final available = data['available'] as double;
        final avgRate = data['averageRate'] as double;
        final totalValue = data['totalValue'] as double;

        if (available <= 0) return const SizedBox.shrink();

        return Card(
          margin: const EdgeInsets.symmetric(vertical: 4),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Job Number: $jobNo', style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Available Stock: ${available.toStringAsFixed(2)} ${stock.unit}'),
                    Text('Average Rate: ₹${avgRate.toStringAsFixed(2)}'),
                  ],
                ),
                const SizedBox(height: 4),
                Text('Total Value: ₹${totalValue.toStringAsFixed(2)}', 
                     style: const TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Future<void> _editLocation(StockMaintenance stock) async {
    final locationController =
        TextEditingController(text: stock.storageLocation);
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
                  .read(stockMaintenanceProvider.notifier)
                  .updateStockLocation(
                    stock.materialCode,
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

  @override
  Widget build(BuildContext context) {
    // Ensure search data stays up to date as provider changes
    final allStocks = ref.watch(stockMaintenanceProvider);
    if (_searchMode == 'all') {
      _filteredStocks = allStocks;
    }

    final displayStocks = _applyAllFilters();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Stock Maintenance'),
        actions: [
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

                await ref.read(stockMaintenanceProvider.notifier).refresh();

                if (mounted) {
                  Navigator.pop(context); // close loading
                }

                if (!mounted) return;

                _initializeSearchData();
                _scheduleGridRefresh();

                if (stateManager != null) {
                  final refreshedStocks = _applyAllFilters();
                  stateManager!.removeAllRows();
                  stateManager!.appendRows(_buildRows(refreshedStocks));
                }

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Refreshed from server'),
                    backgroundColor: Colors.grey[850],
                    duration: const Duration(seconds: 1),
                  ),
                );
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
            tooltip: 'Refresh Stock Maintenance',
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          Expanded(
            child: PlutoGrid(
              key: ValueKey(_gridRebuildToken),
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
                  'Total Stock Value: ₹${ref.read(stockMaintenanceProvider.notifier).getTotalStockValue().toStringAsFixed(2)}',
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

class StockDetailsView extends StatefulWidget {
  final StockMaintenance stock;
  final String searchMode;
  final String searchQuery;

  const StockDetailsView({
    super.key, 
    required this.stock, 
    this.searchMode = 'all', 
    this.searchQuery = ''
  });

  @override
  State<StockDetailsView> createState() => _StockDetailsViewState();
}

class _StockDetailsViewState extends State<StockDetailsView> {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Stock Details - ${widget.stock.materialDescription}',
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ],
        ),
        Text(
          'Code: ${widget.stock.materialCode} | Unit: ${widget.stock.unit}',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 16),
        // For part number search, show job-wise view by default
        if (widget.searchMode == 'part') ...[
          _buildJobWiseStockView(),
        ] else ...[
          _buildSummaryView(),
        ],
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

  Widget _buildJobWiseStockView() {
    // Create a map to store aggregated quantities by job
    Map<String, Map<String, double>> jobTotals = {};

    // Initialize with all job numbers
    Set<String> allJobNumbers = {};
    for (var entry in widget.stock.prDetails.entries) {
      final jobNo = entry.value.jobNo.isEmpty ? 'General' : entry.value.jobNo;
      allJobNumbers.add(jobNo);
      jobTotals[jobNo] = {
        'received': 0.0,
        'issued': 0.0,
        'pendingDelivery': 0.0,
      };
    }
    allJobNumbers.addAll(widget.stock.jobDetails.keys);

    // Calculate totals from GRN details
    for (var grnEntry in widget.stock.grnDetails.entries) {
      final grnNo = grnEntry.key;
      final grnDetail = grnEntry.value;
      
      // Find PO that contains this GRN
      StockPODetails? poDetail;
      for (var poEntry in widget.stock.poDetails.entries) {
        if (poEntry.value.receivedQuantities.containsKey(grnNo)) {
          poDetail = poEntry.value;
          break;
        }
      }
      
      if (poDetail != null) {
        final prQuantities = poDetail.receivedQuantities[grnNo] ?? {};
        for (var prEntry in prQuantities.entries) {
          final prNo = prEntry.key;
          final qty = prEntry.value;
          final jobNo = widget.stock.prDetails[prNo]?.jobNo ?? 'General';
          jobTotals.putIfAbsent(jobNo,
              () => {'received': 0.0, 'issued': 0.0, 'pendingDelivery': 0.0});
          if (grnDetail.acceptedQuantity > 0) {
            // Only count accepted quantities
            jobTotals[jobNo]!['received'] =
                (jobTotals[jobNo]!['received'] ?? 0.0) + qty;
          }
        }
      }
    }

    // Add issued quantities and pending deliveries
    for (var jobEntry in widget.stock.jobDetails.entries) {
      final jobNo = jobEntry.key;
      jobTotals.putIfAbsent(jobNo, () => {'received': 0.0, 'issued': 0.0});
      jobTotals[jobNo]!['issued'] = jobEntry.value.consumedQuantity;
    }

    return Expanded(
      child: SingleChildScrollView(
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Stock Distribution by Job Number',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                const Divider(),
                ...jobTotals.entries.map((jobEntry) {
                  final jobNo = jobEntry.key;
                  final totals = jobEntry.value;
                  final received = totals['received'] ?? 0.0;
                  final issued = totals['issued'] ?? 0.0;
                  final pendingDelivery = totals['pendingDelivery'] ?? 0.0;

                  // Skip this job if no activity
                  if (received <= 0 && issued <= 0 && pendingDelivery <= 0) {
                    return const SizedBox.shrink();
                  }

                  return ExpansionTile(
                    title: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Job: $jobNo',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold),
                              ),
                            ),
                            Text(
                              'Available: ${(received - issued).toStringAsFixed(2)} ${widget.stock.unit}',
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Padding(
                          padding: const EdgeInsets.only(left: 16.0),
                          child: Column(
                            children: [
                              Wrap(
                                spacing: 24,
                                runSpacing: 4,
                                children: [
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Text('Total Received:'),
                                      const SizedBox(width: 8),
                                      Text(
                                          '${received.toStringAsFixed(2)} ${widget.stock.unit}'),
                                    ],
                                  ),
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Text('Total Issued:'),
                                      const SizedBox(width: 8),
                                      Text(
                                          '${issued.toStringAsFixed(2)} ${widget.stock.unit}'),
                                    ],
                                  ),
                                ],
                              ),
                              if (pendingDelivery > 0)
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text('Pending Delivery:'),
                                    Text(
                                        '${pendingDelivery.toStringAsFixed(2)} ${widget.stock.unit}',
                                        style: const TextStyle(
                                            color: Colors.orange)),
                                  ],
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    children: [
                      // Show detailed PR and GR information for this job
                      ..._buildJobDetailedInfo(jobNo),
                    ],
                  );
                }),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildJobDetailedInfo(String jobNo) {
    List<Widget> widgets = [];
    
    // Group GRNs by job number
    Map<String, List<String>> jobGRNs = {};
    
    for (var grnEntry in widget.stock.grnDetails.entries) {
      final grnNo = grnEntry.key;
      final grn = grnEntry.value;
      
      // Find PRs associated with this GRN that belong to the job
      for (var poEntry in widget.stock.poDetails.entries) {
        if (poEntry.value.receivedQuantities.containsKey(grnNo)) {
          final prQtys = poEntry.value.receivedQuantities[grnNo]!;
          for (var prNo in prQtys.keys) {
            final prDetail = widget.stock.prDetails[prNo];
            if (prDetail != null) {
              final prJobNo = prDetail.jobNo.isEmpty ? 'General' : prDetail.jobNo;
              if (prJobNo == jobNo) {
                jobGRNs.putIfAbsent(grnNo, () => []);
                if (!jobGRNs[grnNo]!.contains(prNo)) {
                  jobGRNs[grnNo]!.add(prNo);
                }
              }
            }
          }
        }
      }
    }
    
    // Build detailed widgets for each GRN in this job
    for (var grnEntry in jobGRNs.entries) {
      final grnNo = grnEntry.key;
      final prNos = grnEntry.value;
      final grn = widget.stock.grnDetails[grnNo]!;
      
      // Find supplier name
      String supplierName = 'Unknown';
      for (var poEntry in widget.stock.poDetails.entries) {
        if (poEntry.value.vendorId == grn.vendorId) {
          supplierName = poEntry.value.vendorId; // This is actually vendor ID, we might need to map to name
          break;
        }
      }
      
      widgets.add(
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'GR: $grnNo | Supplier: $supplierName | Date: ${grn.grnDate}',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  ...prNos.map((prNo) {
                    final prDetail = widget.stock.prDetails[prNo];
                    final prQty = widget.stock.poDetails.values
                        .expand((po) {
                          final receivedQtys = po.receivedQuantities[grnNo];
                          return receivedQtys?.entries ?? <MapEntry<String, double>>[];
                        })
                        .firstWhere((entry) => entry.key == prNo, orElse: () => MapEntry('', 0.0))
                        .value;
                    final issuedQty = grn.issuedQuantities[prNo] ?? 0.0;
                    
                    return Padding(
                      padding: const EdgeInsets.only(left: 16.0, top: 4.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('PR: $prNo'),
                          Text('Received: ${prQty.toStringAsFixed(2)} | Issued: ${issuedQty.toStringAsFixed(2)} | Available: ${(prQty - issuedQty).toStringAsFixed(2)} ${widget.stock.unit}'),
                        ],
                      ),
                    );
                  }),
                  const Divider(),
                ],
              ),
            ),
          ),
        ),
      );
    }
    
    return widgets;
  }

  Widget _buildSummaryView() {
    // Create a map to store aggregated quantities by job
    Map<String, Map<String, double>> jobTotals = {};

    // Initialize with all job numbers
    Set<String> allJobNumbers = {};
    for (var entry in widget.stock.prDetails.entries) {
      final jobNo = entry.value.jobNo.isEmpty ? 'General' : entry.value.jobNo;
      allJobNumbers.add(jobNo);
      jobTotals[jobNo] = {
        'received': 0.0,
        'issued': 0.0,
        'pendingDelivery': 0.0,
      };
    }
    allJobNumbers.addAll(widget.stock.jobDetails.keys);

    // Calculate totals from GRN details
    for (var grnEntry in widget.stock.grnDetails.entries) {
      final grnNo = grnEntry.key;
      final grnDetail = grnEntry.value;
      
      // Find PO that contains this GRN
      StockPODetails? poDetail;
      for (var poEntry in widget.stock.poDetails.entries) {
        if (poEntry.value.receivedQuantities.containsKey(grnNo)) {
          poDetail = poEntry.value;
          break;
        }
      }
      
      if (poDetail != null) {
        final prQuantities = poDetail.receivedQuantities[grnNo] ?? {};
        for (var prEntry in prQuantities.entries) {
          final prNo = prEntry.key;
          final qty = prEntry.value;
          final jobNo = widget.stock.prDetails[prNo]?.jobNo ?? 'General';
          jobTotals.putIfAbsent(jobNo,
              () => {'received': 0.0, 'issued': 0.0, 'pendingDelivery': 0.0});
          if (grnDetail.acceptedQuantity > 0) {
            // Only count accepted quantities
            jobTotals[jobNo]!['received'] =
                (jobTotals[jobNo]!['received'] ?? 0.0) + qty;
          }
        }
      }
    }

    // Add issued quantities and pending deliveries
    for (var jobEntry in widget.stock.jobDetails.entries) {
      final jobNo = jobEntry.key;
      jobTotals.putIfAbsent(jobNo, () => {'received': 0.0, 'issued': 0.0});
      jobTotals[jobNo]!['issued'] = jobEntry.value.consumedQuantity;
    }

    // Now group PRs by job number
    Map<String, List<MapEntry<String, StockPRDetails>>> jobWiseStock = {};
    for (var jobNo in allJobNumbers) {
      jobWiseStock[jobNo] = widget.stock.prDetails.entries
          .where((entry) =>
              entry.value.jobNo == jobNo ||
              (jobNo == 'General' && entry.value.jobNo.isEmpty))
          .toList();
    }

    return Expanded(
      child: SingleChildScrollView(
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Stock Distribution',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                const Divider(),
                ...jobTotals.entries.map((jobEntry) {
                  final jobNo = jobEntry.key;
                  final totals = jobEntry.value;
                  final received = totals['received'] ?? 0.0;
                  final issued = totals['issued'] ?? 0.0;
                  final pendingDelivery = totals['pendingDelivery'] ?? 0.0;

                  // Skip this job if no activity
                  if (received <= 0 && issued <= 0 && pendingDelivery <= 0) {
                    return const SizedBox.shrink();
                  }

                  return ExpansionTile(
                    title: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Job: $jobNo',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold),
                              ),
                            ),
                            Text(
                              'Available: ${(received - issued).toStringAsFixed(2)} ${widget.stock.unit}',
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Padding(
                          padding: const EdgeInsets.only(left: 16.0),
                          child: Column(
                            children: [
                              Wrap(
                                spacing: 24,
                                runSpacing: 4,
                                children: [
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Text('Total Received:'),
                                      const SizedBox(width: 8),
                                      Text(
                                          '${received.toStringAsFixed(2)} ${widget.stock.unit}'),
                                    ],
                                  ),
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Text('Total Issued:'),
                                      const SizedBox(width: 8),
                                      Text(
                                          '${issued.toStringAsFixed(2)} ${widget.stock.unit}'),
                                    ],
                                  ),
                                ],
                              ),
                              if (pendingDelivery > 0)
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text('Pending Delivery:'),
                                    Text(
                                        '${pendingDelivery.toStringAsFixed(2)} ${widget.stock.unit}',
                                        style: const TextStyle(
                                            color: Colors.orange)),
                                  ],
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    children: [
                      // Show PR details for this job
                      ...widget.stock.prDetails.entries
                          .where((prEntry) =>
                              (prEntry.value.jobNo == jobNo) ||
                              (jobNo == 'General' &&
                                  prEntry.value.jobNo.isEmpty))
                          .map((prEntry) {
                        final prNo = prEntry.key;
                        final pr = prEntry.value;

                        // Find vendor details from PO
                        String vendorName = '';
                        for (var poDetail in widget.stock.poDetails.entries) {
                          for (var grnQtys
                              in poDetail.value.receivedQuantities.values) {
                            if (grnQtys.containsKey(prNo)) {
                              vendorName = poDetail.value.vendorId;
                              break;
                            }
                          }
                          if (vendorName.isNotEmpty) break;
                        }

                        return Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'PR: $prNo | Vendor: $vendorName',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold),
                              ),
                              Padding(
                                padding: const EdgeInsets.only(left: 16.0),
                                child: Column(
                                  children: [
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Text('Received:'),
                                        const SizedBox(width: 8),
                                        Text(
                                            '${pr.receivedQuantity.toStringAsFixed(2)} ${widget.stock.unit}'),
                                      ],
                                    ),
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Text('Issued:'),
                                        const SizedBox(width: 8),
                                        Text(
                                            '${pr.issuedQuantity.toStringAsFixed(2)} ${widget.stock.unit}'),
                                      ],
                                    ),
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Text('Available:'),
                                        const SizedBox(width: 8),
                                        Text(
                                            '${(pr.receivedQuantity - pr.issuedQuantity).toStringAsFixed(2)} ${widget.stock.unit}'),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              const Divider(),
                            ],
                          ),
                        );
                      }).toList(),
                    ],
                  );
                }),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailedView() {
    return Expanded(
      child: SingleChildScrollView(
        child: _buildStockHistoryView(),
      ),
    );
  }

  Widget _buildStockHistoryView() {
    // Sort GRNs by date (newest first)
    final sortedGRNs = widget.stock.grnDetails.entries.toList()
      ..sort((a, b) => b.value.grnDate.compareTo(a.value.grnDate));

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: sortedGRNs.length,
      itemBuilder: (context, index) {
        final grnEntry = sortedGRNs[index];
        final grn = grnEntry.value;
        final grnNo = grnEntry.key;

        // For each PO, show all PRs for this GRN
        final prRows = <Widget>[];
        widget.stock.poDetails.forEach((poNo, po) {
          if (po.vendorId == grn.vendorId) {
            // Only show PRs from this vendor's PO
            final receivedQtys = po.receivedQuantities[grnNo];
            if (receivedQtys != null) {
              receivedQtys.forEach((prNo, qty) {
                if (qty > 0) {
                  final issuedQty = grn.issuedQuantities[prNo] ?? 0.0;
                  final prDetail = widget.stock.prDetails[prNo];
                  final jobNo = prDetail?.jobNo ?? 'General';
                  final jobDetail = widget.stock.jobDetails[jobNo];

                  prRows.add(
                    Padding(
                      padding: const EdgeInsets.only(
                          left: 16.0, top: 4.0, bottom: 4.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                prNo == 'General'
                                    ? 'General Stock'
                                    : 'PR: $prNo | Job: $jobNo',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                              Text(
                                'Received: ${qty.toStringAsFixed(2)} | Issued: ${issuedQty.toStringAsFixed(2)} | Available: ${(qty - issuedQty).toStringAsFixed(2)} ${widget.stock.unit}',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                          if (jobDetail != null)
                            Padding(
                              padding: const EdgeInsets.only(left: 24.0),
                              child: Text(
                                'Job Details - Allocated: ${jobDetail.allocatedQuantity} | Consumed: ${jobDetail.consumedQuantity}',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      color: Colors.grey[600],
                                    ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                }
              });
            }
          }
        });

        return Card(
          margin: const EdgeInsets.symmetric(vertical: 4.0),
          child: Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        flex: 2,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('GRN: $grnNo'),
                            Text(
                              'Date: ${grn.grnDate}',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            Text(
                              'Vendor: ${grn.vendorId}',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                                'Received: ${grn.receivedQuantity} ${widget.stock.unit}'),
                            if (grn.acceptedQuantity > 0)
                              Text(
                                'Accepted: ${grn.acceptedQuantity} ${widget.stock.unit}',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            if (grn.issuedQuantity > 0)
                              Text(
                                'Issued: ${grn.issuedQuantity} ${widget.stock.unit}',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            Text(
                              'Available: ${grn.availableQuantity} ${widget.stock.unit}',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Divider(),
                  ...prRows,
                ],
              ),
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Divider(),
                      Text('Rate: ₹${grn.rate.toStringAsFixed(2)}'),
                      if (grn.acceptedQuantity > 0)
                        Text(
                            'Value: ₹${(grn.acceptedQuantity * grn.rate).toStringAsFixed(2)}'),
                      if (grn.rejectedQuantity > 0)
                        Text(
                            'Rejected: ${grn.rejectedQuantity} ${widget.stock.unit}',
                            style: const TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
