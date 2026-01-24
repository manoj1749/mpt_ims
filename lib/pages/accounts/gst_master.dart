import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/gst.dart';
import '../../provider/gst_provider.dart';
import 'add_gst_page.dart';

class GSTMasterPage extends ConsumerStatefulWidget {
  const GSTMasterPage({super.key});

  @override
  ConsumerState<GSTMasterPage> createState() => _GSTMasterPageState();
}

class _GSTMasterPageState extends ConsumerState<GSTMasterPage> {
  Set<int> expandedRows = {};
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  final double slNoWidth = 80.0;
  final double nameWidth = 300.0;
  final double codeWidth = 200.0;

  @override
  void initState() {
    super.initState();
    // Load GST data when page is opened
    Future.microtask(() => ref.read(gstListProvider.notifier).loadData());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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

  Widget _buildExpandableRow(GSTModel gst, int index) {
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
                _buildExcelCell('${index + 1}', width: slNoWidth, center: true),
                _buildExcelCell(gst.gstCategory, width: nameWidth),
                _buildExcelCell(
                    gst.gstRate.isNotEmpty
                        ? gst.gstRate
                        : '--',
                    width: codeWidth),
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
                _buildExcelRowLabel("GST Rate", gst.gstRate),
                _buildExcelRowLabel("CGST %", gst.cgst),
                _buildExcelRowLabel("SGST %", gst.sgst),
                _buildExcelRowLabel("IGST %", gst.igst),
                _buildExcelRowLabel("Description", gst.description),
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
                            builder: (_) => AddGSTPage(
                              gstToEdit: gst,
                              index: ref
                                  .read(gstListProvider)
                                  .indexOf(gst),
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
                      onPressed: () => _confirmDelete(context, gst),
                    ),
                  ],
                ),
              ],
            ),
          ),
      ],
    );
  }

  void _confirmDelete(BuildContext context, GSTModel gst) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete GST'),
        content: Text('Are you sure you want to delete ${gst.gstCategory}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              ref.read(gstListProvider.notifier).delete(gst);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('GST deleted')),
              );
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final gstList = ref.watch(gstListProvider);
    final filteredGST = _searchQuery.isEmpty
        ? gstList
        : ref.read(gstListProvider.notifier).searchGST(_searchQuery);

    // Separate CGST+SGST rates from IGST rates
    final cgstSgstRates = filteredGST.where((gst) {
      final cgst = double.tryParse(gst.cgst) ?? 0;
      final sgst = double.tryParse(gst.sgst) ?? 0;
      return cgst > 0 || sgst > 0;
    }).toList();

    final igstRates = filteredGST.where((gst) {
      final igst = double.tryParse(gst.igst) ?? 0;
      return igst > 0;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('GST Master'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(gstListProvider.notifier).refresh(),
            tooltip: 'Refresh',
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AddGSTPage()),
            ),
            tooltip: 'Add GST Rate',
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                labelText: 'Search GST Rates',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (value) => setState(() => _searchQuery = value),
            ),
          ),
          if (filteredGST.isEmpty)
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _searchQuery.isEmpty
                          ? 'No GST entries yet'
                          : 'No GST entries found',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.grey[600],
                      ),
                    ),
                    if (_searchQuery.isEmpty) ...[
                      const SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const AddGSTPage()),
                        ),
                        child: const Text('Add New GST'),
                      ),
                    ]
                  ],
                ),
              ),
            )
          else
            Expanded(
              child: ListView(
                children: [
                  // CGST + SGST Section
                  if (cgstSgstRates.isNotEmpty) ...[
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        'CGST + SGST Rates',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                            ),
                      ),
                    ),
                    Container(
                      color: Colors.black,
                      child: Row(
                        children: [
                          _buildExcelCell('Sl No',
                              width: slNoWidth, center: true),
                          _buildExcelCell('GST Category', width: nameWidth),
                          _buildExcelCell('GST Rate', width: codeWidth),
                          Container(
                            width: 40,
                            height: 44,
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade700),
                            ),
                          ),
                        ],
                      ),
                    ),
                    ...cgstSgstRates.asMap().entries.map((entry) {
                      return _buildExpandableRow(entry.value, entry.key);
                    }),
                    const SizedBox(height: 24),
                  ],
                  // IGST Section
                  if (igstRates.isNotEmpty) ...[
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        'IGST Rates',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.orange,
                            ),
                      ),
                    ),
                    Container(
                      color: Colors.black,
                      child: Row(
                        children: [
                          _buildExcelCell('Sl No',
                              width: slNoWidth, center: true),
                          _buildExcelCell('GST Category', width: nameWidth),
                          _buildExcelCell('GST Rate', width: codeWidth),
                          Container(
                            width: 40,
                            height: 44,
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade700),
                            ),
                          ),
                        ],
                      ),
                    ),
                    ...igstRates.asMap().entries.map((entry) {
                      return _buildExpandableRow(entry.value, entry.key);
                    }),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }
}
