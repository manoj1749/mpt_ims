import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pluto_grid/pluto_grid.dart';
import 'package:collection/collection.dart';
import '../../provider/purchase_request_provider.dart';
import '../../provider/material_provider.dart';
import '../../provider/job_order_request_provider.dart';
import '../../models/purchase_request.dart';
import '../../models/pr_item.dart';
import '../../models/material_item.dart';
import '../../models/job_order_request.dart';
import '../../widgets/pluto_grid_configuration.dart';

class CreateJobOrderRequestPage extends ConsumerWidget {
  final Set<String> selectedJobs;

  const CreateJobOrderRequestPage({
    super.key,
    required this.selectedJobs,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final purchaseRequests = ref.watch(purchaseRequestListProvider);
    final materials = ref.watch(materialListProvider);
    final jobOrderRequestNotifier = ref.watch(jobOrderRequestProvider.notifier);
    
    // Generate auto job order request number
    final jobOrderRequestNo = jobOrderRequestNotifier.generateNextJORNumber();
    final currentDate = DateTime.now().toString().split(' ')[0];

    // Get all materials for selected jobs
    List<PRItem> allJobMaterials = [];
    for (final pr in purchaseRequests) {
      if (pr.jobNo != null && selectedJobs.contains(pr.jobNo!)) {
        // Filter materials that match our criteria
        final matchingMaterials = pr.items.where((item) {
          final material = materials.where((m) => m.partNo == item.materialCode).firstOrNull;
          return material != null &&
                 material.category == "INHOUSE FABRICATION" &&
                 (material.subCategory == "MS" || material.subCategory == "LINK");
        }).toList();
        allJobMaterials.addAll(matchingMaterials);
      }
    }

    // Group materials by raw material
    Map<String, List<PRItem>> materialsByRawMaterial = {};
    for (final prItem in allJobMaterials) {
      final material = materials.where((m) => m.partNo == prItem.materialCode).firstOrNull;
      if (material != null && material.rawMaterial.isNotEmpty) {
        final rawMaterial = material.rawMaterial;
        if (!materialsByRawMaterial.containsKey(rawMaterial)) {
          materialsByRawMaterial[rawMaterial] = [];
        }
        materialsByRawMaterial[rawMaterial]!.add(prItem);
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Create Job Order Request: ${selectedJobs.length} Job(s)'),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          SizedBox(height: 16),
          // Job Order Request Number and Date Inputs
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: TextEditingController(text: jobOrderRequestNo),
                    readOnly: true,
                    decoration: const InputDecoration(
                      labelText: 'Job Order Request No',
                      labelStyle: TextStyle(color: Colors.white70),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(8)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(8)),
                        borderSide: BorderSide(color: Colors.grey),
                      ),
                      disabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(8)),
                        borderSide: BorderSide(color: Colors.grey),
                      ),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                    ),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextField(
                    controller: TextEditingController(text: currentDate),
                    readOnly: true,
                    decoration: const InputDecoration(
                      labelText: 'Date',
                      labelStyle: TextStyle(color: Colors.white70),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(8)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(8)),
                        borderSide: BorderSide(color: Colors.grey),
                      ),
                      disabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(8)),
                        borderSide: BorderSide(color: Colors.grey),
                      ),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                    ),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Materials Section
          Expanded(
            child: materialsByRawMaterial.isEmpty
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
                        'No materials with raw materials found for selected jobs',
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Summary section
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF3D3D3D),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Summary',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Raw Material Groups: ${materialsByRawMaterial.length}',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                            ),
                            Text(
                              'Total Materials: ${allJobMaterials.length}',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                            ),
                            Text(
                              'Selected Jobs: ${selectedJobs.join(", ")}',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Materials grid
                      Expanded(
                        child: PlutoGrid(
                          columns: _buildColumns(),
                          rows: _buildRows(materialsByRawMaterial, materials),
                          configuration: PlutoGridConfigurations.darkMode(),
                        ),
                      ),
                    ],
                  ),
                ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          _createJobOrderRequest(context, ref, materialsByRawMaterial);
        },
        icon: const Icon(Icons.save),
        label: const Text('Create Request'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
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
        title: 'Raw Material',
        field: 'rawMaterial',
        type: PlutoColumnType.text(),
        width: 250,
        backgroundColor: const Color(0xFF2D2D2D),
        titleTextAlign: PlutoColumnTextAlign.center,
        textAlign: PlutoColumnTextAlign.start,
        enableEditingMode: false,
      ),
      PlutoColumn(
        title: 'Material Count',
        field: 'materialCount',
        type: PlutoColumnType.number(),
        width: 120,
        backgroundColor: const Color(0xFF2D2D2D),
        titleTextAlign: PlutoColumnTextAlign.center,
        textAlign: PlutoColumnTextAlign.center,
        enableEditingMode: false,
      ),
      PlutoColumn(
        title: 'Total Quantity',
        field: 'totalQty',
        type: PlutoColumnType.number(format: '#,##0.00'),
        width: 120,
        backgroundColor: const Color(0xFF2D2D2D),
        titleTextAlign: PlutoColumnTextAlign.center,
        textAlign: PlutoColumnTextAlign.right,
        enableEditingMode: false,
      ),
      PlutoColumn(
        title: 'Materials',
        field: 'materials',
        type: PlutoColumnType.text(),
        width: 400,
        backgroundColor: const Color(0xFF2D2D2D),
        titleTextAlign: PlutoColumnTextAlign.center,
        textAlign: PlutoColumnTextAlign.start,
        enableEditingMode: false,
        renderer: (rendererContext) {
          final materials = rendererContext.row.cells['materials']?.value as List<PRItem>?;
          if (materials == null || materials.isEmpty) {
            return const Text(
              'No materials',
              style: TextStyle(color: Colors.white38),
            );
          }

          return Container(
            padding: const EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: materials.take(5).map((material) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: Text(
                    '${material.materialCode} - ${material.materialDescription}',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                );
              }).toList(),
            ),
          );
        },
      ),
    ];
  }

  List<PlutoRow> _buildRows(Map<String, List<PRItem>> materialsByRawMaterial, List<MaterialItem> materialMaster) {
    return materialsByRawMaterial.entries.toList().asMap().entries.map((entry) {
      final index = entry.key;
      final rawMaterialEntry = entry.value;
      final rawMaterial = rawMaterialEntry.key;
      final materials = rawMaterialEntry.value;
      
      // Calculate total quantity
      double totalQty = 0;
      for (final item in materials) {
        totalQty += double.tryParse(item.quantity) ?? 0.0;
      }
      
      return PlutoRow(
        cells: {
          'serialNo': PlutoCell(value: index + 1),
          'rawMaterial': PlutoCell(value: rawMaterial),
          'materialCount': PlutoCell(value: materials.length),
          'totalQty': PlutoCell(value: totalQty),
          'materials': PlutoCell(value: materials),
        },
      );
    }).toList();
  }

  Future<void> _createJobOrderRequest(BuildContext context, WidgetRef ref, Map<String, List<PRItem>> materialsByRawMaterial) async {
    final jobOrderRequestNotifier = ref.read(jobOrderRequestProvider.notifier);
    final jobOrderRequestNo = jobOrderRequestNotifier.generateNextJORNumber();
    final currentDate = DateTime.now().toString().split(' ')[0];

    // Convert materialsByRawMaterial to the required format
    Map<String, List<String>> materialsMap = {};
    for (final entry in materialsByRawMaterial.entries) {
      materialsMap[entry.key] = entry.value.map((prItem) => prItem.materialCode).toList();
    }

    // Create the job order request
    final jobOrderRequest = JobOrderRequest(
      requestNo: jobOrderRequestNo,
      requestDate: currentDate,
      selectedJobs: selectedJobs.toList(),
      materialsByRawMaterial: materialsMap,
      createdDate: DateTime.now(),
      status: 'pending',
    );

    // Save the job order request
    await jobOrderRequestNotifier.addJobOrderRequest(jobOrderRequest);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Job Order Request $jobOrderRequestNo created successfully'),
        backgroundColor: Colors.blue,
      ),
    );

    // Navigate back
    Navigator.of(context).pop();
  }
}
