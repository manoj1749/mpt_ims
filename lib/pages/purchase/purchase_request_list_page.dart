  for (var request in requests) {
    for (var item in request.items) {
      // Calculate total ordered quantity from PR item's orderedQuantities
      final totalOrderedQty = item.totalOrderedQuantity;

      // Check if this PR's items are in any PO
      final bool isInPO = totalOrderedQty > 0;

      // Check if all items in this PR are fully ordered
      final bool allItemsOrdered = request.items.every((item) => item.isFullyOrdered);

      // Calculate received quantity from Store Inwards
      final receivedQty = storeInwards
          .where((si) => si.items.any((siItem) =>
              siItem.materialCode == item.materialCode &&
              siItem.poQuantities.keys.any((poNo) => purchaseOrders.any(
                  (po) =>
                      po.poNo == poNo &&
                      po.items.any((poItem) =>
                          poItem.materialCode == item.materialCode &&
                          poItem.prDetails.values.any((detail) => detail.prNo == request.prNo))))))
          .fold<double>(
              0,
              (sum, si) =>
                  sum +
                  si.items
                      .where((siItem) =>
                          siItem.materialCode == item.materialCode)
                      .fold<double>(
                          0, (sum, siItem) => sum + siItem.acceptedQty));

      // Get PO details
      final relatedPOs = purchaseOrders
          .where((po) => po.items.any((poItem) =>
              poItem.materialCode == item.materialCode &&
              poItem.prDetails.values.any((detail) => detail.prNo == request.prNo)))
          .map((po) => '${po.poNo}\n(${po.poDate})')
          .join('\n\n');

      // Get stock transfer details
      final transfers = storeInwards
          .where((si) => si.items.any((siItem) =>
              siItem.materialCode == item.materialCode &&
              siItem.poQuantities.keys.any((poNo) => purchaseOrders.any(
                  (po) =>
                      po.poNo == poNo &&
                      po.items.any((poItem) =>
                          poItem.materialCode == item.materialCode &&
                          poItem.prDetails.values.any((detail) => detail.prNo == request.prNo))))))
          .map((si) {
            final matchingItems = si.items
                .where((siItem) => siItem.materialCode == item.materialCode);
            if (matchingItems.isNotEmpty) {
              return '${matchingItems.fold<double>(0, (sum, item) => sum + item.acceptedQty)} (${si.grnDate})';
            }
            return '';
          })
          .where((s) => s.isNotEmpty)
          .join('\n');

      final pendingQty = double.parse(item.quantity) - totalOrderedQty;
      final status = pendingQty <= 0
          ? 'Completed'
          : totalOrderedQty > 0
              ? 'Partially Ordered'
              : 'Pending';

      rows.add(
        PlutoRow(
          cells: {
            'serialNo': PlutoCell(value: serialNo++),
            'jobNo': PlutoCell(value: request.jobNo ?? '-'),
            'prNo': PlutoCell(value: request.prNo),
            'prDate': PlutoCell(value: request.date),
            'partNo': PlutoCell(value: item.materialCode),
            'description': PlutoCell(value: item.materialDescription),
            'prQty': PlutoCell(value: double.parse(item.quantity)),
            'unit': PlutoCell(value: item.unit),
            'requestedBy': PlutoCell(value: request.requiredBy),
            'stockTransfer':
                PlutoCell(value: transfers.isEmpty ? '-' : transfers),
            'poDetails':
                PlutoCell(value: relatedPOs.isEmpty ? '-' : relatedPOs),
            'orderedQty': PlutoCell(value: totalOrderedQty),
            'pendingQty': PlutoCell(value: pendingQty),
            'status': PlutoCell(value: status),
            'actions': PlutoCell(value: ''),
          },
        ),
      );
    }
  } 