import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/quality_inspection.dart';
import '../models/material_rating_rule.dart';
import '../provider/quality_inspection_provider.dart';
import '../provider/material_rating_rule_provider.dart';
import '../provider/supplier_provider.dart';

class SupplierRatingService {
  /// Calculate supplier quality rating based on inspection history
  /// This should be called after completing an inspection
  static Future<void> updateSupplierRating(
    WidgetRef ref,
    String supplierName,
  ) async {
    try {
      // Get supplier to find supplier code
      final suppliers = ref.read(supplierListProvider);
      final supplier = suppliers.firstWhere(
        (s) => s.name == supplierName,
        orElse: () => throw Exception('Supplier not found: $supplierName'),
      );
      
      final supplierCode = supplier.vendorCode;
      
      // Get all quality inspections for this supplier
      final allInspections = ref.read(qualityInspectionProvider);
      final supplierInspections = allInspections
          .where((inspection) => inspection.supplierName == supplierName)
          .toList();

      if (supplierInspections.isEmpty) {
        // No inspections yet, keep default rating
        print('No inspections found for $supplierName');
        return;
      }

      // Get rating rule for this supplier code
      final ratingRules = ref.read(materialRatingRuleProvider);
      final supplierRule = ratingRules.firstWhere(
        (rule) => rule.materialCode == supplierCode,
        orElse: () {
          print('No rating rule found for supplier code: $supplierCode, using defaults');
          return MaterialRatingRule(
            materialCode: supplierCode,
            lotAcceptedRating: 5.0,
            lotRejectedRating: 0.0,
          );
        },
      );

      // Calculate average rating from all inspections
      double totalRating = 0.0;
      int ratingCount = 0;

      for (var inspection in supplierInspections) {
        for (var item in inspection.items) {
          // Calculate rejection percentage
          double rejectionPercent = 0.0;
          if (item.inspectedQty > 0) {
            rejectionPercent = (item.rejectedQty / item.inspectedQty) * 100;
          }

          // Get rating for this inspection item
          final rating = supplierRule.calculateRating(
            item.usageDecision,
            rejectionPercent,
          );

          if (rating > 0) {
            totalRating += rating;
            ratingCount++;
          }
        }
      }

      // Calculate average rating
      double averageRating = ratingCount > 0 ? totalRating / ratingCount : 0.0;
      
      // Ensure rating is between 0 and 5
      averageRating = averageRating.clamp(0.0, 5.0);

      print('Calculated average rating for $supplierName: $averageRating (from $ratingCount inspections)');

      // Update the supplier's quality rating
      supplier.qualityRating = averageRating;
      
      // Use the provider's update method to ensure proper sync
      await ref.read(supplierListProvider.notifier).updateSupplier(supplier.key, supplier);

      print('✓ Successfully updated supplier $supplierName (code: $supplierCode) rating to $averageRating');
    } catch (e) {
      print('✗ Error updating supplier rating: $e');
    }
  }

  /// Calculate rating for a single inspection
  static double calculateInspectionRating(
    InspectionItem item,
    MaterialRatingRule rule,
  ) {
    double rejectionPercent = 0.0;
    if (item.inspectedQty > 0) {
      rejectionPercent = (item.rejectedQty / item.inspectedQty) * 100;
    }

    return rule.calculateRating(item.usageDecision, rejectionPercent);
  }

  /// Get supplier rating summary
  static Map<String, dynamic> getSupplierRatingSummary(
    WidgetRef ref,
    String supplierName,
  ) {
    final allInspections = ref.read(qualityInspectionProvider);
    final supplierInspections = allInspections
        .where((inspection) => inspection.supplierName == supplierName)
        .toList();

    int totalInspections = 0;
    int lotAccepted = 0;
    int lotRejected = 0;
    int partialAcceptance = 0;
    int recheck = 0;

    for (var inspection in supplierInspections) {
      for (var item in inspection.items) {
        totalInspections++;
        if (item.usageDecision == 'Lot Accepted') {
          lotAccepted++;
        } else if (item.usageDecision == 'Lot Rejected') {
          lotRejected++;
        } else if (item.usageDecision.contains('Partial') ||
            item.usageDecision == 'Conditionally Accepted') {
          partialAcceptance++;
        } else if (item.usageDecision == '100% Recheck') {
          recheck++;
        }
      }
    }

    return {
      'totalInspections': totalInspections,
      'lotAccepted': lotAccepted,
      'lotRejected': lotRejected,
      'partialAcceptance': partialAcceptance,
      'recheck': recheck,
      'acceptanceRate': totalInspections > 0
          ? (lotAccepted / totalInspections * 100).toStringAsFixed(1)
          : '0.0',
    };
  }
}
