import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:mpt_ims/models/material_item.dart';
import 'package:mpt_ims/provider/material_provider.dart';
import '../../models/supplier.dart';
import '../../models/purchase_order.dart';
import '../../provider/supplier_provider.dart';
import '../../provider/purchase_request_provider.dart';
import '../../provider/purchase_order.dart';

class AddPurchaseOrderPage extends ConsumerStatefulWidget {
  const AddPurchaseOrderPage({super.key});

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
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _boardNoController.dispose();
    _transportController.dispose();
    _deliveryRequirementsController.dispose();
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
        ? []
        : purchaseRequests
            .where((pr) =>
                pr.supplierName == selectedSupplier!.name &&
                pr.materialCode.isNotEmpty)
            .toList();

    final materials = ref.watch(materialListProvider);

    final groupedItems = <String, POItem>{};

    for (var pr in filteredPRs) {
      final qty = double.tryParse(pr.quantity) ?? 0;

      MaterialItem? findMaterialByCode(List<MaterialItem> list, String code) {
        for (final item in list) {
          if (item.partNo == code) return item;
        }
        return null;
      }

      final material = findMaterialByCode(materials, pr.materialCode);

      if (!groupedItems.containsKey(pr.materialCode)) {
        groupedItems[pr.materialCode] = POItem(
          materialCode: pr.materialCode,
          materialDescription: material?.description ?? '',
          unit: material?.unit ?? '',
          quantity: qty,
          costPerUnit: double.parse(material?.saleRate ?? '0'),
          totalCost: qty * double.parse(material?.saleRate ?? '0'),
          seiplRate: double.parse(material?.seiplRate ?? '0'),
          rateDifference: double.parse(material?.saleRate ?? '0') -
              double.parse(material?.seiplRate ?? '0'),
          totalRateDifference: (double.parse(material?.saleRate ?? '0') -
                  double.parse(material?.seiplRate ?? '0')) *
              qty,
        );
      } else {
        groupedItems[pr.materialCode]!.quantity += qty;
        final updatedQty = groupedItems[pr.materialCode]!.quantity;
        groupedItems[pr.materialCode]!.totalCost =
            updatedQty * double.parse(material?.saleRate ?? '0');
        groupedItems[pr.materialCode]!.totalRateDifference = updatedQty *
            (double.parse(material?.saleRate ?? '0') -
                double.parse(material?.seiplRate ?? '0'));
      }
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
                    child: DropdownButtonFormField<Supplier>(
                      value: selectedSupplier,
                      hint: const Text("Select Supplier"),
                      onChanged: (val) =>
                          setState(() => selectedSupplier = val),
                      items: suppliers
                          .map((s) =>
                              DropdownMenuItem(value: s, child: Text(s.name)))
                          .toList(),
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
              if (groupedItems.isNotEmpty)
                Expanded(
                  child: ListView.separated(
                    itemCount: groupedItems.length,
                    separatorBuilder: (_, __) => const Divider(),
                    itemBuilder: (_, index) {
                      final item = groupedItems.values.elementAt(index);
                      return Card(
                        margin: const EdgeInsets.symmetric(
                            vertical: 6, horizontal: 4),
                        elevation: 2,
                        color: Colors.grey[900],
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                      child: Text(
                                          "Cat No: ${item.materialCode}",
                                          style: const TextStyle(
                                              color: Colors.white))),
                                  Expanded(
                                      child: Text(
                                          "Qty: ${item.quantity} ${item.unit}",
                                          style: const TextStyle(
                                              color: Colors.white))),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text("Description: ${item.materialDescription}",
                                  style: const TextStyle(color: Colors.white)),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Expanded(
                                      child: Text(
                                          "Cost/Unit: ₹${item.costPerUnit}",
                                          style: const TextStyle(
                                              color: Colors.white))),
                                  Expanded(
                                      child: Text(
                                          "SEIPL Rate: ₹${item.seiplRate}",
                                          style: const TextStyle(
                                              color: Colors.white))),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Expanded(
                                      child: Text(
                                          "Total Cost: ₹${item.totalCost.toStringAsFixed(2)}",
                                          style: const TextStyle(
                                              color: Colors.white))),
                                  Expanded(
                                      child: Text(
                                          "Rate Diff: ₹${item.rateDifference.toStringAsFixed(2)}",
                                          style: const TextStyle(
                                              color: Colors.white))),
                                  Expanded(
                                      child: Text(
                                          "Total Diff: ₹${item.totalRateDifference.toStringAsFixed(2)}",
                                          style: const TextStyle(
                                              color: Colors.white))),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              const SizedBox(height: 10),
              Center(
                child: ElevatedButton(
                  onPressed: () {
                    final now = DateFormat('yyyy-MM-dd').format(DateTime.now());
                    final items = groupedItems.values.toList();
                    final total = calculateTotal(items);
                    final po = PurchaseOrder(
                      poNo: 'PO${DateTime.now().millisecondsSinceEpoch}',
                      poDate: now,
                      supplierName: selectedSupplier?.name ?? '',
                      boardNo: _boardNoController.text,
                      transport: _transportController.text,
                      deliveryRequirements:
                          _deliveryRequirementsController.text,
                      items: items,
                      total: total,
                      igst: 0,
                      cgst: 0,
                      sgst: 0,
                      grandTotal: total,
                    );
                    poNotifier.addOrder(po);
                    Navigator.pop(context);
                  },
                  child: const Text("Save Data"),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
