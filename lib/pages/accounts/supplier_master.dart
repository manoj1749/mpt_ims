import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mpt_ims/models/supplier.dart';
import 'package:mpt_ims/provider/supplier_provider.dart';
import 'package:mpt_ims/pages/accounts/add_supplier_page.dart';

class SupplierMasterPage extends ConsumerWidget {
  const SupplierMasterPage({super.key});

  void _confirmDeleteSupplier(
      BuildContext context, WidgetRef ref, Supplier supplier) {
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
          FilledButton.tonal(
            onPressed: () {
              ref.read(supplierListProvider.notifier).deleteSupplier(supplier);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Supplier deleted')),
              );
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
    final suppliers = ref.watch(supplierListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Supplier Master'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              // TODO: Implement search
            },
            tooltip: 'Search Suppliers',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AddSupplierPage()),
        ),
        child: const Icon(Icons.add),
      ),
      body: suppliers.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.business_outlined,
                    size: 64,
                    color: Colors.grey[300],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No suppliers yet',
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
                          builder: (_) => const AddSupplierPage()),
                    ),
                    child: const Text('Add New Supplier'),
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
                        '${suppliers.length} Suppliers',
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
                          source: _SupplierDataSource(
                            suppliers: suppliers,
                            context: context,
                            ref: ref,
                            onDelete: (supplier) =>
                                _confirmDeleteSupplier(context, ref, supplier),
                          ),
                          header: null,
                          rowsPerPage: suppliers.length,
                          showFirstLastButtons: true,
                          showCheckboxColumn: false,
                          horizontalMargin: 16,
                          columnSpacing: 20,
                          availableRowsPerPage: const [20, 50, 100, 200],
                          columns: const [
                            DataColumn(label: Text('Name')),
                            DataColumn(label: Text('Vendor Code')),
                            DataColumn(label: Text('Contact Person')),
                            DataColumn(label: Text('Phone')),
                            DataColumn(label: Text('Email')),
                            DataColumn(label: Text('Alt. Email')),
                            DataColumn(label: Text('Address')),
                            DataColumn(label: Text('State')),
                            DataColumn(label: Text('State Code')),
                            DataColumn(label: Text('PAN')),
                            DataColumn(label: Text('GST No')),
                            DataColumn(label: Text('IGST')),
                            DataColumn(label: Text('CGST')),
                            DataColumn(label: Text('SGST')),
                            DataColumn(label: Text('Total GST')),
                            DataColumn(label: Text('Bank')),
                            DataColumn(label: Text('Branch')),
                            DataColumn(label: Text('Account No')),
                            DataColumn(label: Text('IFSC')),
                            DataColumn(label: Text('Payment Terms')),
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

class _SupplierDataSource extends DataTableSource {
  final List<Supplier> suppliers;
  final BuildContext context;
  final WidgetRef ref;
  final Function(Supplier) onDelete;

  _SupplierDataSource({
    required this.suppliers,
    required this.context,
    required this.ref,
    required this.onDelete,
  });

  @override
  DataRow? getRow(int index) {
    if (index >= suppliers.length) return null;
    final s = suppliers[index];

    return DataRow(
      cells: [
        DataCell(
          Text(
            s.name,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
        ),
        DataCell(
          Text(
            s.vendorCode,
            style: TextStyle(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        DataCell(Text(s.contact)),
        DataCell(Text(s.phone)),
        DataCell(Text(s.email)),
        DataCell(Text(s.email1)),
        DataCell(
          Text(
            [s.address1, s.address2, s.address3, s.address4]
                .where((addr) => addr.isNotEmpty)
                .join(', '),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        DataCell(Text(s.state)),
        DataCell(Text(s.stateCode)),
        DataCell(Text(s.pan)),
        DataCell(Text(s.gstNo)),
        DataCell(Text('${s.igst}%')),
        DataCell(Text('${s.cgst}%')),
        DataCell(Text('${s.sgst}%')),
        DataCell(
          Text(
            '${s.totalGst}%',
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
        ),
        DataCell(Text(s.bank)),
        DataCell(Text(s.branch)),
        DataCell(Text(s.account)),
        DataCell(Text(s.ifsc)),
        DataCell(Text(s.paymentTerms)),
        DataCell(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.edit_outlined, size: 20),
                onPressed: () {
                  // TODO: Implement inline editing
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
                onPressed: () => onDelete(s),
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
  int get rowCount => suppliers.length;

  @override
  int get selectedRowCount => 0;
}
