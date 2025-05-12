import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../models/sale_order.dart';
import '../../models/sale_order_item.dart';
import '../../models/material_item.dart';
import '../../provider/sale_order_provider.dart';
import '../../provider/customer_provider.dart';
import '../../provider/material_provider.dart';

class AddEditSaleOrderPage extends ConsumerStatefulWidget {
  final SaleOrder? order;

  const AddEditSaleOrderPage({super.key, this.order});

  @override
  ConsumerState<AddEditSaleOrderPage> createState() => _AddEditSaleOrderPageState();
}

class _AddEditSaleOrderPageState extends ConsumerState<AddEditSaleOrderPage> {
  final _formKey = GlobalKey<FormState>();
  final _orderDateController = TextEditingController();
  final _boardNoController = TextEditingController();
  String? _selectedCustomer;
  List<SaleOrderItem> _items = [];

  @override
  void initState() {
    super.initState();
    if (widget.order != null) {
      // Edit mode - populate fields
      _orderDateController.text = widget.order!.orderDate;
      _boardNoController.text = widget.order!.boardNo;
      _selectedCustomer = widget.order!.customerName;
      _items = List.from(widget.order!.items);
    } else {
      // Add mode - set defaults
      _orderDateController.text = DateFormat('yyyy-MM-dd').format(DateTime.now());
      _items = [];
    }
  }

  @override
  void dispose() {
    _orderDateController.dispose();
    _boardNoController.dispose();
    super.dispose();
  }

  void _addItem() {
    showDialog(
      context: context,
      builder: (context) => _AddItemDialog(
        onAdd: (item) {
          setState(() {
            _items.add(item);
          });
        },
      ),
    );
  }

  void _removeItem(int index) {
    setState(() {
      _items.removeAt(index);
    });
  }

  void _updateQuantity(int index, double newQuantity) {
    setState(() {
      _items[index].updateQuantity(newQuantity);
    });
  }

  @override
  Widget build(BuildContext context) {
    final customers = ref.watch(customerListProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.order == null ? 'Create Sale Order' : 'Edit Sale Order'),
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Order details section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Order Details',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (widget.order != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: TextFormField(
                          initialValue: widget.order!.orderNo,
                          decoration: const InputDecoration(
                            labelText: 'Order No',
                            border: OutlineInputBorder(),
                          ),
                          enabled: false,
                        ),
                      ),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _orderDateController,
                            decoration: const InputDecoration(
                              labelText: 'Order Date',
                              border: OutlineInputBorder(),
                            ),
                            readOnly: true,
                            onTap: () async {
                              final date = await showDatePicker(
                                context: context,
                                initialDate: DateTime.now(),
                                firstDate: DateTime(2000),
                                lastDate: DateTime(2100),
                              );
                              if (date != null) {
                                setState(() {
                                  _orderDateController.text =
                                      DateFormat('yyyy-MM-dd').format(date);
                                });
                              }
                            },
                            validator: (value) =>
                                value?.isEmpty == true ? 'Required' : null,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _selectedCustomer,
                            decoration: const InputDecoration(
                              labelText: 'Customer',
                              border: OutlineInputBorder(),
                            ),
                            items: customers.map((customer) {
                              return DropdownMenuItem(
                                value: customer.name,
                                child: Text(customer.name),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                _selectedCustomer = value;
                              });
                            },
                            validator: (value) =>
                                value == null ? 'Required' : null,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _boardNoController,
                      decoration: const InputDecoration(
                        labelText: 'Job No',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) =>
                          value?.isEmpty == true ? 'Required' : null,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Items section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
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
                        FilledButton.tonal(
                          onPressed: _addItem,
                          child: const Text('Add Item'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (_items.isEmpty)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 32),
                          child: Text(
                            'No items added yet.\nClick "Add Item" to add materials.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.grey,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      )
                    else
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _items.length,
                        separatorBuilder: (_, __) => const Divider(),
                        itemBuilder: (context, index) {
                          final item = _items[index];
                          return ListTile(
                            title: Text(item.materialDescription),
                            subtitle: Text(
                              '${item.quantity} ${item.unit}',
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit),
                                  onPressed: () {
                                    showDialog(
                                      context: context,
                                      builder: (context) => _EditItemDialog(
                                        item: item,
                                        onUpdate: (quantity, _) {
                                          _updateQuantity(index, quantity);
                                        },
                                      ),
                                    );
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline),
                                  onPressed: () => _removeItem(index),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Save button
            FilledButton(
              onPressed: _items.isEmpty
                  ? null
                  : () {
                      if (_formKey.currentState!.validate()) {
                        final order = SaleOrder(
                          orderNo: widget.order?.orderNo ??
                              ref
                                  .read(saleOrderProvider.notifier)
                                  .generateOrderNumber(),
                          orderDate: _orderDateController.text,
                          customerName: _selectedCustomer!,
                          boardNo: _boardNoController.text,
                          items: _items,
                        );

                        if (widget.order != null) {
                          ref
                              .read(saleOrderProvider.notifier)
                              .updateOrder(order);
                        } else {
                          ref
                              .read(saleOrderProvider.notifier)
                              .addOrder(order);
                        }

                        Navigator.pop(context);
                      }
                    },
              child: Text(widget.order == null ? 'Create Order' : 'Update Order'),
            ),
          ],
        ),
      ),
    );
  }
}

class _AddItemDialog extends ConsumerStatefulWidget {
  final void Function(SaleOrderItem) onAdd;

  const _AddItemDialog({required this.onAdd});

  @override
  ConsumerState<_AddItemDialog> createState() => _AddItemDialogState();
}

class _AddItemDialogState extends ConsumerState<_AddItemDialog> {
  MaterialItem? _selectedMaterial;
  final _quantityController = TextEditingController();
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _quantityController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final materials = ref.watch(materialListProvider);
    final filteredMaterials = materials.where((material) {
      final search = _searchQuery.toLowerCase();
      return material.description.toLowerCase().contains(search) ||
          material.slNo.toLowerCase().contains(search) ||
          material.partNo.toLowerCase().contains(search);
    }).toList();

    return AlertDialog(
      title: const Text('Add Item'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Search field
            TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                labelText: 'Search Materials',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
            const SizedBox(height: 16),
            
            // Material selection chips
            const Text(
              'Select Material',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 200,
              child: SingleChildScrollView(
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: filteredMaterials.map((material) {
                    final isSelected = _selectedMaterial?.slNo == material.slNo;
                    return FilterChip(
                      label: Text(material.description),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() {
                          _selectedMaterial = selected ? material : null;
                        });
                      },
                    );
                  }).toList(),
                ),
              ),
            ),
            if (_selectedMaterial != null) ...[
              const SizedBox(height: 16),
              Text(
                'Selected: ${_selectedMaterial!.description}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              Text('Code: ${_selectedMaterial!.slNo}'),
              Text('Unit: ${_selectedMaterial!.unit}'),
              const SizedBox(height: 16),
              TextFormField(
                controller: _quantityController,
                decoration: InputDecoration(
                  labelText: 'Quantity (${_selectedMaterial!.unit})',
                  border: const OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('CANCEL'),
        ),
        FilledButton(
          onPressed: _selectedMaterial == null
              ? null
              : () {
                  final quantity = double.tryParse(_quantityController.text) ?? 0;

                  final item = SaleOrderItem(
                    materialCode: _selectedMaterial!.slNo,
                    materialDescription: _selectedMaterial!.description,
                    unit: _selectedMaterial!.unit,
                    quantity: quantity,
                  );

                  widget.onAdd(item);
                  Navigator.pop(context);
                },
          child: const Text('ADD'),
        ),
      ],
    );
  }
}

class _EditItemDialog extends StatefulWidget {
  final SaleOrderItem item;
  final void Function(double quantity, double costPerUnit) onUpdate;

  const _EditItemDialog({
    required this.item,
    required this.onUpdate,
  });

  @override
  State<_EditItemDialog> createState() => _EditItemDialogState();
}

class _EditItemDialogState extends State<_EditItemDialog> {
  late final TextEditingController _quantityController;

  @override
  void initState() {
    super.initState();
    _quantityController = TextEditingController(text: widget.item.quantity.toString());
  }

  @override
  void dispose() {
    _quantityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit Quantity'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.item.materialDescription,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          Text('Code: ${widget.item.materialCode}'),
          const SizedBox(height: 16),
          TextFormField(
            controller: _quantityController,
            decoration: InputDecoration(
              labelText: 'Quantity (${widget.item.unit})',
              border: const OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('CANCEL'),
        ),
        FilledButton(
          onPressed: () {
            final quantity = double.tryParse(_quantityController.text) ?? 0;
            widget.onUpdate(quantity, 0);
            Navigator.pop(context);
          },
          child: const Text('UPDATE'),
        ),
      ],
    );
  }
} 