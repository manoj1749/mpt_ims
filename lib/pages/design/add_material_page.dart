import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:mpt_ims/models/material_item.dart';
import 'package:mpt_ims/models/supplier.dart';
import 'package:mpt_ims/models/vendor_material_rate.dart';
import 'package:mpt_ims/pages/accounts/add_supplier_page.dart';
import 'package:mpt_ims/provider/material_provider.dart';
import 'package:mpt_ims/provider/supplier_provider.dart';
import 'package:mpt_ims/provider/vendor_material_rate_provider.dart';

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
  final _supplierRateController = TextEditingController();
  final _seiplRateController = TextEditingController();
  final _saleRateController = TextEditingController();
  final _remarksController = TextEditingController();
  final _receivedQtyController = TextEditingController();
  final _issuedQtyController = TextEditingController();
  final _stockController = TextEditingController();

  // Add controllers for all text fields
  final Map<String, TextEditingController> _controllers = {};

  @override
  void initState() {
    super.initState();
    item = widget.materialToEdit?.copy() ?? // Create a copy if editing
        MaterialItem(
          slNo: '',
          description: '',
          partNo: '',
          unit: '',
          category: '',
          subCategory: '',
        );

    // Initialize controllers with current values
    _controllers['slNo'] = TextEditingController(text: item.slNo);
    _controllers['description'] = TextEditingController(text: item.description);
    _controllers['partNo'] = TextEditingController(text: item.partNo);
    _controllers['unit'] = TextEditingController(text: item.unit);
    _controllers['category'] = TextEditingController(text: item.category);
    _controllers['subCategory'] = TextEditingController(text: item.subCategory);
  }

  @override
  void dispose() {
    _supplierRateController.dispose();
    _seiplRateController.dispose();
    _saleRateController.dispose();
    _remarksController.dispose();
    _receivedQtyController.dispose();
    _issuedQtyController.dispose();
    _stockController.dispose();
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
      item.category = _controllers['category']!.text;
      item.subCategory = _controllers['subCategory']!.text;

      if (widget.index != null) {
        // Update existing material
        notifier.updateMaterial(widget.index!, item);
      } else {
        // Create new material with a new slNo
        final newSlNo = (ref.read(materialListProvider).length + 1).toString();
        item.slNo = newSlNo;
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
        validator: (value) =>
            value == null || value.isEmpty ? 'Required' : null,
      ),
    );
  }

  Future<void> _addVendorRate(Supplier vendor) async {
    // Only get rates if editing an existing material
    final rates = widget.materialToEdit != null
        ? ref
            .read(vendorMaterialRateProvider.notifier)
            .getRatesForMaterial(item.slNo)
        : [];
    final existingRate =
        rates.where((r) => r.vendorId == vendor.name).firstOrNull;

    // Reset all controllers for new rate
    _supplierRateController.text = existingRate?.supplierRate ?? '';
    _seiplRateController.text = existingRate?.seiplRate ?? '';
    _saleRateController.text = existingRate?.saleRate ?? '';
    _receivedQtyController.text = existingRate?.totalReceivedQty ?? '0';
    _issuedQtyController.text = existingRate?.issuedQty ?? '0';
    _stockController.text = existingRate?.avlStock ?? '0';
    _remarksController.text = existingRate?.remarks ?? '';

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
            '${existingRate != null ? 'Edit' : 'Add'} Rate for ${vendor.name}'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _supplierRateController,
                decoration: const InputDecoration(
                  labelText: 'Supplier Rate *',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _seiplRateController,
                decoration: const InputDecoration(
                  labelText: 'SEIPL Rate *',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _saleRateController,
                decoration: const InputDecoration(
                  labelText: 'Sale Rate *',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _receivedQtyController,
                decoration: const InputDecoration(
                  labelText: 'Received Quantity',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _issuedQtyController,
                decoration: const InputDecoration(
                  labelText: 'Issued Quantity',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _stockController,
                decoration: const InputDecoration(
                  labelText: 'Available Stock',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
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

    if (result == true && _supplierRateController.text.isNotEmpty) {
      final receivedQty = double.tryParse(_receivedQtyController.text) ?? 0;
      final supplierRate = double.tryParse(_supplierRateController.text) ?? 0;
      final seiplRate = double.tryParse(_seiplRateController.text) ?? 0;

      final newRate = VendorMaterialRate(
        materialId: item.slNo,
        vendorId: vendor.name,
        supplierRate: _supplierRateController.text,
        seiplRate: _seiplRateController.text,
        saleRate: _saleRateController.text,
        lastPurchaseDate: DateFormat('yyyy-MM-dd').format(DateTime.now()),
        remarks: _remarksController.text,
        totalReceivedQty: _receivedQtyController.text,
        issuedQty: _issuedQtyController.text,
        receivedQty: _receivedQtyController.text,
        avlStock: _stockController.text,
        avlStockValue: (double.tryParse(_stockController.text) ?? 0 * seiplRate)
            .toString(),
        billingQtyDiff: '0',
        totalReceivedCost: (receivedQty * supplierRate).toString(),
        totalBilledCost: (receivedQty * seiplRate).toString(),
        costDiff: ((receivedQty * seiplRate) - (receivedQty * supplierRate))
            .toString(),
      );

      if (existingRate != null) {
        ref.read(vendorMaterialRateProvider.notifier).updateRate(newRate);
      } else {
        ref.read(vendorMaterialRateProvider.notifier).addRate(newRate);
      }
      setState(() {}); // Refresh the UI
    }
  }

  void _removeVendorRate(String vendorName) {
    ref
        .read(vendorMaterialRateProvider.notifier)
        .deleteRate(item.slNo, vendorName);
    setState(() {}); // Refresh the UI
  }

  Widget _buildVendorRatesSection(List<Supplier> vendors) {
    // Only show rates if we have a valid material ID (editing an existing material)
    final rates = widget.materialToEdit != null
        ? ref
            .read(vendorMaterialRateProvider.notifier)
            .getRatesForMaterial(item.slNo)
        : [];
    final preferredVendorName =
        widget.materialToEdit != null ? item.getPreferredVendorName(ref) : '';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.materialToEdit != null
                      ? 'Vendor Rates'
                      : 'Save material first to add vendor rates',
                  style: const TextStyle(
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
            else if (widget.materialToEdit == null)
              const Center(
                child: Text('Save the material first to add vendor rates'),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                itemCount: vendors.length,
                itemBuilder: (context, index) {
                  final vendor = vendors[index];
                  final rate =
                      rates.where((r) => r.vendorId == vendor.name).firstOrNull;
                  final isPreferred = vendor.name == preferredVendorName;

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
                                Text('Supplier Rate: ₹${rate.supplierRate}'),
                                Text('SEIPL Rate: ₹${rate.seiplRate}'),
                                Text('Sale Rate: ₹${rate.saleRate}'),
                                Text('Stock: ${rate.avlStock} ${item.unit}'),
                                Text(
                                    'Stock Value: ₹${rate.stockValue.toStringAsFixed(2)}'),
                                Text('Last Purchase: ${rate.lastPurchaseDate}'),
                                if (rate.remarks.isNotEmpty)
                                  Text('Remarks: ${rate.remarks}'),
                              ],
                            )
                          : const Text('No rate added'),
                      trailing: widget.materialToEdit != null
                          ? (rate != null
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
                                ))
                          : null,
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
                    _buildTextField('Category', 'category'),
                    _buildTextField('Sub Category', 'subCategory'),
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
