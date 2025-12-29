import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/state.dart';
import '../../provider/state_provider.dart';

class AddStatePage extends ConsumerStatefulWidget {
  final StateModel? stateToEdit;
  final int? index;

  const AddStatePage({
    super.key,
    this.stateToEdit,
    this.index,
  });

  @override
  ConsumerState<AddStatePage> createState() => _AddStatePageState();
}

class _AddStatePageState extends ConsumerState<AddStatePage> {
  final _formKey = GlobalKey<FormState>();
  late String name, stateCode;

  @override
  void initState() {
    super.initState();
    final s = widget.stateToEdit;
    name = s?.name ?? '';
    stateCode = s?.stateCode ?? '';
  }

  Future<void> _saveState() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      final state = StateModel(
        name: name,
        stateCode: stateCode,
      );

      try {
        final notifier = ref.read(stateListProvider.notifier);
        if (widget.stateToEdit != null) {
          // If state code has changed, we need to delete the old one and add the new one
          // because stateCode is used as the unique identifier
          if (widget.stateToEdit!.stateCode != stateCode) {
            // Delete the old state
            await notifier.delete(widget.stateToEdit!);
            // Add the new state with updated code
            await notifier.add(state);
          } else {
            // State code hasn't changed, just update normally
            await notifier.update(state);
          }
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('State updated successfully')),
            );
          }
        } else {
          await notifier.add(state);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('State added successfully')),
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
            widget.stateToEdit == null ? 'Add State' : 'Edit State'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              children: [
                _buildTextField('State Name', (v) => name = v,
                    initial: name, required: true),
                _buildTextField('State Code', (v) => stateCode = v,
                    initial: stateCode,
                    required: true,
                    keyboardType: TextInputType.number,
                    maxLength: 2),
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: _saveState,
                  child: Text(widget.stateToEdit == null
                      ? 'Add State'
                      : 'Update State'),
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
    int? maxLength,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        initialValue: initial,
        enabled: enabled,
        maxLength: maxLength,
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
        validator: (value) {
          if (required && (value == null || value.isEmpty)) {
            return 'Required';
          }

          final states = ref.read(stateListProvider);
          final currentState = widget.stateToEdit;

          // Validation for various fields to prevent duplicates
          if (enabled && value != null && value.isNotEmpty) {
            // State Code validation
            if (label.contains('State Code')) {
              // Check if it's exactly 2 digits
              if (value.length != 2) {
                return 'State code must be exactly 2 digits';
              }
              if (!RegExp(r'^\d{2}$').hasMatch(value)) {
                return 'State code must contain only numbers';
              }
              
              final existingState = states.any((s) =>
                  s.stateCode.toLowerCase() == value.toLowerCase() &&
                  s.stateCode != (currentState?.stateCode ?? ''));
              if (existingState) {
                return 'State code already exists';
              }
            }

            // State Name validation
            if (label.contains('State Name')) {
              final existingState = states.any((s) =>
                  s.name.toLowerCase() == value.toLowerCase() &&
                  s.name != (currentState?.name ?? ''));
              if (existingState) {
                return 'State name already exists';
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
