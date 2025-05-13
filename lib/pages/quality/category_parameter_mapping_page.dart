import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/category_parameter_mapping.dart';
import '../../models/quality_inspection.dart';
import '../../provider/category_parameter_provider.dart';
import '../../provider/material_provider.dart';

class CategoryParameterMappingPage extends ConsumerStatefulWidget {
  const CategoryParameterMappingPage({super.key});

  @override
  ConsumerState<CategoryParameterMappingPage> createState() =>
      _CategoryParameterMappingPageState();
}

class _CategoryParameterMappingPageState
    extends ConsumerState<CategoryParameterMappingPage> {
  @override
  Widget build(BuildContext context) {
    final mappings = ref.watch(categoryParameterProvider);
    final materials = ref.watch(materialListProvider);

    // Get unique categories from materials
    final categories = materials
        .map((m) => m.category)
        .toSet()
        .where((category) => category.isNotEmpty)
        .toList()
      ..sort(); // Sort categories alphabetically

    return Scaffold(
      appBar: AppBar(
        title: const Text('Category Parameter Mapping'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Configure Quality Parameters by Category',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Select which quality parameters apply to each material category and whether expiry date is required.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: categories.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.category_outlined,
                            size: 64,
                            color: Colors.grey[300],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No material categories found',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Add categories to materials first',
                            style: TextStyle(
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: categories.length,
                      itemBuilder: (context, index) {
                        final category = categories[index];
                        final mapping = mappings.firstWhere(
                          (m) => m.category == category,
                          orElse: () => CategoryParameterMapping(
                            category: category,
                            parameters: [],
                            requiresExpiryDate: false,
                          ),
                        );

                        return Card(
                          margin: const EdgeInsets.only(bottom: 16),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  category,
                                  style:
                                      Theme.of(context).textTheme.titleMedium,
                                ),
                                const SizedBox(height: 16),
                                const Text('Select Parameters to Check:'),
                                const SizedBox(height: 8),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: QualityParameter.standardParameters
                                      .map((param) => FilterChip(
                                            label: Text(param),
                                            selected: mapping.parameters
                                                .contains(param),
                                            onSelected: (selected) {
                                              setState(() {
                                                if (selected) {
                                                  mapping.parameters.add(param);
                                                } else {
                                                  mapping.parameters
                                                      .remove(param);
                                                }
                                                ref
                                                    .read(
                                                        categoryParameterProvider
                                                            .notifier)
                                                    .updateMapping(mapping);
                                              });
                                            },
                                          ))
                                      .toList(),
                                ),
                                const SizedBox(height: 16),
                                SwitchListTile(
                                  title: const Text('Requires Expiry Date'),
                                  subtitle: const Text(
                                      'Enable if materials in this category need expiration date tracking'),
                                  value: mapping.requiresExpiryDate,
                                  onChanged: (value) {
                                    setState(() {
                                      mapping.requiresExpiryDate = value;
                                      ref
                                          .read(categoryParameterProvider
                                              .notifier)
                                          .updateMapping(mapping);
                                    });
                                  },
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
