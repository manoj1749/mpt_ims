import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pluto_grid/pluto_grid.dart';
import '../../models/material_item.dart';
import '../../models/store_inward.dart';
import '../../models/purchase_order.dart';
import '../../models/quality_inspection.dart';
import '../../provider/material_provider.dart';
import '../../provider/store_inward_provider.dart';
import '../../provider/purchase_order.dart';
import '../../provider/vendor_material_rate_provider.dart';
import '../../provider/quality_inspection_provider.dart';

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
    final vendorRates = ref.watch(vendorMaterialRateProvider);
    final qualityInspections = ref.watch(qualityInspectionProvider);

    // Calculate current stock for each material
    final materialStock = <String, double>{};
    final materialInspectionStock = <String, double>{};
    final materialPendingInspectionStock = <String, double>{};

    // Process store inwards to calculate current stock
    for (var inward in storeInwards) {
      for (var item in inward.items) {
        materialStock[item.materialCode] = 
            (materialStock[item.materialCode] ?? 0) + item.acceptedQty;
      }
    }

    // Calculate inspection stock and pending inspection stock
    for (var inspection in qualityInspections) {
      for (var item in inspection.items) {
        if (inspection.status == 'Pending') {
          materialPendingInspectionStock[item.materialCode] = 
              (materialPendingInspectionStock[item.materialCode] ?? 0) + 
              item.pendingQty;
        } else {
          materialInspectionStock[item.materialCode] = 
              (materialInspectionStock[item.materialCode] ?? 0) + 
              item.inspectedQty;
        }
      }
    }

    return materials.map((material) {
      final currentStock = materialStock[material.partNo] ?? 0;
      final inspectionStock = materialInspectionStock[material.partNo] ?? 0;
      final pendingInspectionStock = materialPendingInspectionStock[material.partNo] ?? 0;
      final totalStock = currentStock + inspectionStock + pendingInspectionStock;
      final bestRate = material.getLowestRate(ref);
      final stockValue = totalStock * (double.tryParse(bestRate) ?? 0);

      return PlutoRow(
        cells: {
          'materialCode': PlutoCell(value: material.partNo),
          'description': PlutoCell(value: material.description),
          'unit': PlutoCell(value: material.unit),
          'currentStock': PlutoCell(value: currentStock),
          'inspectionStock': PlutoCell(value: inspectionStock),
          'pendingInspectionStock': PlutoCell(value: pendingInspectionStock),
          'totalStock': PlutoCell(value: totalStock),
          'stockValue': PlutoCell(value: '₹${stockValue.toStringAsFixed(2)}'),
          'preferredVendor': PlutoCell(value: material.getPreferredVendorName(ref)),
          'bestRate': PlutoCell(value: bestRate.isEmpty ? '-' : '₹$bestRate'),
          'actions': PlutoCell(value: ''),
        },
      );
    }).toList();
  }

  void _navigateToDetails(PlutoRow row) {
    final materialCode = row.cells['materialCode']!.value as String;
    final material = ref.read(materialListProvider)
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

    // Track which items have been inspected and accepted
    final inspectedItems = <String, Set<String>>{}; // materialCode -> Set of GRN numbers
    for (var inspection in qualityInspections) {
      for (var item in inspection.items) {
        if (item.acceptedQty > 0) {
          inspectedItems.putIfAbsent(item.materialCode, () => {}).add(inspection.grnNo);
        }
      }
    }

    for (var inward in storeInwards) {
      for (var item in inward.items) {
        if (item.materialCode == material.partNo) {
          // Only show items that have been inspected and accepted
          if (inspectedItems[item.materialCode]?.contains(inward.grnNo) ?? false) {
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
                'acceptedQty': PlutoCell(value: item.acceptedQty),
                'rate': PlutoCell(value: '₹${item.costPerUnit}'),
                'value': PlutoCell(
                    value:
                        '₹${(item.acceptedQty * double.parse(item.costPerUnit)).toStringAsFixed(2)}'),
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
    final qualityInspections = ref.watch(qualityInspectionProvider);
    final rows = <PlutoRow>[];

    for (var inspection in qualityInspections) {
      for (var item in inspection.items) {
        if (item.materialCode == material.partNo) {
          // Only show items that are pending or partially inspected
          if (item.pendingQty > 0 || (item.inspectedQty > 0 && item.inspectedQty < item.receivedQty)) {
            rows.add(PlutoRow(
              cells: {
                'inspectionNo': PlutoCell(value: inspection.inspectionNo),
                'grnNo': PlutoCell(value: inspection.grnNo),
                'jobNo': PlutoCell(value: inspection.jobNumbers[inspection.poNo] ?? ''),
                'poNo': PlutoCell(value: inspection.poNo),
                'supplier': PlutoCell(value: inspection.supplierName),
                'receivedQty': PlutoCell(value: item.receivedQty),
                'inspectedQty': PlutoCell(value: item.inspectedQty),
                'pendingQty': PlutoCell(value: item.pendingQty),
                'status': PlutoCell(value: item.inspectedQty > 0 ? 'Partially Inspected' : 'Pending'),
                'date': PlutoCell(value: inspection.inspectionDate),
              },
            ));
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