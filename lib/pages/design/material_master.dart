import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mpt_ims/pages/design/add_material_page.dart';
import 'package:mpt_ims/provider/material_provider.dart';
import 'package:mpt_ims/models/material_item.dart';

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
                            DataColumn(label: Text('Vendor')),
                            DataColumn(label: Text('Supplier Rate')),
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

    final stockQty = double.tryParse(m.avlStock) ?? 0;
    final stockValue = double.tryParse(m.avlStockValue) ?? 0;
    final costDiff = double.tryParse(m.costDiff) ?? 0;

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
        DataCell(Text(m.vendorName)),
        DataCell(Text('₹${m.supplierRate}')),
        DataCell(Text('₹${m.seiplRate}')),
        DataCell(Text('₹${m.saleRate}')),
        DataCell(
          Text(
            '${m.avlStock} ${m.unit}',
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
        DataCell(Text('${m.totalReceivedQty} ${m.unit}')),
        DataCell(Text('${m.vendorIssuedQty} ${m.unit}')),
        DataCell(Text('${m.vendorReceivedQty} ${m.unit}')),
        DataCell(Text('${m.boardIssueQty} ${m.unit}')),
        DataCell(Text('${m.billingQtyDiff} ${m.unit}')),
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

  @override
  bool get isRowCountApproximate => false;

  @override
  int get rowCount => materials.length;

  @override
  int get selectedRowCount => 0;
}
