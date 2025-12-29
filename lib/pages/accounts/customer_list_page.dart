import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/customer.dart';
import '../../provider/customer_provider.dart';
import 'add_customer_page.dart';
import 'package:open_file/open_file.dart';

class CustomerListPage extends ConsumerStatefulWidget {
  const CustomerListPage({super.key});

  @override
  ConsumerState<CustomerListPage> createState() => _CustomerListPageState();
}

class _CustomerListPageState extends ConsumerState<CustomerListPage> {
  Set<int> expandedRows = {};
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  final double slNoWidth = 80.0;
  final double nameWidth = 300.0;
  final double codeWidth = 200.0;

  @override
  void initState() {
    super.initState();
    // Load customers when page is opened
    Future.microtask(() => ref.read(customerListProvider.notifier).loadData());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Widget _buildExcelCell(String text,
      {double width = 150, bool center = false}) {
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
              style: const TextStyle(
                  fontWeight: FontWeight.w500, color: Colors.white),
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
            color: index.isEven
                ? const Color(0xFF121212)
                : const Color(0xFF1E1E1E),
            child: Row(
              children: [
                _buildExcelCell('${index + 1}', width: slNoWidth, center: true),
                _buildExcelCell(customer.name, width: nameWidth),
                _buildExcelCell(
                    customer.customerCode.isNotEmpty
                        ? customer.customerCode
                        : '--',
                    width: codeWidth),
                Container(
                  width: 40,
                  height: 44,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade700),
                  ),
                  child: Icon(
                    isExpanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
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
                _buildExcelRowLabel(
                    "Address",
                    [
                      customer.address1,
                      customer.address2,
                      customer.address3,
                      customer.address4
                    ].where((s) => s.isNotEmpty).join(', ')),
                _buildExcelRowLabel("State", customer.state),
                _buildExcelRowLabel("State Code", customer.stateCode),
                _buildExcelRowLabel("PAN", customer.pan),
                _buildExcelRowLabel("GST No", customer.gstNo),
                _buildExcelRowLabel("IGST %", customer.igst),
                _buildExcelRowLabel("CGST %", customer.cgst),
                _buildExcelRowLabel("SGST %", customer.sgst),
                _buildExcelRowLabel("Total GST", customer.totalGst),
                _buildExcelRowLabel("Contact Person", customer.contact),
                _buildExcelRowLabel("Phone", customer.phone),
                _buildExcelRowLabel("Email", customer.email),
                _buildExcelRowLabel("Alt Email", customer.email1),
                _buildExcelRowLabel("Bank", customer.bank),
                _buildExcelRowLabel("Branch", customer.branch),
                _buildExcelRowLabel("Account No", customer.account),
                _buildExcelRowLabel("IFSC Code", customer.ifsc),
                _buildExcelRowLabel("Payment Terms", customer.paymentTerms),
                if (customer.attachments.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  const Text(
                    'Attachments',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: customer.attachments.map((p) {
                      final name = p.split('\\').isNotEmpty ? p.split('\\').last : p.split('/').last;
                      final ext = name.split('.').length > 1 ? name.split('.').last.toLowerCase() : '';
                      final icon = ext == 'pdf' ? Icons.picture_as_pdf : Icons.description;
                      return InkWell(
                        onTap: () => _showAttachmentViewer(context, p, name),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Row(
                            children: [
                              Icon(icon, size: 16, color: Colors.grey[400]),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  name,
                                  style: const TextStyle(color: Colors.white),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Icon(Icons.open_in_new, size: 14, color: Colors.grey[500]),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton.icon(
                      icon: const Icon(Icons.edit, color: Colors.white),
                      label: const Text("Edit",
                          style: TextStyle(color: Colors.white)),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => AddCustomerPage(
                              customerToEdit: customer,
                              index: ref
                                  .read(customerListProvider)
                                  .indexOf(customer),
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(width: 8),
                    TextButton.icon(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      label: const Text("Delete",
                          style: TextStyle(color: Colors.red)),
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

  void _showAttachmentViewer(BuildContext context, String filePath, String fileName) {
    final ext = fileName.split('.').last.toLowerCase();
    
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          width: MediaQuery.of(context).size.width * 0.8,
          height: MediaQuery.of(context).size.height * 0.8,
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      fileName,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Divider(),
              Expanded(
                child: ext == 'pdf'
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.picture_as_pdf, size: 64, color: Colors.red),
                            const SizedBox(height: 16),
                            Text(
                              'PDF Viewer',
                              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'File: $fileName',
                              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              onPressed: () async {
                                try {
                                  final result = await OpenFile.open(filePath);
                                  if (result.type != ResultType.done && context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('Error: ${result.message}')),
                                    );
                                  }
                                } catch (e) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('Error opening file: $e')),
                                    );
                                  }
                                }
                              },
                              icon: const Icon(Icons.open_in_new),
                              label: const Text('Open with System Viewer'),
                            ),
                          ],
                        ),
                      )
                    : Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.description, size: 64, color: Colors.blue),
                            const SizedBox(height: 16),
                            Text(
                              'Document Viewer',
                              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'File: $fileName',
                              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              onPressed: () async {
                                try {
                                  final result = await OpenFile.open(filePath);
                                  if (result.type != ResultType.done && context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('Error: ${result.message}')),
                                    );
                                  }
                                } catch (e) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('Error opening file: $e')),
                                    );
                                  }
                                }
                              },
                              icon: const Icon(Icons.open_in_new),
                              label: const Text('Open with System Viewer'),
                            ),
                          ],
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
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
              ref.read(customerListProvider.notifier).delete(customer);
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
    final filteredCustomers = _searchQuery.isEmpty
        ? customers
        : ref.read(customerListProvider.notifier).searchCustomers(_searchQuery);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Customer Master'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(customerListProvider.notifier).refresh(),
            tooltip: 'Refresh',
          ),
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
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                labelText: 'Search Customers',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (value) => setState(() => _searchQuery = value),
            ),
          ),
          if (filteredCustomers.isEmpty)
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _searchQuery.isEmpty
                          ? 'No customers yet'
                          : 'No customers found',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.grey[600],
                      ),
                    ),
                    if (_searchQuery.isEmpty) ...[
                      const SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const AddCustomerPage()),
                        ),
                        child: const Text('Add New Customer'),
                      ),
                    ]
                  ],
                ),
              ),
            )
          else
            Expanded(
              child: Column(
                children: [
                  Container(
                    color: Colors.black,
                    child: Row(
                      children: [
                        _buildExcelCell('Sl No',
                            width: slNoWidth, center: true),
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
                      itemCount: filteredCustomers.length,
                      itemBuilder: (context, index) => _buildExpandableRow(
                        filteredCustomers[index],
                        index,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
