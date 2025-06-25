import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pluto_grid/pluto_grid.dart';
import '../../models/delivery_challan.dart';
import '../../provider/delivery_challan_provider.dart';
import '../../provider/stock_maintenance_provider.dart';
import '../../widgets/pluto_grid_configuration.dart';
import 'add_delivery_challan_page.dart';

final deliveryChallanNotifierProvider =
    StateNotifierProvider<DeliveryChallanNotifier, List<DeliveryChallan>>(
  (ref) => DeliveryChallanNotifier(
    ref.watch(deliveryChallanBoxProvider),
    ref.watch(stockMaintenanceBoxProvider),
  ),
);

class DeliveryChallanListPage extends ConsumerWidget {
  const DeliveryChallanListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final deliveryChallans = ref.watch(deliveryChallanNotifierProvider);

    final columns = [
      PlutoColumn(
        title: 'DC No',
        field: 'dcNo',
        type: PlutoColumnType.text(),
        enableEditingMode: false,
      ),
      PlutoColumn(
        title: 'Date',
        field: 'date',
        type: PlutoColumnType.text(),
        enableEditingMode: false,
      ),
      PlutoColumn(
        title: 'Vendor',
        field: 'vendor',
        type: PlutoColumnType.text(),
        enableEditingMode: false,
      ),
      PlutoColumn(
        title: 'Returnable',
        field: 'returnable',
        type: PlutoColumnType.text(),
        enableEditingMode: false,
      ),
      PlutoColumn(
        title: 'Actions',
        field: 'actions',
        type: PlutoColumnType.text(),
        enableEditingMode: false,
        renderer: (rendererContext) {
          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () {
                  final dc = deliveryChallans.firstWhere(
                    (dc) => dc.dcNo == rendererContext.cell.value,
                  );
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AddDeliveryChallanPage(
                        deliveryChallan: dc,
                      ),
                    ),
                  );
                },
              ),
              IconButton(
                icon: const Icon(Icons.delete),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Delete Delivery Challan'),
                      content: const Text(
                        'Are you sure you want to delete this delivery challan?',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () {
                            final notifier = ref.read(
                              deliveryChallanNotifierProvider.notifier,
                            );
                            notifier.deleteDeliveryChallan(
                              rendererContext.cell.value,
                            );
                            Navigator.pop(context);
                          },
                          child: const Text('Delete'),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          );
        },
      ),
    ];

    final rows = deliveryChallans.map((dc) {
      return PlutoRow(cells: {
        'dcNo': PlutoCell(value: dc.dcNo),
        'date': PlutoCell(value: dc.dcDate),
        'vendor': PlutoCell(value: dc.vendorName),
        'returnable': PlutoCell(value: dc.isReturnable ? 'Yes' : 'No'),
        'actions': PlutoCell(value: dc.dcNo),
      });
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Delivery Challans'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AddDeliveryChallanPage(),
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
          onLoaded: (event) => event.stateManager.setShowColumnFilter(true),
          configuration: PlutoGridConfigurations.darkMode(),
        ),
      ),
    );
  }
}
