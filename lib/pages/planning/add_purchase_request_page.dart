// ignore_for_file: use_build_context_synchronously

import 'dart:io';

import 'package:csv/csv.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:collection/collection.dart';
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

  String _norm(String s) => s
      .replaceAll('\r', '')
      .replaceAll('\u00A0', ' ')
      .replaceAll('\u200B', '')
      .replaceAll('\uFEFF', '')
      .trim()
      .toLowerCase()
      .replaceAll(RegExp(r'\s+'), '')
      .replaceAll(RegExp(r'[^a-z0-9]'), '');

  Future<bool> _showBulkImportPreviewDialog(
    BuildContext context, {
    required List<_CsvPreviewRow> rows,
  }) async {
    return (await showDialog<bool>(
          context: context,
          builder: (context) {
            return StatefulBuilder(
              builder: (context, setState) {
                final preview = rows;

                void recomputeDuplicateErrors() {
                  const duplicateMsg = 'Duplicate material code';

                  // Remove any existing duplicate errors
                  for (final r in preview) {
                    r.errors.removeWhere((e) => e == duplicateMsg);
                  }

                  final counts = <String, int>{};
                  for (final r in preview) {
                    if (r.normalizedCode.isEmpty) continue;
                    counts[r.normalizedCode] = (counts[r.normalizedCode] ?? 0) + 1;
                  }

                  for (final r in preview) {
                    if (r.normalizedCode.isEmpty) continue;
                    if ((counts[r.normalizedCode] ?? 0) > 1) {
                      r.errors.add(duplicateMsg);
                    }
                  }
                }

                final validCount = preview.where((r) => r.errors.isEmpty).length;
                final invalidCount = preview.length - validCount;

                return AlertDialog(
                  title: const Text('Bulk Import Preview'),
                  content: SizedBox(
                    width: 980,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Valid: $validCount    Errors: $invalidCount',
                          style: TextStyle(
                            color: invalidCount > 0
                                ? Colors.orange
                                : Colors.green,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 12),
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxHeight: 420),
                          child: SingleChildScrollView(
                            scrollDirection: Axis.vertical,
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: DataTable(
                                columns: const [
                                  DataColumn(label: Text('#')),
                                  DataColumn(label: Text('Material Code')),
                                  DataColumn(label: Text('Material')),
                                  DataColumn(label: Text('Quantity')),
                                  DataColumn(label: Text('Errors')),
                                  DataColumn(label: Text('')),
                                ],
                                rows: preview.map((r) {
                                  final hasError = r.errors.isNotEmpty;
                                  final errorText = r.errors.join(', ');
                                  return DataRow(
                                    cells: [
                                      DataCell(Text(r.rowNo.toString())),
                                      DataCell(Text(r.materialCode)),
                                      DataCell(Text(r.materialDescription)),
                                      DataCell(Text(r.quantity)),
                                      DataCell(
                                        Text(
                                          errorText,
                                          style: TextStyle(
                                            color: hasError
                                                ? Colors.red
                                                : Colors.green,
                                            fontWeight: hasError
                                                ? FontWeight.w600
                                                : FontWeight.normal,
                                          ),
                                        ),
                                      ),
                                      DataCell(
                                        hasError
                                            ? IconButton(
                                                tooltip: 'Remove row',
                                                onPressed: () {
                                                  setState(() {
                                                    preview.remove(r);
                                                    recomputeDuplicateErrors();
                                                  });
                                                },
                                                icon: const Icon(
                                                    Icons.delete_outline),
                                              )
                                            : const SizedBox.shrink(),
                                      ),
                                    ],
                                  );
                                }).toList(),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        if (invalidCount > 0)
                          const Text(
                            'Only valid rows will be imported.',
                            style: TextStyle(color: Colors.orange),
                          ),
                      ],
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Cancel'),
                    ),
                    FilledButton(
                      onPressed: validCount == 0
                          ? null
                          : () => Navigator.pop(context, true),
                      child: const Text('Import'),
                    ),
                  ],
                );
              },
            );
          },
        )) ??
        false;
  }

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
          quantityController: TextEditingController(text: item.quantity),
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

  Future<void> _downloadBulkTemplate() async {
    try {
      final headers = ['Material Code', 'Material', 'Quantity'];
      final csvData = const ListToCsvConverter().convert([headers]);

      String? outputFile = await FilePicker.platform.saveFile(
        dialogTitle: 'Save Purchase Request Bulk Template',
        fileName: 'purchase_request_bulk_template.csv',
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
              content: Text('Material master is empty. Please add materials first.'),
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
              content: Text('Unsupported file type: $ext. Please upload a CSV file.'),
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
      int descIndex = -1;
      int qtyIndex = -1;

      for (int i = 0; i < headers.length; i++) {
        final h = headers[i];
        if (h.contains('material code') || h.contains('part no') || h.contains('partno')) {
          codeIndex = i;
        } else if (h.contains('material')) {
          descIndex = i;
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
      final previewRows = <_CsvPreviewRow>[];
      final normalizedCodeToRowNos = <String, List<int>>{};

      for (int i = 0; i < dataRows.length; i++) {
        final row = dataRows[i];
        final rowNo = i + 2; // + header row
        if (row.isEmpty) continue;
        if (row.length <= codeIndex || row.length <= qtyIndex) continue;

        final rawCode = row[codeIndex]?.toString().trim() ?? '';
        final rawQty = row[qtyIndex]?.toString().trim() ?? '';
        final rawDesc = descIndex != -1 && row.length > descIndex
            ? (row[descIndex]?.toString().trim() ?? '')
            : '';

        if (rawCode.isEmpty && rawQty.isEmpty && rawDesc.isEmpty) {
          continue;
        }

        final errors = <String>[];
        final normalizedCode = norm(rawCode);

        MaterialItem? matched;
        if (rawCode.isEmpty) {
          errors.add('Missing material code');
        } else {
          matched = materials.firstWhereOrNull((m) => norm(m.partNo) == normalizedCode);
          if (matched == null) {
            errors.add('Material code not found');
          }
        }

        final qty = double.tryParse(rawQty);
        if (rawQty.isEmpty) {
          errors.add('Missing quantity');
        } else if (qty == null) {
          errors.add('Invalid quantity');
        } else if (qty <= 0) {
          errors.add('Quantity must be > 0');
        }

        if (normalizedCode.isNotEmpty) {
          normalizedCodeToRowNos.putIfAbsent(normalizedCode, () => []).add(rowNo);
        }

        previewRows.add(
          _CsvPreviewRow(
            rowNo: rowNo,
            materialCode: rawCode,
            normalizedCode: normalizedCode,
            materialDescription: matched?.description ?? rawDesc,
            quantity: rawQty,
            matchedMaterial: matched,
            errors: errors,
          ),
        );
      }

      for (final e in normalizedCodeToRowNos.entries) {
        if (e.value.length > 1) {
          for (final r in previewRows.where((r) => norm(r.materialCode) == e.key)) {
            r.errors.add('Duplicate material code');
          }
        }
      }

      if (previewRows.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No rows found in CSV'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      final shouldImport = mounted
          ? await _showBulkImportPreviewDialog(context, rows: previewRows)
          : false;
      if (!shouldImport) return;

      final validRows = previewRows.where((r) => r.errors.isEmpty).toList();
      if (validRows.isEmpty) {
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

      final newItems = validRows
          .map(
            (r) => PRItemFormData(
              selectedMaterial: r.matchedMaterial!.description,
              quantity: r.quantity,
              quantityController: TextEditingController(text: r.quantity),
              partNoController:
                  TextEditingController(text: r.matchedMaterial!.partNo),
              unitController:
                  TextEditingController(text: r.matchedMaterial!.unit),
              materialController:
                  TextEditingController(text: r.matchedMaterial!.description),
            ),
          )
          .toList();

      setState(() {
        // If the first item is empty, reuse it, otherwise append
        if (_items.length == 1 &&
            _items[0].selectedMaterial == null &&
            _items[0].quantity == null) {
          final old = _items[0];
          old.dispose();
          _items[0] = newItems.first;
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
        quantityController: TextEditingController(),
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

    String norm(String s) => _norm(s);

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, dialogSetState) {
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
                      keyboardType: TextInputType.multiline,
                      textInputAction: TextInputAction.newline,
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
                          .split(RegExp(r'[\n,]+'))
                          .where((code) => code.trim().isNotEmpty)
                          .map((code) => code.trim())
                          .toList();

                      if (materialCodes.isEmpty) {
                        return;
                      }

                      // Validate material codes
                      final invalidCodes = <String>[];

                      // Replace user-entered codes with canonical Material Master partNo
                      // so the next step uses consistent values.
                      final canonicalCodes = <String>[];
                      for (final code in materialCodes) {
                        final matched = materials.firstWhereOrNull(
                          (m) => norm(m.partNo) == norm(code),
                        );
                        if (matched == null) {
                          invalidCodes.add(code);
                        } else {
                          canonicalCodes.add(matched.partNo);
                        }
                      }

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

                      materialCodes = canonicalCodes;

                      dialogSetState(() {
                        isQuantityStep = true;
                      });
                    } else {
                      // Process quantities
                      final quantities = _quantitiesController.text
                          .split(RegExp(r'[\n,]+'))
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
                      final newItems = <PRItemFormData>[];
                      for (var i = 0; i < materialCodes.length; i++) {
                        final material = materials.firstWhereOrNull(
                          (m) => norm(m.partNo) == norm(materialCodes[i]),
                        );
                        if (material == null) {
                          continue;
                        }
                        final quantity = quantities[i];

                        if (!hasUsedFirstItem &&
                            _items.isNotEmpty &&
                            _items[0].selectedMaterial == null &&
                            _items[0].quantity == null) {
                          // Use the first empty item
                          hasUsedFirstItem = true;
                          // Apply this update to the parent state so the row is rebuilt.
                          setState(() {
                            _items[0].selectedMaterial = material.description;
                            _items[0].quantity = quantity;
                            _items[0].quantityController.text = quantity;
                            _items[0].partNoController.text = material.partNo;
                            _items[0].unitController.text = material.unit;
                            _items[0].materialController.text =
                                material.description;
                          });
                        } else {
                          // Add new item
                          newItems.add(
                            PRItemFormData(
                              selectedMaterial: material.description,
                              quantity: quantity,
                              quantityController:
                                  TextEditingController(text: quantity),
                              partNoController:
                                  TextEditingController(text: material.partNo),
                              unitController:
                                  TextEditingController(text: material.unit),
                              materialController: TextEditingController(
                                  text: material.description),
                            ),
                          );
                        }
                      }

                      if (newItems.isNotEmpty) {
                        setState(() {
                          _items.addAll(newItems);
                        });
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
        child: SafeArea(
          child: SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: EdgeInsets.fromLTRB(
              24,
              24,
              24,
              24 + MediaQuery.of(context).viewInsets.bottom + 120,
            ),
            child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _requiredByController,
                      decoration: const InputDecoration(
                        labelText: 'Requested By',
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
                        ...saleOrders.map((order) {
                          final board = (order.boardNo).toString().trim();
                          final label = board.isEmpty || board == 'null'
                              ? order.jobNo
                              : '${order.jobNo} ($board)';
                          return DropdownMenuItem(
                            value: order.jobNo,
                            child: Text(label),
                          );
                        }),
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
                        // Material Code Selection
                        Expanded(
                          flex: 2,
                          child: Autocomplete<MaterialItem>(
                            fieldViewBuilder: (context, textEditingController,
                                focusNode, onFieldSubmitted) {
                              // Set initial value without triggering rebuild
                              WidgetsBinding.instance.addPostFrameCallback((_) {
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
                                  labelText: 'Material Code',
                                  border: OutlineInputBorder(),
                                ),
                                validator: (v) => v == null || v.isEmpty
                                    ? 'Required'
                                    : !materials.any((m) =>
                                            _norm(m.partNo) == _norm(v))
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
                          flex: 3,
                          child: Autocomplete<MaterialItem>(
                            fieldViewBuilder: (context, textEditingController,
                                focusNode, onFieldSubmitted) {
                              // Set initial value without triggering rebuild
                              WidgetsBinding.instance.addPostFrameCallback((_) {
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
                        // Quantity Field
                        Expanded(
                          flex: 1,
                          child: TextFormField(
                            key: ValueKey('quantity_${item.hashCode}'),
                            controller: item.quantityController,
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
                            ref
                                .read(purchaseRequestListProvider.notifier)
                                .generateOrderNumber();

                        // Process all items (both new and existing)
                        final allItems = <PRItem>[];

                        // First, process the form items
                        for (var item in _items) {
                          final code = item.partNoController.text.trim();
                          if (code.isEmpty) continue;

                          final material = materials.firstWhereOrNull(
                            (m) => _norm(m.partNo) == _norm(code),
                          );
                          if (material == null) continue;
                          if (item.quantity == null || item.quantity!.trim().isEmpty) {
                            continue;
                          }

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
      ),
    );
  }
}

class PRItemFormData {
  String? selectedMaterial;
  String? quantity;
  TextEditingController? _quantityController;
  final TextEditingController partNoController;
  final TextEditingController unitController;
  final TextEditingController materialController;

  PRItemFormData({
    required this.selectedMaterial,
    required this.quantity,
    TextEditingController? quantityController,
    required this.partNoController,
    required this.unitController,
    required this.materialController,
  }) : _quantityController = quantityController;

  TextEditingController get quantityController {
    return _quantityController ??=
        TextEditingController(text: (quantity ?? '').toString());
  }

  void dispose() {
    _quantityController?.dispose();
    partNoController.dispose();
    unitController.dispose();
    materialController.dispose();
  }
}

class _CsvPreviewRow {
  final int rowNo;
  final String materialCode;
  final String normalizedCode;
  final String materialDescription;
  final String quantity;
  final MaterialItem? matchedMaterial;
  final List<String> errors;

  _CsvPreviewRow({
    required this.rowNo,
    required this.materialCode,
    required this.normalizedCode,
    required this.materialDescription,
    required this.quantity,
    required this.matchedMaterial,
    required this.errors,
  });
}
