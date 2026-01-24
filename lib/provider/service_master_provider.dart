import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import '../models/service_master.dart';
import 'base_provider.dart';

final serviceMasterBoxProvider = Provider<Box<ServiceMaster>>((ref) {
  throw UnimplementedError();
});

final serviceMasterProvider =
    StateNotifierProvider<ServiceMasterNotifier, List<ServiceMaster>>(
  (ref) => ServiceMasterNotifier(ref.read(serviceMasterBoxProvider)),
);

class ServiceMasterNotifier extends BaseProvider<ServiceMaster> {
  ServiceMasterNotifier(Box<ServiceMaster> box) : super(box, 'serviceMasters');

  @override
  Map<String, dynamic> modelToMap(ServiceMaster model) {
    return {
      'name': model.name,
      'serviceType': model.serviceType,
    };
  }

  @override
  ServiceMaster mapToModel(Map<String, dynamic> map) {
    return ServiceMaster(
      name: map['name'] ?? '',
      serviceType: map['serviceType'] ?? '',
    );
  }

  @override
  String getModelId(ServiceMaster model) => model.name;

  Future<void> loadServices() => loadData();
  Future<void> addService(ServiceMaster service) => add(service);
  Future<void> updateService(ServiceMaster service) => update(service);
  Future<void> deleteService(ServiceMaster service) => delete(service);
}
