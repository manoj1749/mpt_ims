import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pluto_grid/pluto_grid.dart';
import '../../models/material_item.dart';
import '../../models/purchase_order.dart';
import '../../provider/material_provider.dart';
import '../../provider/store_inward_provider.dart';
import '../../provider/purchase_order.dart';
import '../../provider/vendor_material_rate_provider.dart';
import '../../provider/quality_inspection_provider.dart';

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
              _navigateToDetails(rendererContext.row);
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
    final qualityInspections = ref.watch(qualityInspectionProvider);

    // Calculate stock for each material
    final materialStock = <String,
        Map<String, double>>{}; // materialCode -> {grnNo -> acceptedQty}
    final materialInspectionStock = <String,
        Map<String, double>>{}; // materialCode -> {grnNo -> pendingQty}
    final materialRejectedStock = <String,
        Map<String, double>>{}; // materialCode -> {grnNo -> rejectedQty}

    // First, process quality inspections to track inspected and rejected items
    for (var inspection in qualityInspections) {
      for (var item in inspection.items) {
        // Initialize maps if needed
        materialStock.putIfAbsent(item.materialCode, () => {});
        materialInspectionStock.putIfAbsent(item.materialCode, () => {});
        materialRejectedStock.putIfAbsent(item.materialCode, () => {});

        // Track accepted quantities per GRN
        if (item.acceptedQty > 0) {
          materialStock[item.materialCode]![inspection.grnNo] =
              (materialStock[item.materialCode]![inspection.grnNo] ?? 0) +
                  item.acceptedQty;
        }

        // Track pending quantities per GRN
        if (item.pendingQty > 0) {
          materialInspectionStock[item.materialCode]![inspection.grnNo] =
              (materialInspectionStock[item.materialCode]![inspection.grnNo] ??
                      0) +
                  item.pendingQty;
        }

        // Track rejected quantities per GRN
        if (item.rejectedQty > 0) {
          materialRejectedStock[item.materialCode]![inspection.grnNo] =
              (materialRejectedStock[item.materialCode]![inspection.grnNo] ??
                      0) +
                  item.rejectedQty;
        }
      }
    }

    // Then process store inwards to find items pending inspection
    for (var inward in storeInwards) {
      for (var item in inward.items) {
        materialInspectionStock.putIfAbsent(item.materialCode, () => {});

        // If this GRN hasn't been inspected yet or has pending quantity
        final acceptedQty =
            materialStock[item.materialCode]?[inward.grnNo] ?? 0;
        final rejectedQty =
            materialRejectedStock[item.materialCode]?[inward.grnNo] ?? 0;
        final inspectedQty = acceptedQty + rejectedQty;

        if (inspectedQty < item.receivedQty) {
          materialInspectionStock[item.materialCode]![inward.grnNo] =
              item.receivedQty - inspectedQty;
        }
      }
    }

    return materials.map((material) {
      final currentStock = materialStock[material.partNo]
              ?.values
              .fold(0.0, (sum, qty) => sum + qty) ??
          0;
      final inspectionStock = materialInspectionStock[material.partNo]
              ?.values
              .fold(0.0, (sum, qty) => sum + qty) ??
          0;

      // Total stock should only include accepted and in-inspection items
      final totalStock = currentStock + inspectionStock;

      final bestRate = material.getLowestRate(ref);
      final stockValue = currentStock *
          (double.tryParse(bestRate) ??
              0); // Only count accepted stock in value

      return PlutoRow(
        cells: {
          'materialCode': PlutoCell(value: material.partNo),
          'description': PlutoCell(value: material.description),
          'unit': PlutoCell(value: material.unit),
          'currentStock': PlutoCell(value: currentStock),
          'inspectionStock': PlutoCell(value: inspectionStock),
          'totalStock': PlutoCell(value: totalStock),
          'stockValue': PlutoCell(value: '₹${stockValue.toStringAsFixed(2)}'),
          'preferredVendor':
              PlutoCell(value: material.getPreferredVendorName(ref)),
          'bestRate': PlutoCell(value: bestRate.isEmpty ? '-' : '₹$bestRate'),
          'actions': PlutoCell(value: ''),
        },
      );
    }).toList();
  }

  void _navigateToDetails(PlutoRow row) {
    final materialCode = row.cells['materialCode']!.value as String;
    final material = ref
        .read(materialListProvider)
        .firstWhere((m) => m.partNo == materialCode);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MaterialStockDetailPage(material: material),
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
                      configuration: PlutoGridConfiguration(
                        columnFilter: const PlutoGridColumnFilterConfig(
                          filters: [
                            ...FilterHelper.defaultFilters,
                          ],
                        ),
                        style: PlutoGridStyleConfig(
                          gridBorderColor: Colors.grey[700]!,
                          gridBackgroundColor: Colors.grey[900]!,
                          borderColor: Colors.grey[700]!,
                          iconColor: Colors.grey[300]!,
                          rowColor: Colors.grey[850]!,
                          oddRowColor: Colors.grey[800]!,
                          evenRowColor: Colors.grey[850]!,
                          activatedColor: Colors.blue[900]!,
                          cellTextStyle: const TextStyle(color: Colors.white),
                          columnTextStyle: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                          rowHeight: 45,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

class MaterialStockDetailPage extends ConsumerWidget {
  final MaterialItem material;

  const MaterialStockDetailPage({
    super.key,
    required this.material,
  });

  List<PlutoColumn> _getStockColumns() {
    return [
      PlutoColumn(
        title: 'GRN No',
        field: 'grnNo',
        type: PlutoColumnType.text(),
        width: 120,
        enableEditingMode: false,
      ),
      PlutoColumn(
        title: 'Job No',
        field: 'jobNo',
        type: PlutoColumnType.text(),
        width: 120,
        enableEditingMode: false,
      ),
      PlutoColumn(
        title: 'PO No',
        field: 'poNo',
        type: PlutoColumnType.text(),
        width: 120,
        enableEditingMode: false,
      ),
      PlutoColumn(
        title: 'Supplier',
        field: 'supplier',
        type: PlutoColumnType.text(),
        width: 150,
        enableEditingMode: false,
      ),
      PlutoColumn(
        title: 'Received Qty',
        field: 'receivedQty',
        type: PlutoColumnType.number(),
        width: 120,
        enableEditingMode: false,
      ),
      PlutoColumn(
        title: 'Accepted Qty',
        field: 'acceptedQty',
        type: PlutoColumnType.number(),
        width: 120,
        enableEditingMode: false,
      ),
      PlutoColumn(
        title: 'Rate',
        field: 'rate',
        type: PlutoColumnType.text(),
        width: 120,
        enableEditingMode: false,
      ),
      PlutoColumn(
        title: 'Value',
        field: 'value',
        type: PlutoColumnType.text(),
        width: 120,
        enableEditingMode: false,
      ),
      PlutoColumn(
        title: 'Date',
        field: 'date',
        type: PlutoColumnType.text(),
        width: 120,
        enableEditingMode: false,
      ),
    ];
  }

  List<PlutoColumn> _getInspectionColumns() {
    return [
      PlutoColumn(
        title: 'Inspection No',
        field: 'inspectionNo',
        type: PlutoColumnType.text(),
        width: 120,
        enableEditingMode: false,
      ),
      PlutoColumn(
        title: 'GRN No',
        field: 'grnNo',
        type: PlutoColumnType.text(),
        width: 120,
        enableEditingMode: false,
      ),
      PlutoColumn(
        title: 'Job No',
        field: 'jobNo',
        type: PlutoColumnType.text(),
        width: 120,
        enableEditingMode: false,
      ),
      PlutoColumn(
        title: 'PO No',
        field: 'poNo',
        type: PlutoColumnType.text(),
        width: 120,
        enableEditingMode: false,
      ),
      PlutoColumn(
        title: 'Supplier',
        field: 'supplier',
        type: PlutoColumnType.text(),
        width: 150,
        enableEditingMode: false,
      ),
      PlutoColumn(
        title: 'Received Qty',
        field: 'receivedQty',
        type: PlutoColumnType.number(),
        width: 120,
        enableEditingMode: false,
      ),
      PlutoColumn(
        title: 'Inspected Qty',
        field: 'inspectedQty',
        type: PlutoColumnType.number(),
        width: 120,
        enableEditingMode: false,
      ),
      PlutoColumn(
        title: 'Pending Qty',
        field: 'pendingQty',
        type: PlutoColumnType.number(),
        width: 120,
        enableEditingMode: false,
      ),
      PlutoColumn(
        title: 'Status',
        field: 'status',
        type: PlutoColumnType.text(),
        width: 120,
        enableEditingMode: false,
      ),
      PlutoColumn(
        title: 'Date',
        field: 'date',
        type: PlutoColumnType.text(),
        width: 120,
        enableEditingMode: false,
      ),
    ];
  }

  List<PlutoRow> _getStockRows(WidgetRef ref) {
    final storeInwards = ref.watch(storeInwardProvider);
    final purchaseOrders = ref.watch(purchaseOrderListProvider);
    final qualityInspections = ref.watch(qualityInspectionProvider);
    final rows = <PlutoRow>[];

    // Track which items have been fully inspected and accepted
    final inspectedItems = <String, Map<String, double>>{};

    for (var inspection in qualityInspections) {
      for (var item in inspection.items) {
        if (item.acceptedQty > 0) {
          if (!inspectedItems.containsKey(item.materialCode)) {
            inspectedItems[item.materialCode] = {};
          }
          inspectedItems[item.materialCode]![inspection.grnNo] =
              (inspectedItems[item.materialCode]![inspection.grnNo] ?? 0) +
                  item.acceptedQty;
        }
      }
    }

    for (var inward in storeInwards) {
      for (var item in inward.items) {
        if (item.materialCode == material.partNo) {
          // Only show items that have been fully inspected and accepted
          final acceptedQty =
              inspectedItems[item.materialCode]?[inward.grnNo] ?? 0;
          if (acceptedQty > 0) {
            final po = purchaseOrders.firstWhere(
              (po) => po.poNo == inward.poNo,
              orElse: () => PurchaseOrder(
                poNo: '',
                poDate: '',
                supplierName: '',
                boardNo: '',
                transport: '',
                deliveryRequirements: '',
                items: [],
                total: 0,
                igst: 0,
                cgst: 0,
                sgst: 0,
                grandTotal: 0,
              ),
            );

            rows.add(PlutoRow(
              cells: {
                'grnNo': PlutoCell(value: inward.grnNo),
                'jobNo': PlutoCell(value: po.boardNo),
                'poNo': PlutoCell(value: inward.poNo),
                'supplier': PlutoCell(value: inward.supplierName),
                'receivedQty': PlutoCell(value: item.receivedQty),
                'acceptedQty': PlutoCell(value: acceptedQty),
                'rate': PlutoCell(value: '₹${item.costPerUnit}'),
                'value': PlutoCell(
                    value:
                        '₹${(acceptedQty * double.parse(item.costPerUnit)).toStringAsFixed(2)}'),
                'date': PlutoCell(value: inward.grnDate),
              },
            ));
          }
        }
      }
    }

    return rows;
  }

  List<PlutoRow> _getInspectionRows(WidgetRef ref) {
    final storeInwards = ref.watch(storeInwardProvider);
    final qualityInspections = ref.watch(qualityInspectionProvider);
    final rows = <PlutoRow>[];

    // Track inspection status for each GRN and material
    final inspectionStatus = <String,
        Map<
            String,
            Map<String,
                InspectionStatus>>>{}; // materialCode -> {grnNo -> {inspectionNo -> status}}

    for (var inspection in qualityInspections) {
      for (var item in inspection.items) {
        if (item.materialCode == material.partNo) {
          // Initialize maps if needed
          inspectionStatus.putIfAbsent(item.materialCode, () => {});
          inspectionStatus[item.materialCode]!
              .putIfAbsent(inspection.grnNo, () => {});

          inspectionStatus[item.materialCode]![inspection.grnNo]![
              inspection.inspectionNo] = InspectionStatus(
            inspectionNo: inspection.inspectionNo,
            inspectedQty: item.inspectedQty,
            acceptedQty: item.acceptedQty,
            rejectedQty: item.rejectedQty,
            pendingQty: item.pendingQty,
            date: inspection.inspectionDate,
          );
        }
      }
    }

    // Process store inwards and show inspection status
    for (var inward in storeInwards) {
      for (var item in inward.items) {
        if (item.materialCode == material.partNo) {
          final inspections =
              inspectionStatus[item.materialCode]?[inward.grnNo] ?? {};

          if (inspections.isEmpty) {
            // Not inspected yet
            rows.add(PlutoRow(
              cells: {
                'inspectionNo': PlutoCell(value: '-'),
                'grnNo': PlutoCell(value: inward.grnNo),
                'jobNo': PlutoCell(value: '-'),
                'poNo': PlutoCell(value: inward.poNo),
                'supplier': PlutoCell(value: inward.supplierName),
                'receivedQty': PlutoCell(value: item.receivedQty),
                'inspectedQty': PlutoCell(value: 0),
                'pendingQty': PlutoCell(value: item.receivedQty),
                'status': PlutoCell(value: 'Pending Inspection'),
                'date': PlutoCell(value: inward.grnDate),
              },
            ));
          } else {
            // Add a row for each inspection of this GRN
            for (var status in inspections.values) {
              rows.add(PlutoRow(
                cells: {
                  'inspectionNo': PlutoCell(value: status.inspectionNo),
                  'grnNo': PlutoCell(value: inward.grnNo),
                  'jobNo': PlutoCell(value: '-'),
                  'poNo': PlutoCell(value: inward.poNo),
                  'supplier': PlutoCell(value: inward.supplierName),
                  'receivedQty': PlutoCell(value: item.receivedQty),
                  'inspectedQty': PlutoCell(value: status.inspectedQty),
                  'pendingQty': PlutoCell(value: status.pendingQty),
                  'status': PlutoCell(
                      value: status.pendingQty > 0
                          ? 'Partially Inspected'
                          : 'Completed'),
                  'date': PlutoCell(value: status.date),
                },
              ));
            }
          }
        }
      }
    }

    return rows;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Stock Details - ${material.description}'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Material Information',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text('Code: ${material.partNo}'),
                    Text('Description: ${material.description}'),
                    Text('Unit: ${material.unit}'),
                    Text('Category: ${material.category}'),
                    Text('Sub Category: ${material.subCategory}'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Stock Distribution',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.3,
              child: PlutoGrid(
                columns: _getStockColumns(),
                rows: _getStockRows(ref),
                configuration: PlutoGridConfiguration(
                  columnFilter: const PlutoGridColumnFilterConfig(
                    filters: [
                      ...FilterHelper.defaultFilters,
                    ],
                  ),
                  style: PlutoGridStyleConfig(
                    gridBorderColor: Colors.grey[700]!,
                    gridBackgroundColor: Colors.grey[900]!,
                    borderColor: Colors.grey[700]!,
                    iconColor: Colors.grey[300]!,
                    rowColor: Colors.grey[850]!,
                    oddRowColor: Colors.grey[800]!,
                    evenRowColor: Colors.grey[850]!,
                    activatedColor: Colors.blue[900]!,
                    cellTextStyle: const TextStyle(color: Colors.white),
                    columnTextStyle: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                    rowHeight: 45,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Under Inspection',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            Expanded(
              child: PlutoGrid(
                columns: _getInspectionColumns(),
                rows: _getInspectionRows(ref),
                configuration: PlutoGridConfiguration(
                  columnFilter: const PlutoGridColumnFilterConfig(
                    filters: [
                      ...FilterHelper.defaultFilters,
                    ],
                  ),
                  style: PlutoGridStyleConfig(
                    gridBorderColor: Colors.grey[700]!,
                    gridBackgroundColor: Colors.grey[900]!,
                    borderColor: Colors.grey[700]!,
                    iconColor: Colors.grey[300]!,
                    rowColor: Colors.grey[850]!,
                    oddRowColor: Colors.grey[800]!,
                    evenRowColor: Colors.grey[850]!,
                    activatedColor: Colors.blue[900]!,
                    cellTextStyle: const TextStyle(color: Colors.white),
                    columnTextStyle: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                    rowHeight: 45,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
