// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import '../../models/store_inward.dart';
import '../../provider/store_inward_provider.dart';
import '../../provider/material_provider.dart';
import '../../models/material_item.dart';
import '../../models/supplier.dart';
import '../../provider/supplier_provider.dart';
import '../../models/purchase_order.dart';
import '../../models/po_item.dart';
import '../../provider/purchase_order.dart';
import 'package:pluto_grid/pluto_grid.dart';
import 'package:mpt_ims/pages/store/select_jobs_dialog.dart';

class AddStoreInwardPage extends ConsumerStatefulWidget {
  final StoreInward? existingGR;
  final int? index;

  const AddStoreInwardPage({
    super.key,
    this.existingGR,
    this.index,
  });

  @override
  ConsumerState<AddStoreInwardPage> createState() => _AddStoreInwardPageState();
}

class _AddStoreInwardPageState extends ConsumerState<AddStoreInwardPage> {
  final _formKey = GlobalKey<FormState>();
  final _grnDateController = TextEditingController();
  final _invoiceNoController = TextEditingController();
  final _invoiceDateController = TextEditingController();
  final _invoiceAmountController = TextEditingController();
  final _receivedByController = TextEditingController();
  final _checkedByController = TextEditingController();

  Supplier? selectedSupplier;
  List<String> selectedJobs = ['All'];
  Map<String, Map<String, Map<String, TextEditingController>>>
      prQtyControllers = {};
  Map<String, Map<String, Map<String, bool>>> selectedPRs = {};
  Map<String, Map<String, PlutoGridStateManager?>> gridStateManagers = {};
  bool _isLoading = false;

  String _generateGRNNo() {
    return ref.read(storeInwardProvider.notifier).generateGRNNumber();
  }

  @override
  void initState() {
    super.initState();
    if (widget.existingGR != null) {
      selectedSupplier = ref
          .read(supplierListProvider)
          .firstWhere((s) => s.name == widget.existingGR!.supplierName);
      _grnDateController.text = widget.existingGR!.grnDate;
      _invoiceNoController.text = widget.existingGR!.invoiceNo;
      _invoiceDateController.text = widget.existingGR!.invoiceDate;
      _invoiceAmountController.text = widget.existingGR!.invoiceAmount;
      _receivedByController.text = widget.existingGR!.receivedBy;
      _checkedByController.text = widget.existingGR!.checkedBy;

      // Initialize PR quantities from existing GR
      for (var item in widget.existingGR!.items) {
        selectedPRs[item.materialCode] = {};
        prQtyControllers[item.materialCode] = {};

        for (var poEntry in item.prQuantities.entries) {
          final poNo = poEntry.key;
          selectedPRs[item.materialCode]![poNo] = {};
          prQtyControllers[item.materialCode]![poNo] = {};

          for (var prEntry in poEntry.value.entries) {
            final prNo = prEntry.key;
            selectedPRs[item.materialCode]![poNo]![prNo] = true;
            prQtyControllers[item.materialCode]![poNo]![prNo] =
                TextEditingController(text: prEntry.value.toString());
          }
        }
      }
    } else {
      _grnDateController.text = DateFormat('yyyy-MM-dd').format(DateTime.now());
      _invoiceAmountController.text = '0.00';
    }
  }

  @override
  void dispose() {
    _grnDateController.dispose();
    _invoiceNoController.dispose();
    _invoiceDateController.dispose();
    _invoiceAmountController.dispose();
    _receivedByController.dispose();
    _checkedByController.dispose();
    for (var materialControllers in prQtyControllers.values) {
      for (var poControllers in materialControllers.values) {
        for (var controller in poControllers.values) {
          controller.dispose();
        }
      }
    }
    super.dispose();
  }

  // Update _getUniqueJobNumbers to return Set instead of List
  Set<String> _getUniqueJobNumbers(List<PurchaseOrder> purchaseOrders) {
    final Set<String> jobNos = {'All'}; // Include 'All' as default option
    for (var po in purchaseOrders) {
      for (var jobNo in po.jobNumbers) {
        jobNos.add(jobNo);
      }
      if (po.hasGeneralStockItems) {
        jobNos.add('General');
      }
    }
    return jobNos;
  }

  // Helper method to calculate total invoice amount
  void _updateInvoiceAmount() {
    double total = 0.0;
    for (var entry in prQtyControllers.entries) {
      final materialCode = entry.key;
      final poControllers = entry.value;

      for (var poEntry in poControllers.entries) {
        final poNo = poEntry.key;
        final prControllers = poEntry.value;

        // Get material cost from PO
        final po = ref.read(purchaseOrderListProvider).firstWhere(
              (po) => po.poNo == poNo,
              orElse: () => PurchaseOrder(
                poNo: '',
                poDate: '',
                supplierName: '',
                transport: '',
                deliveryRequirements: '',
                items: [],
                total: 0,
                igst: 0,
                cgst: 0,
                sgst: 0,
                grandTotal: 0,
              ),
            );

        POItem? poItem;
        try {
          poItem =
              po.items.firstWhere((item) => item.materialCode == materialCode);
        } catch (_) {
          poItem = null;
        }
        final cost = double.tryParse(poItem?.costPerUnit ?? '0') ?? 0.0;

        // If PO-level quantity is entered and PR mapping is not shown
        final showPRMapping =
            selectedPRs[materialCode]?[poNo]?['_showPRMapping'] ?? false;
        if (!showPRMapping) {
          final poQty = double.tryParse(prControllers['_po']?.text ?? '') ?? 0;
          total += poQty * cost;
          continue;
        }

        // Calculate PR-wise quantities
        for (var prEntry in prControllers.entries) {
          if (prEntry.key == '_po') continue;
          final qty = double.tryParse(prEntry.value.text) ?? 0;
          total += qty * cost;
        }
      }
    }

    setState(() {
      _invoiceAmountController.text = total.toStringAsFixed(2);
    });
  }

  Widget _buildItemCard(MaterialItem material, List<PurchaseOrder> pos) {
    // Initialize controllers and selected state for this material if not exists
    if (!selectedPRs.containsKey(material.partNo)) {
      selectedPRs[material.partNo] = {};
      prQtyControllers[material.partNo] = {};
      for (var po in pos) {
        selectedPRs[material.partNo]![po.poNo] = {};
        prQtyControllers[material.partNo]![po.poNo] = {};

        // Add a controller for PO-level quantity
        prQtyControllers[material.partNo]![po.poNo]!['_po'] =
            TextEditingController(text: '0');

        final poItem = po.items.firstWhere(
          (item) => item.materialCode == material.partNo,
        );

        // Initialize General PR if needed
        if (poItem.prDetails.isEmpty ||
            poItem.prDetails.containsKey('General')) {
          selectedPRs[material.partNo]![po.poNo]!['General'] = false;
          prQtyControllers[material.partNo]![po.poNo]!['General'] =
              TextEditingController(text: '0');
        }

        for (var prDetail in poItem.prDetails.entries) {
          final prNo = prDetail.key;
          if (prNo != 'General') {
            // Skip General PR here as it's handled above
            // Show PR if its job matches any selected job or if 'All' is selected
            if (selectedJobs.contains('All') ||
                selectedJobs.contains(prDetail.value.jobNo)) {
              selectedPRs[material.partNo]![po.poNo]![prNo] = false;
              prQtyControllers[material.partNo]![po.poNo]![prNo] =
                  TextEditingController(text: '0');
            }
          }
        }
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Material Header
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  material.description,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Code: ${material.partNo}',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // PO List
          ...pos.map((po) {
            final poItem = po.items.firstWhere(
              (item) => item.materialCode == material.partNo,
            );

            // Filter PR details based on selected job
            final filteredPRDetails = Map.fromEntries(poItem.prDetails.entries
                .where((entry) =>
                    selectedJobs.contains('All') ||
                    selectedJobs.contains(entry.value.jobNo)));

            if (filteredPRDetails.isEmpty) return const SizedBox.shrink();

            final totalOrderedQty = filteredPRDetails.values
                .fold(0.0, (sum, detail) => sum + detail.quantity);
            final totalReceivedQty = ref
                .read(storeInwardProvider.notifier)
                .getTotalReceivedQuantityForPO(material.partNo, po.poNo);
            final pendingQty = totalOrderedQty - totalReceivedQty;

            if (pendingQty <= 0) return const SizedBox.shrink();

            final showPRMapping = prQtyControllers[material.partNo]![po.poNo]![
                        '_po']!
                    .text
                    .isNotEmpty &&
                (double.tryParse(
                            prQtyControllers[material.partNo]![po.poNo]!['_po']!
                                .text) ??
                        0) <
                    pendingQty;

            return Column(
              children: [
                // PO Header with Quantity Input
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      // PO Info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  'PO: ${po.poNo}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  'Ordered: $totalOrderedQty',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  'Received: $totalReceivedQty',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                            if (po.poDate.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                'Date: ${po.poDate}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[500],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      // Inward Quantity Input
                      SizedBox(
                        width: 120,
                        child: TextFormField(
                          controller: prQtyControllers[material.partNo]![
                              po.poNo]!['_po'],
                          decoration: InputDecoration(
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 8),
                            hintText: 'Max: $pendingQty',
                            hintStyle: TextStyle(
                                fontSize: 12, color: Colors.grey[500]),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (value == null || value.isEmpty) return null;
                            final qty = double.tryParse(value);
                            if (qty == null) return 'Invalid number';
                            if (qty < 0) return 'Cannot be negative';
                            if (qty > pendingQty) return 'Exceeds pending qty';
                            return null;
                          },
                          onChanged: (value) {
                            // Allow empty value during editing
                            if (value.isEmpty) {
                              setState(() {
                                selectedPRs[material.partNo]![po.poNo]![
                                    '_showPRMapping'] = false;
                                // Clear PR quantities
                                for (var prNo in filteredPRDetails.keys) {
                                  if (prNo != '_po') {
                                    prQtyControllers[material.partNo]![
                                            po.poNo]![prNo]
                                        ?.text = '';
                                  }
                                }
                              });
                              _updateInvoiceAmount();
                              return;
                            }

                            final qty = double.tryParse(value) ?? 0;

                            // Auto-adjust if exceeds pending quantity
                            if (qty > pendingQty) {
                              // Update outside setState to avoid flicker
                              prQtyControllers[material.partNo]![po.poNo]![
                                      '_po']!
                                  .text = pendingQty.toString();
                              setState(() {
                                selectedPRs[material.partNo]![po.poNo]![
                                    '_showPRMapping'] = false;
                              });
                              _updateInvoiceAmount();
                              return;
                            }

                            setState(() {
                              // If quantity equals pending quantity, don't show PR mapping
                              if (qty == pendingQty) {
                                selectedPRs[material.partNo]![po.poNo]![
                                    '_showPRMapping'] = false;

                                // If there's only General PR, put all quantity there
                                if (poItem.prDetails.isEmpty ||
                                    (poItem.prDetails.length == 1 &&
                                        poItem.prDetails
                                            .containsKey('General'))) {
                                  prQtyControllers[material.partNo]![po.poNo]![
                                          'General']
                                      ?.text = qty.toString();
                                  // Clear other PR quantities if any
                                  for (var prNo in filteredPRDetails.keys) {
                                    if (prNo != '_po' && prNo != 'General') {
                                      prQtyControllers[material.partNo]![
                                              po.poNo]![prNo]
                                          ?.text = '';
                                    }
                                  }
                                }
                              } else if (qty > 0) {
                                // Show PR mapping for partial quantities
                                selectedPRs[material.partNo]![po.poNo]![
                                    '_showPRMapping'] = true;

                                // Clear existing PR quantities when showing mapping
                                for (var prNo in filteredPRDetails.keys) {
                                  if (prNo != '_po') {
                                    prQtyControllers[material.partNo]![
                                            po.poNo]![prNo]
                                        ?.text = '';
                                  }
                                }
                              } else {
                                // Hide PR mapping for zero quantity
                                selectedPRs[material.partNo]![po.poNo]![
                                    '_showPRMapping'] = false;
                                // Clear PR quantities
                                for (var prNo in filteredPRDetails.keys) {
                                  if (prNo != '_po') {
                                    prQtyControllers[material.partNo]![
                                            po.poNo]![prNo]
                                        ?.text = '';
                                  }
                                }
                              }
                            });

                            _updateInvoiceAmount();
                          },
                          onEditingComplete: () {
                            // Set to '0' if empty when focus is lost
                            if (prQtyControllers[material.partNo]![po.poNo]![
                                    '_po']!
                                .text
                                .isEmpty) {
                              prQtyControllers[material.partNo]![po.poNo]![
                                      '_po']!
                                  .text = '0';
                              _updateInvoiceAmount();
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                // PR Distribution (if needed)
                if (showPRMapping)
                  Container(
                    padding:
                        const EdgeInsets.only(left: 32, right: 16, bottom: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'PR Distribution',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.blue[700],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ...filteredPRDetails.entries.map((prEntry) {
                          final prNo = prEntry.key;
                          final prDetail = prEntry.value;
                          final totalReceivedQty = ref
                              .read(storeInwardProvider.notifier)
                              .getTotalReceivedQuantityForPR(
                                material.partNo,
                                po.poNo,
                                prNo,
                              );

                          final prPendingQty =
                              prDetail.quantity - totalReceivedQty;
                          if (prPendingQty <= 0) return const SizedBox.shrink();

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              children: [
                                // PR Info
                                Expanded(
                                  child: Row(
                                    children: [
                                      Text(
                                        'PR: $prNo',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        '(${prDetail.jobNo})',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[500],
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Text(
                                        'Ordered: ${prDetail.quantity}',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Received: $totalReceivedQty',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                // PR Quantity Input
                                SizedBox(
                                  width: 120,
                                  child: TextFormField(
                                    controller: prQtyControllers[
                                        material.partNo]![po.poNo]![prNo],
                                    decoration: InputDecoration(
                                      isDense: true,
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                              horizontal: 8, vertical: 8),
                                      hintText: 'Max: $prPendingQty',
                                      hintStyle: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[500]),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                    ),
                                    keyboardType: TextInputType.number,
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return null;
                                      }
                                      final qty = double.tryParse(value);
                                      if (qty == null) return 'Invalid number';
                                      if (qty < 0) return 'Cannot be negative';
                                      if (qty > prPendingQty) {
                                        return 'Exceeds pending qty';
                                      }
                                      return null;
                                    },
                                    onChanged: (value) {
                                      // Allow empty value during editing
                                      if (value.isEmpty) {
                                        setState(() {});
                                        _updateInvoiceAmount();
                                        return;
                                      }

                                      final qty = double.tryParse(value) ?? 0;

                                      // Auto-adjust if exceeds pending qty
                                      if (qty > prPendingQty) {
                                        // Update outside setState
                                        prQtyControllers[material.partNo]![
                                                po.poNo]![prNo]
                                            ?.text = prPendingQty.toString();
                                      }

                                      // Calculate total from PR quantities
                                      double total = 0;
                                      // First calculate non-General PR quantities
                                      for (var prEntry
                                          in filteredPRDetails.entries) {
                                        final currentPrNo = prEntry.key;
                                        if (currentPrNo != 'General') {
                                          final prQty = double.tryParse(
                                                  prQtyControllers[material
                                                                      .partNo]![
                                                                  po.poNo]![
                                                              currentPrNo]
                                                          ?.text ??
                                                      '') ??
                                              0;
                                          total += prQty;
                                        }
                                      }

                                      // Then add General PR quantity if it exists
                                      if (prQtyControllers[material.partNo]![
                                              po.poNo]!
                                          .containsKey('General')) {
                                        final generalQty = double.tryParse(
                                                prQtyControllers[material
                                                                .partNo]![
                                                            po.poNo]!['General']
                                                        ?.text ??
                                                    '') ??
                                            0;
                                        total += generalQty;
                                      }

                                      print(
                                          'Updating _po for ${material.partNo} - ${po.poNo}: $total (PR: $prNo, Qty: $qty)');

                                      // Update PO level quantity outside setState
                                      prQtyControllers[material.partNo]![
                                              po.poNo]!['_po']
                                          ?.text = total.toString();

                                      setState(() {});
                                      _updateInvoiceAmount();
                                    },
                                    onEditingComplete: () {
                                      // Set to '0' if empty when focus is lost
                                      if (prQtyControllers[material.partNo]![
                                              po.poNo]![prNo]!
                                          .text
                                          .isEmpty) {
                                        prQtyControllers[material.partNo]![
                                                po.poNo]![prNo]!
                                            .text = '0';
                                        _updateInvoiceAmount();
                                      }
                                    },
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                if (po != pos.last) const Divider(height: 1),
              ],
            );
          }),
        ],
      ),
    );
  }

  Future<void> _saveGR() async {
    if (!_formKey.currentState!.validate()) return;

    // Additional validation for PR quantities
    bool hasValidQuantities = false;
    for (var materialControllers in prQtyControllers.values) {
      for (var poControllers in materialControllers.values) {
        final poQty = double.tryParse(poControllers['_po']?.text ?? '0') ?? 0;
        if (poQty > 0) {
          hasValidQuantities = true;
          break;
        }
      }
      if (hasValidQuantities) break;
    }

    if (!hasValidQuantities) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please enter at least one valid quantity')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final grnNo = widget.existingGR?.grnNo ?? _generateGRNNo();
      final purchaseOrders = ref.read(purchaseOrderListProvider);
      final poNotifier = ref.read(purchaseOrderListProvider.notifier);

      // Create inward items
      final inwardItems = <InwardItem>[];
      final poNos = <String>{}; // Track unique PO numbers

      for (var entry in prQtyControllers.entries) {
        final materialCode = entry.key;
        final poControllers = entry.value;

        print('Processing material: $materialCode');

        double totalReceivedQty = 0;
        final material = ref
            .read(materialListProvider)
            .firstWhere((m) => m.partNo == materialCode);

        final inwardItem = InwardItem(
          materialCode: materialCode,
          materialDescription: material.description,
          unit: material.unit,
          orderedQty: 0, // Will be calculated
          receivedQty: 0, // Will be calculated
          acceptedQty: 0,
          rejectedQty: 0,
          costPerUnit: '0',
        );

        // Process PR quantities
        for (var poEntry in poControllers.entries) {
          final poNo = poEntry.key;
          final prControllers = poEntry.value;
          final po = purchaseOrders.firstWhere((po) => po.poNo == poNo);
          final poItem = po.items.firstWhere(
            (item) => item.materialCode == materialCode,
          );

          print('Processing PO: $poNo');

          // Get cost from PO
          inwardItem.costPerUnit = poItem.costPerUnit;

          // Get PO-level quantity
          final poQty = double.tryParse(prControllers['_po']?.text ?? '0') ?? 0;
          if (poQty <= 0) continue;

          // Check if PR mapping is shown
          final showPRMapping =
              selectedPRs[materialCode]?[poNo]?['_showPRMapping'] ?? false;

          print('PO Qty: $poQty, Show PR Mapping: $showPRMapping');

          if (!showPRMapping) {
            // If PR mapping is not shown, handle the total PO quantity

            // First check if there are any non-General PRs
            final nonGeneralPRs = poItem.prDetails.entries
                .where((e) => e.key != 'General')
                .toList();

            // Get existing PR quantities
            double prTotal = 0;
            double generalQty = 0;

            // Calculate existing PR quantities
            for (var prEntry in prControllers.entries) {
              if (prEntry.key == '_po') continue;

              final qty = double.tryParse(prEntry.value.text) ?? 0;
              if (prEntry.key == 'General') {
                generalQty = qty;
              } else {
                prTotal += qty;
              }
            }

            print('Existing PR total: $prTotal, General: $generalQty');

            if (nonGeneralPRs.isEmpty &&
                poItem.prDetails.containsKey('General')) {
              // Only General PR exists, assign all quantity to it
              print('Assigning all quantity to General PR: $poQty');
              const prNo = 'General';
              inwardItem.addPRQuantity(poNo, prNo, poQty);
              totalReceivedQty += poQty;
              inwardItem.addJobNumberForPR(poNo, prNo, 'General');

              // Update PO received quantities
              if (widget.existingGR != null) {
                poItem.receivedQuantities
                    .remove('${widget.existingGR!.grnNo}_$prNo');
              }
              poItem.addReceivedQuantity('${grnNo}_$prNo', poQty);
            } else {
              // Handle both General and non-General PRs
              print('Handling mixed PR distribution');

              // First distribute to non-General PRs if they exist
              if (nonGeneralPRs.isNotEmpty) {
                double remainingQty = poQty;

                // First try to use existing PR quantities
                for (var prEntry in prControllers.entries) {
                  if (prEntry.key == '_po' || prEntry.key == 'General') {
                    continue;
                  }

                  final prNo = prEntry.key;
                  final qty = double.tryParse(prEntry.value.text) ?? 0;
                  if (qty <= 0) continue;

                  // Check if this quantity can be accommodated
                  final prPendingQty = poItem.getPendingQuantityForPR(prNo);
                  final actualQty = qty > prPendingQty ? prPendingQty : qty;

                  if (actualQty > 0 && actualQty <= remainingQty) {
                    print('Adding PR quantity: $prNo = $actualQty');
                    inwardItem.addPRQuantity(poNo, prNo, actualQty);
                    totalReceivedQty += actualQty;
                    remainingQty -= actualQty;

                    final jobNo = poItem.prDetails[prNo]?.jobNo ?? 'General';
                    inwardItem.addJobNumberForPR(poNo, prNo, jobNo);

                    // Update PO received quantities
                    if (widget.existingGR != null) {
                      poItem.receivedQuantities
                          .remove('${widget.existingGR!.grnNo}_$prNo');
                    }
                    poItem.addReceivedQuantity('${grnNo}_$prNo', actualQty);
                  }
                }

                // If there's remaining quantity and General PR exists, assign it there
                if (remainingQty > 0 &&
                    poItem.prDetails.containsKey('General')) {
                  print(
                      'Adding remaining quantity to General PR: $remainingQty');
                  const prNo = 'General';
                  inwardItem.addPRQuantity(poNo, prNo, remainingQty);
                  totalReceivedQty += remainingQty;
                  inwardItem.addJobNumberForPR(poNo, prNo, 'General');

                  // Update PO received quantities
                  if (widget.existingGR != null) {
                    poItem.receivedQuantities
                        .remove('${widget.existingGR!.grnNo}_$prNo');
                  }
                  poItem.addReceivedQuantity('${grnNo}_$prNo', remainingQty);
                }
              } else {
                // Use existing PR quantities if they exist
                print('Using existing PR quantities');

                // Add non-General PRs first
                for (var prEntry in prControllers.entries) {
                  if (prEntry.key == '_po' || prEntry.key == 'General') {
                    continue;
                  }

                  final prNo = prEntry.key;
                  final qty = double.tryParse(prEntry.value.text) ?? 0;
                  if (qty <= 0) continue;

                  print('Adding PR quantity: $prNo = $qty');
                  inwardItem.addPRQuantity(poNo, prNo, qty);
                  totalReceivedQty += qty;

                  final jobNo = poItem.prDetails[prNo]?.jobNo ?? 'General';
                  inwardItem.addJobNumberForPR(poNo, prNo, jobNo);

                  // Update PO received quantities
                  if (widget.existingGR != null) {
                    poItem.receivedQuantities
                        .remove('${widget.existingGR!.grnNo}_$prNo');
                  }
                  poItem.addReceivedQuantity('${grnNo}_$prNo', qty);
                }

                // Add General PR if it exists
                if (poItem.prDetails.containsKey('General') && generalQty > 0) {
                  print('Adding General PR quantity: $generalQty');
                  const prNo = 'General';
                  inwardItem.addPRQuantity(poNo, prNo, generalQty);
                  totalReceivedQty += generalQty;
                  inwardItem.addJobNumberForPR(poNo, prNo, 'General');

                  // Update PO received quantities
                  if (widget.existingGR != null) {
                    poItem.receivedQuantities
                        .remove('${widget.existingGR!.grnNo}_$prNo');
                  }
                  poItem.addReceivedQuantity('${grnNo}_$prNo', generalQty);
                }
              }
            }
          } else {
            // PR mapping is shown, use manually entered PR quantities
            print('Using manually entered PR quantities');
            for (var prEntry in prControllers.entries) {
              if (prEntry.key == '_po') continue;

              final prNo = prEntry.key;
              final qty = double.tryParse(prEntry.value.text) ?? 0;
              if (qty <= 0) continue;

              final jobNo = poItem.prDetails[prNo]?.jobNo ?? 'General';
              print('PR: $prNo, Qty: $qty, Job: $jobNo');

              inwardItem.addPRQuantity(poNo, prNo, qty);
              totalReceivedQty += qty;
              inwardItem.addJobNumberForPR(poNo, prNo, jobNo);

              // Update PO received quantities
              if (widget.existingGR != null) {
                poItem.receivedQuantities
                    .remove('${widget.existingGR!.grnNo}_$prNo');
              }
              poItem.addReceivedQuantity('${grnNo}_$prNo', qty);
            }
          }

          poNos.add(poNo); // Track PO number

          // Set ordered quantity from PO
          inwardItem.orderedQty = double.tryParse(poItem.quantity) ?? 0;
        }

        if (totalReceivedQty > 0) {
          inwardItem.receivedQty = totalReceivedQty;
          inwardItems.add(inwardItem);
          print(
              'Added inward item for $materialCode with total qty: $totalReceivedQty');
        }
      }

      // Create or update GR
      final newGR = StoreInward(
        grnNo: grnNo,
        grnDate: _grnDateController.text,
        supplierName: selectedSupplier!.name,
        poNo: poNos.join(', '), // Join all PO numbers
        poDate: '', // Multiple dates possible
        invoiceNo: _invoiceNoController.text,
        invoiceDate: _invoiceDateController.text,
        invoiceAmount: _invoiceAmountController.text,
        receivedBy: _receivedByController.text,
        checkedBy: _checkedByController.text,
        items: inwardItems,
      );

      // Update PO status for all affected POs
      final updatedPOs = <String>{};
      for (var inwardItem in inwardItems) {
        for (var poNo in inwardItem.prQuantities.keys) {
          if (!updatedPOs.contains(poNo)) {
            final poIndex = purchaseOrders.indexWhere((po) => po.poNo == poNo);
            if (poIndex >= 0) {
              final po = purchaseOrders[poIndex];
              po.updateStatus();
              poNotifier.updateOrder(poIndex, po);
              updatedPOs.add(poNo);
            }
          }
        }
      }

      // Save the GR
      if (widget.existingGR != null && widget.index != null) {
        final grNotifier = ref.read(storeInwardProvider.notifier);
        grNotifier.updateInward(widget.index!, newGR);
      } else {
        final grNotifier = ref.read(storeInwardProvider.notifier);
        grNotifier.addInward(newGR);
      }

      Navigator.pop(context);
    } catch (e) {
      print('Error saving GR: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving GR: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final suppliers = ref.watch(supplierListProvider);
    final purchaseOrders = ref
        .watch(purchaseOrderListProvider)
        .where((po) =>
            selectedSupplier != null &&
            po.supplierName == selectedSupplier!.name &&
            !po.isFullyReceived)
        .toList();

    // Get unique job numbers
    final availableJobs = _getUniqueJobNumbers(purchaseOrders);

    // Get materials that have pending POs from the selected supplier
    final materials = ref.watch(materialListProvider).where((material) {
      return purchaseOrders.any((po) {
        // Find items for this material in the PO
        final poItems = po.items.where((item) => item.materialCode == material.partNo);
        if (poItems.isEmpty) return false;

        for (var item in poItems) {
          // Calculate total ordered and received quantities
          double totalOrderedQty = 0.0;
          double totalReceivedQty = 0.0;

          // If no PRs or only General PR, use PO quantity
          if (item.prDetails.isEmpty || (item.prDetails.length == 1 && item.prDetails.containsKey('General'))) {
            totalOrderedQty = double.tryParse(item.quantity) ?? 0.0;
            totalReceivedQty = item.receivedQuantities.values
                .fold<double>(0.0, (sum, qty) => sum + (qty as double));
          } else {
            // Calculate PR-wise quantities
            for (var prDetail in item.prDetails.entries) {
              // Skip if job filter is active and this PR's job doesn't match
              if (!selectedJobs.contains('All') && !selectedJobs.contains(prDetail.value.jobNo)) {
                continue;
              }
              totalOrderedQty += prDetail.value.quantity;
              totalReceivedQty += item.receivedQuantities.entries
                  .where((entry) => entry.key.contains('_${prDetail.key}'))
                  .fold<double>(0.0, (sum, entry) => sum + (entry.value as double));
            }
          }

          // If there's pending quantity, show this material
          if (totalOrderedQty > totalReceivedQty) {
            return true;
          }
        }
        return false;
      });
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.existingGR != null
            ? "Edit Goods Receipt"
            : "Create Goods Receipt"),
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
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
                          onChanged: widget.existingGR != null
                              ? null
                              : (val) {
                                  setState(() {
                                    selectedSupplier = val;
                                    selectedPRs.clear();
                                    prQtyControllers.clear();
                                    selectedJobs = ['All'];
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
                      // Replace job filter with button to open SelectJobsDialog
                      Expanded(
                        child: OutlinedButton.icon(
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
                                availableJobs: availableJobs.toList(),
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
                                selectedPRs.clear();
                                prQtyControllers.clear();
                              });
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _grnDateController,
                          decoration: const InputDecoration(
                            labelText: 'GR Date',
                            border: OutlineInputBorder(),
                          ),
                          readOnly: true,
                          onTap: () async {
                            final date = await showDatePicker(
                              context: context,
                              initialDate: DateTime.now(),
                              firstDate: DateTime.now()
                                  .subtract(const Duration(days: 30)),
                              lastDate: DateTime.now(),
                            );
                            if (date != null) {
                              setState(() {
                                _grnDateController.text =
                                    DateFormat('yyyy-MM-dd').format(date);
                              });
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextFormField(
                          controller: _invoiceDateController,
                          decoration: const InputDecoration(
                            labelText: 'Invoice Date',
                            border: OutlineInputBorder(),
                          ),
                          readOnly: true,
                          onTap: () async {
                            final date = await showDatePicker(
                              context: context,
                              initialDate: DateTime.now(),
                              firstDate: DateTime.now()
                                  .subtract(const Duration(days: 30)),
                              lastDate: DateTime.now(),
                            );
                            if (date != null) {
                              setState(() {
                                _invoiceDateController.text =
                                    DateFormat('yyyy-MM-dd').format(date);
                              });
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _invoiceNoController,
                          decoration: const InputDecoration(
                            labelText: 'Invoice No',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextFormField(
                          controller: _invoiceAmountController,
                          decoration: const InputDecoration(
                            labelText: 'Invoice Amount',
                            border: OutlineInputBorder(),
                          ),
                          readOnly: true,
                          style: TextStyle(
                            color: Colors.grey[700],
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _receivedByController,
                          decoration: const InputDecoration(
                            labelText: 'Received By',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextFormField(
                          controller: _checkedByController,
                          decoration: const InputDecoration(
                            labelText: 'Checked By',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (selectedSupplier != null) ...[
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: materials
                      .map((material) => _buildItemCard(
                            material,
                            purchaseOrders
                                .where((po) => po.items.any((item) =>
                                    item.materialCode == material.partNo))
                                .toList(),
                          ))
                      .toList(),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _saveGR,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 48, vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator()
                        : const Text(
                            "Save Goods Receipt",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
