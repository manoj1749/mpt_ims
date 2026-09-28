import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pluto_grid/pluto_grid.dart';
import '../../models/bill_of_preparation.dart';
import '../../provider/bill_of_preparation_provider.dart';
import '../../widgets/pluto_grid_configuration.dart';
import 'add_bill_of_preparation_page.dart';

class BopMaterialDetailsPage extends ConsumerStatefulWidget {
  final BillOfPreparation bop;

  const BopMaterialDetailsPage({
    super.key,
    required this.bop,
  });

  @override
  ConsumerState<BopMaterialDetailsPage> createState() =>
      _BopMaterialDetailsPageState();
}

class _BopMaterialDetailsPageState
    extends ConsumerState<BopMaterialDetailsPage> {
  String? _selectedCktType;
  bool _isReloading = false;

  Future<void> _reloadBop() async {
    if (_isReloading) return;
    setState(() => _isReloading = true);
    try {
      await ref.read(billOfPreparationProvider.notifier).loadData();
    } finally {
      if (mounted) {
        setState(() => _isReloading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Watch the BOP provider for real-time updates
    final bops = ref.watch(billOfPreparationProvider);

    // Find the current BOP from the provider (it might have been updated)
    final currentBop = bops.firstWhere(
      (b) =>
          b.jobNo == widget.bop.jobNo &&
          b.createdDate == widget.bop.createdDate,
      orElse: () => widget.bop, // Fallback to original if not found
    );

    // Collect all unique CKT type names from materials
    final Set<String> uniqueCktTypes = <String>{};
    for (final material in currentBop.materials) {
      for (final materialCktType in material.cktTypes) {
        if (materialCktType.cktTypeName.isNotEmpty) {
          uniqueCktTypes.add(materialCktType.cktTypeName);
        }
      }
    }
    final sortedCktTypes = uniqueCktTypes.toList()..sort();

    final selectedCktType =
        sortedCktTypes.contains(_selectedCktType) ? _selectedCktType : null;
    final visibleCktTypes =
        selectedCktType == null ? sortedCktTypes : <String>[selectedCktType];

    return Scaffold(
      appBar: AppBar(
        title: Text('Materials for ${currentBop.jobNo}'),
        backgroundColor: Colors.grey[850],
        actions: [
          IconButton(
            onPressed: _isReloading ? null : _reloadBop,
            tooltip: 'Reload BOP data and totals',
            icon: _isReloading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(
              children: [
                const Text('Show materials with CKT quantity greater than 0:'),
                const SizedBox(width: 12),
                SizedBox(
                  width: 240,
                  child: DropdownButtonFormField<String?>(
                    value: selectedCktType,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'CKT Type',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    items: [
                      const DropdownMenuItem<String?>(
                        value: null,
                        child: Text('All CKT Types'),
                      ),
                      ...sortedCktTypes.map(
                        (cktType) => DropdownMenuItem<String?>(
                          value: cktType,
                          child: Text(cktType),
                        ),
                      ),
                    ],
                    onChanged: (value) {
                      setState(() => _selectedCktType = value);
                    },
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: PlutoGrid(
              key: UniqueKey(),
              columns: _buildColumns(visibleCktTypes, currentBop, context),
              rows: _getRows(visibleCktTypes, currentBop, selectedCktType),
              configuration: PlutoGridConfigurations.darkMode(),
              onLoaded: (PlutoGridOnLoadedEvent event) {
                event.stateManager.setShowColumnFilter(true);
                event.stateManager
                    .setSelectingMode(PlutoGridSelectingMode.none);
              },
            ),
          ),
        ],
      ),
    );
  }

  List<PlutoColumn> _buildColumns(
      List<String> cktTypes, BillOfPreparation bop, BuildContext context) {
    final columns = [
      PlutoColumn(
        title: 'S.No',
        field: 'serialNo',
        type: PlutoColumnType.number(),
        width: 80,
        backgroundColor: Colors.grey[850],
        titleTextAlign: PlutoColumnTextAlign.center,
        textAlign: PlutoColumnTextAlign.center,
        enableEditingMode: false,
      ),
      PlutoColumn(
        title: 'Material Code',
        field: 'materialCode',
        type: PlutoColumnType.text(),
        width: 150,
        backgroundColor: Colors.grey[850],
        enableEditingMode: false,
      ),
      PlutoColumn(
        title: 'Material Description',
        field: 'materialDescription',
        type: PlutoColumnType.text(),
        width: 300,
        backgroundColor: Colors.grey[850],
        enableEditingMode: false,
      ),
      PlutoColumn(
        title: 'Material Source',
        field: 'materialSource',
        type: PlutoColumnType.text(),
        width: 200,
        backgroundColor: Colors.grey[850],
        enableEditingMode: false,
      ),
    ];

    // Add CKT type columns with quantities
    for (final cktType in cktTypes) {
      String title = cktType;
      // Find the CKT type quantity from the BOP
      for (final bopCktType in bop.cktTypes) {
        if (bopCktType.name == cktType) {
          title = '$cktType (${bopCktType.quantity})';
          break;
        }
      }

      columns.add(PlutoColumn(
        title: title,
        titleSpan: TextSpan(
          children: [
            TextSpan(text: title),
            const WidgetSpan(child: SizedBox(width: 6)),
            WidgetSpan(
              alignment: PlaceholderAlignment.middle,
              child: GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AddBillOfPreparationPage(
                        existingBop: bop,
                        index: null,
                        cktTypeFilter: cktType,
                      ),
                    ),
                  );
                },
                child: const Icon(
                  Icons.edit,
                  size: 16,
                  color: Colors.blue,
                ),
              ),
            ),
          ],
        ),
        field: 'ckt_$cktType',
        type: PlutoColumnType.number(),
        width: 150,
        backgroundColor: Colors.grey[850],
        titleTextAlign: PlutoColumnTextAlign.center,
        textAlign: PlutoColumnTextAlign.center,
        enableEditingMode: false,
      ));
    }

    columns.add(
      PlutoColumn(
        title: 'Sum Total',
        field: 'sumTotal',
        type: PlutoColumnType.number(),
        width: 140,
        backgroundColor: Colors.grey[850],
        titleTextAlign: PlutoColumnTextAlign.center,
        textAlign: PlutoColumnTextAlign.center,
        enableEditingMode: false,
      ),
    );

    return columns;
  }

  List<PlutoRow> _getRows(
      List<String> cktTypes, BillOfPreparation bop, String? selectedCktType) {
    final materials = selectedCktType == null
        ? bop.materials
        : bop.materials.where((material) {
            return material.cktTypes.any((ckt) =>
                ckt.cktTypeName == selectedCktType && ckt.materialQuantity > 0);
          }).toList();

    return materials.asMap().entries.map((entry) {
      final index = entry.key;
      final material = entry.value;

      final displaySource = material.materialSource == 'material_master'
          ? 'Material Master'
          : material.materialSource == 'customer_scope'
              ? 'Customer Free Issue'
              : material.materialSource;

      final Map<String, PlutoCell> cells = {
        'serialNo': PlutoCell(value: index + 1),
        'materialCode': PlutoCell(value: material.materialCode),
        'materialDescription': PlutoCell(value: material.materialDescription),
        'materialSource': PlutoCell(value: displaySource),
      };

      var sumTotal = 0.0;

      // Show the extended value for each CKT column: material quantity * CKT quantity.
      for (final cktType in cktTypes) {
        final matchingMaterialCktTypes = material.cktTypes
            .where((ckt) => ckt.cktTypeName == cktType)
            .toList();
        final extendedValue = matchingMaterialCktTypes.fold<double>(
            0.0,
            (total, ckt) =>
                total + (ckt.cktTypeQuantity * ckt.materialQuantity));
        final materialQuantity = matchingMaterialCktTypes.fold<double>(
            0.0, (total, ckt) => total + ckt.materialQuantity);
        cells['ckt_$cktType'] = PlutoCell(value: materialQuantity);
        sumTotal += extendedValue;
      }

      cells['sumTotal'] = PlutoCell(value: sumTotal);

      return PlutoRow(cells: cells);
    }).toList();
  }
}
