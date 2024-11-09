import 'dart:io';
import 'package:object_tools/src/schedular/enums.dart';
import 'package:path/path.dart' as path;

class JobLogger {
  final String logDirectory;
  final File _logFile;
  final bool consoleOutput;

  JobLogger({
    required this.logDirectory,
    this.consoleOutput = true,
  }) : _logFile = File(path.join(logDirectory,
            'scheduler_${DateTime.now().toIso8601String().substring(0, 10)}.log')) {
    if (!Directory(logDirectory).existsSync()) {
      Directory(logDirectory).createSync(recursive: true);
    }
  }

  Future<void> log(JobLogLevel level, String message,
      {dynamic error, StackTrace? stackTrace}) async {
    final timestamp = DateTime.now().toIso8601String();
    final logEntry =
        '$timestamp [${level.name.toUpperCase()}] $message${error != null ? '\nError: $error' : ''}${stackTrace != null ? '\nStackTrace: $stackTrace' : ''}\n';

    if (consoleOutput) {
      print(logEntry);
    }

    await _logFile.writeAsString(logEntry, mode: FileMode.append);
  }
}
