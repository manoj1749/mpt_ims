import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mpt_ims/models/supplier.dart';
import 'package:mpt_ims/provider/service_supplier_provider.dart';
import 'package:mpt_ims/pages/accounts/add_service_supplier_page.dart';
import 'package:mpt_ims/provider/material_rating_rule_provider.dart';
import 'package:mpt_ims/models/material_rating_rule.dart';
import 'package:open_file/open_file.dart';

class ServiceSupplierMasterPage extends ConsumerStatefulWidget {
  const ServiceSupplierMasterPage({super.key});

  @override
  ConsumerState<ServiceSupplierMasterPage> createState() =>
      _ServiceSupplierMasterPageState();
}

class _ServiceSupplierMasterPageState
    extends ConsumerState<ServiceSupplierMasterPage> {
  Set<int> expandedRows = {};

  final double slNoWidth = 80.0;
  final double nameWidth = 300.0;
  final double codeWidth = 200.0;
  final double ratingWidth = 150.0;

  Widget _buildDataCell(String text,
      {bool isHeader = false, required double width}) {
    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        border: Border(
          right: BorderSide(color: Colors.grey[300]!),
          bottom: BorderSide(color: Colors.grey[300]!),
        ),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontWeight: isHeader ? FontWeight.bold : FontWeight.normal,
          fontSize: 14,
        ),
      ),
    );
  }

  Widget _buildExcelCell(String text,
      {double width = 150, bool center = false}) {
    return Container(
      width: width,
      height: 44,
      alignment: center ? Alignment.center : Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade700, width: 1),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 13,
        ),
      ),
    );
  }

  Widget _buildExcelRowLabel(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 160,
            child: Text(
              label,
              style: const TextStyle(
                  fontWeight: FontWeight.w500, color: Colors.white),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRatingCell(double rating, {required double width}) {
    return Container(
      width: width,
      height: 44,
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade700, width: 1),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildStarRating(rating, size: 16),
          const SizedBox(width: 8),
          Text(
            rating.toStringAsFixed(1),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStarRating(double rating, {double size = 20}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        final shouldBeFull = index < rating.floor();
        final shouldBeHalf = index < rating && index >= rating.floor();

        if (shouldBeFull) {
          return Icon(Icons.star, color: Colors.amber, size: size);
        } else if (shouldBeHalf) {
          return Icon(Icons.star_half, color: Colors.amber, size: size);
        } else {
          return Icon(Icons.star_border, color: Colors.amber, size: size);
        }
      }),
    );
  }

  Widget _buildExcelRow(Supplier supplier, int index) {
    final isExpanded = expandedRows.contains(index);

    return Column(
      children: [
        InkWell(
          onTap: () {
            setState(() {
              if (isExpanded) {
                expandedRows.remove(index);
              } else {
                expandedRows.add(index);
              }
            });
          },
          child: Container(
            color: index.isEven
                ? const Color(0xFF121212)
                : const Color(0xFF1E1E1E),
            child: Row(
              children: [
                _buildExcelCell('${index + 1}', width: 80, center: true),
                _buildExcelCell(supplier.name, width: 300),
                _buildRatingCell(supplier.qualityRating ?? 0.0, width: 150),
                _buildExcelCell(
                    supplier.vendorCode.isNotEmpty ? supplier.vendorCode : '--',
                    width: 180),
                Container(
                  width: 40,
                  height: 44,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade700),
                  ),
                  child: Icon(
                    isExpanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ],
            ),
          ),
        ),
        if (isExpanded)
          Container(
            color: const Color(0xFF1A1A1A),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildExcelRowLabel(
                    "Address",
                    [
                      supplier.address1,
                      supplier.address2,
                      supplier.address3,
                      supplier.address4
                    ].where((e) => e.isNotEmpty).join(', ')),
                _buildExcelRowLabel("State", supplier.state),
                _buildExcelRowLabel("State Code", supplier.stateCode),
                _buildExcelRowLabel("PAN", supplier.pan),
                _buildExcelRowLabel("GST No", supplier.gstNo),
                _buildExcelRowLabel("IGST %", supplier.igst),
                _buildExcelRowLabel("CGST %", supplier.cgst),
                _buildExcelRowLabel("SGST %", supplier.sgst),
                _buildExcelRowLabel("Total GST", supplier.totalGst),
                _buildExcelRowLabel("Contact Person", supplier.contact),
                _buildExcelRowLabel("Phone", supplier.phone),
                _buildExcelRowLabel("Email", supplier.email),
                _buildExcelRowLabel("Alt Email", supplier.email1),
                _buildExcelRowLabel("Bank", supplier.bank),
                _buildExcelRowLabel("Branch", supplier.branch),
                _buildExcelRowLabel("Account No", supplier.account),
                _buildExcelRowLabel("IFSC Code", supplier.ifsc),
                _buildExcelRowLabel("Payment Terms", supplier.paymentTerms),
                if ((supplier.attachments ?? []).isNotEmpty) ...[
                  const SizedBox(height: 8),
                  const Text(
                    'Attachments',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: (supplier.attachments ?? []).map((p) {
                      final name = p.split('\\').isNotEmpty
                          ? p.split('\\').last
                          : p.split('/').last;
                      final ext = name.split('.').length > 1
                          ? name.split('.').last.toLowerCase()
                          : '';
                      final icon = ext == 'pdf'
                          ? Icons.picture_as_pdf
                          : Icons.description;
                      return InkWell(
                        onTap: () => _showAttachmentViewer(context, p, name),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Row(
                            children: [
                              Icon(icon, size: 16, color: Colors.grey[400]),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  name,
                                  style: const TextStyle(color: Colors.white),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Icon(Icons.open_in_new,
                                  size: 14, color: Colors.grey[500]),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      const SizedBox(
                        width: 160,
                        child: Text(
                          "Quality Rating",
                          style: TextStyle(
                              fontWeight: FontWeight.w500,
                              color: Colors.white),
                        ),
                      ),
                      Expanded(
                        child: Row(
                          children: [
                            _buildStarRating(supplier.qualityRating ?? 0.0),
                            const SizedBox(width: 8),
                            Text(
                              '${(supplier.qualityRating ?? 0.0).toStringAsFixed(1)}/5.0',
                              style: const TextStyle(color: Colors.white),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton.icon(
                      icon: const Icon(Icons.edit, color: Colors.white),
                      label: const Text("Edit",
                          style: TextStyle(color: Colors.white)),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => AddServiceSupplierPage(
                              supplierToEdit: supplier,
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(width: 8),
                    TextButton.icon(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      label: const Text("Delete",
                          style: TextStyle(color: Colors.red)),
                      onPressed: () => _confirmDeleteSupplier(supplier),
                    ),
                  ],
                ),
              ],
            ),
          ),
      ],
    );
  }

  void _showAttachmentViewer(
      BuildContext context, String filePath, String fileName) {
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
                            const Icon(Icons.picture_as_pdf,
                                size: 64, color: Colors.red),
                            const SizedBox(height: 16),
                            Text(
                              'PDF Viewer',
                              style: TextStyle(
                                  fontSize: 16, color: Colors.grey[600]),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'File: $fileName',
                              style: TextStyle(
                                  fontSize: 14, color: Colors.grey[500]),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              onPressed: () async {
                                try {
                                  final result =
                                      await OpenFile.open(filePath);
                                  if (result.type != ResultType.done &&
                                      context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                          content:
                                              Text('Error: ${result.message}')),
                                    );
                                  }
                                } catch (e) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                          content:
                                              Text('Error opening file: $e')),
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
                            const Icon(Icons.description,
                                size: 64, color: Colors.blue),
                            const SizedBox(height: 16),
                            Text(
                              'Document Viewer',
                              style: TextStyle(
                                  fontSize: 16, color: Colors.grey[600]),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'File: $fileName',
                              style: TextStyle(
                                  fontSize: 14, color: Colors.grey[500]),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              onPressed: () async {
                                try {
                                  final result =
                                      await OpenFile.open(filePath);
                                  if (result.type != ResultType.done &&
                                      context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                          content:
                                              Text('Error: ${result.message}')),
                                    );
                                  }
                                } catch (e) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                          content:
                                              Text('Error opening file: $e')),
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

  void _confirmDeleteSupplier(Supplier supplier) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Service Supplier'),
        content: Text('Are you sure you want to delete ${supplier.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              ref
                  .read(serviceSupplierListProvider.notifier)
                  .deleteServiceSupplier(supplier);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Service supplier deleted')),
              );
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _openConfigureSlabsDialog() async {
    final supplierCodeController = TextEditingController();
    final supplierNameController = TextEditingController();
    List<Supplier> filteredSuppliers = [];
    bool showSupplierSuggestions = false;
    String activeSupplierField = 'code';
    final partialController = TextEditingController(
        text: '0-5=4.5\n5.01-10=4.0\n10.01-20=3.0\n20.01-30=2.0\n30.01-100=1.0');
    final recheckController = TextEditingController(
        text: '0-5=3.0\n5.01-10=2.5\n10.01-20=2.0\n20.01-100=1.5');
    final lotAcceptedController = TextEditingController(text: '5');
    final lotRejectedController = TextEditingController(text: '0');

    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Configure Rating Slabs'),
          content: SizedBox(
            width: 600,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  StatefulBuilder(
                    builder: (context, setState) {
                      final suppliers = ref.read(serviceSupplierListProvider);
                      void onCodeChanged(String value) {
                        setState(() {
                          activeSupplierField = 'code';
                          if (value.isEmpty) {
                            filteredSuppliers = [];
                            showSupplierSuggestions = false;
                          } else {
                            filteredSuppliers = suppliers
                                .where((s) => s.vendorCode
                                    .toLowerCase()
                                    .contains(value.toLowerCase()))
                                .take(8)
                                .toList();
                            showSupplierSuggestions = true;
                          }
                        });
                        final exact = suppliers
                            .where((s) =>
                                s.vendorCode.toLowerCase() == value.toLowerCase())
                            .firstOrNull;
                        if (exact != null) {
                          setState(() {
                            supplierNameController.text = exact.name;
                            showSupplierSuggestions = false;
                          });
                        }
                      }

                      void onNameChanged(String value) {
                        setState(() {
                          activeSupplierField = 'name';
                          if (value.isEmpty) {
                            filteredSuppliers = [];
                            showSupplierSuggestions = false;
                          } else {
                            filteredSuppliers = suppliers
                                .where((s) => s.name
                                    .toLowerCase()
                                    .contains(value.toLowerCase()))
                                .take(8)
                                .toList();
                            showSupplierSuggestions = true;
                          }
                        });
                        final exact = suppliers
                            .where((s) => s.name.toLowerCase() == value.toLowerCase())
                            .firstOrNull;
                        if (exact != null) {
                          setState(() {
                            supplierCodeController.text = exact.vendorCode;
                            showSupplierSuggestions = false;
                          });
                        }
                      }

                      void selectSupplier(Supplier s) {
                        setState(() {
                          supplierCodeController.text = s.vendorCode;
                          supplierNameController.text = s.name;
                          showSupplierSuggestions = false;
                        });
                      }

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: supplierCodeController,
                                  decoration: const InputDecoration(
                                    labelText: 'Supplier Code',
                                    border: OutlineInputBorder(),
                                    suffixIcon: Icon(Icons.search),
                                  ),
                                  onChanged: onCodeChanged,
                                  onTap: () {
                                    if (supplierCodeController.text.isNotEmpty) {
                                      onCodeChanged(supplierCodeController.text);
                                    }
                                  },
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextField(
                                  controller: supplierNameController,
                                  decoration: const InputDecoration(
                                    labelText: 'Supplier Name',
                                    border: OutlineInputBorder(),
                                    suffixIcon: Icon(Icons.search),
                                  ),
                                  onChanged: onNameChanged,
                                  onTap: () {
                                    if (supplierNameController.text.isNotEmpty) {
                                      onNameChanged(supplierNameController.text);
                                    }
                                  },
                                ),
                              ),
                            ],
                          ),
                          if (showSupplierSuggestions)
                            Container(
                              margin: const EdgeInsets.only(top: 6),
                              constraints: const BoxConstraints(maxHeight: 220),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey.shade700),
                                borderRadius: BorderRadius.circular(4),
                                color: Colors.black,
                              ),
                              child: filteredSuppliers.isNotEmpty
                                  ? ListView.builder(
                                      itemCount: filteredSuppliers.length,
                                      itemBuilder: (context, i) {
                                        final s = filteredSuppliers[i];
                                        return ListTile(
                                          dense: true,
                                          title: Text(
                                            s.name,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          subtitle: Text(
                                            s.vendorCode,
                                            style: TextStyle(
                                              color: Colors.grey.shade300,
                                            ),
                                          ),
                                          onTap: () => selectSupplier(s),
                                        );
                                      },
                                    )
                                  : Container(
                                      padding: const EdgeInsets.all(12),
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.info_outline,
                                            color: Colors.grey.shade400,
                                            size: 18,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            'No suppliers found',
                                            style: TextStyle(
                                              color: Colors.grey.shade300,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                            ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: lotAcceptedController,
                    decoration: const InputDecoration(
                      labelText: 'Lot Accepted Rating',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: lotRejectedController,
                    decoration: const InputDecoration(
                      labelText: 'Lot Rejected Rating',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                      'Partial Acceptance Slabs (min-max=rating per line)'),
                  const SizedBox(height: 6),
                  TextField(
                    controller: partialController,
                    maxLines: 6,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text('100% Recheck Slabs (min-max=rating per line)'),
                  const SizedBox(height: 6),
                  TextField(
                    controller: recheckController,
                    maxLines: 6,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                final code = supplierCodeController.text.trim();
                if (code.isEmpty) return;

                List<RatingRange> parseSlabs(String text) {
                  final lines = text.split('\n');
                  final slabs = <RatingRange>[];
                  for (final raw in lines) {
                    final line = raw.trim();
                    if (line.isEmpty) continue;
                    final parts = line.split('=');
                    if (parts.length != 2) continue;
                    final range = parts[0].split('-');
                    if (range.length != 2) continue;
                    final minP = double.tryParse(range[0].trim());
                    final maxP = double.tryParse(range[1].trim());
                    final rating = double.tryParse(parts[1].trim());
                    if (minP == null || maxP == null || rating == null) continue;
                    slabs.add(
                        RatingRange(minPercent: minP, maxPercent: maxP, rating: rating));
                  }
                  return slabs;
                }

                final partial = parseSlabs(partialController.text);
                final recheck = parseSlabs(recheckController.text);
                final lotAcc =
                    double.tryParse(lotAcceptedController.text.trim()) ?? 5.0;
                final lotRej =
                    double.tryParse(lotRejectedController.text.trim()) ?? 0.0;

                final rule = MaterialRatingRule(
                  materialCode: code,
                  lotAcceptedRating: lotAcc,
                  lotRejectedRating: lotRej,
                  partialAcceptanceSlabs: partial.isNotEmpty ? partial : null,
                  recheck100Slabs: recheck.isNotEmpty ? recheck : null,
                );

                await ref.read(materialRatingRuleProvider.notifier).upsertRule(rule);
                if (mounted) {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Rating slabs saved')),
                  );
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final suppliers = ref.watch(serviceSupplierListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Service Supplier Master'),
        actions: [
          TextButton.icon(
            onPressed: () => _openConfigureSlabsDialog(),
            icon: const Icon(Icons.tune, color: Colors.white),
            label: const Text('Configure Slabs',
                style: TextStyle(color: Colors.white)),
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AddServiceSupplierPage()),
            ),
            tooltip: 'Add Service Supplier',
          ),
        ],
      ),
      body: suppliers.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'No service suppliers yet',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const AddServiceSupplierPage()),
                    ),
                    child: const Text('Add New Service Supplier'),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                Container(
                  color: Colors.black,
                  child: Row(
                    children: [
                      _buildDataCell('Sl No', isHeader: true, width: slNoWidth),
                      _buildDataCell('Supplier Name',
                          isHeader: true, width: nameWidth),
                      _buildDataCell('Quality Rating',
                          isHeader: true, width: ratingWidth),
                      _buildDataCell('Supplier Code',
                          isHeader: true, width: codeWidth),
                      const SizedBox(width: 36),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: suppliers.length,
                    itemBuilder: (context, index) => _buildExcelRow(
                      suppliers[index],
                      index,
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
