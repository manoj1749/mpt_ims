import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/customer.dart';
import '../../provider/customer_provider.dart';
import 'add_customer_page.dart';

class CustomerListPage extends ConsumerWidget {
  const CustomerListPage({super.key});

  void _confirmDelete(BuildContext context, WidgetRef ref, Customer customer) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Customer'),
        content: Text('Are you sure you want to delete ${customer.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton.tonal(
            onPressed: () {
              ref.read(customerListProvider.notifier).deleteCustomer(customer);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Customer deleted')),
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
    final customers = ref.watch(customerListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Customer Master'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              // TODO: Implement search
            },
            tooltip: 'Search Customers',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AddCustomerPage()),
        ),
        child: const Icon(Icons.add),
      ),
      body: customers.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.people_outline,
                    size: 64,
                    color: Colors.grey[300],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No customers yet',
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
                          builder: (_) => const AddCustomerPage()),
                    ),
                    child: const Text('Add New Customer'),
                  ),
                ],
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Card(
                  elevation: 0,
                  margin: EdgeInsets.zero,
                  child: SizedBox(
                    width: MediaQuery.of(context).size.width - 32,
                    child: PaginatedDataTable(
                      source: _CustomerDataSource(
                        customers: customers,
                        context: context,
                        ref: ref,
                        onDelete: (customer) =>
                            _confirmDelete(context, ref, customer),
                      ),
                      header: null,
                      rowsPerPage: customers.length,
                      showFirstLastButtons: true,
                      showCheckboxColumn: false,
                      horizontalMargin: 16,
                      columnSpacing: 20,
                      columns: const [
                        DataColumn(label: Text('Name')),
                        DataColumn(label: Text('Customer Code')),
                        DataColumn(label: Text('Contact')),
                        DataColumn(label: Text('Phone')),
                        DataColumn(label: Text('Email')),
                        DataColumn(label: Text('Alt. Email')),
                        DataColumn(label: Text('Address')),
                        DataColumn(label: Text('State')),
                        DataColumn(label: Text('State Code')),
                        DataColumn(label: Text('PAN')),
                        DataColumn(label: Text('GST No.')),
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
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

class _CustomerDataSource extends DataTableSource {
  final List<Customer> customers;
  final BuildContext context;
  final WidgetRef ref;
  final Function(Customer) onDelete;

  _CustomerDataSource({
    required this.customers,
    required this.context,
    required this.ref,
    required this.onDelete,
  });

  @override
  DataRow? getRow(int index) {
    if (index >= customers.length) return null;
    final customer = customers[index];

    return DataRow(
      cells: [
        DataCell(
          Text(
            customer.name,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
        ),
        DataCell(
          Text(
            customer.customerCode,
            style: TextStyle(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        DataCell(Text(customer.contact)),
        DataCell(Text(customer.phone)),
        DataCell(Text(customer.email)),
        DataCell(Text(customer.email1)),
        DataCell(
          Text(
            [
              customer.address1,
              customer.address2,
              customer.address3,
              customer.address4
            ].where((addr) => addr.isNotEmpty).join(', '),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        DataCell(Text(customer.state)),
        DataCell(Text(customer.stateCode)),
        DataCell(Text(customer.pan)),
        DataCell(Text(customer.gstNo)),
        DataCell(Text('${customer.igst}%')),
        DataCell(Text('${customer.cgst}%')),
        DataCell(Text('${customer.sgst}%')),
        DataCell(
          Text(
            '${customer.totalGst}%',
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
        ),
        DataCell(Text(customer.bank)),
        DataCell(Text(customer.branch)),
        DataCell(Text(customer.account)),
        DataCell(Text(customer.ifsc)),
        DataCell(Text(customer.paymentTerms)),
        DataCell(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.edit_outlined),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AddCustomerPage(
                        customerToEdit: customer,
                        index: index,
                      ),
                    ),
                  );
                },
                tooltip: 'Edit Customer',
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline),
                onPressed: () => onDelete(customer),
                tooltip: 'Delete Customer',
                color: Colors.red,
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
  int get rowCount => customers.length;

  @override
  int get selectedRowCount => 0;
}
