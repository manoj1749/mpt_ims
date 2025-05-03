import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mpt_ims/pages/design/add_material_page.dart';
import 'package:mpt_ims/provider/material_provider.dart';
import 'package:mpt_ims/models/material_item.dart';
import 'package:mpt_ims/provider/vendor_material_rate_provider.dart';
import 'package:pluto_grid/pluto_grid.dart';

class MaterialMasterPage extends ConsumerWidget {
  const MaterialMasterPage({super.key});

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
        title: 'SEIPL Rate',
        field: 'seiplRate',
        type: PlutoColumnType.text(),
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
          final material = ref
              .read(materialListProvider)
              .firstWhere((m) => m.slNo == rendererContext.row.cells['slNo']!.value);

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
                        index: ref.read(materialListProvider).indexOf(material),
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
          .watch(vendorMaterialRateProvider.notifier)
          .getRatesForMaterial(m.slNo)
          .fold(0.0, (sum, rate) => sum + (double.tryParse(rate.inspectionStock) ?? 0));

      return PlutoRow(
        cells: {
          'slNo': PlutoCell(value: m.slNo),
          'partNo': PlutoCell(value: m.partNo),
          'description': PlutoCell(value: m.description),
          'category': PlutoCell(value: m.category),
          'subCategory': PlutoCell(value: m.subCategory),
          'unit': PlutoCell(value: m.unit),
          'preferredVendor': PlutoCell(value: m.getPreferredVendorName(ref)),
          'bestRate': PlutoCell(
              value: m.getLowestSupplierRate(ref).isEmpty
                  ? '-'
                  : '₹${m.getLowestSupplierRate(ref)}'),
          'vendorCount': PlutoCell(value: m.getVendorCount(ref)),
          'seiplRate': PlutoCell(
              value: m.getPreferredVendorSeiplRate(ref).isEmpty
                  ? '-'
                  : '₹${m.getPreferredVendorSeiplRate(ref)}'),
          'saleRate': PlutoCell(
              value: m.getPreferredVendorSaleRate(ref).isEmpty
                  ? '-'
                  : '₹${m.getPreferredVendorSaleRate(ref)}'),
          'stock': PlutoCell(value: '${m.getTotalAvailableStock(ref)} ${m.unit}'),
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
  Widget build(BuildContext context, WidgetRef ref) {
    final materials = ref.watch(materialListProvider);
    final isLoading = ref.watch(vendorRatesLoadingProvider);
    // Watch the entire vendor rates state to make the UI reactive
    final _ = ref.watch(vendorMaterialRateProvider);

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
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddMaterialPage()),
          );
        },
        child: const Icon(Icons.add),
      ),
      body: isLoading
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
                          onLoaded: (PlutoGridOnLoadedEvent event) {
                            event.stateManager.setShowColumnFilter(true);
                          },
                          configuration: PlutoGridConfiguration(
                            columnFilter: PlutoGridColumnFilterConfig(
                              filters: const [
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
            onPressed: () {
              ref.read(materialListProvider.notifier).deleteMaterial(material);
              Navigator.pop(context);
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
    final rates = material.getRankedVendors(ref);

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
                    Expanded(child: Text('SEIPL Rate')),
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
                      Expanded(child: Text('₹${rate.supplierRate}')),
                      Expanded(child: Text('₹${rate.seiplRate}')),
                      Expanded(child: Text('₹${rate.saleRate}')),
                      Expanded(child: Text('${rate.avlStock} ${material.unit}')),
                      Expanded(
                          child: Text('₹${rate.stockValue.toStringAsFixed(2)}')),
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
