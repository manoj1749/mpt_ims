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
          'stockValue': PlutoCell(
              value: stock.currentStock > 0 ? stock.totalStockValue : 0),
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

  Widget _buildStockHistoryView(StockMaintenance stock) {
    // Sort GRNs by date (newest first)
    final sortedGRNs = stock.grnDetails.entries.toList()
      ..sort((a, b) => b.value.grnDate.compareTo(a.value.grnDate));

    return ListView.builder(
      itemCount: sortedGRNs.length,
      itemBuilder: (context, index) {
        final grnEntry = sortedGRNs[index];
        final grn = grnEntry.value;
        final grnNo = grnEntry.key;

        // Get vendor details
        final vendorDetails = stock.vendorDetails[grn.vendorId];
        final vendorName = vendorDetails?.vendorName ?? 'Unknown Vendor';

        // Get PO numbers from GRN details
        final poNumbers = stock.poDetails.entries
            .where((po) => po.value.vendorId == grn.vendorId)
            .map((e) => e.key)
            .toList();

        return Card(
          margin: const EdgeInsets.symmetric(vertical: 4.0),
          child: Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              title: Row(
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
                          'Vendor: $vendorName',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('Qty: ${grn.receivedQuantity} ${stock.unit}'),
                        if (grn.acceptedQuantity > 0)
                          Text(
                            'Accepted: ${grn.acceptedQuantity} ${stock.unit}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              children: [
                // PO Level
                ...poNumbers.map((poNo) {
                  final po = stock.poDetails[poNo]!;

                  return Padding(
                    padding: const EdgeInsets.only(left: 16.0),
                    child: Card(
                      margin: const EdgeInsets.symmetric(vertical: 4.0),
                      child: Theme(
                        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                        child: ExpansionTile(
                          title: Row(
                            children: [
                              Expanded(
                                flex: 2,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('PO: $poNo'),
                                    Text(
                                      'Date: ${po.poDate}',
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
                                        'Ordered: ${po.orderedQuantity} ${stock.unit}'),
                                    Text(
                                      'Received: ${po.receivedQuantity} ${stock.unit}',
                                      style: Theme.of(context).textTheme.bodySmall,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          children: [
                            // PR Level
                            ...stock.prDetails.entries.where((pr) {
                              // Find job details that reference this PR and PO
                              return stock.jobDetails.values.any((job) => 
                                job.prNo == pr.key && 
                                stock.poDetails[poNo]?.vendorId == grn.vendorId);
                            }).map((prEntry) {
                              final pr = prEntry.value;
                              final prNo = prEntry.key;

                              // Find job details for this PR
                              final jobDetail = stock.jobDetails.values
                                  .firstWhere((job) => job.prNo == prNo);

                              return Padding(
                                padding: const EdgeInsets.only(left: 16.0),
                                child: ListTile(
                                  title: Row(
                                    children: [
                                      Expanded(
                                        flex: 2,
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text('PR: $prNo'),
                                            Text(
                                              'Job: ${jobDetail.jobNo}',
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .bodySmall,
                                            ),
                                          ],
                                        ),
                                      ),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.end,
                                          children: [
                                            Text(
                                                'Requested: ${pr.requestedQuantity} ${stock.unit}'),
                                            Text(
                                                'Received: ${pr.receivedQuantity} ${stock.unit}',
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .bodySmall),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }).toList(),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),

                // Additional GRN details
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
                        Text('Rejected: ${grn.rejectedQuantity} ${stock.unit}',
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
    // Map to store PR-wise quantities with their details
    final prQuantities = <String, Map<String, dynamic>>{};
    double generalStock = 0.0;

    // First, initialize PR quantities with requested amounts
    for (var prEntry in widget.stock.prDetails.entries) {
      final prNo = prEntry.key;
      final pr = prEntry.value;
      final job = widget.stock.jobDetails.values
          .where((job) => job.prNo == prNo)
          .firstOrNull;

      if (job != null) {
        prQuantities[prNo] = {
          'jobNo': job.jobNo,
          'requested': pr.requestedQuantity,
          'received': 0.0,
        };
      }
    }

    // Calculate received quantities from GRNs
    for (var grnEntry in widget.stock.grnDetails.entries) {
      final grn = grnEntry.value;
      double remainingQty = grn.receivedQuantity;
      bool allocated = false;

      // Find POs related to this GRN's vendor
      final relatedPOs = widget.stock.poDetails.entries
          .where((po) => po.value.vendorId == grn.vendorId)
          .toList();

      for (var poEntry in relatedPOs) {
        final po = poEntry.value;
        
        // Find PRs related to this PO
        for (var prEntry in widget.stock.prDetails.entries) {
          final prNo = prEntry.key;
          final pr = prEntry.value;
          
          // Check if this PR is linked to a job and has pending quantity
          if (prQuantities.containsKey(prNo)) {
            final prData = prQuantities[prNo]!;
            final pendingQty = prData['requested'] - prData['received'];
            
            if (pendingQty > 0 && remainingQty > 0) {
              // Allocate quantity to this PR
              final allocatedQty = remainingQty > pendingQty ? pendingQty : remainingQty;
              prData['received'] += allocatedQty;
              remainingQty -= allocatedQty;
              allocated = true;
            }
          }
        }
      }

      // Add remaining quantity to general stock
      if (!allocated || remainingQty > 0) {
        generalStock += remainingQty;
      }
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
                // Show PR/Job-wise quantities
                ...prQuantities.entries.map((entry) {
                  final prNo = entry.key;
                  final data = entry.value;
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('PR: $prNo'),
                                Text(
                                  'Job: ${data['jobNo']}',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text('${data['received'].toStringAsFixed(2)} ${widget.stock.unit}'),
                                Text(
                                  'Requested: ${data['requested'].toStringAsFixed(2)} ${widget.stock.unit}',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ],
                        ),
                        const Divider(),
                      ],
                    ),
                  );
                }).toList(),
                // Show general stock
                if (generalStock > 0)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('General Stock'),
                        Text('${generalStock.toStringAsFixed(2)} ${widget.stock.unit}'),
                      ],
                    ),
                  ),
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

        // Get vendor details
        final vendorDetails = widget.stock.vendorDetails[grn.vendorId];
        final vendorName = vendorDetails?.vendorName ?? 'Unknown Vendor';

        // Get PO numbers from GRN details that match this GRN's vendor
        final relatedPOs = widget.stock.poDetails.entries
            .where((po) => po.value.vendorId == grn.vendorId)
            .toList();

        // Get PR and Job details for this GRN
        final prJobDetails = <String, Map<String, dynamic>>{};
        bool isGeneralStock = true;

        // For each PO, find PRs that have received stock from this specific GRN
        for (var poEntry in relatedPOs) {
          final poNo = poEntry.key;
          final po = poEntry.value;

          // Check if this PO has any PRs that received stock from this GRN
          final receivedQtys = po.receivedQuantities[grnNo];
          if (receivedQtys != null) {
            // Process each PR that received stock from this GRN
            for (var prEntry in receivedQtys.entries) {
              final prNo = prEntry.key;
              final receivedQty = prEntry.value;

              // Skip if no quantity was received
              if (receivedQty <= 0) continue;

              // Get PR details
              final pr = widget.stock.prDetails[prNo];
              if (pr == null) continue;

              // Find job for this PR
              final job = widget.stock.jobDetails.values
                  .where((job) => job.prNo == prNo)
                  .firstOrNull;

              // If we found a job and PR with received quantity, add it to our details
              if (job != null) {
                isGeneralStock = false;
                prJobDetails[prNo] = {
                  'jobNo': job.jobNo,
                  'poNo': poNo,
                  'poQty': po.orderedQuantity,
                  'poReceived': po.receivedQuantity,
                  'requested': pr.requestedQuantity,
                  'received': receivedQty,
                };
              }
            }
          }
        }

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
                              'Vendor: $vendorName',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text('Qty: ${grn.receivedQuantity} ${widget.stock.unit}'),
                            if (grn.acceptedQuantity > 0)
                              Text(
                                'Accepted: ${grn.acceptedQuantity} ${widget.stock.unit}',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Divider(),
                  if (isGeneralStock) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'General Stock',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          '${grn.receivedQuantity} ${widget.stock.unit}',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ] else ...[
                    ...prJobDetails.entries.map((entry) {
                      final prNo = entry.key;
                      final details = entry.value;
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'PO: ${details['poNo']}',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Text(
                                'Received: ${details['poReceived']} / ${details['poQty']} ${widget.stock.unit}',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          Padding(
                            padding: const EdgeInsets.only(left: 16.0, top: 4.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'PR: $prNo | Job: ${details['jobNo']}',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                                Text(
                                  'Received: ${details['received']} / ${details['requested']} ${widget.stock.unit}',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ],
                ],
              ),
              children: [
                // Additional GRN details
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
                        Text('Rejected: ${grn.rejectedQuantity} ${widget.stock.unit}',
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
