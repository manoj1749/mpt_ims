// ignore_for_file: deprecated_member_use
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:collection/collection.dart';
import '../../models/sale_order.dart';
import '../../models/customer.dart';
import '../../provider/sale_order_provider.dart';
import '../../provider/customer_provider.dart';

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
  final _customerNameController = TextEditingController();
  final _customerCodeController = TextEditingController();
  final _customerNameFocusNode = FocusNode();
  final _customerCodeFocusNode = FocusNode();
  final _jobNoController = TextEditingController();
  final _customerPoNoController = TextEditingController();
  final _customerPoDateController = TextEditingController();
  final _planningStartDateController = TextEditingController();
  final _planningEndDateController = TextEditingController();
  final _actualStartDateController = TextEditingController();
  final _customerRequirementDateController = TextEditingController();
  final _customerCommitmentDateController = TextEditingController();
  final _actualCustomerDeliveryDateController = TextEditingController();
  final _jobNotesController = TextEditingController();
  String _jobStatus = 'Not Started';
  bool _isCustomerFreeIssueAvailable = false;
  List<Customer> _filteredCustomers = [];
  bool _showCustomerSuggestions = false;
  late String _orderNo;

  @override
  void initState() {
    super.initState();

    // Add listener to end date controller to rebuild UI when text changes
    _endDateController.addListener(() {
      setState(() {});
    });

    if (widget.order != null) {
      // Edit mode - populate fields
      _orderNo = widget.order!.orderNo;
      _orderDateController.text = widget.order!.orderDate;
      _jobStartDateController.text = widget.order!.jobStartDate;
      _targetDateController.text = widget.order!.targetDate;
      _endDateController.text = widget.order!.endDate ?? '';
      _boardNoController.text = widget.order!.boardNo;
      _customerNameController.text = widget.order!.customerName;
      _jobNoController.text = widget.order!.jobNo;
      _isCustomerFreeIssueAvailable =
          widget.order!.isCustomerFreeIssueAvailable ?? false;
      _customerPoNoController.text = widget.order!.customerPoNo ?? '';
      _customerPoDateController.text = widget.order!.customerPoDate ?? '';
      _planningStartDateController.text = widget.order!.planningStartDate ?? '';
      _planningEndDateController.text = widget.order!.planningEndDate ?? '';
      _actualStartDateController.text = widget.order!.actualStartDate ?? '';
      _customerRequirementDateController.text =
          widget.order!.customerRequirementDate ?? '';
      _customerCommitmentDateController.text =
          widget.order!.customerCommitmentDate ?? '';
      _actualCustomerDeliveryDateController.text =
          widget.order!.actualCustomerDeliveryDate ?? '';
      _jobStatus = widget.order!.jobStatus ?? 'Not Started';
      _jobNotesController.text = widget.order!.jobNotes ?? '';

      // Find customer code from customer list
      final customers = ref.read(customerListProvider);
      final customer = customers.firstWhereOrNull(
        (c) => c.name == widget.order!.customerName,
      );
      _customerCodeController.text = customer?.customerCode ?? '';
    } else {
      // Add mode - set defaults
      _orderNo = ref.read(saleOrderProvider.notifier).generateOrderNumber();
      final jobNo = ref.read(saleOrderProvider.notifier).generateJobNumber();
      final now = DateFormat('yyyy-MM-dd').format(DateTime.now());
      _orderDateController.text = now;
      _jobStartDateController.text = now;
      _targetDateController.text = '';
      _jobNoController.text = jobNo;
    }
  }

  @override
  void dispose() {
    _orderDateController.dispose();
    _jobStartDateController.dispose();
    _targetDateController.dispose();
    _endDateController.dispose();
    _boardNoController.dispose();
    _customerNameController.dispose();
    _customerCodeController.dispose();
    _jobNoController.dispose();
    _customerPoNoController.dispose();
    _customerPoDateController.dispose();
    _planningStartDateController.dispose();
    _planningEndDateController.dispose();
    _actualStartDateController.dispose();
    _customerRequirementDateController.dispose();
    _customerCommitmentDateController.dispose();
    _actualCustomerDeliveryDateController.dispose();
    _jobNotesController.dispose();
    _customerNameFocusNode.dispose();
    _customerCodeFocusNode.dispose();
    super.dispose();
  }

  double _getProgressValue(String status) {
    switch (status) {
      case 'Not Started':
        return 0.0;
      case 'In Progress':
        return 0.5;
      case 'Completed':
        return 1.0;
      case 'On Hold':
        return 0.25;
      default:
        return 0.0;
    }
  }

  void _onCustomerNameChanged(String value) {
    final customers = ref.read(customerListProvider);
    setState(() {
      if (value.isEmpty) {
        _filteredCustomers = [];
        _showCustomerSuggestions = false;
      } else {
        _filteredCustomers = customers
            .where((c) => c.name.toLowerCase().contains(value.toLowerCase()))
            .take(5)
            .toList();
        _showCustomerSuggestions = _filteredCustomers.isNotEmpty;
      }
    });

    // Auto-fill if exact match
    final exactMatch = customers
        .where((c) => c.name.toLowerCase() == value.toLowerCase())
        .firstOrNull;

    if (exactMatch != null) {
      _customerCodeController.text = exactMatch.customerCode;
    }
  }

  void _onCustomerCodeChanged(String value) {
    final customers = ref.read(customerListProvider);
    setState(() {
      if (value.isEmpty) {
        _filteredCustomers = [];
        _showCustomerSuggestions = false;
      } else {
        _filteredCustomers = customers
            .where((c) =>
                c.customerCode.toLowerCase().contains(value.toLowerCase()))
            .take(5)
            .toList();
        _showCustomerSuggestions = _filteredCustomers.isNotEmpty;
      }
    });

    // Auto-fill if exact match
    final exactMatch = customers
        .where((c) => c.customerCode.toLowerCase() == value.toLowerCase())
        .firstOrNull;

    if (exactMatch != null) {
      _customerNameController.text = exactMatch.name;
    }
  }

  void _selectCustomer(Customer customer) {
    setState(() {
      _customerNameController.text = customer.name;
      _customerCodeController.text = customer.customerCode;
      _showCustomerSuggestions = false;
      _filteredCustomers = [];
    });
    _customerNameFocusNode.unfocus();
    _customerCodeFocusNode.unfocus();
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

  String _calculateDifferenceDays(String date1, String date2) {
    if (date1.isEmpty || date2.isEmpty) return '';

    final d1 = DateTime.tryParse(date1);
    final d2 = DateTime.tryParse(date2);

    if (d1 == null || d2 == null) return '';

    final difference = d2.difference(d1).inDays;
    return difference.toString();
  }

  void _saveOrder() {
    if (_formKey.currentState!.validate()) {
      final order = SaleOrder(
        orderNo: _orderNo,
        orderDate: _orderDateController.text,
        customerName: _customerNameController.text,
        boardNo: _boardNoController.text,
        jobStartDate: _jobStartDateController.text,
        targetDate: _targetDateController.text,
        endDate:
            _endDateController.text.isEmpty ? null : _endDateController.text,
        jobNo: _jobNoController.text,
        planningStartDate: _planningStartDateController.text.isEmpty
            ? null
            : _planningStartDateController.text,
        planningEndDate: _planningEndDateController.text.isEmpty
            ? null
            : _planningEndDateController.text,
        actualStartDate: _actualStartDateController.text.isEmpty
            ? null
            : _actualStartDateController.text,
        customerRequirementDate: _customerRequirementDateController.text.isEmpty
            ? null
            : _customerRequirementDateController.text,
        customerCommitmentDate: _customerCommitmentDateController.text.isEmpty
            ? null
            : _customerCommitmentDateController.text,
        actualCustomerDeliveryDate:
            _actualCustomerDeliveryDateController.text.isEmpty
                ? null
                : _actualCustomerDeliveryDateController.text,
        jobStatus: _jobStatus,
        jobNotes:
            _jobNotesController.text.isEmpty ? null : _jobNotesController.text,
        isCustomerFreeIssueAvailable: _isCustomerFreeIssueAvailable,
        customerPoNo: _isCustomerFreeIssueAvailable
            ? (_customerPoNoController.text.isEmpty
                ? null
                : _customerPoNoController.text)
            : null,
        customerPoDate: _isCustomerFreeIssueAvailable
            ? (_customerPoDateController.text.isEmpty
                ? null
                : _customerPoDateController.text)
            : null,
      );

      if (widget.order != null) {
        ref.read(saleOrderProvider.notifier).updateOrder(order);
      } else {
        ref.read(saleOrderProvider.notifier).addOrder(order);
      }

      // Manually trigger a sync
      ref.read(saleOrderProvider.notifier).refresh();

      Navigator.pop(context, true); // Return true to indicate success
    }
  }

  @override
  Widget build(BuildContext context) {
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
              // Order Details ExpansionTile
              Card(
                child: ExpansionTile(
                  initiallyExpanded: true,
                  tilePadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  leading: const Icon(Icons.receipt_long),
                  title: const Text(
                    'Order Details',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Order Number and Order Date in one row
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  initialValue: _orderNo,
                                  decoration: const InputDecoration(
                                    labelText: 'Order No',
                                    border: OutlineInputBorder(),
                                  ),
                                  enabled: false,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: TextFormField(
                                  controller: _orderDateController,
                                  decoration: const InputDecoration(
                                    labelText: 'Order Date',
                                    border: OutlineInputBorder(),
                                  ),
                                  readOnly: true,
                                  onTap: () => _selectDate(
                                      context, _orderDateController),
                                  validator: (value) => value?.isEmpty == true
                                      ? 'Required'
                                      : null,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // Customer Name and Customer Code in one row
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    TextFormField(
                                      controller: _customerNameController,
                                      focusNode: _customerNameFocusNode,
                                      decoration: const InputDecoration(
                                        labelText: 'Customer Name',
                                        border: OutlineInputBorder(),
                                        hintText: 'Enter customer name',
                                        suffixIcon: Icon(Icons.search),
                                      ),
                                      onChanged: _onCustomerNameChanged,
                                      onTap: () {
                                        if (_customerNameController
                                            .text.isNotEmpty) {
                                          _onCustomerNameChanged(
                                              _customerNameController.text);
                                        }
                                      },
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'Required';
                                        }
                                        return null;
                                      },
                                    ),
                                    if (_showCustomerSuggestions &&
                                        _customerNameFocusNode.hasFocus)
                                      Container(
                                        constraints: const BoxConstraints(
                                            maxHeight: 200),
                                        decoration: BoxDecoration(
                                          border: Border.all(
                                              color: Colors.grey.shade700),
                                          borderRadius:
                                              BorderRadius.circular(4),
                                          color: Colors.black,
                                        ),
                                        child: ListView.builder(
                                          shrinkWrap: true,
                                          itemCount: _filteredCustomers.length,
                                          itemBuilder: (context, index) {
                                            final customer =
                                                _filteredCustomers[index];
                                            return ListTile(
                                              dense: true,
                                              title: Text(
                                                customer.name,
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.white,
                                                ),
                                              ),
                                              subtitle: Text(
                                                'Code: ${customer.customerCode}',
                                                style: TextStyle(
                                                    color:
                                                        Colors.grey.shade300),
                                              ),
                                              onTap: () =>
                                                  _selectCustomer(customer),
                                            );
                                          },
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    TextFormField(
                                      controller: _customerCodeController,
                                      focusNode: _customerCodeFocusNode,
                                      decoration: const InputDecoration(
                                        labelText: 'Customer Code',
                                        border: OutlineInputBorder(),
                                        hintText: 'Enter customer code',
                                        suffixIcon: Icon(Icons.search),
                                      ),
                                      onChanged: _onCustomerCodeChanged,
                                      onTap: () {
                                        if (_customerCodeController
                                            .text.isNotEmpty) {
                                          _onCustomerCodeChanged(
                                              _customerCodeController.text);
                                        }
                                      },
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'Required';
                                        }
                                        return null;
                                      },
                                    ),
                                    if (_showCustomerSuggestions &&
                                        _customerCodeFocusNode.hasFocus)
                                      Container(
                                        constraints: const BoxConstraints(
                                            maxHeight: 200),
                                        decoration: BoxDecoration(
                                          border: Border.all(
                                              color: Colors.grey.shade700),
                                          borderRadius:
                                              BorderRadius.circular(4),
                                          color: Colors.black,
                                        ),
                                        child: ListView.builder(
                                          shrinkWrap: true,
                                          itemCount: _filteredCustomers.length,
                                          itemBuilder: (context, index) {
                                            final customer =
                                                _filteredCustomers[index];
                                            return ListTile(
                                              dense: true,
                                              title: Text(
                                                customer.customerCode,
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.white,
                                                ),
                                              ),
                                              subtitle: Text(
                                                customer.name,
                                                style: TextStyle(
                                                    color:
                                                        Colors.grey.shade300),
                                              ),
                                              onTap: () =>
                                                  _selectCustomer(customer),
                                            );
                                          },
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // Job No field
                          TextFormField(
                            controller: _jobNoController,
                            decoration: const InputDecoration(
                              labelText: 'Job No',
                              border: OutlineInputBorder(),
                              hintText: 'Enter job number',
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter a job number';
                              }

                              // Check for duplicate job numbers (only when creating new order)
                              if (widget.order == null) {
                                final existingOrders =
                                    ref.read(saleOrderProvider);
                                final duplicateExists = existingOrders.any(
                                    (order) =>
                                        order.jobNo.toLowerCase() ==
                                        value.toLowerCase());
                                if (duplicateExists) {
                                  return 'Job number already exists';
                                }
                              }

                              return null;
                            },
                          ),

                          const SizedBox(height: 16),

                          SwitchListTile(
                            title: const Text(
                                'Is Customer Free Issue Available?'),
                            value: _isCustomerFreeIssueAvailable,
                            contentPadding: EdgeInsets.zero,
                            onChanged: (v) {
                              setState(() {
                                _isCustomerFreeIssueAvailable = v;
                                if (!v) {
                                  _customerPoNoController.clear();
                                  _customerPoDateController.clear();
                                }
                              });
                            },
                          ),

                          if (_isCustomerFreeIssueAvailable) ...[
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    controller: _customerPoNoController,
                                    decoration: const InputDecoration(
                                      labelText: 'Customer PO No',
                                      border: OutlineInputBorder(),
                                    ),
                                    validator: (v) {
                                      if (!_isCustomerFreeIssueAvailable) {
                                        return null;
                                      }
                                      if (v == null || v.trim().isEmpty) {
                                        return 'Required';
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: TextFormField(
                                    controller: _customerPoDateController,
                                    decoration: const InputDecoration(
                                      labelText: 'Customer PO Date',
                                      border: OutlineInputBorder(),
                                    ),
                                    readOnly: true,
                                    onTap: () => _selectDate(
                                        context, _customerPoDateController),
                                    validator: (v) {
                                      if (!_isCustomerFreeIssueAvailable) {
                                        return null;
                                      }
                                      if (v == null || v.trim().isEmpty) {
                                        return 'Required';
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Job Schedule ExpansionTile
              Card(
                child: ExpansionTile(
                  initiallyExpanded: true,
                  tilePadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  leading: const Icon(Icons.schedule),
                  title: const Text(
                    'Job Schedule',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Row 1: Sales Target Start Date, Planning Target Start Date, Actual Start Date, Difference Days
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: _jobStartDateController,
                                  decoration: const InputDecoration(
                                    labelText: 'Sales Target Start Date',
                                    border: OutlineInputBorder(),
                                  ),
                                  readOnly: true,
                                  onTap: () => _selectDate(
                                      context, _jobStartDateController),
                                  validator: (value) {
                                    if (value?.isEmpty == true)
                                      return 'Required';
                                    return null;
                                  },
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: TextFormField(
                                  controller: _planningStartDateController,
                                  decoration: InputDecoration(
                                    labelText: 'Planning Target Start Date',
                                    border: const OutlineInputBorder(),
                                    suffixIcon: _planningStartDateController.text.isNotEmpty
                                        ? IconButton(
                                            icon: const Icon(Icons.clear),
                                            onPressed: () {
                                              setState(() {
                                                _planningStartDateController.clear();
                                              });
                                            },
                                          )
                                        : null,
                                  ),
                                  readOnly: true,
                                  onTap: () => _selectDate(
                                      context, _planningStartDateController),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: TextFormField(
                                  controller: _actualStartDateController,
                                  decoration: InputDecoration(
                                    labelText: 'Actual Start Date',
                                    border: const OutlineInputBorder(),
                                    suffixIcon: _actualStartDateController.text.isNotEmpty
                                        ? IconButton(
                                            icon: const Icon(Icons.clear),
                                            onPressed: () {
                                              setState(() {
                                                _actualStartDateController.clear();
                                              });
                                            },
                                          )
                                        : null,
                                  ),
                                  readOnly: true,
                                  onTap: () => _selectDate(
                                      context, _actualStartDateController),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: TextFormField(
                                  decoration: InputDecoration(
                                    labelText: 'Difference Days',
                                    border: const OutlineInputBorder(),
                                    filled: true,
                                    fillColor: Colors.grey[800],
                                  ),
                                  readOnly: true,
                                  controller: TextEditingController(
                                    text: _calculateDifferenceDays(
                                      _jobStartDateController.text,
                                      _actualStartDateController.text,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // Row 2: Sales Target End Date, Planning Target End Date, Actual End Date
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: _targetDateController,
                                  decoration: const InputDecoration(
                                    labelText: 'Sales Target End Date',
                                    border: OutlineInputBorder(),
                                  ),
                                  readOnly: true,
                                  onTap: () => _selectDate(
                                      context, _targetDateController),
                                  validator: (value) {
                                    if (value?.isEmpty == true)
                                      return 'Required';
                                    return null;
                                  },
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: TextFormField(
                                  controller: _planningEndDateController,
                                  decoration: InputDecoration(
                                    labelText: 'Planning Target End Date',
                                    border: const OutlineInputBorder(),
                                    suffixIcon: _planningEndDateController.text.isNotEmpty
                                        ? IconButton(
                                            icon: const Icon(Icons.clear),
                                            onPressed: () {
                                              setState(() {
                                                _planningEndDateController.clear();
                                              });
                                            },
                                          )
                                        : null,
                                  ),
                                  readOnly: true,
                                  onTap: () => _selectDate(
                                      context, _planningEndDateController),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: TextFormField(
                                  controller: _endDateController,
                                  decoration: InputDecoration(
                                    labelText: 'Actual End Date',
                                    border: const OutlineInputBorder(),
                                    suffixIcon: _endDateController.text.isNotEmpty
                                        ? IconButton(
                                            icon: const Icon(Icons.clear),
                                            onPressed: () {
                                              setState(() {
                                                _endDateController.clear();
                                              });
                                            },
                                          )
                                        : null,
                                  ),
                                  readOnly: true,
                                  onTap: () =>
                                      _selectDate(context, _endDateController),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child:
                                    Container(), // Empty space to align with row 1
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // Row 3: Customer Requirement Date, Customer Commitment Date, Actual Customer Delivery Date
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller:
                                      _customerRequirementDateController,
                                  decoration: InputDecoration(
                                    labelText: 'Customer Requirement Date',
                                    border: const OutlineInputBorder(),
                                    suffixIcon: _customerRequirementDateController.text.isNotEmpty
                                        ? IconButton(
                                            icon: const Icon(Icons.clear),
                                            onPressed: () {
                                              setState(() {
                                                _customerRequirementDateController.clear();
                                              });
                                            },
                                          )
                                        : null,
                                  ),
                                  readOnly: true,
                                  onTap: () => _selectDate(context,
                                      _customerRequirementDateController),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: TextFormField(
                                  controller: _customerCommitmentDateController,
                                  decoration: InputDecoration(
                                    labelText: 'Customer Commitment Date Given',
                                    border: const OutlineInputBorder(),
                                    suffixIcon: _customerCommitmentDateController.text.isNotEmpty
                                        ? IconButton(
                                            icon: const Icon(Icons.clear),
                                            onPressed: () {
                                              setState(() {
                                                _customerCommitmentDateController.clear();
                                              });
                                            },
                                          )
                                        : null,
                                  ),
                                  readOnly: true,
                                  onTap: () => _selectDate(context,
                                      _customerCommitmentDateController),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: TextFormField(
                                  controller:
                                      _actualCustomerDeliveryDateController,
                                  decoration: InputDecoration(
                                    labelText: 'Actual Customer Delivery Date',
                                    border: const OutlineInputBorder(),
                                    suffixIcon: _actualCustomerDeliveryDateController.text.isNotEmpty
                                        ? IconButton(
                                            icon: const Icon(Icons.clear),
                                            onPressed: () {
                                              setState(() {
                                                _actualCustomerDeliveryDateController.clear();
                                              });
                                            },
                                          )
                                        : null,
                                  ),
                                  readOnly: true,
                                  onTap: () => _selectDate(context,
                                      _actualCustomerDeliveryDateController),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child:
                                    Container(), // Empty space to align with row 1
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Job Status ExpansionTile
              Card(
                child: ExpansionTile(
                  initiallyExpanded: true,
                  tilePadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  leading: const Icon(Icons.work_history),
                  title: const Text(
                    'Job Status',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Job Status Dropdown
                          DropdownButtonFormField<String>(
                            decoration: const InputDecoration(
                              labelText: 'Job Status',
                              border: OutlineInputBorder(),
                            ),
                            value: 'Not Started', // Default value
                            items: const [
                              DropdownMenuItem(
                                value: 'Not Started',
                                child: Text('Not Started'),
                              ),
                              DropdownMenuItem(
                                value: 'In Progress',
                                child: Text('In Progress'),
                              ),
                              DropdownMenuItem(
                                value: 'Completed',
                                child: Text('Completed'),
                              ),
                              DropdownMenuItem(
                                value: 'On Hold',
                                child: Text('On Hold'),
                              ),
                            ],
                            onChanged: (String? newValue) {
                              if (newValue != null) {
                                setState(() {
                                  _jobStatus = newValue;
                                });
                              }
                            },
                          ),
                          const SizedBox(height: 16),

                          const Text(
                            'Job Progress',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: Directionality(
                                  textDirection: ui.TextDirection.ltr,
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(5),
                                    child: LinearProgressIndicator(
                                      value: _getProgressValue(_jobStatus),
                                      backgroundColor: Colors.grey[300],
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        _jobStatus == 'Completed'
                                            ? Colors.green
                                            : _jobStatus == 'In Progress'
                                                ? Colors.orange
                                                : _jobStatus == 'On Hold'
                                                    ? Colors.red
                                                    : Theme.of(context)
                                                        .primaryColor,
                                      ),
                                      minHeight: 10,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                '${(_getProgressValue(_jobStatus) * 100).toInt()}%',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // Job Notes
                          TextFormField(
                            controller: _jobNotesController,
                            decoration: const InputDecoration(
                              labelText: 'Job Notes',
                              border: OutlineInputBorder(),
                              hintText: 'Enter notes about the job status',
                              alignLabelWithHint: true,
                            ),
                            maxLines: 3,
                            keyboardType: TextInputType.multiline,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),
              FilledButton(
                style: FilledButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 5, vertical: 20),
                ),
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
