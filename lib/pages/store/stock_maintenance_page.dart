// ignore_for_file: use_build_context_synchronously, unnecessary_type_check, avoid_print

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pluto_grid/pluto_grid.dart';
import '../../models/stock_maintenance.dart';
import '../../provider/stock_maintenance_provider.dart';
import '../../widgets/pluto_grid_configuration.dart';
import 'package:hive/hive.dart';

class StockMaintenancePage extends ConsumerStatefulWidget {
  const StockMaintenancePage({super.key});

  @override
  StockMaintenancePageState createState() => StockMaintenancePageState();
}

class StockMaintenancePageState extends ConsumerState<StockMaintenancePage> {
  PlutoGridStateManager? stateManager;

  @override
  void initState() {
    super.initState();
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
    });
  }

  List<PlutoRow> _buildRows(List<StockMaintenance> stocks) {
    return stocks.map((stock) {
      // Calculate total issued quantity
      double totalIssuedQty = 0.0;
      for (var prDetail in stock.prDetails.values) {
        totalIssuedQty += prDetail.issuedQuantity;
      }

      // Calculate current stock after subtracting issued quantity
      double currentStock = stock.calculatedCurrentStock - totalIssuedQty;
      double totalStock = stock.calculatedTotalStock - totalIssuedQty;

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
    final stock = ref
        .read(stockMaintenanceProvider.notifier)
        .getStockForMaterial(materialCode);
    if (stock == null) return;

    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          width: MediaQuery.of(context).size.width * 0.8,
          height: MediaQuery.of(context).size.height * 0.8,
          padding: const EdgeInsets.all(16.0),
          child: StockDetailsView(stock: stock),
        ),
      ),
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

class StockDetailsView extends StatefulWidget {
  final StockMaintenance stock;

  const StockDetailsView({super.key, required this.stock});

  @override
  State<StockDetailsView> createState() => _StockDetailsViewState();
}

class _StockDetailsViewState extends State<StockDetailsView> {
  bool showDetailedView = false;

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
            Row(
              children: [
                const Text('Detailed View'),
                const SizedBox(width: 8),
                Switch(
                  value: showDetailedView,
                  onChanged: (value) {
                    setState(() {
                      showDetailedView = value;
                    });
                  },
                ),
              ],
            ),
          ],
        ),
        Text(
          'Code: ${widget.stock.materialCode} | Unit: ${widget.stock.unit}',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 16),
        if (!showDetailedView) ...[
          _buildSummaryView(),
        ] else ...[
          _buildDetailedView(),
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

  Widget _buildSummaryView() {
    // First group by job number
    Map<String, List<MapEntry<String, StockPRDetails>>> jobWiseStock = {};
    
    for (var entry in widget.stock.prDetails.entries) {
      final jobNo = entry.value.jobNo.isEmpty ? 'General' : entry.value.jobNo;
      jobWiseStock.putIfAbsent(jobNo, () => []);
      jobWiseStock[jobNo]!.add(entry);
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
                ...jobWiseStock.entries.map((jobEntry) {
                  // Calculate job totals
                  double totalReceived = 0.0;
                  double totalIssued = 0.0;
                  for (var prEntry in jobEntry.value) {
                    totalReceived += prEntry.value.receivedQuantity;
                    totalIssued += prEntry.value.issuedQuantity;
                  }

                  // Skip this job if no available stock
                  if (totalReceived - totalIssued <= 0) {
                    return const SizedBox.shrink(); // Hide this job
                  }

                  return ExpansionTile(
                    title: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Job: ${jobEntry.key}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(left: 16.0),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('Total Received:'),
                                  Text('${totalReceived.toStringAsFixed(2)} ${widget.stock.unit}'),
                                ],
                              ),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('Total Issued:'),
                                  Text('${totalIssued.toStringAsFixed(2)} ${widget.stock.unit}'),
                                ],
                              ),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('Available:'),
                                  Text('${(totalReceived - totalIssued).toStringAsFixed(2)} ${widget.stock.unit}'),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    children: [
                      ...jobEntry.value.map((prEntry) {
                        final prNo = prEntry.key;
                        final pr = prEntry.value;
                        // Find vendor details from PO
                        String vendorName = '';
                        // Look through PO details to find the vendor
                        for (var poDetail in widget.stock.poDetails.entries) {
                          // Check if this PO has received quantities for this PR
                          for (var grnQtys in poDetail.value.receivedQuantities.values) {
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
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              Padding(
                                padding: const EdgeInsets.only(left: 16.0),
                                child: Column(
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        const Text('Received:'),
                                        Text('${pr.receivedQuantity.toStringAsFixed(2)} ${widget.stock.unit}'),
                                      ],
                                    ),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        const Text('Issued:'),
                                        Text('${pr.issuedQuantity.toStringAsFixed(2)} ${widget.stock.unit}'),
                                      ],
                                    ),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        const Text('Available:'),
                                        Text('${(pr.receivedQuantity - pr.issuedQuantity).toStringAsFixed(2)} ${widget.stock.unit}'),
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
                }).toList(),
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
          final receivedQtys = po.receivedQuantities[grnNo];
          if (receivedQtys != null) {
            receivedQtys.forEach((prNo, qty) {
              if (qty > 0) {
                final issuedQty = grn.issuedQuantities[prNo] ?? 0.0;
                prRows.add(
                  Padding(
                    padding: const EdgeInsets.only(
                        left: 16.0, top: 4.0, bottom: 4.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          prNo == 'General' ? 'General Stock' : 'PR: $prNo',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        Text(
                          'Received: ${qty.toStringAsFixed(2)} | Issued: ${issuedQty.toStringAsFixed(2)} | Available: ${(qty - issuedQty).toStringAsFixed(2)} ${widget.stock.unit}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                );
              }
            });
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
