import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pluto_grid/pluto_grid.dart';
import '../../models/stock_maintenance.dart';
import '../../provider/stock_maintenance_provider.dart';
import '../../widgets/pluto_grid_configuration.dart';

class StockMaintenancePage extends ConsumerStatefulWidget {
  const StockMaintenancePage({super.key});

  @override
  ConsumerState<StockMaintenancePage> createState() => _StockMaintenancePageState();
}

class _StockMaintenancePageState extends ConsumerState<StockMaintenancePage> {
  PlutoGridStateManager? stateManager;
  bool _isLoading = false;

  List<PlutoRow> _buildRows(List<StockMaintenance> stocks) {
    return stocks.map((stock) {
      return PlutoRow(
        cells: {
          'materialCode': PlutoCell(value: stock.materialCode),
          'description': PlutoCell(value: stock.materialDescription),
          'currentStock': PlutoCell(value: stock.currentStock),
          'underInspection': PlutoCell(value: stock.stockUnderInspection),
          'totalStock': PlutoCell(value: stock.totalStock),
          'unit': PlutoCell(value: stock.unit),
          'location': PlutoCell(value: stock.storageLocation),
          'rack': PlutoCell(value: stock.rackNumber),
          'value': PlutoCell(value: stock.totalStockValue),
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
        field: 'value',
        type: PlutoColumnType.number(),
        width: 120,
        titleTextAlign: PlutoColumnTextAlign.center,
        textAlign: PlutoColumnTextAlign.right,
        enableEditingMode: false,
        renderer: (rendererContext) {
          final value = rendererContext.cell.value as num;
          return Text('₹${value.toStringAsFixed(2)}');
        },
      ),
      PlutoColumn(
        title: 'Avg. Rate',
        field: 'avgRate',
        type: PlutoColumnType.number(),
        width: 120,
        titleTextAlign: PlutoColumnTextAlign.center,
        textAlign: PlutoColumnTextAlign.right,
        enableEditingMode: false,
        renderer: (rendererContext) {
          final value = rendererContext.cell.value as num;
          return Text('₹${value.toStringAsFixed(2)}');
        },
      ),
      PlutoColumn(
        title: 'Actions',
        field: 'actions',
        type: PlutoColumnType.text(),
        width: 120,
        titleTextAlign: PlutoColumnTextAlign.center,
        textAlign: PlutoColumnTextAlign.center,
        enableEditingMode: false,
        renderer: (rendererContext) {
          final stock = rendererContext.cell.value as StockMaintenance;
          return Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.info_outline, size: 20),
                onPressed: () => _showStockDetails(stock),
                color: Colors.blue,
                tooltip: 'View Details',
                constraints: const BoxConstraints(
                  minWidth: 32,
                  minHeight: 32,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.edit_location_outlined, size: 20),
                onPressed: () => _editLocation(stock),
                color: Colors.orange,
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

  Future<void> _showStockDetails(StockMaintenance stock) async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Stock Details - ${stock.materialDescription}'),
        content: SizedBox(
          width: MediaQuery.of(context).size.width * 0.8,
          height: MediaQuery.of(context).size.height * 0.8,
          child: DefaultTabController(
            length: 5,
            child: Column(
              children: [
                const TabBar(
                  tabs: [
                    Tab(text: 'GRN Details'),
                    Tab(text: 'PO Details'),
                    Tab(text: 'PR Details'),
                    Tab(text: 'Job Details'),
                    Tab(text: 'Vendor Details'),
                  ],
                ),
                Expanded(
                  child: TabBarView(
                    children: [
                      _buildGRNDetailsTable(stock),
                      _buildPODetailsTable(stock),
                      _buildPRDetailsTable(stock),
                      _buildJobDetailsTable(stock),
                      _buildVendorDetailsTable(stock),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildGRNDetailsTable(StockMaintenance stock) {
    final columns = [
      DataColumn(label: Text('GRN No')),
      DataColumn(label: Text('Date')),
      DataColumn(label: Text('Received')),
      DataColumn(label: Text('Accepted')),
      DataColumn(label: Text('Rejected')),
      DataColumn(label: Text('Rate')),
    ];

    final rows = stock.grnDetails.entries.map((entry) {
      final grn = entry.value;
      return DataRow(cells: [
        DataCell(Text(grn.grnNo)),
        DataCell(Text(grn.grnDate)),
        DataCell(Text(grn.receivedQuantity.toString())),
        DataCell(Text(grn.acceptedQuantity.toString())),
        DataCell(Text(grn.rejectedQuantity.toString())),
        DataCell(Text('₹${grn.rate.toStringAsFixed(2)}')),
      ]);
    }).toList();

    return SingleChildScrollView(
      child: DataTable(columns: columns, rows: rows),
    );
  }

  Widget _buildPODetailsTable(StockMaintenance stock) {
    final columns = [
      DataColumn(label: Text('PO No')),
      DataColumn(label: Text('Date')),
      DataColumn(label: Text('Ordered')),
      DataColumn(label: Text('Received')),
      DataColumn(label: Text('Rate')),
    ];

    final rows = stock.poDetails.entries.map((entry) {
      final po = entry.value;
      return DataRow(cells: [
        DataCell(Text(po.poNo)),
        DataCell(Text(po.poDate)),
        DataCell(Text(po.orderedQuantity.toString())),
        DataCell(Text(po.receivedQuantity.toString())),
        DataCell(Text('₹${po.rate.toStringAsFixed(2)}')),
      ]);
    }).toList();

    return SingleChildScrollView(
      child: DataTable(columns: columns, rows: rows),
    );
  }

  Widget _buildPRDetailsTable(StockMaintenance stock) {
    final columns = [
      DataColumn(label: Text('PR No')),
      DataColumn(label: Text('Date')),
      DataColumn(label: Text('Requested')),
      DataColumn(label: Text('Ordered')),
      DataColumn(label: Text('Received')),
    ];

    final rows = stock.prDetails.entries.map((entry) {
      final pr = entry.value;
      return DataRow(cells: [
        DataCell(Text(pr.prNo)),
        DataCell(Text(pr.prDate)),
        DataCell(Text(pr.requestedQuantity.toString())),
        DataCell(Text(pr.orderedQuantity.toString())),
        DataCell(Text(pr.receivedQuantity.toString())),
      ]);
    }).toList();

    return SingleChildScrollView(
      child: DataTable(columns: columns, rows: rows),
    );
  }

  Widget _buildJobDetailsTable(StockMaintenance stock) {
    final columns = [
      DataColumn(label: Text('Job No')),
      DataColumn(label: Text('PR No')),
      DataColumn(label: Text('Allocated')),
      DataColumn(label: Text('Consumed')),
      DataColumn(label: Text('Balance')),
    ];

    final rows = stock.jobDetails.entries.map((entry) {
      final job = entry.value;
      return DataRow(cells: [
        DataCell(Text(job.jobNo)),
        DataCell(Text(job.prNo)),
        DataCell(Text(job.allocatedQuantity.toString())),
        DataCell(Text(job.consumedQuantity.toString())),
        DataCell(Text((job.allocatedQuantity - job.consumedQuantity).toString())),
      ]);
    }).toList();

    return SingleChildScrollView(
      child: DataTable(columns: columns, rows: rows),
    );
  }

  Widget _buildVendorDetailsTable(StockMaintenance stock) {
    final columns = [
      DataColumn(label: Text('Vendor')),
      DataColumn(label: Text('Quantity')),
      DataColumn(label: Text('Rate')),
      DataColumn(label: Text('Value')),
      DataColumn(label: Text('Last Purchase')),
    ];

    final rows = stock.vendorDetails.entries.map((entry) {
      final vendor = entry.value;
      return DataRow(cells: [
        DataCell(Text(vendor.vendorName)),
        DataCell(Text(vendor.quantity.toString())),
        DataCell(Text('₹${vendor.rate.toStringAsFixed(2)}')),
        DataCell(Text('₹${vendor.totalValue.toStringAsFixed(2)}')),
        DataCell(Text(vendor.lastPurchaseDate)),
      ]);
    }).toList();

    return SingleChildScrollView(
      child: DataTable(columns: columns, rows: rows),
    );
  }

  Future<void> _editLocation(StockMaintenance stock) async {
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
              await ref.read(stockMaintenanceProvider.notifier).updateStockLocation(
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
    final stocks = ref.watch(stockMaintenanceProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Stock Maintenance'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => setState(() {}),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: PlutoGrid(
              columns: _getColumns(),
              rows: _buildRows(stocks),
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