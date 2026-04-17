import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pluto_grid/pluto_grid.dart';
import '../../models/bill_of_preparation.dart';
import '../../models/material_item.dart';
import '../../provider/bill_of_preparation_provider.dart';
import '../../provider/material_provider.dart';
import '../../widgets/pluto_grid_configuration.dart';
import 'add_bill_of_preparation_page.dart';
import 'bop_material_details_page.dart';

class BillOfPreparationListPage extends ConsumerStatefulWidget {
  const BillOfPreparationListPage({super.key});

  @override
  ConsumerState<BillOfPreparationListPage> createState() =>
      _BillOfPreparationListPageState();
}

class _BillOfPreparationListPageState
    extends ConsumerState<BillOfPreparationListPage> {
  PlutoGridStateManager? stateManager;

  List<PlutoColumn> _buildBasicColumns() {
    return [
      PlutoColumn(
        title: 'S.No',
        field: 'serialNo',
        type: PlutoColumnType.number(),
        width: 60,
        backgroundColor: Colors.grey[850],
        titleTextAlign: PlutoColumnTextAlign.center,
        textAlign: PlutoColumnTextAlign.center,
        enableEditingMode: false,
      ),
      PlutoColumn(
        title: 'Job Number',
        field: 'jobNo',
        type: PlutoColumnType.text(),
        width: 200,
        enableEditingMode: false,
        renderer: (rendererContext) {
          return InkWell(
            onTap: () {
              final index = rendererContext.row.cells['index']!.value as int;
              final bop = ref.read(billOfPreparationProvider)[index];
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => BopMaterialDetailsPage(bop: bop),
                ),
              );
            },
            child: Container(
              padding: const EdgeInsets.all(8),
              child: Row(
                children: [
                  const Icon(
                    Icons.open_in_new,
                    color: Colors.white,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      rendererContext.cell.value.toString(),
                      style: const TextStyle(
                        color: Colors.white,
    
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
      PlutoColumn(
        title: 'Created Date',
        field: 'createdDate',
        type: PlutoColumnType.text(),
        width: 120,
        enableEditingMode: false,
      ),
      PlutoColumn(
        title: 'Final Quantity',
        field: 'finalValue',
        type: PlutoColumnType.number(format: '#,##0.00'),
        width: 120,
        enableEditingMode: false,
        textAlign: PlutoColumnTextAlign.right,
      ),
      PlutoColumn(
        title: 'Actions',
        field: 'actions',
        type: PlutoColumnType.text(),
        width: 120,
        enableEditingMode: false,
        renderer: (rendererContext) {
          return Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              InkWell(
                onTap: () {
                  final index = rendererContext.row.cells['index']!.value as int;
                  final bop = ref.read(billOfPreparationProvider)[index];
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AddBillOfPreparationPage(
                        existingBop: bop,
                        index: index,
                      ),
                    ),
                  );
                },
                child: const Padding(
                  padding: EdgeInsets.all(4.0),
                  child: Icon(Icons.edit, color: Colors.blue, size: 18),
                ),
              ),
              const SizedBox(width: 4),
              InkWell(
                onTap: () {
                  final index = rendererContext.row.cells['index']!.value as int;
                  final bop = ref.read(billOfPreparationProvider)[index];
                  _showDeleteDialog(bop);
                },
                child: const Padding(
                  padding: EdgeInsets.all(4.0),
                  child: Icon(Icons.delete, color: Colors.red, size: 18),
                ),
              ),
            ],
          );
        },
      ),
    ];
  }

  List<PlutoColumn> _buildDynamicColumns(List<BillOfPreparation> bops) {
    // Collect all unique CKT type names
    final Set<String> uniqueCktTypes = <String>{};
    print('DEBUG: Building columns for ${bops.length} BOPs');
    
    for (final bop in bops) {
      print('DEBUG: BOP ${bop.jobNo} has ${bop.cktTypes.length} CKT types');
      for (final cktType in bop.cktTypes) {
        print('DEBUG: CKT Type: "${cktType.name}" with quantity ${cktType.quantity}');
        if (cktType.name.isNotEmpty) {
          uniqueCktTypes.add(cktType.name);
        }
      }
    }

    // Sort CKT types alphabetically for consistent column order
    final sortedCktTypes = uniqueCktTypes.toList()..sort();
    print('DEBUG: Unique CKT types: $sortedCktTypes');

    // Build dynamic columns
    final dynamicColumns = <PlutoColumn>[];
    
    // Add CKT type columns with quantities from the first BOP
    for (final cktTypeName in sortedCktTypes) {
      String title = cktTypeName;
      // Find the quantity from the first BOP that has this CKT type
      for (final bop in bops) {
        for (final cktType in bop.cktTypes) {
          if (cktType.name == cktTypeName) {
            title = '$cktTypeName (${cktType.quantity})';
            print('DEBUG: Setting title for $cktTypeName to: $title');
            break;
          }
        }
        if (title != cktTypeName) break; // Found the quantity
      }
      
      dynamicColumns.add(PlutoColumn(
        title: title,
        field: 'ckt_$cktTypeName',
        type: PlutoColumnType.number(),
        width: 150,
        enableEditingMode: false,
        textAlign: PlutoColumnTextAlign.center,
        titleTextAlign: PlutoColumnTextAlign.center,
      ));
    }

    // Combine basic columns with dynamic CKT type columns (insert before Final Quantity)
    final basicColumns = _buildBasicColumns();
    final finalColumns = <PlutoColumn>[];
    
    // Add columns up to Created Date
    final createdDateIndex = basicColumns.indexWhere((col) => col.field == 'createdDate');
    if (createdDateIndex != -1) {
      finalColumns.addAll(basicColumns.take(createdDateIndex + 1));
    }
    
    // Add dynamic CKT type columns
    finalColumns.addAll(dynamicColumns);
    
    // Add remaining columns (Final Quantity and Actions)
    final remainingColumns = basicColumns.skip(createdDateIndex + 1).toList();
    finalColumns.addAll(remainingColumns);
    
    return finalColumns;
  }

  void _showMaterialsModal(BuildContext context, BillOfPreparation bop) {
    // Group materials by CKT types
    final Map<String, List<Map<String, dynamic>>> cktTypeGroups = {};
    
    for (final material in bop.materials) {
      for (final materialCktType in material.cktTypes) {
        final cktTypeName = materialCktType.cktTypeName;
        if (!cktTypeGroups.containsKey(cktTypeName)) {
          cktTypeGroups[cktTypeName] = [];
        }
        // Find the material item to get raw material info
        final materials = ref.read(materialListProvider);
        final materialItem = materials.firstWhere(
          (m) => m.partNo == material.materialCode,
          orElse: () => MaterialItem(slNo: '', description: '', partNo: '', unit: '', category: '', subCategory: '', rawMaterial: ''),
        );
        
        cktTypeGroups[cktTypeName]!.add({
          'materialCode': material.materialCode,
          'materialDescription': material.materialDescription,
          'materialRawMaterial': materialItem.rawMaterial,
          'materialQuantity': materialCktType.materialQuantity,
        });
      }
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Materials for ${bop.jobNo}'),
        content: SizedBox(
          width: double.maxFinite,
          child: cktTypeGroups.isEmpty
              ? const Center(
                  child: Text('No materials found for this BOP'),
                )
              : ListView.builder(
                  shrinkWrap: true,
                  itemCount: cktTypeGroups.keys.length,
                  itemBuilder: (context, index) {
                    final cktTypeName = cktTypeGroups.keys.elementAt(index);
                    final materials = cktTypeGroups[cktTypeName]!;
                    
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // CKT Type Header
                            Text(
                              'CKT TYPE: $cktTypeName',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 12),
                            
                            // Materials under this CKT Type
                            ...materials.asMap().entries.map((entry) {
                              final materialIndex = entry.key;
                              final material = entry.value;
                              return Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey[300]!),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      material['materialCode'],
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      material['materialDescription'],
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 14,
                                      ),
                                    ),
                                    if (material['materialRawMaterial'].isNotEmpty) ...[
                                      const SizedBox(height: 4),
                                      Text(
                                        'Raw Material: ${material['materialRawMaterial']}',
                                        style: TextStyle(
                                          color: Colors.grey[400],
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        const Text(
                                          'Quantity: ',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w500,
                                            fontSize: 14,
                                          ),
                                        ),
                                        Text(
                                          '${material['materialQuantity']}',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              );
                            }),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(BillOfPreparation bop) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Bill of Preparation'),
        content: Text('Are you sure you want to delete the Bill of Preparation for ${bop.jobNo}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              ref.read(billOfPreparationProvider.notifier).deleteBillOfPreparation(bop, ref);
              Navigator.pop(context);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  List<PlutoRow> _getRows(List<BillOfPreparation> bops) {
    return bops.asMap().entries.map((entry) {
      final index = entry.key;
      final bop = entry.value;
      
      final Map<String, PlutoCell> cells = {
        'serialNo': PlutoCell(value: index + 1),
        'index': PlutoCell(value: index),
        'jobNo': PlutoCell(value: bop.jobNo),
        'createdDate': PlutoCell(value: bop.createdDate),
        'finalValue': PlutoCell(value: bop.finalValue.toStringAsFixed(2)),
        'actions': PlutoCell(value: ''),
      };
      
      return PlutoRow(cells: cells);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final bops = ref.watch(billOfPreparationProvider);
    
    // Use only basic columns (no CKT type columns)
    final columns = _buildBasicColumns();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bill of Preparation'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AddBillOfPreparationPage(
                    existingBop: null,
                    index: null,
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: bops.isEmpty
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
                    'No Bill of Preparations Found',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Create your first Bill of Preparation using the + button above',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            )
          : PlutoGrid(
              key: ValueKey(bops.length), // Force rebuild when data changes
              columns: columns,
              rows: _getRows(bops),
              onLoaded: (PlutoGridOnLoadedEvent event) {
                stateManager = event.stateManager;
                // Apply grid configuration
                stateManager?.setShowColumnFilter(true);
                stateManager?.setSelectingMode(PlutoGridSelectingMode.none);
              },
              configuration: PlutoGridConfigurations.darkMode(),
              onChanged: (PlutoGridOnChangedEvent event) {
                // Handle any grid changes if needed
              },
            ),
    );
  }
}
