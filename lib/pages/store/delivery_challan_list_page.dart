import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/delivery_challan.dart';
import '../../provider/delivery_challan_provider.dart';
import '../../services/pdf_service.dart';
import '../../models/supplier.dart';
import '../../provider/supplier_provider.dart';
import '../../models/material_item.dart';
import '../../provider/material_provider.dart';
import 'add_job_delivery_challan_page.dart';

class DeliveryChallanListPage extends ConsumerStatefulWidget {
  const DeliveryChallanListPage({super.key});

  @override
  ConsumerState<DeliveryChallanListPage> createState() =>
      _DeliveryChallanListPageState();
}

class _DeliveryChallanListPageState
    extends ConsumerState<DeliveryChallanListPage> {
  @override
  Widget build(BuildContext context) {
    final deliveryChallans = ref.watch(deliveryChallanListProvider);
    
    // Filter for billing delivery challans (sale-order based, final billing value)
    final jobDeliveryChallans = deliveryChallans.where((dc) => dc.dcType == 'billing' || (dc.dcType == 'job_order' && dc.items.any((i) => i.unit == 'JOB'))).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Delivery Challans'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Add Delivery Challan',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AddJobDeliveryChallanPage(),
                ),
              );
            },
          ),
        ],
      ),
      body: jobDeliveryChallans.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.description_outlined,
                    size: 64,
                    color: Colors.grey,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'No Delivery Challans Found',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Create your first delivery challan using the + button above',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: jobDeliveryChallans.length,
              itemBuilder: (context, index) {
                final dc = jobDeliveryChallans[index];
                final totalValue = dc.items.fold<double>(0, (sum, item) => sum + item.price);
                
                return Card(
                  margin: const EdgeInsets.only(bottom: 16.0),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header row with DC number and actions
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    dc.dcNo,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    dc.dcDate,
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            PopupMenuButton<String>(
                              icon: const Icon(Icons.more_vert),
                              onSelected: (value) {
                                switch (value) {
                                  case 'pdf':
                                    _showPDFOptions(dc);
                                    break;
                                  case 'delete':
                                    _deleteDeliveryChallan(dc);
                                    break;
                                }
                              },
                              itemBuilder: (context) => [
                                const PopupMenuItem(
                                  value: 'pdf',
                                  child: Row(
                                    children: [
                                      Icon(Icons.picture_as_pdf),
                                      SizedBox(width: 8),
                                      Text('Generate PDF'),
                                    ],
                                  ),
                                ),
                                const PopupMenuItem(
                                  value: 'delete',
                                  child: Row(
                                    children: [
                                      Icon(Icons.delete),
                                      SizedBox(width: 8),
                                      Text('Delete'),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        
                        // Customer and Job info
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Customer',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  Text(
                                    dc.vendorName,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (dc.jobOrderNumber != null && dc.jobOrderNumber!.isNotEmpty) ...[
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Job Order',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                    Text(
                                      dc.jobOrderNumber!,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    'Total Value',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  Text(
                                    totalValue.toStringAsFixed(2),
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        
                        // Items
                        if (dc.items.isNotEmpty) ...[
                          Text(
                            'Items (${dc.items.length})',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          ...dc.items.map((item) => Padding(
                            padding: const EdgeInsets.only(bottom: 4.0),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    item.materialDescription,
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                ),
                                Text(
                                  '${item.quantity} ${item.unit} - ${item.price.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          )).toList(),
                        ],
                        
                        // Note
                        if (dc.note != null && dc.note!.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(
                            'Note: ${dc.note}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  void _showPDFOptions(DeliveryChallan dc) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[850],
        title: Text(
          'Generate Delivery Challan PDF for ${dc.dcNo}',
          style: TextStyle(color: Colors.grey[200]),
        ),
        content: Text(
          'Choose how to save the DC PDF:',
          style: TextStyle(color: Colors.grey[200]),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _generateAndSaveToDownloads(dc);
            },
            child: Text(
              'Quick Save',
              style: TextStyle(color: Colors.grey[300]),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _generateAndSavePDF(dc);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
            ),
            child: const Text('Choose Location'),
          ),
        ],
      ),
    );
  }

  void _deleteDeliveryChallan(DeliveryChallan dc) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[850],
        title: Text(
          'Delete Delivery Challan',
          style: TextStyle(color: Colors.grey[200]),
        ),
        content: Text(
          'Are you sure you want to delete delivery challan ${dc.dcNo}?',
          style: TextStyle(color: Colors.grey[200]),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(color: Colors.grey[300]),
            ),
          ),
          TextButton(
            onPressed: () {
              final notifier = ref.read(
                deliveryChallanListProvider.notifier,
              );
              notifier.deleteDeliveryChallan(
                dc,
                ref,
              );
              Navigator.pop(context);
            },
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _generateAndSavePDF(DeliveryChallan dc) async {
    try {
      if (!mounted) return;

      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          backgroundColor: Colors.grey[850],
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(
                'Preparing PDF...',
                style: TextStyle(color: Colors.grey[200]),
              ),
            ],
          ),
        ),
      );

      final success = await PDFService.saveJobDeliveryChallan(dc);

      Navigator.pop(context); // Close loading dialog

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('PDF saved successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Save cancelled by user'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      Navigator.pop(context); // Close loading dialog
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving PDF: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _generateAndSaveToDownloads(DeliveryChallan dc) async {
    try {
      if (!mounted) return;

      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          backgroundColor: Colors.grey[850],
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(
                'Preparing PDF...',
                style: TextStyle(color: Colors.grey[200]),
              ),
            ],
          ),
        ),
      );

      final success = await PDFService.saveJobDeliveryChallanToDownloads(dc);

      Navigator.pop(context); // Close loading dialog

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(Platform.isMacOS || Platform.isIOS
                ? 'PDF saved to Documents folder successfully!'
                : 'PDF saved to Downloads folder successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to save PDF to Downloads'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      Navigator.pop(context); // Close loading dialog
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving PDF: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}