// ignore_for_file: use_build_context_synchronously

import 'dart:io';

import 'package:csv/csv.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../models/purchase_request.dart';
import '../../models/pr_item.dart';
import '../../provider/material_provider.dart';
import '../../provider/purchase_request_provider.dart';
import '../../provider/sale_order_provider.dart';
import '../../models/material_item.dart';

class AddCustomerFreeIssuePage extends ConsumerStatefulWidget {
  final PurchaseRequest? existingRequest;
  final int? index;
  const AddCustomerFreeIssuePage({super.key, required this.existingRequest, required this.index});

  @override
  ConsumerState<AddCustomerFreeIssuePage> createState() => _AddCustomerFreeIssuePageState();
}

class _AddCustomerFreeIssuePageState extends ConsumerState<AddCustomerFreeIssuePage> {
  final _formKey = GlobalKey<FormState>();
  final List<CFIItemFormData> _items = [];
  final _requestedByController = TextEditingController();
  String? _selectedJobNo;

  // Controllers for bulk entry
  final _materialCodesController = TextEditingController();
  final _quantitiesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      try {
        await ref.read(saleOrderProvider.notifier).loadSaleOrders();
      } catch (_) {}
    });
    if (widget.existingRequest != null) {
      _requestedByController.text = widget.existingRequest!.requiredBy;
      _selectedJobNo = widget.existingRequest!.jobNo;
      for (var item in widget.existingRequest!.items) {
        _items.add(CFIItemFormData(
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

  Future<void> _downloadBulkTemplate() async {
    try {
      final headers = ['Material Code', 'Material', 'Quantity'];
      final csvData = const ListToCsvConverter().convert([headers]);

      String? outputFile = await FilePicker.platform.saveFile(
        dialogTitle: 'Save Customer Free Issue Bulk Template',
        fileName: 'customer_free_issue_bulk_template.csv',
        type: FileType.any,
      );

      if (outputFile == null) {
        return;
      }

      if (!outputFile.toLowerCase().endsWith('.csv')) {
        outputFile = '$outputFile.csv';
      }

      final file = File(outputFile);
      await file.writeAsString(csvData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Template saved successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save template: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _uploadBulkCsv() async {
    try {
      final materials = ref.read(materialListProvider);
      if (materials.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content:
                  Text('Material master is empty. Please add materials first.'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      FilePickerResult? result;
      try {
        result = await FilePicker.platform.pickFiles(
          type: FileType.any,
          allowMultiple: false,
        );
      } catch (_) {
        result = await FilePicker.platform.pickFiles(
          type: FileType.custom,
          allowedExtensions: ['csv'],
          allowMultiple: false,
        );
      }

      if (result == null || result.files.single.path == null) {
        return;
      }

      final file = File(result.files.single.path!);
      final ext = result.files.single.extension?.toLowerCase();
      if (ext != null && ext != 'csv') {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  'Unsupported file type: $ext. Please upload a CSV file.'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      String norm(String s) => s
          .replaceAll('\r', '')
          .replaceAll('\u00A0', ' ')
          .replaceAll('\u200B', '')
          .replaceAll('\uFEFF', '')
          .trim()
          .toLowerCase()
          .replaceAll(RegExp(r'\s+'), '')
          .replaceAll(RegExp(r'[^a-z0-9]'), '');

      final input = await file.readAsString();
      final rows = const CsvToListConverter().convert(input);
      if (rows.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('CSV file is empty'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      final headers = rows.first.map((e) => e.toString().toLowerCase()).toList();
      int codeIndex = -1;
      int qtyIndex = -1;

      for (int i = 0; i < headers.length; i++) {
        final h = headers[i];
        if (h.contains('material code') || h.contains('part no') || h.contains('partno')) {
          codeIndex = i;
        } else if (h.contains('qty') || h.contains('quantity')) {
          qtyIndex = i;
        }
      }

      if (codeIndex == -1 || qtyIndex == -1) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('CSV must have at least Material Code and Quantity columns.'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      final dataRows = rows.sublist(1);
      final invalidRows = <String>[];
      final newItems = <CFIItemFormData>[];

      for (int rowIndex = 0; rowIndex < dataRows.length; rowIndex++) {
        final row = dataRows[rowIndex];
        if (row.isEmpty) continue;
        if (row.length <= codeIndex || row.length <= qtyIndex) continue;

        final rawCode = row[codeIndex]?.toString().trim() ?? '';
        final qtyStr = row[qtyIndex]?.toString().trim() ?? '';
        if (rawCode.isEmpty && qtyStr.isEmpty) continue;

        final material = materials.firstWhere(
          (m) => norm(m.partNo) == norm(rawCode),
          orElse: () => MaterialItem(
            slNo: '',
            description: '',
            partNo: '',
            unit: '',
            category: '',
            subCategory: '',
          ),
        );

        if (material.partNo.isEmpty) {
          invalidRows.add('${rowIndex + 2}: $rawCode (invalid material code)');
          continue;
        }

        if (qtyStr.isEmpty) {
          invalidRows.add('${rowIndex + 2}: ${material.partNo} (missing quantity)');
          continue;
        }

        newItems.add(
          CFIItemFormData(
            selectedMaterial: material.description,
            quantity: qtyStr,
            partNoController: TextEditingController(text: material.partNo),
            unitController: TextEditingController(text: material.unit),
            materialController: TextEditingController(text: material.description),
          ),
        );
      }

      if (invalidRows.isNotEmpty && mounted) {
        await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Some rows could not be imported'),
            content: SizedBox(
              width: 500,
              child: SingleChildScrollView(
                child: Text(invalidRows.join('\n')),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }

      if (newItems.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No valid rows to import from CSV'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      setState(() {
        if (_items.length == 1 &&
            _items[0].selectedMaterial == null &&
            _items[0].quantity == null) {
          final first = newItems.first;
          _items[0].selectedMaterial = first.selectedMaterial;
          _items[0].quantity = first.quantity;
          _items[0].partNoController.text = first.partNoController.text;
          _items[0].unitController.text = first.unitController.text;
          _items[0].materialController.text = first.materialController.text;
          _items.addAll(newItems.skip(1));
        } else {
          _items.addAll(newItems);
        }
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Imported ${newItems.length} items from CSV'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error importing CSV: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _requestedByController.dispose();
    _materialCodesController.dispose();
    _quantitiesController.dispose();
    for (var item in _items) {
      item.dispose();
    }
    super.dispose();
  }

  void _addNewItem() {
    setState(() {
      _items.add(CFIItemFormData(
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
              title: Text(isQuantityStep ? 'Enter Quantities' : 'Enter Material Codes'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!isQuantityStep) ...[
                    const Text('Enter material codes, one per line:'),
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
                    const Text('Enter quantities in the same order:'),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _quantitiesController,
                      maxLines: 8,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        border: const OutlineInputBorder(),
                        hintText: 'Enter quantities for:\n${materialCodes.join('\n')}',
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
                      materialCodes = _materialCodesController.text
                          .split('\n')
                          .where((code) => code.trim().isNotEmpty)
                          .map((code) => code.trim())
                          .toList();

                      final invalidCodes = materialCodes
                          .where((code) => !materials.any((m) => m.partNo == code))
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
                                const Text('The following codes were not found:'),
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
                            content: Text('Please enter ${materialCodes.length} quantities, one for each material code.'),
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

                      bool hasUsedFirstItem = false;
                      for (var i = 0; i < materialCodes.length; i++) {
                        final material = materials.firstWhere((m) => m.partNo == materialCodes[i]);
                        final quantity = quantities[i];

                        if (!hasUsedFirstItem &&
                            _items.isNotEmpty &&
                            _items[0].selectedMaterial == null &&
                            _items[0].quantity == null) {
                          setState(() {
                            _items[0].selectedMaterial = material.description;
                            _items[0].quantity = quantity;
                            _items[0].partNoController.text = material.partNo;
                            _items[0].unitController.text = material.unit;
                            _items[0].materialController.text = material.description;
                          });
                          hasUsedFirstItem = true;
                        } else {
                          _items.add(CFIItemFormData(
                            selectedMaterial: material.description,
                            quantity: quantity,
                            partNoController: TextEditingController(text: material.partNo),
                            unitController: TextEditingController(text: material.unit),
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

  String _generateCFINumber(List<PurchaseRequest> all) {
    final now = DateTime.now();
    int financialYear = now.year;
    if (now.month < 4) financialYear--;
    final nextFinancialYear = financialYear + 1;
    final yearPrefix = '${financialYear.toString().substring(2)}${nextFinancialYear.toString().substring(2)}';

    final valid = all.where((r) => r.prNo.startsWith('CFI$yearPrefix') && r.prNo.length == 13).toList();
    if (valid.isEmpty) return 'CFI${yearPrefix}000001';
    final seqNumbers = valid.map((r) => int.tryParse(r.prNo.substring(7)) ?? 0).toList();
    final nextSeq = (seqNumbers.isEmpty ? 0 : seqNumbers.reduce((a, b) => a > b ? a : b)) + 1;
    return 'CFI$yearPrefix${nextSeq.toString().padLeft(6, '0')}' ;
  }

  @override
  Widget build(BuildContext context) {
    final materials = ref.watch(materialListProvider);
    final saleOrders = ref.watch(saleOrderProvider);

    final eligibleSaleOrders = saleOrders
        .where((o) => (o.isCustomerFreeIssueAvailable ?? false))
        .toList();

    if (eligibleSaleOrders.isEmpty) {
      eligibleSaleOrders.addAll(saleOrders);
    }

    if (_selectedJobNo != null && _selectedJobNo!.isNotEmpty) {
      final selectedOrder = saleOrders
          .where((o) => o.jobNo == _selectedJobNo)
          .toList();
      for (final o in selectedOrder) {
        if (!eligibleSaleOrders.any((e) => e.jobNo == o.jobNo)) {
          eligibleSaleOrders.add(o);
        }
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.existingRequest != null ? 'Edit Customer Free Issue' : 'New Customer Free Issue'),
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
                      controller: _requestedByController,
                      decoration: const InputDecoration(
                        labelText: 'Requested By',
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) => v == null || v.isEmpty ? 'Required' : null,
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
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'Required';
                        }
                        return null;
                      },
                      items: [
                        const DropdownMenuItem(value: null, child: Text('None')),
                        ...eligibleSaleOrders.map((order) => DropdownMenuItem(
                              value: order.jobNo,
                              child: Text(order.jobNo),
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
                  Text('Items', style: Theme.of(context).textTheme.titleMedium),
                  Row(
                    children: [
                      TextButton.icon(
                        onPressed: _downloadBulkTemplate,
                        icon: const Icon(Icons.download),
                        label: const Text('Template'),
                      ),
                      const SizedBox(width: 8),
                      TextButton.icon(
                        onPressed: _uploadBulkCsv,
                        icon: const Icon(Icons.upload_file),
                        label: const Text('Upload CSV'),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton.icon(
                        onPressed: _showBulkEntryDialog,
                        icon: const Icon(Icons.playlist_add),
                        label: const Text('Add Multiple Items'),
                      ),
                    ],
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
                        Expanded(
                          flex: 2,
                          child: Autocomplete<MaterialItem>(
                            fieldViewBuilder: (context, textEditingController, focusNode, onFieldSubmitted) {
                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                if (textEditingController.text.isEmpty && item.partNoController.text.isNotEmpty) {
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
                                    side: BorderSide(color: Theme.of(context).dividerColor),
                                  ),
                                  child: ConstrainedBox(
                                    constraints: const BoxConstraints(maxHeight: 200, maxWidth: 400),
                                    child: ListView.builder(
                                      padding: const EdgeInsets.all(8.0),
                                      itemCount: options.length,
                                      itemBuilder: (context, index) {
                                        final option = options.elementAt(index);
                                        return InkWell(
                                          onTap: () => onSelected(option),
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
                                            child: Text('${option.partNo} - ${option.description}', style: const TextStyle(fontSize: 14.0)),
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
                                  material.partNo.toLowerCase().contains(textEditingValue.text.toLowerCase()));
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
                        Expanded(
                          flex: 3,
                          child: Autocomplete<MaterialItem>(
                            fieldViewBuilder: (context, textEditingController, focusNode, onFieldSubmitted) {
                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                if (textEditingController.text.isEmpty && item.selectedMaterial != null) {
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
                                    side: BorderSide(color: Theme.of(context).dividerColor),
                                  ),
                                  child: ConstrainedBox(
                                    constraints: const BoxConstraints(maxHeight: 200, maxWidth: 600),
                                    child: ListView.builder(
                                      padding: const EdgeInsets.all(8.0),
                                      itemCount: options.length,
                                      itemBuilder: (context, index) {
                                        final option = options.elementAt(index);
                                        return InkWell(
                                          onTap: () => onSelected(option),
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
                                            child: Text(option.description, style: const TextStyle(fontSize: 14.0)),
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
                              return materials.where((material) => material.description
                                  .toLowerCase()
                                  .contains(textEditingValue.text.toLowerCase()));
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
                            validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                            onChanged: (v) => item.quantity = v,
                            onSaved: (v) => item.quantity = v,
                          ),
                        ),
                        const SizedBox(width: 8),
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
                        final now = DateFormat('yyyy-MM-dd').format(DateTime.now());
                        final all = ref.read(purchaseRequestListProvider);
                        final cfiNo = widget.existingRequest?.prNo ?? _generateCFINumber(all);

                        final allItems = <PRItem>[];
                        for (var item in _items) {
                          if (item.selectedMaterial == null) continue;
                          final material = materials.firstWhere((m) => m.description == item.selectedMaterial);
                          final prItem = PRItem(
                            materialCode: material.partNo,
                            materialDescription: material.description,
                            unit: material.unit,
                            quantity: item.quantity!,
                            prNo: cfiNo,
                          );
                          allItems.add(prItem);
                        }

                        final request = PurchaseRequest(
                          prNo: cfiNo,
                          date: now,
                          requiredBy: _requestedByController.text,
                          items: allItems,
                          jobNo: _selectedJobNo,
                        );

                        if (widget.existingRequest != null && widget.index != null) {
                          await ref.read(purchaseRequestListProvider.notifier).updateRequest(widget.index!, request);
                        } else {
                          await ref.read(purchaseRequestListProvider.notifier).addRequest(request);
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

class CFIItemFormData {
  String? selectedMaterial;
  String? quantity;
  final TextEditingController partNoController;
  final TextEditingController unitController;
  final TextEditingController materialController;

  CFIItemFormData({
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
