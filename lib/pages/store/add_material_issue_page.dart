// ignore_for_file: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member, unused_local_variable, use_build_context_synchronously, avoid_print

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
  // Track selected MRs with a map of composite key (materialCode_mrNo) -> bool
  final Map<String, bool> selectedMRs = {};
  // Track quantity controllers with composite key
  final Map<String, TextEditingController> qtyControllers = {};
  String? selectedVendor;

  // Store Job Numbers from MRs
  Set<String> jobNumbers = {};

  // Store materials with their MR items and parent MR - no merging
  List<(MaterialItem, MaterialRequestItem, MaterialRequest)> materialMRItems = [];

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
    jobNos.add('General'); // Add General option
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
      // Initialize MR quantities and selected MRs from existing issue items
      for (var item in widget.existingIssue!.items) {
        for (var mrDetail in item.mrDetails.entries) {
          final key = '${item.materialCode}_${mrDetail.key}';
          selectedMRs[key] = true;
          qtyControllers[key] = TextEditingController(
              text: item.issuedQuantities[mrDetail.key]?.toString() ?? '0');
        }
      }

      setState(() {
        issueItems = List<MaterialIssueItem>.from(widget.existingIssue!.items);
      });
    }

    // Initialize material MR items
    final materialRequests = ref
        .read(materialRequestListProvider)
        .where((mr) => mr.status != 'Completed')
        .toList();
    _updateMaterialMRItems(materialRequests);
  }

  @override
  void dispose() {
    // Dispose all quantity controllers
    for (var controller in qtyControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  MaterialIssueItem _createIssueItem(MaterialItem material,
      List<(MaterialRequestItem, MaterialRequest)> mrItems) {
    
    final Map<String, double> issuedQuantities = {};
    final Map<String, ItemMRDetails> mrDetails = {};
    double totalQty = 0.0;

    for (var (mrItem, mr) in mrItems) {
      final key = '${material.partNo}_${mrItem.issueNo}';
      if (selectedMRs[key] == true) {
        final qty = double.tryParse(qtyControllers[key]!.text) ?? 0.0;
        if (qty > 0) {
          // Make sure we get the job number from the MR
          final jobNo = mr.jobNo ?? 'General';
          print('Creating MI Item - MR: ${mrItem.issueNo}, Job No: $jobNo'); // Debug log
          
          mrDetails[mrItem.issueNo] = ItemMRDetails(
            mrNo: mrItem.issueNo,
            jobNo: jobNo,
            quantity: qty,
          );
          issuedQuantities[mrItem.issueNo] = qty;
          totalQty += qty;
        }
      }
    }

    return MaterialIssueItem(
      materialCode: material.partNo,
      materialDescription: material.description,
      unit: material.unit,
      quantity: totalQty,
      mrDetails: mrDetails,
      issuedQuantities: issuedQuantities,
    );
  }

  void _updateMaterialMRItems(List<MaterialRequest> materialRequests) {
    // Clear existing items
    materialMRItems.clear();

    // Filter by selected jobs if not "All"
    final filteredMRs = materialRequests.where((mr) {
      if (selectedJobs.contains('All')) return true;
      return selectedJobs.contains(mr.jobNo);
    }).toList();

    // Get all materials from filtered MRs
    for (var mr in filteredMRs) {
      for (var mrItem in mr.items) {
        // Get the material
        final material = ref.read(materialListProvider).firstWhere(
              (m) => m.partNo == mrItem.materialCode,
              orElse: () => MaterialItem(
                slNo: mrItem.materialCode,
                description: mrItem.materialDescription,
                partNo: mrItem.materialCode,
                unit: mrItem.unit,
                category: 'General',
                subCategory: '',
              ),
            );

        // Add to materialMRItems
        materialMRItems.add((material, mrItem, mr));

        // Initialize controllers if not exists
        final key = '${material.partNo}_${mr.issueNo}';
        if (!qtyControllers.containsKey(key)) {
          qtyControllers[key] = TextEditingController();
        }
      }
    }

    // Sort by material code
    materialMRItems.sort((a, b) => a.$1.partNo.compareTo(b.$1.partNo));
  }

  void _updateJobFilter() {
    final materialRequests = ref
        .read(materialRequestListProvider)
        .where((mr) => mr.status != 'Completed')
        .toList();
    _updateMaterialMRItems(materialRequests);
  }

  void _updateVendorFilter() {
    final materialRequests = ref
        .read(materialRequestListProvider)
        .where((mr) => mr.status != 'Completed')
        .toList();
    _updateMaterialMRItems(materialRequests);
  }

  Future<void> _saveMaterialIssue() async {
    if (!_formKey.currentState!.validate()) return;

    final issueDate = DateFormat('dd-MM-yyyy').format(DateTime.now());
    final issueNo = widget.existingIssue?.issueNo ??
        'MI${DateFormat('yyyyMMddHHmmss').format(DateTime.now())}';

    // Check if any items are selected and have valid quantities
    bool hasSelectedItems = false;
    for (var item in materialMRItems) {
      final material = item.$1;
      final mrItem = item.$2;
      final mr = item.$3;
      final key = '${material.partNo}_${mr.issueNo}';
      
      if (selectedMRs[key] == true) {
        final qty = double.tryParse(qtyControllers[key]?.text ?? '') ?? 0;
        if (qty > 0) {
          hasSelectedItems = true;
          break;
        }
      }
    }

    if (!hasSelectedItems) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please select at least one item and enter a valid quantity')),
      );
      return;
    }

    // Create issue items
    final items = <MaterialIssueItem>[];
    for (var item in materialMRItems) {
      final material = item.$1;
      final mrItem = item.$2;
      final mr = item.$3;
      final issueItem = _createIssueItem(material, [(mrItem, mr)]);
      if (issueItem.mrDetails.isNotEmpty) {
        items.add(issueItem);
      }
    }

    final materialIssue = MaterialIssue(
      issueNo: issueNo,
      issueDate: issueDate,
      issuedTo: 'Store',  // Default to Store since we removed the field
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.existingIssue == null
            ? 'Create Material Issue'
            : 'Edit Material Issue'),
        actions: [
          TextButton(
            onPressed: _saveMaterialIssue,
            child: const Text('Save', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Job Filter Button
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                      ),
                      icon: const Icon(Icons.filter_list),
                      label: Text(
                        selectedJobs.contains('All')
                            ? 'All Jobs'
                            : '${selectedJobs.length} Jobs Selected',
                      ),
                      onPressed: () async {
                        final result = await showDialog<List<String>>(
                          context: context,
                          builder: (context) => SelectJobsDialog(
                            selectedJobs: selectedJobs,
                            availableJobs: _getUniqueJobNumbers().toList(),
                          ),
                        );

                        if (result != null) {
                          setState(() {
                            selectedJobs = result;
                            // If no jobs selected, default to 'All'
                            if (selectedJobs.isEmpty) {
                              selectedJobs = ['All'];
                            }
                            // If 'All' is selected, clear other selections
                            if (selectedJobs.contains('All')) {
                              selectedJobs = ['All'];
                            }
                            _updateJobFilter();
                          });
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Vendor Filter
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: selectedVendor ?? 'All',
                      decoration: const InputDecoration(
                        labelText: 'Vendor',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      ),
                      items: _getUniqueVendors()
                          .map((vendor) => DropdownMenuItem(
                                value: vendor,
                                child: Text(vendor),
                              ))
                          .toList(),
                      onChanged: (value) {
                        setState(() {
                          selectedVendor = value == 'All' ? null : value;
                          _updateVendorFilter();
                        });
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              // Select All Row
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Checkbox(
                          value: materialMRItems.isNotEmpty &&
                              materialMRItems.every((item) {
                                final key = '${item.$1.partNo}_${item.$3.issueNo}';
                                return selectedMRs[key] == true;
                              }),
                          onChanged: (value) {
                            if (value == null) return;
                            setState(() {
                              for (var item in materialMRItems) {
                                final material = item.$1;
                                final mrItem = item.$2;
                                final mr = item.$3;
                                final key = '${material.partNo}_${mr.issueNo}';
                                selectedMRs[key] = value;
                                if (value) {
                                  final issuedQty = mrItem.issuedQuantities.values
                                      .fold(0.0, (sum, qty) => sum + qty);
                                  final remainingQty =
                                      double.parse(mrItem.quantity) - issuedQty;
                                  qtyControllers[key]?.text =
                                      remainingQty.toString();
                                } else {
                                  qtyControllers[key]?.text = '0';
                                }
                              }
                            });
                          },
                        ),
                        const Text('Select All',
                            style: TextStyle(fontWeight: FontWeight.w500)),
                      ],
                    ),
                    Text(
                        'Total Items: ${materialMRItems.length}',
                        style: const TextStyle(fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              for (var item in materialMRItems) ...[
                Builder(
                  builder: (context) {
                    final material = item.$1;
                    final mrItem = item.$2;
                    final mr = item.$3;

                    // Filter by vendor if selected
                    if (selectedVendor != null && selectedVendor != 'All') {
                      final vendorName = material.getPreferredVendorName(ref);
                      if (vendorName != selectedVendor) {
                        return const SizedBox.shrink();
                      }
                    }

                    return _buildCompactItemRow(material, mrItem, mr);
                  },
                ),
                const SizedBox(height: 8),  // Add spacing between items
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCompactItemRow(MaterialItem material, MaterialRequestItem mrItem, MaterialRequest mr) {
    final materialCode = material.partNo;
    final key = '${materialCode}_${mr.issueNo}';

    // Get stock for this job
    final stockItem = ref
        .read(stockMaintenanceProvider)
        .firstWhere((s) => s.materialCode == materialCode,
            orElse: () => StockMaintenance(
                  materialCode: material.partNo,
                  materialDescription: material.description,
                  unit: material.unit,
                  storageLocation: material.storageLocation ?? '',
                  rackNumber: material.rackNumber ?? '',
                ));

    // Get job-specific stock if available
    final jobNo = mr.jobNo ?? 'General';
    final jobDetails = stockItem.jobDetails[jobNo];
    final availableQty = jobDetails != null
        ? jobDetails.allocatedQuantity - jobDetails.consumedQuantity
        : 0.0;

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    material.description,
                    style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Stock: $availableQty ${material.unit}',
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                SizedBox(
                  width: 24,
                  child: Checkbox(
                    value: selectedMRs[key] ?? false,
                    onChanged: (value) {
                      setState(() {
                        selectedMRs[key] = value ?? false;
                        if (value == true) {
                          final issuedQty = mrItem.issuedQuantities.values
                              .fold(0.0, (sum, qty) => sum + qty);
                          final remainingQty =
                              double.parse(mrItem.quantity) - issuedQty;
                          // Only allow issuing up to available stock
                          final maxQty = remainingQty < availableQty
                              ? remainingQty
                              : availableQty;
                          qtyControllers[key]?.text = maxQty.toString();
                        } else {
                          qtyControllers[key]?.text = '0';
                        }
                      });
                    },
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Code: ${material.partNo}',
                        style: const TextStyle(fontSize: 12),
                      ),
                      Text(
                        mr.issueNo,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: Colors.blue,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Job: ${mr.jobNo ?? "General"}',
                      style: const TextStyle(fontSize: 12),
                    ),
                    Text(
                      'Req: ${mrItem.quantity} | Issued: ${mrItem.issuedQuantities.values.fold(0.0, (sum, qty) => sum + qty)}',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ),
                const SizedBox(width: 16),
                SizedBox(
                  width: 80,
                  child: TextFormField(
                    controller: qtyControllers[key],
                    keyboardType: TextInputType.number,
                    enabled: selectedMRs[key] == true,
                    style: const TextStyle(fontSize: 13),
                    decoration: InputDecoration(
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 8,
                      ),
                      hintText: '0.0',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    validator: (value) {
                      if (selectedMRs[key] == true) {
                        final qty = double.tryParse(value ?? '') ?? 0;
                        if (qty <= 0) {
                          return 'Required';
                        }
                        if (qty > availableQty) {
                          return 'Exceeds stock';
                        }
                        final issuedQty = mrItem.issuedQuantities.values
                            .fold(0.0, (sum, qty) => sum + qty);
                        final remainingQty =
                            double.parse(mrItem.quantity) - issuedQty;
                        if (qty > remainingQty) {
                          return 'Exceeds pending';
                        }
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
