import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'dart:io';
import 'package:collection/collection.dart';
import 'package:csv/csv.dart';
import 'package:file_picker/file_picker.dart';
import '../../models/material_item.dart';
import '../../models/customer_scope_material_issue_master.dart';
import '../../provider/material_provider.dart';
import '../../provider/customer_scope_material_issue_master_provider.dart';
import '../../models/bill_of_preparation.dart';
import '../../models/sale_order.dart';
import '../../provider/bill_of_preparation_provider.dart';
import '../../provider/sale_order_provider.dart';

class AddBillOfPreparationPage extends ConsumerStatefulWidget {
  final BillOfPreparation? existingBop;
  final int? index;
  final String? cktTypeFilter;

  const AddBillOfPreparationPage({
    super.key,
    this.existingBop,
    this.index,
    this.cktTypeFilter,
  });

  @override
  ConsumerState<AddBillOfPreparationPage> createState() =>
      _AddBillOfPreparationPageState();
}

class _BopCsvPreviewRow {
  final int rowNo;
  final String cktTypeName;
  final String cktTypeQty;
  final String materialSource;
  final String materialCode;
  final String materialDescription;
  final String materialQty;
  final String normalizedKey;
  final MaterialItem? matchedMaterial;
  final CustomerScopeMaterialIssueMaster? matchedCustomerScopeMaterial;
  final List<String> errors;

  _BopCsvPreviewRow({
    required this.rowNo,
    required this.cktTypeName,
    required this.cktTypeQty,
    required this.materialSource,
    required this.materialCode,
    required this.materialDescription,
    required this.materialQty,
    required this.normalizedKey,
    required this.matchedMaterial,
    required this.matchedCustomerScopeMaterial,
    required this.errors,
  });
}

// New data structure for CKT type with materials
class CktTypeWithMaterials {
  String name;
  double quantity;
  List<MaterialAssignment> materials;
  
  CktTypeWithMaterials({
    required this.name,
    required this.quantity,
    this.materials = const [],
  });
  
  CktTypeWithMaterials copyWith({
    String? name,
    double? quantity,
    List<MaterialAssignment>? materials,
  }) {
    return CktTypeWithMaterials(
      name: name ?? this.name,
      quantity: quantity ?? this.quantity,
      materials: materials ?? this.materials,
    );
  }
}

class MaterialAssignment {
  String materialCode;
  String materialDescription;
  String materialRawMaterial;
  double materialQuantity;
  String materialSource; // 'material_master' or 'customer_scope'
  
  MaterialAssignment({
    required this.materialCode,
    required this.materialDescription,
    required this.materialQuantity,
    this.materialRawMaterial = '',
    this.materialSource = 'material_master',
  });
  
  MaterialAssignment copyWith({
    String? materialCode,
    String? materialDescription,
    String? materialRawMaterial,
    double? materialQuantity,
    String? materialSource,
  }) {
    return MaterialAssignment(
      materialCode: materialCode ?? this.materialCode,
      materialDescription: materialDescription ?? this.materialDescription,
      materialRawMaterial: materialRawMaterial ?? this.materialRawMaterial,
      materialQuantity: materialQuantity ?? this.materialQuantity,
      materialSource: materialSource ?? this.materialSource,
    );
  }
}

class _AddBillOfPreparationPageState extends ConsumerState<AddBillOfPreparationPage> {
  final _formKey = GlobalKey<FormState>();
  String _selectedBoardNo = '';
  List<CktTypeWithMaterials> _cktTypesWithMaterials = [];
  List<MaterialItem> materials = [];
  List<CustomerScopeMaterialIssueMaster> customerScopeMaterials = [];
  double _finalValue = 0.0;
  bool _isEditMode = false;

  final _bulkEntryController = TextEditingController();

  String _norm(String s) => s
      .replaceAll('\r', '')
      .replaceAll('\u00A0', ' ')
      .replaceAll('\u200B', '')
      .replaceAll('\uFEFF', '')
      .trim()
      .toLowerCase()
      .replaceAll(RegExp(r'\s+'), '')
      .replaceAll(RegExp(r'[^a-z0-9]'), '');

  @override
  void initState() {
    super.initState();
    // Load materials from provider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        materials = ref.read(materialListProvider);
        customerScopeMaterials = ref.read(customerScopeMaterialIssueMasterListProvider);
        print('DEBUG: Loaded ${customerScopeMaterials.length} customer scope materials');
        setState(() {});
      }
    });
    
    if (widget.existingBop != null) {
      _selectedBoardNo = widget.existingBop!.jobNo;
      // Convert existing BOP to new structure
      _cktTypesWithMaterials = [];
      for (final cktType in widget.existingBop!.cktTypes) {
        // If cktTypeFilter is provided, only include that CKT type
        if (widget.cktTypeFilter != null && cktType.name != widget.cktTypeFilter) {
          continue;
        }
        
        final materialsForCktType = <MaterialAssignment>[];
        for (final material in widget.existingBop!.materials) {
          for (final materialCktType in material.cktTypes) {
            if (materialCktType.cktTypeName == cktType.name) {
              // Find the material item to get raw material info
              final materialItem = materials.firstWhere(
                (m) => m.partNo == material.materialCode,
                orElse: () => MaterialItem(slNo: '', description: '', partNo: '', unit: '', category: '', subCategory: '', rawMaterial: ''),
              );
              materialsForCktType.add(MaterialAssignment(
                materialCode: material.materialCode,
                materialDescription: material.materialDescription,
                materialRawMaterial: materialItem.rawMaterial,
                materialQuantity: materialCktType.materialQuantity,
                materialSource: material.materialSource,
              ));
            }
          }
        }
        _cktTypesWithMaterials.add(CktTypeWithMaterials(
          name: cktType.name,
          quantity: cktType.quantity,
          materials: materialsForCktType,
        ));
      }
      _finalValue = widget.existingBop!.finalValue;
    }
  }

  @override
  void dispose() {
    _bulkEntryController.dispose();
    super.dispose();
  }

  Future<bool> _showBulkImportPreviewDialog(
    BuildContext context, {
    required List<_BopCsvPreviewRow> rows,
  }) async {
    return (await showDialog<bool>(
          context: context,
          builder: (context) {
            return StatefulBuilder(
              builder: (context, setState) {
                final preview = rows;

                void recomputeDuplicateErrors() {
                  const duplicateMsg = 'Duplicate row';
                  for (final r in preview) {
                    r.errors.removeWhere((e) => e == duplicateMsg);
                  }

                  final counts = <String, int>{};
                  for (final r in preview) {
                    if (r.normalizedKey.isEmpty) continue;
                    counts[r.normalizedKey] = (counts[r.normalizedKey] ?? 0) + 1;
                  }

                  for (final r in preview) {
                    if (r.normalizedKey.isEmpty) continue;
                    if ((counts[r.normalizedKey] ?? 0) > 1) {
                      r.errors.add(duplicateMsg);
                    }
                  }
                }

                recomputeDuplicateErrors();

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
                                  DataColumn(label: Text('CKT Type')),
                                  DataColumn(label: Text('CKT Qty')),
                                  DataColumn(label: Text('Source')),
                                  DataColumn(label: Text('Material Code')),
                                  DataColumn(label: Text('Material')),
                                  DataColumn(label: Text('Material Qty')),
                                  DataColumn(label: Text('Errors')),
                                  DataColumn(label: Text('')),
                                ],
                                rows: preview.map((r) {
                                  final hasError = r.errors.isNotEmpty;
                                  final errorText = r.errors.join(', ');
                                  return DataRow(
                                    cells: [
                                      DataCell(Text(r.rowNo.toString())),
                                      DataCell(Text(r.cktTypeName)),
                                      DataCell(Text(r.cktTypeQty)),
                                      DataCell(Text(r.materialSource)),
                                      DataCell(Text(r.materialCode)),
                                      DataCell(Text(r.materialDescription)),
                                      DataCell(Text(r.materialQty)),
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

  Future<void> _downloadBulkTemplate() async {
    try {
      final headers = [
        'CKT Type',
        'CKT Qty',
        'Material Source',
        'Material Code',
        'Material',
        'Material Qty'
      ];
      final csvData = const ListToCsvConverter().convert([headers]);

      String? outputFile = await FilePicker.platform.saveFile(
        dialogTitle: 'Save BOP Bulk Template',
        fileName: 'bop_bulk_template.csv',
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
      final matMaster = ref.read(materialListProvider);
      final cfiMaster = ref.read(customerScopeMaterialIssueMasterListProvider);
      if (matMaster.isEmpty && cfiMaster.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Material masters are empty. Please add materials first.'),
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
      int cktNameIndex = -1;
      int cktQtyIndex = -1;
      int sourceIndex = -1;
      int codeIndex = -1;
      int descIndex = -1;
      int qtyIndex = -1;

      for (int i = 0; i < headers.length; i++) {
        final h = headers[i];
        if (h.contains('ckt') && h.contains('type')) {
          cktNameIndex = i;
        } else if (h.contains('ckt') && (h.contains('qty') || h.contains('quantity'))) {
          cktQtyIndex = i;
        } else if (h.contains('source')) {
          sourceIndex = i;
        } else if (h.contains('material code') || h.contains('part no') || h.contains('partno')) {
          codeIndex = i;
        } else if (h == 'material' || h.contains('description')) {
          descIndex = i;
        } else if (h.contains('material qty') || (h.contains('material') && (h.contains('qty') || h.contains('quantity')))) {
          qtyIndex = i;
        }
      }

      if (cktNameIndex == -1 || cktQtyIndex == -1 || sourceIndex == -1 || codeIndex == -1 || qtyIndex == -1) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('CSV must have CKT Type, CKT Qty, Material Source, Material Code and Material Qty columns.'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      final dataRows = rows.sublist(1);
      final previewRows = <_BopCsvPreviewRow>[];

      for (int i = 0; i < dataRows.length; i++) {
        final row = dataRows[i];
        final rowNo = i + 2;
        if (row.isEmpty) continue;
        if (row.length <= cktNameIndex || row.length <= cktQtyIndex || row.length <= sourceIndex || row.length <= codeIndex || row.length <= qtyIndex) {
          continue;
        }

        final rawCktName = row[cktNameIndex]?.toString().trim() ?? '';
        final rawCktQty = row[cktQtyIndex]?.toString().trim() ?? '';
        final rawSource = row[sourceIndex]?.toString().trim() ?? '';
        final rawCode = row[codeIndex]?.toString().trim() ?? '';
        final rawMaterialQty = row[qtyIndex]?.toString().trim() ?? '';
        final rawDesc = descIndex != -1 && row.length > descIndex
            ? (row[descIndex]?.toString().trim() ?? '')
            : '';

        if (rawCktName.isEmpty && rawCktQty.isEmpty && rawSource.isEmpty && rawCode.isEmpty && rawMaterialQty.isEmpty && rawDesc.isEmpty) {
          continue;
        }

        final errors = <String>[];
        final normalizedCkt = _norm(rawCktName);
        final normalizedCode = _norm(rawCode);

        if (rawCktName.isEmpty) {
          errors.add('Missing CKT Type');
        }

        final cktQty = double.tryParse(rawCktQty);
        if (rawCktQty.isEmpty) {
          errors.add('Missing CKT Qty');
        } else if (cktQty == null) {
          errors.add('Invalid CKT Qty');
        } else if (cktQty <= 0) {
          errors.add('CKT Qty must be > 0');
        }

        String source = rawSource.toLowerCase();
        if (source.isEmpty) {
          errors.add('Missing Material Source');
        } else if (source != 'material_master' && source != 'customer_scope') {
          if (source.contains('material')) {
            source = 'material_master';
          } else if (source.contains('customer')) {
            source = 'customer_scope';
          } else {
            errors.add('Invalid Material Source');
          }
        }

        MaterialItem? matchedMat;
        CustomerScopeMaterialIssueMaster? matchedCfi;
        if (rawCode.isEmpty) {
          errors.add('Missing material code');
        } else {
          if (source == 'customer_scope') {
            matchedCfi = cfiMaster.firstWhereOrNull((m) => _norm(m.partNo) == normalizedCode);
            if (matchedCfi == null) {
              errors.add('Material code not found');
            }
          } else {
            matchedMat = matMaster.firstWhereOrNull((m) => _norm(m.partNo) == normalizedCode);
            if (matchedMat == null) {
              errors.add('Material code not found');
            }
          }
        }

        final matQty = double.tryParse(rawMaterialQty);
        if (rawMaterialQty.isEmpty) {
          errors.add('Missing material qty');
        } else if (matQty == null) {
          errors.add('Invalid material qty');
        } else if (matQty <= 0) {
          errors.add('Material qty must be > 0');
        }

        final desc = matchedMat?.description ?? matchedCfi?.description ?? rawDesc;
        final key = '${normalizedCkt}_${source}_${normalizedCode}';

        previewRows.add(
          _BopCsvPreviewRow(
            rowNo: rowNo,
            cktTypeName: rawCktName,
            cktTypeQty: rawCktQty,
            materialSource: source,
            materialCode: rawCode,
            materialDescription: desc,
            materialQty: rawMaterialQty,
            normalizedKey: key,
            matchedMaterial: matchedMat,
            matchedCustomerScopeMaterial: matchedCfi,
            errors: errors,
          ),
        );
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

      setState(() {
        for (final r in validRows) {
          final cktName = r.cktTypeName.trim();
          final cktQty = double.tryParse(r.cktTypeQty.trim()) ?? 0.0;
          final src = r.materialSource;
          final code = (src == 'customer_scope'
                  ? r.matchedCustomerScopeMaterial?.partNo
                  : r.matchedMaterial?.partNo) ??
              r.materialCode.trim();
          final desc = (src == 'customer_scope'
                  ? r.matchedCustomerScopeMaterial?.description
                  : r.matchedMaterial?.description) ??
              r.materialDescription.trim();
          final rawMaterial = src == 'material_master'
              ? (r.matchedMaterial?.rawMaterial ?? '')
              : '';
          final matQty = double.tryParse(r.materialQty.trim()) ?? 0.0;

          final cktIndex = _cktTypesWithMaterials.indexWhere(
              (c) => _norm(c.name) == _norm(cktName));
          CktTypeWithMaterials ckt;
          if (cktIndex == -1) {
            ckt = CktTypeWithMaterials(name: cktName, quantity: cktQty, materials: []);
            _cktTypesWithMaterials.add(ckt);
          } else {
            ckt = _cktTypesWithMaterials[cktIndex];
            if (cktQty > 0) {
              ckt = ckt.copyWith(quantity: cktQty);
              _cktTypesWithMaterials[cktIndex] = ckt;
            }
          }

          final existingMatIndex = ckt.materials.indexWhere((m) =>
              _norm(m.materialCode) == _norm(code) && m.materialSource == src);

          final updatedAssignment = MaterialAssignment(
            materialCode: code,
            materialDescription: desc,
            materialRawMaterial: rawMaterial,
            materialQuantity: matQty,
            materialSource: src,
          );

          final updatedMaterials = List<MaterialAssignment>.from(ckt.materials);
          if (existingMatIndex == -1) {
            updatedMaterials.add(updatedAssignment);
          } else {
            updatedMaterials[existingMatIndex] = updatedAssignment;
          }

          final updatedCkt = ckt.copyWith(materials: updatedMaterials);
          final idx = _cktTypesWithMaterials.indexWhere((c) => _norm(c.name) == _norm(updatedCkt.name));
          if (idx != -1) {
            _cktTypesWithMaterials[idx] = updatedCkt;
          }
        }

        _calculateFinalValue();
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Imported ${validRows.length} rows from CSV'),
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

  Future<void> _showBulkEntryDialog() async {
    _bulkEntryController.clear();

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add Multiple Items'),
          content: SizedBox(
            width: 760,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Enter rows, one per line:',
                  style: TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Format: CKT Type, CKT Qty, Material Source, Material Code, Material Qty',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _bulkEntryController,
                  maxLines: 10,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    hintText:
                        'e.g.\nTest_1,2,material_master,M001,1\nTest_1,2,customer_scope,CFI001,3',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                final lines = _bulkEntryController.text
                    .split(RegExp(r'[\n]+'))
                    .map((l) => l.trim())
                    .where((l) => l.isNotEmpty)
                    .toList();

                if (lines.isEmpty) {
                  return;
                }

                final matMaster = ref.read(materialListProvider);
                final cfiMaster =
                    ref.read(customerScopeMaterialIssueMasterListProvider);

                final previewRows = <_BopCsvPreviewRow>[];
                for (int i = 0; i < lines.length; i++) {
                  final rowNo = i + 1;
                  final parts = lines[i]
                      .split(',')
                      .map((p) => p.trim())
                      .toList();

                  final errors = <String>[];
                  if (parts.length < 5) {
                    errors.add('Invalid format');
                    previewRows.add(
                      _BopCsvPreviewRow(
                        rowNo: rowNo,
                        cktTypeName: parts.isNotEmpty ? parts[0] : '',
                        cktTypeQty: parts.length > 1 ? parts[1] : '',
                        materialSource: parts.length > 2 ? parts[2] : '',
                        materialCode: parts.length > 3 ? parts[3] : '',
                        materialDescription: '',
                        materialQty: parts.length > 4 ? parts[4] : '',
                        normalizedKey: '',
                        matchedMaterial: null,
                        matchedCustomerScopeMaterial: null,
                        errors: errors,
                      ),
                    );
                    continue;
                  }

                  final rawCkt = parts[0];
                  final rawCktQty = parts[1];
                  final rawSource = parts[2];
                  final rawCode = parts[3];
                  final rawMatQty = parts[4];

                  if (rawCkt.isEmpty) {
                    errors.add('Missing CKT Type');
                  }
                  final cktQty = double.tryParse(rawCktQty);
                  if (rawCktQty.isEmpty) {
                    errors.add('Missing CKT Qty');
                  } else if (cktQty == null || cktQty <= 0) {
                    errors.add('Invalid CKT Qty');
                  }

                  String source = rawSource.toLowerCase();
                  if (source != 'material_master' && source != 'customer_scope') {
                    if (source.contains('material')) {
                      source = 'material_master';
                    } else if (source.contains('customer')) {
                      source = 'customer_scope';
                    } else {
                      errors.add('Invalid Material Source');
                    }
                  }

                  if (rawCode.isEmpty) {
                    errors.add('Missing material code');
                  }

                  final matQty = double.tryParse(rawMatQty);
                  if (rawMatQty.isEmpty) {
                    errors.add('Missing material qty');
                  } else if (matQty == null || matQty <= 0) {
                    errors.add('Invalid material qty');
                  }

                  MaterialItem? matchedMat;
                  CustomerScopeMaterialIssueMaster? matchedCfi;
                  if (errors.isEmpty) {
                    if (source == 'customer_scope') {
                      matchedCfi = cfiMaster.firstWhereOrNull(
                          (m) => _norm(m.partNo) == _norm(rawCode));
                      if (matchedCfi == null) {
                        errors.add('Material code not found');
                      }
                    } else {
                      matchedMat = matMaster.firstWhereOrNull(
                          (m) => _norm(m.partNo) == _norm(rawCode));
                      if (matchedMat == null) {
                        errors.add('Material code not found');
                      }
                    }
                  }

                  final desc =
                      matchedMat?.description ?? matchedCfi?.description ?? '';
                  final key = '${_norm(rawCkt)}_${source}_${_norm(rawCode)}';

                  previewRows.add(
                    _BopCsvPreviewRow(
                      rowNo: rowNo,
                      cktTypeName: rawCkt,
                      cktTypeQty: rawCktQty,
                      materialSource: source,
                      materialCode: rawCode,
                      materialDescription: desc,
                      materialQty: rawMatQty,
                      normalizedKey: key,
                      matchedMaterial: matchedMat,
                      matchedCustomerScopeMaterial: matchedCfi,
                      errors: errors,
                    ),
                  );
                }

                final shouldImport = await _showBulkImportPreviewDialog(
                  context,
                  rows: previewRows,
                );
                if (!shouldImport) return;

                final validRows = previewRows.where((r) => r.errors.isEmpty).toList();
                if (validRows.isEmpty) return;

                setState(() {
                  for (final r in validRows) {
                    final cktName = r.cktTypeName.trim();
                    final cktQty = double.tryParse(r.cktTypeQty.trim()) ?? 0.0;
                    final src = r.materialSource;
                    final code = (src == 'customer_scope'
                            ? r.matchedCustomerScopeMaterial?.partNo
                            : r.matchedMaterial?.partNo) ??
                        r.materialCode.trim();
                    final desc = (src == 'customer_scope'
                            ? r.matchedCustomerScopeMaterial?.description
                            : r.matchedMaterial?.description) ??
                        r.materialDescription.trim();
                    final rawMaterial = src == 'material_master'
                        ? (r.matchedMaterial?.rawMaterial ?? '')
                        : '';
                    final matQty = double.tryParse(r.materialQty.trim()) ?? 0.0;

                    final cktIndex = _cktTypesWithMaterials.indexWhere(
                        (c) => _norm(c.name) == _norm(cktName));
                    CktTypeWithMaterials ckt;
                    if (cktIndex == -1) {
                      ckt = CktTypeWithMaterials(
                          name: cktName, quantity: cktQty, materials: []);
                      _cktTypesWithMaterials.add(ckt);
                    } else {
                      ckt = _cktTypesWithMaterials[cktIndex];
                      if (cktQty > 0) {
                        ckt = ckt.copyWith(quantity: cktQty);
                        _cktTypesWithMaterials[cktIndex] = ckt;
                      }
                    }

                    final existingMatIndex = ckt.materials.indexWhere((m) =>
                        _norm(m.materialCode) == _norm(code) &&
                        m.materialSource == src);

                    final updatedAssignment = MaterialAssignment(
                      materialCode: code,
                      materialDescription: desc,
                      materialRawMaterial: rawMaterial,
                      materialQuantity: matQty,
                      materialSource: src,
                    );

                    final updatedMaterials =
                        List<MaterialAssignment>.from(ckt.materials);
                    if (existingMatIndex == -1) {
                      updatedMaterials.add(updatedAssignment);
                    } else {
                      updatedMaterials[existingMatIndex] = updatedAssignment;
                    }

                    final updatedCkt = ckt.copyWith(materials: updatedMaterials);
                    final idx = _cktTypesWithMaterials.indexWhere(
                        (c) => _norm(c.name) == _norm(updatedCkt.name));
                    if (idx != -1) {
                      _cktTypesWithMaterials[idx] = updatedCkt;
                    }
                  }
                  _calculateFinalValue();
                });

                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(this.context).showSnackBar(
                    SnackBar(
                      content: Text('Added ${validRows.length} rows'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              },
              child: const Text('Preview'),
            ),
          ],
        );
      },
    );
  }

  void _calculateFinalValue() {
    double total = 0.0;
    for (final cktTypeWithMaterials in _cktTypesWithMaterials) {
      for (final materialAssignment in cktTypeWithMaterials.materials) {
        // Calculate: material quantity * CKT type quantity
        total += materialAssignment.materialQuantity * cktTypeWithMaterials.quantity;
      }
    }
    setState(() {
      _finalValue = total;
    });
  }

  void _addCktType() {
    setState(() {
      _cktTypesWithMaterials.add(CktTypeWithMaterials(
        name: '',
        quantity: 0,
        materials: [],
      ));
    });
  }

  void _removeCktType(int index) {
    setState(() {
      _cktTypesWithMaterials.removeAt(index);
      _calculateFinalValue();
    });
  }

  void _updateCktType(int index, CktTypeWithMaterials updated) {
    setState(() {
      _cktTypesWithMaterials[index] = updated;
      _calculateFinalValue();
    });
  }

  Future<void> _saveBillOfPreparation() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      if (_selectedBoardNo == null || _selectedBoardNo!.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select a Job Number'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      if (_cktTypesWithMaterials.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please add at least one CKT Type'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Validate CKT types have names and quantities
      for (final cktTypeWithMaterials in _cktTypesWithMaterials) {
        if (cktTypeWithMaterials.name.isEmpty || cktTypeWithMaterials.quantity <= 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('All CKT types must have names and quantities'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }
        
        // Validate materials for this CKT type (only if materials are added)
        for (final material in cktTypeWithMaterials.materials) {
          if (material.materialCode.isEmpty ||
              material.materialQuantity <= 0) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('All materials must have valid codes and quantities'),
                backgroundColor: Colors.red,
              ),
            );
            return;
          }
        }
      }

      // Convert new structure back to BOP format
      final cktTypes = _cktTypesWithMaterials.map((cktTypeWithMaterials) => CktType(
        name: cktTypeWithMaterials.name,
        quantity: cktTypeWithMaterials.quantity,
      )).toList();

      // Create materials from the new structure
      final materials = <BopMaterial>[];
      final materialMap = <String, BopMaterial>{};
      
      for (final cktTypeWithMaterials in _cktTypesWithMaterials) {
        for (final materialAssignment in cktTypeWithMaterials.materials) {
          if (!materialMap.containsKey(materialAssignment.materialCode)) {
            materialMap[materialAssignment.materialCode] = BopMaterial(
              materialCode: materialAssignment.materialCode,
              materialDescription: materialAssignment.materialDescription,
              materialSource: materialAssignment.materialSource,
              cktTypes: [],
            );
          }
          
          final material = materialMap[materialAssignment.materialCode]!;
          material.cktTypes.add(MaterialCktType(
            cktTypeName: cktTypeWithMaterials.name,
            cktTypeQuantity: cktTypeWithMaterials.quantity,
            materialQuantity: materialAssignment.materialQuantity,
          ));
        }
      }
      
      final materialsList = materialMap.values.toList();

      final notifier = ref.read(billOfPreparationProvider.notifier);
      final bop = BillOfPreparation(
        jobNo: _selectedBoardNo!,
        createdDate: DateTime.now().toString().split(' ')[0],
        cktTypes: cktTypes,
        materials: materialsList,
        finalValue: _finalValue,
      );

      try {
        if (widget.existingBop != null && widget.index != null) {
          await notifier.updateBillOfPreparation(widget.index!, bop, ref);
        } else {
          await notifier.addBillOfPreparation(bop, ref);
        }

        if (mounted) {
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final saleOrders = ref.watch(saleOrderProvider);
    final materials = ref.watch(materialListProvider);

    // Get unique job numbers from sale orders
    final jobNumbers = saleOrders
        .where((so) => so.jobNo.isNotEmpty)
        .map((so) => so.jobNo)
        .toSet()
        .toList()
      ..sort(); // Sort for consistent ordering

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.existingBop != null
            ? 'Edit Bill of Preparation'
            : 'New Bill of Preparation'),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Job Number Dropdown
              if (jobNumbers.isEmpty)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    border: Border.all(color: Colors.orange.shade200),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.warning_amber, color: Colors.orange.shade700),
                          const SizedBox(width: 8),
                          Text(
                            'No Job Numbers Available',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.orange.shade800,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Please create Sale Orders with Job Numbers first, or enter a Job Number manually:',
                        style: TextStyle(color: Colors.orange.shade700),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        decoration: const InputDecoration(
                          labelText: 'Enter Job Number Manually',
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (value) {
                          setState(() {
                            _selectedBoardNo = value;
                          });
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter a Job Number';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                )
              else
                DropdownButtonFormField2<String>(
                  value: _selectedBoardNo.isNotEmpty && jobNumbers.contains(_selectedBoardNo) ? _selectedBoardNo : null,
                  decoration: const InputDecoration(
                    labelText: 'Job Number',
                    border: OutlineInputBorder(),
                  ),
                  items: jobNumbers
                      .map((jobNo) => DropdownMenuItem(
                            value: jobNo,
                            child: Text(jobNo),
                          ))
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedBoardNo = value ?? '';
                    });
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please select a Job Number';
                    }
                    return null;
                  },
                ),
              const SizedBox(height: 24),

              // CKT Types Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'CKT Types',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
              ..._cktTypesWithMaterials.asMap().entries.map((entry) {
                final index = entry.key;
                final cktTypeWithMaterials = entry.value;
                return CktTypeWithMaterialsWidget(
                  cktTypeWithMaterials: cktTypeWithMaterials,
                  index: index,
                  onUpdate: (updated) => _updateCktType(index, updated),
                  onRemove: () => _removeCktType(index),
                  materials: materials,
                  customerScopeMaterials: customerScopeMaterials,
                );
              }),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _addCktType,
                icon: const Icon(Icons.add),
                label: const Text('Add CKT Type'),
              ),
              const SizedBox(height: 32),

              // Final Value Summary
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Final Quantity of BOP',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        _finalValue.toStringAsFixed(2),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Save Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _saveBillOfPreparation,
                  icon: const Icon(Icons.save),
                  label: const Text('Save Bill of Preparation'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class CktTypeWithMaterialsWidget extends StatelessWidget {
  final CktTypeWithMaterials cktTypeWithMaterials;
  final int index;
  final Function(CktTypeWithMaterials) onUpdate;
  final VoidCallback onRemove;
  final List<MaterialItem> materials;
  final List<CustomerScopeMaterialIssueMaster> customerScopeMaterials;

  const CktTypeWithMaterialsWidget({
    super.key,
    required this.cktTypeWithMaterials,
    required this.index,
    required this.onUpdate,
    required this.onRemove,
    required this.materials,
    required this.customerScopeMaterials,
  });

  void _addMaterial(Function(CktTypeWithMaterials) onUpdate) {
    final updatedMaterials = [...cktTypeWithMaterials.materials, MaterialAssignment(
      materialCode: '',
      materialDescription: '',
      materialQuantity: 0,
    )];
    onUpdate(cktTypeWithMaterials.copyWith(materials: updatedMaterials));
  }

  void _updateMaterial(int materialIndex, MaterialAssignment updated, Function(CktTypeWithMaterials) onUpdate) {
    final updatedMaterials = List<MaterialAssignment>.from(cktTypeWithMaterials.materials);
    updatedMaterials[materialIndex] = updated;
    onUpdate(cktTypeWithMaterials.copyWith(materials: updatedMaterials));
  }

  void _removeMaterial(int materialIndex, Function(CktTypeWithMaterials) onUpdate) {
    final updatedMaterials = List<MaterialAssignment>.from(cktTypeWithMaterials.materials);
    updatedMaterials.removeAt(materialIndex);
    onUpdate(cktTypeWithMaterials.copyWith(materials: updatedMaterials));
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // CKT Type Header Row
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    initialValue: cktTypeWithMaterials.name,
                    decoration: const InputDecoration(
                      labelText: 'CKT Type Name',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) {
                      onUpdate(cktTypeWithMaterials.copyWith(name: value));
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 1,
                  child: TextFormField(
                    initialValue: cktTypeWithMaterials.quantity.toString(),
                    decoration: const InputDecoration(
                      labelText: 'Quantity',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (value) {
                      final quantity = double.tryParse(value) ?? 0;
                      onUpdate(cktTypeWithMaterials.copyWith(quantity: quantity));
                    },
                  ),
                ),
                const SizedBox(width: 16),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: onRemove,
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Materials Section for this CKT Type
            const Text(
              'Materials for this CKT Type',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            
            // List of Materials
            ...cktTypeWithMaterials.materials.asMap().entries.map((entry) {
              final materialIndex = entry.key;
              final materialAssignment = entry.value;
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Material Source Selection
                          Container(
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Material Source',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Expanded(
                                      child: RadioListTile<String>(
                                        title: const Text('Material Master'),
                                        value: 'material_master',
                                        groupValue: materialAssignment.materialSource,
                                        onChanged: (value) {
                                          _updateMaterial(materialIndex, materialAssignment.copyWith(
                                            materialSource: value,
                                          ), onUpdate);
                                        },
                                        dense: true,
                                      ),
                                    ),
                                    Expanded(
                                      child: RadioListTile<String>(
                                        title: const Text('Customer Free Issue'),
                                        value: 'customer_scope',
                                        groupValue: materialAssignment.materialSource,
                                        onChanged: (value) {
                                          _updateMaterial(materialIndex, materialAssignment.copyWith(
                                            materialSource: value,
                                          ), onUpdate);
                                        },
                                        dense: true,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                flex: 1,
                                child: Autocomplete<Object>(
                                  key: ValueKey('code_autocomplete_${materialIndex}_${materialAssignment.materialSource}'),
                                  optionsBuilder: (textEditingValue) {
                                    final query = textEditingValue.text.toLowerCase().trim();
                                    if (materialAssignment.materialSource == 'customer_scope') {
                                      if (query.isEmpty) return customerScopeMaterials.cast<Object>();
                                      return customerScopeMaterials.where((material) =>
                                          material.partNo.toLowerCase().contains(query)).cast<Object>();
                                    } else {
                                      if (query.isEmpty) return materials.cast<Object>();
                                      return materials.where((material) =>
                                          material.partNo.toLowerCase().contains(query)).cast<Object>();
                                    }
                                  },
                                  displayStringForOption: (material) {
                                    if (material is CustomerScopeMaterialIssueMaster) {
                                      return material.partNo;
                                    }
                                    return (material as MaterialItem).partNo;
                                  },
                                  onSelected: (Object selection) {
                                    if (selection is CustomerScopeMaterialIssueMaster) {
                                      _updateMaterial(materialIndex, materialAssignment.copyWith(
                                        materialCode: selection.partNo,
                                        materialDescription: selection.description,
                                        materialRawMaterial: '',
                                      ), onUpdate);
                                    } else if (selection is MaterialItem) {
                                      _updateMaterial(materialIndex, materialAssignment.copyWith(
                                        materialCode: selection.partNo,
                                        materialDescription: selection.description,
                                        materialRawMaterial: selection.rawMaterial,
                                      ), onUpdate);
                                    }
                                  },
                                  fieldViewBuilder: (context, textEditingController, focusNode, onFieldSubmitted) {
                                    // Sync controller with current state
                                    WidgetsBinding.instance.addPostFrameCallback((_) {
                                      if (textEditingController.text != materialAssignment.materialCode) {
                                        textEditingController.text = materialAssignment.materialCode;
                                      }
                                    });
                                    return TextFormField(
                                      controller: textEditingController,
                                      focusNode: focusNode,
                                      decoration: const InputDecoration(
                                        labelText: 'Material Code',
                                        border: OutlineInputBorder(),
                                      ),
                                      onFieldSubmitted: (value) {
                                        if (materialAssignment.materialSource == 'customer_scope') {
                                          final foundMaterial = customerScopeMaterials.firstWhere(
                                            (m) => m.partNo.toLowerCase() == value.toLowerCase(),
                                            orElse: () => customerScopeMaterials.isNotEmpty ? customerScopeMaterials.first : CustomerScopeMaterialIssueMaster(slNo: '', description: '', partNo: '', unit: '', category: '', subCategory: ''),
                                          );
                                          _updateMaterial(materialIndex, materialAssignment.copyWith(
                                            materialCode: foundMaterial.partNo,
                                            materialDescription: foundMaterial.description,
                                            materialRawMaterial: '',
                                          ), onUpdate);
                                        } else {
                                          final foundMaterial = materials.firstWhere(
                                            (m) => m.partNo.toLowerCase() == value.toLowerCase(),
                                            orElse: () => materials.isNotEmpty ? materials.first : MaterialItem(slNo: '1', description: '', partNo: '', unit: '', category: '', subCategory: '', rawMaterial: ''),
                                          );
                                          _updateMaterial(materialIndex, materialAssignment.copyWith(
                                            materialCode: foundMaterial.partNo,
                                            materialDescription: foundMaterial.description,
                                            materialRawMaterial: foundMaterial.rawMaterial,
                                          ), onUpdate);
                                        }
                                      },
                                    );
                                  },
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                flex: 1,
                                child: Autocomplete<Object>(
                                  key: ValueKey('desc_autocomplete_${materialIndex}_${materialAssignment.materialSource}'),
                                  optionsBuilder: (textEditingValue) {
                                    final query = textEditingValue.text.toLowerCase().trim();
                                    if (materialAssignment.materialSource == 'customer_scope') {
                                      if (query.isEmpty) return customerScopeMaterials.cast<Object>();
                                      return customerScopeMaterials.where((material) =>
                                          material.description.toLowerCase().contains(query)).cast<Object>();
                                    } else {
                                      if (query.isEmpty) return materials.cast<Object>();
                                      return materials.where((material) =>
                                          material.description.toLowerCase().contains(query)).cast<Object>();
                                    }
                                  },
                                  displayStringForOption: (material) {
                                    if (material is CustomerScopeMaterialIssueMaster) {
                                      return material.description;
                                    }
                                    return (material as MaterialItem).description;
                                  },
                                  onSelected: (Object selection) {
                                    if (selection is CustomerScopeMaterialIssueMaster) {
                                      _updateMaterial(materialIndex, materialAssignment.copyWith(
                                        materialCode: selection.partNo,
                                        materialDescription: selection.description,
                                        materialRawMaterial: '',
                                      ), onUpdate);
                                    } else if (selection is MaterialItem) {
                                      _updateMaterial(materialIndex, materialAssignment.copyWith(
                                        materialCode: selection.partNo,
                                        materialDescription: selection.description,
                                        materialRawMaterial: selection.rawMaterial,
                                      ), onUpdate);
                                    }
                                  },
                                  fieldViewBuilder: (context, textEditingController, focusNode, onFieldSubmitted) {
                                    // Sync controller with current state
                                    WidgetsBinding.instance.addPostFrameCallback((_) {
                                      if (textEditingController.text != materialAssignment.materialDescription) {
                                        textEditingController.text = materialAssignment.materialDescription;
                                      }
                                    });
                                    return TextFormField(
                                      controller: textEditingController,
                                      focusNode: focusNode,
                                      decoration: const InputDecoration(
                                        labelText: 'Description',
                                        border: OutlineInputBorder(),
                                      ),
                                      onFieldSubmitted: (value) {
                                        if (materialAssignment.materialSource == 'customer_scope') {
                                          final foundMaterial = customerScopeMaterials.firstWhere(
                                            (m) => m.description.toLowerCase() == value.toLowerCase(),
                                            orElse: () => customerScopeMaterials.isNotEmpty ? customerScopeMaterials.first : CustomerScopeMaterialIssueMaster(slNo: '', description: '', partNo: '', unit: '', category: '', subCategory: ''),
                                          );
                                          _updateMaterial(materialIndex, materialAssignment.copyWith(
                                            materialCode: foundMaterial.partNo,
                                            materialDescription: foundMaterial.description,
                                            materialRawMaterial: '',
                                          ), onUpdate);
                                        } else {
                                          final foundMaterial = materials.firstWhere(
                                            (m) => m.description.toLowerCase() == value.toLowerCase(),
                                            orElse: () => materials.isNotEmpty ? materials.first : MaterialItem(slNo: '1', description: '', partNo: '', unit: '', category: '', subCategory: '', rawMaterial: ''),
                                          );
                                          _updateMaterial(materialIndex, materialAssignment.copyWith(
                                            materialCode: foundMaterial.partNo,
                                            materialDescription: foundMaterial.description,
                                            materialRawMaterial: foundMaterial.rawMaterial,
                                          ), onUpdate);
                                        }
                                      },
                                    );
                                  },
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                flex: 1,
                                child: TextFormField(
                                  initialValue: materialAssignment.materialQuantity.toString(),
                                  decoration: const InputDecoration(
                                    labelText: 'Material Quantity',
                                    border: OutlineInputBorder(),
                                  ),
                                  keyboardType: TextInputType.number,
                                  onChanged: (value) {
                                    final quantity = double.tryParse(value) ?? 0;
                                    _updateMaterial(materialIndex, materialAssignment.copyWith(
                                      materialQuantity: quantity,
                                    ), onUpdate);
                                  },
                                ),
                              ),
                              const SizedBox(width: 8),
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () => _removeMaterial(materialIndex, onUpdate),
                              ),
                            ],
                          ),
                          const SizedBox(height: 15),
                          Builder(
                            builder: (context) {
                              print('DEBUG: Building raw material field with: "${materialAssignment.materialRawMaterial}"');
                              return TextFormField(
                                key: ValueKey('material_raw_${materialIndex}_${materialAssignment.materialRawMaterial}'),
                                initialValue: materialAssignment.materialRawMaterial,
                                decoration: const InputDecoration(
                                  labelText: 'Raw Material',
                                  border: OutlineInputBorder(),
                                ),
                                maxLines: 1,
                                onChanged: (value) {
                                  print('DEBUG: Raw material changed to: "$value"');
                                  _updateMaterial(materialIndex, materialAssignment.copyWith(
                                    materialRawMaterial: value,
                                  ), onUpdate);
                                },
                              );
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            }),
            
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: () => _addMaterial(onUpdate),
              icon: const Icon(Icons.add),
              label: const Text('Add Material'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 36),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class MaterialWidget extends StatelessWidget {
  final BopMaterial material;
  final int index;
  final List<MaterialItem> materials;
  final Function(BopMaterial) onUpdate;
  final VoidCallback onRemove;
  final List<CktType> availableCktTypes;

  const MaterialWidget({
    super.key,
    required this.material,
    required this.index,
    required this.materials,
    required this.onUpdate,
    required this.onRemove,
    required this.availableCktTypes,
  });

  void _addMaterialCktType(Function(BopMaterial) onUpdate) {
    final updatedMaterial = material.copyWith(
      cktTypes: [...material.cktTypes, MaterialCktType(
        cktTypeName: '',
        cktTypeQuantity: 0,
        materialQuantity: 0,
      )],
    );
    onUpdate(updatedMaterial);
  }

  void _updateMaterialCktType(int cktIndex, MaterialCktType updatedCktType, Function(BopMaterial) onUpdate) {
    final updatedCktTypes = List<MaterialCktType>.from(material.cktTypes);
    updatedCktTypes[cktIndex] = updatedCktType;
    final updatedMaterial = material.copyWith(cktTypes: updatedCktTypes);
    onUpdate(updatedMaterial);
  }

  void _removeMaterialCktType(int cktIndex, Function(BopMaterial) onUpdate) {
    final updatedCktTypes = List<MaterialCktType>.from(material.cktTypes);
    updatedCktTypes.removeAt(cktIndex);
    final updatedMaterial = material.copyWith(cktTypes: updatedCktTypes);
    onUpdate(updatedMaterial);
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Material Selection Row
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Autocomplete<MaterialItem>(
                    fieldViewBuilder: (context, textEditingController, focusNode, onFieldSubmitted) {
                      textEditingController.text = material.materialCode;
                      return TextFormField(
                        controller: textEditingController,
                        focusNode: focusNode,
                        decoration: const InputDecoration(
                          labelText: 'Material Code',
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (value) {
                          final foundMaterial = materials.firstWhere(
                            (m) => m.partNo.toLowerCase() == value.toLowerCase(),
                            orElse: () => materials.isNotEmpty ? materials.first : MaterialItem(slNo: '1', description: '', partNo: '', unit: '', category: '', subCategory: ''),
                          );
                          onUpdate(material.copyWith(
                            materialCode: value,
                            materialDescription: foundMaterial.description,
                          ));
                        },
                      );
                    },
                    optionsBuilder: (textEditingValue) {
                      if (textEditingValue.text.isEmpty) {
                        return materials;
                      }
                      return materials.where((material) =>
                          material.partNo.toLowerCase().contains(textEditingValue.text.toLowerCase()));
                    },
                    displayStringForOption: (material) => material.partNo,
                    onSelected: (selectedMaterial) {
                      onUpdate(material.copyWith(
                        materialCode: selectedMaterial.partNo,
                        materialDescription: selectedMaterial.description,
                      ));
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 3,
                  child: TextFormField(
                    initialValue: material.materialDescription,
                    decoration: const InputDecoration(
                      labelText: 'Material Description',
                      border: OutlineInputBorder(),
                    ),
                    readOnly: true,
                    style: const TextStyle(color: Colors.grey),
                    key: ValueKey('desc_${material.materialCode}_${material.materialDescription}'),
                  ),
                ),
                const SizedBox(width: 16),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: onRemove,
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // CKT Types Section
            const Text(
              'CKT Types for this Material',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            
            // List of CKT Types for this material
            ...material.cktTypes.asMap().entries.map((entry) {
              final cktIndex = entry.key;
              final materialCktType = entry.value;
              
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    // CKT Type Dropdown
                    Expanded(
                      flex: 2,
                      child: DropdownButtonFormField<String>(
                        key: ValueKey('ckt_${index}_${cktIndex}_${materialCktType.cktTypeName}'),
                        value: materialCktType.cktTypeName.isNotEmpty ? materialCktType.cktTypeName : null,
                        decoration: const InputDecoration(
                          labelText: 'CKT Type',
                          border: OutlineInputBorder(),
                        ),
                        items: availableCktTypes
                            .where((ckt) => ckt.name.isNotEmpty)
                            .map((ckt) => DropdownMenuItem(
                                  value: ckt.name,
                                  child: Text('${ckt.name} (${ckt.quantity})'),
                                ))
                            .toList(),
                        onChanged: (value) {
                          final selectedCkt = availableCktTypes.firstWhere(
                            (ckt) => ckt.name == value,
                            orElse: () => CktType(name: '', quantity: 0),
                          );
                          _updateMaterialCktType(
                            cktIndex,
                            materialCktType.copyWith(
                              cktTypeName: value ?? '',
                              cktTypeQuantity: selectedCkt.quantity,
                            ),
                            onUpdate,
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Material Quantity
                    Expanded(
                      child: TextFormField(
                        key: ValueKey('qty_${index}_${cktIndex}_${materialCktType.materialQuantity}'),
                        initialValue: materialCktType.materialQuantity.toString(),
                        decoration: const InputDecoration(
                          labelText: 'Material Qty',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        onChanged: (value) {
                          final quantity = double.tryParse(value) ?? 0;
                          _updateMaterialCktType(
                            cktIndex,
                            materialCktType.copyWith(materialQuantity: quantity),
                            onUpdate,
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    IconButton(
                      icon: const Icon(Icons.remove_circle, color: Colors.red),
                      onPressed: () => _removeMaterialCktType(cktIndex, onUpdate),
                    ),
                  ],
                ),
              );
            }).toList(),
            
            // Add CKT Type Button
            ElevatedButton.icon(
              onPressed: () => _addMaterialCktType(onUpdate),
              icon: const Icon(Icons.add),
              label: const Text('Add CKT Type'),
            ),
          ],
        ),
      ),
    );
  }
}
