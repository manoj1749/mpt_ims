import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mpt_ims/models/supplier.dart';
import 'package:mpt_ims/provider/supplier_provider.dart';
import 'package:mpt_ims/pages/accounts/add_supplier_page.dart';

class SupplierMasterPage extends ConsumerStatefulWidget {
  const SupplierMasterPage({super.key});

  @override
  ConsumerState<SupplierMasterPage> createState() => _SupplierMasterPageState();
}

class _SupplierMasterPageState extends ConsumerState<SupplierMasterPage> {
  Set<int> expandedRows = {};

  // Fixed widths for columns
  final double slNoWidth = 80.0;
  final double nameWidth = 300.0;
  final double codeWidth = 200.0;

  Widget _buildDataCell(String text,
      {bool isHeader = false, required double width}) {
    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        border: Border(
          right: BorderSide(color: Colors.grey[300]!),
          bottom: BorderSide(color: Colors.grey[300]!),
        ),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontWeight: isHeader ? FontWeight.bold : FontWeight.normal,
          fontSize: 14,
        ),
      ),
    );
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

  Widget _buildExcelRow(Supplier supplier, int index) {
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
                _buildExcelCell('${index + 1}', width: 80, center: true),
                _buildExcelCell(supplier.name, width: 300),
                _buildExcelCell(
                    supplier.vendorCode.isNotEmpty ? supplier.vendorCode : '--',
                    width: 180),
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
                      supplier.address1,
                      supplier.address2,
                      supplier.address3,
                      supplier.address4
                    ].where((e) => e.isNotEmpty).join(', ')),
                _buildExcelRowLabel("State", supplier.state),
                _buildExcelRowLabel("State Code", supplier.stateCode),
                _buildExcelRowLabel("PAN", supplier.pan),
                _buildExcelRowLabel("GST No", supplier.gstNo),
                _buildExcelRowLabel("IGST %", '${supplier.igst}'),
                _buildExcelRowLabel("CGST %", '${supplier.cgst}'),
                _buildExcelRowLabel("SGST %", '${supplier.sgst}'),
                _buildExcelRowLabel("Total GST", '${supplier.totalGst}'),
                _buildExcelRowLabel("Contact Person", supplier.contact),
                _buildExcelRowLabel("Phone", supplier.phone),
                _buildExcelRowLabel("Email", supplier.email),
                _buildExcelRowLabel("Alt Email", supplier.email1),
                _buildExcelRowLabel("Bank", supplier.bank),
                _buildExcelRowLabel("Branch", supplier.branch),
                _buildExcelRowLabel("Account No", supplier.account),
                _buildExcelRowLabel("IFSC Code", supplier.ifsc),
                _buildExcelRowLabel("Payment Terms", supplier.paymentTerms),

                const SizedBox(height: 12),

                // ✅ Edit & Delete buttons
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
                            builder: (_) => AddSupplierPage(
                              supplierToEdit: supplier,
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
                      onPressed: () => _confirmDeleteSupplier(supplier),
                    ),
                  ],
                ),
              ],
            ),
          ),
      ],
    );
  }

  void _confirmDeleteSupplier(Supplier supplier) {
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
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final suppliers = ref.watch(supplierListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Supplier Master'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AddSupplierPage()),
            ),
            tooltip: 'Add Supplier',
          ),
        ],
      ),
      body: suppliers.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'No suppliers yet',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(
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
          : Column(
              children: [
                Container(
                  color: Colors.black,
                  child: Row(
                    children: [
                      _buildDataCell('Sl No', isHeader: true, width: slNoWidth),
                      _buildDataCell('Supplier Name',
                          isHeader: true, width: nameWidth),
                      _buildDataCell('Supplier Code',
                          isHeader: true, width: codeWidth),
                      const SizedBox(width: 36),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: suppliers.length,
                    itemBuilder: (context, index) => _buildExcelRow(
                      suppliers[index],
                      index,
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
