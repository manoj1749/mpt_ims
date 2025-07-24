import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import '../models/universal_parameter.dart';
import 'base_provider.dart';

final universalParameterBoxProvider = Provider<Box<UniversalParameter>>((ref) {
  throw UnimplementedError();
});

final universalParameterProvider =
    StateNotifierProvider<UniversalParameterNotifier, List<UniversalParameter>>(
  (ref) => UniversalParameterNotifier(ref.read(universalParameterBoxProvider)),
);

class UniversalParameterNotifier extends BaseProvider<UniversalParameter> {
  UniversalParameterNotifier(Box<UniversalParameter> box)
      : super(box, 'universalParameters');

  @override
  Map<String, dynamic> modelToMap(UniversalParameter parameter) {
    return {
      'name': parameter.name,
    };
  }

  @override
  UniversalParameter mapToModel(Map<String, dynamic> map) {
    return UniversalParameter(
      name: map['name'] ?? '',
    );
  }

  @override
  String getModelId(UniversalParameter parameter) => parameter.name;

  // Map old method names to new base provider methods
  Future<void> loadParameters() => loadData();
  Future<void> addParameter(String name) => add(UniversalParameter(name: name));
  Future<void> deleteParameter(UniversalParameter parameter) => delete(parameter);
  Future<void> removeParameter(UniversalParameter parameter) => delete(parameter);

  // Helper methods
  UniversalParameter? getParameterByName(String name) {
    try {
      return state.firstWhere((param) => param.name == name);
    } catch (_) {
      return null;
    }
  }
}
