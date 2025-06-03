import 'package:flutter/material.dart';
import 'package:pluto_grid/pluto_grid.dart';

class PlutoGridConfigurations {
  static PlutoGridConfiguration darkMode({
    double headerHeight = 56.0,
    double rowHeight = 45.0,
    double columnFilterHeight = 50.0,
  }) {
    return PlutoGridConfiguration(
      columnFilter: const PlutoGridColumnFilterConfig(
        filters: [...FilterHelper.defaultFilters],
      ),
      style: PlutoGridStyleConfig(
        gridBorderColor: Colors.grey[700]!,
        gridBackgroundColor: Colors.grey[900]!,
        borderColor: Colors.grey[700]!,
        iconColor: Colors.grey[300]!,
        rowColor: Colors.grey[850]!,
        oddRowColor: Colors.grey[800]!,
        evenRowColor: Colors.grey[850]!,
        activatedColor: Colors.blue[900]!,
        cellTextStyle: TextStyle(
          color: Colors.grey[200]!,
          fontSize: 13,
        ),
        columnTextStyle: TextStyle(
          color: Colors.grey[200]!,
          fontWeight: FontWeight.bold,
          fontSize: 13,
        ),
        rowHeight: rowHeight,
        columnHeight: headerHeight,
        columnFilterHeight: columnFilterHeight,
        defaultColumnTitlePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        defaultColumnFilterPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        defaultCellPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        enableColumnBorderVertical: true,
        enableColumnBorderHorizontal: true,
        enableCellBorderVertical: true,
        enableCellBorderHorizontal: true,
        enableRowColorAnimation: false,
        gridPopupBorderRadius: BorderRadius.circular(4),
        menuBackgroundColor: Colors.grey[900]!,
        cellColorInReadOnlyState: Colors.grey[900]!,
        cellColorInEditState: Colors.grey[800]!,
      ),
      columnSize: const PlutoGridColumnSizeConfig(
        autoSizeMode: PlutoAutoSizeMode.none,
        resizeMode: PlutoResizeMode.normal,
      ),
      scrollbar: const PlutoGridScrollbarConfig(
        isAlwaysShown: true,
        scrollbarThickness: 8,
        hoverWidth: 20,
      ),
    );
  }
} 