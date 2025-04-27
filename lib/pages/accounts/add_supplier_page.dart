import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mpt_ims/models/supplier.dart';
import 'package:mpt_ims/provider/supplier_provider.dart';

class AddSupplierPage extends ConsumerStatefulWidget {
  final Supplier? supplierToEdit;

  const AddSupplierPage({super.key, this.supplierToEdit});

  @override
  ConsumerState<AddSupplierPage> createState() => _AddSupplierPageState();
}

class _AddSupplierPageState extends ConsumerState<AddSupplierPage> {
  final _formKey = GlobalKey<FormState>();

  late String name,
      contact,
      phone,
      email,
      vendorCode,
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
    final s = widget.supplierToEdit;
    name = s?.name ?? '';
    contact = s?.contact ?? '';
    phone = s?.phone ?? '';
    email = s?.email ?? '';
    vendorCode = s?.vendorCode ?? '';
    address1 = s?.address1 ?? '';
    address2 = s?.address2 ?? '';
    address3 = s?.address3 ?? '';
    address4 = s?.address4 ?? '';
    state = s?.state ?? '';
    stateCode = s?.stateCode ?? '';
    paymentTerms = s?.paymentTerms ?? '';
    pan = s?.pan ?? '';
    gstNo = s?.gstNo ?? '';
    igst = s?.igst ?? '';
    cgst = s?.cgst ?? '';
    sgst = s?.sgst ?? '';
    totalGst = s?.totalGst ?? '';
    bank = s?.bank ?? '';
    branch = s?.branch ?? '';
    account = s?.account ?? '';
    ifsc = s?.ifsc ?? '';
    email1 = s?.email1 ?? '';
  }

  void _saveSupplier() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      final updated = Supplier(
        name: name,
        contact: contact,
        phone: phone,
        email: email,
        vendorCode: vendorCode,
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

      final notifier = ref.read(supplierListProvider.notifier);
      if (widget.supplierToEdit == null) {
        notifier.addSupplier(updated);
      } else {
        notifier.updateSupplier(widget.supplierToEdit!.key, updated);
      }
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: Text(widget.supplierToEdit == null
              ? 'Add Supplier'
              : 'Edit Supplier')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              children: [
                _buildTextField('Supplier Name', (v) => name = v,
                    initial: name),
                _buildTextField('Contact Person', (v) => contact = v,
                    initial: contact),
                _buildTextField('Phone', (v) => phone = v,
                    initial: phone, keyboardType: TextInputType.phone),
                _buildTextField('Email', (v) => email = v,
                    initial: email, keyboardType: TextInputType.emailAddress),
                _buildTextField('Vendor Code', (v) => vendorCode = v,
                    initial: vendorCode),
                _buildTextField('Address 1', (v) => address1 = v,
                    initial: address1),
                _buildTextField('Address 2', (v) => address2 = v,
                    initial: address2),
                _buildTextField('Address 3', (v) => address3 = v,
                    initial: address3),
                _buildTextField('Address 4', (v) => address4 = v,
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
                ElevatedButton(
                  onPressed: _saveSupplier,
                  child: Text(widget.supplierToEdit == null
                      ? 'Save Supplier'
                      : 'Update Supplier'),
                ),
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
        validator: (value) =>
            (value == null || value.isEmpty) ? 'Required' : null,
        onSaved: (value) => onSaved(value ?? ''),
      ),
    );
  }
}
