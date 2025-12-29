import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/customer.dart';
import '../../models/state.dart';
import '../../models/gst.dart';
import '../../provider/customer_provider.dart';
import '../../provider/state_provider.dart';
import '../../provider/gst_provider.dart';
import '../../provider/payment_terms_provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:open_file/open_file.dart';
import 'add_state_page.dart';
import 'payment_terms_settings_page.dart';
import 'add_gst_page.dart';

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
  final Map<GlobalKey<FormFieldState>, Timer> _fieldValidationDebounce = {};

  final Map<String, GlobalKey<FormFieldState>> _fieldKeys = {};

  final GlobalKey<FormFieldState> _stateFieldKey = GlobalKey<FormFieldState>();
  final GlobalKey<FormFieldState> _stateCodeFieldKey =
      GlobalKey<FormFieldState>();
  final GlobalKey<FormFieldState> _gstSuffixFieldKey =
      GlobalKey<FormFieldState>();

  final GlobalKey<FormFieldState> _customGstRateFieldKey =
      GlobalKey<FormFieldState>();
  final GlobalKey<FormFieldState> _customIgstRateFieldKey =
      GlobalKey<FormFieldState>();
  final _stateController = TextEditingController();
  final _stateCodeController = TextEditingController();
  final _stateFocusNode = FocusNode();
  final _stateCodeFocusNode = FocusNode();
  final _igstController = TextEditingController();
  final _cgstController = TextEditingController();
  final _sgstController = TextEditingController();
  final _totalGstController = TextEditingController();
  final _gstSuffixController = TextEditingController();
  final _gstNoController = TextEditingController();
  
  // GST rate options from GST Master
  GSTModel? _selectedGstRate;
  GSTModel? _selectedIgstRate;
  final TextEditingController _customGstRateController = TextEditingController();
  final TextEditingController _customIgstRateController = TextEditingController();
  bool _showCustomGstRate = false;
  bool _showCustomIgstRate = false;
  List<StateModel> _filteredStates = [];
  bool _showStateSuggestions = false;
  final List<String> _attachments = [];

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
    // Load payment terms and GST rates
    Future.microtask(() async {
      try {
        await ref.read(paymentTermsListProvider.notifier).loadPaymentTerms();
        await ref.read(gstListProvider.notifier).loadData();
      } catch (e) {
        // Silently handle error
      }
    });
    
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
    if (paymentTerms.trim() == '-') {
      paymentTerms = '';
    }
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
    // Initialize attachments
    _attachments.clear();
    if (c?.attachments != null) {
      _attachments.addAll(c!.attachments);
    }

    // Initialize state controllers
    _stateController.text = state;
    _stateCodeController.text = stateCode;

    // Initialize GST controllers
    _igstController.text = igst;
    _cgstController.text = cgst;
    _sgstController.text = sgst;
    _totalGstController.text = totalGst;

    // Set selected IGST rate if IGST is set
    if (igst.isNotEmpty) {
      try {
        final igstVal = double.parse(igst);
        if (igstVal > 0) {
          // Try to find matching GST rate from master
          final gstRates = ref.read(gstListProvider);
          _selectedIgstRate = gstRates.firstWhere(
            (gst) => double.tryParse(gst.igst) == igstVal && gst.cgst == '0' && gst.sgst == '0',
            orElse: () => GSTModel(
              gstCategory: '${igstVal.toStringAsFixed(1)}% IGST',
              gstRate: igstVal.toString(),
              cgst: '0',
              sgst: '0',
              igst: igstVal.toString(),
              description: 'IGST Rate - ${igstVal.toStringAsFixed(1)}%',
            ),
          );
          // Check if this is a custom rate (not found in master)
          final isCustom = !gstRates.any((gst) => double.tryParse(gst.igst) == igstVal && gst.cgst == '0' && gst.sgst == '0');
          if (isCustom) {
            _showCustomIgstRate = true;
            _customIgstRateController.text = igstVal.toStringAsFixed(2);
          }
        }
      } catch (e) {
        // Ignore parsing errors
      }
    }

    // Set selected GST rate if CGST and SGST are set
    if (cgst.isNotEmpty && sgst.isNotEmpty) {
      try {
        final cgstVal = double.parse(cgst);
        final sgstVal = double.parse(sgst);
        if (cgstVal > 0 || sgstVal > 0) {
          // Try to find matching GST rate from master
          final gstRates = ref.read(gstListProvider);
          final totalRate = cgstVal + sgstVal;
          _selectedGstRate = gstRates.firstWhere(
            (gst) => double.tryParse(gst.cgst) == cgstVal && double.tryParse(gst.sgst) == sgstVal && gst.igst == '0',
            orElse: () => GSTModel(
              gstCategory: '${totalRate.toStringAsFixed(1)}% (${cgstVal.toStringAsFixed(1)}% CGST + ${sgstVal.toStringAsFixed(1)}% SGST)',
              gstRate: totalRate.toString(),
              cgst: cgstVal.toString(),
              sgst: sgstVal.toString(),
              igst: '0',
              description: 'GST Rate - ${totalRate.toStringAsFixed(1)}% Total',
            ),
          );
          // Check if this is a custom rate (not found in master)
          final isCustom = !gstRates.any((gst) => double.tryParse(gst.cgst) == cgstVal && double.tryParse(gst.sgst) == sgstVal && gst.igst == '0');
          if (isCustom) {
            _showCustomGstRate = true;
            _customGstRateController.text = totalRate.toStringAsFixed(2);
          }
        }
      } catch (e) {
        // Ignore parsing errors
      }
    }

    // Initialize GST Number fields
    _gstNoController.text = gstNo;
    // Extract last 3 characters if GST No exists
    if (gstNo.length >= 3) {
      _gstSuffixController.text = gstNo.substring(gstNo.length - 3);
    }

    // Don't enforce tax visibility on init - let the loaded values remain
    // _enforceTaxVisibility() will be called when state changes
  }

  // Determine if current state is Tamil Nadu
  bool get _isTamilNadu => _stateController.text.trim().toLowerCase() == 'tamil nadu';

  // Enforce UI/state for GST fields based on state selection
  void _enforceTaxVisibility() {
    // Note: This method should only be called when state changes
    // It enforces which tax type should be used based on location
    if (_isTamilNadu) {
      // Within Tamil Nadu: CGST+SGST only, clear IGST
      if (_igstController.text != '0') {
        _igstController.text = '0';
        _selectedIgstRate = null;
        _showCustomIgstRate = false;
        _customIgstRateController.clear();
      }
      _calculateGST();
    } else {
      // Outside Tamil Nadu: IGST only, clear CGST/SGST
      if (_cgstController.text != '0' || _sgstController.text != '0') {
        _cgstController.text = '0';
        _sgstController.text = '0';
        _selectedGstRate = null;
        _showCustomGstRate = false;
        _customGstRateController.clear();
      }
      _calculateGST();
    }
    setState(() {});
  }

  // Update GST rates based on selected GST rate
  void _updateGstRates() {
    if (_selectedGstRate != null) {
      // First clear IGST when switching to CGST/SGST split
      _igstController.text = '0';
      _cgstController.text = _selectedGstRate!.cgst;
      _sgstController.text = _selectedGstRate!.sgst;
      _calculateGST();
    }
  }

  // Calculate total GST and handle IGST logic
  void _calculateGST() {
    double igstVal = double.tryParse(_igstController.text) ?? 0;
    double cgstVal = double.tryParse(_cgstController.text) ?? 0;
    double sgstVal = double.tryParse(_sgstController.text) ?? 0;

    // If IGST is provided, clear CGST and SGST
    if (igstVal > 0) {
      _cgstController.text = '0';
      _sgstController.text = '0';
      cgstVal = 0;
      sgstVal = 0;
      _selectedGstRate = null;
      _showCustomGstRate = false;
      _customGstRateController.clear();
    } else if (cgstVal > 0 || sgstVal > 0) {
      // If CGST/SGST is provided, set IGST to 0
      igstVal = 0;
      _igstController.text = '0';
    }

    // Calculate total GST
    double total = igstVal + cgstVal + sgstVal;
    _totalGstController.text = total.toStringAsFixed(2);

    // Update the string values
    igst = _igstController.text;
    cgst = _cgstController.text;
    sgst = _sgstController.text;
    totalGst = _totalGstController.text;
  }

  // Update GST Number from State Code + PAN + Suffix
  void _updateGstNumber() {
    final stateCodeVal = _stateCodeController.text.trim();
    final panVal = pan.trim();
    final suffixVal = _gstSuffixController.text.trim();

    if (stateCodeVal.isNotEmpty && panVal.isNotEmpty && suffixVal.isNotEmpty) {
      final fullGst = '$stateCodeVal$panVal$suffixVal';
      _gstNoController.text = fullGst;
      gstNo = fullGst;
    } else if (stateCodeVal.isNotEmpty && panVal.isNotEmpty) {
      final partialGst = '$stateCodeVal$panVal';
      _gstNoController.text = partialGst;
      gstNo = partialGst;
    } else {
      _gstNoController.text = '';
      gstNo = '';
    }
  }

  void _onStateChanged(String value) {
    final states = ref.read(stateListProvider);
    setState(() {
      if (value.isEmpty) {
        _filteredStates = [];
        _showStateSuggestions = false;
      } else {
        _filteredStates = states
            .where((s) => s.name.toLowerCase().contains(value.toLowerCase()))
            .take(5)
            .toList();
        _showStateSuggestions = true;
      }
    });

    final exactMatch = states
        .where((s) => s.name.toLowerCase() == value.toLowerCase())
        .firstOrNull;

    if (exactMatch != null) {
      _stateCodeController.text = exactMatch.stateCode;
      state = exactMatch.name;
      stateCode = exactMatch.stateCode;
      _updateGstNumber();
      _enforceTaxVisibility();
    }
  }

  void _onStateCodeChanged(String value) {
    final states = ref.read(stateListProvider);
    setState(() {
      if (value.isEmpty) {
        _filteredStates = [];
        _showStateSuggestions = false;
      } else {
        _filteredStates = states
            .where((s) => s.stateCode.toLowerCase().contains(value.toLowerCase()))
            .take(5)
            .toList();
        _showStateSuggestions = true;
      }
    });

    final exactMatch = states
        .where((s) => s.stateCode.toLowerCase() == value.toLowerCase())
        .firstOrNull;

    if (exactMatch != null) {
      _stateController.text = exactMatch.name;
      state = exactMatch.name;
      stateCode = exactMatch.stateCode;
      _updateGstNumber();
      _enforceTaxVisibility();
    }
  }

  void _selectState(StateModel stateModel) {
    setState(() {
      _stateController.text = stateModel.name;
      _stateCodeController.text = stateModel.stateCode;
      _showStateSuggestions = false;
      _filteredStates = [];
      state = stateModel.name;
      stateCode = stateModel.stateCode;
    });
    _stateFocusNode.unfocus();
    _stateCodeFocusNode.unfocus();
    _updateGstNumber();
    _enforceTaxVisibility();
  }

  void _addNewState() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AddStatePage()),
    ).then((_) {
      ref.read(stateListProvider.notifier).loadData();
      setState(() {
        if (_stateController.text.isNotEmpty) {
          _onStateChanged(_stateController.text);
        } else if (_stateCodeController.text.isNotEmpty) {
          _onStateCodeChanged(_stateCodeController.text);
        }
      });
    });
  }

  void _showAttachmentViewer(BuildContext context, String filePath, String fileName) {
    final ext = fileName.split('.').last.toLowerCase();
    
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          width: MediaQuery.of(context).size.width * 0.8,
          height: MediaQuery.of(context).size.height * 0.8,
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      fileName,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Divider(),
              Expanded(
                child: ext == 'pdf'
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.picture_as_pdf, size: 64, color: Colors.red),
                            const SizedBox(height: 16),
                            Text(
                              'PDF Viewer',
                              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'File: $fileName',
                              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              onPressed: () async {
                                try {
                                  final result = await OpenFile.open(filePath);
                                  if (result.type != ResultType.done && context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('Error: ${result.message}')),
                                    );
                                  }
                                } catch (e) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('Error opening file: $e')),
                                    );
                                  }
                                }
                              },
                              icon: const Icon(Icons.open_in_new),
                              label: const Text('Open with System Viewer'),
                            ),
                          ],
                        ),
                      )
                    : Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.description, size: 64, color: Colors.blue),
                            const SizedBox(height: 16),
                            Text(
                              'Document Viewer',
                              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'File: $fileName',
                              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              onPressed: () async {
                                try {
                                  final result = await OpenFile.open(filePath);
                                  if (result.type != ResultType.done && context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('Error: ${result.message}')),
                                    );
                                  }
                                } catch (e) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('Error opening file: $e')),
                                    );
                                  }
                                }
                              },
                              icon: const Icon(Icons.open_in_new),
                              label: const Text('Open with System Viewer'),
                            ),
                          ],
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _saveCustomer() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      // Save custom GST rates to GST Master if they exist
      if (_selectedGstRate != null) {
        final isCustomCgstSgst = _selectedGstRate!.gstCategory.contains('CGST +') || 
                                 (_selectedGstRate!.gstCategory.startsWith('Custom') && !_selectedGstRate!.gstCategory.contains('IGST'));
        if (isCustomCgstSgst) {
          final gstRates = ref.read(gstListProvider);
          final exists = gstRates.any((gst) => 
            gst.cgst == _selectedGstRate!.cgst && 
            gst.sgst == _selectedGstRate!.sgst &&
            gst.igst == '0'
          );
          if (!exists) {
            try {
              await ref.read(gstListProvider.notifier).add(_selectedGstRate!);
            } catch (e) {
              // Ignore if already exists
            }
          }
        }
      }

      if (_selectedIgstRate != null) {
        final isCustomIgst = _selectedIgstRate!.gstCategory.endsWith('IGST') || _selectedIgstRate!.gstCategory == 'CustomIGST';
        if (isCustomIgst) {
          final gstRates = ref.read(gstListProvider);
          final exists = gstRates.any((gst) => 
            gst.igst == _selectedIgstRate!.igst &&
            gst.cgst == '0' &&
            gst.sgst == '0'
          );
          if (!exists) {
            try {
              await ref.read(gstListProvider.notifier).add(_selectedIgstRate!);
            } catch (e) {
              // Ignore if already exists
            }
          }
        }
      }

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
        state: _stateController.text,
        stateCode: _stateCodeController.text,
        paymentTerms: paymentTerms,
        pan: pan,
        gstNo: _gstNoController.text,
        igst: _igstController.text,
        cgst: _cgstController.text,
        sgst: _sgstController.text,
        totalGst: _totalGstController.text,
        bank: bank,
        branch: branch,
        account: account,
        ifsc: ifsc,
        email1: email1,
        attachments: _attachments,
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
                _buildStateTextField(),
                _buildStateCodeTextField(),
                _buildPaymentTermsDropdown(),
                _buildTextField('PAN No', (v) {
                  pan = v.toUpperCase();
                  _updateGstNumber();
                }, initial: pan, maxLength: 10, onChangedCallback: (v) {
                  pan = v.toUpperCase();
                  _updateGstNumber();
                }),
                _buildGstNumberField(),
                // Show CGST+SGST controls only for Tamil Nadu; else show IGST only
                if (_isTamilNadu) ...[
                  _buildGstRateDropdown(),
                ] else ...[
                  _buildIgstRateDropdown(),
                ],
                _buildGstTextField('Total GST %', _totalGstController,
                    enabled: false),
                _buildTextField('Bank Name', (v) => bank = v, initial: bank),
                _buildTextField('Branch', (v) => branch = v, initial: branch),
                _buildTextField('Account No', (v) => account = v,
                    initial: account),
                _buildTextField('IFSC Code', (v) => ifsc = v, initial: ifsc),
                _buildTextField('Alternate Email', (v) => email1 = v,
                    initial: email1),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Attachments (PDF/DOC/DOCX)',
                    style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    OutlinedButton.icon(
                      onPressed: () async {
                        final result = await FilePicker.platform.pickFiles(
                          allowMultiple: true,
                          type: FileType.custom,
                          allowedExtensions: const ['pdf', 'doc', 'docx'],
                        );
                        if (result != null) {
                          setState(() {
                            for (final f in result.files) {
                              if (f.path != null && !_attachments.contains(f.path!)) {
                                _attachments.add(f.path!);
                              }
                            }
                          });
                        }
                      },
                      icon: const Icon(Icons.attach_file),
                      label: const Text('Upload Files'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (_attachments.isNotEmpty)
                  Column(
                    children: _attachments.map((p) {
                      final name = p.split('\\').isNotEmpty ? p.split('\\').last : p.split('/').last;
                      final ext = name.split('.').length > 1 ? name.split('.').last.toLowerCase() : '';
                      final icon = ext == 'pdf' ? Icons.picture_as_pdf : Icons.description;
                      return ListTile(
                        dense: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                        leading: Icon(icon, color: Colors.grey[700]),
                        title: Text(name, overflow: TextOverflow.ellipsis),
                        trailing: IconButton(
                          icon: const Icon(Icons.close, color: Colors.red),
                          onPressed: () {
                            setState(() {
                              _attachments.remove(p);
                            });
                          },
                        ),
                        onTap: () {
                          _showAttachmentViewer(context, p, name);
                        },
                      );
                    }).toList(),
                  ),
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

  Widget _buildGstRateDropdown() {
    final gstRates = ref.watch(gstListProvider);
    
    // Build dropdown items from GST Master
    List<DropdownMenuItem<String?>> dropdownItems = [
      ...gstRates.where((gst) => double.tryParse(gst.cgst) != null && double.tryParse(gst.cgst)! > 0).map((gst) {
        return DropdownMenuItem<String?>(
          value: gst.gstCategory,
          child: Text(gst.gstCategory),
        );
      }),
    ];

    // Add custom rate to dropdown if it exists and not already in the list
    if (_selectedGstRate != null) {
      // Check if this is a custom rate (contains "CGST +" pattern or starts with "Custom" but not "Custom IGST")
      final isCustomCgstSgst = _selectedGstRate!.gstCategory.contains('CGST +') || 
                               (_selectedGstRate!.gstCategory.startsWith('Custom') && !_selectedGstRate!.gstCategory.contains('IGST'));
      if (isCustomCgstSgst) {
        // Check if this category is not already in the dropdown items
        final alreadyExists = dropdownItems.any((item) => item.value == _selectedGstRate!.gstCategory);
        if (!alreadyExists) {
          dropdownItems.add(
            DropdownMenuItem<String?>(
              value: _selectedGstRate!.gstCategory,
              child: Text(_selectedGstRate!.gstCategory),
            ),
          );
        }
      }
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'GST Rate %',
                    border: OutlineInputBorder(),
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String?>(
                      value: _selectedGstRate?.gstCategory,
                      hint: const Text('Select GST Rate'),
                      isExpanded: true,
                      items: dropdownItems,
                      onChanged: (String? newValue) {
                        if (newValue == null) return;
                        setState(() {
                          final selectedGst = gstRates
                              .firstWhere((gst) => gst.gstCategory == newValue);
                          _selectedGstRate = selectedGst;
                          _updateGstRates();
                        });
                      },
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                tooltip: 'Add GST Rate',
                icon: const Icon(Icons.add_circle_outline),
                onPressed: () async {
                  final created = await Navigator.push<GSTModel>(
                    context,
                    MaterialPageRoute(builder: (_) => const AddGSTPage()),
                  );
                  if (created == null) return;
                  await ref.read(gstListProvider.notifier).loadData();
                  if (!mounted) return;
                  setState(() {
                    if ((double.tryParse(created.igst) ?? 0) > 0) {
                      _selectedIgstRate = created;
                      _igstController.text = created.igst;
                    } else {
                      _selectedGstRate = created;
                      _cgstController.text = created.cgst;
                      _sgstController.text = created.sgst;
                      _igstController.text = '0';
                    }
                    _calculateGST();
                  });
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCustomGstRateField() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Row(
            children: [
              Expanded(
                child: TextFormField(
                  key: _customGstRateFieldKey,
                  controller: _customGstRateController,
                  decoration: const InputDecoration(
                    labelText: 'Custom GST Rate % (Total)',
                    border: OutlineInputBorder(),
                    hintText: 'Enter GST rate (e.g., 12)',
                  ),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  onChanged: (value) {
                    final rate = double.tryParse(value);
                    if (rate != null && rate > 0) {
                      final halfRate = rate / 2;
                      final customGst = GSTModel(
                        gstCategory: '${rate.toStringAsFixed(1)}% (${halfRate.toStringAsFixed(1)}% CGST + ${halfRate.toStringAsFixed(1)}% SGST)',
                        gstRate: rate.toString(),
                        cgst: halfRate.toString(),
                        sgst: halfRate.toString(),
                        igst: '0',
                        description: 'GST Rate - ${rate.toStringAsFixed(1)}% Total',
                      );
                      
                      _selectedGstRate = customGst;
                      _updateGstRates();
                    }

                    _scheduleFieldValidation(_customGstRateFieldKey);
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      if (_igstController.text.isEmpty) {
                        return 'Required if IGST is not provided';
                      }
                      return null;
                    }
                    final rate = double.tryParse(value);
                    if (rate == null || rate <= 0) {
                      return 'Enter a valid positive number';
                    }
                    return null;
                  },
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () {
                  setState(() {
                    _showCustomGstRate = false;
                    _selectedGstRate = null;
                    _customGstRateController.clear();
                    _cgstController.clear();
                    _sgstController.clear();
                    _calculateGST();
                  });
                },
              ),
            ],
          ),
        ),
        // Show CGST and SGST splits
        Row(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(right: 8.0, bottom: 8.0),
                child: TextFormField(
                  controller: _cgstController,
                  readOnly: true,
                  decoration: const InputDecoration(
                    labelText: 'CGST %',
                    border: OutlineInputBorder(),
                    filled: true,
                    fillColor: Colors.transparent,
                  ),
                  style: const TextStyle(color: Colors.white70),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(left: 8.0, bottom: 8.0),
                child: TextFormField(
                  controller: _sgstController,
                  readOnly: true,
                  decoration: const InputDecoration(
                    labelText: 'SGST %',
                    border: OutlineInputBorder(),
                    filled: true,
                    fillColor: Colors.transparent,
                  ),
                  style: const TextStyle(color: Colors.white70),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildIgstRateDropdown() {
    final gstRates = ref.watch(gstListProvider);
    
    // Build dropdown items for IGST from GST Master
    List<DropdownMenuItem<String?>> dropdownItems = [
      ...gstRates.where((gst) => double.tryParse(gst.igst) != null && double.tryParse(gst.igst)! > 0).map((gst) {
        return DropdownMenuItem<String?>(
          value: gst.gstCategory,
          child: Text(gst.gstCategory),
        );
      }),
    ];

    // Add custom rate to dropdown if it exists and not already in the list
    if (_selectedIgstRate != null) {
      // Check if this is a custom IGST rate (ends with "IGST" or old "CustomIGST" format)
      final isCustomIgst = _selectedIgstRate!.gstCategory.endsWith('IGST') || _selectedIgstRate!.gstCategory == 'CustomIGST';
      if (isCustomIgst) {
        // Check if this category is not already in the dropdown items
        final alreadyExists = dropdownItems.any((item) => item.value == _selectedIgstRate!.gstCategory);
        if (!alreadyExists) {
          dropdownItems.add(
            DropdownMenuItem<String?>(
              value: _selectedIgstRate!.gstCategory,
              child: Text(_selectedIgstRate!.gstCategory),
            ),
          );
        }
      }
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String?>(
                  value: _selectedIgstRate?.gstCategory,
                  decoration: const InputDecoration(
                    labelText: 'IGST Rate',
                    border: OutlineInputBorder(),
                  ),
                  hint: const Text('Select IGST Rate'),
                  isExpanded: true,
                  items: dropdownItems,
                  onChanged: (String? newValue) {
                    if (newValue == null) return;
                    setState(() {
                      final selectedGst = gstRates
                          .firstWhere((gst) => gst.gstCategory == newValue);
                      _selectedIgstRate = selectedGst;
                      _igstController.text = selectedGst.igst;
                      _calculateGST();
                    });
                  },
                  validator: (value) {
                    if (!_isTamilNadu && value == null) {
                      return 'Please select IGST rate';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                tooltip: 'Add IGST Rate',
                icon: const Icon(Icons.add_circle_outline),
                onPressed: () async {
                  final created = await Navigator.push<GSTModel>(
                    context,
                    MaterialPageRoute(builder: (_) => const AddGSTPage()),
                  );
                  if (created == null) return;
                  await ref.read(gstListProvider.notifier).loadData();
                  if (!mounted) return;
                  setState(() {
                    _selectedIgstRate = created;
                    _igstController.text = created.igst;
                    _calculateGST();
                  });
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCustomIgstRateField() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        key: _customIgstRateFieldKey,
        controller: _customIgstRateController,
        decoration: const InputDecoration(
          labelText: 'Custom IGST Rate %',
          border: OutlineInputBorder(),
          hintText: 'Enter IGST rate (e.g., 12)',
        ),
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        onChanged: (value) {
          final rate = double.tryParse(value);
          if (rate != null && rate > 0) {
            final customIgst = GSTModel(
              gstCategory: '${rate.toStringAsFixed(1)}% IGST',
              gstRate: rate.toString(),
              cgst: '0',
              sgst: '0',
              igst: rate.toString(),
              description: 'IGST Rate - ${rate.toStringAsFixed(1)}%',
            );
            
            _selectedIgstRate = customIgst;
            _igstController.text = rate.toStringAsFixed(2);
            _calculateGST();
          }

          _scheduleFieldValidation(_customIgstRateFieldKey);
        },
        validator: (value) {
          if (_showCustomIgstRate && (value == null || value.isEmpty)) {
            return 'Please enter custom IGST rate';
          }
          final rate = double.tryParse(value ?? '');
          if (_showCustomIgstRate && (rate == null || rate <= 0)) {
            return 'Please enter a valid rate';
          }
          return null;
        },
      ),
    );
  }

  Widget _buildGstTextField(String label, TextEditingController controller,
      {bool enabled = true}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: controller,
        readOnly: !enabled,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        onChanged: (value) {
          if (label == 'IGST %' && value.isNotEmpty && double.tryParse(value) != null) {
            setState(() {
              _selectedGstRate = null;
              _showCustomGstRate = false;
              _customGstRateController.clear();
            });
          }
          _calculateGST();
        },
        validator: (value) {
          if (enabled && value != null && value.isNotEmpty) {
            final numValue = double.tryParse(value);
            if (numValue == null) {
              return 'Enter valid number';
            }
            if (numValue < 0) {
              return 'Cannot be negative';
            }
          }
          return null;
        },
      ),
    );
  }

  Widget _buildGstNumberField() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextFormField(
            controller: _gstNoController,
            readOnly: true,
            decoration: const InputDecoration(
              labelText: 'GST No (Auto-generated)',
              border: OutlineInputBorder(),
              hintText: 'State Code + PAN + 3 digits',
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Required';
              }
              return null;
            },
          ),
          const SizedBox(height: 8),
          TextFormField(
            key: _gstSuffixFieldKey,
            controller: _gstSuffixController,
            decoration: const InputDecoration(
              labelText: 'GST Suffix (3 characters)',
              border: OutlineInputBorder(),
              hintText: 'e.g., 1Z5 or 1ZA',
              helperText: 'Format: Digit + Letter + Alphanumeric',
            ),
            maxLength: 3,
            textCapitalization: TextCapitalization.characters,
            onChanged: (value) {
              _updateGstNumber();
              _scheduleFieldValidation(_gstSuffixFieldKey);
            },
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Required';
              }
              if (value.length != 3) {
                return 'Must be exactly 3 characters';
              }
              final firstChar = value[0];
              final middleChar = value[1];
              final lastChar = value[2];
              
              // First character must be a digit
              final isFirstDigit = int.tryParse(firstChar) != null;
              
              // Middle character must be a letter
              final isMiddleLetter = RegExp(r'^[A-Z]$').hasMatch(middleChar);
              
              // Last character must be alphanumeric (digit or letter)
              final isLastAlphanumeric = RegExp(r'^[A-Z0-9]$').hasMatch(lastChar);

              if (!isFirstDigit) {
                return 'First character must be a digit';
              }
              if (!isMiddleLetter) {
                return 'Middle character must be a letter';
              }
              if (!isLastAlphanumeric) {
                return 'Last character must be alphanumeric';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStateTextField() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextFormField(
            key: _stateFieldKey,
            controller: _stateController,
            focusNode: _stateFocusNode,
            decoration: const InputDecoration(
              labelText: 'State',
              border: OutlineInputBorder(),
              hintText: 'Enter state name',
              suffixIcon: Icon(Icons.search),
            ),
            onChanged: (value) {
              _onStateChanged(value);
              _scheduleFieldValidation(_stateFieldKey);
            },
            onTap: () {
              if (_stateController.text.isNotEmpty) {
                _onStateChanged(_stateController.text);
              }
            },
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Required';
              }
              return null;
            },
            onSaved: (value) => state = value ?? '',
          ),
          if (_showStateSuggestions && _stateFocusNode.hasFocus)
            Container(
              constraints: const BoxConstraints(maxHeight: 200),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade700),
                borderRadius: BorderRadius.circular(4),
                color: Colors.black,
              ),
              child: _filteredStates.isNotEmpty
                  ? ListView.builder(
                      shrinkWrap: true,
                      itemCount: _filteredStates.length,
                      itemBuilder: (context, index) {
                        final stateModel = _filteredStates[index];
                        return ListTile(
                          dense: true,
                          title: Text(
                            stateModel.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          subtitle: Text(
                            'Code: ${stateModel.stateCode}',
                            style: TextStyle(color: Colors.grey.shade300),
                          ),
                          onTap: () => _selectState(stateModel),
                        );
                      },
                    )
                  : Container(
                      padding: const EdgeInsets.all(12),
                      child: ListTile(
                        leading: Icon(
                          Icons.info_outline,
                          color: Colors.grey.shade400,
                          size: 20,
                        ),
                        title: Text(
                          'No states found',
                          style: TextStyle(
                            color: Colors.grey.shade300,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        subtitle: Text(
                          'Add a new state to continue',
                          style: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: 12,
                          ),
                        ),
                        trailing: ElevatedButton.icon(
                          icon: const Icon(Icons.add, size: 16),
                          label: const Text('Add State'),
                          onPressed: _addNewState,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            minimumSize: const Size(100, 32),
                          ),
                        ),
                      ),
                    ),
            ),
        ],
      ),
    );
  }

  Widget _buildStateCodeTextField() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextFormField(
            key: _stateCodeFieldKey,
            controller: _stateCodeController,
            focusNode: _stateCodeFocusNode,
            decoration: const InputDecoration(
              labelText: 'State Code',
              border: OutlineInputBorder(),
              hintText: 'Enter state code',
              suffixIcon: Icon(Icons.search),
            ),
            onChanged: (value) {
              _onStateCodeChanged(value);
              _scheduleFieldValidation(_stateCodeFieldKey);
            },
            onTap: () {
              if (_stateCodeController.text.isNotEmpty) {
                _onStateCodeChanged(_stateCodeController.text);
              }
            },
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Required';
              }
              return null;
            },
            onSaved: (value) => stateCode = value ?? '',
          ),
          if (_showStateSuggestions && _stateCodeFocusNode.hasFocus)
            Container(
              constraints: const BoxConstraints(maxHeight: 200),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade700),
                borderRadius: BorderRadius.circular(4),
                color: Colors.black,
              ),
              child: _filteredStates.isNotEmpty
                  ? ListView.builder(
                      shrinkWrap: true,
                      itemCount: _filteredStates.length,
                      itemBuilder: (context, index) {
                        final stateModel = _filteredStates[index];
                        return ListTile(
                          dense: true,
                          title: Text(
                            stateModel.stateCode,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          subtitle: Text(
                            stateModel.name,
                            style: TextStyle(color: Colors.grey.shade300),
                          ),
                          onTap: () => _selectState(stateModel),
                        );
                      },
                    )
                  : Container(
                      padding: const EdgeInsets.all(12),
                      child: ListTile(
                        leading: Icon(
                          Icons.info_outline,
                          color: Colors.grey.shade400,
                          size: 20,
                        ),
                        title: Text(
                          'No states found',
                          style: TextStyle(
                            color: Colors.grey.shade300,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        subtitle: Text(
                          'Add a new state to continue',
                          style: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: 12,
                          ),
                        ),
                        trailing: ElevatedButton.icon(
                          icon: const Icon(Icons.add, size: 16),
                          label: const Text('Add State'),
                          onPressed: _addNewState,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            minimumSize: const Size(100, 32),
                          ),
                        ),
                      ),
                    ),
            ),
        ],
      ),
    );
  }

  Widget _buildPaymentTermsDropdown() {
    final paymentTermsList = ref.watch(paymentTermsListProvider);
    // Deduplicate by name and build a sorted list
    final uniqueNames = <String>{}..addAll(paymentTermsList.map((t) => t.name));
    final terms = uniqueNames.toList()..sort();
    // Ensure current value exists in list; otherwise, use null
    final currentValue = terms.contains(paymentTerms) ? paymentTerms : null;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Expanded(
            child: DropdownButtonFormField<String>(
              value: currentValue,
              decoration: const InputDecoration(
                labelText: 'Payment Terms',
                border: OutlineInputBorder(),
              ),
              hint: const Text('Select payment terms'),
              items: terms.map((name) {
                return DropdownMenuItem<String>(
                  value: name,
                  child: Text(name),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  paymentTerms = value ?? '';
                });
              },
              validator: (value) {
                // Optional field, no validation needed
                return null;
              },
            ),
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'Manage Payment Terms',
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const PaymentTermsSettingsPage(),
                ),
              );
              // Refresh payment terms after returning
              await ref.read(paymentTermsListProvider.notifier).loadPaymentTerms();
            },
          ),
        ],
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
    int? maxLength,
    Function(String)? onChangedCallback,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        key: _getFieldKey(label),
        initialValue: initial,
        enabled: enabled,
        maxLength: maxLength,
        inputFormatters: (label.contains('IFSC') || label.contains('PAN'))
            ? [
                FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9]')),
                LengthLimitingTextInputFormatter(label.contains('IFSC') ? 11 : 10),
                UpperCaseTextFormatter(),
              ]
            : null,
        decoration: InputDecoration(
          labelText: required ? '$label *' : label,
          border: const OutlineInputBorder(),
          filled: !enabled,
          fillColor: !enabled ? Colors.grey[600] : null,
          counterText: maxLength != null ? '' : null,
        ),
        style: TextStyle(
          color: !enabled ? Colors.grey[400] : null,
        ),
        keyboardType: keyboardType,
        onChanged: (v) {
          if (onChangedCallback != null) {
            onChangedCallback(v);
          }
          _scheduleFieldValidation(_getFieldKey(label));
        },
        validator: (value) {
          if (required && (value == null || value.isEmpty)) {
            return 'Required';
          }

          if (label.contains('IFSC')) {
            if (value == null || value.isEmpty) {
              return null;
            }
            final v = value.toUpperCase().trim();
            final ifscRegex = RegExp(r'^[A-Z]{4}0[A-Z0-9]{6}$');
            if (!ifscRegex.hasMatch(v)) {
              return 'Invalid IFSC format (e.g., ABCD0EF1234)';
            }
          }
          
          // PAN number validation
          if (label.contains('PAN')) {
            if (value != null && value.isNotEmpty && value.length != 10) {
              return 'PAN must be exactly 10 characters';
            }
            if (value != null && value.isNotEmpty) {
              final panRegex = RegExp(r'^[A-Z]{5}[0-9]{4}[A-Z]$');
              if (!panRegex.hasMatch(value.toUpperCase())) {
                return 'Invalid PAN format (e.g., AAAAA9999A)';
              }
            }
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

            // PAN duplicate check
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
        onSaved: (value) => onSaved(
            (label.contains('IFSC') || label.contains('PAN'))
                ? (value ?? '').toUpperCase()
                : (value ?? '')),
      ),
    );
  }

  GlobalKey<FormFieldState> _getFieldKey(String label) {
    return _fieldKeys.putIfAbsent(label, () => GlobalKey<FormFieldState>());
  }

  void _scheduleFieldValidation(GlobalKey<FormFieldState> fieldKey) {
    _fieldValidationDebounce[fieldKey]?.cancel();
    _fieldValidationDebounce[fieldKey] =
        Timer(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      fieldKey.currentState?.validate();
    });
  }

  @override
  void dispose() {
    for (final t in _fieldValidationDebounce.values) {
      t.cancel();
    }
    _stateController.dispose();
    _stateCodeController.dispose();
    _stateFocusNode.dispose();
    _stateCodeFocusNode.dispose();
    _igstController.dispose();
    _cgstController.dispose();
    _sgstController.dispose();
    _totalGstController.dispose();
    _gstSuffixController.dispose();
    _gstNoController.dispose();
    _customGstRateController.dispose();
    _customIgstRateController.dispose();
    super.dispose();
  }
}

class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    return newValue.copyWith(
      text: newValue.text.toUpperCase(),
      selection: newValue.selection,
    );
  }
}
