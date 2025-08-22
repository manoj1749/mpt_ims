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
  
  // Weight unit dropdown
  String _selectedWeightUnit = 'kgs';
  final _weightValueController = TextEditingController();

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
    _controllers['binNumber'] = TextEditingController(text: item.binNumber);
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
    _weightValueController.dispose();
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
        item.binNumber = _controllers['binNumber']!.text;
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
      bool enabled = true,
      FormFieldValidator<String>? validator}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextFormField(
        controller: _controllers[field],
        enabled: enabled,
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

  Widget _buildSearchableDropdown(String label, String field, List<String> options,
      {String? hint, FormFieldValidator<String>? validator}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Autocomplete<String>(
        fieldViewBuilder: (context, textEditingController, focusNode, onFieldSubmitted) {
          // Set initial value
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (textEditingController.text.isEmpty && _controllers[field]!.text.isNotEmpty) {
              textEditingController.text = _controllers[field]!.text;
            }
          });
          return TextFormField(
            controller: textEditingController,
            focusNode: focusNode,
            decoration: InputDecoration(
              labelText: label,
              border: const OutlineInputBorder(),
              hintText: hint,
            ),
            validator: validator,
            onChanged: (value) {
              _controllers[field]!.text = value;
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
          return options.where((option) =>
              option.toLowerCase().contains(textEditingValue.text.toLowerCase()));
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
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
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
                DropdownMenuItem(value: 'milligrams', child: Text('Milligrams')),
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
                    _buildSearchableDropdown('Description', 'description', _getAvailableDescriptions(),
                        hint: 'Enter or select description',
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Required';
                          }
                          // Check for duplicate description (case-insensitive)
                          final materials = ref.read(materialListProvider);
                          final duplicateExists = materials.any((m) => 
                              m.description.toLowerCase() == value.toLowerCase() &&
                              m.slNo != item.slNo); // Exclude current item when editing
                          if (duplicateExists) {
                            return 'Description already exists';
                          }
                          return null;
                        }),
                    widget.materialToEdit == null ?
                      _buildSearchableDropdown('Part No', 'partNo', _getAvailablePartNumbers(),
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
                          }) :
                      _buildTextField(
                        'Part No',
                        'partNo',
                        enabled: false,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Required';
                          }
                          return null;
                        }
                      ),
                    _buildWeightField(),
                    _buildSearchableDropdown('Unit', 'unit', _getAvailableUnits(),
                        hint: 'Enter or select unit'),
                    _buildTextField('Storage Location', 'storageLocation'),
                    _buildSearchableDropdown('Rack Number', 'rackNumber', _getAvailableRackNumbers(),
                        hint: 'Enter or select rack number'),
                    _buildSearchableDropdown('BIN Number', 'binNumber', _getAvailableBinNumbers(),
                        hint: 'Enter or select BIN number'),
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

  // Helper methods to get available options for searchable dropdowns
  List<String> _getAvailableUnits() {
    final materials = ref.read(materialListProvider);
    final units = materials.map((m) => m.unit).where((unit) => unit.isNotEmpty).toSet().toList();
    units.sort();
    return units;
  }

  List<String> _getAvailableRackNumbers() {
    final materials = ref.read(materialListProvider);
    final rackNumbers = materials.map((m) => m.rackNumber).where((rack) => rack != null && rack.isNotEmpty).cast<String>().toSet().toList();
    rackNumbers.sort();
    return rackNumbers;
  }

  List<String> _getAvailableDescriptions() {
    final materials = ref.read(materialListProvider);
    final descriptions = materials.map((m) => m.description).where((desc) => desc.isNotEmpty).toSet().toList();
    descriptions.sort();
    return descriptions;
  }

  List<String> _getAvailablePartNumbers() {
    final materials = ref.read(materialListProvider);
    final partNumbers = materials.map((m) => m.partNo).where((part) => part.isNotEmpty).toSet().toList();
    partNumbers.sort();
    return partNumbers;
  }

  List<String> _getAvailableBinNumbers() {
    final materials = ref.read(materialListProvider);
    final binNumbers = materials.map((m) => m.binNumber).where((bin) => bin != null && bin.isNotEmpty).cast<String>().toSet().toList();
    binNumbers.sort();
    return binNumbers;
  }
}
