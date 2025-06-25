import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final syncStatusProvider = StateProvider<String?>((ref) => null);
final syncErrorProvider = StateProvider<String?>((ref) => null);

class SyncStatusWidget extends ConsumerWidget {
  const SyncStatusWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(syncStatusProvider);
    final error = ref.watch(syncErrorProvider);

    if (status == null && error == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(8.0),
      margin: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        color: error != null ? Colors.red.withOpacity(0.1) : Colors.green.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (error != null) ...[
            const Icon(Icons.error_outline, color: Colors.red),
            const SizedBox(width: 8),
            Text(error, style: const TextStyle(color: Colors.red)),
          ] else if (status != null) ...[
            const Icon(Icons.sync, color: Colors.green),
            const SizedBox(width: 8),
            Text(status, style: const TextStyle(color: Colors.green)),
          ],
        ],
      ),
    );
  }
} 