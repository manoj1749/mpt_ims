// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pluto_grid/pluto_grid.dart';
import '../../provider/quality_inspection_provider.dart';
import '../../models/quality_inspection.dart';
import '../../widgets/pluto_grid_configuration.dart';

class CapaStatusPage extends ConsumerStatefulWidget {
  const CapaStatusPage({super.key});

  @override
  ConsumerState<CapaStatusPage> createState() => _CapaStatusPageState();
}

class _CapaStatusPageState extends ConsumerState<CapaStatusPage> {
  late final List<PlutoColumn> columns;
  PlutoGridStateManager? stateManager;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    columns = [
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
        title: 'GRN No',
        field: 'grnNo',
        type: PlutoColumnType.text(),
        width: 120,
        backgroundColor: Colors.grey[850],
        titleTextAlign: PlutoColumnTextAlign.center,
        textAlign: PlutoColumnTextAlign.center,
        enableEditingMode: false,
      ),
      PlutoColumn(
        title: 'PO No',
        field: 'poNo',
        type: PlutoColumnType.text(),
        width: 120,
        backgroundColor: Colors.grey[850],
        titleTextAlign: PlutoColumnTextAlign.center,
        textAlign: PlutoColumnTextAlign.center,
        enableEditingMode: false,
      ),
      PlutoColumn(
        title: 'Supplier',
        field: 'supplier',
        type: PlutoColumnType.text(),
        width: 150,
        backgroundColor: Colors.grey[850],
        titleTextAlign: PlutoColumnTextAlign.center,
        textAlign: PlutoColumnTextAlign.center,
        enableEditingMode: false,
      ),
      PlutoColumn(
        title: 'Material',
        field: 'material',
        type: PlutoColumnType.text(),
        width: 200,
        backgroundColor: Colors.grey[850],
        titleTextAlign: PlutoColumnTextAlign.center,
        textAlign: PlutoColumnTextAlign.start,
        enableEditingMode: false,
      ),
      PlutoColumn(
        title: 'Inspection Date',
        field: 'inspectionDate',
        type: PlutoColumnType.date(),
        width: 120,
        backgroundColor: Colors.grey[850],
        titleTextAlign: PlutoColumnTextAlign.center,
        textAlign: PlutoColumnTextAlign.center,
        enableEditingMode: false,
      ),
      PlutoColumn(
        title: 'Usage Decision',
        field: 'usageDecision',
        type: PlutoColumnType.text(),
        width: 120,
        backgroundColor: Colors.grey[850],
        titleTextAlign: PlutoColumnTextAlign.center,
        textAlign: PlutoColumnTextAlign.center,
        enableEditingMode: false,
      ),
      PlutoColumn(
        title: 'CAPA Status',
        field: 'capaStatus',
        type: PlutoColumnType.text(),
        width: 120,
        backgroundColor: Colors.grey[850],
        titleTextAlign: PlutoColumnTextAlign.center,
        textAlign: PlutoColumnTextAlign.center,
        enableEditingMode: false,
      ),
      PlutoColumn(
        title: 'Remarks',
        field: 'remarks',
        type: PlutoColumnType.text(),
        width: 200,
        backgroundColor: Colors.grey[850],
        titleTextAlign: PlutoColumnTextAlign.center,
        textAlign: PlutoColumnTextAlign.start,
        enableEditingMode: false,
      ),
    ];
  }

  List<PlutoRow> _getRows(List<QualityInspection> inspections) {
    // Filter inspections that require CAPA
    final capaInspections = inspections.where((inspection) =>
        inspection.items.any((item) => item.capaRequired == true)).toList();

    // Filter based on search query if any
    final filteredInspections = _searchQuery.isEmpty
        ? capaInspections
        : capaInspections.where((inspection) {
            final searchLower = _searchQuery.toLowerCase();
            return inspection.grnNo.toLowerCase().contains(searchLower) ||
                inspection.poNo.toLowerCase().contains(searchLower) ||
                inspection.supplierName.toLowerCase().contains(searchLower) ||
                inspection.items.any((item) =>
                    item.materialDescription.toLowerCase().contains(searchLower));
          }).toList();

    final rows = <PlutoRow>[];
    var serialNo = 1;

    for (var inspection in filteredInspections) {
      // Add a row for each item that requires CAPA
      for (var item in inspection.items) {
        if (item.capaRequired == true) {
          rows.add(
            PlutoRow(
              cells: {
                'serialNo': PlutoCell(value: serialNo++),
                'grnNo': PlutoCell(value: inspection.grnNo),
                'poNo': PlutoCell(value: inspection.poNo),
                'supplier': PlutoCell(value: inspection.supplierName),
                'material': PlutoCell(value: item.materialDescription),
                'inspectionDate': PlutoCell(value: inspection.inspectionDate),
                'usageDecision': PlutoCell(value: item.usageDecision),
                'capaStatus': PlutoCell(
                    value: item.inspectionRemark?.contains('CAPA Completed') ?? false ? 'Completed' : 'Pending'),
                'remarks': PlutoCell(
                    value: item.inspectionRemark?.isEmpty ?? true
                        ? '-'
                        : item.inspectionRemark),
              },
            ),
          );
        }
      }
    }

    return rows;
  }

  @override
  Widget build(BuildContext context) {
    final inspections = ref.watch(qualityInspectionProvider);

    return Scaffold(
      backgroundColor: Colors.grey[900],
      appBar: AppBar(
        title: const Text('CAPA Status'),
        elevation: 0,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search...',
                hintStyle: TextStyle(color: Colors.grey[400]),
                prefixIcon: Icon(Icons.search, color: Colors.grey[400]),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                fillColor: Colors.grey[850],
                filled: true,
              ),
              style: const TextStyle(color: Colors.white),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
                // Refresh grid with new search query
                if (stateManager != null) {
                  stateManager!.removeAllRows();
                  stateManager!.appendRows(_getRows(inspections));
                }
              },
            ),
          ),
          Expanded(
            child: inspections.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.assignment_late_outlined,
                          size: 64,
                          color: Colors.grey[300],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No CAPA records found',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  )
                : Padding(
                    padding: const EdgeInsets.all(16),
                    child: PlutoGrid(
                      columns: columns,
                      rows: _getRows(inspections),
                      onLoaded: (PlutoGridOnLoadedEvent event) {
                        stateManager = event.stateManager;
                        stateManager?.setShowColumnFilter(true);
                      },
                      configuration: PlutoGridConfigurations.darkMode(),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
} 