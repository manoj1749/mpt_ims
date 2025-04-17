import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mpt_ims/models/supplier.dart';
import 'package:mpt_ims/provider/supplier_provider.dart';
import 'package:mpt_ims/pages/accounts/add_supplier_page.dart';

class SupplierMasterPage extends ConsumerWidget {
  const SupplierMasterPage({super.key});

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
      appBar: AppBar(title: const Text('Supplier Master')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AddSupplierPage()),
        ),
        child: const Icon(Icons.add),
      ),
      body: suppliers.isEmpty
          ? const Center(child: Text('No suppliers found.'))
          : SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columnSpacing: 24,
                columns: const [
                  DataColumn(label: Text('Name')),
                  DataColumn(label: Text('Address')),
                  DataColumn(label: Text('State')),
                  DataColumn(label: Text('State Code')),
                  DataColumn(label: Text('Contact')),
                  DataColumn(label: Text('Phone')),
                  DataColumn(label: Text('Email')),
                  DataColumn(label: Text('Alt Email')),
                  DataColumn(label: Text('Vendor Code')),
                  DataColumn(label: Text('PAN')),
                  DataColumn(label: Text('GST No')),
                  DataColumn(label: Text('IGST')),
                  DataColumn(label: Text('CGST')),
                  DataColumn(label: Text('SGST')),
                  DataColumn(label: Text('Total GST')),
                  DataColumn(label: Text('Bank')),
                  DataColumn(label: Text('Branch')),
                  DataColumn(label: Text('Account')),
                  DataColumn(label: Text('IFSC')),
                  DataColumn(label: Text('Payment Terms')),
                  DataColumn(label: Text('Actions')),
                ],
                rows: suppliers.map((s) {
                  return DataRow(cells: [
                    DataCell(Text(s.name)),
                    DataCell(Text('${s.address1}, ${s.address2}, ${s.address3}, ${s.address4}')),
                    DataCell(Text(s.state)),
                    DataCell(Text(s.stateCode)),
                    DataCell(Text(s.contact)),
                    DataCell(Text(s.phone)),
                    DataCell(Text(s.email)),
                    DataCell(Text(s.email1)),
                    DataCell(Text(s.vendorCode)),
                    DataCell(Text(s.pan)),
                    DataCell(Text(s.gstNo)),
                    DataCell(Text(s.igst)),
                    DataCell(Text(s.cgst)),
                    DataCell(Text(s.sgst)),
                    DataCell(Text(s.totalGst)),
                    DataCell(Text(s.bank)),
                    DataCell(Text(s.branch)),
                    DataCell(Text(s.account)),
                    DataCell(Text(s.ifsc)),
                    DataCell(Text(s.paymentTerms)),
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
                                  builder: (_) => AddSupplierPage(supplierToEdit: s),
                                ),
                              );
                            },
                          ),
                        ),
                        Tooltip(
                          message: 'Delete',
                          child: IconButton(
                            icon: const Icon(Icons.delete),
                            color: Colors.red[400],
                            onPressed: () => _confirmDeleteSupplier(context, ref, s),
                          ),
                        ),
                      ],
                    )),
                  ]);
                }).toList(),
              ),
            ),
    );
  }
}
