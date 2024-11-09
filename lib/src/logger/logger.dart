// lib/src/logger_configuration.dart
import 'dart:async';
import 'package:object_tools/src/logger/configuration.dart';
import 'package:object_tools/src/logger/enums.dart';
import 'package:object_tools/src/logger/file_sinks.dart';
import 'package:object_tools/src/logger/log_buffer.dart';
import 'package:object_tools/src/logger/log_event.dart';
import 'package:object_tools/src/logger/log_formatter.dart';

// lib/src/logger.dart
class Logger {
  final LoggerConfiguration _config;
  final List<LogBuffer> _buffers;
  // ignore: unused_field
  final ILogFormatter _formatter;
  bool _isDisposed = false;

  Logger._({
    required LoggerConfiguration config,
    required List<ILogSink> sinks,
    ILogFormatter? formatter,
  })  : _config = config,
        _formatter = formatter ?? DefaultLogFormatter(config),
        _buffers = sinks
            .map((sink) => LogBuffer(
                  sink: sink,
                  autoFlushInterval: config.autoFlushInterval,
                ))
            .toList();

  static Logger create({
    required String appName,
    LogLevel minimumLevel = LogLevel.information,
    bool useConsole = true,
    bool useFile = true,
    String? logDirectory,
    Map<String, dynamic> defaultProperties = const {},
  }) {
    final config = LoggerConfiguration(
      appName: appName,
      minimumLevel: minimumLevel,
      logDirectory: logDirectory ?? 'logs',
      defaultProperties: defaultProperties,
    );

    final sinks = <ILogSink>[];

    if (useConsole) {
      sinks.add(ConsoleSink());
    }

    if (useFile) {
      sinks.add(RotatingFileSink(config: config));
    }

    return Logger._(
      config: config,
      sinks: sinks,
    );
  }

  void _log(
    LogLevel level,
    String message, {
    Map<String, dynamic> properties = const {},
    dynamic exception,
    StackTrace? stackTrace,
  }) {
    if (_isDisposed) {
      throw StateError('Logger has been disposed');
    }

    if (level.index < _config.minimumLevel.index) return;

    final allProperties = Map<String, dynamic>.from(_config.defaultProperties)
      ..addAll(properties);

    String? source;
    if (_config.includeCallSite) {
      source = _getCallSite();
    }

    final logEvent = LogEvent(
      timestamp: DateTime.now(),
      level: level,
      message: message,
      properties: allProperties,
      exception: exception,
      stackTrace: stackTrace ?? (exception == null ? null : StackTrace.current),
      source: source,
    );

    for (final buffer in _buffers) {
      buffer.add(logEvent);
    }
  }

  String? _getCallSite() {
    try {
      final frames = StackTrace.current.toString().split('\n');
      // Skip first frames (logger internal calls)
      for (var i = 0; i < frames.length; i++) {
        if (!frames[i].contains('Logger.') && !frames[i].contains('_log')) {
          final frame = frames[i].trim();
          final uri = Uri.parse(frame);
          return '${uri.pathSegments.last}:${uri.fragment}';
        }
      }
    } catch (_) {
      // Ignore parsing errors
    }
    return null;
  }

  void verbose(String message,
      {Map<String, dynamic> properties = const {}, dynamic exception}) {
    _log(LogLevel.verbose, message,
        properties: properties, exception: exception);
  }

  void debug(String message,
      {Map<String, dynamic> properties = const {}, dynamic exception}) {
    _log(LogLevel.debug, message, properties: properties, exception: exception);
  }

  void information(String message,
      {Map<String, dynamic> properties = const {}, dynamic exception}) {
    _log(LogLevel.information, message,
        properties: properties, exception: exception);
  }

  void warning(String message,
      {Map<String, dynamic> properties = const {}, dynamic exception}) {
    _log(LogLevel.warning, message,
        properties: properties, exception: exception);
  }

  void error(String message,
      {Map<String, dynamic> properties = const {}, dynamic exception}) {
    _log(LogLevel.error, message, properties: properties, exception: exception);
  }

  void fatal(String message,
      {Map<String, dynamic> properties = const {}, dynamic exception}) {
    _log(LogLevel.fatal, message, properties: properties, exception: exception);
  }

  Future<void> dispose() async {
    if (_isDisposed) return;

    _isDisposed = true;
    for (final buffer in _buffers) {
      buffer.dispose();
    }
  }
}
