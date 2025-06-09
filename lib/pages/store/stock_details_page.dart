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
import '../../models/category.dart';
import '../../provider/category_provider.dart';

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
          materialInspectionStock[item.materialCode]![inward.grnNo] = underInspectionQty;
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
    ref.watch(qualityInspectionProvider);
    final categories = ref.watch(categoryListProvider);
    final rows = <PlutoRow>[];

    // Get the material's category
    final category = categories.firstWhere(
      (c) => c.name == material.category,
      orElse: () => Category(name: material.category),
    );

    // Process store inwards for stock distribution
    for (var inward in storeInwards) {
      for (var item in inward.items) {
        if (item.materialCode == material.partNo) {
          // Find PO if it exists
          final po = purchaseOrders.firstWhere(
            (po) => po.poNo == inward.poNo,
            orElse: () => PurchaseOrder(
              poNo: inward.poNo,
              poDate: 'Unknown',
              supplierName: inward.supplierName,
              transport: 'Unknown',
              deliveryRequirements: 'Unknown',
              items: [],
              total: 0,
              igst: 0,
              cgst: 0,
              sgst: 0,
              grandTotal: 0,
            ),
          );

          // If quality check is not required, show full quantity in stock
          if (!category.requiresQualityCheck) {
            rows.add(PlutoRow(
              cells: {
                'grnNo': PlutoCell(value: inward.grnNo),
                'jobNo': PlutoCell(value: inward.grnNo),
                'poNo': PlutoCell(value: inward.poNo),
                'poDate': PlutoCell(value: po.poDate),
                'supplier': PlutoCell(value: inward.supplierName),
                'receivedQty': PlutoCell(value: item.receivedQty),
                'acceptedQty': PlutoCell(value: item.receivedQty), // Full quantity is accepted
                'rate': PlutoCell(value: '₹${item.costPerUnit}'),
                'value': PlutoCell(
                    value: '₹${(item.receivedQty * double.parse(item.costPerUnit)).toStringAsFixed(2)}'),
                'date': PlutoCell(value: inward.grnDate),
              },
            ));
            continue;
          }

          // For items requiring inspection, show accepted quantities
          final acceptedQty = item.totalAcceptedQty;
          if (acceptedQty > 0) {
            rows.add(PlutoRow(
              cells: {
                'grnNo': PlutoCell(value: inward.grnNo),
                'jobNo': PlutoCell(value: inward.grnNo),
                'poNo': PlutoCell(value: inward.poNo),
                'poDate': PlutoCell(value: po.poDate),
                'supplier': PlutoCell(value: inward.supplierName),
                'receivedQty': PlutoCell(value: item.receivedQty),
                'acceptedQty': PlutoCell(value: acceptedQty),
                'rate': PlutoCell(value: '₹${item.costPerUnit}'),
                'value': PlutoCell(
                    value: '₹${(acceptedQty * double.parse(item.costPerUnit)).toStringAsFixed(2)}'),
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
    ref.watch(qualityInspectionProvider);
    final categories = ref.watch(categoryListProvider);
    final rows = <PlutoRow>[];

    // Get the material's category
    final category = categories.firstWhere(
      (c) => c.name == material.category,
      orElse: () => Category(name: material.category),
    );

    // Skip inspection rows if quality check is not required
    if (!category.requiresQualityCheck) {
      return rows;
    }

    // Process store inwards for items under inspection
    for (var inward in storeInwards) {
      for (var item in inward.items) {
        if (item.materialCode == material.partNo) {
          final underInspectionQty = item.underInspectionQty;
          
          if (underInspectionQty > 0) {
            // Get latest inspection status
            final inspectionEntries = item.inspectionStatus.entries.toList();
            inspectionEntries.sort((a, b) => b.key.compareTo(a.key));
            final latestInspection = inspectionEntries.isEmpty ? null : inspectionEntries.first;

            final status = latestInspection?.value.status ?? 'Pending Inspection';
            final inspectedQty = item.inspectedQuantity;

            rows.add(PlutoRow(
              cells: {
                'inspectionNo': PlutoCell(
                  value: latestInspection?.key ?? '-'
                ),
                'grnNo': PlutoCell(value: inward.grnNo),
                'jobNo': PlutoCell(value: '-'),
                'poNo': PlutoCell(value: inward.poNo),
                'supplier': PlutoCell(value: inward.supplierName),
                'receivedQty': PlutoCell(value: item.receivedQty),
                'inspectedQty': PlutoCell(value: inspectedQty),
                'pendingQty': PlutoCell(value: underInspectionQty),
                'status': PlutoCell(value: status),
                'date': PlutoCell(value: inward.grnDate),
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
                    Text('Storage Location: ${material.storageLocation}'),
                    Text('Rack Number: ${material.rackNumber}'),
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
