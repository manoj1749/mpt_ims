import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../models/material_item.dart';
import '../../models/purchase_request.dart';
import '../../pages/design/add_material_page.dart';
import '../../provider/material_provider.dart';
import '../../provider/purchase_request_provider.dart';

class AddPurchaseRequestPage extends ConsumerStatefulWidget {
  final PurchaseRequest? existingRequest;
  final int? index;
  const AddPurchaseRequestPage(
      {super.key, required this.existingRequest, required this.index});

  @override
  ConsumerState<AddPurchaseRequestPage> createState() =>
      _AddPurchaseRequestPageState();
}

class _AddPurchaseRequestPageState
    extends ConsumerState<AddPurchaseRequestPage> {
  final _formKey = GlobalKey<FormState>();

  String? selectedMaterial;
  String? quantity;
  String? requiredBy;
  String? remarks;

  // Controllers for auto-fill
  final TextEditingController _partNoController = TextEditingController();
  final TextEditingController _unitController = TextEditingController();

  @override
  void dispose() {
    _partNoController.dispose();
    _unitController.dispose();
    super.dispose();
  }

  void _updateControllers(MaterialItem m) {
    _partNoController.text = m.partNo;
    _unitController.text = m.unit;
  }

  @override
  Widget build(BuildContext context) {
    final materials = ref.watch(materialListProvider);

    final selected = materials.firstWhere(
      (m) => m.description == selectedMaterial,
      orElse: () => MaterialItem(
        slNo: '',
        vendorName: '',
        description: '',
        partNo: '',
        unit: '',
        supplierRate: '',
        seiplRate: '',
        category: '',
        subCategory: '',
        saleRate: '',
        totalReceivedQty: '',
        vendorIssuedQty: '',
        vendorReceivedQty: '',
        boardIssueQty: '',
        avlStock: '',
        avlStockValue: '',
        billingQtyDiff: '',
        totalReceivedCost: '',
        totalBilledCost: '',
        costDiff: '',
      ),
    );

    // Update autofill fields on selection
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (selectedMaterial != null) _updateControllers(selected);
    });

    return Scaffold(
      appBar: AppBar(title: const Text('Add Purchase Request')),
      body: LayoutBuilder(builder: (context, constraints) {
        return SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight, maxWidth: constraints.maxWidth, minWidth: constraints.maxWidth),
            child: IntrinsicHeight(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (materials.isEmpty)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('No materials found.'),
                              ElevatedButton(
                                onPressed: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) => const AddMaterialPage()),
                                ),
                                child: const Text('Add Material'),
                              ),
                            ],
                          )
                        else
                          DropdownButtonFormField2<String>(
                            isExpanded: true,
                            value: selectedMaterial,
                            decoration: const InputDecoration(
                              labelText: 'Material Name',
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 14),
                            ),
                            items: materials
                                .map((m) => DropdownMenuItem<String>(
                                      value: m.description,
                                      child: Text(
                                          '${m.description} (${m.vendorName})'),
                                    ))
                                .toList(),
                            onChanged: (val) {
                              setState(() {
                                selectedMaterial = val;
                                final selectedItem = materials
                                    .firstWhere((m) => m.description == val);
                                _updateControllers(selectedItem);
                              });
                            },
                            validator: (val) =>
                                val == null || val.isEmpty ? 'Required' : null,
                          ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _partNoController,
                          enabled: false,
                          decoration: const InputDecoration(
                            labelText: 'Material Code (Part No)',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _unitController,
                          enabled: false,
                          decoration: const InputDecoration(
                            labelText: 'Unit',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Quantity',
                            border: OutlineInputBorder(),
                          ),
                          validator: (v) =>
                              v == null || v.isEmpty ? 'Required' : null,
                          onSaved: (v) => quantity = v,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          decoration: const InputDecoration(
                            labelText: 'Required By',
                            hintText: 'Enter date or name',
                            border: OutlineInputBorder(),
                          ),
                          validator: (v) =>
                              v == null || v.isEmpty ? 'Required' : null,
                          onSaved: (v) => requiredBy = v,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          maxLines: 3,
                          decoration: const InputDecoration(
                            labelText: 'Remarks',
                            border: OutlineInputBorder(),
                          ),
                          onSaved: (v) => remarks = v,
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: () {
                            if (_formKey.currentState!.validate()) {
                              _formKey.currentState!.save();
                              final now = DateFormat('yyyy-MM-dd')
                                  .format(DateTime.now());

                              final newRequest = PurchaseRequest(
                                prNo: widget.existingRequest?.prNo ??
                                    'PR${DateTime.now().millisecondsSinceEpoch}',
                                date: widget.existingRequest?.date ?? now,
                                materialCode: selected.partNo,
                                materialDescription: selected.description,
                                unit: selected.unit,
                                quantity: quantity ?? '',
                                requiredBy: requiredBy ?? '',
                                remarks: remarks ?? '',
                                supplierName: selected.vendorName,
                                status: 'Requested',
                              );

                              final notifier = ref
                                  .read(purchaseRequestListProvider.notifier);
                              if (widget.index != null) {
                                notifier.updateRequest(
                                    widget.index!, newRequest);
                              } else {
                                notifier.addRequest(newRequest);
                              }

                              Navigator.pop(context);
                            }
                          },
                          child: const Text('Submit'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}
