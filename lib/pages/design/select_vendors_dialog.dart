import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mpt_ims/provider/supplier_provider.dart';

class SelectVendorsDialog extends ConsumerStatefulWidget {
  final List<String> selectedVendors;

  const SelectVendorsDialog({
    super.key,
    required this.selectedVendors,
  });

  @override
  ConsumerState<SelectVendorsDialog> createState() =>
      _SelectVendorsDialogState();
}

class _SelectVendorsDialogState extends ConsumerState<SelectVendorsDialog> {
  late List<String> _selectedVendors;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selectedVendors = List.from(widget.selectedVendors);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vendors = ref.watch(supplierListProvider);
    final filteredVendors = vendors
        .where((vendor) =>
            vendor.name.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();

    return Dialog(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Select Vendors',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Search Vendors',
                prefixIcon: const Icon(Icons.search),
                border: const OutlineInputBorder(),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          setState(() {
                            _searchQuery = '';
                            _searchController.clear();
                          });
                        },
                      )
                    : null,
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
            const SizedBox(height: 16),
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.4,
              ),
              child: SingleChildScrollView(
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: filteredVendors.map((vendor) {
                    final isSelected = _selectedVendors.contains(vendor.name);
                    return FilterChip(
                      selected: isSelected,
                      label: Text(vendor.name),
                      onSelected: (bool selected) {
                        setState(() {
                          if (selected) {
                            _selectedVendors.add(vendor.name);
                          } else {
                            _selectedVendors.remove(vendor.name);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: () => Navigator.pop(context, _selectedVendors),
                  child: const Text('Done'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
