import 'package:object_tools/src/logger/enums.dart';

class LogEvent {
  final DateTime timestamp;
  final LogLevel level;
  final String message;
  final Map<String, dynamic> properties;
  final dynamic exception;
  final StackTrace? stackTrace;
  final String? source;

  LogEvent({
    required this.timestamp,
    required this.level,
    required this.message,
    this.properties = const {},
    this.exception,
    this.stackTrace,
    this.source,
  });
}
