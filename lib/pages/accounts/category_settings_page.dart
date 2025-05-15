import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../provider/category_provider.dart';
import '../../provider/sub_category_provider.dart';
import '../../provider/category_parameter_provider.dart';
import '../../provider/universal_parameter_provider.dart';
import '../../models/category.dart';
import '../../models/category_parameter_mapping.dart';

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
                    title: const Text('Requires Expiry Date'),
                    subtitle: const Text(
                        'Enable if materials in this category need expiration date tracking'),
                    value: mappings
                        .firstWhere(
                          (m) => m.category == _selectedCategory!.name,
                          orElse: () => CategoryParameterMapping(
                            category: _selectedCategory!.name,
                            parameters: [],
                            requiresExpiryDate: false,
                          ),
                        )
                        .requiresExpiryDate,
                    onChanged: (value) {
                      final mapping = mappings.firstWhere(
                        (m) => m.category == _selectedCategory!.name,
                        orElse: () => CategoryParameterMapping(
                          category: _selectedCategory!.name,
                          parameters: [],
                          requiresExpiryDate: false,
                        ),
                      );
                      mapping.requiresExpiryDate = value;
                      ref
                          .read(categoryParameterProvider.notifier)
                          .updateMapping(mapping);
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

  @override
  Widget build(BuildContext context) {
    final categories = ref.watch(categoryListProvider);
    final subCategories = ref.watch(subCategoryListProvider);

    final filteredSubCategories = _selectedCategory != null
        ? subCategories
            .where((sc) => sc.categoryName == _selectedCategory!.name)
            .toList()
        : subCategories;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Category Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSection(
            'Category',
            categories,
            (name) => ref.read(categoryListProvider.notifier).addCategory(name),
            onDelete: (category) => ref
                .read(categoryListProvider.notifier)
                .deleteCategory(category),
          ),
          _buildSection(
            'Sub-Category',
            _selectedCategory != null ? filteredSubCategories : [],
            (name) => ref
                .read(subCategoryListProvider.notifier)
                .addSubCategory(name, _selectedCategory?.name ?? ''),
            onDelete: (subCategory) => ref
                .read(subCategoryListProvider.notifier)
                .deleteSubCategory(subCategory),
          ),
          if (_selectedCategory == null)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                'Select a category to manage its sub-categories',
                style:
                    TextStyle(color: Colors.grey, fontStyle: FontStyle.italic),
              ),
            ),
          _buildQualityParameterSection(),
        ],
      ),
    );
  }
}
