// import 'package:flutter/material.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:pluto_grid/pluto_grid.dart';
// import '../../models/material_item.dart';
// import '../../provider/material_provider.dart';
// import '../../widgets/pluto_grid_configuration.dart';

// class MaterialSelectionDialog extends ConsumerStatefulWidget {
//   const MaterialSelectionDialog({super.key});

//   @override
//   MaterialSelectionDialogState createState() => MaterialSelectionDialogState();
// }

// class MaterialSelectionDialogState extends ConsumerState<MaterialSelectionDialog> {
//   PlutoGridStateManager? stateManager;
//   TextEditingController searchController = TextEditingController();

//   List<PlutoRow> _buildRows(List<MaterialItem> materials) {
//     return materials.map((material) {
//       return PlutoRow(
//         cells: {
//           'materialCode': PlutoCell(value: material.partNo),
//           'description': PlutoCell(value: material.description),
//           'unit': PlutoCell(value: material.unit),
//           'category': PlutoCell(value: material.category),
//           'actions': PlutoCell(value: material),
//         },
//       );
//     }).toList();
//   }

//   List<PlutoColumn> _getColumns() {
//     return [
//       PlutoColumn(
//         title: 'Material Code',
//         field: 'materialCode',
//         type: PlutoColumnType.text(),
//         width: 150,
//         titleTextAlign: PlutoColumnTextAlign.center,
//         textAlign: PlutoColumnTextAlign.center,
//         enableEditingMode: false,
//       ),
//       PlutoColumn(
//         title: 'Description',
//         field: 'description',
//         type: PlutoColumnType.text(),
//         width: 200,
//         titleTextAlign: PlutoColumnTextAlign.center,
//         textAlign: PlutoColumnTextAlign.left,
//         enableEditingMode: false,
//       ),
//       PlutoColumn(
//         title: 'Unit',
//         field: 'unit',
//         type: PlutoColumnType.text(),
//         width: 80,
//         titleTextAlign: PlutoColumnTextAlign.center,
//         textAlign: PlutoColumnTextAlign.center,
//         enableEditingMode: false,
//       ),
//       PlutoColumn(
//         title: 'Category',
//         field: 'category',
//         type: PlutoColumnType.text(),
//         width: 120,
//         titleTextAlign: PlutoColumnTextAlign.center,
//         textAlign: PlutoColumnTextAlign.center,
//         enableEditingMode: false,
//       ),
//       PlutoColumn(
//         title: 'Actions',
//         field: 'actions',
//         type: PlutoColumnType.text(),
//         width: 100,
//         titleTextAlign: PlutoColumnTextAlign.center,
//         textAlign: PlutoColumnTextAlign.center,
//         enableEditingMode: false,
//         renderer: (rendererContext) {
//           return IconButton(
//             icon: const Icon(Icons.add_circle_outline, size: 20),
//             onPressed: () => _selectMaterial(rendererContext.cell.value as MaterialItem),
//             color: Colors.blue,
//             tooltip: 'Select Material',
//           );
//         },
//       ),
//     ];
//   }

//   void _selectMaterial(MaterialItem material) {
//     Navigator.of(context).pop(material);
//   }

//   @override
//   Widget build(BuildContext context) {
//     final materials = ref.watch(materialListProvider);

//     return Dialog(
//       child: Container(
//         width: MediaQuery.of(context).size.width * 0.8,
//         height: MediaQuery.of(context).size.height * 0.8,
//         padding: const EdgeInsets.all(16.0),
//         child: Column(
//           children: [
//             Row(
//               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//               children: [
//                 const Text(
//                   'Select Material',
//                   style: TextStyle(
//                     fontSize: 20,
//                     fontWeight: FontWeight.bold,
//                   ),
//                 ),
//                 IconButton(
//                   icon: const Icon(Icons.close),
//                   onPressed: () => Navigator.of(context).pop(),
//                 ),
//               ],
//             ),
//             const SizedBox(height: 16),
//             TextField(
//               controller: searchController,
//               decoration: const InputDecoration(
//                 labelText: 'Search Materials',
//                 prefixIcon: Icon(Icons.search),
//                 border: OutlineInputBorder(),
//               ),
//               onChanged: (value) {
//                 // TODO: Implement search functionality
//               },
//             ),
//             const SizedBox(height: 16),
//             Expanded(
//               child: PlutoGrid(
//                 columns: _getColumns(),
//                 rows: _buildRows(materials),
//                 onLoaded: (event) => stateManager = event.stateManager,
//                 configuration: getGridConfiguration(),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   @override
//   void dispose() {
//     searchController.dispose();
//     super.dispose();
//   }
// }
