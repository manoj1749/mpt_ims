import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:mpt_ims/models/material_item.dart';
import 'package:mpt_ims/models/supplier.dart';
import 'package:mpt_ims/pages/accounts/add_supplier_page.dart';
import 'package:mpt_ims/provider/material_provider.dart';
import 'package:mpt_ims/provider/supplier_provider.dart';

class AddMaterialPage extends ConsumerStatefulWidget {
  final MaterialItem? materialToEdit;
  final int? index;

  const AddMaterialPage({
    super.key,
    this.materialToEdit,
    this.index,
  });

  @override
  ConsumerState<AddMaterialPage> createState() => _AddMaterialPageState();
}

class _AddMaterialPageState extends ConsumerState<AddMaterialPage> {
  final _formKey = GlobalKey<FormState>();
  late MaterialItem item;
  final _rateController = TextEditingController();
  final _remarksController = TextEditingController();

  // Add controllers for all text fields
  final Map<String, TextEditingController> _controllers = {};

  @override
  void initState() {
    super.initState();
    item = widget.materialToEdit?.copy() ??  // Create a copy if editing
        MaterialItem(
          slNo: '',
          description: '',
          partNo: '',
          unit: '',
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
          vendorRates: {},
        );

    // Initialize controllers with current values
    _controllers['slNo'] = TextEditingController(text: item.slNo);
    _controllers['description'] = TextEditingController(text: item.description);
    _controllers['partNo'] = TextEditingController(text: item.partNo);
    _controllers['unit'] = TextEditingController(text: item.unit);
    _controllers['seiplRate'] = TextEditingController(text: item.seiplRate);
    _controllers['category'] = TextEditingController(text: item.category);
    _controllers['subCategory'] = TextEditingController(text: item.subCategory);
    _controllers['saleRate'] = TextEditingController(text: item.saleRate);
    _controllers['totalReceivedQty'] = TextEditingController(text: item.totalReceivedQty);
    _controllers['vendorIssuedQty'] = TextEditingController(text: item.vendorIssuedQty);
    _controllers['vendorReceivedQty'] = TextEditingController(text: item.vendorReceivedQty);
    _controllers['boardIssueQty'] = TextEditingController(text: item.boardIssueQty);
    _controllers['avlStock'] = TextEditingController(text: item.avlStock);
    _controllers['avlStockValue'] = TextEditingController(text: item.avlStockValue);
    _controllers['billingQtyDiff'] = TextEditingController(text: item.billingQtyDiff);
    _controllers['totalReceivedCost'] = TextEditingController(text: item.totalReceivedCost);
    _controllers['totalBilledCost'] = TextEditingController(text: item.totalBilledCost);
    _controllers['costDiff'] = TextEditingController(text: item.costDiff);
  }

  @override
  void dispose() {
    _rateController.dispose();
    _remarksController.dispose();
    // Dispose all controllers
    for (var controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _saveMaterial() {
    if (_formKey.currentState!.validate()) {
      final notifier = ref.read(materialListProvider.notifier);

      // Update item with current values
      item.slNo = _controllers['slNo']!.text;
      item.description = _controllers['description']!.text;
      item.partNo = _controllers['partNo']!.text;
      item.unit = _controllers['unit']!.text;
      item.seiplRate = _controllers['seiplRate']!.text;
      item.category = _controllers['category']!.text;
      item.subCategory = _controllers['subCategory']!.text;
      item.saleRate = _controllers['saleRate']!.text;
      item.totalReceivedQty = _controllers['totalReceivedQty']!.text;
      item.vendorIssuedQty = _controllers['vendorIssuedQty']!.text;
      item.vendorReceivedQty = _controllers['vendorReceivedQty']!.text;
      item.boardIssueQty = _controllers['boardIssueQty']!.text;
      item.avlStock = _controllers['avlStock']!.text;
      item.avlStockValue = _controllers['avlStockValue']!.text;
      item.billingQtyDiff = _controllers['billingQtyDiff']!.text;
      item.totalReceivedCost = _controllers['totalReceivedCost']!.text;
      item.totalBilledCost = _controllers['totalBilledCost']!.text;
      item.costDiff = _controllers['costDiff']!.text;

      if (widget.index != null) {
        notifier.updateMaterial(widget.index!, item);
      } else {
        item.slNo = (ref.read(materialListProvider).length + 1).toString();
        notifier.addMaterial(item);
      }

      Navigator.pop(context);
    }
  }

  Widget _buildTextField(String label, String field,
      {TextInputType type = TextInputType.text}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextFormField(
        controller: _controllers[field],
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        keyboardType: type,
        validator: (value) => value == null || value.isEmpty ? 'Required' : null,
      ),
    );
  }

  Future<void> _addVendorRate(Supplier vendor) async {
    // If editing existing rate, populate the fields
    if (item.vendorRates.containsKey(vendor.name)) {
      final rate = item.vendorRates[vendor.name]!;
      _rateController.text = rate.rate;
      _remarksController.text = rate.remarks;
    } else {
      _rateController.text = '';
      _remarksController.text = '';
    }

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${item.vendorRates.containsKey(vendor.name) ? 'Edit' : 'Add'} Rate for ${vendor.name}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _rateController,
              decoration: const InputDecoration(
                labelText: 'Rate *',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              validator: (v) => v == null || v.isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _remarksController,
              decoration: const InputDecoration(
                labelText: 'Remarks',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (result == true && _rateController.text.isNotEmpty) {
      setState(() {
        item.vendorRates[vendor.name] = VendorRate(
          rate: _rateController.text,
          lastPurchaseDate: DateFormat('yyyy-MM-dd').format(DateTime.now()),
          remarks: _remarksController.text,
        );
      });
    }
  }

  void _removeVendorRate(String vendorName) {
    setState(() {
      item.vendorRates.remove(vendorName);
    });
  }

  Widget _buildVendorRatesSection(List<Supplier> vendors) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Vendor Rates',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (vendors.isEmpty)
                  TextButton.icon(
                    icon: const Icon(Icons.add),
                    label: const Text('Add Vendor'),
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const AddSupplierPage(),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            if (vendors.isEmpty)
              const Center(
                child: Text('No vendors available'),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                itemCount: vendors.length,
                itemBuilder: (context, index) {
                  final vendor = vendors[index];
                  final rate = item.vendorRates[vendor.name];
                  final isPreferred = vendor.name == item.preferredVendorName;

                  return Card(
                    color: isPreferred ? Colors.green[50] : null,
                    child: ListTile(
                      leading: isPreferred 
                        ? const Icon(Icons.star, color: Colors.amber)
                        : const SizedBox(width: 24),
                      title: Text(vendor.name),
                      subtitle: rate != null
                          ? Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Rate: ₹${rate.rate}'),
                                Text('Last Purchase: ${rate.lastPurchaseDate}'),
                                if (rate.remarks.isNotEmpty)
                                  Text('Remarks: ${rate.remarks}'),
                              ],
                            )
                          : const Text('No rate added'),
                      trailing: rate != null
                          ? Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit),
                                  onPressed: () => _addVendorRate(vendor),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete),
                                  onPressed: () =>
                                      _removeVendorRate(vendor.name),
                                ),
                              ],
                            )
                          : TextButton(
                              onPressed: () => _addVendorRate(vendor),
                              child: const Text('Add Rate'),
                            ),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final vendors = ref.watch(supplierListProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.materialToEdit == null
            ? 'Add New Material'
            : 'Edit Material'),
        actions: [
          TextButton.icon(
            icon: const Icon(Icons.save),
            label: const Text('Save'),
            onPressed: _saveMaterial,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 2,
              child: Form(
                key: _formKey,
                child: ListView(
                  children: [
                    _buildTextField('Sl No', 'slNo'),
                    _buildTextField('Description', 'description'),
                    _buildTextField('Part No', 'partNo'),
                    _buildTextField('Unit', 'unit'),
                    _buildTextField('SEIPL Rate', 'seiplRate', type: TextInputType.number),
                    _buildTextField('Category', 'category'),
                    _buildTextField('Sub Category', 'subCategory'),
                    _buildTextField('Sale Rate', 'saleRate', type: TextInputType.number),
                    _buildTextField('Total Received Qty', 'totalReceivedQty', type: TextInputType.number),
                    _buildTextField('Vendor Issued Qty', 'vendorIssuedQty', type: TextInputType.number),
                    _buildTextField('Vendor Received Qty', 'vendorReceivedQty', type: TextInputType.number),
                    _buildTextField('Board Issue Qty', 'boardIssueQty', type: TextInputType.number),
                    _buildTextField('AVL Stock', 'avlStock', type: TextInputType.number),
                    _buildTextField('AVL Stock Value', 'avlStockValue', type: TextInputType.number),
                    _buildTextField('Billing Qty Diff', 'billingQtyDiff', type: TextInputType.number),
                    _buildTextField('Total Received Cost', 'totalReceivedCost', type: TextInputType.number),
                    _buildTextField('Total Billed Cost', 'totalBilledCost', type: TextInputType.number),
                    _buildTextField('Cost Diff', 'costDiff', type: TextInputType.number),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildVendorRatesSection(vendors),
            ),
          ],
        ),
      ),
    );
  }
}
