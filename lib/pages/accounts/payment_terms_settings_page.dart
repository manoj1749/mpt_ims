import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../provider/payment_terms_provider.dart';
import '../../models/payment_terms.dart';

class PaymentTermsSettingsPage extends ConsumerStatefulWidget {
  const PaymentTermsSettingsPage({super.key});

  @override
  ConsumerState<PaymentTermsSettingsPage> createState() =>
      _PaymentTermsSettingsPageState();
}

class _PaymentTermsSettingsPageState
    extends ConsumerState<PaymentTermsSettingsPage> {
  final _paymentTermController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        await ref.read(paymentTermsListProvider.notifier).loadPaymentTerms();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error loading payment terms: $e')),
          );
        }
      }
    });
  }

  @override
  void dispose() {
    _paymentTermController.dispose();
    super.dispose();
  }

  void _showAddDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Payment Term'),
        content: TextField(
          controller: _paymentTermController,
          decoration: const InputDecoration(
            hintText: 'Enter payment term (e.g., Net 30, Net 60)',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final text = _paymentTermController.text.trim();
              if (text.isNotEmpty) {
                _addPaymentTerm(text);
                Navigator.pop(context);
                _paymentTermController.clear();
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showEditDialog(PaymentTerms paymentTerm) {
    _paymentTermController.text = paymentTerm.name;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Payment Term'),
        content: TextField(
          controller: _paymentTermController,
          decoration: const InputDecoration(
            hintText: 'Enter payment term',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () {
              _paymentTermController.clear();
              Navigator.pop(context);
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final text = _paymentTermController.text.trim();
              if (text.isNotEmpty) {
                _updatePaymentTerm(paymentTerm, text);
                Navigator.pop(context);
                _paymentTermController.clear();
              }
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  Future<void> _addPaymentTerm(String name) async {
    try {
      await ref.read(paymentTermsListProvider.notifier).addPaymentTerm(name);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Payment term "$name" added successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error adding payment term: $e')),
        );
      }
    }
  }

  Future<void> _updatePaymentTerm(PaymentTerms oldTerm, String newName) async {
    try {
      final updatedTerm = oldTerm.copyWith(name: newName);
      await ref.read(paymentTermsListProvider.notifier).updatePaymentTerm(updatedTerm);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Payment term updated successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating payment term: $e')),
        );
      }
    }
  }

  Future<void> _deletePaymentTerm(PaymentTerms paymentTerm) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Payment Term'),
        content: Text('Are you sure you want to delete "${paymentTerm.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await ref.read(paymentTermsListProvider.notifier).deletePaymentTerm(paymentTerm);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Payment term deleted successfully')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error deleting payment term: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final paymentTerms = ref.watch(paymentTermsListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment Terms Settings'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Payment Terms',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                ElevatedButton.icon(
                  onPressed: _showAddDialog,
                  icon: const Icon(Icons.add),
                  label: const Text('Add Payment Term'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: paymentTerms.isEmpty
                  ? const Center(
                      child: Text(
                        'No payment terms added yet.\nClick "Add Payment Term" to get started.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    )
                  : ListView.builder(
                      itemCount: paymentTerms.length,
                      itemBuilder: (context, index) {
                        final paymentTerm = paymentTerms[index];
                        return Card(
                          child: ListTile(
                            title: Text(
                              paymentTerm.name,
                              style: const TextStyle(fontWeight: FontWeight.w500),
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit, color: Colors.blue),
                                  onPressed: () => _showEditDialog(paymentTerm),
                                  tooltip: 'Edit',
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red),
                                  onPressed: () => _deletePaymentTerm(paymentTerm),
                                  tooltip: 'Delete',
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
