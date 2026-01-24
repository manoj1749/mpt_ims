// ignore_for_file: cast_from_null_always_fails

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import '../models/state.dart';
import 'base_provider.dart';

final stateBoxProvider = Provider<Box<StateModel>>((ref) {
  throw UnimplementedError();
});

final stateListProvider =
    StateNotifierProvider<StateNotifier, List<StateModel>>((ref) {
  return StateNotifier(ref.read(stateBoxProvider));
});

class StateNotifier extends BaseProvider<StateModel> {
  StateNotifier(Box<StateModel> box) : super(box, 'states');

  @override
  Map<String, dynamic> modelToMap(StateModel state) {
    return {
      'name': state.name,
      'stateCode': state.stateCode,
    };
  }

  @override
  StateModel mapToModel(Map<String, dynamic> map) {
    return StateModel(
      name: map['name'] ?? '',
      stateCode: map['stateCode'] ?? '',
    );
  }

  @override
  String getModelId(StateModel state) => state.stateCode;

  // Get state by name
  StateModel? getStateByName(String name) {
    return state.firstWhere(
      (state) => state.name == name,
      orElse: () => null as StateModel,
    );
  }

  // Generate next sequential state code
  String generateNextStateCode() {
    final states = state;
    int maxNumber = 0;

    // Find the highest existing number in ST-xxxx format
    for (var state in states) {
      final code = state.stateCode;
      if (code.startsWith('ST-') && code.length >= 6) {
        final numberPart = code.substring(3); // Remove "ST-" prefix
        final number = int.tryParse(numberPart);
        if (number != null && number > maxNumber) {
          maxNumber = number;
        }
      }
    }

    // Generate next sequential number with leading zeros
    final nextNumber = maxNumber + 1;
    return 'ST-${nextNumber.toString().padLeft(3, '0')}';
  }

  // Search states with custom matcher
  List<StateModel> searchStates(String query) {
    return search(query, (state, query) {
      return state.name.toLowerCase().contains(query) ||
          state.stateCode.toLowerCase().contains(query);
    });
  }
}
