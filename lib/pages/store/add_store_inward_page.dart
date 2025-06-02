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
import '../../provider/purchase_order.dart';

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
  String? selectedJobNo;
  Map<String, Map<String, TextEditingController>> poQtyControllers = {};
  Map<String, Map<String, bool>> selectedPOs = {};
  bool _isLoading = false;

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

      // Initialize PO quantities from existing GR
      for (var item in widget.existingGR!.items) {
        selectedPOs[item.materialCode] = {};
        poQtyControllers[item.materialCode] = {};

        for (var entry in item.poQuantities.entries) {
          selectedPOs[item.materialCode]![entry.key] = true;
          poQtyControllers[item.materialCode]![entry.key] =
              TextEditingController(text: entry.value.toString());
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
    for (var materialControllers in poQtyControllers.values) {
      for (var controller in materialControllers.values) {
        controller.dispose();
      }
    }
    super.dispose();
  }

  // Get unique job numbers from POs
  List<String> _getUniqueJobNumbers(List<PurchaseOrder> purchaseOrders) {
    final Set<String> jobNos = {'All'}; // Include 'All' as default option
    for (var po in purchaseOrders) {
      for (var jobNo in po.jobNumbers) {
        jobNos.add(jobNo);
      }
      if (po.hasGeneralStockItems) {
        jobNos.add('General');
      }
    }
    return jobNos.toList()..sort();
  }

  Widget _buildItemCard(MaterialItem material, List<PurchaseOrder> pos) {
    // Initialize controllers and selected state for this material if not exists
    if (!selectedPOs.containsKey(material.partNo)) {
      selectedPOs[material.partNo] = {};
      poQtyControllers[material.partNo] = {};
      for (var po in pos) {
        // Initialize for both PR and general stock if applicable
        for (var prDetail in po.items
            .firstWhere((item) => item.materialCode == material.partNo)
            .prDetails
            .entries) {
          final key = '${po.poNo}_${prDetail.key}';
          selectedPOs[material.partNo]![key] = false;
          poQtyControllers[material.partNo]![key] =
              TextEditingController(text: '0');
        }
      }
    }

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              material.description,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 4),
            Text('Code: ${material.partNo}'),
            const SizedBox(height: 16),
            // Consolidated PO View
            ...pos.map((po) {
              final poItem = po.items.firstWhere(
                (item) => item.materialCode == material.partNo,
              );
              
              // Calculate total ordered quantity for this PO
              final totalOrdered = poItem.prDetails.values
                  .fold(0.0, (sum, detail) => sum + detail.quantity);
              
              // Get all job numbers for this PO
              final jobNumbers = poItem.prDetails.values
                  .map((detail) => detail.jobNo == 'General' ? 'General Stock' : detail.jobNo)
                  .join(', ');
              
              // Calculate total received quantity for this PO
              final totalReceivedQty = ref
                  .read(storeInwardProvider.notifier)
                  .getTotalReceivedQuantity(material.partNo, po.poNo);

              // Create a controller for consolidated inward quantity if not exists
              final consolidatedKey = '${po.poNo}_consolidated';
              if (!poQtyControllers[material.partNo]!.containsKey(consolidatedKey)) {
                poQtyControllers[material.partNo]![consolidatedKey] =
                    TextEditingController(text: '0');
              }

              return Column(
                children: [
                  // Consolidated PO row
            Row(
              children: [
                Expanded(
                        flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                            Text('PO: ${po.poNo}',
                                style: const TextStyle(fontWeight: FontWeight.w500)),
                            const SizedBox(height: 4),
                            Text('Job Numbers: $jobNumbers',
                                style: const TextStyle(fontSize: 12)),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Text('Ordered: $totalOrdered',
                            style: const TextStyle(fontSize: 12)),
                      ),
                      Expanded(
                        child: Text('Received: $totalReceivedQty',
                            style: const TextStyle(fontSize: 12)),
                ),
                Expanded(
                        child: TextFormField(
                          controller: poQtyControllers[material.partNo]![consolidatedKey],
                          decoration: const InputDecoration(
                            isDense: true,
                            contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                            hintText: 'Enter Qty',
                          ),
                          keyboardType: TextInputType.number,
                    style: const TextStyle(fontSize: 12),
                          onChanged: (value) {
                            setState(() {
                              final inwardQty = double.tryParse(value) ?? 0.0;
                              
                              if (inwardQty > 0) {
                                // Calculate total remaining quantity for all PRs
                                double totalRemainingQty = 0.0;
                                for (var prDetail in poItem.prDetails.entries) {
                                  final prReceivedQty = ref
                                      .read(storeInwardProvider.notifier)
                                      .getPRReceivedQuantity(material.partNo, po.poNo, prDetail.key);
                                  final prRemainingQty = prDetail.value.quantity - prReceivedQty;
                                  if (prRemainingQty > 0) {
                                    totalRemainingQty += prRemainingQty;
                                  }
                                }

                                if (totalRemainingQty > 0) {
                                  // Distribute the inward quantity proportionally among PRs
                                  double remainingInward = inwardQty;
                                  
                                  for (var prDetail in poItem.prDetails.entries) {
                                    final key = '${po.poNo}_${prDetail.key}';
                                    final prReceivedQty = ref
                                        .read(storeInwardProvider.notifier)
                                        .getPRReceivedQuantity(material.partNo, po.poNo, prDetail.key);
                                    final prRemainingQty = prDetail.value.quantity - prReceivedQty;
                                    
                                    if (prRemainingQty > 0) {
                                      selectedPOs[material.partNo]![key] = true;
                                      final proportion = prRemainingQty / totalRemainingQty;
                                      final allocatedQty = (remainingInward * proportion).roundToDouble();
                                      poQtyControllers[material.partNo]![key]?.text = allocatedQty.toString();
                                      remainingInward -= allocatedQty;
                                    }
                                  }
                                  
                                  // Add any remaining quantity due to rounding to the last PR
                                  if (remainingInward > 0) {
                                    for (var prDetail in poItem.prDetails.entries.toList().reversed) {
                                      final key = '${po.poNo}_${prDetail.key}';
                                      if (selectedPOs[material.partNo]![key] == true) {
                                        final currentQty = double.tryParse(
                                                poQtyControllers[material.partNo]![key]?.text ?? '0') ??
                                            0.0;
                                        poQtyControllers[material.partNo]![key]?.text =
                                            (currentQty + remainingInward).toString();
                                        break;
                                      }
                                    }
                                  }
                                }
                              } else {
                                // Reset PR-wise quantities
                                for (var prDetail in poItem.prDetails.entries) {
                                  final key = '${po.poNo}_${prDetail.key}';
                                  poQtyControllers[material.partNo]![key]?.text = '0';
                                  selectedPOs[material.partNo]![key] = false;
                                }
                              }
                              _invoiceAmountController.text =
                                  _calculateInvoiceAmount().toStringAsFixed(2);
                            });
                          },
                  ),
                ),
              ],
            ),
                  // Show detailed PR view only if inward qty < remaining total
                  if ((double.tryParse(poQtyControllers[material.partNo]?[consolidatedKey]?.text ?? '0') ?? 0) > 0 &&
                      (double.tryParse(poQtyControllers[material.partNo]?[consolidatedKey]?.text ?? '0') ?? 0) < (totalOrdered - totalReceivedQty))
                    Padding(
                      padding: const EdgeInsets.only(left: 16, top: 8),
                      child: Table(
              columnWidths: const {
                          0: FlexColumnWidth(0.5), // Checkbox
                          1: FlexColumnWidth(1.5), // Job No
                2: FlexColumnWidth(1), // Ordered
                3: FlexColumnWidth(1), // Received
                4: FlexColumnWidth(1.5), // Inward Qty
              },
              children: [
                const TableRow(
                  children: [
                              Text(''), // Checkbox
                              Text('Job No',
                                  style: TextStyle(fontWeight: FontWeight.w500, fontSize: 12)),
                    Text('Ordered',
                                  style: TextStyle(fontWeight: FontWeight.w500, fontSize: 12)),
                    Text('Received',
                                  style: TextStyle(fontWeight: FontWeight.w500, fontSize: 12)),
                    Text('Inward Qty',
                                  style: TextStyle(fontWeight: FontWeight.w500, fontSize: 12)),
                  ],
                ),
                          ...poItem.prDetails.entries.map((prDetail) {
                            final key = '${po.poNo}_${prDetail.key}';
                            final orderedQty = prDetail.value.quantity;
                            final receivedQty = ref
                                .read(storeInwardProvider.notifier)
                                .getPRReceivedQuantity(material.partNo, po.poNo, prDetail.key);
                            final remainingQty = orderedQty - receivedQty;
                            
                            if (remainingQty <= 0) return null;
                            
                            final isSelected = selectedPOs[material.partNo]?[key] ?? false;

                  return TableRow(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Checkbox(
                          value: isSelected,
                          onChanged: (bool? value) {
    setState(() {
                                        selectedPOs[material.partNo]![key] = value ?? false;
                              if (value == true) {
                                          // Calculate proportional quantity based on remaining quantities
                                          final totalPOInwardQty = double.tryParse(
                                              poQtyControllers[material.partNo]![
                                                      '${po.poNo}_consolidated']?.text ??
                                                  '0') ??
                                              0.0;
                                          final totalRemainingQty = poItem.prDetails.entries.fold(
                                              0.0,
                                              (sum, pr) =>
                                                  sum +
                                                  (pr.value.quantity -
                                                      ref
                                                          .read(storeInwardProvider.notifier)
                                                          .getPRReceivedQuantity(
                                                              material.partNo,
                                                              po.poNo,
                                                              pr.key)));
                                          
                                          if (totalRemainingQty > 0) {
                                            final proportion = remainingQty / totalRemainingQty;
                                            final allocatedQty =
                                                (totalPOInwardQty * proportion).roundToDouble();
                                            poQtyControllers[material.partNo]![key]?.text =
                                                allocatedQty.toString();
                                          }
                              } else {
                                          poQtyControllers[material.partNo]![key]?.text = '0';
                              }
                                        _invoiceAmountController.text =
                                            _calculateInvoiceAmount().toStringAsFixed(2);
                            });
                          },
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                                  child: Text(
                                    prDetail.value.jobNo == 'General' ? 'General Stock' : prDetail.value.jobNo,
                                    style: const TextStyle(fontSize: 12),
                      ),
                                ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                                  child: Text(orderedQty.toString(),
                            style: const TextStyle(fontSize: 12)),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                                  child: Text(receivedQty.toString(),
                                      style: const TextStyle(fontSize: 12)),
                        ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                          child: TextFormField(
                                    controller: poQtyControllers[material.partNo]![key],
                            enabled: isSelected,
                                    decoration: const InputDecoration(
                              isDense: true,
                                      contentPadding:
                                          EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                    ),
                            keyboardType: TextInputType.number,
                                    style: const TextStyle(fontSize: 12),
                            validator: (value) {
                              if (!isSelected) return null;
                                      if (value == null || value.isEmpty) return 'Required';
                              final qty = double.tryParse(value);
                                      if (qty == null || qty <= 0) return 'Invalid';
                                      if (qty > remainingQty)
                                        return 'Max ${remainingQty.toStringAsFixed(2)}';
                              return null;
                            },
                            onChanged: (value) {
                                      setState(() {
                                        // Update consolidated quantity when PR-wise quantity changes
                                        double totalPRQty = 0.0;
                                        for (var pr in poItem.prDetails.entries) {
                                          final prKey = '${po.poNo}_${pr.key}';
                                          if (selectedPOs[material.partNo]?[prKey] == true) {
                                            totalPRQty += double.tryParse(
                                                    poQtyControllers[material.partNo]?[prKey]
                                                            ?.text ??
                                                        '0') ??
                                                0.0;
                                          }
                                        }
                                        poQtyControllers[material.partNo]![
                                                '${po.poNo}_consolidated']
                                            ?.text = totalPRQty.toString();
                                        _invoiceAmountController.text =
                                            _calculateInvoiceAmount().toStringAsFixed(2);
                                      });
                            },
                        ),
                      ),
                    ],
                  );
                          }).whereType<TableRow>().toList(),
              ],
                      ),
            ),
                ],
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  InwardItem _createInwardItem(MaterialItem material, List<PurchaseOrder> pos) {
    final poQuantities = <String, double>{};
    final jobNumbers = <String, String>{};
    double totalQty = 0;

    for (var po in pos) {
      final poItem = po.items.firstWhere(
        (item) => item.materialCode == material.partNo,
      );

      for (var prDetail in poItem.prDetails.entries) {
        final key = '${po.poNo}_${prDetail.key}';
        if (!selectedPOs[material.partNo]!.containsKey(key)) {
          selectedPOs[material.partNo]![key] = false;
    }

        if (selectedPOs[material.partNo]![key] == true) {
          final inwardController = poQtyControllers[material.partNo]?[key] ??
              TextEditingController(text: '0');
          final inwardQty = double.tryParse(inwardController.text) ?? 0;
          
          if (inwardQty > 0) {
            poQuantities[po.poNo] = (poQuantities[po.poNo] ?? 0.0) + inwardQty;
            totalQty += inwardQty;
            jobNumbers[po.poNo] = prDetail.value.jobNo == 'General' 
                ? 'General Stock' 
                : prDetail.value.jobNo;
          }
        }
      }
    }

    return InwardItem(
      materialCode: material.partNo,
      materialDescription: material.description,
      unit: material.unit,
      orderedQty: totalQty,
      receivedQty: totalQty,
      acceptedQty: totalQty,
      rejectedQty: 0,
      costPerUnit: pos.first.items
          .firstWhere((item) => item.materialCode == material.partNo)
          .costPerUnit,
      poQuantities: poQuantities,
      jobNumbers: jobNumbers,
    );
  }

  // Add this method to calculate total invoice amount
  double _calculateInvoiceAmount() {
    double total = 0.0;

    for (var material in ref.read(materialListProvider)) {
      if (selectedPOs.containsKey(material.partNo)) {
        for (var entry in selectedPOs[material.partNo]!.entries) {
          if (entry.value) {
            // Extract PO number from the composite key (poNo_prKey)
            final poNo = entry.key.split('_')[0];
            final qty = double.tryParse(
                    poQtyControllers[material.partNo]?[entry.key]?.text ?? '0') ??
                0.0;

            // Find the PO and get the cost per unit
            final pos = ref
                .read(purchaseOrderListProvider)
                .where((po) => po.poNo == poNo);
                
            if (pos.isNotEmpty) {
              final po = pos.first;
              final poItem = po.items
                  .firstWhere((item) => item.materialCode == material.partNo);
              final costPerUnit = double.tryParse(poItem.costPerUnit) ?? 0.0;

              total += qty * costPerUnit;
            }
          }
        }
      }
    }

    return total;
  }

  void _onSavePressed() async {
    if (!_formKey.currentState!.validate()) return;

    if (_invoiceNoController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter Invoice No')),
      );
      return;
    }

    if (_invoiceDateController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter Invoice Date')),
      );
      return;
    }

    if (_receivedByController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter Received By')),
      );
      return;
    }

    if (_checkedByController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter Checked By')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final materials = ref.read(materialListProvider);
      final purchaseOrders = ref
          .read(purchaseOrderListProvider)
          .where((po) =>
              po.supplierName == selectedSupplier!.name && !po.isFullyReceived)
          .toList();

      final inwardItems = <InwardItem>[];
      bool hasItems = false;

      // Create inward items
      for (var material in materials) {
        final pos = purchaseOrders
            .where((po) =>
                po.items.any((item) => item.materialCode == material.partNo))
            .toList();

        if (pos.isNotEmpty) {
          final inwardItem = _createInwardItem(material, pos);
          if (inwardItem.receivedQty > 0) {
            inwardItems.add(inwardItem);
            hasItems = true;
          }
        }
      }

      if (!hasItems) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Please add at least one item with quantity')),
        );
        setState(() => _isLoading = false);
        return;
      }

      final grnNo = widget.existingGR?.grnNo ??
          'GRN${DateTime.now().millisecondsSinceEpoch}';

      final newGR = StoreInward(
        grnNo: grnNo,
        grnDate: _grnDateController.text,
        supplierName: selectedSupplier!.name,
        poNo: purchaseOrders.first.poNo,
        poDate: purchaseOrders.first.poDate,
        invoiceNo: _invoiceNoController.text,
        invoiceDate: _invoiceDateController.text,
        invoiceAmount: _invoiceAmountController.text,
        receivedBy: _receivedByController.text,
        checkedBy: _checkedByController.text,
        items: inwardItems,
      );

      // Update PO received quantities
      final poNotifier = ref.read(purchaseOrderListProvider.notifier);
      for (var inwardItem in inwardItems) {
        for (var entry in inwardItem.poQuantities.entries) {
          final poNo = entry.key;
          final qty = entry.value;

          final poIndex = purchaseOrders.indexWhere((po) => po.poNo == poNo);
          if (poIndex >= 0) {
            final po = purchaseOrders[poIndex];
            final poItem = po.items.firstWhere(
              (item) => item.materialCode == inwardItem.materialCode,
            );

            // Clear existing received quantity for this GR if editing
            if (widget.existingGR != null) {
              poItem.receivedQuantities.remove(widget.existingGR!.grnNo);
            }

            // Add new received quantity
            poItem.addReceivedQuantity(grnNo, qty);

            // Update PO status
            po.updateStatus();
            final index = ref.read(purchaseOrderListProvider).indexOf(po);
            poNotifier.updateOrder(index, po);
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
    final jobNumbers = _getUniqueJobNumbers(purchaseOrders);

    // Get materials that have pending POs from the selected supplier
    final materials = ref.watch(materialListProvider).where((material) {
      return purchaseOrders.any(
          (po) => po.items.any((item) => item.materialCode == material.partNo));
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
                                selectedPOs.clear();
                                poQtyControllers.clear();
                                    selectedJobNo = 'All';
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
                      // Job Number Filter
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
                              selectedPOs.clear();
                              poQtyControllers.clear();
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
                    onPressed: _isLoading ? null : _onSavePressed,
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
