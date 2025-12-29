import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import '../models/service_name.dart';
import 'base_provider.dart';

final serviceNameBoxProvider = Provider<Box<ServiceName>>((ref) {
  if (Hive.isBoxOpen('serviceNames')) {
    return Hive.box<ServiceName>('serviceNames');
  }
  throw UnimplementedError();
});

final serviceNameProvider =
    StateNotifierProvider<ServiceNameNotifier, List<ServiceName>>(
  (ref) => ServiceNameNotifier(ref.read(serviceNameBoxProvider)),
);

class ServiceNameNotifier extends BaseProvider<ServiceName> {
  ServiceNameNotifier(Box<ServiceName> box) : super(box, 'serviceNames');

  @override
  Map<String, dynamic> modelToMap(ServiceName model) {
    return {
      'name': model.name,
    };
  }

  @override
  ServiceName mapToModel(Map<String, dynamic> map) {
    return ServiceName(
      name: map['name'] ?? '',
    );
  }

  @override
  String getModelId(ServiceName model) => model.name;

  Future<void> loadServiceNames() => loadData();
  Future<void> addServiceName(String name) => add(ServiceName(name: name));
  Future<void> deleteServiceName(ServiceName service) => delete(service);
}
