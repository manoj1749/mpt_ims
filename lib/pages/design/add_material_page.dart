import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:mpt_ims/models/material_item.dart';
import 'package:mpt_ims/models/supplier.dart';
import 'package:mpt_ims/pages/accounts/add_supplier_page.dart';
import 'package:mpt_ims/provider/material_provider.dart';
import 'package:mpt_ims/provider/supplier_provider.dart';

class AddMaterialPage extends ConsumerStatefulWidget {
  final MaterialItem? materialToEdit;
  final int? index;

  const AddMaterialPage({super.key, this.materialToEdit, this.index});

  @override
  ConsumerState<AddMaterialPage> createState() => _AddMaterialPageState();
}

class _AddMaterialPageState extends ConsumerState<AddMaterialPage> {
  final _formKey = GlobalKey<FormState>();
  late MaterialItem item;
  String? selectedSupplier;

  @override
  void initState() {
    super.initState();
    item = widget.materialToEdit ??
        MaterialItem(
          slNo: '',
          vendorName: '',
          description: '',
          partNo: '',
          unit: '',
          supplierRate: '',
          seiplRate: '',
          category: '',
          subCategory: '',
          saleRate: '',
          totalReceivedQty: '',
          vendorIssuedQty: '',
          vendorReceivedQty: '',
          boardIssueQty: '',
          avlStock: '',
          avlStockValue: '',
          billingQtyDiff: '',
          totalReceivedCost: '',
          totalBilledCost: '',
          costDiff: '',
        );
    selectedSupplier = item.vendorName;
  }

  void _saveMaterial() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      final notifier = ref.read(materialListProvider.notifier);

      if (widget.index != null) {
        notifier.updateMaterial(widget.index!, item);
      } else {
        item.slNo = (ref.read(materialListProvider).length + 1).toString();
        notifier.addMaterial(item);
      }

      Navigator.pop(context);
    }
  }

  Widget _buildTextField(String label, void Function(String) onSaved,
      {String? initial, TextInputType type = TextInputType.text}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextFormField(
        initialValue: initial,
        decoration: InputDecoration(
            labelText: label, border: const OutlineInputBorder()),
        keyboardType: type,
        validator: (v) => v == null || v.isEmpty ? 'Required' : null,
        onSaved: (v) => onSaved(v ?? ''),
      ),
    );
  }

// Inside your build method
  Widget _buildSupplierDropdown(List<Supplier> suppliers) {
    if (suppliers.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('No vendors found.'),
            ElevatedButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AddSupplierPage()),
              ),
              child: const Text('Add Vendor'),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: DropdownButtonFormField2<String>(
        isExpanded: true,
        value: suppliers.any((s) => s.name == selectedSupplier)
            ? selectedSupplier
            : null,
        decoration: const InputDecoration(
          labelText: 'Vendor Name',
          border: OutlineInputBorder(),
          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 0),
        ),
        items: suppliers
            .map((s) => DropdownMenuItem(
                  value: s.name,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Text(
                      s.name,
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                ))
            .toList(),
        onChanged: (value) => setState(() => selectedSupplier = value),
        validator: (value) =>
            value == null || value.isEmpty ? 'Required' : null,
        onSaved: (value) => item.vendorName = value ?? '',
        buttonStyleData: const ButtonStyleData(
          height: 52,
          padding: EdgeInsets.zero,
        ),
        dropdownStyleData: DropdownStyleData(
          maxHeight: 250,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: Colors.grey[900], // Adjust based on your theme
          ),
          padding: const EdgeInsets.symmetric(vertical: 6),
          offset: const Offset(0, -2), // Ensures dropdown opens just below
        ),
        menuItemStyleData: const MenuItemStyleData(
          height: 44,
          padding: EdgeInsets.symmetric(horizontal: 14),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final suppliers = ref.watch(supplierListProvider);

    return Scaffold(
      appBar: AppBar(
          title: Text(widget.materialToEdit == null
              ? 'Add Material'
              : 'Edit Material')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              children: [
                _buildSupplierDropdown(suppliers),
                _buildTextField('Description', (v) => item.description = v,
                    initial: item.description),
                _buildTextField('Part No', (v) => item.partNo = v,
                    initial: item.partNo),
                _buildTextField('Unit', (v) => item.unit = v,
                    initial: item.unit),
                _buildTextField('Supplier Rate', (v) => item.supplierRate = v,
                    initial: item.supplierRate),
                _buildTextField('SEIPL Rate', (v) => item.seiplRate = v,
                    initial: item.seiplRate),
                _buildTextField('Category', (v) => item.category = v,
                    initial: item.category),
                _buildTextField('Sub Category', (v) => item.subCategory = v,
                    initial: item.subCategory),
                _buildTextField('Sale Rate', (v) => item.saleRate = v,
                    initial: item.saleRate),
                _buildTextField(
                    'Total Received Qty', (v) => item.totalReceivedQty = v,
                    initial: item.totalReceivedQty),
                _buildTextField(
                    'Vendor Issued Qty', (v) => item.vendorIssuedQty = v,
                    initial: item.vendorIssuedQty),
                _buildTextField(
                    'Vendor Received Qty', (v) => item.vendorReceivedQty = v,
                    initial: item.vendorReceivedQty),
                _buildTextField(
                    'Board Issue Qty', (v) => item.boardIssueQty = v,
                    initial: item.boardIssueQty),
                _buildTextField('AVL Stock', (v) => item.avlStock = v,
                    initial: item.avlStock),
                _buildTextField(
                    'AVL Stock Value', (v) => item.avlStockValue = v,
                    initial: item.avlStockValue),
                _buildTextField(
                    'Billing Qty Diff', (v) => item.billingQtyDiff = v,
                    initial: item.billingQtyDiff),
                _buildTextField(
                    'Total Received Cost', (v) => item.totalReceivedCost = v,
                    initial: item.totalReceivedCost),
                _buildTextField(
                    'Total Billed Cost', (v) => item.totalBilledCost = v,
                    initial: item.totalBilledCost),
                _buildTextField('Cost Diff', (v) => item.costDiff = v,
                    initial: item.costDiff),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _saveMaterial,
                  child: Text(widget.materialToEdit == null
                      ? 'Save Material'
                      : 'Update Material'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
