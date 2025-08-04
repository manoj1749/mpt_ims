import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:mpt_ims/models/material_item.dart';
import 'package:mpt_ims/models/supplier.dart';
import 'package:mpt_ims/models/vendor_material_rate.dart';
import 'package:mpt_ims/provider/material_provider.dart';

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
  final _baseRateController = TextEditingController();
  final _saleRateController = TextEditingController();
  final _discountController = TextEditingController();
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

  // Helper methods for discount calculations
  void _calculateDiscountFromRates() {
    final baseRate = double.tryParse(_baseRateController.text);
    final purchaseRate = double.tryParse(_saleRateController.text);
    
    if (baseRate != null && purchaseRate != null && baseRate > 0) {
      final discount = ((baseRate - purchaseRate) / baseRate) * 100;
      _discountController.text = discount.toStringAsFixed(2);
    }
  }

  void _calculatePurchaseRateFromDiscount() {
    final baseRate = double.tryParse(_baseRateController.text);
    final discount = double.tryParse(_discountController.text);
    
    if (baseRate != null && discount != null && baseRate > 0) {
      final purchaseRate = baseRate - (baseRate * discount / 100);
      _saleRateController.text = purchaseRate.toStringAsFixed(2);
    }
  }

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
    _controllers['actualWeight'] =
        TextEditingController(text: item.actualWeight);
    _controllers['saleRate'] = TextEditingController(text: item.saleRate);
    _inspectionStockController = TextEditingController(text: '0');

    // Set initial category and subcategory if editing
    if (widget.materialToEdit != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final categories = ref.read(categoryListProvider);
        final subCategories = ref.read(subCategoryListProvider);

        // Get existing vendor rates from the material
        selectedVendors = item.vendorRates.map((r) => r.vendorId).toList();

        setState(() {
          // Find the actual category object from the list, or null if not found
          _selectedCategory = categories.cast<Category?>().firstWhere(
            (c) => c?.name == item.category,
            orElse: () => null,
          );

          if (_selectedCategory != null && _selectedCategory!.name.isNotEmpty) {
            // Find the actual subcategory object from the list, or null if not found
            _selectedSubCategory = subCategories.cast<SubCategory?>().firstWhere(
              (sc) =>
                  sc?.name == item.subCategory &&
                  sc?.categoryName == item.category,
              orElse: () => null,
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
    _discountController.dispose();
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
      final rates = item.vendorRates;

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
        item.saleRate = _controllers['saleRate']?.text ?? '';

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
    // Get existing rate from material's vendor rates
    final existingRate = item.getRateForVendor(vendor.name);

    // Reset all controllers for new rate
    _baseRateController.text = existingRate?.baseRate ?? '';
    _saleRateController.text = existingRate?.purchaseRate ?? '';
    _discountController.text = '';
    _remarksController.text = existingRate?.remarks ?? '';

    // Calculate initial discount if both rates exist
    if (existingRate != null && 
        existingRate.baseRate.isNotEmpty && 
        existingRate.purchaseRate.isNotEmpty) {
      _calculateDiscountFromRates();
    }

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
                controller: _baseRateController,
                decoration: const InputDecoration(
                  labelText: 'Base Rate (Vendor\'s Standard Rate)',
                  border: OutlineInputBorder(),
                  helperText: 'Vendor\'s catalog/standard rate',
                ),
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  // Auto-calculate purchase rate if discount is entered
                  if (_discountController.text.isNotEmpty) {
                    _calculatePurchaseRateFromDiscount();
                  }
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _saleRateController,
                decoration: const InputDecoration(
                  labelText: 'Purchase Rate * (Actual Purchase Rate)',
                  border: OutlineInputBorder(),
                  helperText: 'Negotiated/actual purchase rate',
                ),
                keyboardType: TextInputType.number,
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                onChanged: (value) {
                  // Auto-calculate discount when purchase rate changes
                  _calculateDiscountFromRates();
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _discountController,
                decoration: const InputDecoration(
                  labelText: 'Discount %',
                  border: OutlineInputBorder(),
                  helperText: 'Discount percentage (auto-calculated or enter manually)',
                  suffixText: '%',
                ),
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  // Auto-calculate purchase rate when discount changes
                  _calculatePurchaseRateFromDiscount();
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _remarksController,
                decoration: const InputDecoration(
                  labelText: 'Remarks',
                  border: OutlineInputBorder(),
                  helperText: 'Additional notes about this vendor rate',
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

      final newRate = VendorMaterialRate(
        vendorId: vendor.name,
        baseRate: _baseRateController.text,
        purchaseRate: _saleRateController.text, // This is actually the purchase rate
        lastPurchaseDate: DateFormat('yyyy-MM-dd').format(DateTime.now()),
        remarks: _remarksController.text,
        isPreferred: false,
      );

      // Add/update the vendor rate directly in the material
      if (existingRate != null) {
        item.updateVendorRate(newRate);
      } else {
        item.addVendorRate(newRate);
      }
      setState(() {}); // Refresh the UI
    }
  }

  Widget _buildVendorRatesSection() {
    final rates = item.vendorRates;

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
                      vendorId: vendorName,
                      baseRate: '',
                      purchaseRate: '',
                      lastPurchaseDate:
                          DateFormat('yyyy-MM-dd').format(DateTime.now()),
                      remarks: '',
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
                          // Set preferred vendor using material's method
                          if (rate.isPreferred) {
                            // Remove preferred status
                            item.setPreferredVendor('');
                          } else {
                            // Set as preferred vendor
                            item.setPreferredVendor(rate.vendorId);
                          }
                          setState(() {}); // Refresh UI
                        },
                        tooltip: 'Set as preferred vendor',
                      ),
                      title: Text(vendorName),
                      subtitle: rate.purchaseRate.isNotEmpty
                          ? Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Base Rate: ₹${rate.baseRate}'),
                                Text('Purchase Rate: ₹${rate.purchaseRate}'),
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
                                item.removeVendorRate(vendorName);
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
                      type:
                          const TextInputType.numberWithOptions(decimal: true),
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
                    _buildTextField(
                      'Material Sale Rate',
                      'saleRate',
                      type: const TextInputType.numberWithOptions(decimal: true),
                      hint: 'Enter material\'s own sale rate',
                      validator: (value) {
                        if (value != null && value.isNotEmpty) {
                          if (double.tryParse(value) == null) {
                            return 'Please enter a valid number';
                          }
                          if (double.parse(value) < 0) {
                            return 'Sale rate cannot be negative';
                          }
                        }
                        return null;
                      },
                    ),
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
