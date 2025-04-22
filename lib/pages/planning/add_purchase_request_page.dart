import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../models/material_item.dart';
import '../../models/purchase_request.dart';
import '../../models/pr_item.dart';
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

class _AddPurchaseRequestPageState extends ConsumerState<AddPurchaseRequestPage> {
  final _formKey = GlobalKey<FormState>();
  final List<PRItemFormData> _items = [];
  String? _requiredBy;

  @override
  void initState() {
    super.initState();
    if (widget.existingRequest != null) {
      _requiredBy = widget.existingRequest!.requiredBy;
      for (var item in widget.existingRequest!.items) {
        _items.add(PRItemFormData(
          selectedMaterial: item.materialDescription,
          quantity: item.quantity,
          remarks: item.remarks,
          partNoController: TextEditingController(text: item.materialCode),
          unitController: TextEditingController(text: item.unit),
        ));
      }
    } else {
      _addNewItem();
    }
  }

  @override
  void dispose() {
    for (var item in _items) {
      item.dispose();
    }
    super.dispose();
  }

  void _addNewItem() {
    setState(() {
      _items.add(PRItemFormData(
        selectedMaterial: null,
        quantity: null,
        remarks: null,
        partNoController: TextEditingController(),
        unitController: TextEditingController(),
      ));
    });
  }

  void _removeItem(int index) {
    setState(() {
      _items[index].dispose();
      _items.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    final materials = ref.watch(materialListProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Add Purchase Request')),
      body: LayoutBuilder(builder: (context, constraints) {
        return SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: constraints.maxHeight,
              maxWidth: constraints.maxWidth,
              minWidth: constraints.maxWidth,
            ),
            child: IntrinsicHeight(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
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
                        Column(
                          children: [
                            TextFormField(
                              initialValue: _requiredBy,
                              decoration: const InputDecoration(
                                labelText: 'Required By',
                                hintText: 'Enter date or name',
                                border: OutlineInputBorder(),
                              ),
                              validator: (v) =>
                                  v == null || v.isEmpty ? 'Required' : null,
                              onSaved: (v) => _requiredBy = v,
                            ),
                            const SizedBox(height: 20),
                            ..._items.asMap().entries.map((entry) {
                              final index = entry.key;
                              final item = entry.value;
                              return Card(
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            'Item ${index + 1}',
                                            style: Theme.of(context)
                                                .textTheme
                                                .titleMedium,
                                          ),
                                          if (_items.length > 1)
                                            IconButton(
                                              icon: const Icon(Icons.delete),
                                              onPressed: () =>
                                                  _removeItem(index),
                                            ),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      DropdownButtonFormField2<String>(
                                        isExpanded: true,
                                        value: item.selectedMaterial,
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
                                            item.selectedMaterial = val;
                                            final selectedItem = materials
                                                .firstWhere((m) =>
                                                    m.description == val);
                                            item.partNoController.text =
                                                selectedItem.partNo;
                                            item.unitController.text =
                                                selectedItem.unit;
                                          });
                                        },
                                        validator: (val) => val == null ||
                                                val.isEmpty
                                            ? 'Required'
                                            : null,
                                      ),
                                      const SizedBox(height: 12),
                                      TextFormField(
                                        controller: item.partNoController,
                                        enabled: false,
                                        decoration: const InputDecoration(
                                          labelText: 'Material Code (Part No)',
                                          border: OutlineInputBorder(),
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      TextFormField(
                                        controller: item.unitController,
                                        enabled: false,
                                        decoration: const InputDecoration(
                                          labelText: 'Unit',
                                          border: OutlineInputBorder(),
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      TextFormField(
                                        initialValue: item.quantity,
                                        keyboardType: TextInputType.number,
                                        decoration: const InputDecoration(
                                          labelText: 'Quantity',
                                          border: OutlineInputBorder(),
                                        ),
                                        validator: (v) => v == null ||
                                                v.isEmpty
                                            ? 'Required'
                                            : null,
                                        onSaved: (v) => item.quantity = v,
                                      ),
                                      const SizedBox(height: 12),
                                      TextFormField(
                                        initialValue: item.remarks,
                                        maxLines: 3,
                                        decoration: const InputDecoration(
                                          labelText: 'Remarks',
                                          border: OutlineInputBorder(),
                                        ),
                                        onSaved: (v) => item.remarks = v,
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }).toList(),
                            const SizedBox(height: 20),
                            ElevatedButton.icon(
                              onPressed: _addNewItem,
                              icon: const Icon(Icons.add),
                              label: const Text('Add Another Item'),
                            ),
                          ],
                        ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: () {
                          if (_formKey.currentState!.validate()) {
                            _formKey.currentState!.save();
                            final now =
                                DateFormat('yyyy-MM-dd').format(DateTime.now());

                            final items = _items.map((item) {
                              final material = materials.firstWhere(
                                (m) => m.description == item.selectedMaterial,
                              );

                              return PRItem(
                                materialCode: material.partNo,
                                materialDescription: material.description,
                                unit: material.unit,
                                quantity: item.quantity!,
                                remarks: item.remarks ?? '',
                              );
                            }).toList();

                            final newRequest = PurchaseRequest(
                              prNo: widget.existingRequest?.prNo ??
                                  'PR${DateTime.now().millisecondsSinceEpoch}',
                              date: widget.existingRequest?.date ?? now,
                              requiredBy: _requiredBy!,
                              supplierName: materials
                                  .firstWhere((m) =>
                                      m.description == _items[0].selectedMaterial)
                                  .vendorName,
                              items: items,
                              status: 'Requested',
                            );

                            final notifier =
                                ref.read(purchaseRequestListProvider.notifier);
                            if (widget.index != null) {
                              notifier.updateRequest(widget.index!, newRequest);
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
        );
      }),
    );
  }
}

class PRItemFormData {
  String? selectedMaterial;
  String? quantity;
  String? remarks;
  final TextEditingController partNoController;
  final TextEditingController unitController;

  PRItemFormData({
    required this.selectedMaterial,
    required this.quantity,
    required this.remarks,
    required this.partNoController,
    required this.unitController,
  });

  void dispose() {
    partNoController.dispose();
    unitController.dispose();
  }
}
