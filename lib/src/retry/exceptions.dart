// Hata tipleri
class RetryException implements Exception {
  final String message;
  final dynamic originalError;

  RetryException(this.message, [this.originalError]);

  @override
  String toString() =>
      'RetryException: $message${originalError != null ? ' ($originalError)' : ''}';
}

class CircuitBreakerException implements Exception {
  final String operationKey;
  final DateTime? resetTime;

  CircuitBreakerException(this.operationKey, [this.resetTime]);

  @override
  String toString() =>
      'CircuitBreakerException: Circuit is open for $operationKey'
      '${resetTime != null ? ' (resets at $resetTime)' : ''}';
}

class RateLimitException implements Exception {
  final String operationKey;
  final Duration waitTime;

  RateLimitException(this.operationKey, this.waitTime);

  @override
  String toString() =>
      'RateLimitException: Rate limit exceeded for $operationKey. '
      'Try again in ${waitTime.inSeconds} seconds';
}
