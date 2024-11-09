import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:object_tools/src/logger/configuration.dart';
import 'package:object_tools/src/logger/log_buffer.dart';
import 'package:object_tools/src/logger/log_event.dart';
import 'package:object_tools/src/logger/log_formatter.dart';

class ConsoleSink implements ILogSink {
  @override
  void emit(LogEvent logEvent) {
    final levelString = logEvent.level.toString().split('.').last.toUpperCase();
    final timestamp = logEvent.timestamp.toIso8601String();

    String message = '[$timestamp] $levelString: ${logEvent.message}';

    if (logEvent.properties.isNotEmpty) {
      message += '\nProperties: ${logEvent.properties}';
    }

    if (logEvent.exception != null) {
      message += '\nException: ${logEvent.exception}';
    }

    if (kDebugMode) {
      print(message);
    }
  }

  @override
  void close() {}
}

class _InternalFileSink implements ILogSink {
  IOSink? _sink;

  @override
  void emit(LogEvent logEvent) {
    if (_sink == null) {
      return;
    }

    _sink!.write('$logEvent\n');
  }

  @override
  Future<void> close() async {
    if (_sink != null) {
      await _sink!.flush();
      await _sink!.close();
      _sink = null;
    }
  }

  set sink(IOSink? value) {
    _sink = value;
  }
}

class RotatingFileSink implements ILogSink {
  final LoggerConfiguration config;
  final ILogFormatter formatter;
  File? _currentFile;
  IOSink? _currentSink;
  int _currentFileSize = 0;
  final LogBuffer _buffer;

  RotatingFileSink({
    required this.config,
    ILogFormatter? formatter,
  })  : formatter = formatter ?? DefaultLogFormatter(config),
        _buffer = LogBuffer(
          sink: _InternalFileSink(),
          autoFlushInterval: config.autoFlushInterval,
        ) {
    _initializeDirectory();
    _createNewLogFile();
  }

  void _initializeDirectory() {
    final dir = Directory(config.logDirectory);
    if (!dir.existsSync()) {
      dir.createSync(recursive: true);
    }
  }

  Future<void> _createNewLogFile() async {
    final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
    final fileName = '${config.appName}_$timestamp.log';
    final filePath = '${config.logDirectory}/$fileName';

    _currentFile = File(filePath);
    _currentSink = _currentFile!.openWrite(mode: FileMode.append);
    _currentFileSize = 0;

    await _removeOldLogFiles();
  }

  Future<void> _removeOldLogFiles() async {
    final dir = Directory(config.logDirectory);
    final files = await dir
        .list()
        .where((entity) => entity is File && entity.path.endsWith('.log'))
        .toList();

    if (files.length > config.maxLogFiles) {
      files.sort(
          (a, b) => b.statSync().modified.compareTo(a.statSync().modified));

      for (var i = config.maxLogFiles; i < files.length; i++) {
        await files[i].delete();
      }
    }
  }

  @override
  void emit(LogEvent logEvent) {
    final formattedLog = formatter.format(logEvent);
    final logSize = formattedLog.length;

    if (_currentFileSize + logSize > config.maxLogFileSize * 1024) {
      _rotateLog();
    }

    _buffer.add(logEvent);
    _currentFileSize += logSize;
  }

  Future<void> _rotateLog() async {
    await _currentSink?.flush();
    await _currentSink?.close();
    await _createNewLogFile();
  }

  @override
  Future<void> close() async {
    _buffer.dispose();
    await _currentSink?.flush();
    await _currentSink?.close();
  }
}
