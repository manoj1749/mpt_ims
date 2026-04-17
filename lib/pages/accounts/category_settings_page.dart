// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../provider/category_provider.dart';
import '../../provider/sub_category_provider.dart';
import '../../provider/category_parameter_provider.dart';
import '../../provider/universal_parameter_provider.dart';
import '../../models/category.dart';
import '../../models/sub_category.dart';
import '../../models/category_parameter_mapping.dart';
import 'package:hive/hive.dart';

class CategorySettingsPage extends ConsumerStatefulWidget {
  const CategorySettingsPage({super.key});

  @override
  ConsumerState<CategorySettingsPage> createState() =>
      _CategorySettingsPageState();
}

class _CategorySettingsPageState extends ConsumerState<CategorySettingsPage> {
  final _categoryController = TextEditingController();
  final _subCategoryController = TextEditingController();
  final _parameterController = TextEditingController();

  // Sample size controllers
  final _sampleSizeLessThan100Controller = TextEditingController();
  final _sampleSize100To500Controller = TextEditingController();
  final _sampleSizeGreaterThan500Controller = TextEditingController();
  final _shelfLifeValueController = TextEditingController();

  Category? _selectedCategory;
  Category? _unsavedCategory;
  bool _hasUnsavedChanges = false;
  bool _hasUnsavedParameterChanges = false;
  Set<String> _unsavedParameters = {};
  bool _unsavedRequiresExpiryDate = false;

  bool _hasUnsavedSubCategoryChanges = false;
  final Set<String> _pendingSubCategoryAdds = {};
  final Set<String> _pendingSubCategoryDeletes = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        // Load all required data
        await ref.read(categoryListProvider.notifier).loadCategories();
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
    _categoryController.dispose();
    _subCategoryController.dispose();
    _parameterController.dispose();
    _sampleSizeLessThan100Controller.dispose();
    _sampleSize100To500Controller.dispose();
    _sampleSizeGreaterThan500Controller.dispose();
    _shelfLifeValueController.dispose();
    super.dispose();
  }

  Future<void> _refreshData() async {
    await ref.read(categoryListProvider.notifier).refresh();
    await ref.read(subCategoryListProvider.notifier).refresh();
    await ref.read(categoryParameterProvider.notifier).refresh();
    await ref.read(universalParameterProvider.notifier).refresh();
  }

  void _printBoxContents() {
    print('\n==== PRINTING CATEGORY SETTINGS DATA ====');

    // Print Categories
    if (Hive.isBoxOpen('categories')) {
      final categoryBox = Hive.box<Category>('categories');
      print('\n-- Categories Box Contents --');
      for (var category in categoryBox.values) {
        print('''
Category: ${category.name}
- Requires Quality Check: ${category.requiresQualityCheck}
- Sample Size <100: ${category.sampleSizeLessThan100}
- Sample Size 100-500: ${category.sampleSize100To500}
- Sample Size >500: ${category.sampleSizeGreaterThan500}
- Has Expiry Date: ${category.hasExpiryDate}
- Has Shelf Life: ${category.hasShelfLife}
- Shelf Life Value: ${category.shelfLifeValue}
- Shelf Life Unit: ${category.shelfLifeUnit}
''');
      }
    } else {
      print('Categories box is not open');
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

    print('\n==== END CATEGORY SETTINGS DATA ====\n');
  }

  void _showAddDialog(String title, String hint, Function(String) onAdd) {
    final controller = title == 'Category'
        ? _categoryController
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
    if (_hasUnsavedChanges || _hasUnsavedParameterChanges || _hasUnsavedSubCategoryChanges) {
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

  void _onCategorySelected(Category category) {
    if (_hasUnsavedChanges) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Unsaved Changes'),
          content: const Text('Save changes before switching categories?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                setState(() {
                  _selectedCategory = category;
                  _unsavedCategory = Category(
                    name: category.name,
                    requiresQualityCheck: category.requiresQualityCheck,
                    sampleSizeLessThan100: category.sampleSizeLessThan100,
                    sampleSize100To500: category.sampleSize100To500,
                    sampleSizeGreaterThan500: category.sampleSizeGreaterThan500,
                    hasExpiryDate: category.hasExpiryDate,
                    hasShelfLife: category.hasShelfLife,
                    shelfLifeValue: category.shelfLifeValue,
                    shelfLifeUnit: category.shelfLifeUnit,
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
                  _selectedCategory = category;
                  _unsavedCategory = Category(
                    name: category.name,
                    requiresQualityCheck: category.requiresQualityCheck,
                    sampleSizeLessThan100: category.sampleSizeLessThan100,
                    sampleSize100To500: category.sampleSize100To500,
                    sampleSizeGreaterThan500: category.sampleSizeGreaterThan500,
                    hasExpiryDate: category.hasExpiryDate,
                    hasShelfLife: category.hasShelfLife,
                    shelfLifeValue: category.shelfLifeValue,
                    shelfLifeUnit: category.shelfLifeUnit,
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
        _selectedCategory = category;
        _unsavedCategory = Category(
          name: category.name,
          requiresQualityCheck: category.requiresQualityCheck,
          sampleSizeLessThan100: category.sampleSizeLessThan100,
          sampleSize100To500: category.sampleSize100To500,
          sampleSizeGreaterThan500: category.sampleSizeGreaterThan500,
          hasExpiryDate: category.hasExpiryDate,
          hasShelfLife: category.hasShelfLife,
          shelfLifeValue: category.shelfLifeValue,
          shelfLifeUnit: category.shelfLifeUnit,
        );
        final mappings = ref.read(categoryParameterProvider);
        final mapping = mappings.firstWhere(
          (m) => m.category == category.name,
          orElse: () => CategoryParameterMapping(
            category: category.name,
            parameters: [],
            requiresExpiryDate: false,
          ),
        );
        _unsavedParameters = Set<String>.from(mapping.parameters);
        _unsavedRequiresExpiryDate = mapping.requiresExpiryDate;
        _hasUnsavedParameterChanges = false;

        _pendingSubCategoryAdds.clear();
        _pendingSubCategoryDeletes.clear();
        _hasUnsavedSubCategoryChanges = false;
      });
      _updateTextControllers(category);
    }
  }

  Future<void> _saveChanges() async {
    if (_unsavedCategory != null) {
      await ref.read(categoryListProvider.notifier).updateCategory(_unsavedCategory!);
      setState(() {
        _selectedCategory = _unsavedCategory!.copyWith();
        _hasUnsavedChanges = false;
      });
      _updateTextControllers(_selectedCategory!);
      _printBoxContents();
    }

    if (_selectedCategory != null && _hasUnsavedParameterChanges) {
      final mappings = ref.read(categoryParameterProvider);
      final existing = mappings.firstWhere(
        (m) => m.category == _selectedCategory!.name,
        orElse: () => CategoryParameterMapping(
          category: _selectedCategory!.name,
          parameters: [],
          requiresExpiryDate: false,
        ),
      );

      final updatedMapping = CategoryParameterMapping(
        category: existing.category,
        parameters: _unsavedParameters.toList(),
        requiresExpiryDate: _unsavedRequiresExpiryDate,
        lastModified: existing.lastModified,
      );
      await ref.read(categoryParameterProvider.notifier).updateMapping(updatedMapping);
      setState(() {
        _hasUnsavedParameterChanges = false;
      });
    }

    if (_selectedCategory != null && _hasUnsavedSubCategoryChanges) {
      final catName = _selectedCategory!.name;
      final existingSubs = ref
          .read(subCategoryListProvider)
          .where((sc) => sc.categoryName == catName)
          .toList();

      // Apply deletes first
      for (final name in _pendingSubCategoryDeletes) {
        final toDelete = existingSubs.where((sc) => sc.name == name).toList();
        for (final sc in toDelete) {
          await ref.read(subCategoryListProvider.notifier).deleteSubCategory(sc);
        }
      }

      // Apply adds
      for (final name in _pendingSubCategoryAdds) {
        await ref.read(subCategoryListProvider.notifier).addSubCategory(name, catName);
      }

      if (mounted) {
        setState(() {
          _pendingSubCategoryAdds.clear();
          _pendingSubCategoryDeletes.clear();
          _hasUnsavedSubCategoryChanges = false;
        });
      }
    }
  }

  void _updateTextControllers(Category category) {
    _sampleSizeLessThan100Controller.text =
        category.sampleSizeLessThan100?.toString() ?? '';
    _sampleSize100To500Controller.text =
        category.sampleSize100To500?.toString() ?? '';
    _sampleSizeGreaterThan500Controller.text =
        category.sampleSizeGreaterThan500?.toString() ?? '';
    _shelfLifeValueController.text = category.shelfLifeValue?.toString() ?? '';
  }

  void _updateUnsavedCategory(Category updatedCategory) {
    setState(() {
      _unsavedCategory = updatedCategory;
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
                  onTap: title == 'Category'
                      ? () => _onCategorySelected(item as Category)
                      : null,
                  selected: title == 'Category' && item == _selectedCategory,
                );
              },
            ),
        ],
      ),
    );
  }

  Future<void> _updateCategory(Category updatedCategory) async {
    await ref
        .read(categoryListProvider.notifier)
        .updateCategory(updatedCategory);
    setState(() => _selectedCategory = updatedCategory);
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
                      'Enable if materials in this category require quality inspection'),
                  value: _unsavedCategory?.requiresQualityCheck ?? true,
                  onChanged: (value) {
                    final updatedCategory = _unsavedCategory!.copyWith(
                      requiresQualityCheck: value,
                    );
                    _updateUnsavedCategory(updatedCategory);
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
                          // Remove this parameter from all category mappings
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
                if (_selectedCategory == null)
                  const Text(
                    'Select a category to manage its parameters',
                    style: TextStyle(
                        color: Colors.grey, fontStyle: FontStyle.italic),
                  )
                else ...[
                  Text(
                    'Parameters for ${_selectedCategory!.name}',
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
                        final isSelected = _unsavedParameters.contains(param.name);

                        return FilterChip(
                          label: Text(param.name),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() {
                              final newParams = Set<String>.from(_unsavedParameters);
                              if (selected) {
                                newParams.add(param.name);
                              } else {
                                newParams.remove(param.name);
                              }
                              _unsavedParameters = newParams;
                              _hasUnsavedParameterChanges = true;
                            });
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
    if (_unsavedCategory == null) return const SizedBox.shrink();

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
                    final updatedCategory = _unsavedCategory!.copyWith(
                      sampleSizeLessThan100: intValue,
                    );
                    _updateUnsavedCategory(updatedCategory);
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
                    final updatedCategory = _unsavedCategory!.copyWith(
                      sampleSize100To500: intValue,
                    );
                    _updateUnsavedCategory(updatedCategory);
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
                    final updatedCategory = _unsavedCategory!.copyWith(
                      sampleSizeGreaterThan500: intValue,
                    );
                    _updateUnsavedCategory(updatedCategory);
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
    if (_unsavedCategory == null) return const SizedBox.shrink();

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
                // Master toggle for expiry/shelf life tracking
                SwitchListTile(
                  title: const Text('Requires Expiry/Shelf Life Tracking'),
                  subtitle: const Text(
                      'Enable if materials in this category require expiry or shelf life management'),
                  value: (_unsavedCategory!.hasExpiryDate == true || _unsavedCategory!.hasShelfLife == true),
                  onChanged: (value) {
                    if (value) {
                      // If enabling, default to expiry date
                      final updatedCategory = _unsavedCategory!.copyWith(
                        hasExpiryDate: true,
                        hasShelfLife: false,
                      );
                      _updateUnsavedCategory(updatedCategory);
                    } else {
                      // If disabling, turn off both expiry and shelf life
                      final updatedCategory = _unsavedCategory!.copyWith(
                        hasExpiryDate: false,
                        hasShelfLife: false,
                        shelfLifeValue: null,
                        shelfLifeUnit: null,
                      );
                      _updateUnsavedCategory(updatedCategory);
                    }
                    
                    setState(() {
                      _unsavedRequiresExpiryDate =
                          value && _unsavedCategory!.hasExpiryDate == true;
                      _hasUnsavedParameterChanges = true;
                    });
                  },
                ),
                const SizedBox(height: 16),
                // Show expiry/shelf life options only if tracking is enabled
                if (_unsavedCategory!.hasExpiryDate == true || _unsavedCategory!.hasShelfLife == true) ...[
                  Row(
                    children: [
                      Expanded(
                        child: CheckboxListTile(
                          title: const Text('Has Expiry Date'),
                          value: _unsavedCategory!.hasExpiryDate,
                          onChanged: (value) {
                            if (value != null) {
                              final updatedCategory = _unsavedCategory!.copyWith(
                                hasExpiryDate: value,
                                hasShelfLife: value
                                    ? false
                                    : _unsavedCategory!.hasShelfLife,
                              );
                              _updateUnsavedCategory(updatedCategory);

                              setState(() {
                                _unsavedRequiresExpiryDate = value;
                                _hasUnsavedParameterChanges = true;
                              });
                            }
                          },
                        ),
                      ),
                      Expanded(
                        child: CheckboxListTile(
                          title: const Text('Has Shelf Life'),
                          value: _unsavedCategory!.hasShelfLife,
                          onChanged: (value) {
                            if (value != null) {
                              final updatedCategory = _unsavedCategory!.copyWith(
                                hasShelfLife: value,
                                hasExpiryDate: value
                                    ? false
                                    : _unsavedCategory!.hasExpiryDate,
                                shelfLifeValue: value
                                    ? _unsavedCategory!.shelfLifeValue
                                    : null,
                                shelfLifeUnit: value
                                    ? _unsavedCategory!.shelfLifeUnit ?? 'days'
                                    : null,
                              );
                              _updateUnsavedCategory(updatedCategory);
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                if (_unsavedCategory!.hasShelfLife == true) ...[
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
                            final updatedCategory = _unsavedCategory!.copyWith(
                              shelfLifeValue: intValue,
                            );
                            _updateUnsavedCategory(updatedCategory);
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
                          value: _unsavedCategory!.shelfLifeUnit ?? 'days',
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
                              final updatedCategory =
                                  _unsavedCategory!.copyWith(
                                shelfLifeUnit: value,
                              );
                              _updateUnsavedCategory(updatedCategory);
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ],
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
    final categories = ref.watch(categoryListProvider);
    final subCategories = ref.watch(subCategoryListProvider);

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Category Settings'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () async {
              final shouldPop = await _onWillPop();
              if (shouldPop && mounted) {
                Navigator.of(context).pop();
              }
            },
          ),
          actions: [
            TextButton.icon(
              onPressed: () async {
                if (!_hasUnsavedChanges &&
                    !_hasUnsavedParameterChanges &&
                    !_hasUnsavedSubCategoryChanges) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('No changes to save')),
                  );
                  return;
                }

                await _saveChanges();

                if (!mounted) return;
                setState(() {
                  _selectedCategory = _unsavedCategory;
                  if (_selectedCategory != null) {
                    _unsavedCategory = Category(
                      name: _selectedCategory!.name,
                      requiresQualityCheck: _selectedCategory!.requiresQualityCheck,
                      sampleSizeLessThan100: _selectedCategory!.sampleSizeLessThan100,
                      sampleSize100To500: _selectedCategory!.sampleSize100To500,
                      sampleSizeGreaterThan500: _selectedCategory!.sampleSizeGreaterThan500,
                      hasExpiryDate: _selectedCategory!.hasExpiryDate,
                      hasShelfLife: _selectedCategory!.hasShelfLife,
                      shelfLifeValue: _selectedCategory!.shelfLifeValue,
                      shelfLifeUnit: _selectedCategory!.shelfLifeUnit,
                    );
                  }
                  _hasUnsavedChanges = false;
                });

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Saved successfully')),
                );
              },
              icon: const Icon(Icons.save, color: Colors.white),
              label:
                  const Text('Save', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildSection(
                'Category',
                categories,
                (name) {
                  ref.read(categoryListProvider.notifier).addCategory(name);
                },
                onDelete: (category) {
                  ref
                      .read(categoryListProvider.notifier)
                      .deleteCategory(category);
                  if (_selectedCategory == category) {
                    setState(() {
                      _selectedCategory = null;
                      _unsavedCategory = null;
                      _hasUnsavedChanges = false;
                    });
                  }
                },
              ),
              if (_selectedCategory != null) ...[
                _buildSection(
                  'Sub-Category',
                  () {
                    final catName = _selectedCategory!.name;
                    final existing = subCategories
                        .where((sc) => sc.categoryName == catName)
                        .map((sc) => sc.name)
                        .toSet();

                    final pendingAdds = Set<String>.from(_pendingSubCategoryAdds);
                    final pendingDeletes = Set<String>.from(_pendingSubCategoryDeletes);

                    final visibleExisting = existing
                        .where((name) => !pendingDeletes.contains(name))
                        .map((name) => SubCategory(name: name, categoryName: catName));

                    final visibleAdds = pendingAdds
                        .where((name) => !existing.contains(name))
                        .where((name) => !pendingDeletes.contains(name))
                        .map((name) => SubCategory(name: name, categoryName: catName));

                    final all = [...visibleExisting, ...visibleAdds]
                      ..sort((a, b) => a.name.compareTo(b.name));
                    return all;
                  }(),
                  (name) {
                    final trimmed = name.trim();
                    if (trimmed.isEmpty) return;
                    setState(() {
                      _pendingSubCategoryAdds.add(trimmed);
                      _pendingSubCategoryDeletes.remove(trimmed);
                      _hasUnsavedSubCategoryChanges = true;
                    });
                  },
                  onDelete: (subCategory) {
                    final name = (subCategory as SubCategory).name;
                    setState(() {
                      // If it was a newly-added (pending) subcategory, just unstage it
                      if (_pendingSubCategoryAdds.remove(name)) {
                        // nothing else
                      } else {
                        _pendingSubCategoryDeletes.add(name);
                      }
                      _hasUnsavedSubCategoryChanges =
                          _pendingSubCategoryAdds.isNotEmpty ||
                              _pendingSubCategoryDeletes.isNotEmpty;
                    });
                  },
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
