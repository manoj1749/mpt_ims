import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../provider/category_provider.dart';
import '../../provider/sub_category_provider.dart';
import '../../provider/category_parameter_provider.dart';
import '../../provider/universal_parameter_provider.dart';
import '../../models/category.dart';
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
  Category? _selectedCategory;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _printBoxContents();
    });
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
      final mappingBox = Hive.box<CategoryParameterMapping>('categoryParameterMappings');
      print('\n-- Category Parameter Mappings Box Contents --');
      for (var mapping in mappingBox.values) {
        print('''
Mapping for Category: ${mapping.category}
- Parameters: ${mapping.parameters}
- Requires Expiry Date: ${mapping.requiresExpiryDate}
''');
      }
    } else {
      print('Category Parameter Mappings box is not open');
    }

    print('\n==== END CATEGORY SETTINGS DATA ====\n');
  }

  @override
  void dispose() {
    _categoryController.dispose();
    _subCategoryController.dispose();
    _parameterController.dispose();
    super.dispose();
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
                      ? () =>
                          setState(() => _selectedCategory = item as Category)
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
    await ref.read(categoryListProvider.notifier).updateCategory(updatedCategory);
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
                      _printBoxContents(); // Print contents after adding parameter
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
                  value: _selectedCategory?.requiresQualityCheck ?? true,
                  onChanged: (value) {
                    final updatedCategory = _selectedCategory!.copyWith(
                      requiresQualityCheck: value,
                      sampleSizeLessThan100: value ? _selectedCategory!.sampleSizeLessThan100 : null,
                      sampleSize100To500: value ? _selectedCategory!.sampleSize100To500 : null,
                      sampleSizeGreaterThan500: value ? _selectedCategory!.sampleSizeGreaterThan500 : null,
                      hasExpiryDate: value ? _selectedCategory!.hasExpiryDate : false,
                      hasShelfLife: value ? _selectedCategory!.hasShelfLife : false,
                      shelfLifeValue: value ? _selectedCategory!.shelfLifeValue : null,
                      shelfLifeUnit: value ? _selectedCategory!.shelfLifeUnit : null,
                    );
                    _updateCategory(updatedCategory);
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
                        final isSelected = mappings.any((m) =>
                            m.category == _selectedCategory!.name &&
                            m.parameters.contains(param.name));

                        return FilterChip(
                          label: Text(param.name),
                          selected: isSelected,
                          onSelected: (selected) {
                            final mapping = mappings.firstWhere(
                              (m) => m.category == _selectedCategory!.name,
                              orElse: () => CategoryParameterMapping(
                                category: _selectedCategory!.name,
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
                  const SizedBox(height: 16),
                  SwitchListTile(
                    title: const Text('Requires Quality Check'),
                    subtitle: const Text(
                        'Enable if materials in this category require quality inspection'),
                    value: _selectedCategory?.requiresQualityCheck ?? true,
                    onChanged: (value) {
                      setState(() {
                        _selectedCategory?.requiresQualityCheck = value;
                        ref
                            .read(categoryListProvider.notifier)
                            .updateCategory(_selectedCategory!);
                      });
                    },
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
    if (_selectedCategory == null) return const SizedBox.shrink();

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
                  initialValue: _selectedCategory!.sampleSizeLessThan100?.toString() ?? '',
                  onChanged: (value) {
                    final intValue = int.tryParse(value);
                    if (intValue != null) {
                      final updatedCategory = _selectedCategory!.copyWith(
                        sampleSizeLessThan100: intValue,
                      );
                      _updateCategory(updatedCategory);
                    }
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Sample Size for Qty 100-500',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  initialValue: _selectedCategory!.sampleSize100To500?.toString() ?? '',
                  onChanged: (value) {
                    final intValue = int.tryParse(value);
                    if (intValue != null) {
                      final updatedCategory = _selectedCategory!.copyWith(
                        sampleSize100To500: intValue,
                      );
                      _updateCategory(updatedCategory);
                    }
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Sample Size for Qty > 500',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  initialValue: _selectedCategory!.sampleSizeGreaterThan500?.toString() ?? '',
                  onChanged: (value) {
                    final intValue = int.tryParse(value);
                    if (intValue != null) {
                      final updatedCategory = _selectedCategory!.copyWith(
                        sampleSizeGreaterThan500: intValue,
                      );
                      _updateCategory(updatedCategory);
                    }
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
    if (_selectedCategory == null) return const SizedBox.shrink();

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
                        value: _selectedCategory!.hasExpiryDate ?? false,
                        onChanged: (value) {
                          if (value != null) {
                            final updatedCategory = _selectedCategory!.copyWith(
                              hasExpiryDate: value,
                              hasShelfLife: false,
                              shelfLifeValue: null,
                              shelfLifeUnit: null,
                            );
                            _updateCategory(updatedCategory);
                          }
                        },
                      ),
                    ),
                    Expanded(
                      child: CheckboxListTile(
                        title: const Text('Has Shelf Life'),
                        value: _selectedCategory!.hasShelfLife ?? false,
                        onChanged: (value) {
                          if (value != null) {
                            final updatedCategory = _selectedCategory!.copyWith(
                              hasShelfLife: value,
                              hasExpiryDate: false,
                              shelfLifeValue: value ? _selectedCategory!.shelfLifeValue : null,
                              shelfLifeUnit: value ? _selectedCategory!.shelfLifeUnit : null,
                            );
                            _updateCategory(updatedCategory);
                          }
                        },
                      ),
                    ),
                  ],
                ),
                if (_selectedCategory!.hasShelfLife == true) ...[
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
                          initialValue: _selectedCategory!.shelfLifeValue?.toString() ?? '',
                          onChanged: (value) {
                            final intValue = int.tryParse(value);
                            if (intValue != null) {
                              final updatedCategory = _selectedCategory!.copyWith(
                                shelfLifeValue: intValue,
                              );
                              _updateCategory(updatedCategory);
                            }
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
                          value: _selectedCategory!.shelfLifeUnit ?? 'days',
                          items: const [
                            DropdownMenuItem(value: 'days', child: Text('Days')),
                            DropdownMenuItem(value: 'months', child: Text('Months')),
                            DropdownMenuItem(value: 'years', child: Text('Years')),
                          ],
                          onChanged: (value) {
                            if (value != null) {
                              final updatedCategory = _selectedCategory!.copyWith(
                                shelfLifeUnit: value,
                              );
                              _updateCategory(updatedCategory);
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
    final categories = ref.watch(categoryListProvider);
    final subCategories = ref.watch(subCategoryListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Category Settings'),
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
                ref.read(categoryListProvider.notifier).deleteCategory(category);
                if (_selectedCategory == category) {
                  setState(() => _selectedCategory = null);
                }
              },
            ),
            if (_selectedCategory != null) ...[
              _buildSection(
                'Sub-Category',
                subCategories.where((sc) => sc.categoryName == _selectedCategory!.name).toList(),
                (name) {
                  ref.read(subCategoryListProvider.notifier).addSubCategory(
                    name,
                    _selectedCategory!.name,
                  );
                },
                onDelete: (subCategory) {
                  ref.read(subCategoryListProvider.notifier).deleteSubCategory(subCategory);
                },
              ),
              _buildQualityParameterSection(),
              if (_selectedCategory?.requiresQualityCheck == true) ...[
                _buildSamplePlanSection(),
                _buildExpiryShelfLifeSection(),
              ],
            ],
          ],
        ),
      ),
    );
  }
}
