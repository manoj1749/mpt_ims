// ignore_for_file: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member, unused_local_variable, use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../models/material_item.dart';
import '../../models/material_request.dart';
import '../../models/material_request_item.dart';
import '../../models/material_issue.dart';
import '../../models/material_issue_item.dart';
import '../../models/stock_maintenance.dart';
import '../../provider/material_provider.dart';
import '../../provider/material_request_provider.dart';
import '../../provider/material_issue_provider.dart';
import '../../provider/stock_maintenance_provider.dart';
import '../store/select_jobs_dialog.dart';

class AddMaterialIssuePage extends ConsumerStatefulWidget {
  final MaterialIssue? existingIssue;
  final int? index;

  const AddMaterialIssuePage({
    super.key,
    this.existingIssue,
    this.index,
  });

  @override
  ConsumerState<AddMaterialIssuePage> createState() =>
      _AddMaterialIssuePageState();
}

class _AddMaterialIssuePageState extends ConsumerState<AddMaterialIssuePage> {
  final _formKey = GlobalKey<FormState>();
  List<String> selectedJobs = ['All'];
  List<MaterialIssueItem> issueItems = [];
  final Map<String, Map<String, TextEditingController>> qtyControllers = {};
  final TextEditingController _issuedToController = TextEditingController();
  String? selectedVendor;

  // Track selected MRs with a map of materialCode -> Map of mrNo -> bool
  Map<String, Map<String, bool>> selectedMRs = {};

  // Store Job Numbers from MRs
  Set<String> jobNumbers = {};

  // Store materials with their MR items and parent MR
  Map<String, List<(MaterialRequestItem, MaterialRequest)>> materialMRItems = {};

  // Get unique job numbers from MRs
  Set<String> _getUniqueJobNumbers() {
    final Set<String> jobNos = {'All'}; // Include 'All' as default option
    final materialRequests = ref
        .read(materialRequestListProvider)
        .where((mr) => mr.status != 'Completed')
        .toList();

    for (var mr in materialRequests) {
      if (mr.jobNo != null && mr.jobNo!.isNotEmpty) {
        jobNos.add(mr.jobNo!);
      }
    }
    return jobNos;
  }

  // Get unique vendors from materials
  List<String> _getUniqueVendors() {
    final Set<String> vendors = {'All'};
    final materials = ref.read(materialListProvider);
    
    for (var material in materials) {
      final vendorName = material.getPreferredVendorName(ref);
      if (vendorName.isNotEmpty) {
        vendors.add(vendorName);
      }
    }
    
    return vendors.toList()..sort();
  }

  @override
  void initState() {
    super.initState();
    if (widget.existingIssue != null) {
      _issuedToController.text = widget.existingIssue!.issuedTo;

      // Initialize MR quantities and selected MRs from existing issue items
      for (var item in widget.existingIssue!.items) {
        selectedMRs[item.materialCode] = {};
        qtyControllers[item.materialCode] = {};

        for (var detail in item.mrDetails.entries) {
          selectedMRs[item.materialCode]![detail.key] = true;
          qtyControllers[item.materialCode]![detail.key] =
              TextEditingController(text: detail.value.quantity.toString());
        }

        // Initialize job numbers from existing issue if editing
        for (var detail in item.mrDetails.values) {
          if (detail.jobNo.isNotEmpty) {
            jobNumbers.add(detail.jobNo);
          }
        }
      }

      setState(() {
        issueItems = List<MaterialIssueItem>.from(widget.existingIssue!.items);
      });
    }

    // Initialize material MR items
    _updateMaterialMRItems();
  }

  @override
  void dispose() {
    _issuedToController.dispose();
    for (var materialControllers in qtyControllers.values) {
      for (var controller in materialControllers.values) {
        controller.dispose();
      }
    }
    super.dispose();
  }

  void _updateMaterialMRItems() {
    final materials = ref.read(materialListProvider);
    final materialRequests = ref
        .read(materialRequestListProvider)
        .where((mr) => mr.status != 'Completed')
        .toList();

    print('Found ${materialRequests.length} material requests');
    for (var mr in materialRequests) {
      print('MR ${mr.issueNo}: status=${mr.status}, jobNo=${mr.jobNo}, items=${mr.items.length}');
      for (var item in mr.items) {
        print('  Item: code=${item.materialCode}, issueNo=${item.issueNo}, quantity=${item.quantity}');
      }
    }

    materialMRItems.clear();

    for (var mr in materialRequests) {
      print('\nProcessing MR ${mr.issueNo}:');
      // Skip if MR's job doesn't match selected jobs
      if (!selectedJobs.contains('All') && !selectedJobs.contains(mr.jobNo)) {
        print('Skipping MR ${mr.issueNo} - job ${mr.jobNo} not in selected jobs $selectedJobs');
        continue;
      }

      print('Checking items in MR ${mr.issueNo}:');
      final itemsWithEmptyIssueNo = mr.items.where((item) => item.issueNo.isEmpty).toList();
      print('Found ${itemsWithEmptyIssueNo.length} items with empty issueNo');

      for (var item in itemsWithEmptyIssueNo) {
        print('\nProcessing item ${item.materialCode}:');
        try {
          print('Looking for material ${item.materialCode} in materials list');
          final material = materials.firstWhere(
            (m) => m.partNo == item.materialCode,
            orElse: () {
              print('Material not found: ${item.materialCode}');
              throw Exception('Material not found: ${item.materialCode}');
            },
          );
          print('Found material: ${material.partNo} - ${material.description}');

          // Add the item to materialMRItems without stock check
          print('Adding item ${item.materialCode} to material MR items');
          materialMRItems.putIfAbsent(item.materialCode, () => []).add((item, mr));
        } catch (e) {
          print('Error processing item ${item.materialCode}: $e');
        }
      }
    }
    print('\nFinal material MR items: ${materialMRItems.length} materials');
    materialMRItems.forEach((code, items) {
      print('Material $code: ${items.length} items');
    });
  }

  MaterialIssueItem _createIssueItem(MaterialItem material, List<(MaterialRequestItem, MaterialRequest)> mrItems) {
    // Calculate total quantity from MR-wise quantities
    final mrDetails = <String, ItemMRDetails>{};
    double totalQty = 0;

    // Handle MR-based items
    for (var (mrItem, mr) in mrItems) {
      if (selectedMRs[material.partNo]?[mrItem.issueNo] == true) {
        final controller = qtyControllers[material.partNo]?[mrItem.issueNo];
        if (controller != null) {
          final issueQty = double.tryParse(controller.text) ?? 0;
          if (issueQty > 0) {
            mrDetails[mrItem.issueNo] = ItemMRDetails(
              mrNo: mrItem.issueNo,
              jobNo: mr.jobNo ?? '',
              quantity: issueQty,
            );
            totalQty += issueQty;
          }
        }
      }
    }

    return MaterialIssueItem(
      materialCode: material.partNo,
      materialDescription: material.description,
      unit: material.unit,
      quantity: totalQty,
      mrDetails: mrDetails,
    );
  }

  Future<void> _saveMaterialIssue() async {
    if (!_formKey.currentState!.validate()) return;

    final issueDate = DateFormat('dd-MM-yyyy').format(DateTime.now());
    final issueNo = widget.existingIssue?.issueNo ??
        'MI${DateFormat('yyyyMMddHHmmss').format(DateTime.now())}';

    // Create issue items
    final items = <MaterialIssueItem>[];
    for (var entry in materialMRItems.entries) {
      final material = ref
          .read(materialListProvider)
          .firstWhere((m) => m.partNo == entry.key);
      final issueItem = _createIssueItem(material, entry.value);
      if (issueItem.mrDetails.isNotEmpty) {
        items.add(issueItem);
      }
    }

    if (items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one item to issue')),
      );
      return;
    }

    final materialIssue = MaterialIssue(
      issueNo: issueNo,
      issueDate: issueDate,
      issuedTo: _issuedToController.text,
      items: items,
    );

    try {
      if (widget.existingIssue != null) {
        await ref
            .read(materialIssueProvider.notifier)
            .updateMaterialIssue(materialIssue);
      } else {
        await ref
            .read(materialIssueProvider.notifier)
            .createMaterialIssue(materialIssue);
      }

      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  Widget _buildItemCard(MaterialItem material, List<(MaterialRequestItem, MaterialRequest)> mrItems) {
    // Initialize selectedMRs for this material if not already done
    if (!selectedMRs.containsKey(material.partNo)) {
      selectedMRs[material.partNo] = {};
      qtyControllers[material.partNo] = {};
      for (var mrTuple in mrItems) {
        final mrItem = mrTuple.$1;
        selectedMRs[material.partNo]![mrItem.issueNo] = false;
        qtyControllers[material.partNo]![mrItem.issueNo] = TextEditingController();
      }
    }

    // Get current stock level
    final stockItem = ref.read(stockMaintenanceProvider)
        .firstWhere((stock) => stock.materialCode == material.partNo,
            orElse: () => StockMaintenance(
              materialCode: material.partNo,
              materialDescription: material.description,
              unit: material.unit,
              storageLocation: material.storageLocation ?? '',
              rackNumber: material.rackNumber ?? '',
            ));
    final stockLevel = stockItem.currentStock;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        material.description,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        'Code: ${material.partNo} | Unit: ${material.unit}',
                        style: const TextStyle(
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Current Stock: $stockLevel',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 16),
            Table(
              columnWidths: const {
                0: FlexColumnWidth(0.5), // Checkbox column
                1: FlexColumnWidth(1.5), // MR No
                2: FlexColumnWidth(1.5), // Job No
                3: FlexColumnWidth(1), // Requested
                4: FlexColumnWidth(1), // Issued
                5: FlexColumnWidth(1.5), // Issue Qty
              },
              children: [
                TableRow(
                  children: [
                    // Add Select All checkbox
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Checkbox(
                        value: mrItems.every((mrTuple) {
                          final mrItem = mrTuple.$1;
                          return selectedMRs[material.partNo]?[mrItem.issueNo] == true;
                        }),
                        side: const BorderSide(color: Colors.white, width: 1.5),
                        fillColor: MaterialStateProperty.resolveWith<Color>((Set<MaterialState> states) {
                          if (states.contains(MaterialState.selected)) {
                            return Colors.blue;
                          }
                          return Colors.transparent;
                        }),
                        checkColor: Colors.white,
                        onChanged: (bool? value) {
                          setState(() {
                            for (var mrTuple in mrItems) {
                              final mrItem = mrTuple.$1;
                              selectedMRs[material.partNo]![mrItem.issueNo] = value ?? false;
                              if (value == true) {
                                final remainingQty = double.parse(mrItem.quantity) - 
                                    mrItem.issuedQuantities.values.fold(0.0, (sum, qty) => sum + qty);
                                qtyControllers[material.partNo]![mrItem.issueNo]?.text = 
                                    remainingQty.toString();
                              } else {
                                qtyControllers[material.partNo]![mrItem.issueNo]?.text = '0';
                              }
                            }
                          });
                        },
                      ),
                    ),
                    const Text('MR No',
                        style: TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: 12)),
                    const Text('Job No',
                        style: TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: 12)),
                    const Text('Requested',
                        style: TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: 12)),
                    const Text('Issued',
                        style: TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: 12)),
                    const Text('Issue Qty',
                        style: TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: 12)),
                  ],
                ),
                ...mrItems.map((mrTuple) {
                  final mrItem = mrTuple.$1;
                  final mr = mrTuple.$2;
                  final issuedQty = mrItem.issuedQuantities.values.fold(0.0, (sum, qty) => sum + qty);
                  final remainingQty = double.parse(mrItem.quantity) - issuedQty;

                  return TableRow(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Checkbox(
                          value: selectedMRs[material.partNo]?[mrItem.issueNo] ?? false,
                          side: const BorderSide(color: Colors.white, width: 1.5),
                          fillColor: MaterialStateProperty.resolveWith<Color>((Set<MaterialState> states) {
                            if (states.contains(MaterialState.selected)) {
                              return Colors.blue;
                            }
                            return Colors.transparent;
                          }),
                          checkColor: Colors.white,
                          onChanged: (bool? value) {
                            setState(() {
                              selectedMRs[material.partNo]![mrItem.issueNo] = value ?? false;
                              if (value == true) {
                                qtyControllers[material.partNo]![mrItem.issueNo]?.text = 
                                    remainingQty.toString();
                              } else {
                                qtyControllers[material.partNo]![mrItem.issueNo]?.text = '0';
                              }
                            });
                          },
                        ),
                      ),
                      Text(mrItem.issueNo,
                          style: const TextStyle(fontSize: 12)),
                      Text(mr.jobNo ?? '',
                          style: const TextStyle(fontSize: 12)),
                      Text(mrItem.quantity,
                          style: const TextStyle(fontSize: 12)),
                      Text(issuedQty.toString(),
                          style: const TextStyle(fontSize: 12)),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: SizedBox(
                          height: 32,
                          child: TextFormField(
                            controller: qtyControllers[material.partNo]![mrItem.issueNo],
                            enabled: selectedMRs[material.partNo]?[mrItem.issueNo] ?? false,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            style: const TextStyle(fontSize: 12),
                            decoration: const InputDecoration(
                              isDense: true,
                              contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                              border: OutlineInputBorder(),
                            ),
                            validator: (value) {
                              if (selectedMRs[material.partNo]?[mrItem.issueNo] == true) {
                                if (value == null || value.isEmpty) {
                                  return 'Required';
                                }
                                final qty = double.tryParse(value);
                                if (qty == null) {
                                  return 'Invalid number';
                                }
                                if (qty <= 0) {
                                  return 'Must be > 0';
                                }
                                if (qty > remainingQty) {
                                  return 'Exceeds request';
                                }
                                if (qty > stockLevel) {
                                  return 'Exceeds stock';
                                }
                              }
                              return null;
                            },
                          ),
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.existingIssue != null
            ? 'Edit Material Issue'
            : 'New Material Issue'),
        actions: [
          TextButton(
            onPressed: _saveMaterialIssue,
            child: const Text('Save',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _issuedToController,
                      decoration: const InputDecoration(
                        labelText: 'Issued To',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter who the materials are issued to';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  DropdownButton<String>(
                    value: selectedVendor ?? 'All',
                    items: _getUniqueVendors()
                        .map((vendor) => DropdownMenuItem(
                              value: vendor,
                              child: Text(vendor),
                            ))
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedVendor = value == 'All' ? null : value;
                        _updateMaterialMRItems();
                      });
                    },
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton.icon(
                    onPressed: () async {
                      final selectedJobsList = await showDialog<List<String>>(
                        context: context,
                        builder: (context) => SelectJobsDialog(
                          availableJobs: _getUniqueJobNumbers().toList(),
                          selectedJobs: selectedJobs,
                        ),
                      );
                      if (selectedJobsList != null) {
                        setState(() {
                          selectedJobs = selectedJobsList;
                          _updateMaterialMRItems();
                        });
                      }
                    },
                    icon: const Icon(Icons.filter_list),
                    label: const Text('Filter Jobs'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ...materialMRItems.entries.map((entry) {
                final material = ref
                    .read(materialListProvider)
                    .firstWhere((m) => m.partNo == entry.key);
                    
                // Filter by vendor if selected
                if (selectedVendor != null && selectedVendor != 'All') {
                  final vendorName = material.getPreferredVendorName(ref);
                  if (vendorName != selectedVendor) {
                    return const SizedBox.shrink();
                  }
                }
                
                return _buildItemCard(material, entry.value);
              }).toList(),
            ],
          ),
        ),
      ),
    );
  }
} 