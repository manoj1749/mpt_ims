// ignore_for_file: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member, unused_local_variable

import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../models/material_item.dart';
import '../../models/supplier.dart';
import '../../models/pr_item.dart';
import '../../models/po_item.dart';
import '../../models/purchase_order.dart';
import '../../provider/supplier_provider.dart';
import '../../provider/material_provider.dart';
import '../../provider/purchase_request_provider.dart';
import '../../provider/purchase_order.dart';
import '../../provider/vendor_material_rate_provider.dart';
import 'package:collection/collection.dart';

class AddPurchaseOrderPage extends ConsumerStatefulWidget {
  final PurchaseOrder? existingPO;
  final int? index;

  const AddPurchaseOrderPage({
    super.key,
    this.existingPO,
    this.index,
  });

  @override
  ConsumerState<AddPurchaseOrderPage> createState() => _AddPurchaseOrderPageState();
}

class _AddPurchaseOrderPageState extends ConsumerState<AddPurchaseOrderPage> {
  final _formKey = GlobalKey<FormState>();
  Supplier? selectedSupplier;
  String? selectedJobNo;
  List<POItem> poItems = [];
  final Map<String, Map<String, TextEditingController>> qtyControllers = {};
  final Map<String, Map<String, TextEditingController>> maxQtyControllers = {};
  final TextEditingController _transportController = TextEditingController();
  final TextEditingController _deliveryRequirementsController = TextEditingController();
  Map<String, Map<String, TextEditingController>> prQtyControllers = {};

  // Track selected PRs with a map of materialCode -> Map of prNo -> bool
  Map<String, Map<String, bool>> selectedPRs = {};

  // Store Job Numbers from PRs
  Set<String> jobNumbers = {};

  // Store materials with their PR items
  Map<String, List<PRItem>> materialPRItems = {};

  @override
  void initState() {
    super.initState();
    if (widget.existingPO != null) {
      selectedSupplier = ref
          .read(supplierListProvider)
          .firstWhere((s) => s.name == widget.existingPO!.supplierName);
      _transportController.text = widget.existingPO!.transport;
      _deliveryRequirementsController.text =
          widget.existingPO!.deliveryRequirements;

      // Initialize PR quantities and selected PRs from existing PO items
      for (var item in widget.existingPO!.items) {
        selectedPRs[item.materialCode] = {};
        prQtyControllers[item.materialCode] = {};
        
        for (var detail in item.prDetails.entries) {
          selectedPRs[item.materialCode]![detail.key] = detail.value.quantity > 0;
          prQtyControllers[item.materialCode]![detail.key] = 
              TextEditingController(text: detail.value.quantity.toString());
        }

        // Initialize general stock quantities if any
        if (item.prDetails.isEmpty || item.prDetails.containsKey('General')) {
          selectedPRs[item.materialCode]!['General'] = true;
          prQtyControllers[item.materialCode]!['General'] =
              TextEditingController(text: item.quantity);
        }

        // Initialize job numbers from existing PO if editing
        for (var detail in item.prDetails.values) {
          if (detail.jobNo.isNotEmpty && detail.jobNo != 'General') {
            jobNumbers.add(detail.jobNo);
          }
        }
      }

      setState(() {
        poItems = List<POItem>.from(widget.existingPO!.items);
      });
    }
  }

  @override
  void dispose() {
    _transportController.dispose();
    _deliveryRequirementsController.dispose();
    for (var materialControllers in prQtyControllers.values) {
      for (var controller in materialControllers.values) {
        controller.dispose();
      }
    }
    super.dispose();
  }

  void _updateMaterialPRItems() {
    if (selectedSupplier == null) return;

    final materials = ref.read(materialListProvider);
    final purchaseRequests = ref
        .read(purchaseRequestListProvider)
        .where((pr) => pr.status != 'Completed')
        .toList();

    materialPRItems.clear();

    for (var pr in purchaseRequests) {
      if (selectedJobNo != null &&
          selectedJobNo != 'All' &&
          pr.jobNo != selectedJobNo) {
        continue;
      }

      for (var item in pr.items.where((item) => !item.isFullyOrdered)) {
        final material = materials.firstWhere(
          (m) => m.partNo == item.materialCode,
          orElse: () => throw Exception('Material not found: ${item.materialCode}'),
        );

        final rates = ref
            .read(vendorMaterialRateProvider.notifier)
            .getRatesForMaterial(material.slNo);

        if (rates.any((r) => r.vendorId == selectedSupplier!.name)) {
          materialPRItems.putIfAbsent(item.materialCode, () => []).add(item);
        }
      }
    }
  }

  POItem _createPOItem(MaterialItem material, List<PRItem> prItems) {
    final rates = ref
        .read(vendorMaterialRateProvider.notifier)
        .getRatesForMaterial(material.slNo);

    // Check if the supplier has a rate for this material
    final vendorRate = rates.firstWhere(
      (r) => r.vendorId == selectedSupplier!.name,
      orElse: () => throw Exception('Rate not found'),
    );

    // Default values if no rate is found
    final costPerUnit = double.parse(vendorRate.saleRate);
    final saleRate = double.parse(vendorRate.saleRate);
    final marginPerUnit = saleRate - costPerUnit;

    // Calculate total quantity from PR-wise quantities and general stock
    final prDetails = <String, ItemPRDetails>{};
    double totalQty = 0;

    // If this is a general stock item (no PR items), handle it separately
    if (prItems.isEmpty && selectedPRs[material.partNo]?['General'] == true) {
      final controller = prQtyControllers[material.partNo]?['General'];
      if (controller != null) {
        final orderQty = double.tryParse(controller.text) ?? 0;
        if (orderQty > 0) {
          prDetails['General'] = ItemPRDetails(
            prNo: 'General',
            jobNo: 'General',
            quantity: orderQty,
          );
          totalQty = orderQty;
        }
      }
    } else {
      // Handle PR-based items
      for (var prItem in prItems) {
        if (selectedPRs[material.partNo]?[prItem.prNo] == true) {
          final controller = prQtyControllers[material.partNo]?[prItem.prNo];
          if (controller != null) {
            final orderQty = double.tryParse(controller.text) ?? 0;
            if (orderQty > 0) {
              // Get the parent PR to access its job number
              final pr = ref
                  .read(purchaseRequestListProvider)
                  .firstWhere((pr) => pr.prNo == prItem.prNo);

              prDetails[prItem.prNo] = ItemPRDetails(
                prNo: prItem.prNo,
                jobNo: pr.jobNo ?? 'General',
                quantity: orderQty,
              );
              totalQty += orderQty;
            }
          }
        }
      }

      // Add general stock for PR-based items if selected
      if (selectedPRs[material.partNo]?['General'] == true) {
        final controller = prQtyControllers[material.partNo]?['General'];
        if (controller != null) {
          final orderQty = double.tryParse(controller.text) ?? 0;
          if (orderQty > 0) {
            prDetails['General'] = ItemPRDetails(
              prNo: 'General',
              jobNo: 'General',
              quantity: orderQty,
            );
            totalQty += orderQty;
          }
        }
      }
    }

    return POItem(
      materialCode: material.partNo,
      materialDescription: material.description,
      unit: material.unit,
      quantity: totalQty.toString(),
      costPerUnit: costPerUnit.toString(),
      totalCost: (costPerUnit * totalQty).toString(),
      saleRate: saleRate.toString(),
      marginPerUnit: marginPerUnit.toString(),
      totalMargin: (marginPerUnit * totalQty).toString(),
      prDetails: prDetails,
    );
  }

  // Method to get job number display text for a material
  String _getJobNumberDisplay(MaterialItem material, List<PRItem> prItems) {
    // If this is a general stock item (no PR items)
    if (prItems.isEmpty && selectedPRs[material.partNo]?['General'] == true) {
      return 'General Stock';
    }

    // Get all selected PR job numbers
    final jobNumbers = <String>{};
    for (var prItem in prItems) {
      if (selectedPRs[material.partNo]?[prItem.prNo] == true) {
        final controller = prQtyControllers[material.partNo]?[prItem.prNo];
        if (controller != null && double.tryParse(controller.text) != null && double.tryParse(controller.text)! > 0) {
          final pr = ref
              .read(purchaseRequestListProvider)
              .firstWhere((pr) => pr.prNo == prItem.prNo);
          if (pr.jobNo != null && pr.jobNo!.isNotEmpty) {
            jobNumbers.add(pr.jobNo!);
          }
        }
      }
    }

    // If no PR job numbers and general stock is selected
    if (jobNumbers.isEmpty && selectedPRs[material.partNo]?['General'] == true) {
      return 'General Stock';
    }

    // If we have PR job numbers
    if (jobNumbers.isNotEmpty) {
      return jobNumbers.join(', ');
    }

    return 'General Stock';
  }

  Widget _buildItemCard(MaterialItem material, List<PRItem> prItems) {
    // Initialize selectedPRs for this material if not already done
    if (!selectedPRs.containsKey(material.partNo)) {
      selectedPRs[material.partNo] = {};
      prQtyControllers[material.partNo] = {};
      for (var prItem in prItems) {
        selectedPRs[material.partNo]![prItem.prNo] = false;
        prQtyControllers[material.partNo]![prItem.prNo] = TextEditingController();
      }
      // Add general stock option
      selectedPRs[material.partNo]!['General'] = false;
      prQtyControllers[material.partNo]!['General'] = TextEditingController();
    }

    // Get all vendor rates for this material
    final rates = ref
        .read(vendorMaterialRateProvider.notifier)
        .getRatesForMaterial(material.slNo)
        .where((r) => double.tryParse(r.saleRate) != null)
        .toList();

    // Sort rates by price
    rates.sort((a, b) => double.parse(a.saleRate).compareTo(double.parse(b.saleRate)));

    // Find selected supplier's rate
    final selectedRate = rates.firstWhere(
      (r) => r.vendorId == selectedSupplier!.name,
      orElse: () => throw Exception('Rate not found'),
    );

    // Get lowest and highest prices
    final lowestPrice = double.parse(rates.first.saleRate);
    final highestPrice = double.parse(rates.last.saleRate);
    final selectedPrice = double.parse(selectedRate.saleRate);

    // Determine color based on rate comparison
    Color priceColor;
    Color textColor = Colors.black;

    if (selectedPrice == lowestPrice) {
      priceColor = Colors.green.shade200;
    } else if (selectedPrice == highestPrice && selectedPrice > lowestPrice) {
      priceColor = Colors.red.shade200;
      textColor = Colors.white;
    } else {
      priceColor = Colors.yellow.shade200;
    }

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      color: priceColor,
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
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: textColor,
                        ),
                      ),
                      Text(
                        'Code: ${material.partNo} | Unit: ${material.unit}',
                        style: TextStyle(
                          fontSize: 12,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Job No: ${_getJobNumberDisplay(material, prItems)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: textColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            'Rate: ₹${selectedRate.saleRate}',
                            style: TextStyle(
                              fontSize: 12,
                              color: textColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 16),
                          if (selectedPrice > lowestPrice)
                            Text(
                              'Best Rate: ₹${rates.first.saleRate} (${rates.first.vendorId})',
                              style: TextStyle(
                                fontSize: 12,
                                color: textColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                        ],
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
                1: FlexColumnWidth(1.5), // PR No
                2: FlexColumnWidth(1.5), // Job No
                3: FlexColumnWidth(1), // Need
                4: FlexColumnWidth(1), // Ordered
                5: FlexColumnWidth(1.5), // Order Qty
              },
              children: [
                TableRow(
                  children: [
                    const Text(''), // Checkbox header
                    Text('PR No',
                        style: TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: 12,
                            color: textColor)),
                    Text('Job No',
                        style: TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: 12,
                            color: textColor)),
                    Text('Need',
                        style: TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: 12,
                            color: textColor)),
                    Text('Ordered',
                        style: TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: 12,
                            color: textColor)),
                    Text('Order Qty',
                        style: TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: 12,
                            color: textColor)),
                  ],
                ),
                // Add General Stock row first
                TableRow(
                  children: [
                    // Checkbox
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Checkbox(
                        value: selectedPRs[material.partNo]?['General'] ?? false,
                        onChanged: (bool? value) {
                          setState(() {
                            selectedPRs[material.partNo]!['General'] = value ?? false;
                            if (!value!) {
                              prQtyControllers[material.partNo]!['General']!.text = '';
                            }
                          });
                        },
                      ),
                    ),
                    // PR No (General Stock)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Text('General Stock',
                          style: TextStyle(
                              fontSize: 12,
                              color: textColor,
                              fontStyle: FontStyle.italic)),
                    ),
                    // Job No
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Text('General Stock',
                          style: TextStyle(fontSize: 12, color: textColor)),
                    ),
                    // Need
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Text('-',
                          style: TextStyle(fontSize: 12, color: textColor)),
                    ),
                    // Ordered
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Text('-',
                          style: TextStyle(fontSize: 12, color: textColor)),
                    ),
                    // Order Qty
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: SizedBox(
                        height: 32,
                        child: TextFormField(
                          controller: prQtyControllers[material.partNo]!['General'],
                          enabled: selectedPRs[material.partNo]?['General'] ?? false,
                          decoration: InputDecoration(
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 8),
                            border: const OutlineInputBorder(),
                            filled: !(selectedPRs[material.partNo]?['General'] ?? false),
                            fillColor: !(selectedPRs[material.partNo]?['General'] ?? false)
                                ? Colors.grey[200]
                                : null,
                          ),
                          style: TextStyle(
                              fontSize: 12,
                              color: textColor,
                              fontWeight: FontWeight.w500),
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (!(selectedPRs[material.partNo]?['General'] ?? false)) return null;
                            if (value == null || value.isEmpty) return 'Required';
                            final qty = double.tryParse(value);
                            if (qty == null || qty <= 0) return 'Invalid';
                            return null;
                          },
                        ),
                      ),
                    ),
                  ],
                ),
                ...prItems.map((prItem) {
                  final totalQty = double.parse(prItem.quantity);
                  final orderedQty = prItem.orderedQuantities.entries
                      .where((e) => e.key != widget.existingPO?.poNo)
                      .fold(0.0, (sum, e) => sum + e.value);
                  final remainingQty = totalQty - orderedQty;

                  // Get the parent PR to access its job number
                  final parentPR = ref
                      .read(purchaseRequestListProvider)
                      .firstWhereOrNull((pr) => pr.prNo == prItem.prNo);
                  final jobNo = parentPR?.jobNo ?? 'General Stock';

                  final isInExistingPO = widget.existingPO?.items.any(
                          (item) => item.prDetails.containsKey(prItem.prNo)) ??
                      false;

                  if (remainingQty <= 0 && !isInExistingPO) {
                    return const TableRow(children: [
                      SizedBox(),
                      SizedBox(),
                      SizedBox(),
                      SizedBox(),
                      SizedBox(),
                      SizedBox()
                    ]);
                  }

                  final isSelected =
                      selectedPRs[material.partNo]?[prItem.prNo] ?? false;

                  return TableRow(
                    children: [
                      // Checkbox
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Checkbox(
                          value: isSelected,
                          onChanged: (bool? value) {
                            setState(() {
                              selectedPRs.putIfAbsent(
                                  material.partNo, () => {});
                              prQtyControllers.putIfAbsent(
                                  material.partNo, () => {});

                              selectedPRs[material.partNo]![prItem.prNo] =
                                  value ?? false;

                              prQtyControllers[material.partNo]!.putIfAbsent(
                                  prItem.prNo, () => TextEditingController());
                              
                              if (value == true) {
                                prQtyControllers[material.partNo]![prItem.prNo]!
                                    .text = remainingQty.toString();
                              } else {
                                prQtyControllers[material.partNo]![prItem.prNo]!
                                    .text = '0';
                              }
                            });
                          },
                        ),
                      ),
                      // PR No
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Text(prItem.prNo,
                            style: TextStyle(fontSize: 12, color: textColor)),
                      ),
                      // Job No
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Text(jobNo,
                            style: TextStyle(fontSize: 12, color: textColor)),
                      ),
                      // Need
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Text(totalQty.toStringAsFixed(2),
                            style: TextStyle(fontSize: 12, color: textColor)),
                      ),
                      // Ordered
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Text(orderedQty.toStringAsFixed(2),
                            style: TextStyle(fontSize: 12, color: textColor)),
                      ),
                      // Order Qty
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: SizedBox(
                          height: 32,
                          child: TextFormField(
                            controller:
                                prQtyControllers[material.partNo]![prItem.prNo],
                            enabled: isSelected,
                            decoration: InputDecoration(
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 8),
                              border: const OutlineInputBorder(),
                              filled: !isSelected,
                              fillColor: !isSelected ? Colors.grey[200] : null,
                            ),
                            style: TextStyle(
                              fontSize: 12,
                                color: textColor,
                                fontWeight: FontWeight.w500),
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              if (!isSelected) return null;
                              if (value == null || value.isEmpty) {
                                return null;
                              }
                              final qty = double.tryParse(value);
                              if (qty == null) return 'Invalid';
                              if (qty < 0) return 'Invalid';
                              if (qty > remainingQty) return 'Exceeds';
                              return null;
                            },
                            onChanged: (value) {
                              if (!isSelected) return;
                              final qty = double.tryParse(value);
                              if (qty != null && qty > remainingQty) {
                                prQtyControllers[material.partNo]?[prItem.prNo]
                                    ?.text = remainingQty.toString();
                              }
                              setState(() {});
                            },
                          ),
                        ),
                      ),
                    ],
                  );
                }).where(
                    (row) => row.children.any((cell) => cell is! SizedBox)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _onSavePressed() {
    if (!_formKey.currentState!.validate()) return;

    final materials = ref.read(materialListProvider);
    bool hasItems = false;

    final updatedPOItems = <POItem>[];

    // Process PR-based and general stock items
    for (var entry in materialPRItems.entries) {
      final material = materials.firstWhere(
        (m) => m.partNo == entry.key,
        orElse: () => throw Exception('Material not found: ${entry.key}'),
      );
      final prItems = entry.value;

      // Create POItem only if there are quantities
      final poItem = _createPOItem(material, prItems);
      if (double.parse(poItem.quantity) > 0) {
        updatedPOItems.add(poItem);
        hasItems = true;
      }
    }

    // Process newly added general stock items
    for (var entry in selectedPRs.entries) {
      if (!materialPRItems.containsKey(entry.key) && entry.value['General'] == true) {
        final material = materials.firstWhere(
          (m) => m.partNo == entry.key,
          orElse: () => throw Exception('Material not found: ${entry.key}'),
        );
        final poItem = _createPOItem(material, []);
        if (double.parse(poItem.quantity) > 0) {
          updatedPOItems.add(poItem);
          hasItems = true;
        }
      }
    }

    if (!hasItems) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one item with quantity')),
      );
      return;
    }

    if (_transportController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter Transport details')),
      );
      return;
    }

    if (_deliveryRequirementsController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter Delivery Requirements')),
      );
      return;
    }

    // Calculate tax amounts
    final subtotal = updatedPOItems.fold(
        0.0, (sum, item) => sum + double.parse(item.totalCost));

    double parseGstRate(String? value) {
      if (value == null || value.isEmpty) return 0.0;
      value = value.replaceAll('%', '').trim();
      return double.tryParse(value) ?? 0.0;
    }

    final igst = subtotal * (parseGstRate(selectedSupplier!.igst) / 100);
    final cgst = subtotal * (parseGstRate(selectedSupplier!.cgst) / 100);
    final sgst = subtotal * (parseGstRate(selectedSupplier!.sgst) / 100);
    final grandTotal = subtotal + igst + cgst + sgst;

    final poNo = widget.existingPO?.poNo ?? 'PO${DateTime.now().millisecondsSinceEpoch}';
    final now = DateFormat('yyyy-MM-dd').format(DateTime.now());

    final newPO = PurchaseOrder(
      poNo: poNo,
      poDate: widget.existingPO?.poDate ?? now,
      supplierName: selectedSupplier!.name,
      transport: _transportController.text,
      deliveryRequirements: _deliveryRequirementsController.text,
      items: updatedPOItems,
      total: subtotal,
      igst: igst,
      cgst: cgst,
      sgst: sgst,
      grandTotal: grandTotal,
    );

    // Update PR quantities and status
    final prNotifier = ref.read(purchaseRequestListProvider.notifier);
    final purchaseRequests = ref.read(purchaseRequestListProvider);

    // Only update PR quantities for PR-based items
    for (var poItem in updatedPOItems) {
      for (var prDetail in poItem.prDetails.entries) {
        if (prDetail.key == 'General') continue; // Skip general stock items

        // Find the PR and update its item quantities
        for (var pr in purchaseRequests) {
          if (pr.prNo == prDetail.value.prNo) {
            final prItem = pr.items.firstWhere(
              (item) => item.materialCode == poItem.materialCode,
              orElse: () => throw Exception('PR item not found'),
            );

            if (prDetail.value.quantity > 0) {
              // Clear any existing ordered quantity for this PO if editing
              if (widget.existingPO != null) {
                prItem.orderedQuantities.remove(widget.existingPO!.poNo);
              }

              // Add the new ordered quantity
              prItem.addOrderedQuantity(poNo, prDetail.value.quantity);

              // Update PR status
              pr.updateStatus();
              final index = purchaseRequests.indexOf(pr);
              prNotifier.updateRequest(index, pr);
            }
          }
        }
      }
    }

    // Save the PO
    if (widget.existingPO != null && widget.index != null) {
      final poNotifier = ref.read(purchaseOrderListProvider.notifier);
      poNotifier.updateOrder(widget.index!, newPO);
    } else {
      final poNotifier = ref.read(purchaseOrderListProvider.notifier);
      poNotifier.addOrder(newPO);
    }

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final suppliers = ref.watch(supplierListProvider);
    final materials = ref.watch(materialListProvider);
    final purchaseRequests = ref
        .watch(purchaseRequestListProvider)
        .where((pr) => pr.status != 'Completed')
        .toList();

    // Get unique job numbers for filter dropdown
    final jobNos = {'All'};
    for (var pr in purchaseRequests) {
      if (pr.jobNo != null && pr.jobNo!.isNotEmpty) {
        jobNos.add(pr.jobNo!);
      }
    }
    final jobNumbers = jobNos.toList()..sort();

    // Update material PR items when supplier or job number changes
    _updateMaterialPRItems();

    // Get all materials that have general stock items
    final generalStockMaterials = selectedPRs.entries
        .where((entry) => 
          entry.value['General'] == true && 
          !materialPRItems.containsKey(entry.key))
        .map((entry) => materials.firstWhere(
        (m) => m.partNo == entry.key,
        orElse: () => throw Exception('Material not found: ${entry.key}'),
        ))
        .toList();

    return Scaffold(
      appBar: AppBar(title: const Text("Purchase Order Creation")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField2<Supplier>(
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Select Supplier',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(vertical: 0),
                      ),
                      hint: const Text("Select Supplier"),
                      value: selectedSupplier,
                      items: suppliers
                          .map((supplier) => DropdownMenuItem<Supplier>(
                                value: supplier,
                                child: Text(
                                  supplier.name,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ))
                          .toList(),
                      onChanged: (val) {
                        setState(() {
                          selectedSupplier = val;
                          selectedPRs.clear();
                          selectedJobNo = 'All'; // Reset job filter when supplier changes
                        });
                      },
                      dropdownStyleData: DropdownStyleData(
                        maxHeight: 300,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      menuItemStyleData: const MenuItemStyleData(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                      ),
                      buttonStyleData: const ButtonStyleData(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        height: 60,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Add Job Number Filter Dropdown
                  Expanded(
                    child: DropdownButtonFormField2<String>(
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Filter by Job',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(vertical: 0),
                      ),
                      hint: const Text("Select Job"),
                      value: selectedJobNo ?? 'All',
                      items: jobNumbers
                          .map((jobNo) => DropdownMenuItem<String>(
                                value: jobNo,
                                child: Text(
                                  jobNo,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ))
                          .toList(),
                      onChanged: (val) {
                        setState(() {
                          selectedJobNo = val;
                          selectedPRs.clear();
                        });
                      },
                      dropdownStyleData: DropdownStyleData(
                        maxHeight: 300,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      menuItemStyleData: const MenuItemStyleData(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                      ),
                      buttonStyleData: const ButtonStyleData(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        height: 60,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                            "PO No: PO${DateTime.now().millisecondsSinceEpoch}"),
                        Text(
                            "Date: ${DateFormat('dd/MMM/yy').format(DateTime.now())}"),
                      ],
                    ),
                  ),
                ],
              ),
              TextFormField(
                controller: _transportController,
                decoration: const InputDecoration(labelText: 'Transport'),
              ),
              TextFormField(
                controller: _deliveryRequirementsController,
                decoration:
                    const InputDecoration(labelText: 'Delivery Requirements'),
              ),
              const SizedBox(height: 24),
              if (selectedSupplier != null) ...[
                Expanded(
                  child: ListView(
                    children: [
                      Text(
                        'PR-Based Items',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 16),
                      ...materialPRItems.entries.map((entry) {
                        final materialCode = entry.key;
                        final prItems = entry.value;
                        final material = materials.firstWhere(
                          (m) => m.partNo == materialCode,
                        );
                        return _buildItemCard(material, prItems);
                      }),
                      if (generalStockMaterials.isNotEmpty) ...[
                        const SizedBox(height: 24),
                        Text(
                          'General Stock Items',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 16),
                        ...generalStockMaterials.map((material) => 
                          _buildItemCard(material, [])),
                      ],
                      const SizedBox(height: 24),
                      Center(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            _showAddNewItemDialog(context);
                          },
                          icon: const Icon(Icons.add),
                          label: const Text('Add New Item'),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[900],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ListenableBuilder(
                    listenable: Listenable.merge([
                      ...qtyControllers.values
                          .expand((controllers) => controllers.values),
                    ]),
                    builder: (context, _) {
                      double total = 0;

                      // Calculate total for PR-based items
                      for (var entry in materialPRItems.entries) {
                        final material = materials.firstWhere(
                          (m) => m.partNo == entry.key,
                          orElse: () => throw Exception('Material not found'),
                        );
                        final poItem = _createPOItem(material, entry.value);
                        total += double.parse(poItem.totalCost);
                      }

                      // Calculate GST
                      final igst = total *
                          (double.tryParse(
                                  selectedSupplier!.igst.replaceAll('%', '')) ??
                              0) /
                          100;
                      final cgst = total *
                          (double.tryParse(
                                  selectedSupplier!.cgst.replaceAll('%', '')) ??
                              0) /
                          100;
                      final sgst = total *
                          (double.tryParse(
                                  selectedSupplier!.sgst.replaceAll('%', '')) ??
                              0) /
                          100;
                      final grandTotal = total + igst + cgst + sgst;

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Summary',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          Text('Sub Total: ₹${total.toStringAsFixed(2)}'),
                          if (igst > 0)
                            Text(
                                'IGST (${selectedSupplier!.igst}): ₹${igst.toStringAsFixed(2)}'),
                          if (cgst > 0)
                            Text(
                                'CGST (${selectedSupplier!.cgst}): ₹${cgst.toStringAsFixed(2)}'),
                          if (sgst > 0)
                            Text(
                                'SGST (${selectedSupplier!.sgst}): ₹${sgst.toStringAsFixed(2)}'),
                          const Divider(),
                          Text(
                            'Grand Total: ₹${grandTotal.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
                const SizedBox(height: 24),
                Center(
                  child: ElevatedButton(
                    onPressed: _onSavePressed,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 48, vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      "Save Purchase Order",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _showAddNewItemDialog(BuildContext context) {
    MaterialItem? selectedMaterial;
    final qtyController = TextEditingController();
    final materials = ref.read(materialListProvider);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New Item'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<MaterialItem>(
              decoration: const InputDecoration(
                labelText: 'Select Material',
                border: OutlineInputBorder(),
              ),
              items: materials
                  .where((m) {
                    // Only show materials that:
                    // 1. Have rates for the selected supplier
                    // 2. Are not already in the PR list
                    final rates = ref
                        .read(vendorMaterialRateProvider.notifier)
                        .getRatesForMaterial(m.slNo);
                    final hasRate = rates.any((r) => r.vendorId == selectedSupplier!.name);
                    final notInPRs = !materialPRItems.containsKey(m.partNo);
                    return hasRate && notInPRs;
                  })
                  .map((m) => DropdownMenuItem(
                        value: m,
                        child: Text('${m.partNo} - ${m.description}'),
                      ))
                  .toList(),
              onChanged: (value) {
                selectedMaterial = value;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: qtyController,
              decoration: const InputDecoration(
                labelText: 'Quantity',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (selectedMaterial != null && qtyController.text.isNotEmpty) {
                final qty = double.tryParse(qtyController.text);
                if (qty != null && qty > 0) {
                  setState(() {
                    // Add to general stock items
                    selectedPRs.putIfAbsent(selectedMaterial!.partNo, () => {})['General'] = true;
                    prQtyControllers.putIfAbsent(selectedMaterial!.partNo, () => {})['General'] =
                        TextEditingController(text: qty.toString());
                    
                    // Add an empty PR items list for this material
                    materialPRItems[selectedMaterial!.partNo] = [];
                  });
                  Navigator.pop(context);
                }
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }
}
