import 'package:hive/hive.dart';

part 'payment_terms.g.dart';

@HiveType(typeId: 52)
class PaymentTerms extends HiveObject {
  @HiveField(0)
  String name;

  PaymentTerms({
    required this.name,
  });

  PaymentTerms copyWith({
    String? name,
  }) {
    return PaymentTerms(
      name: name ?? this.name,
    );
  }
}
