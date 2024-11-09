import 'package:intl/intl.dart';
import 'package:object_tools/src/logger/configuration.dart';
import 'package:object_tools/src/logger/log_event.dart';

abstract class ILogFormatter {
  String format(LogEvent event);
}

abstract class ILogSink {
  void emit(LogEvent logEvent);
  void close();
}

class DefaultLogFormatter implements ILogFormatter {
  final LoggerConfiguration config;

  DefaultLogFormatter(this.config);

  @override
  String format(LogEvent event) {
    final buffer = StringBuffer();
    final timestamp = DateFormat(config.dateTimeFormat).format(event.timestamp);

    buffer.write('[$timestamp] ');
    buffer.write('[${event.level.toString().split('.').last.toUpperCase()}] ');
    buffer.write('[${config.appName}] ');

    if (event.source != null) {
      buffer.write('[${event.source}] ');
    }

    buffer.write(event.message);

    if (event.properties.isNotEmpty) {
      buffer.write('\nProperties: ');
      event.properties.forEach((key, value) {
        buffer.write('\n  $key: $value');
      });
    }

    if (event.exception != null) {
      buffer.write('\nException: ${event.exception}');
      if (config.includeStackTrace && event.stackTrace != null) {
        buffer.write('\nStackTrace:\n${event.stackTrace}');
      }
    }

    return buffer.toString();
  }
}
