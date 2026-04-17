// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import '../../provider/category_provider.dart';
import '../../provider/sub_category_provider.dart';
import '../../provider/category_parameter_provider.dart';
import '../../provider/universal_parameter_provider.dart';
import '../../models/category.dart';
import '../../models/sub_category.dart';
import '../../models/category_parameter_mapping.dart';

class QualityCategorySettingsPage extends ConsumerStatefulWidget {
  const QualityCategorySettingsPage({super.key});

  @override
  ConsumerState<QualityCategorySettingsPage> createState() => _QualityCategorySettingsPageState();
}

class _QualityCategorySettingsPageState extends ConsumerState<QualityCategorySettingsPage> {
  final _sampleSizeLessThan100Controller = TextEditingController();
  final _sampleSize100To500Controller = TextEditingController();
  final _sampleSizeGreaterThan500Controller = TextEditingController();
  final _shelfLifeValueController = TextEditingController();

  Category? _selectedCategory;
  Category? _unsavedCategory;
  bool _hasUnsavedChanges = false;
  bool _hasUnsavedParameterChanges = false;

  bool _hasUnsavedSubCategoryChanges = false;
  final Set<String> _pendingSubCategoryAdds = {};
  final Set<String> _pendingSubCategoryDeletes = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        await ref.read(categoryListProvider.notifier).loadCategories();
        await ref.read(subCategoryListProvider.notifier).loadSubCategories();
        await ref.read(categoryParameterProvider.notifier).loadMappings();
        await ref.read(universalParameterProvider.notifier).loadParameters();
        // Auto-select first category so parameters are visible immediately
        final cats = ref.read(categoryListProvider);
        if (cats.isNotEmpty) {
          _onCategorySelected(cats.first);
        }
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
    _sampleSizeLessThan100Controller.dispose();
    _sampleSize100To500Controller.dispose();
    _sampleSizeGreaterThan500Controller.dispose();
    _shelfLifeValueController.dispose();
    super.dispose();
  }

  void _printBoxContents() {
    print('\n==== PRINTING QUALITY CATEGORY SETTINGS DATA ====');
    if (Hive.isBoxOpen('category_parameter_mappings')) {
      final box = Hive.box<CategoryParameterMapping>('category_parameter_mappings');
      for (var mapping in box.values) {
        print('Mapping: ${mapping.category} -> ${mapping.parameters} | requiresExpiryDate: ${mapping.requiresExpiryDate} | lastModified: ${mapping.lastModified}');
      }
    }
  }

  void _updateUnsavedCategory(Category updated) {
    setState(() {
      _unsavedCategory = updated;
      _hasUnsavedChanges = true;
    });
  }

  void _markParametersDirty() {
    if (!mounted) return;
    setState(() {
      _hasUnsavedParameterChanges = true;
    });
  }

  void _onCategorySelected(Category category) {
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
      _hasUnsavedParameterChanges = false;
      _updateTextControllers(category);
      
      // Reset subcategory changes
      _pendingSubCategoryAdds.clear();
      _pendingSubCategoryDeletes.clear();
      _hasUnsavedSubCategoryChanges = false;
    });
  }

  void _updateTextControllers(Category category) {
    _sampleSizeLessThan100Controller.text = category.sampleSizeLessThan100?.toString() ?? '';
    _sampleSize100To500Controller.text = category.sampleSize100To500?.toString() ?? '';
    _sampleSizeGreaterThan500Controller.text = category.sampleSizeGreaterThan500?.toString() ?? '';
    _shelfLifeValueController.text = category.shelfLifeValue?.toString() ?? '';
  }

  Future<void> _saveChanges() async {
    if (_unsavedCategory != null) {
      await ref.read(categoryListProvider.notifier).updateCategory(_unsavedCategory!);
      setState(() {
        _selectedCategory = _unsavedCategory!.copyWith();
        _hasUnsavedChanges = false;
        _hasUnsavedParameterChanges = false;
      });
      _updateTextControllers(_selectedCategory!);
      _printBoxContents();
    }

    // Save subcategory changes
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

  Widget _buildCategoryList() {
    final categories = ref.watch(categoryListProvider);
    return Card(
      margin: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.black,
            child: const Text(
              'Categories',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
          if (categories.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('No categories found', style: TextStyle(color: Colors.grey)),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: categories.length,
              itemBuilder: (context, index) {
                final cat = categories[index];
                return ListTile(
                  title: Text(cat.name),
                  onTap: () => _onCategorySelected(cat),
                  selected: cat.name == _selectedCategory?.name,
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildSubCategorySection() {
    final subCategories = ref.watch(subCategoryListProvider);
    
    if (_selectedCategory == null) return const SizedBox.shrink();
    
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
                  'Sub-Categories',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                ),
                IconButton(
                  icon: const Icon(Icons.add, color: Colors.white),
                  tooltip: 'Add Sub-Category',
                  onPressed: () {
                    final controller = TextEditingController();
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        backgroundColor: Colors.grey[850],
                        title: const Text('Add Sub-Category', style: TextStyle(color: Colors.white)),
                        content: TextField(
                          controller: controller,
                          style: const TextStyle(color: Colors.white),
                          decoration: const InputDecoration(
                            hintText: 'Enter sub-category name',
                            hintStyle: TextStyle(color: Colors.grey),
                            border: OutlineInputBorder(),
                          ),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
                          ),
                          TextButton(
                            onPressed: () {
                              final text = controller.text.trim();
                              if (text.isNotEmpty) {
                                setState(() {
                                  _pendingSubCategoryAdds.add(text);
                                  _pendingSubCategoryDeletes.remove(text);
                                  _hasUnsavedSubCategoryChanges = true;
                                });
                                Navigator.pop(context);
                              }
                            },
                            child: const Text('Add', style: TextStyle(color: Colors.blue)),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          if (all.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('No sub-categories added yet', style: TextStyle(color: Colors.grey)),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: all.length,
              itemBuilder: (context, index) {
                final subCat = all[index];
                final isPending = pendingAdds.contains(subCat.name);
                return ListTile(
                  title: Text(subCat.name),
                  subtitle: isPending ? const Text('(New)', style: TextStyle(color: Colors.green, fontStyle: FontStyle.italic)) : null,
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    onPressed: () {
                      setState(() {
                        // If it was a newly-added (pending) subcategory, just unstage it
                        if (_pendingSubCategoryAdds.remove(subCat.name)) {
                          // nothing else
                        } else {
                          _pendingSubCategoryDeletes.add(subCat.name);
                        }
                        _hasUnsavedSubCategoryChanges =
                            _pendingSubCategoryAdds.isNotEmpty ||
                            _pendingSubCategoryDeletes.isNotEmpty;
                      });
                    },
                  ),
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
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                ),
                IconButton(
                  icon: const Icon(Icons.add, color: Colors.white),
                  tooltip: 'Add Quality Parameter',
                  onPressed: () async {
                    final controller = TextEditingController();
                    final name = await showDialog<String>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Add Quality Parameter'),
                        content: TextField(
                          controller: controller,
                          decoration: const InputDecoration(
                            hintText: 'Enter parameter name',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: const Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () {
                              final text = controller.text.trim();
                              if (text.isNotEmpty) {
                                Navigator.of(context).pop(text);
                              }
                            },
                            child: const Text('Add'),
                          ),
                        ],
                      ),
                    );
                    if (name != null && name.isNotEmpty) {
                      await ref.read(universalParameterProvider.notifier).addParameter(name);
                      _printBoxContents();
                    }
                  },
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
                  subtitle: const Text('Enable if materials in this category require quality inspection'),
                  value: _unsavedCategory?.requiresQualityCheck ?? true,
                  onChanged: _unsavedCategory == null
                      ? null
                      : (value) {
                          final updated = _unsavedCategory!.copyWith(requiresQualityCheck: value);
                          _updateUnsavedCategory(updated);
                        },
                ),
                const SizedBox(height: 16),
                const Text('Universal Parameters', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 8),
                if (universalParams.isEmpty)
                  const Text('No parameters defined yet', style: TextStyle(color: Colors.grey))
                else
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: universalParams.map((param) {
                      return Chip(
                        label: Text(param.name),
                        onDeleted: () {
                          ref.read(universalParameterProvider.notifier).removeParameter(param);
                          for (var mapping in mappings) {
                            if (mapping.parameters.contains(param.name)) {
                              final newParams = List<String>.from(mapping.parameters)..remove(param.name);
                              final updatedMapping = CategoryParameterMapping(
                                category: mapping.category,
                                parameters: newParams,
                                requiresExpiryDate: mapping.requiresExpiryDate,
                                lastModified: mapping.lastModified,
                              );
                              ref.read(categoryParameterProvider.notifier).updateMapping(updatedMapping);
                              _markParametersDirty();
                            }
                          }
                        },
                      );
                    }).toList(),
                  ),
                const SizedBox(height: 16),
                if (_selectedCategory == null)
                  const Text('Select a category to manage its parameters', style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic))
                else ...[
                  Text('Parameters for ${_selectedCategory!.name}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 16),
                  if (universalParams.isEmpty)
                    const Text('No parameters defined yet', style: TextStyle(color: Colors.grey))
                  else
                    Builder(
                      builder: (context) {
                        final mapping = mappings.firstWhere(
                          (m) => m.category == _selectedCategory!.name,
                          orElse: () => CategoryParameterMapping(
                            category: _selectedCategory!.name,
                            parameters: [],
                            requiresExpiryDate: false,
                          ),
                        );

                        return Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: universalParams.map((param) {
                            final isSelected = mapping.parameters.contains(param.name);
                            return FilterChip(
                              label: Text(param.name),
                              selected: isSelected,
                              onSelected: (selected) {
                                final newParams = List<String>.from(mapping.parameters);
                                if (selected) {
                                  if (!newParams.contains(param.name)) {
                                    newParams.add(param.name);
                                  }
                                } else {
                                  newParams.remove(param.name);
                                }

                                final updatedMapping = CategoryParameterMapping(
                                  category: mapping.category,
                                  parameters: newParams,
                                  requiresExpiryDate: mapping.requiresExpiryDate,
                                  lastModified: mapping.lastModified,
                                );
                                ref
                                    .read(categoryParameterProvider.notifier)
                                    .updateMapping(updatedMapping);
                                _markParametersDirty();
                              },
                            );
                          }).toList(),
                        );
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
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Sample Size for Qty < 100', border: OutlineInputBorder()),
                  keyboardType: TextInputType.number,
                  controller: _sampleSizeLessThan100Controller,
                  onChanged: (value) => _updateUnsavedCategory(
                    _unsavedCategory!.copyWith(sampleSizeLessThan100: int.tryParse(value)),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Sample Size for Qty 100-500', border: OutlineInputBorder()),
                  keyboardType: TextInputType.number,
                  controller: _sampleSize100To500Controller,
                  onChanged: (value) => _updateUnsavedCategory(_unsavedCategory!.copyWith(sampleSize100To500: int.tryParse(value))),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Sample Size for Qty > 500', border: OutlineInputBorder()),
                  keyboardType: TextInputType.number,
                  controller: _sampleSizeGreaterThan500Controller,
                  onChanged: (value) => _updateUnsavedCategory(_unsavedCategory!.copyWith(sampleSizeGreaterThan500: int.tryParse(value))),
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
    final mappings = ref.watch(categoryParameterProvider);
    final mapping = _selectedCategory == null
        ? null
        : mappings.firstWhere(
            (m) => m.category == _selectedCategory!.name,
            orElse: () => CategoryParameterMapping(category: _selectedCategory!.name, parameters: [], requiresExpiryDate: false),
          );

    return Card(
      margin: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.black,
            child: const Text('Expiry/Shelf Life Settings', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text('Requires Expiry/Shelf Life Tracking'),
                  subtitle: const Text('Enable if materials in this category require expiry or shelf life management'),
                  value: (_unsavedCategory!.hasExpiryDate == true || _unsavedCategory!.hasShelfLife == true),
                  onChanged: (value) {
                    if (value) {
                      _updateUnsavedCategory(_unsavedCategory!.copyWith(hasExpiryDate: true, hasShelfLife: false));
                    } else {
                      _updateUnsavedCategory(_unsavedCategory!.copyWith(hasExpiryDate: false, hasShelfLife: false, shelfLifeValue: null, shelfLifeUnit: null));
                    }
                    if (mapping != null) {
                      final updated = CategoryParameterMapping(
                        category: mapping.category,
                        parameters: List<String>.from(mapping.parameters),
                        requiresExpiryDate: value && _unsavedCategory!.hasExpiryDate == true,
                        lastModified: mapping.lastModified,
                      );
                      ref.read(categoryParameterProvider.notifier).updateMapping(updated);
                      _markParametersDirty();
                    }
                  },
                ),
                const SizedBox(height: 16),
                if (_unsavedCategory!.hasExpiryDate == true || _unsavedCategory!.hasShelfLife == true) ...[
                  Row(
                    children: [
                      Expanded(
                        child: CheckboxListTile(
                          title: const Text('Has Expiry Date'),
                          value: _unsavedCategory!.hasExpiryDate,
                          onChanged: (value) {
                            if (value != null) {
                              _updateUnsavedCategory(_unsavedCategory!.copyWith(
                                hasExpiryDate: value,
                                hasShelfLife: value ? false : _unsavedCategory!.hasShelfLife,
                              ));
                              if (mapping != null) {
                                final updated = CategoryParameterMapping(
                                  category: mapping.category,
                                  parameters: List<String>.from(mapping.parameters),
                                  requiresExpiryDate: value,
                                  lastModified: mapping.lastModified,
                                );
                                ref.read(categoryParameterProvider.notifier).updateMapping(updated);
                                _markParametersDirty();
                              }
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
                              _updateUnsavedCategory(_unsavedCategory!.copyWith(
                                hasShelfLife: value,
                                hasExpiryDate: value ? false : _unsavedCategory!.hasExpiryDate,
                                shelfLifeValue: value ? _unsavedCategory!.shelfLifeValue : null,
                                shelfLifeUnit: value ? (_unsavedCategory!.shelfLifeUnit ?? 'days') : null,
                              ));
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
                            decoration: const InputDecoration(labelText: 'Shelf Life Duration', border: OutlineInputBorder()),
                            keyboardType: TextInputType.number,
                            controller: _shelfLifeValueController,
                            onChanged: (value) => _updateUnsavedCategory(_unsavedCategory!.copyWith(shelfLifeValue: int.tryParse(value))),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            decoration: const InputDecoration(labelText: 'Unit', border: OutlineInputBorder()),
                            value: _unsavedCategory!.shelfLifeUnit ?? 'days',
                            items: const [
                              DropdownMenuItem(value: 'days', child: Text('Days')),
                              DropdownMenuItem(value: 'months', child: Text('Months')),
                              DropdownMenuItem(value: 'years', child: Text('Years')),
                            ],
                            onChanged: (value) {
                              if (value != null) {
                                _updateUnsavedCategory(_unsavedCategory!.copyWith(shelfLifeUnit: value));
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

  Future<bool> _onWillPop() async {
    if (_hasUnsavedChanges || _hasUnsavedParameterChanges || _hasUnsavedSubCategoryChanges) {
      final result = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: Colors.grey[850],
          title: const Text('Unsaved Changes', style: TextStyle(color: Colors.white)),
          content: const Text('Do you want to discard your unsaved changes?', style: TextStyle(color: Colors.grey)),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Discard', style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
      );
      return result ?? false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final categories = ref.watch(categoryListProvider);

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
      appBar: AppBar(
        title: const Text('Category Settings (Quality)'),
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
              if (!_hasUnsavedChanges && !_hasUnsavedParameterChanges && !_hasUnsavedSubCategoryChanges) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('No changes to save')),
                );
                return;
              }

              await _saveChanges();

              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Saved successfully')),
              );
            },
            icon: const Icon(Icons.save, color: Colors.white),
            label: const Text('Save', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildCategoryList(),
            if (_selectedCategory != null) ...[
              _buildSubCategorySection(),
              _buildQualityParameterSection(),
              if (_unsavedCategory?.requiresQualityCheck == true) ...[
                _buildSamplePlanSection(),
                _buildExpiryShelfLifeSection(),
              ],
            ] else ...[
              Card(
                margin: const EdgeInsets.all(8),
                child: const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('Select a category to manage quality settings', style: TextStyle(color: Colors.grey)),
                ),
              ),
            ],
          ],
        ),
      ),
    ),
    );
  }
}
