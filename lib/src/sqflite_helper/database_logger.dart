// Logger service
import 'package:logger/logger.dart';

class DatabaseLogger {
  final Logger _logger = Logger(
    printer: PrettyPrinter(
      methodCount: 0,
      errorMethodCount: 5,
      lineLength: 50,
      colors: true,
      printEmojis: true,
      dateTimeFormat: DateTimeFormat.dateAndTime,
    ),
  );

  void logQuery(String query, [List<dynamic>? params]) {
    _logger.i('SQL Query: $query\nParameters: $params');
  }

  void logError(String message, dynamic error, [StackTrace? stackTrace]) {
    _logger.e(message, time: null, error: error, stackTrace: stackTrace);
  }

  void logInfo(String message) {
    _logger.i(message);
  }
}
