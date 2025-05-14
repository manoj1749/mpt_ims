import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../provider/category_provider.dart';
import '../../provider/sub_category_provider.dart';
import '../../provider/quality_provider.dart';
import '../../models/category.dart';
import '../../models/sub_category.dart';
import '../../models/quality.dart';

class CategorySettingsPage extends ConsumerStatefulWidget {
  const CategorySettingsPage({super.key});

  @override
  ConsumerState<CategorySettingsPage> createState() =>
      _CategorySettingsPageState();
}

class _CategorySettingsPageState extends ConsumerState<CategorySettingsPage> {
  final _categoryController = TextEditingController();
  final _subCategoryController = TextEditingController();
  final _qualityController = TextEditingController();
  Category? _selectedCategory;

  @override
  void dispose() {
    _categoryController.dispose();
    _subCategoryController.dispose();
    _qualityController.dispose();
    super.dispose();
  }

  void _showAddDialog(String title, String hint, Function(String) onAdd) {
    if (title == 'Sub-Category' && _selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a category first'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Add $title'),
        content: TextField(
          controller: title == 'Category'
              ? _categoryController
              : title == 'Sub-Category'
                  ? _subCategoryController
                  : _qualityController,
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
              final text = title == 'Category'
                  ? _categoryController.text
                  : title == 'Sub-Category'
                      ? _subCategoryController.text
                      : _qualityController.text;
              if (text.isNotEmpty) {
                onAdd(text);
                Navigator.pop(context);
                if (title == 'Category') {
                  _categoryController.clear();
                } else if (title == 'Sub-Category') {
                  _subCategoryController.clear();
                } else {
                  _qualityController.clear();
                }
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

  @override
  Widget build(BuildContext context) {
    final categories = ref.watch(categoryListProvider);
    final subCategories = ref.watch(subCategoryListProvider);
    final qualities = ref.watch(qualityListProvider);

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
          _buildSection(
            'Quality',
            qualities,
            (name) => ref.read(qualityListProvider.notifier).addQuality(name),
            onDelete: (quality) =>
                ref.read(qualityListProvider.notifier).deleteQuality(quality),
          ),
        ],
      ),
    );
  }
}
