import 'package:object_tools/src/logger/enums.dart';

class LoggerConfiguration {
  final String appName;
  final LogLevel minimumLevel;
  final bool includeCallSite;
  final bool includeStackTrace;
  final String dateTimeFormat;
  final int maxLogFileSize; // KB cinsinden
  final int maxLogFiles;
  final String logDirectory;
  final Duration? autoFlushInterval;
  final Map<String, dynamic> defaultProperties;

  LoggerConfiguration({
    required this.appName,
    this.minimumLevel = LogLevel.information,
    this.includeCallSite = false,
    this.includeStackTrace = true,
    this.dateTimeFormat = 'yyyy-MM-dd HH:mm:ss.SSS',
    this.maxLogFileSize = 10240, // 10MB
    this.maxLogFiles = 5,
    this.logDirectory = 'logs',
    this.autoFlushInterval = const Duration(seconds: 30),
    this.defaultProperties = const {},
  });
}
