// ignore_for_file: use_build_context_synchronously, non_constant_identifier_names

import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:mpt_ims/models/material_request_item.dart';
import 'package:mpt_ims/provider/material_request_provider.dart';
import '../../models/material_request.dart';
import '../../provider/material_provider.dart';
import '../../provider/sale_order_provider.dart';
import '../../models/material_item.dart';

class AddMaterialRequestPage extends ConsumerStatefulWidget {
  final MaterialRequest? existingIssue;
  final int? index;
  const AddMaterialRequestPage({
    super.key,
    required this.existingIssue,
    required this.index,
  });

  @override
  ConsumerState<AddMaterialRequestPage> createState() =>
      _AddMaterialRequestPageState();
}

class _AddMaterialRequestPageState
    extends ConsumerState<AddMaterialRequestPage> {
  final _formKey = GlobalKey<FormState>();
  final List<MaterialRequestItemFormData> _items = [];
  final _issuedByController = TextEditingController();
  String? _selectedJobNo;

  // Controllers for bulk entry
  final _materialCodesController = TextEditingController();
  final _quantitiesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Load sale orders when page is opened
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        await ref.read(saleOrderProvider.notifier).loadSaleOrders();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error loading job numbers: $e')),
          );
        }
      }
    });

    if (widget.existingIssue != null) {
      _issuedByController.text = widget.existingIssue!.issuedBy;
      _selectedJobNo = widget.existingIssue!.jobNo;
      for (var item in widget.existingIssue!.items) {
        _items.add(MaterialRequestItemFormData(
          selectedMaterial: item.materialDescription,
          quantity: item.quantity,
          partNoController: TextEditingController(text: item.materialCode),
          unitController: TextEditingController(text: item.unit),
          materialController:
              TextEditingController(text: item.materialDescription),
        ));
      }
    } else {
      _addNewItem();
    }
  }

  @override
  void dispose() {
    _issuedByController.dispose();
    _materialCodesController.dispose();
    _quantitiesController.dispose();
    for (var item in _items) {
      item.dispose();
    }
    super.dispose();
  }

  void _addNewItem() {
    setState(() {
      _items.add(MaterialRequestItemFormData(
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
                            _items[0].materialController.text =
                                material.description;
                          });
                          hasUsedFirstItem = true;
                        } else {
                          // Add new item
                          _items.add(MaterialRequestItemFormData(
                            selectedMaterial: material.description,
                            quantity: quantity,
                            partNoController:
                                TextEditingController(text: material.partNo),
                            unitController:
                                TextEditingController(text: material.unit),
                            materialController: TextEditingController(
                                text: material.description),
                          ));
                        }
                      }

                      Navigator.pop(context);
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

  Future<void> _saveMaterialRequest() async {
    if (!_formKey.currentState!.validate()) return;

    final items = _items.map((item) {
      // Get the quantity from the controller
      final quantity = double.tryParse(item.quantityController.text) ?? 0.0;

      return MaterialRequestItem(
        materialCode: item.partNoController.text,
        materialDescription: item.materialController.text,
        unit: item.unitController.text,
        quantity: quantity
            .toString(), // Convert to string since the model expects a string
        issueNo: '', // Initialize with empty string
      );
    }).toList();

    final materialRequest = MaterialRequest(
      issueNo: widget.existingIssue?.issueNo ??
          ref.read(materialRequestProvider.notifier).generateIssueNo(),
      date: DateFormat('yyyy-MM-dd').format(DateTime.now()),
      jobNo: _selectedJobNo,
      issuedBy: _issuedByController.text,
      status: 'Active',
      items: items,
    );

    if (widget.existingIssue != null) {
      await ref
          .read(materialRequestProvider.notifier)
          .updateMaterialRequest(materialRequest);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Material Request updated successfully')),
        );
      }
    } else {
      await ref
          .read(materialRequestProvider.notifier)
          .addMaterialRequest(materialRequest);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Material Request created successfully')),
        );
      }
    }

    if (mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final materials = ref.watch(materialListProvider);
    final saleOrders = ref.watch(saleOrderProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.existingIssue != null
            ? 'Edit Material Request'
            : 'New Material Request'),
        actions: [
          FilledButton.icon(
            onPressed: _saveMaterialRequest,
            icon: const Icon(Icons.save),
            label: const Text('Save'),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
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
                      onChanged: (value) {
                        setState(() {
                          _selectedJobNo = value;
                        });
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please select a job number';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _issuedByController,
                      decoration: const InputDecoration(
                        labelText: 'Requested By',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter who is issuing';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Materials',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Row(
                    children: [
                      OutlinedButton.icon(
                        onPressed: _showBulkEntryDialog,
                        icon: const Icon(Icons.playlist_add),
                        label: const Text('Bulk Entry'),
                      ),
                      const SizedBox(width: 8),
                      FilledButton.icon(
                        onPressed: _addNewItem,
                        icon: const Icon(Icons.add),
                        label: const Text('Add Item'),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _items.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 16),
                itemBuilder: (context, index) {
                  final item = _items[index];
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
                              fieldViewBuilder: (context, textEditingController,
                                  focusNode, onFieldSubmitted) {
                                // Set initial value without triggering rebuild
                                WidgetsBinding.instance
                                    .addPostFrameCallback((_) {
                                  if (textEditingController.text.isEmpty &&
                                      item.partNoController.text.isNotEmpty) {
                                    textEditingController.text =
                                        item.partNoController.text;
                                  }
                                });
                                return TextFormField(
                                  controller: textEditingController,
                                  focusNode: focusNode,
                                  decoration: const InputDecoration(
                                    labelText: 'Part No',
                                    border: OutlineInputBorder(),
                                  ),
                                  validator: (v) => v == null || v.isEmpty
                                      ? 'Required'
                                      : !materials.any((m) => m.partNo == v)
                                          ? 'Invalid material code'
                                          : null,
                                );
                              },
                              optionsViewBuilder:
                                  (context, onSelected, options) {
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
                                          final option =
                                              options.elementAt(index);
                                          return InkWell(
                                            onTap: () => onSelected(option),
                                            child: Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
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
                              displayStringForOption: (material) =>
                                  material.partNo,
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
                                  item.materialController.text =
                                      material.description;
                                });
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          // Material Description Selection
                          Expanded(
                            flex: 4,
                            child: Autocomplete<MaterialItem>(
                              fieldViewBuilder: (context, textEditingController,
                                  focusNode, onFieldSubmitted) {
                                // Set initial value without triggering rebuild
                                WidgetsBinding.instance
                                    .addPostFrameCallback((_) {
                                  if (textEditingController.text.isEmpty &&
                                      item.selectedMaterial != null) {
                                    textEditingController.text =
                                        item.selectedMaterial!;
                                  }
                                });
                                return TextFormField(
                                  controller: textEditingController,
                                  focusNode: focusNode,
                                  decoration: const InputDecoration(
                                    labelText: 'Description',
                                    border: OutlineInputBorder(),
                                  ),
                                  validator: (v) => v == null || v.isEmpty
                                      ? 'Required'
                                      : !materials
                                              .any((m) => m.description == v)
                                          ? 'Invalid material'
                                          : null,
                                );
                              },
                              optionsViewBuilder:
                                  (context, onSelected, options) {
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
                                          final option =
                                              options.elementAt(index);
                                          return InkWell(
                                            onTap: () => onSelected(option),
                                            child: Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
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
                              displayStringForOption: (material) =>
                                  material.description,
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
                                  item.materialController.text =
                                      material.description;
                                });
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              controller: item.unitController,
                              decoration: const InputDecoration(
                                labelText: 'Unit',
                                border: OutlineInputBorder(),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter unit';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              controller: item.quantityController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Quantity',
                                border: OutlineInputBorder(),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter quantity';
                                }
                                final qty = double.tryParse(value);
                                if (qty == null || qty <= 0) {
                                  return 'Please enter a valid quantity';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          IconButton(
                            icon: const Icon(Icons.delete),
                            color: Colors.red,
                            onPressed: () => _removeItem(index),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class MaterialRequestItemFormData {
  String? selectedMaterial;
  String? quantity;
  final TextEditingController partNoController;
  final TextEditingController unitController;
  final TextEditingController materialController;
  final TextEditingController quantityController;

  MaterialRequestItemFormData({
    this.selectedMaterial,
    this.quantity,
    required this.partNoController,
    required this.unitController,
    required this.materialController,
  }) : quantityController = TextEditingController(text: quantity);

  void dispose() {
    partNoController.dispose();
    unitController.dispose();
    materialController.dispose();
    quantityController.dispose();
  }
}
