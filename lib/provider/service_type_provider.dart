import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import '../models/service_type.dart';
import 'base_provider.dart';

final serviceTypeBoxProvider = Provider<Box<ServiceType>>((ref) {
  if (Hive.isBoxOpen('serviceTypes')) {
    return Hive.box<ServiceType>('serviceTypes');
  }
  throw UnimplementedError();
});

final serviceTypeProvider =
    StateNotifierProvider<ServiceTypeNotifier, List<ServiceType>>(
  (ref) => ServiceTypeNotifier(ref.read(serviceTypeBoxProvider)),
);

class ServiceTypeNotifier extends BaseProvider<ServiceType> {
  ServiceTypeNotifier(Box<ServiceType> box) : super(box, 'serviceTypes');

  @override
  Map<String, dynamic> modelToMap(ServiceType model) {
    return {
      'name': model.name,
      'serviceName': model.serviceName,
    };
  }

  @override
  ServiceType mapToModel(Map<String, dynamic> map) {
    return ServiceType(
      name: map['name'] ?? '',
      serviceName: map['serviceName'] ?? '',
    );
  }

  @override
  String getModelId(ServiceType model) => '${model.serviceName}_${model.name}';

  Future<void> loadServiceTypes() => loadData();

  Future<void> addServiceType(String serviceName, String name) =>
      add(ServiceType(name: name, serviceName: serviceName));

  Future<void> deleteServiceType(ServiceType type) => delete(type);

  List<ServiceType> getTypesForService(String serviceName) {
    return state.where((t) => t.serviceName == serviceName).toList();
  }
}
