// ignore_for_file: cast_from_null_always_fails

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import '../models/gst.dart';
import 'base_provider.dart';

final gstBoxProvider = Provider<Box<GSTModel>>((ref) {
  throw UnimplementedError();
});

final gstListProvider =
    StateNotifierProvider<GSTNotifier, List<GSTModel>>((ref) {
  return GSTNotifier(ref.read(gstBoxProvider));
});

class GSTNotifier extends BaseProvider<GSTModel> {
  GSTNotifier(Box<GSTModel> box) : super(box, 'gst');

  @override
  Map<String, dynamic> modelToMap(GSTModel gst) {
    return {
      'gstCategory': gst.gstCategory,
      'gstRate': gst.gstRate,
      'cgst': gst.cgst,
      'sgst': gst.sgst,
      'igst': gst.igst,
      'description': gst.description,
    };
  }

  @override
  GSTModel mapToModel(Map<String, dynamic> map) {
    return GSTModel(
      gstCategory: map['gstCategory'] ?? '',
      gstRate: map['gstRate'] ?? '',
      cgst: map['cgst'] ?? '',
      sgst: map['sgst'] ?? '',
      igst: map['igst'] ?? '',
      description: map['description'] ?? '',
    );
  }

  @override
  String getModelId(GSTModel gst) => gst.gstCategory;

  // Get GST by category
  GSTModel? getGSTByCategory(String category) {
    return state.firstWhere(
      (gst) => gst.gstCategory == category,
      orElse: () => null as GSTModel,
    );
  }

  // Generate next sequential GST code
  String generateNextGSTCode() {
    final gstList = state;
    int maxNumber = 0;

    // Find the highest existing number in GST-xxxx format
    for (var gst in gstList) {
      final category = gst.gstCategory;
      if (category.startsWith('GST-') && category.length >= 7) {
        final numberPart = category.substring(4); // Remove "GST-" prefix
        final number = int.tryParse(numberPart);
        if (number != null && number > maxNumber) {
          maxNumber = number;
        }
      }
    }

    // Generate next sequential number with leading zeros
    final nextNumber = maxNumber + 1;
    return 'GST-${nextNumber.toString().padLeft(3, '0')}';
  }

  // Search GST with custom matcher
  List<GSTModel> searchGST(String query) {
    return search(query, (gst, query) {
      return gst.gstCategory.toLowerCase().contains(query) ||
          gst.gstRate.toLowerCase().contains(query) ||
          gst.description.toLowerCase().contains(query);
    });
  }
}
