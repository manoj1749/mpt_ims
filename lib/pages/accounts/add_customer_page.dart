import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/customer.dart';
import '../../provider/customer_provider.dart';

class AddCustomerPage extends ConsumerStatefulWidget {
  final Customer? customerToEdit;
  final int? index;

  const AddCustomerPage({
    super.key,
    this.customerToEdit,
    this.index,
  });

  @override
  ConsumerState<AddCustomerPage> createState() => _AddCustomerPageState();
}

class _AddCustomerPageState extends ConsumerState<AddCustomerPage> {
  final _formKey = GlobalKey<FormState>();
  late String name,
      contact,
      phone,
      email,
      customerCode,
      address1,
      address2,
      address3,
      address4,
      state,
      stateCode,
      paymentTerms,
      pan,
      gstNo,
      igst,
      cgst,
      sgst,
      totalGst,
      bank,
      branch,
      account,
      ifsc,
      email1;

  @override
  void initState() {
    super.initState();
    final c = widget.customerToEdit;
    name = c?.name ?? '';
    contact = c?.contact ?? '';
    phone = c?.phone ?? '';
    email = c?.email ?? '';
    // Auto-generate customer code for new customers
    customerCode = c?.customerCode ??
        (widget.customerToEdit == null
            ? ref.read(customerListProvider.notifier).generateNextCustomerCode()
            : '');
    address1 = c?.address1 ?? '';
    address2 = c?.address2 ?? '';
    address3 = c?.address3 ?? '';
    address4 = c?.address4 ?? '';
    state = c?.state ?? '';
    stateCode = c?.stateCode ?? '';
    paymentTerms = c?.paymentTerms ?? '';
    pan = c?.pan ?? '';
    gstNo = c?.gstNo ?? '';
    igst = c?.igst ?? '';
    cgst = c?.cgst ?? '';
    sgst = c?.sgst ?? '';
    totalGst = c?.totalGst ?? '';
    bank = c?.bank ?? '';
    branch = c?.branch ?? '';
    account = c?.account ?? '';
    ifsc = c?.ifsc ?? '';
    email1 = c?.email1 ?? '';
  }

  Future<void> _saveCustomer() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      final customer = Customer(
        name: name,
        contact: contact,
        phone: phone,
        email: email,
        customerCode: customerCode,
        address1: address1,
        address2: address2,
        address3: address3,
        address4: address4,
        state: state,
        stateCode: stateCode,
        paymentTerms: paymentTerms,
        pan: pan,
        gstNo: gstNo,
        igst: igst,
        cgst: cgst,
        sgst: sgst,
        totalGst: totalGst,
        bank: bank,
        branch: branch,
        account: account,
        ifsc: ifsc,
        email1: email1,
      );

      try {
        final notifier = ref.read(customerListProvider.notifier);
        if (widget.customerToEdit != null) {
          await notifier.update(customer);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Customer updated successfully')),
            );
          }
        } else {
          await notifier.add(customer);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Customer added successfully')),
            );
          }
        }
        if (mounted) {
          Navigator.pop(context);
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
            widget.customerToEdit == null ? 'Add Customer' : 'Edit Customer'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              children: [
                _buildTextField('Customer Name', (v) => name = v,
                    initial: name, required: true),
                _buildTextField('Contact Person', (v) => contact = v,
                    initial: contact),
                _buildTextField('Phone', (v) => phone = v,
                    initial: phone, keyboardType: TextInputType.phone),
                _buildTextField('Email', (v) => email = v,
                    initial: email, keyboardType: TextInputType.emailAddress),
                _buildTextField('Customer Code', (v) => customerCode = v,
                    initial: customerCode,
                    required: true,
                    enabled: widget.customerToEdit == null),
                _buildTextField('Address Line 1', (v) => address1 = v,
                    initial: address1),
                _buildTextField('Address Line 2', (v) => address2 = v,
                    initial: address2),
                _buildTextField('Address Line 3', (v) => address3 = v,
                    initial: address3),
                _buildTextField('Address Line 4', (v) => address4 = v,
                    initial: address4),
                _buildTextField('State', (v) => state = v, initial: state),
                _buildTextField('State Code', (v) => stateCode = v,
                    initial: stateCode),
                _buildTextField('Payment Terms', (v) => paymentTerms = v,
                    initial: paymentTerms),
                _buildTextField('PAN No', (v) => pan = v, initial: pan),
                _buildTextField('GST No', (v) => gstNo = v, initial: gstNo),
                _buildTextField('IGST %', (v) => igst = v, initial: igst),
                _buildTextField('CGST %', (v) => cgst = v, initial: cgst),
                _buildTextField('SGST %', (v) => sgst = v, initial: sgst),
                _buildTextField('Total GST %', (v) => totalGst = v,
                    initial: totalGst),
                _buildTextField('Bank Name', (v) => bank = v, initial: bank),
                _buildTextField('Branch', (v) => branch = v, initial: branch),
                _buildTextField('Account No', (v) => account = v,
                    initial: account),
                _buildTextField('IFSC Code', (v) => ifsc = v, initial: ifsc),
                _buildTextField('Alternate Email', (v) => email1 = v,
                    initial: email1),
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: _saveCustomer,
                  child: Text(widget.customerToEdit == null
                      ? 'Add Customer'
                      : 'Update Customer'),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
    String label,
    Function(String) onSaved, {
    TextInputType keyboardType = TextInputType.text,
    String? initial,
    bool required = false,
    bool enabled = true,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        initialValue: initial,
        enabled: enabled,
        decoration: InputDecoration(
          labelText: required ? '$label *' : label,
          border: const OutlineInputBorder(),
          filled: !enabled,
          fillColor: !enabled ? Colors.grey[600] : null,
        ),
        style: TextStyle(
          color: !enabled ? Colors.grey[400] : null,
        ),
        keyboardType: keyboardType,
        validator: (value) {
          if (required && (value == null || value.isEmpty)) {
            return 'Required';
          }

          final customers = ref.read(customerListProvider);
          final currentCustomer = widget.customerToEdit;

          // Validation for various fields to prevent duplicates
          if (enabled && value != null && value.isNotEmpty) {
            // Customer Code validation
            if (label.contains('Customer Code')) {
              final existingCustomer = customers.any((c) =>
                  c.customerCode.toLowerCase() == value.toLowerCase() &&
                  c.customerCode != (currentCustomer?.customerCode ?? ''));
              if (existingCustomer) {
                return 'Customer code already exists';
              }
            }

            // Customer Name validation
            if (label.contains('Customer Name')) {
              final existingCustomer = customers.any((c) =>
                  c.name.toLowerCase() == value.toLowerCase() &&
                  c.name != (currentCustomer?.name ?? ''));
              if (existingCustomer) {
                return 'Customer name already exists';
              }
            }

            // PAN validation
            if (label.contains('PAN')) {
              final existingCustomer = customers.any((c) =>
                  c.pan.toLowerCase() == value.toLowerCase() &&
                  c.pan != (currentCustomer?.pan ?? ''));
              if (existingCustomer) {
                return 'PAN number already exists';
              }
            }

            // GST validation
            if (label.contains('GST No')) {
              final existingCustomer = customers.any((c) =>
                  c.gstNo.toLowerCase() == value.toLowerCase() &&
                  c.gstNo != (currentCustomer?.gstNo ?? ''));
              if (existingCustomer) {
                return 'GST number already exists';
              }
            }
          }

          return null;
        },
        onSaved: (value) => onSaved(value ?? ''),
      ),
    );
  }
}
