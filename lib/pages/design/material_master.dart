import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mpt_ims/pages/design/add_material_page.dart';
import 'package:mpt_ims/provider/material_provider.dart';

class MaterialMasterPage extends ConsumerWidget {
  const MaterialMasterPage({super.key});

  void _confirmDelete(BuildContext context, WidgetRef ref, int index) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Material'),
        content: const Text('Are you sure you want to delete this material item?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              ref.read(materialListProvider.notifier).deleteMaterial(index);
              Navigator.pop(context);
            },
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
      appBar: AppBar(title: const Text('Material Master')),
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
          ? const Center(child: Text('No materials found.'))
          : SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columnSpacing: 24,
                columns: const [
                  DataColumn(label: Text('SL No')),
                  DataColumn(label: Text('Description')),
                  DataColumn(label: Text('Vendor')),
                  DataColumn(label: Text('Part No')),
                  DataColumn(label: Text('Unit')),
                  DataColumn(label: Text('Supplier Rate')),
                  DataColumn(label: Text('SEIPL Rate')),
                  DataColumn(label: Text('Category')),
                  DataColumn(label: Text('Sub Category')),
                  DataColumn(label: Text('Sale Rate')),
                  DataColumn(label: Text('Total Received Qty')),
                  DataColumn(label: Text('Vendor Issued Qty')),
                  DataColumn(label: Text('Vendor Received Qty')),
                  DataColumn(label: Text('Board Issue Qty')),
                  DataColumn(label: Text('Available Stock')),
                  DataColumn(label: Text('Stock Value')),
                  DataColumn(label: Text('Billing Qty Diff')),
                  DataColumn(label: Text('Received Cost')),
                  DataColumn(label: Text('Billed Cost')),
                  DataColumn(label: Text('Cost Diff')),
                  DataColumn(label: Text('Actions')),
                ],
                rows: List.generate(materials.length, (index) {
                  final item = materials[index];
                  return DataRow(cells: [
                    DataCell(Text('${index + 1}')),
                    DataCell(Text(item.description)),
                    DataCell(Text(item.vendorName)),
                    DataCell(Text(item.partNo)),
                    DataCell(Text(item.unit)),
                    DataCell(Text(item.supplierRate)),
                    DataCell(Text(item.seiplRate)),
                    DataCell(Text(item.category)),
                    DataCell(Text(item.subCategory)),
                    DataCell(Text(item.saleRate)),
                    DataCell(Text(item.totalReceivedQty)),
                    DataCell(Text(item.vendorIssuedQty)),
                    DataCell(Text(item.vendorReceivedQty)),
                    DataCell(Text(item.boardIssueQty)),
                    DataCell(Text(item.avlStock)),
                    DataCell(Text(item.avlStockValue)),
                    DataCell(Text(item.billingQtyDiff)),
                    DataCell(Text(item.totalReceivedCost)),
                    DataCell(Text(item.totalBilledCost)),
                    DataCell(Text(item.costDiff)),
                    DataCell(Row(
                      children: [
                        Tooltip(
                          message: 'Edit',
                          child: IconButton(
                            icon: const Icon(Icons.edit),
                            color: Colors.teal[600],
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => AddMaterialPage(materialToEdit: item),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 6),
                        Tooltip(
                          message: 'Delete',
                          child: IconButton(
                            icon: const Icon(Icons.delete),
                            color: Colors.red[400],
                            onPressed: () => _confirmDelete(context, ref, index),
                          ),
                        ),
                      ],
                    )),
                  ]);
                }),
              ),
            ),
    );
  }
}
