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
import 'dart:math' as math;

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
  List<(MaterialItem, MaterialRequestItem, MaterialRequest)> materialMRItems =
      [];

  // Get unique job numbers from MRs
  Set<String> _getUniqueJobNumbers() {
    final Set<String> jobNos = {'All'}; // Include 'All' as default option
    final materialRequests = ref
        .read(materialRequestListProvider)
        .where((mr) => mr.status != 'Completed' && mr.status != 'Issued')
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
      final vendorName = material.getPreferredVendorName();
      if (vendorName.isNotEmpty) {
        vendors.add(vendorName);
      }
    }

    return vendors.toList()..sort();
  }

  @override
  void initState() {
    super.initState();
    // Load material requests and stock maintenance when page is opened
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        // Load stock maintenance first to get PR data
        await ref.read(stockMaintenanceProvider.notifier).loadStock();
        // Then load material requests
        await ref.read(materialRequestProvider.notifier).loadMaterialRequests();

        if (widget.existingIssue != null) {
          // Initialize MR quantities and selected MRs from existing issue items
          for (var item in widget.existingIssue!.items) {
            for (var mrDetail in item.mrDetails.entries) {
              final key = '${item.materialCode}_${mrDetail.key}';
              selectedMRs[key] = true;
              qtyControllers[key] = TextEditingController(
                  text: item.issuedQuantities[mrDetail.key]?.toString() ?? '0');
              // Also restore PR selection
              final prNo = item.prMapping[mrDetail.key];
              if (prNo != null && prNo.isNotEmpty) {
                selectedPRs[key] = prNo;
              }
            }
          }

          setState(() {
            issueItems =
                List<MaterialIssueItem>.from(widget.existingIssue!.items);
          });
        }

        // Force refresh material requests to get latest status
        await ref.read(materialRequestProvider.notifier).loadData();

        // Initialize material MR items
        final allMaterialRequests = ref.read(materialRequestListProvider);
        print('\n=== Debug: All Material Requests ===');
        for (var mr in allMaterialRequests) {
          print('MR: ${mr.issueNo}, Status: ${mr.status}, Job: ${mr.jobNo}');
        }

        final materialRequests = allMaterialRequests
            .where((mr) => mr.status != 'Completed' && mr.status != 'Issued')
            .toList();
        print('\n=== Debug: Filtered Material Requests ===');
        for (var mr in materialRequests) {
          print(
              'Filtered MR: ${mr.issueNo}, Status: ${mr.status}, Job: ${mr.jobNo}');
        }
        _updateMaterialMRItems(materialRequests);
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
    final Map<String, String> prMapping = {}; // Add PR mapping
    double totalQty = 0.0;

    print('\n=== Creating Material Issue Item ===');
    print('Material: ${material.partNo} - ${material.description}');

    for (var (mrItem, mr) in mrItems) {
      final key = '${material.partNo}_${mr.issueNo}';
      if (selectedMRs[key] == true && selectedPRs[key] != null) {
        final qty = double.tryParse(qtyControllers[key]!.text) ?? 0.0;
        if (qty > 0) {
          final jobNo = mr.jobNo ?? 'General';
          print(
              '  MR: ${mr.issueNo}, Job No: $jobNo, PR: ${selectedPRs[key]}, Quantity: $qty');

          mrDetails[mr.issueNo] = ItemMRDetails(
            mrNo: mr.issueNo,
            jobNo: jobNo,
            quantity: qty,
            prNo: selectedPRs[key], // Add PR number
          );
          issuedQuantities[mr.issueNo] = qty;
          prMapping[mr.issueNo] = selectedPRs[key]!; // Store PR mapping
          totalQty += qty;
        }
      }
    }

    print('  Total Quantity: $totalQty');
    print('  PR Mapping: $prMapping');

    return MaterialIssueItem(
      materialCode: material.partNo,
      materialDescription: material.description,
      unit: material.unit,
      quantity: totalQty,
      mrDetails: mrDetails,
      issuedQuantities: issuedQuantities,
      prMapping: prMapping, // Add PR mapping to issue item
    );
  }

  void _updateMaterialMRItems(List<MaterialRequest> materialRequests) {
    // Clear existing items
    materialMRItems.clear();

    // Get all existing material issues to check issued quantities
    final existingIssues = ref.read(materialIssueListProvider);

    // Helper function to get total issued quantity for an MR item
    double getIssuedQuantityForMRItem(String mrNo, String materialCode) {
      double totalIssued = 0.0;
      for (var issue in existingIssues) {
        for (var item in issue.items) {
          if (item.materialCode == materialCode &&
              item.mrDetails.containsKey(mrNo)) {
            totalIssued += item.mrDetails[mrNo]!.quantity;
          }
        }
      }
      return totalIssued;
    }

    // Filter MRs and their items based on actual issued quantities
    final filteredMRs = materialRequests.where((mr) {
      // Filter by selected jobs
      if (!selectedJobs.contains('All') && !selectedJobs.contains(mr.jobNo)) {
        return false;
      }

      // Check if any items in this MR still have pending quantities
      return mr.items.any((mrItem) {
        final issuedQty =
            getIssuedQuantityForMRItem(mr.issueNo, mrItem.materialCode);
        final requestedQty = double.tryParse(mrItem.quantity.toString()) ?? 0.0;
        return issuedQty < requestedQty; // Has pending quantity
      });
    }).toList();

    // Get all materials from filtered MRs
    for (var mr in filteredMRs) {
      for (var mrItem in mr.items) {
        // Check if this specific item has pending quantity
        final issuedQty =
            getIssuedQuantityForMRItem(mr.issueNo, mrItem.materialCode);
        final requestedQty = double.tryParse(mrItem.quantity.toString()) ?? 0.0;
        if (issuedQty >= requestedQty) continue; // Skip if fully issued

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

    // Sort materialMRItems by material code and MR number
    materialMRItems.sort((a, b) {
      int codeCompare = a.$1.partNo.compareTo(b.$1.partNo);
      if (codeCompare != 0) return codeCompare;
      return a.$3.issueNo.compareTo(b.$3.issueNo);
    });

    // Notify UI to rebuild
    setState(() {});
  }

  void _updateJobFilter() {
    final materialRequests = ref
        .read(materialRequestListProvider)
        .where((mr) => mr.status != 'Completed' && mr.status != 'Issued')
        .toList();
    _updateMaterialMRItems(materialRequests);
  }

  void _updateVendorFilter() {
    final materialRequests = ref
        .read(materialRequestListProvider)
        .where((mr) => mr.status != 'Completed' && mr.status != 'Issued')
        .toList();
    _updateMaterialMRItems(materialRequests);
  }

  Future<void> _saveMaterialIssue() async {
    if (!_formKey.currentState!.validate()) return;

    final issueDate = DateFormat('dd-MM-yyyy').format(DateTime.now());
    final issueNo = widget.existingIssue?.issueNo ??
        ref.read(materialIssueProvider.notifier).generateIssueNo();

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
            content: Text(
                'Please select at least one item and enter a valid quantity')),
      );
      return;
    }

    // Group items by material code
    final materialGroups =
        <String, List<(MaterialRequestItem, MaterialRequest)>>{};
    for (var item in materialMRItems) {
      final material = item.$1;
      final mrItem = item.$2;
      final mr = item.$3;
      final key = '${material.partNo}_${mr.issueNo}';

      if (selectedMRs[key] == true) {
        final qty = double.tryParse(qtyControllers[key]?.text ?? '') ?? 0;
        if (qty > 0) {
          materialGroups
              .putIfAbsent(material.partNo, () => [])
              .add((mrItem, mr));
        }
      }
    }

    // Create issue items
    final items = <MaterialIssueItem>[];
    for (var entry in materialGroups.entries) {
      final material =
          materialMRItems.firstWhere((item) => item.$1.partNo == entry.key).$1;
      final issueItem = _createIssueItem(material, entry.value);
      if (issueItem.mrDetails.isNotEmpty) {
        items.add(issueItem);
      }
    }

    final materialIssue = MaterialIssue(
      issueNo: issueNo,
      issueDate: issueDate,
      issuedTo: 'Store',
      items: items,
    );

    try {
      if (widget.existingIssue != null) {
        await ref
            .read(materialIssueProvider.notifier)
            .updateMaterialIssue(materialIssue);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Material Issue updated successfully')),
          );
        }
      } else {
        await ref
            .read(materialIssueProvider.notifier)
            .createMaterialIssue(materialIssue);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Material Issue created successfully')),
          );
        }
      }

      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
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
                        padding: const EdgeInsets.symmetric(
                            vertical: 16, horizontal: 16),
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
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                decoration: BoxDecoration(
                  color: Theme.of(context)
                      .colorScheme
                      .surfaceContainerHighest
                      .withOpacity(0.3),
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
                                final key =
                                    '${item.$1.partNo}_${item.$3.issueNo}';
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
                                  final issuedQty = mrItem
                                      .issuedQuantities.values
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
                    Text('Total Items: ${materialMRItems.length}',
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
                      final vendorName = material.getPreferredVendorName();
                      if (vendorName != selectedVendor) {
                        return const SizedBox.shrink();
                      }
                    }

                    return _buildCompactItemRow(material, mrItem, mr);
                  },
                ),
                const SizedBox(height: 8), // Add spacing between items
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCompactItemRow(
      MaterialItem material, MaterialRequestItem mrItem, MaterialRequest mr) {
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

    // Get all available PRs for this job
    final availablePRs = stockItem.prDetails.entries
        .where((entry) =>
            entry.value.jobNo == jobNo &&
            entry.value.receivedQuantity > entry.value.issuedQuantity)
        .toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Checkbox(
                  value: selectedMRs[key] ?? false,
                  onChanged: (value) {
                    setState(() {
                      selectedMRs[key] = value ?? false;
                      if (!value!) {
                        qtyControllers[key]?.text = '0';
                      }
                    });
                  },
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${material.partNo} - ${material.description}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text('MR: ${mr.issueNo} | Job: ${mr.jobNo ?? "General"}'),
                      Text(
                          'Pending Qty: ${mrItem.pendingQuantity} ${material.unit}'),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                if (selectedMRs[key] == true) ...[
                  // Show PR selection dropdown
                  DropdownButton<String>(
                    hint: const Text('Select PR'),
                    value: selectedPRs[key],
                    items: [
                      for (var pr in availablePRs)
                        DropdownMenuItem(
                          value: pr.key,
                          child: Text(
                              '${pr.key} (${pr.value.receivedQuantity - pr.value.issuedQuantity} ${material.unit})'),
                        ),
                    ],
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() {
                        selectedPRs[key] = value;
                        // Update available quantity based on selected PR
                        final prDetails = stockItem.prDetails[value]!;
                        final availableQty = prDetails.receivedQuantity -
                            prDetails.issuedQuantity;
                        qtyControllers[key]?.text = math
                            .min(availableQty, mrItem.pendingQuantity)
                            .toString();
                      });
                    },
                  ),
                  const SizedBox(width: 16),
                  SizedBox(
                    width: 120,
                    child: TextFormField(
                      controller: qtyControllers[key],
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Issue Qty',
                        suffixText: material.unit,
                        border: const OutlineInputBorder(),
                      ),
                      enabled: selectedPRs[key] != null,
                      validator: (value) {
                        if (selectedMRs[key] == true) {
                          if (selectedPRs[key] == null) {
                            return 'Select PR';
                          }
                          final qty = double.tryParse(value ?? '') ?? 0;
                          if (qty <= 0) {
                            return 'Required';
                          }
                          final prDetails =
                              stockItem.prDetails[selectedPRs[key]]!;
                          final availableQty = prDetails.receivedQuantity -
                              prDetails.issuedQuantity;
                          if (qty > availableQty) {
                            return 'Exceeds PR';
                          }
                          if (qty > mrItem.pendingQuantity) {
                            return 'Exceeds MR';
                          }
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Add this field to track selected PRs
  final Map<String, String> selectedPRs = {};
}
