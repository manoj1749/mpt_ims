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
import '../../models/customer.dart';
import '../../provider/customer_provider.dart';
import '../../models/purchase_request.dart';
import '../../models/pr_item.dart';
import '../../provider/purchase_request_provider.dart';
import 'package:pluto_grid/pluto_grid.dart';
import 'package:mpt_ims/pages/store/select_jobs_dialog.dart';

class AddCustomerScopeGRPage extends ConsumerStatefulWidget {
  final StoreInward? existingGR;
  final int? index;

  const AddCustomerScopeGRPage({
    super.key,
    this.existingGR,
    this.index,
  });

  @override
  ConsumerState<AddCustomerScopeGRPage> createState() => _AddCustomerScopeGRPageState();
}

class _AddCustomerScopeGRPageState extends ConsumerState<AddCustomerScopeGRPage> {
  final _formKey = GlobalKey<FormState>();
  final _grnDateController = TextEditingController();
  final _invoiceNoController = TextEditingController();
  final _invoiceDateController = TextEditingController();
  final _invoiceAmountController = TextEditingController();
  final _receivedByController = TextEditingController();
  final _checkedByController = TextEditingController();
  final TextEditingController _customerSearchController = TextEditingController();

  Supplier? selectedSupplier;
  Customer? selectedCustomer;
  List<String> selectedJobs = ['All'];
  Map<String, Map<String, Map<String, TextEditingController>>>
      prQtyControllers = {};
  // Controllers for price input per Material -> PO
  Map<String, Map<String, TextEditingController>> priceControllers = {};
  Map<String, Map<String, Map<String, bool>>> selectedPRs = {};
  Map<String, Map<String, PlutoGridStateManager?>> gridStateManagers = {};
  bool _isLoading = false;

  String _generateGRNNo() {
    return ref.read(storeInwardProvider.notifier).generateGRNNumber();
  }

  @override
  void initState() {
    super.initState();
    // Load customer data
    Future.microtask(() async {
      try {
        await ref.read(customerListProvider.notifier).loadData();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error loading customers: $e')),
          );
        }
      }
    });

    if (widget.existingGR != null) {
      selectedCustomer = ref
          .read(customerListProvider)
          .firstWhere((c) => c.name == widget.existingGR!.customerName,
              orElse: () => ref.read(customerListProvider).first);
      _grnDateController.text = widget.existingGR!.grnDate;
      _invoiceNoController.text = widget.existingGR!.invoiceNo;
      _invoiceDateController.text = widget.existingGR!.invoiceDate;
      _invoiceAmountController.text =
          widget.existingGR!.invoiceAmount.toStringAsFixed(2);
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
    _customerSearchController.dispose();
    for (var materialControllers in prQtyControllers.values) {
      for (var poControllers in materialControllers.values) {
        for (var controller in poControllers.values) {
          controller.dispose();
        }
      }
    }
    for (var poMap in priceControllers.values) {
      for (var controller in poMap.values) {
        controller.dispose();
      }
    }
    super.dispose();
  }

  // Get unique job numbers from Purchase Requests
  Set<String> _getUniqueJobNumbers(List<PurchaseRequest> purchaseRequests) {
    final Set<String> jobNos = {'All'}; // Include 'All' as default option
    for (var pr in purchaseRequests) {
      final j = pr.jobNo?.trim() ?? '';
      if (j.isNotEmpty && j != 'General') {
        jobNos.add(j);
      } else if (j == 'General') {
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
        // Get cost per unit from user input if available, else PO item
        final enteredPriceText = priceControllers[materialCode]?[poNo]?.text;
        final cost = enteredPriceText != null && enteredPriceText.isNotEmpty
            ? (double.tryParse(enteredPriceText) ?? 0.0)
            : (double.tryParse(poItem?.costPerUnit ?? '0') ?? 0.0);

        // Sum all PR quantities for this PO
        double poTotal = 0.0;
        for (var prEntry in prControllers.entries) {
          if (prEntry.key == '_po') continue;
          final qty = double.tryParse(prEntry.value.text) ?? 0;
          if (qty > 0) {
            poTotal += qty * cost;
          }
        }

        total += poTotal;
      }
    }

    // Calculate GST
    final customer = selectedCustomer;
    if (customer != null) {
      final igst = total *
          (double.tryParse(customer.igst.replaceAll('%', '')) ?? 0) /
          100;
      final cgst = total *
          (double.tryParse(customer.cgst.replaceAll('%', '')) ?? 0) /
          100;
      final sgst = total *
          (double.tryParse(customer.sgst.replaceAll('%', '')) ?? 0) /
          100;
      total += igst + cgst + sgst;
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
      priceControllers[material.partNo] = {};
      for (var po in pos) {
        selectedPRs[material.partNo]![po.poNo] = {};
        prQtyControllers[material.partNo]![po.poNo] = {};

        // Add a controller for PO-level quantity
        prQtyControllers[material.partNo]![po.poNo]!['_po'] =
            TextEditingController(text: '0');

        final poItem = po.items.firstWhere(
          (item) => item.materialCode == material.partNo,
        );

        // Initialize price controller with PO price
        priceControllers[material.partNo]![po.poNo] =
            TextEditingController(text: poItem.costPerUnit);

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

            // Calculate total received by summing up all PRs including General
            double totalReceivedQty = 0.0;
            for (var prEntry in filteredPRDetails.entries) {
              final prNo = prEntry.key;
              final receivedForPR = ref
                      .read(storeInwardProvider.notifier)
                      .getReceivedQuantityForPR(
                          material.partNo, po.poNo, prNo) ??
                  0.0;
              totalReceivedQty += receivedForPR;
            }

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
                      // Price Input
                      SizedBox(
                        width: 140,
                        child: TextFormField(
                          controller:
                              priceControllers[material.partNo]![po.poNo],
                          decoration: InputDecoration(
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 8),
                            labelText: 'Price (per ${material.unit})',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (value == null || value.isEmpty) return 'Required';
                            final p = double.tryParse(value);
                            if (p == null || p < 0) return 'Invalid price';
                            return null;
                          },
                          onChanged: (_) => _updateInvoiceAmount(),
                        ),
                      ),
                      const SizedBox(width: 16),
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
                                // If quantity equals pending quantity, auto-distribute to PRs
                                if (filteredPRDetails.isNotEmpty) {
                                  double remainingQty = pendingQty;

                                  // First handle non-General PRs
                                  for (var prEntry in filteredPRDetails.entries
                                      .where((e) => e.key != 'General')) {
                                    final prNo = prEntry.key;
                                    final prDetail = prEntry.value;
                                    final prPendingQty = prDetail.quantity -
                                        (ref
                                                .read(storeInwardProvider
                                                    .notifier)
                                                .getReceivedQuantityForPR(
                                                    material.partNo,
                                                    po.poNo,
                                                    prNo) ??
                                            0);

                                    if (prPendingQty > 0 && remainingQty > 0) {
                                      final allocatedQty =
                                          remainingQty >= prPendingQty
                                              ? prPendingQty
                                              : remainingQty;
                                      prQtyControllers[material.partNo]![
                                              po.poNo]![prNo]
                                          ?.text = allocatedQty.toString();
                                      remainingQty -= allocatedQty;
                                    } else {
                                      prQtyControllers[material.partNo]![
                                              po.poNo]![prNo]
                                          ?.text = '0';
                                    }
                                  }

                                  // Then handle General PR if it exists and there's remaining quantity
                                  if (remainingQty > 0 &&
                                      filteredPRDetails
                                          .containsKey('General')) {
                                    prQtyControllers[material.partNo]![
                                            po.poNo]!['General']
                                        ?.text = remainingQty.toString();
                                  }

                                  selectedPRs[material.partNo]![po.poNo]![
                                      '_showPRMapping'] = false;
                                }
                              });
                              _updateInvoiceAmount();
                              return;
                            }

                            setState(() {
                              // If quantity equals pending quantity, auto-distribute to PRs
                              if (qty == pendingQty &&
                                  filteredPRDetails.isNotEmpty) {
                                double remainingQty = qty;

                                // First handle non-General PRs
                                for (var prEntry in filteredPRDetails.entries
                                    .where((e) => e.key != 'General')) {
                                  final prNo = prEntry.key;
                                  final prDetail = prEntry.value;
                                  final prPendingQty = prDetail.quantity -
                                      (ref
                                              .read(
                                                  storeInwardProvider.notifier)
                                              .getReceivedQuantityForPR(
                                                  material.partNo,
                                                  po.poNo,
                                                  prNo) ??
                                          0);

                                  if (prPendingQty > 0 && remainingQty > 0) {
                                    final allocatedQty =
                                        remainingQty >= prPendingQty
                                            ? prPendingQty
                                            : remainingQty;
                                    prQtyControllers[material.partNo]![
                                            po.poNo]![prNo]
                                        ?.text = allocatedQty.toString();
                                    remainingQty -= allocatedQty;
                                  } else {
                                    prQtyControllers[material.partNo]![
                                            po.poNo]![prNo]
                                        ?.text = '0';
                                  }
                                }

                                // Then handle General PR if it exists and there's remaining quantity
                                if (remainingQty > 0 &&
                                    filteredPRDetails.containsKey('General')) {
                                  prQtyControllers[material.partNo]![po.poNo]![
                                          'General']
                                      ?.text = remainingQty.toString();
                                }

                                selectedPRs[material.partNo]![po.poNo]![
                                    '_showPRMapping'] = false;
                              } else {
                                // Show PR mapping for partial quantities
                                selectedPRs[material.partNo]![po.poNo]![
                                    '_showPRMapping'] = true;
                                // Clear PR quantities to allow manual mapping
                                for (var prNo in filteredPRDetails.keys) {
                                  if (prNo != '_po') {
                                    prQtyControllers[material.partNo]![
                                            po.poNo]![prNo]
                                        ?.text = '0';
                                  }
                                }
                              }
                            });

                            _updateInvoiceAmount();
                          },
                          onEditingComplete: () {
                            // Allow zero value when focus is lost
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
                          final totalReceivedForPR = ref
                                  .read(storeInwardProvider.notifier)
                                  .getReceivedQuantityForPR(
                                      material.partNo, po.poNo, prNo) ??
                              0.0;

                          final prPendingQty =
                              prDetail.quantity - totalReceivedForPR;
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
                                        'Received: $totalReceivedForPR',
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

                                      // Then add General PR quantity if it exists and we're not currently editing it
                                      if (prQtyControllers[material.partNo]![
                                                  po.poNo]!
                                              .containsKey('General') &&
                                          prNo != 'General') {
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
                                      // Allow zero value when focus is lost
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
        // Check PO-level quantity
        final poQty = double.tryParse(poControllers['_po']?.text ?? '0') ?? 0;

        // Check PR-level quantities
        double totalPRQty = 0;
        for (var prController in poControllers.entries) {
          if (prController.key != '_po') {
            final prQty = double.tryParse(prController.value.text) ?? 0;
            totalPRQty += prQty;
          }
        }

        if (poQty > 0 || totalPRQty > 0) {
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

    // Validate price mismatch vs PO price (only when quantities > 0)
    final priceMismatches = <String>[];
    final purchaseOrders = ref.read(purchaseOrderListProvider);
    for (var materialEntry in priceControllers.entries) {
      final materialCode = materialEntry.key;
      for (var poEntry in materialEntry.value.entries) {
        final poNo = poEntry.key;
        // Skip validation if no quantity is being received for this PO
        final poControllersForMaterial = prQtyControllers[materialCode]?[poNo];
        double totalQtyForPO = 0.0;
        if (poControllersForMaterial != null) {
          for (var prEnt in poControllersForMaterial.entries) {
            if (prEnt.key == '_po') continue;
            totalQtyForPO += double.tryParse(prEnt.value.text) ?? 0.0;
          }
          totalQtyForPO +=
              double.tryParse(poControllersForMaterial['_po']?.text ?? '0') ??
                  0.0;
        }
        if (totalQtyForPO <= 0.0) continue;

        final enteredText = poEntry.value.text;
        final entered = double.tryParse(enteredText) ?? double.nan;
        final po = purchaseOrders.firstWhere(
          (p) => p.poNo == poNo,
          orElse: () => PurchaseOrder(
            poNo: poNo,
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
          poItem = po.items.firstWhere((i) => i.materialCode == materialCode);
        } catch (_) {
          poItem = null;
        }
        final poPrice = double.tryParse(poItem?.costPerUnit ?? '') ?? double.nan;
        if (!entered.isNaN && !poPrice.isNaN) {
          if ((entered - poPrice).abs() > 0.0001) {
            priceMismatches.add(
                '$materialCode (PO: $poNo) Entered: ₹${entered.toStringAsFixed(2)} vs PO: ₹${poPrice.toStringAsFixed(2)}');
          }
        }
      }
    }

    if (priceMismatches.isNotEmpty) {
      await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.error_outline, color: Colors.red, size: 28),
              SizedBox(width: 8),
              Text('Price Mismatched')
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Price Mismatched. Please Check With Purchase.',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 12),
              ...priceMismatches.map((m) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.warning_amber,
                            color: Colors.orange, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            m,
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                        ),
                      ],
                    ),
                  )),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final grnNo = widget.existingGR?.grnNo ?? _generateGRNNo();
      final purchaseOrders = ref.read(purchaseOrderListProvider);
      final poNotifier = ref.read(purchaseOrderListProvider.notifier);
      final grNotifier = ref.read(storeInwardProvider.notifier);

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
        // Process PR quantities (including General)
        for (var poEntry in poControllers.entries) {
          final poNo = poEntry.key;
          final prControllers = poEntry.value;
          final po = purchaseOrders.firstWhere((po) => po.poNo == poNo);
          POItem? poItem;
          try {
            poItem = po.items
                .firstWhere((item) => item.materialCode == materialCode);
            // Set cost per unit from entered price (fallback to PO)
            final enteredPriceText =
                priceControllers[materialCode]?[poNo]?.text ?? '';
            final enteredPrice = double.tryParse(enteredPriceText);
            if (enteredPrice != null) {
              inwardItem.costPerUnit = enteredPrice.toStringAsFixed(2);
            } else {
              inwardItem.costPerUnit = poItem.costPerUnit;
            }
          } catch (_) {
            poItem = null;
          }
          print(
              'DEBUG: poItem.prDetails for $materialCode/$poNo: \\${poItem?.prDetails}');
          for (var prEntry in prControllers.entries) {
            if (prEntry.key == '_po') continue;
            final prNo = prEntry.key;
            final qty = double.tryParse(prEntry.value.text) ?? 0.0;
            if (qty <= 0) continue;
            print('Adding PR quantity: $prNo = $qty');
            inwardItem.addPRQuantity(poNo, prNo, qty);
            totalReceivedQty += qty;
            final jobNo = poItem?.prDetails[prNo]?.jobNo ?? 'General';
            inwardItem.addJobNumberForPR(poNo, prNo, jobNo);
            if (widget.existingGR != null) {
              poItem?.receivedQuantities
                  .remove('${widget.existingGR!.grnNo}_$prNo');
            }
            poItem?.addReceivedQuantity('${grnNo}_$prNo', qty);
          }
          poNos.add(poNo); // Track PO number
          inwardItem.orderedQty = double.tryParse(poItem?.quantity ?? '0') ?? 0;
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
        supplierName: selectedCustomer!.name,
        poNo: poNos.join(', '), // Join all PO numbers
        poDate: '', // Multiple dates possible
        invoiceNo: _invoiceNoController.text,
        invoiceDate: _invoiceDateController.text,
        invoiceAmount:
            StoreInward.parseInvoiceAmount(_invoiceAmountController.text),
        receivedBy: _receivedByController.text,
        checkedBy: _checkedByController.text,
        items: inwardItems,
        isCustomerScope: true,
        customerId: selectedCustomer!.customerCode,
        customerName: selectedCustomer!.name,
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
        grNotifier.updateInward(widget.index!, newGR);
      } else {
        print('\nAdding new inward: ${newGR.grnNo}');
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
    final customers = ref.watch(customerListProvider);
    
    // Get CFI Purchase Requests (PRs starting with 'CFI')
    final purchaseRequests = ref
        .watch(purchaseRequestListProvider)
        .where((pr) => pr.prNo.startsWith('CFI'))
        .toList();

    // Get unique job numbers from CFI PRs
    final availableJobs = _getUniqueJobNumbers(purchaseRequests);

    // Get materials that have pending quantities in CFI PRs
    final materials = ref.watch(materialListProvider).where((material) {
      return purchaseRequests.any((pr) {
        // Skip if job filter is active and this PR's job doesn't match
        if (!selectedJobs.contains('All') && 
            !selectedJobs.contains(pr.jobNo ?? '')) {
          return false;
        }
        
        // Find items for this material in the PR
        final prItems = pr.items.where((item) => item.materialCode == material.partNo);
        if (prItems.isEmpty) return false;

        for (var item in prItems) {
          final totalRequired = double.tryParse(item.quantity) ?? 0.0;
          final totalReceived = item.totalReceivedQuantity;
          
          // If there's pending quantity, include this material
          if (totalReceived < totalRequired) {
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
                        child: DropdownButtonFormField2<Customer>(
                          isExpanded: true,
                          decoration: const InputDecoration(
                            labelText: 'Select Customer',
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(vertical: 0),
                          ),
                          hint: const Text("Select Customer"),
                          value: selectedCustomer,
                          items: ref.watch(customerListProvider)
                              .map((customer) => DropdownMenuItem<Customer>(
                                    value: customer,
                                    child: Text(
                                      customer.name,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ))
                              .toList(),
                          dropdownSearchData: DropdownSearchData(
                            searchController: _customerSearchController,
                            searchInnerWidgetHeight: 56,
                            searchInnerWidget: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: TextFormField(
                                controller: _customerSearchController,
                                decoration: const InputDecoration(
                                  isDense: true,
                                  hintText: 'Search customer...',
                                  border: OutlineInputBorder(),
                                ),
                              ),
                            ),
                            searchMatchFn: (item, searchValue) {
                              final name = item.value?.name ?? '';
                              return name
                                  .toLowerCase()
                                  .contains(searchValue.toLowerCase());
                            },
                          ),
                          onMenuStateChange: (isOpen) {
                            if (!isOpen) {
                              _customerSearchController.clear();
                            }
                          },
                          onChanged: widget.existingGR != null
                              ? null
                              : (val) {
                                  setState(() {
                                    selectedCustomer = val;
                                    selectedPRs.clear();
                                    prQtyControllers.clear();
                                    priceControllers.clear();
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
            if (selectedCustomer != null) ...[
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
