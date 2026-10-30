import 'dart:io';

import 'package:path_provider/path_provider.dart';

class AppDiagnosticLogger {
  static String? _logPath;

  static Future<void> initialize() async {
    final documentsDirectory = await getApplicationDocumentsDirectory();
    final logDirectory = Directory(
      '${documentsDirectory.path}${Platform.pathSeparator}'
      'MPT_IMS${Platform.pathSeparator}Logs',
    );
    await logDirectory.create(recursive: true);
    _logPath = '${logDirectory.path}${Platform.pathSeparator}app.log';
  }

  static void write(String message) {
    final path = _logPath;
    if (path == null) {
      print('[APP DIAGNOSTICS] $message');
      return;
    }

    try {
      File(path).writeAsStringSync(
        '${DateTime.now().toIso8601String()} $message\n',
        mode: FileMode.append,
        flush: true,
      );
    } catch (error) {
      print('[APP DIAGNOSTICS] Could not write log: $error');
      print('[APP DIAGNOSTICS] $message');
    }
  }
}
