import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:mpt_ims/models/customer_scope_material_issue_master.dart';
import 'package:mpt_ims/provider/customer_scope_material_issue_master_provider.dart';

import 'package:mpt_ims/provider/category_provider.dart';
import 'package:mpt_ims/provider/sub_category_provider.dart';
import 'package:mpt_ims/provider/inventory_classification_provider.dart';
import 'package:mpt_ims/models/category.dart';
import 'package:mpt_ims/models/sub_category.dart';
import 'package:mpt_ims/models/inventory_classification.dart';

class AddCustomerScopeMaterialIssueMasterPage extends ConsumerStatefulWidget {
  final CustomerScopeMaterialIssueMaster? materialToEdit;
  final int? index;

  const AddCustomerScopeMaterialIssueMasterPage({
    super.key,
    this.materialToEdit,
    this.index,
  });

  @override
  ConsumerState<AddCustomerScopeMaterialIssueMasterPage> createState() => _AddCustomerScopeMaterialIssueMasterPageState();
}

class _AddCustomerScopeMaterialIssueMasterPageState extends ConsumerState<AddCustomerScopeMaterialIssueMasterPage> {
  final _formKey = GlobalKey<FormState>();
  late CustomerScopeMaterialIssueMaster item;
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

  @override
  void initState() {
    super.initState();
    item = widget.materialToEdit?.copy() ?? // Create a copy if editing
        CustomerScopeMaterialIssueMaster(
          slNo: (ref.read(customerScopeMaterialIssueMasterListProvider).length + 1)
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
    _inspectionStockController = TextEditingController(text: '0');

    // Initialize weight value controller and parse existing weight
    _initializeWeightField();

    // Set initial category and subcategory if editing
    if (widget.materialToEdit != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final categories = ref.read(categoryListProvider);
        final subCategories = ref.read(subCategoryListProvider);
        final inventoryClassifications = ref.read(inventoryClassificationListProvider);

        setState(() {
          // Find the actual category object from the list, or null if not found
          _selectedCategory = categories.cast<Category?>().firstWhere(
                (c) => c?.name == item.category,
                orElse: () => null,
              );

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.materialToEdit == null
            ? 'Add New Customer Scope Material Issue Master'
            : 'Edit Customer Scope Material Issue Master'),
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
                      final materials = ref.read(customerScopeMaterialIssueMasterListProvider);
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
                            final materials = ref.read(customerScopeMaterialIssueMasterListProvider);
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
                    _buildCategoryDropdown(),
                    _buildSubCategoryDropdown(),
                    _buildInventoryClassificationDropdown(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _saveMaterial() async {
    if (_formKey.currentState!.validate()) {
      try {
        final notifier = ref.read(customerScopeMaterialIssueMasterListProvider.notifier);

        // Update item with current values
        item.slNo = _controllers['slNo']!.text;
        item.description = _controllers['description']!.text;
        item.partNo = _controllers['partNo']!.text;
        item.unit = _controllers['unit']!.text;
        item.storageLocation = _controllers['storageLocation']!.text;
        item.rackNumber = _controllers['rackNumber']!.text;
        item.binNumber = _controllers['binNumber']!.text;
        item.hsnCode = _controllers['hsnCode']!.text;
        item.actualWeight = _controllers['actualWeight']!.text;
        item.category = _selectedCategory?.name ?? '';
        item.subCategory = _selectedSubCategory?.name ?? '';
        item.inventoryClassification = _selectedInventoryClassification?.name ?? '';

        if (widget.index != null) {
          // Update existing material
          await notifier.updateCustomerScopeMaterialIssueMaster(widget.index!, item);
        } else {
          // Create new material with a new slNo
          final newSlNo =
              (ref.read(customerScopeMaterialIssueMasterListProvider).length + 1).toString();
          item.slNo = newSlNo;
          await notifier.addCustomerScopeMaterialIssueMaster(item);
        }

        // Ensure the material list is refreshed
        ref.invalidate(customerScopeMaterialIssueMasterListProvider);

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

  // Helper method to get filtered subcategories
  Widget _buildInventoryClassificationDropdown() {
    final inventoryClassifications = ref.watch(inventoryClassificationListProvider);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
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
    );
  }

  List<SubCategory> _getFilteredSubCategories() {
    if (_selectedCategory == null) return [];
    return ref
        .read(subCategoryListProvider)
        .where((sc) => sc.categoryName == _selectedCategory!.name)
        .toList();
  }

  // Helper methods to get available options for searchable dropdowns
  List<String> _getAvailableUnits() {
    final materials = ref.read(customerScopeMaterialIssueMasterListProvider);
    final units = materials
        .map((m) => m.unit)
        .where((unit) => unit.isNotEmpty)
        .toSet()
        .toList();
    units.sort();
    return units;
  }

  List<String> _getAvailableRackNumbers() {
    final materials = ref.read(customerScopeMaterialIssueMasterListProvider);
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
    final materials = ref.read(customerScopeMaterialIssueMasterListProvider);
    final descriptions = materials
        .map((m) => m.description)
        .where((desc) => desc.isNotEmpty)
        .toSet()
        .toList();
    descriptions.sort();
    return descriptions;
  }

  List<String> _getAvailablePartNumbers() {
    final materials = ref.read(customerScopeMaterialIssueMasterListProvider);
    final partNumbers = materials
        .map((m) => m.partNo)
        .where((part) => part.isNotEmpty)
        .toSet()
        .toList();
    partNumbers.sort();
    return partNumbers;
  }

  List<String> _getAvailableBinNumbers() {
    final materials = ref.read(customerScopeMaterialIssueMasterListProvider);
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
    final materials = ref.read(customerScopeMaterialIssueMasterListProvider);
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
