import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mpt_ims/pages/design/add_material_page.dart';
import 'package:mpt_ims/provider/material_provider.dart';
import 'package:mpt_ims/models/material_item.dart';
import 'package:mpt_ims/models/vendor_material_rate.dart';
import 'package:mpt_ims/provider/vendor_material_rate_provider.dart';

class MaterialMasterPage extends ConsumerWidget {
  const MaterialMasterPage({super.key});

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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final materials = ref.watch(materialListProvider);

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
      body: materials.isEmpty
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
                    child: Card(
                      elevation: 0,
                      margin: EdgeInsets.zero,
                      child: SizedBox(
                        width: MediaQuery.of(context).size.width - 32,
                        child: PaginatedDataTable(
                          source: _MaterialDataSource(
                            materials: materials,
                            context: context,
                            ref: ref,
                            onDelete: (material) =>
                                _confirmDelete(context, ref, material),
                          ),
                          header: null,
                          rowsPerPage: materials.length,
                          showFirstLastButtons: true,
                          showCheckboxColumn: false,
                          horizontalMargin: 16,
                          columnSpacing: 20,
                          availableRowsPerPage: const [20, 50, 100, 200],
                          columns: const [
                            DataColumn(label: Text('SL No')),
                            DataColumn(label: Text('Part No')),
                            DataColumn(label: Text('Description')),
                            DataColumn(label: Text('Category')),
                            DataColumn(label: Text('Sub Category')),
                            DataColumn(label: Text('Unit')),
                            DataColumn(label: Text('Preferred Vendor')),
                            DataColumn(label: Text('Best Rate')),
                            DataColumn(label: Text('# of Vendors')),
                            DataColumn(label: Text('SEIPL Rate')),
                            DataColumn(label: Text('Sale Rate')),
                            DataColumn(label: Text('Stock')),
                            DataColumn(label: Text('Stock Value')),
                            DataColumn(label: Text('Total Received')),
                            DataColumn(label: Text('Vendor Issued')),
                            DataColumn(label: Text('Vendor Received')),
                            DataColumn(label: Text('Board Issue')),
                            DataColumn(label: Text('Billing Diff')),
                            DataColumn(label: Text('Cost Diff')),
                            DataColumn(label: Text('Actions')),
                          ],
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

class _MaterialDataSource extends DataTableSource {
  final List<MaterialItem> materials;
  final BuildContext context;
  final WidgetRef ref;
  final Function(MaterialItem) onDelete;

  _MaterialDataSource({
    required this.materials,
    required this.context,
    required this.ref,
    required this.onDelete,
  });

  @override
  DataRow? getRow(int index) {
    if (index >= materials.length) return null;
    final m = materials[index];

    final stockQty = double.tryParse(m.getTotalAvailableStock(ref)) ?? 0;
    final stockValue = double.tryParse(m.getTotalStockValue(ref)) ?? 0;
    final costDiff = double.tryParse(m.getTotalCostDiff(ref)) ?? 0;

    return DataRow(
      cells: [
        DataCell(
          Text(
            m.slNo,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
        ),
        DataCell(
          Text(
            m.partNo,
            style: TextStyle(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        DataCell(
          Text(
            m.description,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        DataCell(Text(m.category)),
        DataCell(Text(m.subCategory)),
        DataCell(Text(m.unit)),
        DataCell(Text(m.getPreferredVendorName(ref))),
        DataCell(Text(m.getLowestSupplierRate(ref).isEmpty
            ? '-'
            : '₹${m.getLowestSupplierRate(ref)}')),
        DataCell(Text(m.getVendorCount(ref).toString())),
        DataCell(Text('₹${m.getTotalReceivedCost(ref)}')),
        DataCell(Text('₹${m.getTotalBilledCost(ref)}')),
        DataCell(
          Text(
            '${m.getTotalAvailableStock(ref)} ${m.unit}',
            style: TextStyle(
              color: stockQty > 0 ? Colors.green : Colors.red,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        DataCell(
          Text(
            '₹${stockValue.toStringAsFixed(2)}',
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
        ),
        DataCell(Text('${m.getTotalReceivedQty(ref)} ${m.unit}')),
        DataCell(Text('${m.getTotalIssuedQty(ref)} ${m.unit}')),
        DataCell(Text('${m.getTotalReceivedQty(ref)} ${m.unit}')),
        DataCell(Text('${m.getTotalIssuedQty(ref)} ${m.unit}')),
        DataCell(Text('${m.getTotalReceivedQty(ref)} ${m.unit}')),
        DataCell(
          Text(
            '₹${costDiff.toStringAsFixed(2)}',
            style: TextStyle(
              color: costDiff < 0 ? Colors.red : Colors.green,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        DataCell(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.edit_outlined, size: 20),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AddMaterialPage(
                        materialToEdit: m,
                        index: materials.indexOf(m),
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
                onPressed: () => _showVendorDetails(context, m),
                tooltip: 'Vendor Details',
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, size: 20),
                onPressed: () => onDelete(m),
                color: Colors.red[400],
                tooltip: 'Delete',
                constraints: const BoxConstraints(
                  minWidth: 32,
                  minHeight: 32,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showVendorDetails(BuildContext context, MaterialItem material) {
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
              }).toList(),
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

  @override
  bool get isRowCountApproximate => false;

  @override
  int get rowCount => materials.length;

  @override
  int get selectedRowCount => 0;
}
