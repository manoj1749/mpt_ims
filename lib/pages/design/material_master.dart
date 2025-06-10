// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mpt_ims/pages/design/add_material_page.dart';
import 'package:mpt_ims/provider/material_provider.dart';
import 'package:mpt_ims/models/material_item.dart';
import 'package:mpt_ims/provider/vendor_material_rate_provider.dart';
import 'package:pluto_grid/pluto_grid.dart';
import 'package:collection/collection.dart';
import '../../widgets/pluto_grid_configuration.dart';

class MaterialMasterPage extends ConsumerStatefulWidget {
  const MaterialMasterPage({super.key});

  @override
  ConsumerState<MaterialMasterPage> createState() => _MaterialMasterPageState();
}

class _MaterialMasterPageState extends ConsumerState<MaterialMasterPage> {
  PlutoGridStateManager? stateManager;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    // Set loading to false after the first frame
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

  List<PlutoColumn> _getColumns(BuildContext context, WidgetRef ref) {
    return [
      PlutoColumn(
        title: 'SL No',
        field: 'slNo',
        type: PlutoColumnType.text(),
        width: 100,
        enableEditingMode: false,
      ),
      PlutoColumn(
        title: 'Part No',
        field: 'partNo',
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
        title: 'Category',
        field: 'category',
        type: PlutoColumnType.text(),
        width: 120,
        enableEditingMode: false,
      ),
      PlutoColumn(
        title: 'Sub Category',
        field: 'subCategory',
        type: PlutoColumnType.text(),
        width: 120,
        enableEditingMode: false,
      ),
      PlutoColumn(
        title: 'Unit',
        field: 'unit',
        type: PlutoColumnType.text(),
        width: 80,
        backgroundColor: Colors.grey[850],
        titleTextAlign: PlutoColumnTextAlign.center,
        textAlign: PlutoColumnTextAlign.center,
        enableEditingMode: false,
      ),
      PlutoColumn(
        title: 'Actual Weight',
        field: 'actualWeight',
        type: PlutoColumnType.text(),
        width: 120,
        backgroundColor: Colors.grey[850],
        titleTextAlign: PlutoColumnTextAlign.center,
        textAlign: PlutoColumnTextAlign.center,
        enableEditingMode: false,
      ),
      PlutoColumn(
        title: 'Storage Location',
        field: 'storageLocation',
        type: PlutoColumnType.text(),
        width: 120,
        backgroundColor: Colors.grey[850],
        titleTextAlign: PlutoColumnTextAlign.center,
        textAlign: PlutoColumnTextAlign.center,
        enableEditingMode: false,
      ),
      PlutoColumn(
        title: 'Rack Number',
        field: 'rackNumber',
        type: PlutoColumnType.text(),
        width: 120,
        backgroundColor: Colors.grey[850],
        titleTextAlign: PlutoColumnTextAlign.center,
        textAlign: PlutoColumnTextAlign.center,
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
        title: '# of Vendors',
        field: 'vendorCount',
        type: PlutoColumnType.number(),
        width: 120,
        enableEditingMode: false,
      ),
      PlutoColumn(
        title: 'Sale Rate',
        field: 'saleRate',
        type: PlutoColumnType.text(),
        width: 120,
        enableEditingMode: false,
      ),
      PlutoColumn(
        title: 'Stock',
        field: 'stock',
        type: PlutoColumnType.text(),
        width: 120,
        enableEditingMode: false,
      ),
      PlutoColumn(
        title: 'Inspection Stock',
        field: 'inspectionStock',
        type: PlutoColumnType.text(),
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
        title: 'Total Received',
        field: 'totalReceived',
        type: PlutoColumnType.text(),
        width: 120,
        enableEditingMode: false,
      ),
      PlutoColumn(
        title: 'Vendor Issued',
        field: 'vendorIssued',
        type: PlutoColumnType.text(),
        width: 120,
        enableEditingMode: false,
      ),
      PlutoColumn(
        title: 'Vendor Received',
        field: 'vendorReceived',
        type: PlutoColumnType.text(),
        width: 120,
        enableEditingMode: false,
      ),
      PlutoColumn(
        title: 'Board Issue',
        field: 'boardIssue',
        type: PlutoColumnType.text(),
        width: 120,
        enableEditingMode: false,
      ),
      PlutoColumn(
        title: 'Cost Diff',
        field: 'costDiff',
        type: PlutoColumnType.text(),
        width: 120,
        enableEditingMode: false,
      ),
      PlutoColumn(
        title: 'Actions',
        field: 'actions',
        type: PlutoColumnType.text(),
        width: 200,
        enableEditingMode: false,
        renderer: (rendererContext) {
          final materials = ref.read(materialListProvider);
          final material = materials
              .where((m) => m.slNo == rendererContext.row.cells['slNo']!.value)
              .firstOrNull;

          if (material == null) {
            return const SizedBox.shrink();
          }

          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.edit_outlined, size: 20),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AddMaterialPage(
                        materialToEdit: material,
                        index: materials.indexOf(material),
                      ),
                    ),
                  );
                },
                color: Colors.blue,
                tooltip: 'Edit',
                constraints: const BoxConstraints(
                  minWidth: 32,
                  minHeight: 32,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.people_outline, size: 20),
                onPressed: () => _showVendorDetails(
                  context,
                  material,
                  ref,
                ),
                tooltip: 'Vendor Details',
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, size: 20),
                onPressed: () => _confirmDelete(
                  context,
                  ref,
                  material,
                ),
                color: Colors.red[400],
                tooltip: 'Delete',
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

  List<PlutoRow> _getRows(List<MaterialItem> materials, WidgetRef ref) {
    return materials.map((m) {
      final stockValue = double.tryParse(m.getTotalStockValue(ref)) ?? 0;
      final costDiff = double.tryParse(m.getTotalCostDiff(ref)) ?? 0;

      // Get total inspection stock across all vendors
      final inspectionStock = ref
          .read(vendorMaterialRateProvider.notifier)
          .getRatesForMaterial(m.slNo)
          .fold(
              0.0,
              (sum, rate) =>
                  sum + (double.tryParse(rate.inspectionStock) ?? 0));

      return PlutoRow(
        cells: {
          'slNo': PlutoCell(value: m.slNo),
          'partNo': PlutoCell(value: m.partNo),
          'description': PlutoCell(value: m.description),
          'category': PlutoCell(value: m.category),
          'subCategory': PlutoCell(value: m.subCategory),
          'unit': PlutoCell(value: m.unit),
          'actualWeight': PlutoCell(value: m.actualWeight),
          'storageLocation': PlutoCell(value: m.storageLocation),
          'rackNumber': PlutoCell(value: m.rackNumber),
          'preferredVendor': PlutoCell(value: m.getPreferredVendorName(ref)),
          'bestRate': PlutoCell(
              value: m.getLowestRate(ref).isEmpty
                  ? '-'
                  : '₹${m.getLowestRate(ref)}'),
          'vendorCount': PlutoCell(value: m.getVendorCount(ref)),
          'saleRate': PlutoCell(
              value: m.getPreferredVendorSaleRate(ref).isEmpty
                  ? '-'
                  : '₹${m.getPreferredVendorSaleRate(ref)}'),
          'stock':
              PlutoCell(value: '${m.getTotalAvailableStock(ref)} ${m.unit}'),
          'inspectionStock': PlutoCell(value: '$inspectionStock ${m.unit}'),
          'stockValue': PlutoCell(value: '₹${stockValue.toStringAsFixed(2)}'),
          'totalReceived':
              PlutoCell(value: '${m.getTotalReceivedQty(ref)} ${m.unit}'),
          'vendorIssued':
              PlutoCell(value: '${m.getTotalIssuedQty(ref)} ${m.unit}'),
          'vendorReceived':
              PlutoCell(value: '${m.getTotalReceivedQty(ref)} ${m.unit}'),
          'boardIssue':
              PlutoCell(value: '${m.getTotalIssuedQty(ref)} ${m.unit}'),
          'costDiff': PlutoCell(value: '₹${costDiff.toStringAsFixed(2)}'),
          'actions': PlutoCell(value: ''),
        },
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    // Watch both the materials list and vendor rates to ensure UI updates
    final materials = ref.watch(materialListProvider);
    // Watch the vendor rates state to trigger rebuilds when it changes
    ref.watch(vendorMaterialRateProvider);

    // Rebuild the grid rows when either materials or vendor rates change
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && stateManager?.rows.isNotEmpty == true) {
        stateManager?.removeAllRows();
        stateManager?.appendRows(_getRows(materials, ref));
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Material Master'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              // TODO: Implement search
            },
            tooltip: 'Search Materials',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddMaterialPage()),
          );
        },
        child: const Icon(Icons.add),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : materials.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.inventory_2_outlined,
                        size: 64,
                        color: Colors.grey[300],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No materials yet',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 8),
                      FilledButton(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const AddMaterialPage()),
                        ),
                        child: const Text('Add New Material'),
                      ),
                    ],
                  ),
                )
              : Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            '${materials.length} Materials',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(width: 16),
                          FilledButton.tonal(
                            onPressed: () {
                              // TODO: Implement filtering
                            },
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.filter_list, size: 20),
                                SizedBox(width: 8),
                                Text('Filter'),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        child: PlutoGrid(
                          columns: _getColumns(context, ref),
                          rows: _getRows(materials, ref),
                          onLoaded: _onPlutoGridLoaded,
                          configuration: PlutoGridConfigurations.darkMode(),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }

  void _confirmDelete(
      BuildContext context, WidgetRef ref, MaterialItem material) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Material'),
        content:
            const Text('Are you sure you want to delete this material item?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton.tonal(
            onPressed: () async {
              try {
                Navigator.pop(context); // Close dialog first

                // Delete all vendor rates for this material first
                final vendorRateNotifier =
                    ref.read(vendorMaterialRateProvider.notifier);
                final rates =
                    vendorRateNotifier.getRatesForMaterial(material.slNo);
                for (final rate in rates) {
                  await vendorRateNotifier.deleteRate(
                      material.slNo, rate.vendorId);
                }

                // Then delete the material
                await ref
                    .read(materialListProvider.notifier)
                    .deleteMaterial(material);

                // The UI will automatically update due to the provider changes
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error deleting material: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: FilledButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showVendorDetails(
      BuildContext context, MaterialItem material, WidgetRef ref) {
    final rates = ref
        .read(vendorMaterialRateProvider.notifier)
        .getRatesForMaterial(material.slNo);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Vendors for ${material.description}'),
        content: SizedBox(
          width: 800,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const ListTile(
                title: Row(
                  children: [
                    Expanded(child: Text('Vendor')),
                    Expanded(child: Text('Supplier Rate')),
                    Expanded(child: Text('Sale Rate')),
                    Expanded(child: Text('Stock')),
                    Expanded(child: Text('Stock Value')),
                    Expanded(child: Text('Last Purchase')),
                    Expanded(child: Text('Remarks')),
                  ],
                ),
              ),
              const Divider(),
              ...rates.map((rate) {
                return ListTile(
                  title: Row(
                    children: [
                      Expanded(child: Text(rate.vendorId)),
                      Expanded(child: Text('₹${rate.saleRate}')),
                      Expanded(
                          child: Text('${rate.avlStock} ${material.unit}')),
                      Expanded(
                          child:
                              Text('₹${rate.stockValue.toStringAsFixed(2)}')),
                      Expanded(child: Text(rate.lastPurchaseDate)),
                      Expanded(child: Text(rate.remarks)),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
