// ignore_for_file: use_build_context_synchronously

import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../models/purchase_request.dart';
import '../../models/pr_item.dart';
import '../../provider/material_provider.dart';
import '../../provider/purchase_request_provider.dart';
import '../../provider/sale_order_provider.dart';
import '../../models/material_item.dart';

class AddPurchaseRequestPage extends ConsumerStatefulWidget {
  final PurchaseRequest? existingRequest;
  final int? index;
  const AddPurchaseRequestPage(
      {super.key, required this.existingRequest, required this.index});

  @override
  ConsumerState<AddPurchaseRequestPage> createState() =>
      _AddPurchaseRequestPageState();
}

class _AddPurchaseRequestPageState
    extends ConsumerState<AddPurchaseRequestPage> {
  final _formKey = GlobalKey<FormState>();
  final List<PRItemFormData> _items = [];
  final _requiredByController = TextEditingController();
  String? _selectedJobNo;

  // Controllers for bulk entry
  final _materialCodesController = TextEditingController();
  final _quantitiesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.existingRequest != null) {
      _requiredByController.text = widget.existingRequest!.requiredBy;
      _selectedJobNo = widget.existingRequest!.jobNo;
      for (var item in widget.existingRequest!.items) {
        _items.add(PRItemFormData(
          selectedMaterial: item.materialDescription,
          quantity: item.quantity,
          partNoController: TextEditingController(text: item.materialCode),
          unitController: TextEditingController(text: item.unit),
          materialController: TextEditingController(text: item.materialDescription),
        ));
      }
    } else {
      _addNewItem();
    }
  }

  @override
  void dispose() {
    _requiredByController.dispose();
    _materialCodesController.dispose();
    _quantitiesController.dispose();
    for (var item in _items) {
      item.dispose();
    }
    super.dispose();
  }

  void _addNewItem() {
    setState(() {
      _items.add(PRItemFormData(
        selectedMaterial: null,
        quantity: null,
        partNoController: TextEditingController(),
        unitController: TextEditingController(),
        materialController: TextEditingController(),
      ));
    });
  }

  void _removeItem(int index) {
    setState(() {
      final item = _items[index];
      item.dispose();
      _items.removeAt(index);
    });
  }

  Future<void> _showBulkEntryDialog() async {
    _materialCodesController.clear();
    _quantitiesController.clear();
    bool isQuantityStep = false;
    List<String> materialCodes = [];
    final materials = ref.read(materialListProvider);

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(
                  isQuantityStep ? 'Enter Quantities' : 'Enter Material Codes'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!isQuantityStep) ...[
                    const Text(
                      'Enter material codes, one per line:',
                      style: TextStyle(fontSize: 14),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _materialCodesController,
                      maxLines: 8,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: 'e.g.\nM001\nM002\nM003',
                      ),
                    ),
                  ] else ...[
                    const Text(
                      'Enter quantities in the same order:',
                      style: TextStyle(fontSize: 14),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _quantitiesController,
                      maxLines: 8,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        border: const OutlineInputBorder(),
                        hintText:
                            'Enter quantities for:\n${materialCodes.join('\n')}',
                      ),
                    ),
                  ],
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () {
                    if (!isQuantityStep) {
                      // Process material codes
                      materialCodes = _materialCodesController.text
                          .split('\n')
                          .where((code) => code.trim().isNotEmpty)
                          .map((code) => code.trim())
                          .toList();

                      // Validate material codes
                      final invalidCodes = materialCodes
                          .where(
                              (code) => !materials.any((m) => m.partNo == code))
                          .toList();

                      if (invalidCodes.isNotEmpty) {
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Invalid Material Codes'),
                            content: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                    'The following codes were not found:'),
                                const SizedBox(height: 8),
                                Text(invalidCodes.join('\n')),
                              ],
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('OK'),
                              ),
                            ],
                          ),
                        );
                        return;
                      }

                      setState(() {
                        isQuantityStep = true;
                      });
                    } else {
                      // Process quantities
                      final quantities = _quantitiesController.text
                          .split('\n')
                          .where((qty) => qty.trim().isNotEmpty)
                          .map((qty) => qty.trim())
                          .toList();

                      if (quantities.length != materialCodes.length) {
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Quantity Mismatch'),
                            content: Text(
                                'Please enter ${materialCodes.length} quantities, one for each material code.'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('OK'),
                              ),
                            ],
                          ),
                        );
                        return;
                      }

                      // Add all items
                      // If we have an empty first item, use that instead of adding a new one
                      bool hasUsedFirstItem = false;
                      for (var i = 0; i < materialCodes.length; i++) {
                        final material = materials
                            .firstWhere((m) => m.partNo == materialCodes[i]);
                        final quantity = quantities[i];

                        if (!hasUsedFirstItem &&
                            _items.isNotEmpty &&
                            _items[0].selectedMaterial == null &&
                            _items[0].quantity == null) {
                          // Use the first empty item
                          setState(() {
                            _items[0].selectedMaterial = material.description;
                            _items[0].quantity = quantity;
                            _items[0].partNoController.text = material.partNo;
                            _items[0].unitController.text = material.unit;
                            _items[0].materialController.text = material.description;
                          });
                          hasUsedFirstItem = true;
                        } else {
                          // Add new item
                          _items.add(PRItemFormData(
                            selectedMaterial: material.description,
                            quantity: quantity,
                            partNoController:
                                TextEditingController(text: material.partNo),
                            unitController:
                                TextEditingController(text: material.unit),
                            materialController: TextEditingController(text: material.description),
                          ));
                        }
                      }

                      Navigator.pop(context);
                      setState(() {});
                    }
                  },
                  child: Text(isQuantityStep ? 'Add Items' : 'Next'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final materials = ref.watch(materialListProvider);
    final saleOrders = ref.watch(saleOrderProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.existingRequest != null
              ? 'Edit Purchase Request'
              : 'New Purchase Request',
        ),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _requiredByController,
                      decoration: const InputDecoration(
                        labelText: 'Required By',
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) =>
                          v == null || v.isEmpty ? 'Required' : null,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: DropdownButtonFormField2<String>(
                      value: _selectedJobNo,
                      decoration: const InputDecoration(
                        labelText: 'Job No',
                        border: OutlineInputBorder(),
                      ),
                      items: [
                        const DropdownMenuItem(
                          value: null,
                          child: Text('None'),
                        ),
                        ...saleOrders.map((order) => DropdownMenuItem(
                              value: order.boardNo,
                              child: Text(order.boardNo),
                            )),
                      ],
                      onChanged: (v) => setState(() => _selectedJobNo = v),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Items',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  OutlinedButton.icon(
                    onPressed: _showBulkEntryDialog,
                    icon: const Icon(Icons.playlist_add),
                    label: const Text('Add Multiple Items'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ..._items.asMap().entries.map((entry) {
                final index = entry.key;
                final item = entry.value;
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Material Code Selection
                        Expanded(
                          flex: 2,
                          child: Autocomplete<MaterialItem>(
                            fieldViewBuilder: (context,
                                textEditingController,
                                focusNode,
                                onFieldSubmitted) {
                              // Set initial value without triggering rebuild
                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                if (textEditingController.text.isEmpty &&
                                    item.partNoController.text.isNotEmpty) {
                                  textEditingController.text = item.partNoController.text;
                                }
                              });
                              return TextFormField(
                                controller: textEditingController,
                                focusNode: focusNode,
                                decoration: const InputDecoration(
                                  labelText: 'Material Code',
                                  border: OutlineInputBorder(),
                                ),
                                validator: (v) => v == null || v.isEmpty
                                    ? 'Required'
                                    : !materials.any((m) => m.partNo == v)
                                        ? 'Invalid material code'
                                        : null,
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
                                              '${option.partNo} - ${option.description}',
                                              style: const TextStyle(
                                                fontSize: 14.0,
                                              ),
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ),
                              );
                            },
                            displayStringForOption: (material) => material.partNo,
                            optionsBuilder: (textEditingValue) {
                              if (textEditingValue.text.isEmpty) {
                                return materials;
                              }
                              return materials.where((material) =>
                                  material.partNo.toLowerCase().contains(
                                      textEditingValue.text.toLowerCase()));
                            },
                            onSelected: (material) {
                              setState(() {
                                item.selectedMaterial = material.description;
                                item.partNoController.text = material.partNo;
                                item.unitController.text = material.unit;
                                item.materialController.text = material.description;
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        // Material Description Selection
                        Expanded(
                          flex: 3,
                          child: Autocomplete<MaterialItem>(
                            fieldViewBuilder: (context,
                                textEditingController,
                                focusNode,
                                onFieldSubmitted) {
                              // Set initial value without triggering rebuild
                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                if (textEditingController.text.isEmpty &&
                                    item.selectedMaterial != null) {
                                  textEditingController.text = item.selectedMaterial!;
                                }
                              });
                              return TextFormField(
                                controller: textEditingController,
                                focusNode: focusNode,
                                decoration: const InputDecoration(
                                  labelText: 'Material',
                                  border: OutlineInputBorder(),
                                ),
                                validator: (v) => v == null || v.isEmpty
                                    ? 'Required'
                                    : !materials.any((m) => m.description == v)
                                        ? 'Invalid material'
                                        : null,
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
                                      maxWidth: 600,
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
                                              option.description,
                                              style: const TextStyle(
                                                fontSize: 14.0,
                                              ),
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ),
                              );
                            },
                            displayStringForOption: (material) => material.description,
                            optionsBuilder: (textEditingValue) {
                              if (textEditingValue.text.isEmpty) {
                                return materials;
                              }
                              return materials.where((material) =>
                                  material.description.toLowerCase().contains(
                                      textEditingValue.text.toLowerCase()));
                            },
                            onSelected: (material) {
                              setState(() {
                                item.selectedMaterial = material.description;
                                item.partNoController.text = material.partNo;
                                item.unitController.text = material.unit;
                                item.materialController.text = material.description;
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        // Quantity Field
                        Expanded(
                          flex: 1,
                          child: TextFormField(
                            key: ValueKey('quantity_${item.hashCode}'),
                            initialValue: item.quantity,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Quantity',
                              border: OutlineInputBorder(),
                            ),
                            validator: (v) =>
                                v == null || v.isEmpty ? 'Required' : null,
                            onChanged: (v) => item.quantity = v,
                            onSaved: (v) => item.quantity = v,
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Delete Button
                        IconButton(
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () => _removeItem(index),
                        ),
                      ],
                    ),
                  ),
                );
              }),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  OutlinedButton.icon(
                    onPressed: _addNewItem,
                    icon: const Icon(Icons.add),
                    label: const Text('Add Item'),
                  ),
                  FilledButton(
                    onPressed: () async {
                      if (_formKey.currentState!.validate()) {
                        _formKey.currentState!.save();
                        final now =
                            DateFormat('yyyy-MM-dd').format(DateTime.now());

                        final prNo = widget.existingRequest?.prNo ??
                            'PR${DateTime.now().millisecondsSinceEpoch}';

                        // Process all items (both new and existing)
                        final allItems = <PRItem>[];

                        // First, process the form items
                        for (var item in _items) {
                          if (item.selectedMaterial == null) continue;

                          final material = materials.firstWhere(
                            (m) => m.description == item.selectedMaterial,
                          );

                          final prItem = PRItem(
                            materialCode: material.partNo,
                            materialDescription: material.description,
                            unit: material.unit,
                            quantity: item.quantity!,
                            prNo: prNo,
                          );

                          allItems.add(prItem);
                        }

                        final request = PurchaseRequest(
                          prNo: prNo,
                          date: now,
                          requiredBy: _requiredByController.text,
                          items: allItems,
                          jobNo: _selectedJobNo,
                        );

                        if (widget.existingRequest != null &&
                            widget.index != null) {
                          ref
                              .read(purchaseRequestListProvider.notifier)
                              .updateRequest(widget.index!, request);
                        } else {
                          ref
                              .read(purchaseRequestListProvider.notifier)
                              .addRequest(request);
                        }

                        Navigator.pop(context);
                      }
                    },
                    child: const Text('Save'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class PRItemFormData {
  String? selectedMaterial;
  String? quantity;
  final TextEditingController partNoController;
  final TextEditingController unitController;
  final TextEditingController materialController;

  PRItemFormData({
    required this.selectedMaterial,
    required this.quantity,
    required this.partNoController,
    required this.unitController,
    required this.materialController,
  });

  void dispose() {
    partNoController.dispose();
    unitController.dispose();
    materialController.dispose();
  }
}
