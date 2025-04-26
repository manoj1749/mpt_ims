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
    customerCode = c?.customerCode ?? '';
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

  void _saveCustomer() {
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

      final notifier = ref.read(customerListProvider.notifier);
      if (widget.index != null) {
        notifier.updateCustomer(widget.index!, customer);
      } else {
        notifier.addCustomer(customer);
      }
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.customerToEdit == null ? 'Add Customer' : 'Edit Customer'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              children: [
                _buildTextField('Customer Name', (v) => name = v, initial: name),
                _buildTextField('Contact Person', (v) => contact = v, initial: contact),
                _buildTextField('Phone', (v) => phone = v, initial: phone, keyboardType: TextInputType.phone),
                _buildTextField('Email', (v) => email = v, initial: email, keyboardType: TextInputType.emailAddress),
                _buildTextField('Customer Code', (v) => customerCode = v, initial: customerCode),
                _buildTextField('Address Line 1', (v) => address1 = v, initial: address1),
                _buildTextField('Address Line 2', (v) => address2 = v, initial: address2),
                _buildTextField('Address Line 3', (v) => address3 = v, initial: address3),
                _buildTextField('Address Line 4', (v) => address4 = v, initial: address4),
                _buildTextField('State', (v) => state = v, initial: state),
                _buildTextField('State Code', (v) => stateCode = v, initial: stateCode),
                _buildTextField('Payment Terms', (v) => paymentTerms = v, initial: paymentTerms),
                _buildTextField('PAN No', (v) => pan = v, initial: pan),
                _buildTextField('GST No', (v) => gstNo = v, initial: gstNo),
                _buildTextField('IGST %', (v) => igst = v, initial: igst),
                _buildTextField('CGST %', (v) => cgst = v, initial: cgst),
                _buildTextField('SGST %', (v) => sgst = v, initial: sgst),
                _buildTextField('Total GST %', (v) => totalGst = v, initial: totalGst),
                _buildTextField('Bank Name', (v) => bank = v, initial: bank),
                _buildTextField('Branch', (v) => branch = v, initial: branch),
                _buildTextField('Account No', (v) => account = v, initial: account),
                _buildTextField('IFSC Code', (v) => ifsc = v, initial: ifsc),
                _buildTextField('Alternate Email', (v) => email1 = v, initial: email1),
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: _saveCustomer,
                  child: Text(widget.customerToEdit == null ? 'Add Customer' : 'Update Customer'),
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
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        initialValue: initial,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        keyboardType: keyboardType,
        validator: (value) => (value == null || value.isEmpty) ? 'Required' : null,
        onSaved: (value) => onSaved(value ?? ''),
      ),
    );
  }
} 