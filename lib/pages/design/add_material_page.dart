import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:mpt_ims/models/material_item.dart';
import 'package:mpt_ims/models/supplier.dart';
import 'package:mpt_ims/models/vendor_material_rate.dart';
import 'package:mpt_ims/provider/material_provider.dart';
import 'package:mpt_ims/provider/vendor_material_rate_provider.dart';
import 'package:mpt_ims/provider/category_provider.dart';
import 'package:mpt_ims/provider/sub_category_provider.dart';
import 'package:mpt_ims/models/category.dart';
import 'package:mpt_ims/models/sub_category.dart';
import 'package:mpt_ims/pages/design/select_vendors_dialog.dart';

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

  // Track selected vendors
  List<String> selectedVendors = [];

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
    _controllers['storageLocation'] =
        TextEditingController(text: item.storageLocation);
    _controllers['rackNumber'] = TextEditingController(text: item.rackNumber);
    _controllers['actualWeight'] = TextEditingController(text: item.actualWeight);
    _inspectionStockController = TextEditingController(text: '0');

    // Set initial category and subcategory if editing
    if (widget.materialToEdit != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final categories = ref.read(categoryListProvider);
        final subCategories = ref.read(subCategoryListProvider);

        // Get existing vendor rates
        final rates = ref
            .read(vendorMaterialRateProvider.notifier)
            .getRatesForMaterial(item.slNo);
        selectedVendors = rates.map((r) => r.vendorId).toList();

        setState(() {
          _selectedCategory = categories.firstWhere(
            (c) => c.name == item.category,
            orElse: () => Category(name: ''),
          );

          if (_selectedCategory != null && _selectedCategory!.name.isNotEmpty) {
            _selectedSubCategory = subCategories.firstWhere(
              (sc) =>
                  sc.name == item.subCategory &&
                  sc.categoryName == item.category,
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
      // Check if all selected vendors have rates
      final rates = ref
          .read(vendorMaterialRateProvider.notifier)
          .getRatesForMaterial(item.slNo);

      final vendorsWithoutRates = selectedVendors
          .where((vendor) => !rates.any((r) => r.vendorId == vendor))
          .toList();

      if (vendorsWithoutRates.isNotEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Please provide sale rates for: ${vendorsWithoutRates.join(", ")}',
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      try {
        final notifier = ref.read(materialListProvider.notifier);

        // Update item with current values
        item.slNo = _controllers['slNo']!.text;
        item.description = _controllers['description']!.text;
        item.partNo = _controllers['partNo']!.text;
        item.unit = _controllers['unit']!.text;
        item.storageLocation = _controllers['storageLocation']!.text;
        item.rackNumber = _controllers['rackNumber']!.text;
        item.actualWeight = _controllers['actualWeight']!.text;
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
      {TextInputType type = TextInputType.text,
      String? hint,
      FormFieldValidator<String>? validator}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextFormField(
        controller: _controllers[field],
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          hintText: hint,
        ),
        keyboardType: type,
        validator: validator,
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
            _selectedSubCategory =
                null; // Reset subcategory when category changes
          });
        },
        validator: (value) =>
            value == null || value.name.isEmpty ? 'Required' : null,
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
        onChanged: _selectedCategory == null
            ? null
            : (SubCategory? newValue) {
                setState(() {
                  _selectedSubCategory = newValue;
                });
              },
        validator: (value) =>
            value == null || value.name.isEmpty ? 'Required' : null,
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

    if (result == true && _saleRateController.text.isNotEmpty) {
      final receivedQty = double.tryParse(_receivedQtyController.text) ?? 0;
      final saleRate = double.tryParse(_saleRateController.text) ?? 0;

      final newRate = VendorMaterialRate(
        materialId: item.slNo,
        vendorId: vendor.name,
        saleRate: _saleRateController.text,
        lastPurchaseDate: DateFormat('yyyy-MM-dd').format(DateTime.now()),
        remarks: _remarksController.text,
        totalReceivedQty: _receivedQtyController.text,
        issuedQty: _issuedQtyController.text,
        receivedQty: _receivedQtyController.text,
        avlStock: _stockController.text,
        avlStockValue:
            (double.tryParse(_stockController.text) ?? 0 * saleRate).toString(),
        billingQtyDiff: '0',
        totalReceivedCost: (receivedQty * saleRate).toString(),
        totalBilledCost: (receivedQty * saleRate).toString(),
        costDiff: '0',
        inspectionStock: _inspectionStockController.text,
        isPreferred: false,
      );

      if (existingRate != null) {
        ref.read(vendorMaterialRateProvider.notifier).updateRate(newRate);
      } else {
        ref.read(vendorMaterialRateProvider.notifier).addRate(newRate);
      }
      setState(() {}); // Refresh the UI
    }
  }

  Widget _buildVendorRatesSection() {
    final rates = ref
        .read(vendorMaterialRateProvider.notifier)
        .getRatesForMaterial(item.slNo);

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
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: () async {
                    final result = await showDialog<List<String>>(
                      context: context,
                      builder: (context) => SelectVendorsDialog(
                        selectedVendors: selectedVendors,
                      ),
                    );

                    if (result != null) {
                      setState(() {
                        selectedVendors = result;
                      });
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (selectedVendors.isEmpty)
              const Center(
                child: Text('No vendors selected'),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const ClampingScrollPhysics(),
                itemCount: selectedVendors.length,
                itemBuilder: (context, index) {
                  final vendorName = selectedVendors[index];
                  final rate = rates.firstWhere(
                    (r) => r.vendorId == vendorName,
                    orElse: () => VendorMaterialRate(
                      materialId: item.slNo,
                      vendorId: vendorName,
                      saleRate: '',
                      lastPurchaseDate:
                          DateFormat('yyyy-MM-dd').format(DateTime.now()),
                      remarks: '',
                      totalReceivedQty: '0',
                      issuedQty: '0',
                      receivedQty: '0',
                      avlStock: '0',
                      avlStockValue: '0',
                      billingQtyDiff: '0',
                      totalReceivedCost: '0',
                      totalBilledCost: '0',
                      costDiff: '0',
                      isPreferred: false,
                    ),
                  );

                  return Card(
                    child: ListTile(
                      leading: IconButton(
                        icon: Icon(
                          rate.isPreferred ? Icons.star : Icons.star_border,
                          color: rate.isPreferred ? Colors.amber : null,
                        ),
                        onPressed: () {
                          // Update preferred vendor
                          final rateProvider =
                              ref.read(vendorMaterialRateProvider.notifier);

                          // First, remove preferred status from all vendors for this material
                          for (final r in rates) {
                            if (r.isPreferred) {
                              rateProvider
                                  .updateRate(r.copyWith(isPreferred: false));
                            }
                          }

                          // Then set the new preferred vendor
                          rateProvider.updateRate(
                              rate.copyWith(isPreferred: !rate.isPreferred));
                          setState(() {}); // Refresh UI
                        },
                        tooltip: 'Set as preferred vendor',
                      ),
                      title: Text(vendorName),
                      subtitle: rate.saleRate.isNotEmpty
                          ? Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
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
                            onPressed: () => _addVendorRate(
                              Supplier(
                                name: vendorName,
                                igst: '',
                                cgst: '',
                                sgst: '',
                                contact: '',
                                phone: '',
                                email: '',
                                vendorCode: '',
                                address1: '',
                                address2: '',
                                address3: '',
                                address4: '',
                                state: '',
                                stateCode: '',
                                paymentTerms: '',
                                pan: '',
                                gstNo: '',
                                totalGst: '',
                                bank: '',
                                branch: '',
                                account: '',
                                ifsc: '',
                                email1: '',
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete),
                            onPressed: () {
                              setState(() {
                                selectedVendors.remove(vendorName);
                                ref
                                    .read(vendorMaterialRateProvider.notifier)
                                    .deleteRate(item.slNo, vendorName);
                              });
                            },
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
                    _buildTextField(
                      'Actual Weight',
                      'actualWeight',
                      type: const TextInputType.numberWithOptions(decimal: true),
                      hint: 'Enter actual/finished goods weight',
                      validator: (value) {
                        if (value != null && value.isNotEmpty) {
                          if (double.tryParse(value) == null) {
                            return 'Please enter a valid number';
                          }
                          if (double.parse(value) < 0) {
                            return 'Weight cannot be negative';
                          }
                        }
                        return null;
                      },
                    ),
                    _buildTextField('Unit', 'unit'),
                    _buildTextField('Storage Location', 'storageLocation'),
                    _buildTextField('Rack Number', 'rackNumber'),
                    _buildCategoryDropdown(),
                    _buildSubCategoryDropdown(),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: SingleChildScrollView(
                child: _buildVendorRatesSection(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper method to get filtered subcategories
  List<SubCategory> _getFilteredSubCategories() {
    if (_selectedCategory == null) return [];
    return ref
        .read(subCategoryListProvider)
        .where((sc) => sc.categoryName == _selectedCategory!.name)
        .toList();
  }
}
