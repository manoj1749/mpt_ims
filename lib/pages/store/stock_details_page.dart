import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mpt_ims/widgets/pluto_grid_configuration.dart';
import 'package:pluto_grid/pluto_grid.dart';
import '../../models/material_item.dart';
import '../../models/purchase_order.dart';
import '../../provider/material_provider.dart';
import '../../provider/store_inward_provider.dart';
import '../../provider/purchase_order.dart';
import '../../provider/vendor_material_rate_provider.dart';
import '../../provider/quality_inspection_provider.dart';
import '../../models/category.dart';
import '../../provider/category_provider.dart';

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
        title: 'Inspection Stock',
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
        title: 'Preferred Vendor',
        field: 'preferredVendor',
        type: PlutoColumnType.text(),
        width: 150,
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
    final storeInwards = ref.watch(storeInwardProvider);
    ref.watch(vendorMaterialRateProvider);
    ref.watch(qualityInspectionProvider);
    final categories = ref.watch(categoryListProvider);

    // Calculate stock for each material
    final materialStock = <String,
        Map<String, double>>{}; // materialCode -> {grnNo -> acceptedQty}
    final materialInspectionStock = <String,
        Map<String, double>>{}; // materialCode -> {grnNo -> pendingQty}
    final materialRejectedStock = <String,
        Map<String, double>>{}; // materialCode -> {grnNo -> rejectedQty}

    // Process store inwards to calculate stock
    for (var inward in storeInwards) {
      for (var item in inward.items) {
        // Get the material's category
        final material = materials.firstWhere(
          (m) => m.partNo == item.materialCode,
          orElse: () => MaterialItem(
            slNo: item.materialCode,
            description: '',
            partNo: item.materialCode,
            unit: item.unit,
            category: 'General',
            subCategory: '',
          ),
        );

        final category = categories.firstWhere(
          (c) => c.name == material.category,
          orElse: () => Category(name: material.category),
        );

        // Initialize maps if needed
        materialStock.putIfAbsent(item.materialCode, () => {});
        materialInspectionStock.putIfAbsent(item.materialCode, () => {});
        materialRejectedStock.putIfAbsent(item.materialCode, () => {});

        // For items that don't require inspection, add directly to stock
        if (!category.requiresQualityCheck) {
          materialStock[item.materialCode]![inward.grnNo] = item.receivedQty;
          continue;
        }

        // For items requiring inspection, calculate based on inspection status
        final acceptedQty = item.totalAcceptedQty;
        final rejectedQty = item.totalRejectedQty;
        final underInspectionQty = item.underInspectionQty;

        // Add accepted quantity to stock
        if (acceptedQty > 0) {
          materialStock[item.materialCode]![inward.grnNo] = acceptedQty;
        }

        // Add quantity under inspection
        if (underInspectionQty > 0) {
          materialInspectionStock[item.materialCode]![inward.grnNo] =
              underInspectionQty;
        }

        // Add rejected quantity
        if (rejectedQty > 0) {
          materialRejectedStock[item.materialCode]![inward.grnNo] = rejectedQty;
        }
      }
    }

    // Create rows for each material
    final rows = <PlutoRow>[];
    for (var material in materials) {
      // Get the material's category
      final category = categories.firstWhere(
        (c) => c.name == material.category,
        orElse: () => Category(name: material.category),
      );

      double currentStock = 0;
      double inspectionStock = 0;
      double rejectedStock = 0;

      // Calculate stock based on category
      if (!category.requiresQualityCheck) {
        // For non-inspection items, all received stock is current stock
        currentStock = materialStock[material.partNo]
                ?.values
                .fold<double>(0.0, (sum, qty) => sum + qty) ??
            0;
        inspectionStock = 0;
        rejectedStock = 0;
      } else {
        // For inspection items, calculate based on inspection status
        currentStock = materialStock[material.partNo]
                ?.values
                .fold<double>(0.0, (sum, qty) => sum + qty) ??
            0;
        inspectionStock = materialInspectionStock[material.partNo]
                ?.values
                .fold<double>(0.0, (sum, qty) => sum + qty) ??
            0;
        rejectedStock = materialRejectedStock[material.partNo]
                ?.values
                .fold<double>(0.0, (sum, qty) => sum + qty) ??
            0;
      }

      // Total stock should only include accepted and in-inspection items
      final totalStock = currentStock + inspectionStock;

      final bestRate = material.getLowestRate(ref);
      final stockValue = currentStock *
          (double.tryParse(bestRate) ??
              0); // Only count accepted stock in value

      rows.add(PlutoRow(
        cells: {
          'materialCode': PlutoCell(value: material.partNo),
          'description': PlutoCell(value: material.description),
          'unit': PlutoCell(value: material.unit),
          'storageLocation': PlutoCell(value: material.storageLocation),
          'rackNumber': PlutoCell(value: material.rackNumber),
          'currentStock': PlutoCell(value: currentStock),
          'inspectionStock': PlutoCell(value: inspectionStock),
          'rejectedStock': PlutoCell(value: rejectedStock),
          'totalStock': PlutoCell(value: totalStock),
          'stockValue': PlutoCell(value: '₹${stockValue.toStringAsFixed(2)}'),
          'preferredVendor':
              PlutoCell(value: material.getPreferredVendorName(ref)),
          'bestRate': PlutoCell(value: bestRate.isEmpty ? '-' : '₹$bestRate'),
          'actions': PlutoCell(value: ''),
        },
      ));
    }

    return rows;
  }

  void _showMaterialDetails(String materialCode) {
    final storeInwards = ref.read(storeInwardProvider);
    final List<GRDetails> grDetails = [];

    // Process store inwards to build hierarchical data
    for (var inward in storeInwards) {
      final relevantItems =
          inward.items.where((item) => item.materialCode == materialCode);

      for (var item in relevantItems) {
        final List<PODetails> poDetails = [];

        // Group by PO and process PR quantities
        for (var poEntry in item.prQuantities.entries) {
          final String poNo = poEntry.key;
          final Map<String, double> prQtys = poEntry.value;
          final List<PRDetails> prDetails = [];
          double poTotal = 0;

          // Process PR details for this PO
          for (var prEntry in prQtys.entries) {
            final String prNo = prEntry.key;
            final double qty = prEntry.value;
            final String jobNo = item.prJobNumbers[poNo]?[prNo] ?? 'N/A';

            prDetails.add(PRDetails(
              prNo: prNo,
              jobNo: jobNo,
              quantity: qty,
            ));

            poTotal += qty;
          }

          poDetails.add(PODetails(
            poNo: poNo,
            quantity: poTotal,
            prDetails: prDetails,
          ));
        }

        grDetails.add(GRDetails(
          grNo: inward.grnNo,
          date: inward.grnDate,
          quantity: item.receivedQty,
          poDetails: poDetails,
        ));
      }
    }

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
                child: MaterialDetailsView(grDetails: grDetails),
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
