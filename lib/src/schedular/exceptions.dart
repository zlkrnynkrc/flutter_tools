/// Özel hata sınıfı
class SchedulerException implements Exception {
  final String message;
  final dynamic originalError;
  final StackTrace? stackTrace;

  SchedulerException(this.message, {this.originalError, this.stackTrace});

  @override
  String toString() =>
      'SchedulerException: $message${originalError != null ? '\nOriginal error: $originalError' : ''}';
}
