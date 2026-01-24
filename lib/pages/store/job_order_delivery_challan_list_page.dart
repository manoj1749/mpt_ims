import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pluto_grid/pluto_grid.dart';
import '../../models/delivery_challan.dart';
import '../../provider/delivery_challan_provider.dart';
import '../../provider/supplier_provider.dart';
import '../../provider/material_provider.dart';
import '../../services/pdf_service.dart';
import '../../widgets/pluto_grid_configuration.dart';
import 'add_delivery_challan_page.dart';

class JobOrderDeliveryChallanListPage extends ConsumerStatefulWidget {
  const JobOrderDeliveryChallanListPage({super.key});

  @override
  ConsumerState<JobOrderDeliveryChallanListPage> createState() =>
      _JobOrderDeliveryChallanListPageState();
}

class _JobOrderDeliveryChallanListPageState
    extends ConsumerState<JobOrderDeliveryChallanListPage> {
  @override
  Widget build(BuildContext context) {
    final allDeliveryChallans = ref.watch(deliveryChallanListProvider);
    // Filter for job order delivery challans only
    final deliveryChallans = allDeliveryChallans.where((dc) => dc.dcType == 'job_order').toList();

    final columns = [
      PlutoColumn(
        title: 'DC No',
        field: 'dcNo',
        type: PlutoColumnType.text(),
        enableEditingMode: false,
        width: 120,
      ),
      PlutoColumn(
        title: 'Date',
        field: 'date',
        type: PlutoColumnType.text(),
        enableEditingMode: false,
        width: 100,
      ),
      PlutoColumn(
        title: 'Vendor',
        field: 'vendor',
        type: PlutoColumnType.text(),
        enableEditingMode: false,
        width: 150,
      ),
      PlutoColumn(
        title: 'GSTIN',
        field: 'gstin',
        type: PlutoColumnType.text(),
        enableEditingMode: false,
        width: 150,
      ),
      PlutoColumn(
        title: 'Email',
        field: 'email',
        type: PlutoColumnType.text(),
        enableEditingMode: false,
        width: 200,
      ),
      PlutoColumn(
        title: 'Returnable',
        field: 'returnable',
        type: PlutoColumnType.text(),
        enableEditingMode: false,
        width: 100,
      ),
      PlutoColumn(
        title: 'Note',
        field: 'note',
        type: PlutoColumnType.text(),
        enableEditingMode: false,
        width: 150,
      ),
      PlutoColumn(
        title: 'Items',
        field: 'items',
        type: PlutoColumnType.text(),
        enableEditingMode: false,
        width: 300,
        renderer: (rendererContext) {
          final dc = deliveryChallans.firstWhere(
            (dc) => dc.dcNo == rendererContext.row.cells['dcNo']!.value,
          );
          return Container(
            constraints: const BoxConstraints(maxHeight: 200),
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: dc.items.map((item) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 4.0),
                      child: Text(
                        '${item.materialCode} - ${item.materialDescription} (${item.quantity} ${item.unit}) - Job: ${item.jobNo ?? "General"}${item.prNo != null ? " - PR: ${item.prNo}" : ""}',
                        style: const TextStyle(fontSize: 12),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 2,
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          );
        },
      ),
      PlutoColumn(
        title: 'Actions',
        field: 'actions',
        type: PlutoColumnType.text(),
        enableEditingMode: false,
        width: 140,
        renderer: (rendererContext) {
          final dc = deliveryChallans.firstWhere(
            (dc) => dc.dcNo == rendererContext.cell.value,
          );
          return Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: Icon(Icons.picture_as_pdf, color: Colors.grey[300]),
                iconSize: 18,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(
                  minWidth: 28,
                  minHeight: 28,
                ),
                onPressed: () => _showPDFOptions(dc),
                tooltip: 'Generate DC PDF',
              ),
              IconButton(
                icon: Icon(Icons.delete, color: Colors.grey[300]),
                iconSize: 18,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(
                  minWidth: 32,
                  minHeight: 32,
                ),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      backgroundColor: Colors.grey[850],
                      title: Text(
                        'Delete Delivery Challan',
                        style: TextStyle(color: Colors.grey[200]),
                      ),
                      content: Text(
                        'Are you sure you want to delete this delivery challan?',
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
                              rendererContext.cell.value,
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
                },
                tooltip: 'Delete',
              ),
            ],
          );
        },
      ),
    ];

    final rows = deliveryChallans.map((dc) {
      return PlutoRow(cells: {
        'dcNo': PlutoCell(value: dc.dcNo),
        'date': PlutoCell(value: dc.dcDate),
        'vendor': PlutoCell(value: dc.vendorName),
        'gstin': PlutoCell(value: dc.vendorGstin ?? ''),
        'email': PlutoCell(value: dc.vendorEmail ?? ''),
        'returnable': PlutoCell(value: dc.isReturnable ? 'Yes' : 'No'),
        'note': PlutoCell(value: dc.note ?? ''),
        'items': PlutoCell(value: dc.dcNo),
        'actions': PlutoCell(value: dc.dcNo),
      });
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Job Order Delivery Challans'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AddDeliveryChallanPage(),
                ),
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: PlutoGrid(
          columns: columns,
          rows: rows,
          onLoaded: (event) => event.stateManager.setShowColumnFilter(true),
          configuration: PlutoGridConfigurations.darkMode(),
        ),
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

  Future<void> _generateAndSavePDF(DeliveryChallan dc) async {
    try {
      final suppliers = ref.read(supplierListProvider);
      final supplier = suppliers.firstWhere(
        (s) => s.name == dc.vendorName,
        orElse: () => suppliers.isNotEmpty
            ? suppliers.first
            : throw Exception('No suppliers found'),
      );

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

      final materials = ref.read(materialListProvider);
      final success = await PDFService.saveDeliveryChallan(dc, supplier,
          materials: materials);

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
      final suppliers = ref.read(supplierListProvider);
      final supplier = suppliers.firstWhere(
        (s) => s.name == dc.vendorName,
        orElse: () => suppliers.isNotEmpty
            ? suppliers.first
            : throw Exception('No suppliers found'),
      );

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

      final materials = ref.read(materialListProvider);
      final success = await PDFService.saveDeliveryChallanToDownloads(
          dc, supplier,
          materials: materials);

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