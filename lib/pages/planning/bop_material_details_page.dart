import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pluto_grid/pluto_grid.dart';
import '../../models/bill_of_preparation.dart';
import '../../provider/bill_of_preparation_provider.dart';
import '../../widgets/pluto_grid_configuration.dart';
import 'add_bill_of_preparation_page.dart';

class BopMaterialDetailsPage extends ConsumerWidget {
  final BillOfPreparation bop;

  const BopMaterialDetailsPage({
    super.key,
    required this.bop,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch the BOP provider for real-time updates
    final bops = ref.watch(billOfPreparationProvider);
    
    // Find the current BOP from the provider (it might have been updated)
    final currentBop = bops.firstWhere(
      (b) => b.jobNo == bop.jobNo,
      orElse: () => bop, // Fallback to original if not found
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

    return Scaffold(
      appBar: AppBar(
        title: Text('Materials for ${currentBop.jobNo}'),
        backgroundColor: Colors.grey[850],
      ),
      body: PlutoGrid(
        key: ValueKey('${currentBop.jobNo}_${currentBop.materials.length}'),
        columns: _buildColumns(sortedCktTypes, currentBop, context),
        rows: _getRows(sortedCktTypes, currentBop),
        configuration: PlutoGridConfigurations.darkMode(),
        onLoaded: (PlutoGridOnLoadedEvent event) {
          event.stateManager.setShowColumnFilter(true);
          event.stateManager.setSelectingMode(PlutoGridSelectingMode.none);
        },
      ),
    );
  }

  List<PlutoColumn> _buildColumns(List<String> cktTypes, BillOfPreparation bop, BuildContext context) {
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

    return columns;
  }

  List<PlutoRow> _getRows(List<String> cktTypes, BillOfPreparation bop) {
    return bop.materials.asMap().entries.map((entry) {
      final index = entry.key;
      final material = entry.value;

      final displaySource = material.materialSource == 'material_master' ? 'Material Master' : 
                          material.materialSource == 'customer_scope' ? 'Customer Free Issue' : material.materialSource;
      
      final Map<String, PlutoCell> cells = {
        'serialNo': PlutoCell(value: index + 1),
        'materialCode': PlutoCell(value: material.materialCode),
        'materialDescription': PlutoCell(value: material.materialDescription),
        'materialSource': PlutoCell(value: displaySource),
      };

      // Add CKT type quantities
      for (final cktType in cktTypes) {
        final materialCktType = material.cktTypes
            .where((ckt) => ckt.cktTypeName == cktType)
            .firstOrNull;
        final quantity = materialCktType?.materialQuantity ?? 0.0;
        cells['ckt_$cktType'] = PlutoCell(value: quantity);
      }

      return PlutoRow(cells: cells);
    }).toList();
  }
}
