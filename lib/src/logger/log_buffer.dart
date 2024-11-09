import 'dart:async';

import 'package:object_tools/src/logger/log_event.dart';
import 'package:object_tools/src/logger/log_formatter.dart';

class LogBuffer {
  final int maxSize;
  final List<LogEvent> _buffer = [];
  final ILogSink _sink;
  Timer? _flushTimer;

  LogBuffer({
    required ILogSink sink,
    this.maxSize = 100,
    Duration? autoFlushInterval,
  }) : _sink = sink {
    if (autoFlushInterval != null) {
      _flushTimer = Timer.periodic(autoFlushInterval, (_) => flush());
    }
  }

  void add(LogEvent event) {
    _buffer.add(event);
    if (_buffer.length >= maxSize) {
      flush();
    }
  }

  void flush() {
    if (_buffer.isEmpty) return;

    for (final event in _buffer) {
      try {
        _sink.emit(event);
      } catch (e, stackTrace) {
        print('Error writing to log sink: $e\n$stackTrace');
      }
    }

    _buffer.clear();
  }

  void dispose() {
    flush();
    _flushTimer?.cancel();
    _sink.close();
  }
}
