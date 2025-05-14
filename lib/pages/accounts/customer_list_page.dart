import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/customer.dart';
import '../../provider/customer_provider.dart';
import 'add_customer_page.dart';

class CustomerListPage extends ConsumerStatefulWidget {
  const CustomerListPage({super.key});

  @override
  ConsumerState<CustomerListPage> createState() => _CustomerListPageState();
}

class _CustomerListPageState extends ConsumerState<CustomerListPage> {
  Set<int> expandedRows = {};

  final double slNoWidth = 80.0;
  final double nameWidth = 300.0;
  final double codeWidth = 200.0;

  Widget _buildExcelCell(String text, {double width = 150, bool center = false}) {
    return Container(
      width: width,
      height: 44,
      alignment: center ? Alignment.center : Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade700, width: 1),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 13,
        ),
      ),
    );
  }

  Widget _buildExcelRowLabel(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 160,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w500, color: Colors.white),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpandableRow(Customer customer, int index) {
    final isExpanded = expandedRows.contains(index);

    return Column(
      children: [
        InkWell(
          onTap: () {
            setState(() {
              if (isExpanded) {
                expandedRows.remove(index);
              } else {
                expandedRows.add(index);
              }
            });
          },
          child: Container(
            color: index.isEven ? const Color(0xFF121212) : const Color(0xFF1E1E1E),
            child: Row(
              children: [
                _buildExcelCell('${index + 1}', width: slNoWidth, center: true),
                _buildExcelCell(customer.name, width: nameWidth),
                _buildExcelCell(customer.customerCode.isNotEmpty ? customer.customerCode : '--', width: codeWidth),
                Container(
                  width: 40,
                  height: 44,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade700),
                  ),
                  child: Icon(
                    isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ],
            ),
          ),
        ),
        if (isExpanded)
          Container(
            color: const Color(0xFF1A1A1A),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildExcelRowLabel("Address", [
                  customer.address1,
                  customer.address2,
                  customer.address3,
                  customer.address4
                ].where((s) => s.isNotEmpty).join(', ')),
                _buildExcelRowLabel("State", customer.state),
                _buildExcelRowLabel("State Code", customer.stateCode),
                _buildExcelRowLabel("PAN", customer.pan),
                _buildExcelRowLabel("GST No", customer.gstNo),
                _buildExcelRowLabel("IGST %", '${customer.igst}'),
                _buildExcelRowLabel("CGST %", '${customer.cgst}'),
                _buildExcelRowLabel("SGST %", '${customer.sgst}'),
                _buildExcelRowLabel("Total GST", '${customer.totalGst}'),
                _buildExcelRowLabel("Contact Person", customer.contact),
                _buildExcelRowLabel("Phone", customer.phone),
                _buildExcelRowLabel("Email", customer.email),
                _buildExcelRowLabel("Alt Email", customer.email1),
                _buildExcelRowLabel("Bank", customer.bank),
                _buildExcelRowLabel("Branch", customer.branch),
                _buildExcelRowLabel("Account No", customer.account),
                _buildExcelRowLabel("IFSC Code", customer.ifsc),
                _buildExcelRowLabel("Payment Terms", customer.paymentTerms),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton.icon(
                      icon: const Icon(Icons.edit, color: Colors.white),
                      label: const Text("Edit", style: TextStyle(color: Colors.white)),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => AddCustomerPage(
                              customerToEdit: customer,
                              index: ref.read(customerListProvider).indexOf(customer),
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(width: 8),
                    TextButton.icon(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      label: const Text("Delete", style: TextStyle(color: Colors.red)),
                      onPressed: () => _confirmDelete(context, customer),
                    ),
                  ],
                ),
              ],
            ),
          ),
      ],
    );
  }

  void _confirmDelete(BuildContext context, Customer customer) {
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
          TextButton(
            onPressed: () {
              ref.read(customerListProvider.notifier).deleteCustomer(customer);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Customer deleted')),
              );
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final customers = ref.watch(customerListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Customer Master'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AddCustomerPage()),
            ),
            tooltip: 'Add Customer',
          ),
        ],
      ),
      body: customers.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'No customers yet',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const AddCustomerPage()),
                    ),
                    child: const Text('Add New Customer'),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                Container(
                  color: Colors.black,
                  child: Row(
                    children: [
                      _buildExcelCell('Sl No', width: slNoWidth, center: true),
                      _buildExcelCell('Customer Name', width: nameWidth),
                      _buildExcelCell('Customer Code', width: codeWidth),
                      Container(
                        width: 40,
                        height: 44,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade700),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: customers.length,
                    itemBuilder: (context, index) => _buildExpandableRow(
                      customers[index],
                      index,
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
