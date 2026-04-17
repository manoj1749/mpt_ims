import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pluto_grid/pluto_grid.dart';
import '../../models/delivery_challan.dart';
import '../../models/supplier.dart';
import '../../provider/delivery_challan_provider.dart';
import '../../provider/supplier_provider.dart';
import '../../provider/material_provider.dart';
import '../../services/pdf_service.dart';
import '../../widgets/pluto_grid_configuration.dart';
import 'add_delivery_challan_page.dart';

class InternalInwardDeliveryChallanListPage extends ConsumerStatefulWidget {
  const InternalInwardDeliveryChallanListPage({super.key});

  @override
  ConsumerState<InternalInwardDeliveryChallanListPage> createState() =>
      _InternalInwardDeliveryChallanListPageState();
}

class _InternalInwardDeliveryChallanListPageState
    extends ConsumerState<InternalInwardDeliveryChallanListPage> {
  PlutoGridStateManager? _stateManager;
  ProviderSubscription<List<DeliveryChallan>>? _dcSub;
  ProviderSubscription<List<Supplier>>? _supplierSub;

  void _refreshGridRows({
    List<DeliveryChallan>? deliveryChallans,
    List<Supplier>? suppliers,
  }) {
    if (_stateManager == null) {
      return;
    }

    final sourceDcs =
        (deliveryChallans ?? ref.read(deliveryChallanListProvider)) ??
            <DeliveryChallan>[];
    final sourceSuppliers =
        (suppliers ?? ref.read(supplierListProvider)) ?? <Supplier>[];

    final dcs = sourceDcs
        .where((dc) => dc.dcType == 'internal' && dc.internalFlow == 'inward')
        .toList();

    final rowsNow = _buildRows(dcs, sourceSuppliers);
    _stateManager!
      ..removeAllRows()
      ..appendRows(rowsNow);
  }

  @override
  void initState() {
    super.initState();

    _dcSub = ref.listenManual<List<DeliveryChallan>>(
      deliveryChallanListProvider,
      (previous, next) {
        _refreshGridRows(deliveryChallans: next);
      },
    );

    _supplierSub = ref.listenManual<List<Supplier>>(
      supplierListProvider,
      (previous, next) {
        _refreshGridRows(suppliers: next);
      },
    );
  }

  @override
  void dispose() {
    _dcSub?.close();
    _supplierSub?.close();
    super.dispose();
  }

  List<PlutoRow> _buildRows(
    List<DeliveryChallan> deliveryChallans,
    List<Supplier> suppliers,
  ) {
    return deliveryChallans.map((dc) {
      final fromVendor = (dc.fromVendor ?? '').trim();
      final toVendor = (dc.toVendor ?? '').trim();
      final counterpartyName = fromVendor;
      Supplier? counterparty;
      if (counterpartyName.isNotEmpty) {
        try {
          counterparty = suppliers.firstWhere((s) => s.name == counterpartyName);
        } catch (_) {
          counterparty = null;
        }
      }

      final totalPrice = dc.items.fold<double>(
        0.0,
        (sum, item) => sum + (item.price * item.quantity),
      );

      final gstin = (dc.vendorGstin ?? '').trim().isNotEmpty
          ? (dc.vendorGstin ?? '')
          : (counterparty?.gstNo ?? '');
      final email = (dc.vendorEmail ?? '').trim().isNotEmpty
          ? (dc.vendorEmail ?? '')
          : (counterparty?.email ?? '');

      // Build text representations for Items, Quantities, and Prices
      final itemsText = dc.items
          .map((item) =>
              '${item.materialCode} - ${item.materialDescription} (Job: ${item.jobNo ?? "General"}${item.prNo != null ? " | PR: ${item.prNo}" : ""})')
          .join('\n');

      final quantitiesText = dc.items
          .map((item) => '${item.quantity} ${item.unit}')
          .join('\n');

      final pricesText = dc.items
          .map((item) =>
              'Unit: ₹${item.price.toStringAsFixed(2)} | Total: ₹${(item.quantity * item.price).toStringAsFixed(2)}')
          .join('\n');

      return PlutoRow(cells: {
        'dcNo': PlutoCell(value: dc.dcNo),
        'date': PlutoCell(value: dc.dcDate),
        'fromVendor': PlutoCell(value: fromVendor),
        'toVendor': PlutoCell(value: toVendor),
        'gstin': PlutoCell(value: gstin),
        'email': PlutoCell(value: email),
        'items': PlutoCell(value: itemsText),
        'quantities': PlutoCell(value: quantitiesText),
        'prices': PlutoCell(value: pricesText),
        'totalPrice': PlutoCell(value: totalPrice.toStringAsFixed(2)),
        'returnable': PlutoCell(value: dc.isReturnable ? 'Yes' : 'No'),
        'note': PlutoCell(value: dc.note ?? ''),
        'actions': PlutoCell(value: dc),
      });
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final allDeliveryChallans = ref.watch(deliveryChallanListProvider);
    final suppliers = ref.watch(supplierListProvider);
    // Filter for internal inward delivery challans only
    final deliveryChallans = allDeliveryChallans
        .where((dc) => dc.dcType == 'internal' && dc.internalFlow == 'inward')
        .toList();

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
        title: 'From Vendor',
        field: 'fromVendor',
        type: PlutoColumnType.text(),
        enableEditingMode: false,
        width: 150,
      ),
      PlutoColumn(
        title: 'To Vendor',
        field: 'toVendor',
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
        width: 350,
        renderer: (rendererContext) {
          final itemsText = rendererContext.cell.value as String;
          return Container(
            constraints: const BoxConstraints(maxHeight: 200),
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
                child: Text(
                  itemsText,
                  style: const TextStyle(fontSize: 12),
                  maxLines: null,
                  softWrap: true,
                ),
              ),
            ),
          );
        },
      ),
      PlutoColumn(
        title: 'Quantities',
        field: 'quantities',
        type: PlutoColumnType.text(),
        enableEditingMode: false,
        width: 120,
        renderer: (rendererContext) {
          final quantitiesText = rendererContext.cell.value as String;
          return Container(
            constraints: const BoxConstraints(maxHeight: 200),
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
                child: Text(
                  quantitiesText,
                  style: const TextStyle(fontSize: 12),
                ),
              ),
            ),
          );
        },
      ),
      PlutoColumn(
        title: 'Individual Prices',
        field: 'prices',
        type: PlutoColumnType.text(),
        enableEditingMode: false,
        width: 200,
        renderer: (rendererContext) {
          final pricesText = rendererContext.cell.value as String;
          return Container(
            constraints: const BoxConstraints(maxHeight: 200),
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
                child: Text(
                  pricesText,
                  style: const TextStyle(fontSize: 12),
                ),
              ),
            ),
          );
        },
      ),
      PlutoColumn(
        title: 'Total Price',
        field: 'totalPrice',
        type: PlutoColumnType.text(),
        enableEditingMode: false,
        width: 120,
        titleTextAlign: PlutoColumnTextAlign.right,
        textAlign: PlutoColumnTextAlign.right,
        renderer: (rendererContext) {
          final value = rendererContext.cell.value;
          return Text(
            value == null || value.toString().isEmpty ? '0.00' : value.toString(),
            textAlign: TextAlign.right,
            style: const TextStyle(fontSize: 12),
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
          final dc = rendererContext.cell.value as DeliveryChallan;
          return Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: Icon(Icons.edit, color: Colors.grey[300]),
                iconSize: 18,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(
                  minWidth: 28,
                  minHeight: 28,
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AddDeliveryChallanPage(
                        deliveryChallan: dc,
                        presetDcType: 'internal',
                        presetInternalFlow: 'inward',
                      ),
                    ),
                  );
                },
                tooltip: 'Edit',
              ),
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
                },
                tooltip: 'Delete',
              ),
            ],
          );
        },
      ),
    ];

    final rows = _buildRows(deliveryChallans, suppliers);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Internal Delivery Challans - Inward'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AddDeliveryChallanPage(
                    presetDcType: 'internal',
                    presetInternalFlow: 'inward',
                  ),
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
          onLoaded: (event) {
            _stateManager = event.stateManager;
            event.stateManager.setShowColumnFilter(true);
            _refreshGridRows();
          },
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
