import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/universal_parameter.dart';

// Box provider for dependency injection
final universalParameterBoxProvider = Provider<Box<UniversalParameter>>((ref) {
  throw UnimplementedError();
});

class UniversalParameterNotifier
    extends StateNotifier<List<UniversalParameter>> {
  final Box<UniversalParameter> _box;

  UniversalParameterNotifier(this._box) : super([]) {
    _loadParameters();
  }

  void _loadParameters() {
    state = _box.values.toList();
  }

  Future<void> addParameter(String name) async {
    final parameter = UniversalParameter(name: name);
    await _box.add(parameter);
    _loadParameters();
  }

  Future<void> removeParameter(UniversalParameter parameter) async {
    await parameter.delete();
    _loadParameters();
  }
}

final universalParameterProvider =
    StateNotifierProvider<UniversalParameterNotifier, List<UniversalParameter>>(
        (ref) {
  final box = ref.watch(universalParameterBoxProvider);
  return UniversalParameterNotifier(box);
});
