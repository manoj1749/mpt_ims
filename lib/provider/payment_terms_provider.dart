import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import '../models/payment_terms.dart';
import 'base_provider.dart';

final paymentTermsBoxProvider = Provider<Box<PaymentTerms>>((ref) {
  throw UnimplementedError();
});

final paymentTermsListProvider =
    StateNotifierProvider<PaymentTermsNotifier, List<PaymentTerms>>(
  (ref) => PaymentTermsNotifier(ref.read(paymentTermsBoxProvider)),
);

class PaymentTermsNotifier extends BaseProvider<PaymentTerms> {
  PaymentTermsNotifier(Box<PaymentTerms> box) : super(box, 'paymentTerms');

  @override
  Map<String, dynamic> modelToMap(PaymentTerms paymentTerms) {
    return {
      'name': paymentTerms.name,
    };
  }

  @override
  PaymentTerms mapToModel(Map<String, dynamic> map) {
    return PaymentTerms(
      name: map['name'] ?? '',
    );
  }

  @override
  String getModelId(PaymentTerms paymentTerms) => paymentTerms.name;

  // Map old method names to new base provider methods
  Future<void> loadPaymentTerms() => loadData();
  Future<void> addPaymentTerm(String name) => add(PaymentTerms(name: name));
  Future<void> updatePaymentTerm(PaymentTerms paymentTerms) => update(paymentTerms);
  Future<void> deletePaymentTerm(PaymentTerms paymentTerms) => delete(paymentTerms);

  // Helper methods
  PaymentTerms? getPaymentTermByName(String name) {
    try {
      return state.firstWhere((term) => term.name == name);
    } catch (_) {
      return null;
    }
  }
}
