import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/gst.dart';
import '../../provider/gst_provider.dart';

class AddGSTPage extends ConsumerStatefulWidget {
  final GSTModel? gstToEdit;
  final int? index;

  const AddGSTPage({
    super.key,
    this.gstToEdit,
    this.index,
  });

  @override
  ConsumerState<AddGSTPage> createState() => _AddGSTPageState();
}

class _AddGSTPageState extends ConsumerState<AddGSTPage> {
  final _formKey = GlobalKey<FormState>();
  late String gstCategory,
      gstRate,
      cgst,
      sgst,
      igst,
      description;

  String _taxType = 'GST';

  final TextEditingController _gstRateController = TextEditingController();
  final TextEditingController _cgstController = TextEditingController();
  final TextEditingController _sgstController = TextEditingController();
  final TextEditingController _igstController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final g = widget.gstToEdit;
    gstCategory = g?.gstCategory ?? '';
    gstRate = g?.gstRate ?? '';
    cgst = g?.cgst ?? '';
    sgst = g?.sgst ?? '';
    igst = g?.igst ?? '';
    description = g?.description ?? '';

    final igstValue = double.tryParse(igst) ?? 0;
    _taxType = igstValue > 0 ? 'IGST' : 'GST';

    _gstRateController.text = gstRate;
    _cgstController.text = cgst;
    _sgstController.text = sgst;
    _igstController.text = igst;
    _recalculateFromRate();
  }

  @override
  void dispose() {
    _gstRateController.dispose();
    _cgstController.dispose();
    _sgstController.dispose();
    _igstController.dispose();
    super.dispose();
  }

  void _recalculateFromRate() {
    final rate = double.tryParse(_gstRateController.text.trim());
    if (rate == null) {
      _cgstController.text = '';
      _sgstController.text = '';
      _igstController.text = '';
      gstCategory = '';
      return;
    }

    if (_taxType == 'IGST') {
      _igstController.text = rate.toStringAsFixed(2);
      _cgstController.text = '0.00';
      _sgstController.text = '0.00';

      final r = rate.toStringAsFixed(2);
      gstCategory = '$r ($r% IGST)';
    } else {
      final half = rate / 2;
      _cgstController.text = half.toStringAsFixed(2);
      _sgstController.text = half.toStringAsFixed(2);
      _igstController.text = '0.00';

      final r = rate.toStringAsFixed(2);
      final h = half.toStringAsFixed(2);
      gstCategory = '$r ($h% CGST + $h% SGST)';
    }
  }

  Future<void> _saveGST() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      _recalculateFromRate();

      gstRate = _gstRateController.text.trim();
      cgst = _cgstController.text.trim().isEmpty ? '0' : _cgstController.text.trim();
      sgst = _sgstController.text.trim().isEmpty ? '0' : _sgstController.text.trim();
      igst = _igstController.text.trim().isEmpty ? '0' : _igstController.text.trim();

      if (_taxType == 'IGST') {
        cgst = '0';
        sgst = '0';
      } else {
        igst = '0';
      }

      final gst = GSTModel(
        gstCategory: gstCategory,
        gstRate: gstRate,
        cgst: cgst,
        sgst: sgst,
        igst: igst,
        description: description,
      );

      try {
        final notifier = ref.read(gstListProvider.notifier);
        if (widget.gstToEdit != null) {
          await notifier.update(gst);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('GST updated successfully')),
            );
          }
        } else {
          await notifier.add(gst);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('GST added successfully')),
            );
          }
        }
        if (mounted) {
          Navigator.pop(context, gst);
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
            widget.gstToEdit == null ? 'Add GST' : 'Edit GST'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: DropdownButtonFormField<String>(
                    value: _taxType,
                    decoration: const InputDecoration(
                      labelText: 'Category *',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'GST', child: Text('GST (CGST+SGST)')),
                      DropdownMenuItem(value: 'IGST', child: Text('IGST')),
                    ],
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() {
                        _taxType = value;
                        _recalculateFromRate();
                      });
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Required';
                      }
                      return null;
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: TextFormField(
                    controller: _gstRateController,
                    enabled: widget.gstToEdit == null,
                    decoration: InputDecoration(
                      labelText: 'GST Rate *',
                      border: const OutlineInputBorder(),
                      filled: widget.gstToEdit != null,
                      fillColor:
                          widget.gstToEdit != null ? Colors.grey[600] : null,
                    ),
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    onChanged: (_) {
                      setState(_recalculateFromRate);
                    },
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Required';
                      }
                      final v = double.tryParse(value.trim());
                      if (v == null) {
                        return 'Enter valid number';
                      }
                      if (v <= 0) {
                        return 'Must be greater than 0';
                      }
                      return null;
                    },
                  ),
                ),
                if (_taxType == 'GST') ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: TextFormField(
                      controller: _cgstController,
                      readOnly: true,
                      decoration: const InputDecoration(
                        labelText: 'CGST %',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: TextFormField(
                      controller: _sgstController,
                      readOnly: true,
                      decoration: const InputDecoration(
                        labelText: 'SGST %',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ] else ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: TextFormField(
                      controller: _igstController,
                      readOnly: true,
                      decoration: const InputDecoration(
                        labelText: 'IGST %',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ],
                _buildTextField('Description', (v) => description = v,
                    initial: description),
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: _saveGST,
                  child: Text(widget.gstToEdit == null
                      ? 'Add GST'
                      : 'Update GST'),
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

          final gstList = ref.read(gstListProvider);
          final currentGST = widget.gstToEdit;

          // Validation for various fields to prevent duplicates
          if (enabled && value != null && value.isNotEmpty) {
            // GST Category validation
            if (label.contains('GST Category')) {
              final existingGST = gstList.any((g) =>
                  g.gstCategory.toLowerCase() == value.toLowerCase() &&
                  g.gstCategory != (currentGST?.gstCategory ?? ''));
              if (existingGST) {
                return 'GST category already exists';
              }
            }

            // GST Rate validation
            if (label.contains('GST Rate')) {
              final existingGST = gstList.any((g) =>
                  g.gstRate.toLowerCase() == value.toLowerCase() &&
                  g.gstRate != (currentGST?.gstRate ?? ''));
              if (existingGST) {
                return 'GST rate already exists';
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
