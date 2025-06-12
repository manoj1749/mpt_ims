// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pluto_grid/pluto_grid.dart';
import '../../models/stock_maintenance.dart';
import '../../provider/stock_maintenance_provider.dart';
import '../../widgets/pluto_grid_configuration.dart';

class StockMaintenancePage extends ConsumerStatefulWidget {
  const StockMaintenancePage({super.key});

  @override
  StockMaintenancePageState createState() => StockMaintenancePageState();
}

class StockMaintenancePageState extends ConsumerState<StockMaintenancePage> {
  PlutoGridStateManager? stateManager;

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
          'stockValue': PlutoCell(value: stock.currentStock > 0 ? stock.totalStockValue : 0),
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
                onPressed: () => _showStockDetails(context, stock.materialCode),
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

  void _showStockDetails(BuildContext context, String materialCode) {
    final stock = ref.read(stockMaintenanceProvider.notifier)
        .getStockForMaterial(materialCode);
    if (stock == null) return;

    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          width: MediaQuery.of(context).size.width * 0.8,
          height: MediaQuery.of(context).size.height * 0.8,
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Stock Details - ${stock.materialDescription}',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              Expanded(
                child: _buildStockHistoryView(stock),
              ),
              Align(
                alignment: Alignment.bottomRight,
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Close'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStockHistoryView(StockMaintenance stock) {
    // Sort GRNs by date (newest first)
    final sortedGRNs = stock.grnDetails.entries.toList()
      ..sort((a, b) => b.value.grnDate.compareTo(a.value.grnDate));

    return ListView.builder(
      itemCount: sortedGRNs.length,
      itemBuilder: (context, index) {
        final grnEntry = sortedGRNs[index];
        final grn = grnEntry.value;
        
        // Get vendor details
        final vendorDetails = stock.vendorDetails[grn.vendorId];
        final vendorName = vendorDetails?.vendorName ?? 'Unknown Vendor';

        return Card(
          margin: const EdgeInsets.symmetric(vertical: 8.0),
          child: ExpansionTile(
            title: Text('GRN: ${grnEntry.key}'),
            subtitle: Text('Date: ${grn.grnDate}'),
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Vendor: $vendorName'),
                    const SizedBox(height: 8),
                    Text('Received: ${grn.receivedQuantity} ${stock.unit}'),
                    Text('Accepted: ${grn.acceptedQuantity} ${stock.unit}'),
                    Text('Rejected: ${grn.rejectedQuantity} ${stock.unit}'),
                    Text('Rate: ₹${grn.rate.toStringAsFixed(2)}'),
                    if (grn.acceptedQuantity > 0)
                      Text('Value: ₹${(grn.acceptedQuantity * grn.rate).toStringAsFixed(2)}'),
                  ],
                ),
              ),
            ],
          ),
        );
      },
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