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

class InvoiceGenerationPage extends ConsumerStatefulWidget {
  const InvoiceGenerationPage({super.key});

  @override
  ConsumerState<InvoiceGenerationPage> createState() => _InvoiceGenerationPageState();
}

class _InvoiceGenerationPageState extends ConsumerState<InvoiceGenerationPage> {
  @override
  Widget build(BuildContext context) {
    final deliveryChallans = ref.watch(deliveryChallanListProvider);

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
                icon: Icon(Icons.receipt, color: Colors.grey[300]),
                iconSize: 18,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(
                  minWidth: 28,
                  minHeight: 28,
                ),
                onPressed: () => _showInvoiceOptions(dc),
                tooltip: 'Generate Tax Invoice',
              ),
              IconButton(
                icon: Icon(Icons.receipt_long, color: Colors.grey[300]),
                iconSize: 18,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(
                  minWidth: 28,
                  minHeight: 28,
                ),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('E-Invoice generation will be available soon!'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                },
                tooltip: 'Generate E-Invoice (Coming Soon)',
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
        'items': PlutoCell(value: dc.dcNo),
        'actions': PlutoCell(value: dc.dcNo),
      });
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Invoice Generation'),
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

  void _showInvoiceOptions(DeliveryChallan dc) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[850],
        title: Text(
          'Generate Tax Invoice for ${dc.dcNo}',
          style: TextStyle(color: Colors.grey[200]),
        ),
        content: Text(
          'Choose how to save the Tax Invoice PDF:',
          style: TextStyle(color: Colors.grey[200]),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _generateAndSaveInvoiceToDownloads(dc);
            },
            child: Text(
              'Quick Save',
              style: TextStyle(color: Colors.grey[300]),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _generateAndSaveInvoice(dc);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
            ),
            child: const Text('Choose Location'),
          ),
        ],
      ),
    );
  }

  Future<void> _generateAndSaveInvoice(DeliveryChallan dc) async {
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
                'Preparing Tax Invoice PDF...',
                style: TextStyle(color: Colors.grey[200]),
              ),
            ],
          ),
        ),
      );

      final materials = ref.read(materialListProvider);
      final success = await PDFService.saveInvoice(dc, supplier,
          materials: materials);

      Navigator.pop(context); // Close loading dialog

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tax Invoice PDF saved successfully!'),
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
          content: Text('Error saving Tax Invoice PDF: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _generateAndSaveInvoiceToDownloads(DeliveryChallan dc) async {
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
                'Preparing Tax Invoice PDF...',
                style: TextStyle(color: Colors.grey[200]),
              ),
            ],
          ),
        ),
      );

      final materials = ref.read(materialListProvider);
      final success = await PDFService.saveInvoiceToDownloads(
          dc, supplier,
          materials: materials);

      Navigator.pop(context); // Close loading dialog

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(Platform.isMacOS || Platform.isIOS
                ? 'Tax Invoice PDF saved to Documents folder successfully!'
                : 'Tax Invoice PDF saved to Downloads folder successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to save Tax Invoice PDF to Downloads'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      Navigator.pop(context); // Close loading dialog
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving Tax Invoice PDF: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
