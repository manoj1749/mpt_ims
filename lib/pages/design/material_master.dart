import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mpt_ims/models/material_item.dart';
import 'package:mpt_ims/pages/design/add_material_page.dart';
import 'package:mpt_ims/provider/material_provider.dart';

class MaterialMasterPage extends ConsumerWidget {
  const MaterialMasterPage({super.key});

  void _showMaterialDetails(BuildContext context, MaterialItem item) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(item.description),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('SL No: ${item.slNo}'),
              Text('Vendor: ${item.vendorName}'),
              Text('Part No: ${item.partNo}'),
              Text('Unit: ${item.unit}'),
              Text('Supplier Rate: ${item.supplierRate}'),
              Text('SEIPL Rate: ${item.seiplRate}'),
              Text('Category: ${item.category}'),
              Text('Sub Category: ${item.subCategory}'),
              Text('Sale Rate: ${item.saleRate}'),
              Text('Total Received Qty: ${item.totalReceivedQty}'),
              Text('Vendor Issued Qty: ${item.vendorIssuedQty}'),
              Text('Vendor Received Qty: ${item.vendorReceivedQty}'),
              Text('Board Issue Qty: ${item.boardIssueQty}'),
              Text('Available Stock: ${item.avlStock}'),
              Text('Available Stock Value: ${item.avlStockValue}'),
              Text('Billing Qty Diff: ${item.billingQtyDiff}'),
              Text('Total Received Cost: ${item.totalReceivedCost}'),
              Text('Total Billed Cost: ${item.totalBilledCost}'),
              Text('Cost Diff: ${item.costDiff}'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          )
        ],
      ),
    );
  }

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

  void _openAddMaterialForm(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AddMaterialPage()),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final materials = ref.watch(materialListProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Material Master')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openAddMaterialForm(context),
        child: const Icon(Icons.add),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: GridView.count(
          crossAxisCount: 3,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.4,
          children: List.generate(materials.length, (index) {
            final item = materials[index];
            return Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      item.description,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    Text('SL No: ${index + 1}'),
                    Text('Part No: ${item.partNo}'),
                    Text('Stock: ${item.avlStock} ${item.unit}'),
                    Align(
                      alignment: Alignment.bottomRight,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.visibility),
                            onPressed: () => _showMaterialDetails(context, item),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete),
                            onPressed: () => _confirmDelete(context, ref, index),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}