import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mpt_ims/widgets/pluto_grid_configuration.dart';
import 'package:pluto_grid/pluto_grid.dart';
import '../../models/material_item.dart';
import '../../provider/material_provider.dart';
import '../../provider/store_inward_provider.dart';
import '../../provider/vendor_material_rate_provider.dart';
import '../../provider/quality_inspection_provider.dart';
import '../../models/category.dart';
import '../../provider/category_provider.dart';
import '../../provider/stock_maintenance_provider.dart';
import '../../models/stock_maintenance.dart';

// Model classes for hierarchical data
class GRDetails {
  final String grNo;
  final String date;
  final double quantity;
  final List<PODetails> poDetails;

  GRDetails({
    required this.grNo,
    required this.date,
    required this.quantity,
    required this.poDetails,
  });
}

class PODetails {
  final String poNo;
  final double quantity;
  final List<PRDetails> prDetails;

  PODetails({
    required this.poNo,
    required this.quantity,
    required this.prDetails,
  });
}

class PRDetails {
  final String prNo;
  final String jobNo;
  final double quantity;

  PRDetails({
    required this.prNo,
    required this.jobNo,
    required this.quantity,
  });
}

class InspectionStatus {
  final String inspectionNo;
  final double inspectedQty;
  final double acceptedQty;
  final double rejectedQty;
  final double pendingQty;
  final String date;

  InspectionStatus({
    required this.inspectionNo,
    required this.inspectedQty,
    required this.acceptedQty,
    required this.rejectedQty,
    required this.pendingQty,
    required this.date,
  });
}

class StockDetailsPage extends ConsumerStatefulWidget {
  const StockDetailsPage({super.key});

  @override
  ConsumerState<StockDetailsPage> createState() => _StockDetailsPageState();
}

class _StockDetailsPageState extends ConsumerState<StockDetailsPage> {
  PlutoGridStateManager? stateManager;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
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

  List<PlutoColumn> _getColumns() {
    return [
      PlutoColumn(
        title: 'Material Code',
        field: 'materialCode',
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
        title: 'Unit',
        field: 'unit',
        type: PlutoColumnType.text(),
        width: 80,
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
        title: 'Current Stock',
        field: 'currentStock',
        type: PlutoColumnType.number(),
        width: 120,
        enableEditingMode: false,
      ),
      PlutoColumn(
        title: 'Under Inspection',
        field: 'inspectionStock',
        type: PlutoColumnType.number(),
        width: 120,
        enableEditingMode: false,
      ),
      PlutoColumn(
        title: 'Total Stock',
        field: 'totalStock',
        type: PlutoColumnType.number(),
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
        title: 'Allocated Stock',
        field: 'allocatedStock',
        type: PlutoColumnType.number(),
        width: 120,
        enableEditingMode: false,
      ),
      PlutoColumn(
        title: 'Consumed Stock',
        field: 'consumedStock',
        type: PlutoColumnType.number(),
        width: 120,
        enableEditingMode: false,
      ),
      PlutoColumn(
        title: 'Available Stock',
        field: 'availableStock',
        type: PlutoColumnType.number(),
        width: 120,
        enableEditingMode: false,
      ),
      PlutoColumn(
        title: 'Actions',
        field: 'actions',
        type: PlutoColumnType.text(),
        width: 100,
        enableEditingMode: false,
        renderer: (rendererContext) {
          return IconButton(
            icon: const Icon(Icons.visibility_outlined),
            onPressed: () {
              _showMaterialDetails(
                  rendererContext.row.cells['materialCode']!.value as String);
            },
            tooltip: 'View Details',
          );
        },
      ),
    ];
  }

  List<PlutoRow> _getRows() {
    final materials = ref.watch(materialListProvider);
    final stockItems = ref.watch(stockMaintenanceProvider);
    final categories = ref.watch(categoryListProvider);

    // Create rows for each material
    final rows = <PlutoRow>[];
    for (var material in materials) {
      // Get the material's category
      final category = categories.firstWhere(
        (c) => c.name == material.category,
        orElse: () => Category(name: material.category),
      );

      // Get stock details
      final stockItem = stockItems.firstWhere(
        (s) => s.materialCode == material.partNo,
        orElse: () => StockMaintenance(
          materialCode: material.partNo,
          materialDescription: material.description,
          unit: material.unit,
          storageLocation: material.storageLocation ?? '',
          rackNumber: material.rackNumber ?? '',
        ),
      );

      // Calculate job-wise allocated and consumed quantities
      double totalAllocated = 0.0;
      double totalConsumed = 0.0;
      for (var jobDetail in stockItem.jobDetails.values) {
        totalAllocated += jobDetail.allocatedQuantity;
        totalConsumed += jobDetail.consumedQuantity;
      }

      // Calculate GRN-wise quantities
      double totalAccepted = 0.0;
      double totalUnderInspection = 0.0;
      double totalValue = 0.0;

      for (var grn in stockItem.grnDetails.values) {
        totalAccepted += grn.acceptedQuantity;
        totalUnderInspection += (grn.receivedQuantity - (grn.acceptedQuantity + grn.rejectedQuantity));
        
        // Calculate value based on remaining quantity in this GRN
        final remainingQty = grn.acceptedQuantity - grn.issuedQuantity;
        if (remainingQty > 0) {
          totalValue += remainingQty * grn.rate;
        }
      }

      final currentStock = totalAccepted - totalConsumed;
      final totalStock = currentStock + totalUnderInspection;

      rows.add(PlutoRow(
        cells: {
          'materialCode': PlutoCell(value: material.partNo),
          'description': PlutoCell(value: material.description),
          'unit': PlutoCell(value: material.unit),
          'storageLocation': PlutoCell(value: material.storageLocation),
          'rackNumber': PlutoCell(value: material.rackNumber),
          'currentStock': PlutoCell(value: currentStock),
          'inspectionStock': PlutoCell(value: totalUnderInspection),
          'totalStock': PlutoCell(value: totalStock),
          'stockValue': PlutoCell(value: '₹${totalValue.toStringAsFixed(2)}'),
          'allocatedStock': PlutoCell(value: totalAllocated),
          'consumedStock': PlutoCell(value: totalConsumed),
          'availableStock': PlutoCell(value: totalAllocated - totalConsumed),
          'actions': PlutoCell(value: ''),
        },
      ));
    }

    return rows;
  }

  void _showMaterialDetails(String materialCode) {
    final stockItems = ref.read(stockMaintenanceProvider);
    final stockItem = stockItems.firstWhere(
      (s) => s.materialCode == materialCode,
      orElse: () => StockMaintenance(
        materialCode: materialCode,
        materialDescription: '',
        unit: '',
        storageLocation: '',
        rackNumber: '',
      ),
    );

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
                'Material Details - $materialCode',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              Expanded(
                child: DefaultTabController(
                  length: 2,
                  child: Column(
                    children: [
                      const TabBar(
                        tabs: [
                          Tab(text: 'GRN Details'),
                          Tab(text: 'Job Details'),
                        ],
                      ),
                      Expanded(
                        child: TabBarView(
                          children: [
                            // GRN Details Tab
                            ListView.builder(
                              itemCount: stockItem.grnDetails.length,
                              itemBuilder: (context, index) {
                                final grnEntry = stockItem.grnDetails.entries.elementAt(index);
                                final grn = grnEntry.value;
                                return Card(
                                  margin: const EdgeInsets.symmetric(vertical: 4),
                                  child: ExpansionTile(
                                    title: Row(
                                      children: [
                                        Expanded(
                                          flex: 2,
                                          child: Text('GRN No: ${grnEntry.key}'),
                                        ),
                                        Expanded(
                                          flex: 2,
                                          child: Text('Date: ${grn.grnDate}'),
                                        ),
                                        Expanded(
                                          child: Text(
                                            'Qty: ${grn.receivedQuantity}',
                                          ),
                                        ),
                                      ],
                                    ),
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.all(16.0),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text('Received Quantity: ${grn.receivedQuantity}'),
                                            Text('Accepted Quantity: ${grn.acceptedQuantity}'),
                                            Text('Rejected Quantity: ${grn.rejectedQuantity}'),
                                            Text('Issued Quantity: ${grn.issuedQuantity}'),
                                            Text('Rate: ₹${grn.rate}'),
                                            const Divider(),
                                            const Text('PR-wise Quantities:'),
                                            ...grn.issuedQuantities.entries.map((prEntry) {
                                              return Padding(
                                                padding: const EdgeInsets.only(left: 16.0),
                                                child: Text('PR ${prEntry.key}: Issued ${prEntry.value}'),
                                              );
                                            }),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                            // Job Details Tab
                            ListView.builder(
                              itemCount: stockItem.jobDetails.length,
                              itemBuilder: (context, index) {
                                final jobEntry = stockItem.jobDetails.entries.elementAt(index);
                                final job = jobEntry.value;
                                return Card(
                                  margin: const EdgeInsets.symmetric(vertical: 4),
                                  child: ListTile(
                                    title: Text('Job No: ${jobEntry.key}'),
                                    subtitle: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('Allocated Quantity: ${job.allocatedQuantity}'),
                                        Text('Consumed Quantity: ${job.consumedQuantity}'),
                                        Text('Available Quantity: ${job.allocatedQuantity - job.consumedQuantity}'),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerRight,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Stock Details'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'Stock Overview',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(width: 16),
                      FilledButton.tonal(
                        onPressed: () {
                          stateManager?.setShowColumnFilter(
                              !stateManager!.showColumnFilter);
                        },
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.filter_list, size: 20),
                            SizedBox(width: 8),
                            Text('Toggle Filters'),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: PlutoGrid(
                      columns: _getColumns(),
                      rows: _getRows(),
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

class MaterialDetailsView extends StatelessWidget {
  final List<GRDetails> grDetails;

  const MaterialDetailsView({
    super.key,
    required this.grDetails,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: grDetails.length,
      itemBuilder: (context, index) {
        final gr = grDetails[index];
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 4),
          child: ExpansionTile(
            title: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Text('GR No: ${gr.grNo}'),
                ),
                Expanded(
                  flex: 2,
                  child: Text('Date: ${gr.date}'),
                ),
                Expanded(
                  child: Text(
                    'Qty: ${gr.quantity.toStringAsFixed(2)}',
                    textAlign: TextAlign.right,
                  ),
                ),
              ],
            ),
            children: gr.poDetails.map((po) {
              return Padding(
                padding: const EdgeInsets.only(left: 16.0),
                child: Card(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  child: ExpansionTile(
                    title: Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: Text('PO No: ${po.poNo}'),
                        ),
                        Expanded(
                          child: Text(
                            'Qty: ${po.quantity.toStringAsFixed(2)}',
                            textAlign: TextAlign.right,
                          ),
                        ),
                      ],
                    ),
                    children: po.prDetails.map((pr) {
                      return Padding(
                        padding: const EdgeInsets.only(left: 16.0),
                        child: ListTile(
                          title: Row(
                            children: [
                              Expanded(
                                flex: 2,
                                child: Text('PR No: ${pr.prNo}'),
                              ),
                              Expanded(
                                flex: 2,
                                child: Text('Job No: ${pr.jobNo}'),
                              ),
                              Expanded(
                                child: Text(
                                  'Qty: ${pr.quantity.toStringAsFixed(2)}',
                                  textAlign: TextAlign.right,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }
}

// Extension method to help with grouping
extension IterableExtension<T> on Iterable<T> {
  Map<K, List<T>> groupBy<K>(K Function(T) keyFunction) {
    final map = <K, List<T>>{};
    for (var element in this) {
      final key = keyFunction(element);
      map.putIfAbsent(key, () => []).add(element);
    }
    return map;
  }
}
