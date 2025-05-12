import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../models/sale_order.dart';
import '../../provider/sale_order_provider.dart';
import '../../provider/customer_provider.dart';

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
  late String _orderNo;

  @override
  void initState() {
    super.initState();
    if (widget.order != null) {
      // Edit mode - populate fields
      _orderNo = widget.order!.orderNo;
      _orderDateController.text = widget.order!.orderDate;
      _boardNoController.text = widget.order!.boardNo;
      _selectedCustomer = widget.order!.customerName;
    } else {
      // Add mode - set defaults
      _orderNo = ref.read(saleOrderProvider.notifier).generateOrderNumber();
      _orderDateController.text = DateFormat('yyyy-MM-dd').format(DateTime.now());
    }
  }

  @override
  void dispose() {
    _orderDateController.dispose();
    _boardNoController.dispose();
    super.dispose();
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
                    TextFormField(
                      initialValue: _orderNo,
                      decoration: const InputDecoration(
                        labelText: 'Order No',
                        border: OutlineInputBorder(),
                      ),
                      enabled: false,
                    ),
                    const SizedBox(height: 16),
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
            const SizedBox(height: 32),

            // Save button
            FilledButton(
              onPressed: () {
                if (_formKey.currentState!.validate()) {
                  final order = SaleOrder(
                    orderNo: _orderNo,
                    orderDate: _orderDateController.text,
                    customerName: _selectedCustomer!,
                    boardNo: _boardNoController.text,
                  );

                  if (widget.order != null) {
                    ref.read(saleOrderProvider.notifier).updateOrder(order);
                  } else {
                    ref.read(saleOrderProvider.notifier).addOrder(order);
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