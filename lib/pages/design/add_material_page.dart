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
import 'package:mpt_ims/provider/category_provider.dart';
import 'package:mpt_ims/provider/sub_category_provider.dart';
import 'package:mpt_ims/models/category.dart';
import 'package:mpt_ims/models/sub_category.dart';

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
  late TextEditingController _inspectionStockController;

  // Add controllers for all text fields except category and subCategory
  final Map<String, TextEditingController> _controllers = {};

  // Selected category and subcategory
  Category? _selectedCategory;
  SubCategory? _selectedSubCategory;

  @override
  void initState() {
    super.initState();
    item = widget.materialToEdit?.copy() ?? // Create a copy if editing
        MaterialItem(
          slNo: (ref.read(materialListProvider).length + 1)
              .toString(), // Generate new slNo
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
    _inspectionStockController = TextEditingController(text: '0');

    // Set initial category and subcategory if editing
    if (widget.materialToEdit != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final categories = ref.read(categoryListProvider);
        final subCategories = ref.read(subCategoryListProvider);

        setState(() {
          _selectedCategory = categories.firstWhere(
            (c) => c.name == item.category,
            orElse: () => Category(name: ''),
          );

          if (_selectedCategory != null && _selectedCategory!.name.isNotEmpty) {
            _selectedSubCategory = subCategories.firstWhere(
              (sc) => sc.name == item.subCategory && sc.categoryName == item.category,
              orElse: () => SubCategory(name: '', categoryName: ''),
            );
          }
        });
      });
    }
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
    _inspectionStockController.dispose();
    // Dispose all controllers
    for (var controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _saveMaterial() async {
    if (_formKey.currentState!.validate()) {
      try {
        final notifier = ref.read(materialListProvider.notifier);

        // Update item with current values
        item.slNo = _controllers['slNo']!.text;
        item.description = _controllers['description']!.text;
        item.partNo = _controllers['partNo']!.text;
        item.unit = _controllers['unit']!.text;
        item.category = _selectedCategory?.name ?? '';
        item.subCategory = _selectedSubCategory?.name ?? '';

        if (widget.index != null) {
          // Update existing material
          await notifier.updateMaterial(widget.index!, item);
        } else {
          // Create new material with a new slNo
          final newSlNo =
              (ref.read(materialListProvider).length + 1).toString();
          item.slNo = newSlNo;
          await notifier.addMaterial(item);
        }

        // Ensure the material list is refreshed
        ref.invalidate(materialListProvider);

        if (mounted) {
          // Pop back to material master page
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error saving material: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
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

  Widget _buildCategoryDropdown() {
    final categories = ref.watch(categoryListProvider);
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: DropdownButtonFormField<Category>(
        value: _selectedCategory,
        decoration: const InputDecoration(
          labelText: 'Category',
          border: OutlineInputBorder(),
        ),
        items: categories.map((category) {
          return DropdownMenuItem(
            value: category,
            child: Text(category.name),
          );
        }).toList(),
        onChanged: (Category? newValue) {
          setState(() {
            _selectedCategory = newValue;
            _selectedSubCategory = null; // Reset subcategory when category changes
          });
        },
        validator: (value) => value == null || value.name.isEmpty ? 'Required' : null,
      ),
    );
  }

  Widget _buildSubCategoryDropdown() {
    final subCategories = _getFilteredSubCategories();
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: DropdownButtonFormField<SubCategory>(
        value: _selectedSubCategory,
        decoration: const InputDecoration(
          labelText: 'Sub Category',
          border: OutlineInputBorder(),
        ),
        items: subCategories.map((subCategory) {
          return DropdownMenuItem(
            value: subCategory,
            child: Text(subCategory.name),
          );
        }).toList(),
        onChanged: _selectedCategory == null ? null : (SubCategory? newValue) {
          setState(() {
            _selectedSubCategory = newValue;
          });
        },
        validator: (value) => value == null || value.name.isEmpty ? 'Required' : null,
      ),
    );
  }

  Future<void> _addVendorRate(Supplier vendor) async {
    // Get rates if editing an existing material
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
                controller: _inspectionStockController,
                decoration: const InputDecoration(
                  labelText: 'Inspection Stock',
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
        inspectionStock: _inspectionStockController.text,
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
    // Show rates for both new and existing materials
    final rates = ref
        .read(vendorMaterialRateProvider.notifier)
        .getRatesForMaterial(item.slNo);
    final preferredVendorName = item.getPreferredVendorName(ref);

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
                                    'Inspection Stock: ${rate.inspectionStock} ${item.unit}'),
                                Text(
                                    'Stock Value: ₹${rate.stockValue.toStringAsFixed(2)}'),
                                Text('Last Purchase: ${rate.lastPurchaseDate}'),
                                if (rate.remarks.isNotEmpty)
                                  Text('Remarks: ${rate.remarks}'),
                              ],
                            )
                          : const Text('No rate added'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit),
                            onPressed: () => _addVendorRate(vendor),
                          ),
                          if (rate != null)
                            IconButton(
                              icon: const Icon(Icons.delete),
                              onPressed: () => _removeVendorRate(vendor.name),
                            ),
                        ],
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
                    _buildCategoryDropdown(),
                    _buildSubCategoryDropdown(),
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

  // Helper method to get filtered subcategories
  List<SubCategory> _getFilteredSubCategories() {
    if (_selectedCategory == null) return [];
    return ref.read(subCategoryListProvider)
        .where((sc) => sc.categoryName == _selectedCategory!.name)
        .toList();
  }
}
