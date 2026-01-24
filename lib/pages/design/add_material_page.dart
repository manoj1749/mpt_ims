import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import 'package:mpt_ims/models/material_item.dart';
import 'package:mpt_ims/models/supplier.dart';
import 'package:mpt_ims/models/vendor_material_rate.dart';
import 'package:mpt_ims/provider/material_provider.dart';

import 'package:mpt_ims/provider/category_provider.dart';
import 'package:mpt_ims/provider/sub_category_provider.dart';
import 'package:mpt_ims/provider/inventory_classification_provider.dart';
import 'package:mpt_ims/models/category.dart';
import 'package:mpt_ims/models/sub_category.dart';
import 'package:mpt_ims/models/inventory_classification.dart';
import 'package:mpt_ims/pages/design/select_vendors_dialog.dart';
import 'package:mpt_ims/pages/accounts/category_settings_page.dart';
import 'package:mpt_ims/pages/accounts/inventory_classification_page.dart';

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

  // Weight unit dropdown
  String _selectedWeightUnit = 'kgs';
  final _weightValueController = TextEditingController();

  // Add controllers for all text fields except category and subCategory
  final Map<String, TextEditingController> _controllers = {};

  // Selected category and subcategory
  Category? _selectedCategory;
  SubCategory? _selectedSubCategory;
  InventoryClassification? _selectedInventoryClassification;

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
    _controllers['binNumber'] = TextEditingController(text: item.binNumber);
    _controllers['hsnCode'] = TextEditingController(text: item.hsnCode);
    _controllers['actualWeight'] =
        TextEditingController(text: item.actualWeight);
    _controllers['saleRate'] = TextEditingController(text: item.saleRate);
    _inspectionStockController = TextEditingController(text: '0');

    // Initialize weight value controller and parse existing weight
    _initializeWeightField();

    // Set initial category and subcategory if editing
    if (widget.materialToEdit != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final categories = ref.read(categoryListProvider);
        final subCategories = ref.read(subCategoryListProvider);
        final inventoryClassifications = ref.read(inventoryClassificationListProvider);

        // Get existing vendor rates from the material
        selectedVendors = item.vendorRates.map((r) => r.vendorId).toList();

        setState(() {
          // Deduplicate categories by name
          final uniqueCategories = <String, Category>{};
          for (var category in categories) {
            uniqueCategories[category.name] = category;
          }
          
          // Find the actual category object from the deduplicated list
          _selectedCategory = uniqueCategories[item.category];

          if (_selectedCategory != null && _selectedCategory!.name.isNotEmpty) {
            // Find the actual subcategory object from the list, or null if not found
            _selectedSubCategory =
                subCategories.cast<SubCategory?>().firstWhere(
                      (sc) =>
                          sc?.name == item.subCategory &&
                          sc?.categoryName == item.category,
                      orElse: () => null,
                    );
          }

          // Find the actual inventory classification object from the list, or null if not found
          _selectedInventoryClassification = inventoryClassifications.cast<InventoryClassification?>().firstWhere(
                (ic) => ic?.name == item.inventoryClassification,
                orElse: () => null,
              );
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
    _weightValueController.dispose();
    // Dispose all controllers
    for (var controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _saveMaterial() async {
    // Collect all validation errors
    List<String> missingFields = [];
    
    if (_controllers['description']?.text.isEmpty ?? true) {
      missingFields.add('Description');
    }
    if (_controllers['partNo']?.text.isEmpty ?? true) {
      missingFields.add('Part No');
    }
    if (_controllers['unit']?.text.isEmpty ?? true) {
      missingFields.add('Unit');
    }
    if (_selectedCategory == null) {
      missingFields.add('Category');
    }
    if (_selectedSubCategory == null) {
      missingFields.add('Sub Category');
    }

    if (selectedVendors.isEmpty) {
      missingFields.add('Supplier');
    }
    
    // Show dialog if there are missing fields
    if (missingFields.isNotEmpty) {
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Missing Required Fields'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Please fill in the following required fields:'),
                const SizedBox(height: 12),
                ...missingFields.map((field) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: Colors.red, size: 20),
                      const SizedBox(width: 8),
                      Text(field, style: const TextStyle(fontWeight: FontWeight.w500)),
                    ],
                  ),
                )),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
      return;
    }
    
    if (_formKey.currentState!.validate()) {
      // Ensure selected suppliers exist in vendorRates so the material carries supplier info
      for (final vendorName in selectedVendors) {
        final exists = item.vendorRates.any((r) => r.vendorId == vendorName);
        if (!exists) {
          item.addVendorRate(VendorMaterialRate(
            vendorId: vendorName,
            baseRate: '',
            purchaseRate: '',
            lastPurchaseDate: DateFormat('yyyy-MM-dd').format(DateTime.now()),
            remarks: '',
            isPreferred: false,
          ));
        }
      }
      // Remove vendor rates for unselected suppliers
      item.vendorRates.removeWhere((r) => !selectedVendors.contains(r.vendorId));

      // Default preferred supplier to the first selected if none chosen
      if (selectedVendors.isNotEmpty &&
          !item.vendorRates.any((r) => r.isPreferred)) {
        item.setPreferredVendor(selectedVendors.first);
      }

      // Check if all selected vendors have rates
      final rates = item.vendorRates;

      final vendorsWithoutRates = selectedVendors
          .where((vendor) => !rates.any((r) => r.vendorId == vendor))
          .toList();

      if (vendorsWithoutRates.isNotEmpty) {
        if (mounted) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Missing Supplier Rates'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Please provide purchase rates for the following suppliers:'),
                  const SizedBox(height: 12),
                  ...vendorsWithoutRates.map((vendor) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline, color: Colors.orange, size: 20),
                        const SizedBox(width: 8),
                        Text(vendor, style: const TextStyle(fontWeight: FontWeight.w500)),
                      ],
                    ),
                  )),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('OK'),
                ),
              ],
            ),
          );
        }
        return;
      }
      
      // Check if HSN code is missing and show warning dialog
      if (_controllers['hsnCode']?.text.isEmpty ?? true) {
        final shouldContinue = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 28),
                SizedBox(width: 8),
                Expanded(child: Text('HSN Code Not Available')),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'HSN Code has not been entered for this material.',
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                  SizedBox(height: 12),
                  Text(
                    'Warning: Without HSN Code, you will not be able to create Goods Receipt (GR) for this material.',
                    style: TextStyle(color: Colors.red),
                  ),
                  SizedBox(height: 12),
                  Text('Are you sure you want to continue saving without HSN Code?'),
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
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                ),
                child: const Text('Continue Without HSN', style: TextStyle(color: Colors.black)),
              ),
            ],
          ),
        );
        
        if (shouldContinue != true) {
          return; // User cancelled, don't save
        }
      }

      try {
        final notifier = ref.read(materialListProvider.notifier);

        // Normalize fields that must be uppercase
        final normalizedDescription =
            (_controllers['description']!.text).toUpperCase();
        final normalizedPartNo = (_controllers['partNo']!.text).toUpperCase();
        _controllers['description']!.text = normalizedDescription;
        _controllers['partNo']!.text = normalizedPartNo;

        // Update item with current values
        item.slNo = _controllers['slNo']!.text;
        item.description = normalizedDescription;
        item.partNo = normalizedPartNo;
        item.unit = _controllers['unit']!.text;
        item.storageLocation = _controllers['storageLocation']!.text;
        item.rackNumber = _controllers['rackNumber']!.text;
        item.binNumber = _controllers['binNumber']!.text;
        item.hsnCode = _controllers['hsnCode']!.text;
        item.actualWeight = _controllers['actualWeight']!.text;
        item.category = _selectedCategory?.name ?? '';
        item.subCategory = _selectedSubCategory?.name ?? '';
        item.saleRate = _controllers['saleRate']?.text ?? '';
        // Persist inventory classification from the dropdown selection
        item.inventoryClassification = _selectedInventoryClassification?.name ?? item.inventoryClassification;

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
      bool enabled = true,
      FormFieldValidator<String>? validator}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextFormField(
        controller: _controllers[field],
        enabled: enabled,
        inputFormatters: (field == 'partNo' || field == 'description')
            ? [UpperCaseTextFormatter()]
            : null,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          hintText: hint,
          filled: !enabled,
          fillColor: !enabled ? Colors.grey[600] : null,
        ),
        style: TextStyle(
          color: !enabled ? Colors.grey[400] : null,
        ),
        keyboardType: type,
        validator: validator,
      ),
    );
  }

  Widget _buildSearchableDropdown(
      String label, String field, List<String> options,
      {String? hint, FormFieldValidator<String>? validator}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Autocomplete<String>(
        fieldViewBuilder:
            (context, textEditingController, focusNode, onFieldSubmitted) {
          // Set initial value
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (textEditingController.text.isEmpty &&
                _controllers[field]!.text.isNotEmpty) {
              textEditingController.text = _controllers[field]!.text;
            }
          });
          return TextFormField(
            controller: textEditingController,
            focusNode: focusNode,
            inputFormatters: (field == 'partNo' || field == 'description')
                ? [UpperCaseTextFormatter()]
                : null,
            decoration: InputDecoration(
              labelText: label,
              border: const OutlineInputBorder(),
              hintText: hint,
            ),
            validator: validator,
            onChanged: (value) {
              _controllers[field]!.text =
                  (field == 'partNo' || field == 'description')
                      ? value.toUpperCase()
                      : value;
            },
          );
        },
        optionsViewBuilder: (context, onSelected, options) {
          return Align(
            alignment: Alignment.topLeft,
            child: Material(
              elevation: 4.0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: BorderSide(
                  color: Theme.of(context).dividerColor,
                ),
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxHeight: 200,
                  maxWidth: 400,
                ),
                child: ListView.builder(
                  padding: const EdgeInsets.all(8.0),
                  itemCount: options.length,
                  itemBuilder: (context, index) {
                    final option = options.elementAt(index);
                    return InkWell(
                      onTap: () => onSelected(option),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          vertical: 12.0,
                          horizontal: 16.0,
                        ),
                        child: Text(
                          option,
                          style: const TextStyle(fontSize: 14.0),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          );
        },
        optionsBuilder: (textEditingValue) {
          if (textEditingValue.text.isEmpty) {
            return options;
          }
          return options.where((option) => option
              .toLowerCase()
              .contains(textEditingValue.text.toLowerCase()));
        },
        onSelected: (option) {
          setState(() {
            _controllers[field]!.text = option;
          });
        },
      ),
    );
  }

  Widget _buildWeightField() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: TextFormField(
              controller: _weightValueController,
              decoration: const InputDecoration(
                labelText: 'Actual Weight',
                border: OutlineInputBorder(),
                hintText: 'Enter actual/finished goods weight',
              ),
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
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
              onChanged: (value) {
                // Update the combined weight value
                _updateCombinedWeight();
              },
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: DropdownButtonFormField<String>(
              value: _selectedWeightUnit,
              decoration: const InputDecoration(
                labelText: 'Unit',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'kgs', child: Text('Kgs')),
                DropdownMenuItem(value: 'grams', child: Text('Grams')),
                DropdownMenuItem(
                    value: 'milligrams', child: Text('Milligrams')),
                DropdownMenuItem(value: 'tons', child: Text('Tons')),
                DropdownMenuItem(value: 'pounds', child: Text('Pounds')),
                DropdownMenuItem(value: 'ounces', child: Text('Ounces')),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedWeightUnit = value;
                  });
                  _updateCombinedWeight();
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  void _initializeWeightField() {
    final existingWeight = item.actualWeight;
    if (existingWeight != null && existingWeight.isNotEmpty) {
      // Parse existing weight to extract value and unit
      final parts = existingWeight.split(' ');
      if (parts.length >= 2) {
        final weightValue = parts[0];
        final unit = parts[1];

        _weightValueController.text = weightValue;
        _selectedWeightUnit = unit;
      } else {
        // If no unit found, assume it's just a number
        _weightValueController.text = existingWeight;
        _selectedWeightUnit = 'kgs';
      }
    }
  }

  void _updateCombinedWeight() {
    final weightValue = _weightValueController.text;
    if (weightValue.isNotEmpty) {
      final combinedWeight = '$weightValue $_selectedWeightUnit';
      // Store the combined value in the actualWeight field
      _controllers['actualWeight']!.text = combinedWeight;
    }
  }

  Widget _buildCategoryDropdown() {
    final categories = ref.watch(categoryListProvider);
    
    // Remove duplicates by name to prevent dropdown assertion error
    final uniqueCategories = <String, Category>{};
    for (var category in categories) {
      uniqueCategories[category.name] = category;
    }
    final categoryList = uniqueCategories.values.toList();

    // Ensure selected category matches an object in the deduplicated list
    Category? selectedCategory = _selectedCategory;
    if (selectedCategory != null && !categoryList.contains(selectedCategory)) {
      // Find the category by name in the deduplicated list
      selectedCategory = uniqueCategories[selectedCategory.name];
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<Category>(
                  value: selectedCategory,
                  decoration: const InputDecoration(
                    labelText: 'Category',
                    border: OutlineInputBorder(),
                  ),
                  items: categoryList.map((category) {
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
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.add),
                onPressed: _addNewCategory,
                tooltip: 'Add New Category',
                style: IconButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
          if (categories.isEmpty)
            Container(
                padding: const EdgeInsets.all(12),
                child: ListTile(
                  leading: Icon(
                    Icons.info_outline,
                    color: Colors.grey.shade400,
                    size: 20,
                  ),
                  title: Text(
                    'No categories found',
                    style: TextStyle(
                      color: Colors.grey.shade300,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  subtitle: Text(
                    'Click the + button to add a new category',
                    style: TextStyle(
                      color: Colors.grey.shade500,
                      fontSize: 12,
                    ),
                  ),
                )),
        ],
      ),
    );
  }

  Widget _buildSubCategoryDropdown() {
    final subCategories = _getFilteredSubCategories();
    
    // Remove duplicates by name and categoryName to prevent dropdown assertion error
    final uniqueSubCategories = <String, SubCategory>{};
    for (var subCategory in subCategories) {
      final key = '${subCategory.categoryName}_${subCategory.name}';
      uniqueSubCategories[key] = subCategory;
    }
    final subCategoryList = uniqueSubCategories.values.toList();

    // Ensure selected subcategory matches an object in the deduplicated list
    SubCategory? selectedSubCategory = _selectedSubCategory;
    if (selectedSubCategory != null && !subCategoryList.contains(selectedSubCategory)) {
      // Find the subcategory by name and categoryName in the deduplicated list
      final key = '${selectedSubCategory.categoryName}_${selectedSubCategory.name}';
      selectedSubCategory = uniqueSubCategories[key];
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<SubCategory>(
                  value: selectedSubCategory,
                  decoration: const InputDecoration(
                    labelText: 'Sub Category',
                    border: OutlineInputBorder(),
                  ),
                  items: subCategoryList.map((subCategory) {
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
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.add),
                onPressed: _selectedCategory == null ? null : _addNewSubCategory,
                tooltip: 'Add New Sub-Category',
                style: IconButton.styleFrom(
                  backgroundColor: _selectedCategory == null ? Colors.grey : Colors.blue,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
          if (_selectedCategory != null && subCategoryList.isEmpty)
            Container(
                padding: const EdgeInsets.all(12),
                child: ListTile(
                  leading: Icon(
                    Icons.info_outline,
                    color: Colors.grey.shade400,
                    size: 20,
                  ),
                  title: Text(
                    'No sub-categories found for ${_selectedCategory!.name}',
                    style: TextStyle(
                      color: Colors.grey.shade300,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  subtitle: Text(
                    'Click the + button to add a new sub-category',
                    style: TextStyle(
                      color: Colors.grey.shade500,
                      fontSize: 12,
                    ),
                  ),
                )),
        ],
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
                  helperText: 'Must match PO price to avoid mismatch warnings',
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
                  helperText:
                      'Discount percentage (auto-calculated or enter manually)',
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
      // If base rate is empty, set it equal to purchase rate
      final baseRate = _baseRateController.text.isEmpty 
          ? _saleRateController.text 
          : _baseRateController.text;
      
      final newRate = VendorMaterialRate(
        vendorId: vendor.name,
        baseRate: baseRate,
        purchaseRate:
            _saleRateController.text, // This is actually the purchase rate
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
                  'Supplier Rates',
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

                        // Keep vendorRates aligned with selected suppliers
                        for (final vendorName in selectedVendors) {
                          final exists = item.vendorRates
                              .any((r) => r.vendorId == vendorName);
                          if (!exists) {
                            item.addVendorRate(VendorMaterialRate(
                              vendorId: vendorName,
                              baseRate: '',
                              purchaseRate: '',
                              lastPurchaseDate: DateFormat('yyyy-MM-dd')
                                  .format(DateTime.now()),
                              remarks: '',
                              isPreferred: false,
                            ));
                          }
                        }
                        item.vendorRates
                            .removeWhere((r) => !selectedVendors.contains(r.vendorId));

                        if (selectedVendors.isNotEmpty &&
                            !item.vendorRates.any((r) => r.isPreferred)) {
                          item.setPreferredVendor(selectedVendors.first);
                        }
                      });
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (selectedVendors.isEmpty)
              const Center(
                child: Text('No suppliers selected'),
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
                        tooltip: 'Set as preferred supplier',
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
                    _buildSearchableDropdown('Description', 'description',
                        _getAvailableDescriptions(),
                        hint: 'Enter or select description',
                        validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Required';
                      }
                      // Check for duplicate description (case-insensitive)
                      final materials = ref.read(materialListProvider);
                      final duplicateExists = materials.any((m) =>
                          m.description.toLowerCase() == value.toLowerCase() &&
                          m.slNo !=
                              item.slNo); // Exclude current item when editing
                      if (duplicateExists) {
                        return 'Description already exists';
                      }
                      return null;
                    }),
                    widget.materialToEdit == null
                        ? _buildSearchableDropdown(
                            'Part No', 'partNo', _getAvailablePartNumbers(),
                            hint: 'Enter or select part number',
                            validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Required';
                            }
                            // Check for duplicate part number (case-insensitive)
                            final materials = ref.read(materialListProvider);
                            final duplicateExists = materials.any((m) =>
                                m.partNo.toLowerCase() == value.toLowerCase());
                            if (duplicateExists) {
                              return 'Part number already exists';
                            }
                            return null;
                          })
                        : _buildTextField('Part No', 'partNo', enabled: false,
                            validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Required';
                            }
                            return null;
                          }),
                    _buildWeightField(),
                    _buildSearchableDropdown(
                        'Unit', 'unit', _getAvailableUnits(),
                        hint: 'Enter or select unit'),
                    _buildTextField('Storage Location', 'storageLocation'),
                    _buildSearchableDropdown(
                        'Rack Number', 'rackNumber', _getAvailableRackNumbers(),
                        hint: 'Enter or select rack number'),
                    _buildSearchableDropdown(
                        'BIN Number', 'binNumber', _getAvailableBinNumbers(),
                        hint: 'Enter or select BIN number'),
                    _buildSearchableDropdown(
                        'HSN Code', 'hsnCode', _getAvailableHSNCodes(),
                        hint: 'Enter or select HSN code'),
                    _buildTextField(
                      'Material Sale Rate',
                      'saleRate',
                      type:
                          const TextInputType.numberWithOptions(decimal: true),
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
                    _buildInventoryClassificationDropdown(),
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
        .watch(subCategoryListProvider)
        .where((subCat) => subCat.categoryName == _selectedCategory!.name)
        .toList();
  }

  Widget _buildInventoryClassificationDropdown() {
    final inventoryClassifications = ref.watch(inventoryClassificationListProvider);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: DropdownButtonFormField<InventoryClassification>(
              value: _selectedInventoryClassification,
              decoration: const InputDecoration(
                labelText: 'Inventory Classification',
                border: OutlineInputBorder(),
              ),
              items: inventoryClassifications.map((inventoryClassification) {
                return DropdownMenuItem(
                  value: inventoryClassification,
                  child: Text(inventoryClassification.name),
                );
              }).toList(),
              onChanged: (InventoryClassification? newValue) {
                setState(() {
                  _selectedInventoryClassification = newValue;
                  item.inventoryClassification = newValue?.name ?? '';
                });
              },
              validator: (value) =>
                  value == null || value.name.isEmpty ? 'Required' : null,
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _addNewInventoryClassification,
            tooltip: 'Add New Inventory Classification',
            style: IconButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  void _addNewCategory() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CategorySettingsPage()),
    ).then((_) {
      // Refresh the categories after returning from the settings page
      ref.read(categoryListProvider.notifier).loadCategories();
      
      // Update selected category to point to the new object after reload
      if (_selectedCategory != null) {
        final categories = ref.read(categoryListProvider);
        final uniqueCategories = <String, Category>{};
        for (var category in categories) {
          uniqueCategories[category.name] = category;
        }
        _selectedCategory = uniqueCategories[_selectedCategory!.name];
      }
      
      setState(() {});
    });
  }

  void _addNewSubCategory() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CategorySettingsPage()),
    ).then((_) {
      // Refresh the subcategories after returning from the settings page
      ref.read(subCategoryListProvider.notifier).loadSubCategories();
      
      // Update selected subcategory to point to the new object after reload
      if (_selectedSubCategory != null) {
        final subCategories = ref.read(subCategoryListProvider);
        _selectedSubCategory = subCategories.cast<SubCategory?>().firstWhere(
          (sc) => sc?.name == _selectedSubCategory!.name && 
                  sc?.categoryName == _selectedSubCategory!.categoryName,
          orElse: () => null,
        );
      }
      
      setState(() {});
    });
  }

  void _addNewInventoryClassification() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const InventoryClassificationPage()),
    ).then((_) {
      // Refresh the inventory classifications after returning from the settings page
      ref.read(inventoryClassificationListProvider.notifier).loadInventoryClassifications();
      
      // Update selected inventory classification to point to the new object after reload
      if (_selectedInventoryClassification != null) {
        final inventoryClassifications = ref.read(inventoryClassificationListProvider);
        _selectedInventoryClassification = inventoryClassifications.cast<InventoryClassification?>().firstWhere(
          (ic) => ic?.name == _selectedInventoryClassification!.name,
          orElse: () => null,
        );
      }
      
      setState(() {});
    });
  }

  // Helper methods to get available options for searchable dropdowns
  List<String> _getAvailableUnits() {
    final materials = ref.read(materialListProvider);
    final units = materials
        .map((m) => m.unit)
        .where((unit) => unit.isNotEmpty)
        .toSet()
        .toList();
    units.sort();
    return units;
  }

  List<String> _getAvailableRackNumbers() {
    final materials = ref.read(materialListProvider);
    final rackNumbers = materials
        .map((m) => m.rackNumber)
        .where((rack) => rack != null && rack.isNotEmpty)
        .cast<String>()
        .toSet()
        .toList();
    rackNumbers.sort();
    return rackNumbers;
  }

  List<String> _getAvailableDescriptions() {
    final materials = ref.read(materialListProvider);
    final descriptions = materials
        .map((m) => m.description)
        .where((desc) => desc.isNotEmpty)
        .toSet()
        .toList();
    descriptions.sort();
    return descriptions;
  }

  List<String> _getAvailablePartNumbers() {
    final materials = ref.read(materialListProvider);
    final partNumbers = materials
        .map((m) => m.partNo)
        .where((part) => part.isNotEmpty)
        .toSet()
        .toList();
    partNumbers.sort();
    return partNumbers;
  }

  List<String> _getAvailableBinNumbers() {
    final materials = ref.read(materialListProvider);
    final binNumbers = materials
        .map((m) => m.binNumber)
        .where((bin) => bin != null && bin.isNotEmpty)
        .cast<String>()
        .toSet()
        .toList();
    binNumbers.sort();
    return binNumbers;
  }

  List<String> _getAvailableHSNCodes() {
    final materials = ref.read(materialListProvider);
    final hsnCodes = materials
        .map((m) => m.hsnCode)
        .where((hsn) => hsn != null && hsn.isNotEmpty)
        .cast<String>()
        .toSet()
        .toList();
    hsnCodes.sort();
    return hsnCodes;
  }
}

class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final upper = newValue.text.toUpperCase();
    return newValue.copyWith(
      text: upper,
      selection: newValue.selection,
      composing: TextRange.empty,
    );
  }
}
