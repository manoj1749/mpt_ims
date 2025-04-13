import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mpt_ims/models/supplier.dart';
import 'package:mpt_ims/provider/supplier_provider.dart';
import 'package:mpt_ims/pages/accounts/add_supplier_page.dart';

class SupplierMasterPage extends ConsumerWidget {
  const SupplierMasterPage({super.key});

  void _showSupplierDetails(BuildContext context, Supplier supplier) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(supplier.name),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Address: ${supplier.address1}, ${supplier.address2}, ${supplier.address3}, ${supplier.address4}'),
              Text('State: ${supplier.state} (${supplier.stateCode})'),
              Text('Payment Terms: ${supplier.paymentTerms}'),
              Text('PAN NO: ${supplier.pan}'),
              Text('GST NO: ${supplier.gstNo}'),
              Text('IGST: ${supplier.igst}'),
              Text('CGST: ${supplier.cgst}'),
              Text('SGST: ${supplier.sgst}'),
              Text('Total GST: ${supplier.totalGst}'),
              Text('Contact Person: ${supplier.contact}'),
              Text('Phone: ${supplier.phone}'),
              Text('Email: ${supplier.email}'),
              Text('Bank: ${supplier.bank}, Branch: ${supplier.branch}'),
              Text('Account: ${supplier.account}'),
              Text('IFSC: ${supplier.ifsc}'),
              Text('Alternate Email: ${supplier.email1}'),
              Text('Vendor Code: ${supplier.vendorCode}'),
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

  void _confirmDeleteSupplier(BuildContext context, WidgetRef ref, Supplier supplier) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Supplier'),
        content: Text('Are you sure you want to delete ${supplier.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              ref.read(supplierListProvider.notifier).deleteSupplier(supplier);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Supplier deleted')),
              );
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final suppliers = ref.watch(supplierListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Supplier Master'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AddSupplierPage()),
        ),
        child: const Icon(Icons.add),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: GridView.count(
          crossAxisCount: 3,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.4,
          children: suppliers.map((supplier) {
            return Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      supplier.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text('Contact: ${supplier.contact}'),
                    Text('Phone: ${supplier.phone}'),
                    Align(
                      alignment: Alignment.bottomRight,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit),
                            onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => AddSupplierPage(supplierToEdit: supplier),
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.visibility),
                            onPressed: () => _showSupplierDetails(context, supplier),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete),
                            onPressed: () => _confirmDeleteSupplier(context, ref, supplier),
                          ),
                        ],
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
  }
}
