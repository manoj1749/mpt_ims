import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../models/sale_order.dart';
import '../../provider/sale_order_provider.dart';
import '../../provider/customer_provider.dart';
import 'package:dropdown_button2/dropdown_button2.dart';

class AddEditSaleOrderPage extends ConsumerStatefulWidget {
  final SaleOrder? order;

  const AddEditSaleOrderPage({super.key, this.order});

  @override
  ConsumerState<AddEditSaleOrderPage> createState() =>
      _AddEditSaleOrderPageState();
}

class _AddEditSaleOrderPageState extends ConsumerState<AddEditSaleOrderPage> {
  final _formKey = GlobalKey<FormState>();
  final _orderDateController = TextEditingController();
  final _jobStartDateController = TextEditingController();
  final _targetDateController = TextEditingController();
  final _endDateController = TextEditingController();
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
      _jobStartDateController.text = widget.order!.jobStartDate;
      _targetDateController.text = widget.order!.targetDate;
      _endDateController.text = widget.order!.endDate ?? '';
      _boardNoController.text = widget.order!.boardNo;
      _selectedCustomer = widget.order!.customerName;
    } else {
      // Add mode - set defaults
      _orderNo = ref.read(saleOrderProvider.notifier).generateOrderNumber();
      final now = DateFormat('yyyy-MM-dd').format(DateTime.now());
      _orderDateController.text = now;
      _jobStartDateController.text = now;
      _targetDateController.text = '';
    }
  }

  @override
  void dispose() {
    _orderDateController.dispose();
    _jobStartDateController.dispose();
    _targetDateController.dispose();
    _endDateController.dispose();
    _boardNoController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(
      BuildContext context, TextEditingController controller,
      {DateTime? minDate, DateTime? maxDate}) async {
    final DateTime now = DateTime.now();
    final DateTime initialDate = DateTime.tryParse(controller.text) ?? now;

    // Ensure initialDate is between firstDate and lastDate
    DateTime effectiveInitialDate = initialDate;
    if (minDate != null && initialDate.isBefore(minDate)) {
      effectiveInitialDate = minDate;
    }
    if (maxDate != null && initialDate.isAfter(maxDate)) {
      effectiveInitialDate = maxDate;
    }

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: effectiveInitialDate,
      firstDate: minDate ?? DateTime(2000),
      lastDate: maxDate ?? DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        controller.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  void _saveOrder() {
    if (_formKey.currentState!.validate()) {
      final order = SaleOrder(
        orderNo: _orderNo,
        orderDate: _orderDateController.text,
        customerName: _selectedCustomer!,
        boardNo: _boardNoController.text,
        jobStartDate: _jobStartDateController.text,
        targetDate: _targetDateController.text,
        endDate:
            _endDateController.text.isEmpty ? null : _endDateController.text,
      );

      if (widget.order != null) {
        ref.read(saleOrderProvider.notifier).updateOrder(order);
      } else {
        ref.read(saleOrderProvider.notifier).addOrder(order);
      }

      Navigator.pop(context, true); // Return true to indicate success
    }
  }

  @override
  Widget build(BuildContext context) {
    final customers = ref.watch(customerListProvider);

    return WillPopScope(
      onWillPop: () async {
        Navigator.pop(context, false); // Return false to indicate no changes
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(
              widget.order == null ? 'Create Sale Order' : 'Edit Sale Order'),
          elevation: 0,
        ),
        body: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
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
                              onTap: () =>
                                  _selectDate(context, _orderDateController),
                              validator: (value) =>
                                  value?.isEmpty == true ? 'Required' : null,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: DropdownButtonFormField2<String>(
                              value: _selectedCustomer,
                              isExpanded: true,
                              decoration: const InputDecoration(
                                labelText: 'Customer',
                                border: OutlineInputBorder(),
                              ),
                              items: customers.map((customer) {
                                return DropdownMenuItem<String>(
                                  value: customer.name,
                                  child: Text(
                                    customer.name,
                                    overflow: TextOverflow.ellipsis,
                                  ),
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
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Job Schedule',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _jobStartDateController,
                        decoration: const InputDecoration(
                          labelText: 'Job Start Date',
                          border: OutlineInputBorder(),
                        ),
                        readOnly: true,
                        onTap: () =>
                            _selectDate(context, _jobStartDateController),
                        validator: (value) {
                          if (value?.isEmpty == true) return 'Required';
                          final startDate = DateTime.tryParse(value!);
                          if (startDate == null) return 'Invalid date';
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _targetDateController,
                        decoration: const InputDecoration(
                          labelText: 'Target Date',
                          border: OutlineInputBorder(),
                        ),
                        readOnly: true,
                        onTap: () {
                          final startDate =
                              DateTime.tryParse(_jobStartDateController.text);
                          if (startDate == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content:
                                    Text('Please select Job Start Date first'),
                              ),
                            );
                            return;
                          }
                          _selectDate(
                            context,
                            _targetDateController,
                            minDate: startDate,
                          );
                        },
                        validator: (value) {
                          if (value?.isEmpty == true) return 'Required';
                          final targetDate = DateTime.tryParse(value!);
                          if (targetDate == null) return 'Invalid date';

                          final startDate =
                              DateTime.tryParse(_jobStartDateController.text);
                          if (startDate != null &&
                              targetDate.isBefore(startDate)) {
                            return 'Target date must be after start date';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _endDateController,
                        decoration: const InputDecoration(
                          labelText: 'End Date (Optional)',
                          border: OutlineInputBorder(),
                          helperText: 'Leave empty if job is not completed',
                        ),
                        readOnly: true,
                        onTap: () {
                          final targetDate =
                              DateTime.tryParse(_targetDateController.text);
                          if (targetDate == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content:
                                    Text('Please select Target Date first'),
                              ),
                            );
                            return;
                          }
                          _selectDate(
                            context,
                            _endDateController,
                            minDate: targetDate,
                          );
                        },
                        validator: (value) {
                          if (value?.isEmpty == true)
                            return null; // Optional field
                          final endDate = DateTime.tryParse(value!);
                          if (endDate == null) return 'Invalid date';

                          final targetDate =
                              DateTime.tryParse(_targetDateController.text);
                          if (targetDate != null &&
                              endDate.isBefore(targetDate)) {
                            return 'End date must be after target date';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),
              FilledButton(
                onPressed: _saveOrder,
                child: Text(
                    widget.order == null ? 'Create Order' : 'Update Order'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
