import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../provider/store_inward_provider.dart';
import 'add_store_inward_page.dart';

class StoreInwardListPage extends ConsumerWidget {
  const StoreInwardListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final storeInwards = ref.watch(storeInwardProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Store Inwards'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AddStoreInwardPage(),
                ),
              );
            },
          ),
        ],
      ),
      body: storeInwards.isEmpty
          ? const Center(
              child: Text('No store inwards found'),
            )
          : ListView.builder(
              itemCount: storeInwards.length,
              itemBuilder: (context, index) {
                final inward = storeInwards[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: ListTile(
                    title: Text('GRN No: ${inward.grnNo}'),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Supplier: ${inward.supplierName}'),
                        Text('Invoice No: ${inward.invoiceNo}'),
                        Text('Date: ${inward.grnDate}'),
                      ],
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Delete Store Inward'),
                            content: const Text(
                                'Are you sure you want to delete this store inward?'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('Cancel'),
                              ),
                              TextButton(
                                onPressed: () {
                                  ref
                                      .read(storeInwardProvider.notifier)
                                      .deleteInward(inward);
                                  Navigator.pop(context);
                                },
                                child: const Text('Delete'),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                    onTap: () {
                      // TODO: Implement view/edit functionality
                    },
                  ),
                );
              },
            ),
    );
  }
} 