// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../provider/inventory_classification_provider.dart';
import '../../provider/sub_category_provider.dart';
import '../../provider/category_parameter_provider.dart';
import '../../provider/universal_parameter_provider.dart';
import '../../models/inventory_classification.dart';
import '../../models/category_parameter_mapping.dart';
import 'package:hive/hive.dart';

class InventoryClassificationPage extends ConsumerStatefulWidget {
  const InventoryClassificationPage({super.key});

  @override
  ConsumerState<InventoryClassificationPage> createState() =>
      _InventoryClassificationPageState();
}

class _InventoryClassificationPageState extends ConsumerState<InventoryClassificationPage> {
  final _inventoryClassificationController = TextEditingController();
  final _subCategoryController = TextEditingController();
  final _parameterController = TextEditingController();

  // Sample size controllers
  final _sampleSizeLessThan100Controller = TextEditingController();
  final _sampleSize100To500Controller = TextEditingController();
  final _sampleSizeGreaterThan500Controller = TextEditingController();
  final _shelfLifeValueController = TextEditingController();

  InventoryClassification? _selectedInventoryClassification;
  InventoryClassification? _unsavedInventoryClassification;
  bool _hasUnsavedChanges = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        // Load all required data
        await ref.read(inventoryClassificationListProvider.notifier).loadInventoryClassifications();
        await ref.read(subCategoryListProvider.notifier).loadSubCategories();
        await ref.read(categoryParameterProvider.notifier).loadMappings();
        await ref.read(universalParameterProvider.notifier).loadParameters();

        // Print debug info
        _printBoxContents();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error loading data: $e')),
          );
        }
      }
    });
  }

  @override
  void dispose() {
    _inventoryClassificationController.dispose();
    _subCategoryController.dispose();
    _parameterController.dispose();
    _sampleSizeLessThan100Controller.dispose();
    _sampleSize100To500Controller.dispose();
    _sampleSizeGreaterThan500Controller.dispose();
    _shelfLifeValueController.dispose();
    super.dispose();
  }

  Future<void> _refreshData() async {
    await ref.read(inventoryClassificationListProvider.notifier).refresh();
    await ref.read(subCategoryListProvider.notifier).refresh();
    await ref.read(categoryParameterProvider.notifier).refresh();
    await ref.read(universalParameterProvider.notifier).refresh();
  }

  void _printBoxContents() {
    print('\n==== PRINTING INVENTORY CLASSIFICATION DATA ====');

    // Print Inventory Classifications
    if (Hive.isBoxOpen('inventory_classifications')) {
      final inventoryClassificationBox =
          Hive.box<InventoryClassification>('inventory_classifications');
      print('\n-- Inventory Classifications Box Contents --');
      for (var inventoryClassification in inventoryClassificationBox.values) {
        print('''
Inventory Classification: ${inventoryClassification.name}
- Requires Quality Check: ${inventoryClassification.requiresQualityCheck}
- Sample Size <100: ${inventoryClassification.sampleSizeLessThan100}
- Sample Size 100-500: ${inventoryClassification.sampleSize100To500}
- Sample Size >500: ${inventoryClassification.sampleSizeGreaterThan500}
- Has Expiry Date: ${inventoryClassification.hasExpiryDate}
- Has Shelf Life: ${inventoryClassification.hasShelfLife}
- Shelf Life Value: ${inventoryClassification.shelfLifeValue}
- Shelf Life Unit: ${inventoryClassification.shelfLifeUnit}
''');
      }
    } else {
      print('Inventory Classifications box is not open');
    }

    // Print Category Parameter Mappings
    if (Hive.isBoxOpen('categoryParameterMappings')) {
      final mappingBox =
          Hive.box<CategoryParameterMapping>('categoryParameterMappings');
      print('\n-- Category Parameter Mappings Box Contents --');
      for (var mapping in mappingBox.values) {
        print('''
Mapping for Category: ${mapping.category}
- Parameters: ${mapping.parameters}
''');
      }
    } else {
      print('Category Parameter Mappings box is not open');
    }

    print('\n==== END INVENTORY CLASSIFICATION DATA ====\n');
  }

  void _showAddDialog(String title, String hint, Function(String) onAdd) {
    final controller = title == 'Inventory Classification'
        ? _inventoryClassificationController
        : title == 'Sub-Category'
            ? _subCategoryController
            : _parameterController;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Add $title'),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: hint,
            border: const OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final text = controller.text.trim();
              if (text.isNotEmpty) {
                onAdd(text);
                Navigator.pop(context);
                controller.clear();
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  Future<bool> _onWillPop() async {
    if (_hasUnsavedChanges) {
      final result = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Unsaved Changes'),
          content: const Text('Do you want to discard your unsaved changes?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Discard'),
            ),
          ],
        ),
      );
      return result ?? false;
    }
    return true;
  }

  void _onInventoryClassificationSelected(InventoryClassification inventoryClassification) {
    if (_hasUnsavedChanges) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Unsaved Changes'),
          content: const Text('Save changes before switching inventory classifications?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                setState(() {
                  _selectedInventoryClassification = inventoryClassification;
                  _unsavedInventoryClassification = InventoryClassification(
                    name: inventoryClassification.name,
                    requiresQualityCheck: inventoryClassification.requiresQualityCheck,
                    sampleSizeLessThan100: inventoryClassification.sampleSizeLessThan100,
                    sampleSize100To500: inventoryClassification.sampleSize100To500,
                    sampleSizeGreaterThan500: inventoryClassification.sampleSizeGreaterThan500,
                    hasExpiryDate: inventoryClassification.hasExpiryDate,
                    hasShelfLife: inventoryClassification.hasShelfLife,
                    shelfLifeValue: inventoryClassification.shelfLifeValue,
                    shelfLifeUnit: inventoryClassification.shelfLifeUnit,
                  );
                  _hasUnsavedChanges = false;
                });
              },
              child: const Text('Discard'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _saveChanges();
                setState(() {
                  _selectedInventoryClassification = inventoryClassification;
                  _unsavedInventoryClassification = InventoryClassification(
                    name: inventoryClassification.name,
                    requiresQualityCheck: inventoryClassification.requiresQualityCheck,
                    sampleSizeLessThan100: inventoryClassification.sampleSizeLessThan100,
                    sampleSize100To500: inventoryClassification.sampleSize100To500,
                    sampleSizeGreaterThan500: inventoryClassification.sampleSizeGreaterThan500,
                    hasExpiryDate: inventoryClassification.hasExpiryDate,
                    hasShelfLife: inventoryClassification.hasShelfLife,
                    shelfLifeValue: inventoryClassification.shelfLifeValue,
                    shelfLifeUnit: inventoryClassification.shelfLifeUnit,
                  );
                  _hasUnsavedChanges = false;
                });
              },
              child: const Text('Save'),
            ),
          ],
        ),
      );
    } else {
      setState(() {
        _selectedInventoryClassification = inventoryClassification;
        _unsavedInventoryClassification = InventoryClassification(
          name: inventoryClassification.name,
          requiresQualityCheck: inventoryClassification.requiresQualityCheck,
          sampleSizeLessThan100: inventoryClassification.sampleSizeLessThan100,
          sampleSize100To500: inventoryClassification.sampleSize100To500,
          sampleSizeGreaterThan500: inventoryClassification.sampleSizeGreaterThan500,
          hasExpiryDate: inventoryClassification.hasExpiryDate,
          hasShelfLife: inventoryClassification.hasShelfLife,
          shelfLifeValue: inventoryClassification.shelfLifeValue,
          shelfLifeUnit: inventoryClassification.shelfLifeUnit,
        );
      });
      _updateTextControllers(inventoryClassification);
    }
  }

  Future<void> _saveChanges() async {
    if (_unsavedInventoryClassification != null) {
      await ref
          .read(inventoryClassificationListProvider.notifier)
          .updateInventoryClassification(_unsavedInventoryClassification!);
      setState(() {
        _selectedInventoryClassification = _unsavedInventoryClassification!.copyWith();
        _hasUnsavedChanges = false;
      });
      _updateTextControllers(_selectedInventoryClassification!);
      _printBoxContents();
    }
  }

  void _updateTextControllers(InventoryClassification inventoryClassification) {
    _sampleSizeLessThan100Controller.text =
        inventoryClassification.sampleSizeLessThan100?.toString() ?? '';
    _sampleSize100To500Controller.text =
        inventoryClassification.sampleSize100To500?.toString() ?? '';
    _sampleSizeGreaterThan500Controller.text =
        inventoryClassification.sampleSizeGreaterThan500?.toString() ?? '';
    _shelfLifeValueController.text = inventoryClassification.shelfLifeValue?.toString() ?? '';
  }

  void _updateUnsavedInventoryClassification(InventoryClassification updatedInventoryClassification) {
    setState(() {
      _unsavedInventoryClassification = updatedInventoryClassification;
      _hasUnsavedChanges = true;
    });
  }

  Widget _buildSection(
      String title, List<dynamic> items, Function(String) onAdd,
      {Function(dynamic)? onDelete}) {
    return Card(
      margin: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.black,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add, color: Colors.white),
                  onPressed: () => _showAddDialog(
                    title,
                    'Enter $title name',
                    onAdd,
                  ),
                ),
              ],
            ),
          ),
          if (items.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'No items added yet',
                style: TextStyle(color: Colors.grey),
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                return ListTile(
                  title: Text(item.name),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    onPressed: onDelete != null ? () => onDelete(item) : null,
                  ),
                  onTap: title == 'Inventory Classification'
                      ? () => _onInventoryClassificationSelected(item as InventoryClassification)
                      : null,
                  selected: title == 'Inventory Classification' && item == _selectedInventoryClassification,
                );
              },
            ),
        ],
      ),
    );
  }

  Future<void> _updateInventoryClassification(InventoryClassification updatedInventoryClassification) async {
    await ref
        .read(inventoryClassificationListProvider.notifier)
        .updateInventoryClassification(updatedInventoryClassification);
    setState(() => _selectedInventoryClassification = updatedInventoryClassification);
    _printBoxContents(); // Print contents after update
  }

  Widget _buildQualityParameterSection() {
    final mappings = ref.watch(categoryParameterProvider);
    final universalParams = ref.watch(universalParameterProvider);

    return Card(
      margin: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.black,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Quality Parameters',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add, color: Colors.white),
                  onPressed: () => _showAddDialog(
                    'Quality Parameter',
                    'Enter parameter name',
                    (name) {
                      ref
                          .read(universalParameterProvider.notifier)
                          .addParameter(name);
                      _printBoxContents();
                    },
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SwitchListTile(
                  title: const Text('Requires Quality Check'),
                  subtitle: const Text(
                      'Enable if materials in this inventory classification require quality inspection'),
                  value: _unsavedInventoryClassification?.requiresQualityCheck ?? true,
                  onChanged: (value) {
                    final updatedInventoryClassification = _unsavedInventoryClassification!.copyWith(
                      requiresQualityCheck: value,
                    );
                    _updateUnsavedInventoryClassification(updatedInventoryClassification);
                  },
                ),
                const SizedBox(height: 16),
                const Text(
                  'Universal Parameters',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                if (universalParams.isEmpty)
                  const Text(
                    'No parameters defined yet',
                    style: TextStyle(color: Colors.grey),
                  )
                else
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: universalParams.map((param) {
                      return Chip(
                        label: Text(param.name),
                        onDeleted: () {
                          ref
                              .read(universalParameterProvider.notifier)
                              .removeParameter(param);
                          // Remove this parameter from all inventory classification mappings
                          for (var mapping in mappings) {
                            if (mapping.parameters.contains(param.name)) {
                              mapping.parameters.remove(param.name);
                              ref
                                  .read(categoryParameterProvider.notifier)
                                  .updateMapping(mapping);
                            }
                          }
                        },
                      );
                    }).toList(),
                  ),
                const SizedBox(height: 16),
                if (_selectedInventoryClassification == null)
                  const Text(
                    'Select an inventory classification to manage its parameters',
                    style: TextStyle(
                        color: Colors.grey, fontStyle: FontStyle.italic),
                  )
                else ...[
                  Text(
                    'Parameters for ${_selectedInventoryClassification!.name}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (universalParams.isEmpty)
                    const Text(
                      'No parameters defined yet',
                      style: TextStyle(color: Colors.grey),
                    )
                  else
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: universalParams.map((param) {
                        final isSelected = mappings.any((m) =>
                            m.category == _selectedInventoryClassification!.name &&
                            m.parameters.contains(param.name));

                        return FilterChip(
                          label: Text(param.name),
                          selected: isSelected,
                          onSelected: (selected) {
                            final mapping = mappings.firstWhere(
                              (m) => m.category == _selectedInventoryClassification!.name,
                              orElse: () => CategoryParameterMapping(
                                category: _selectedInventoryClassification!.name,
                                parameters: [],
                                requiresExpiryDate: false,
                              ),
                            );

                            if (selected) {
                              mapping.parameters.add(param.name);
                            } else {
                              mapping.parameters.remove(param.name);
                            }
                            ref
                                .read(categoryParameterProvider.notifier)
                                .updateMapping(mapping);
                          },
                        );
                      }).toList(),
                    ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSamplePlanSection() {
    if (_unsavedInventoryClassification == null) return const SizedBox.shrink();

    return Card(
      margin: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.black,
            child: const Text(
              'Sample Plan Settings',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Sample Size for Qty < 100',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  controller: _sampleSizeLessThan100Controller,
                  onChanged: (value) {
                    final intValue = int.tryParse(value);
                    final updatedInventoryClassification = _unsavedInventoryClassification!.copyWith(
                      sampleSizeLessThan100: intValue,
                    );
                    _updateUnsavedInventoryClassification(updatedInventoryClassification);
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Sample Size for Qty 100-500',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  controller: _sampleSize100To500Controller,
                  onChanged: (value) {
                    final intValue = int.tryParse(value);
                    final updatedInventoryClassification = _unsavedInventoryClassification!.copyWith(
                      sampleSize100To500: intValue,
                    );
                    _updateUnsavedInventoryClassification(updatedInventoryClassification);
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Sample Size for Qty > 500',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  controller: _sampleSizeGreaterThan500Controller,
                  onChanged: (value) {
                    final intValue = int.tryParse(value);
                    final updatedInventoryClassification = _unsavedInventoryClassification!.copyWith(
                      sampleSizeGreaterThan500: intValue,
                    );
                    _updateUnsavedInventoryClassification(updatedInventoryClassification);
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpiryShelfLifeSection() {
    if (_unsavedInventoryClassification == null) return const SizedBox.shrink();

    return Card(
      margin: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.black,
            child: const Text(
              'Expiry/Shelf Life Settings',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: CheckboxListTile(
                        title: const Text('Has Expiry Date'),
                        value: _unsavedInventoryClassification!.hasExpiryDate,
                        onChanged: (value) {
                          if (value != null) {
                            final updatedInventoryClassification = _unsavedInventoryClassification!.copyWith(
                              hasExpiryDate: value,
                              hasShelfLife: value
                                  ? false
                                  : _unsavedInventoryClassification!.hasShelfLife,
                            );
                            _updateUnsavedInventoryClassification(updatedInventoryClassification);
                          }
                        },
                      ),
                    ),
                    Expanded(
                      child: CheckboxListTile(
                        title: const Text('Has Shelf Life'),
                        value: _unsavedInventoryClassification!.hasShelfLife,
                        onChanged: (value) {
                          if (value != null) {
                            final updatedInventoryClassification = _unsavedInventoryClassification!.copyWith(
                              hasShelfLife: value,
                              hasExpiryDate: value
                                  ? false
                                  : _unsavedInventoryClassification!.hasExpiryDate,
                              shelfLifeValue: value
                                  ? _unsavedInventoryClassification!.shelfLifeValue
                                  : null,
                              shelfLifeUnit: value
                                  ? _unsavedInventoryClassification!.shelfLifeUnit ?? 'days'
                                  : null,
                            );
                            _updateUnsavedInventoryClassification(updatedInventoryClassification);
                          }
                        },
                      ),
                    ),
                  ],
                ),
                if (_unsavedInventoryClassification!.hasShelfLife == true) ...[
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: TextFormField(
                          decoration: const InputDecoration(
                            labelText: 'Shelf Life Duration',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                          controller: _shelfLifeValueController,
                          onChanged: (value) {
                            final intValue = int.tryParse(value);
                            final updatedInventoryClassification = _unsavedInventoryClassification!.copyWith(
                              shelfLifeValue: intValue,
                            );
                            _updateUnsavedInventoryClassification(updatedInventoryClassification);
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          decoration: const InputDecoration(
                            labelText: 'Unit',
                            border: OutlineInputBorder(),
                          ),
                          value: _unsavedInventoryClassification!.shelfLifeUnit ?? 'days',
                          items: const [
                            DropdownMenuItem(
                                value: 'days', child: Text('Days')),
                            DropdownMenuItem(
                                value: 'months', child: Text('Months')),
                            DropdownMenuItem(
                                value: 'years', child: Text('Years')),
                          ],
                          onChanged: (value) {
                            if (value != null) {
                              final updatedInventoryClassification =
                                  _unsavedInventoryClassification!.copyWith(
                                shelfLifeUnit: value,
                              );
                              _updateUnsavedInventoryClassification(updatedInventoryClassification);
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final inventoryClassifications = ref.watch(inventoryClassificationListProvider);
    final subCategories = ref.watch(subCategoryListProvider);

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Inventory Classification'),
          actions: [
            if (_hasUnsavedChanges)
              TextButton.icon(
                onPressed: () {
                  _saveChanges();
                  setState(() {
                    _selectedInventoryClassification = _unsavedInventoryClassification;
                    _unsavedInventoryClassification = InventoryClassification(
                      name: _selectedInventoryClassification!.name,
                      requiresQualityCheck:
                          _selectedInventoryClassification!.requiresQualityCheck,
                      sampleSizeLessThan100:
                          _selectedInventoryClassification!.sampleSizeLessThan100,
                      sampleSize100To500: _selectedInventoryClassification!.sampleSize100To500,
                      sampleSizeGreaterThan500:
                          _selectedInventoryClassification!.sampleSizeGreaterThan500,
                      hasExpiryDate: _selectedInventoryClassification!.hasExpiryDate,
                      hasShelfLife: _selectedInventoryClassification!.hasShelfLife,
                      shelfLifeValue: _selectedInventoryClassification!.shelfLifeValue,
                      shelfLifeUnit: _selectedInventoryClassification!.shelfLifeUnit,
                    );
                    _hasUnsavedChanges = false;
                  });
                },
                icon: const Icon(Icons.save, color: Colors.white),
                label: const Text('Save Changes',
                    style: TextStyle(color: Colors.white)),
              ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildSection(
                'Inventory Classification',
                inventoryClassifications,
                (name) {
                  ref.read(inventoryClassificationListProvider.notifier).addInventoryClassification(name);
                },
                onDelete: (inventoryClassification) {
                  ref
                      .read(inventoryClassificationListProvider.notifier)
                      .deleteInventoryClassification(inventoryClassification);
                  if (_selectedInventoryClassification == inventoryClassification) {
                    setState(() {
                      _selectedInventoryClassification = null;
                      _unsavedInventoryClassification = null;
                      _hasUnsavedChanges = false;
                    });
                  }
                },
              ),
              if (_selectedInventoryClassification != null) ...[
                _buildSection(
                  'Sub-Category',
                  subCategories
                      .where((sc) => sc.categoryName == _selectedInventoryClassification!.name)
                      .toList(),
                  (name) {
                    ref.read(subCategoryListProvider.notifier).addSubCategory(
                          name,
                          _selectedInventoryClassification!.name,
                        );
                  },
                  onDelete: (subCategory) {
                    ref
                        .read(subCategoryListProvider.notifier)
                        .deleteSubCategory(subCategory);
                  },
                ),
                _buildQualityParameterSection(),
                if (_unsavedInventoryClassification?.requiresQualityCheck == true) ...[
                  _buildSamplePlanSection(),
                  _buildExpiryShelfLifeSection(),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }
}
