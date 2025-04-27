// ignore_for_file: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member

import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:mpt_ims/models/material_item.dart';
import 'package:mpt_ims/models/purchase_request.dart';
import 'package:mpt_ims/models/pr_item.dart';
import 'package:mpt_ims/provider/material_provider.dart';
import '../../models/supplier.dart';
import '../../models/purchase_order.dart';
import '../../provider/supplier_provider.dart';
import '../../provider/purchase_request_provider.dart';
import '../../provider/purchase_order.dart';

class AddPurchaseOrderPage extends ConsumerStatefulWidget {
  final PurchaseOrder? orderToEdit;
  const AddPurchaseOrderPage({super.key, this.orderToEdit});

  @override
  ConsumerState<AddPurchaseOrderPage> createState() =>
      _AddPurchaseOrderPageState();
}

class _AddPurchaseOrderPageState extends ConsumerState<AddPurchaseOrderPage> {
  Supplier? selectedSupplier;
  final TextEditingController _boardNoController = TextEditingController();
  final TextEditingController _transportController = TextEditingController();
  final TextEditingController _deliveryRequirementsController =
      TextEditingController();
  final Map<String, TextEditingController> _qtyControllers = {};
  final _formKey = GlobalKey<FormState>();

  // Group PRs by material code
  Map<String, List<PRItem>> _groupPRsByMaterial(List<PurchaseRequest> prs) {
    final grouped = <String, List<PRItem>>{};
    for (var pr in prs) {
      for (var item in pr.items) {
        if (!item.isFullyOrdered) {
          // Only include items that aren't fully ordered
          grouped.putIfAbsent(item.materialCode, () => []).add(item);
        }
      }
    }
    return grouped;
  }

  // Calculate total remaining quantity for a material
  double _calculateTotalRemainingQuantity(List<PRItem> items) {
    return items.fold(0.0, (sum, item) => sum + item.remainingQuantity);
  }

  // Allocate ordered quantity across PRs
  void _allocateOrderedQuantity(
      String materialCode, double orderedQty, String poNo) {
    final prs = ref.read(purchaseRequestListProvider.notifier);
    final allPRs = prs.state
        .where((pr) => pr.items.any((item) =>
            item.materialCode == materialCode && !item.isFullyOrdered))
        .toList();

    allPRs.sort((a, b) => a.date.compareTo(b.date)); // Process oldest PRs first

    var remainingToAllocate = orderedQty;
    for (var pr in allPRs) {
      if (remainingToAllocate <= 0) break;

      for (var item in pr.items) {
        if (item.materialCode != materialCode || item.isFullyOrdered) continue;

        if (remainingToAllocate <= 0) break;

        final allocateAmount = remainingToAllocate > item.remainingQuantity
            ? item.remainingQuantity
            : remainingToAllocate;

        item.addOrderedQuantity(poNo, allocateAmount);
        remainingToAllocate -= allocateAmount;
      }

      pr.updateStatus();
      pr.save();
    }
  }

  @override
  void initState() {
    super.initState();
    if (widget.orderToEdit != null) {
      final order = widget.orderToEdit!;
      _boardNoController.text = order.boardNo;
      _transportController.text = order.transport;
      _deliveryRequirementsController.text = order.deliveryRequirements;

      // Initialize quantity controllers for existing items
      for (var item in order.items) {
        _qtyControllers[item.materialCode] = TextEditingController(
          text: item.quantity.toString(),
        );
      }
    }
  }

  @override
  void dispose() {
    _boardNoController.dispose();
    _transportController.dispose();
    _deliveryRequirementsController.dispose();
    for (var controller in _qtyControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  double calculateTotal(List<POItem> items) {
    return items.fold(0.0, (sum, item) => sum + item.totalCost);
  }

  @override
  Widget build(BuildContext context) {
    final suppliers = ref.watch(supplierListProvider);
    final purchaseRequests = ref.watch(purchaseRequestListProvider);
    final poNotifier = ref.read(purchaseOrderProvider.notifier);

    final filteredPRs = selectedSupplier == null
        ? <PurchaseRequest>[]
        : purchaseRequests
            .where((pr) =>
                pr.supplierName == selectedSupplier!.name && !pr.isFullyOrdered)
            .toList();

    final groupedItems = _groupPRsByMaterial(filteredPRs);
    final materials = ref.watch(materialListProvider);

    final poItems = <String, POItem>{};

    for (var entry in groupedItems.entries) {
      final materialCode = entry.key;
      final items = entry.value;
      final totalRemainingQty = _calculateTotalRemainingQuantity(items);

      if (totalRemainingQty <= 0) continue; // Skip if no remaining quantity

      MaterialItem? findMaterialByCode(List<MaterialItem> list, String code) {
        for (final item in list) {
          if (item.partNo == code) return item;
        }
        return null;
      }

      final material = findMaterialByCode(materials, materialCode);
      if (material == null) continue;

      poItems[materialCode] = POItem(
        materialCode: materialCode,
        materialDescription: material.description,
        unit: material.unit,
        quantity: totalRemainingQty,
        costPerUnit: double.parse(material.saleRate),
        totalCost: totalRemainingQty * double.parse(material.saleRate),
        seiplRate: double.parse(material.seiplRate),
        rateDifference:
            double.parse(material.saleRate) - double.parse(material.seiplRate),
        totalRateDifference: totalRemainingQty *
            (double.parse(material.saleRate) -
                double.parse(material.seiplRate)),
      );

      // Initialize controller if not exists
      _qtyControllers[materialCode] ??= TextEditingController(
        text: totalRemainingQty.toString(),
      );
    }

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
              const SizedBox(height: 12),
              if (selectedSupplier != null)
                Card(
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Address:",
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        Text(
                            "${selectedSupplier!.address1}, ${selectedSupplier!.address2},"),
                        Text(
                            "${selectedSupplier!.address3}, ${selectedSupplier!.address4}"),
                        const SizedBox(height: 6),
                        Text("GSTIN: ${selectedSupplier!.gstNo}"),
                        Text("Email: ${selectedSupplier!.email}"),
                        Text("Contact: ${selectedSupplier!.contact}"),
                        const SizedBox(height: 6),
                        Text("Payment Terms: ${selectedSupplier!.paymentTerms}",
                            style: const TextStyle(color: Colors.blueGrey)),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _transportController,
                decoration: const InputDecoration(labelText: 'Transport'),
              ),
              TextFormField(
                controller: _deliveryRequirementsController,
                decoration:
                    const InputDecoration(labelText: 'Delivery Requirements'),
              ),
              TextFormField(
                controller: _boardNoController,
                decoration: const InputDecoration(labelText: 'Board No'),
              ),
              const SizedBox(height: 10),
              if (poItems.isNotEmpty)
                Expanded(
                  child: Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Theme.of(context).primaryColor,
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(16),
                              topRight: Radius.circular(16),
                            ),
                          ),
                          child: const Row(
                            children: [
                              Expanded(
                                flex: 2,
                                child: Text(
                                  "Material Details",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  "Quantity",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  "Rates",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  "Cost",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: ListView.separated(
                            padding: const EdgeInsets.all(16),
                            itemCount: poItems.length,
                            separatorBuilder: (_, __) =>
                                const Divider(height: 32),
                            itemBuilder: (_, index) {
                              final item = poItems.values.elementAt(index);
                              final prItems =
                                  groupedItems[item.materialCode] ?? [];
                              final totalNeededQty =
                                  _calculateTotalRemainingQuantity(prItems);

                              // Initialize controller if not exists
                              _qtyControllers[item.materialCode] ??=
                                  TextEditingController(
                                text: totalNeededQty.toString(),
                              );

                              return Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.grey[900],
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.1),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      flex: 2,
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                  horizontal: 8,
                                                  vertical: 4,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: Theme.of(context)
                                                      .primaryColor
                                                      .withOpacity(0.2),
                                                  borderRadius:
                                                      BorderRadius.circular(6),
                                                ),
                                                child: Text(
                                                  item.materialCode,
                                                  style: TextStyle(
                                                    color: Theme.of(context)
                                                        .primaryColor,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            item.materialDescription,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 14,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            "Qty Needed",
                                            style: TextStyle(
                                              color: Colors.white70,
                                              fontSize: 12,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            "$totalNeededQty ${item.unit}",
                                            style: const TextStyle(
                                              color: Colors.amberAccent,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          const Text(
                                            "Order Qty",
                                            style: TextStyle(
                                              color: Colors.white70,
                                              fontSize: 12,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          TextFormField(
                                            controller: _qtyControllers[
                                                item.materialCode],
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                            ),
                                            keyboardType: TextInputType.number,
                                            validator: (value) {
                                              final inputQty = double.tryParse(
                                                      value ?? '') ??
                                                  0;
                                              if (inputQty <= 0) {
                                                return 'Quantity must be greater than 0';
                                              }
                                              if (inputQty > totalNeededQty) {
                                                return 'Cannot exceed required quantity ($totalNeededQty)';
                                              }
                                              return null;
                                            },
                                            onChanged: (val) {
                                              final newQty =
                                                  double.tryParse(val) ?? 0;

                                              // Limit the quantity to remaining quantity
                                              final limitedQty =
                                                  newQty > totalNeededQty
                                                      ? totalNeededQty
                                                      : newQty;

                                              if (newQty > totalNeededQty) {
                                                _qtyControllers[
                                                            item.materialCode]
                                                        ?.text =
                                                    totalNeededQty.toString();
                                              }

                                              setState(() {
                                                item.quantity = limitedQty;
                                                item.totalCost = limitedQty *
                                                    item.costPerUnit;
                                                item.totalRateDifference =
                                                    limitedQty *
                                                        item.rateDifference;
                                              });
                                            },
                                            decoration: InputDecoration(
                                              isDense: true,
                                              contentPadding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 8,
                                                      vertical: 6),
                                              filled: true,
                                              fillColor: Colors.grey[850],
                                              border: OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(6),
                                              ),
                                              errorStyle: const TextStyle(
                                                color: Colors.redAccent,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            "Rate Details",
                                            style: TextStyle(
                                              color: Colors.white70,
                                              fontSize: 12,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          RichText(
                                            text: TextSpan(
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 13,
                                              ),
                                              children: [
                                                const TextSpan(
                                                  text: "Cost/Unit: ",
                                                  style: TextStyle(
                                                      color: Colors.white70),
                                                ),
                                                TextSpan(
                                                  text:
                                                      "₹${item.costPerUnit}\n",
                                                  style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold),
                                                ),
                                                const TextSpan(
                                                  text: "SEIPL: ",
                                                  style: TextStyle(
                                                      color: Colors.white70),
                                                ),
                                                TextSpan(
                                                  text: "₹${item.seiplRate}",
                                                  style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            "Cost Summary",
                                            style: TextStyle(
                                              color: Colors.white70,
                                              fontSize: 12,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          ListenableBuilder(
                                            listenable: _qtyControllers[
                                                item.materialCode]!,
                                            builder: (context, child) {
                                              final qty = double.tryParse(
                                                      _qtyControllers[item
                                                              .materialCode]!
                                                          .text) ??
                                                  item.quantity;
                                              final totalCost =
                                                  qty * item.costPerUnit;
                                              final totalDiff =
                                                  qty * item.rateDifference;

                                              return RichText(
                                                text: TextSpan(
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 13,
                                                  ),
                                                  children: [
                                                    const TextSpan(
                                                      text: "Total: ",
                                                      style: TextStyle(
                                                          color:
                                                              Colors.white70),
                                                    ),
                                                    TextSpan(
                                                      text:
                                                          "₹${totalCost.toStringAsFixed(2)}\n",
                                                      style: const TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        fontSize: 15,
                                                      ),
                                                    ),
                                                    const TextSpan(
                                                      text: "Difference: ",
                                                      style: TextStyle(
                                                          color:
                                                              Colors.white70),
                                                    ),
                                                    TextSpan(
                                                      text:
                                                          "₹${totalDiff.toStringAsFixed(2)}",
                                                      style: TextStyle(
                                                        color: totalDiff > 0
                                                            ? Colors.red[300]
                                                            : Colors.green[300],
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              );
                                            },
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.grey[900],
                            borderRadius: const BorderRadius.only(
                              bottomLeft: Radius.circular(16),
                              bottomRight: Radius.circular(16),
                            ),
                          ),
                          child: ListenableBuilder(
                            listenable: Listenable.merge(
                              _qtyControllers.values.toList(),
                            ),
                            builder: (context, _) {
                              double total = 0;
                              for (var item in poItems.values) {
                                final qty = double.tryParse(
                                        _qtyControllers[item.materialCode]
                                                ?.text ??
                                            '0') ??
                                    0;
                                total += qty * item.costPerUnit;
                              }

                              return Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  Text(
                                    "Total Order Value: ",
                                    style: TextStyle(
                                      color: Colors.grey[400],
                                      fontSize: 16,
                                    ),
                                  ),
                                  Text(
                                    "₹${total.toStringAsFixed(2)}",
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 20,
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 10),
              Center(
                child: ElevatedButton(
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      final now =
                          DateFormat('yyyy-MM-dd').format(DateTime.now());
                      final poNo = 'PO${DateTime.now().millisecondsSinceEpoch}';

                      // Create updated items list with final quantities
                      final updatedItems = poItems.values.map((item) {
                        final qty = double.tryParse(
                                _qtyControllers[item.materialCode]?.text ??
                                    '0') ??
                            0;

                        // Allocate ordered quantity across PRs
                        _allocateOrderedQuantity(item.materialCode, qty, poNo);

                        return POItem(
                          materialCode: item.materialCode,
                          materialDescription: item.materialDescription,
                          unit: item.unit,
                          quantity: qty,
                          costPerUnit: item.costPerUnit,
                          totalCost: qty * item.costPerUnit,
                          seiplRate: item.seiplRate,
                          rateDifference: item.rateDifference,
                          totalRateDifference: qty * item.rateDifference,
                        );
                      }).toList();

                      // Calculate final total
                      double total = updatedItems.fold(
                          0.0, (sum, item) => sum + item.totalCost);

                      // Create and save purchase order
                      final po = PurchaseOrder(
                        poNo: poNo,
                        poDate: now,
                        supplierName: selectedSupplier?.name ?? '',
                        boardNo: _boardNoController.text,
                        transport: _transportController.text,
                        deliveryRequirements:
                            _deliveryRequirementsController.text,
                        items: updatedItems,
                        total: total,
                        igst: 0,
                        cgst: 0,
                        sgst: 0,
                        grandTotal: total,
                      );

                      poNotifier.addOrder(po);
                      Navigator.pop(context);
                    }
                  },
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
              )
            ],
          ),
        ),
      ),
    );
  }
}
