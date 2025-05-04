import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mpt_ims/models/supplier.dart';
import 'package:mpt_ims/provider/supplier_provider.dart';
import 'package:mpt_ims/pages/accounts/add_supplier_page.dart';
import 'package:pluto_grid/pluto_grid.dart';

class SupplierMasterPage extends ConsumerWidget {
  const SupplierMasterPage({super.key});

  List<PlutoColumn> _getColumns(BuildContext context, WidgetRef ref) {
    return [
      PlutoColumn(
        title: 'Name',
        field: 'name',
        type: PlutoColumnType.text(),
        width: 150,
        enableEditingMode: false,
      ),
      PlutoColumn(
        title: 'Vendor Code',
        field: 'vendorCode',
        type: PlutoColumnType.text(),
        width: 120,
        enableEditingMode: false,
      ),
      PlutoColumn(
        title: 'Contact Person',
        field: 'contact',
        type: PlutoColumnType.text(),
        width: 150,
        enableEditingMode: false,
      ),
      PlutoColumn(
        title: 'Phone',
        field: 'phone',
        type: PlutoColumnType.text(),
        width: 120,
        enableEditingMode: false,
      ),
      PlutoColumn(
        title: 'Email',
        field: 'email',
        type: PlutoColumnType.text(),
        width: 180,
        enableEditingMode: false,
      ),
      PlutoColumn(
        title: 'Alt. Email',
        field: 'email1',
        type: PlutoColumnType.text(),
        width: 180,
        enableEditingMode: false,
      ),
      PlutoColumn(
        title: 'Address',
        field: 'address',
        type: PlutoColumnType.text(),
        width: 250,
        enableEditingMode: false,
      ),
      PlutoColumn(
        title: 'State',
        field: 'state',
        type: PlutoColumnType.text(),
        width: 120,
        enableEditingMode: false,
      ),
      PlutoColumn(
        title: 'State Code',
        field: 'stateCode',
        type: PlutoColumnType.text(),
        width: 100,
        enableEditingMode: false,
      ),
      PlutoColumn(
        title: 'PAN',
        field: 'pan',
        type: PlutoColumnType.text(),
        width: 120,
        enableEditingMode: false,
      ),
      PlutoColumn(
        title: 'GST No',
        field: 'gstNo',
        type: PlutoColumnType.text(),
        width: 150,
        enableEditingMode: false,
      ),
      PlutoColumn(
        title: 'IGST',
        field: 'igst',
        type: PlutoColumnType.text(),
        width: 80,
        enableEditingMode: false,
      ),
      PlutoColumn(
        title: 'CGST',
        field: 'cgst',
        type: PlutoColumnType.text(),
        width: 80,
        enableEditingMode: false,
      ),
      PlutoColumn(
        title: 'SGST',
        field: 'sgst',
        type: PlutoColumnType.text(),
        width: 80,
        enableEditingMode: false,
      ),
      PlutoColumn(
        title: 'Total GST',
        field: 'totalGst',
        type: PlutoColumnType.text(),
        width: 100,
        enableEditingMode: false,
      ),
      PlutoColumn(
        title: 'Bank',
        field: 'bank',
        type: PlutoColumnType.text(),
        width: 150,
        enableEditingMode: false,
      ),
      PlutoColumn(
        title: 'Branch',
        field: 'branch',
        type: PlutoColumnType.text(),
        width: 150,
        enableEditingMode: false,
      ),
      PlutoColumn(
        title: 'Account No',
        field: 'account',
        type: PlutoColumnType.text(),
        width: 150,
        enableEditingMode: false,
      ),
      PlutoColumn(
        title: 'IFSC',
        field: 'ifsc',
        type: PlutoColumnType.text(),
        width: 120,
        enableEditingMode: false,
      ),
      PlutoColumn(
        title: 'Payment Terms',
        field: 'paymentTerms',
        type: PlutoColumnType.text(),
        width: 200,
        enableEditingMode: false,
      ),
      PlutoColumn(
        title: 'Actions',
        field: 'actions',
        type: PlutoColumnType.text(),
        width: 120,
        enableEditingMode: false,
        renderer: (rendererContext) {
          final supplier = rendererContext.row.cells['name']!.value as String;
          final supplierData = ref
              .read(supplierListProvider)
              .firstWhere((s) => s.name == supplier);

          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.edit_outlined, size: 20),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          AddSupplierPage(supplierToEdit: supplierData),
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
                onPressed: () => _confirmDeleteSupplier(
                  context,
                  ref,
                  supplierData,
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

  List<PlutoRow> _getRows(List<Supplier> suppliers) {
    return suppliers.map((s) {
      return PlutoRow(
        cells: {
          'name': PlutoCell(value: s.name),
          'vendorCode': PlutoCell(value: s.vendorCode),
          'contact': PlutoCell(value: s.contact),
          'phone': PlutoCell(value: s.phone),
          'email': PlutoCell(value: s.email),
          'email1': PlutoCell(value: s.email1),
          'address': PlutoCell(
            value: [s.address1, s.address2, s.address3, s.address4]
                .where((addr) => addr.isNotEmpty)
                .join(', '),
          ),
          'state': PlutoCell(value: s.state),
          'stateCode': PlutoCell(value: s.stateCode),
          'pan': PlutoCell(value: s.pan),
          'gstNo': PlutoCell(value: s.gstNo),
          'igst': PlutoCell(value: '${s.igst}%'),
          'cgst': PlutoCell(value: '${s.cgst}%'),
          'sgst': PlutoCell(value: '${s.sgst}%'),
          'totalGst': PlutoCell(value: '${s.totalGst}%'),
          'bank': PlutoCell(value: s.bank),
          'branch': PlutoCell(value: s.branch),
          'account': PlutoCell(value: s.account),
          'ifsc': PlutoCell(value: s.ifsc),
          'paymentTerms': PlutoCell(value: s.paymentTerms),
          'actions': PlutoCell(value: ''),
        },
      );
    }).toList();
  }

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
                    child: PlutoGrid(
                      columns: _getColumns(context, ref),
                      rows: _getRows(suppliers),
                      onLoaded: (PlutoGridOnLoadedEvent event) {
                        event.stateManager.setShowColumnFilter(true);
                      },
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
