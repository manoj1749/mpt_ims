import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../models/store_inward.dart';
import '../../provider/store_inward_provider.dart';

class AddStoreInwardPage extends ConsumerStatefulWidget {
  const AddStoreInwardPage({super.key});

  @override
  ConsumerState<AddStoreInwardPage> createState() => _AddStoreInwardPageState();
}

class _AddStoreInwardPageState extends ConsumerState<AddStoreInwardPage> {
  final _formKey = GlobalKey<FormState>();
  final _grnNoController = TextEditingController();
  final _grnDateController = TextEditingController();
  final _supplierNameController = TextEditingController();
  final _poNoController = TextEditingController();
  final _poDateController = TextEditingController();
  final _invoiceNoController = TextEditingController();
  final _invoiceDateController = TextEditingController();
  final _invoiceAmountController = TextEditingController();
  final _receivedByController = TextEditingController();
  final _checkedByController = TextEditingController();

  @override
  void dispose() {
    _grnNoController.dispose();
    _grnDateController.dispose();
    _supplierNameController.dispose();
    _poNoController.dispose();
    _poDateController.dispose();
    _invoiceNoController.dispose();
    _invoiceDateController.dispose();
    _invoiceAmountController.dispose();
    _receivedByController.dispose();
    _checkedByController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final inwardNotifier = ref.read(storeInwardProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('Add Store Inward')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              buildTextField(_grnNoController, 'GRN No'),
              buildTextField(_grnDateController, 'GRN Date', isDate: true),
              buildTextField(_supplierNameController, 'Supplier Name'),
              buildTextField(_poNoController, 'PO No'),
              buildTextField(_poDateController, 'PO Date', isDate: true),
              buildTextField(_invoiceNoController, 'Invoice No'),
              buildTextField(_invoiceDateController, 'Invoice Date',
                  isDate: true),
              buildTextField(_invoiceAmountController, 'Invoice Amount'),
              buildTextField(_receivedByController, 'Received By'),
              buildTextField(_checkedByController, 'Checked By'),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    inwardNotifier.addInward(
                      StoreInward(
                        grnNo: _grnNoController.text,
                        grnDate: _grnDateController.text,
                        supplierName: _supplierNameController.text,
                        poNo: _poNoController.text,
                        poDate: _poDateController.text,
                        invoiceNo: _invoiceNoController.text,
                        invoiceDate: _invoiceDateController.text,
                        invoiceAmount: _invoiceAmountController.text,
                        receivedBy: _receivedByController.text,
                        checkedBy: _checkedByController.text,
                        items: [],
                      ),
                    );
                    Navigator.pop(context);
                  }
                },
                child: const Text('Save Store Inward'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildTextField(TextEditingController controller, String label,
      {bool isDate = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextFormField(
        controller: controller,
        readOnly: isDate,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        onTap: isDate
            ? () async {
                DateTime? picked = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now(),
                  firstDate: DateTime(2000),
                  lastDate: DateTime(2100),
                );
                if (picked != null) {
                  controller.text = DateFormat('yyyy-MM-dd').format(picked);
                }
              }
            : null,
        validator: (value) =>
            value == null || value.isEmpty ? 'Enter $label' : null,
      ),
    );
  }
}
