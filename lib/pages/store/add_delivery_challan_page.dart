import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/delivery_challan.dart';
import '../../models/material_item.dart';
import '../../provider/delivery_challan_provider.dart';
import '../../provider/stock_maintenance_provider.dart';
import '../store/material_selection_dialog.dart';

final deliveryChallanNotifierProvider =
    StateNotifierProvider<DeliveryChallanNotifier, List<DeliveryChallan>>(
  (ref) => DeliveryChallanNotifier(
    ref.watch(deliveryChallanBoxProvider),
    ref.watch(stockMaintenanceBoxProvider),
  ),
);

class AddDeliveryChallanPage extends ConsumerStatefulWidget {
  final DeliveryChallan? deliveryChallan;

  const AddDeliveryChallanPage({super.key, this.deliveryChallan});

  @override
  ConsumerState<AddDeliveryChallanPage> createState() =>
      _AddDeliveryChallanPageState();
}

class _AddDeliveryChallanPageState
    extends ConsumerState<AddDeliveryChallanPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _vendorNameController;
  late TextEditingController _vendorEmailController;
  late TextEditingController _vendorGstinController;
  late TextEditingController _noteController;
  bool _isReturnable = false;
  List<DeliveryChallanItem> _items = [];

  @override
  void initState() {
    super.initState();
    _vendorNameController = TextEditingController(
      text: widget.deliveryChallan?.vendorName ?? '',
    );
    _vendorEmailController = TextEditingController(
      text: widget.deliveryChallan?.vendorEmail ?? '',
    );
    _vendorGstinController = TextEditingController(
      text: widget.deliveryChallan?.vendorGstin ?? '',
    );
    _noteController = TextEditingController(
      text: widget.deliveryChallan?.note ?? '',
    );
    _isReturnable = widget.deliveryChallan?.isReturnable ?? false;
    _items =
        widget.deliveryChallan?.items.map((i) => i.copyWith()).toList() ?? [];
  }

  @override
  void dispose() {
    _vendorNameController.dispose();
    _vendorEmailController.dispose();
    _vendorGstinController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _addItems() async {
    final materials = await showDialog<List<MaterialItem>>(
      context: context,
      builder: (context) => const MaterialSelectionDialog(),
    );

    if (materials != null && materials.isNotEmpty) {
      setState(() {
        for (var material in materials) {
          if (!_items.any((item) => item.materialCode == material.partNo)) {
            _items.add(
              DeliveryChallanItem(
                materialCode: material.partNo,
                materialDescription: material.description,
                unit: material.unit,
                quantity: 0,
              ),
            );
          }
        }
      });
    }
  }

  void _removeItem(int index) {
    setState(() {
      _items.removeAt(index);
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    if (_items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one item')),
      );
      return;
    }

    // Check stock availability
    final stockBox = ref.read(stockMaintenanceBoxProvider);
    for (var item in _items) {
      final stockItem = stockBox.values
          .firstWhere((stock) => stock.materialCode == item.materialCode);

      final jobNo = item.jobNo ?? 'General';
      final availableQty =
          stockItem.jobDetails[jobNo]?.allocatedQuantity ?? 0.0;
      final consumedQty = stockItem.jobDetails[jobNo]?.consumedQuantity ?? 0.0;
      final remainingQty = availableQty - consumedQty;

      if (item.quantity > remainingQty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Insufficient stock for ${item.materialDescription} in job $jobNo',
            ),
          ),
        );
        return;
      }
    }

    final notifier = ref.read(deliveryChallanNotifierProvider.notifier);
    final dc = DeliveryChallan(
      dcNo: widget.deliveryChallan?.dcNo ?? notifier.generateDcNo(),
      dcDate: widget.deliveryChallan?.dcDate ??
          DateTime.now().toString().split(' ')[0],
      vendorName: _vendorNameController.text,
      vendorEmail: _vendorEmailController.text,
      vendorGstin: _vendorGstinController.text,
      items: _items,
      isReturnable: _isReturnable,
      note: _noteController.text,
    );

    try {
      if (widget.deliveryChallan != null) {
        await notifier.updateDeliveryChallan(dc);
      } else {
        await notifier.createDeliveryChallan(dc);
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.deliveryChallan != null
              ? 'Edit Delivery Challan'
              : 'New Delivery Challan',
        ),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _vendorNameController,
                decoration: const InputDecoration(
                  labelText: 'Vendor Name',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter vendor name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _vendorEmailController,
                decoration: const InputDecoration(
                  labelText: 'Vendor Email',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _vendorGstinController,
                decoration: const InputDecoration(
                  labelText: 'Vendor GSTIN',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              CheckboxListTile(
                title: const Text('Returnable'),
                value: _isReturnable,
                onChanged: (value) {
                  setState(() {
                    _isReturnable = value ?? false;
                  });
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _noteController,
                decoration: const InputDecoration(
                  labelText: 'Note',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Items',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: _addItems,
                    icon: const Icon(Icons.add),
                    label: const Text('Add Items'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _items.length,
                itemBuilder: (context, index) {
                  final item = _items[index];
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  '${item.materialCode} - ${item.materialDescription}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete),
                                onPressed: () => _removeItem(index),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  initialValue: item.quantity.toString(),
                                  decoration: InputDecoration(
                                    labelText: 'Quantity (${item.unit})',
                                    border: const OutlineInputBorder(),
                                  ),
                                  keyboardType: TextInputType.number,
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Please enter quantity';
                                    }
                                    final qty = double.tryParse(value);
                                    if (qty == null || qty <= 0) {
                                      return 'Please enter a valid quantity';
                                    }
                                    return null;
                                  },
                                  onChanged: (value) {
                                    final qty = double.tryParse(value) ?? 0;
                                    setState(() {
                                      _items[index] =
                                          item.copyWith(quantity: qty);
                                    });
                                  },
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: TextFormField(
                                  initialValue: item.jobNo ?? 'General',
                                  decoration: const InputDecoration(
                                    labelText: 'Job No',
                                    border: OutlineInputBorder(),
                                  ),
                                  onChanged: (value) {
                                    setState(() {
                                      _items[index] = item.copyWith(
                                        jobNo: value.isEmpty ? null : value,
                                      );
                                    });
                                  },
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _save,
        icon: const Icon(Icons.save),
        label: const Text('Save'),
      ),
    );
  }
}
