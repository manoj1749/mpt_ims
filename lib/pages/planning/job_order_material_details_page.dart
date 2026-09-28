import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pluto_grid/pluto_grid.dart';
import '../../provider/material_provider.dart';
import '../../models/pr_item.dart';
import '../../models/material_item.dart';
import '../../widgets/pluto_grid_configuration.dart';

class JobOrderMaterialDetailsPage extends ConsumerWidget {
  final String jobNo;
  final List<PRItem> materials;

  const JobOrderMaterialDetailsPage({
    super.key,
    required this.jobNo,
    required this.materials,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final materialMaster = ref.watch(materialListProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('Materials for $jobNo'),
        backgroundColor: const Color(0xFF2D2D2D),
        foregroundColor: Colors.white,
      ),
      body: materials.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.inventory_2_outlined,
                    size: 64,
                    color: Colors.white54,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'No materials found',
                    style: TextStyle(
                      color: Colors.white54,
                      fontSize: 18,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'No INHOUSE FABRICATION materials with MS/LINK subcategory found for this job',
                    style: TextStyle(
                      color: Colors.white38,
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
          : Container(
              padding: const EdgeInsets.all(16),
              child: PlutoGrid(
                columns: _buildColumns(),
                rows: _buildRows(materials, materialMaster),
                configuration: PlutoGridConfigurations.darkMode(),
              ),
            ),
    );
  }

  List<PlutoColumn> _buildColumns() {
    return [
      PlutoColumn(
        title: 'S.No',
        field: 'serialNo',
        type: PlutoColumnType.number(),
        width: 60,
        backgroundColor: const Color(0xFF2D2D2D),
        titleTextAlign: PlutoColumnTextAlign.center,
        textAlign: PlutoColumnTextAlign.center,
        enableEditingMode: false,
      ),
      PlutoColumn(
        title: 'Part No',
        field: 'partNo',
        type: PlutoColumnType.text(),
        width: 150,
        backgroundColor: const Color(0xFF2D2D2D),
        titleTextAlign: PlutoColumnTextAlign.center,
        textAlign: PlutoColumnTextAlign.center,
        enableEditingMode: false,
      ),
      PlutoColumn(
        title: 'Description',
        field: 'description',
        type: PlutoColumnType.text(),
        width: 300,
        backgroundColor: const Color(0xFF2D2D2D),
        titleTextAlign: PlutoColumnTextAlign.center,
        textAlign: PlutoColumnTextAlign.start,
        enableEditingMode: false,
      ),
      PlutoColumn(
        title: 'Raw Materials',
        field: 'rawMaterial',
        type: PlutoColumnType.text(),
        width: 200,
        backgroundColor: const Color(0xFF2D2D2D),
        titleTextAlign: PlutoColumnTextAlign.center,
        textAlign: PlutoColumnTextAlign.start,
        enableEditingMode: false,
      ),
      PlutoColumn(
        title: 'Category',
        field: 'category',
        type: PlutoColumnType.text(),
        width: 150,
        backgroundColor: const Color(0xFF2D2D2D),
        titleTextAlign: PlutoColumnTextAlign.center,
        textAlign: PlutoColumnTextAlign.center,
        enableEditingMode: false,
      ),
      PlutoColumn(
        title: 'Subcategory',
        field: 'subCategory',
        type: PlutoColumnType.text(),
        width: 100,
        backgroundColor: const Color(0xFF2D2D2D),
        titleTextAlign: PlutoColumnTextAlign.center,
        textAlign: PlutoColumnTextAlign.center,
        enableEditingMode: false,
      ),
      PlutoColumn(
        title: 'Unit',
        field: 'unit',
        type: PlutoColumnType.text(),
        width: 80,
        backgroundColor: const Color(0xFF2D2D2D),
        titleTextAlign: PlutoColumnTextAlign.center,
        textAlign: PlutoColumnTextAlign.center,
        enableEditingMode: false,
      ),
      PlutoColumn(
        title: 'Quantity',
        field: 'quantity',
        type: PlutoColumnType.number(format: '#,##0.00'),
        width: 100,
        backgroundColor: const Color(0xFF2D2D2D),
        titleTextAlign: PlutoColumnTextAlign.center,
        textAlign: PlutoColumnTextAlign.right,
        enableEditingMode: false,
      ),
      PlutoColumn(
        title: 'Storage Location',
        field: 'storageLocation',
        type: PlutoColumnType.text(),
        width: 120,
        backgroundColor: const Color(0xFF2D2D2D),
        titleTextAlign: PlutoColumnTextAlign.center,
        textAlign: PlutoColumnTextAlign.center,
        enableEditingMode: false,
      ),
      PlutoColumn(
        title: 'Rack Number',
        field: 'rackNumber',
        type: PlutoColumnType.text(),
        width: 100,
        backgroundColor: const Color(0xFF2D2D2D),
        titleTextAlign: PlutoColumnTextAlign.center,
        textAlign: PlutoColumnTextAlign.center,
        enableEditingMode: false,
      ),
    ];
  }

  List<PlutoRow> _buildRows(List<PRItem> prMaterials, List<MaterialItem> materialMaster) {
    return prMaterials.asMap().entries.map((entry) {
      final index = entry.key;
      final prItem = entry.value;
      
      // Get material details from material master
      final material = materialMaster.where((m) => m.partNo == prItem.materialCode).firstOrNull;
      
      return PlutoRow(
        cells: {
          'serialNo': PlutoCell(value: index + 1),
          'partNo': PlutoCell(value: prItem.materialCode),
          'description': PlutoCell(value: prItem.materialDescription),
          'category': PlutoCell(value: material?.category ?? ''),
          'subCategory': PlutoCell(value: material?.subCategory ?? ''),
          'unit': PlutoCell(value: prItem.unit),
          'quantity': PlutoCell(value: double.tryParse(prItem.quantity) ?? 0.0),
          'storageLocation': PlutoCell(value: material?.storageLocation ?? ''),
          'rackNumber': PlutoCell(value: material?.rackNumber ?? ''),
          'rawMaterial': PlutoCell(value: material?.rawMaterial ?? ''),
        },
      );
    }).toList();
  }
}
