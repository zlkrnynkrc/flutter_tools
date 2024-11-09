// Geliştirilmiş RetryPolicy
import 'package:object_tools/src/retry/bulkhead_semaphore.dart';
import 'package:object_tools/src/retry/cache.dart';
import 'package:object_tools/src/retry/exceptions.dart';
import 'package:object_tools/src/retry/enums.dart';
import 'package:object_tools/src/retry/metrics.dart';
import 'package:object_tools/src/retry/retry_options.dart';

class RetryPolicy {
  final RetryOptions options;
  final _breakers = <String, _CircuitBreakerState>{};
  final _bulkheads = <String, BulkheadSemaphore>{};
  final _cache = Cache<dynamic>();
  final RetryMetrics metrics = RetryMetrics();

  RetryPolicy([this.options = const RetryOptions()]);

  Future<T> execute<T>(
    String operationKey,
    Future<T> Function() operation, {
    bool Function(Exception)? shouldRetry,
    bool useCircuitBreaker = false,
    bool useBulkhead = false,
    int? maxConcurrent,
    Duration? cacheTtl,
    bool validateResponse = false,
    bool Function(T)? responseValidator,
  }) async {
    // Rate limiting kontrolü
    if (options.rateLimiter != null) {
      if (!options.rateLimiter!.checkLimit(operationKey)) {
        final waitTime = options.rateLimiter!.getWaitTime(operationKey);
        throw RateLimitException(
            operationKey, waitTime ?? const Duration(seconds: 1));
      }
    }

    // Cache kontrolü
    if (options.useCache) {
      final cachedResult = _cache.get(operationKey) as T?;
      if (cachedResult != null) {
        _log('Cache hit for $operationKey', RetryLogLevel.debug);
        return cachedResult;
      }
    }

    final stopwatch = Stopwatch()..start();

    try {
      final result = await _executeWithPolicies(
        operationKey,
        operation,
        useCircuitBreaker,
        useBulkhead,
        maxConcurrent,
        shouldRetry,
        validateResponse || options.validateResponse,
        responseValidator ?? options.responseValidator as bool Function(T)?,
      );

      // Başarılı sonucu cache'e ekle
      if (options.useCache) {
        _cache.set(operationKey, result, cacheTtl ?? options.cacheTtl);
      }

      stopwatch.stop();
      metrics.recordSuccess(operationKey, stopwatch.elapsed);

      return result;
    } catch (e) {
      stopwatch.stop();
      metrics.recordFailure(operationKey, stopwatch.elapsed);

      if (options.fallbackValue != null) {
        _log('Using fallback value for $operationKey', RetryLogLevel.info);
        return options.fallbackValue!(e) as T;
      }
      rethrow;
    }
  }

  Future<T> _executeWithPolicies<T>(
    String operationKey,
    Future<T> Function() operation,
    bool useCircuitBreaker,
    bool useBulkhead,
    int? maxConcurrent,
    bool Function(Exception)? shouldRetry,
    bool validateResponse,
    bool Function(T)? responseValidator,
  ) async {
    if (useBulkhead) {
      final bulkhead = _bulkheads.putIfAbsent(
        operationKey,
        () => BulkheadSemaphore(maxConcurrent ?? 10),
      );
      await bulkhead.acquire();
    }

    try {
      if (useCircuitBreaker) {
        return await _executeWithCircuitBreaker(
          operationKey,
          () => _executeWithRetry(
            operation,
            shouldRetry,
            validateResponse,
            responseValidator,
          ),
        );
      } else {
        return await _executeWithRetry(
          operation,
          shouldRetry,
          validateResponse,
          responseValidator,
        );
      }
    } finally {
      if (useBulkhead) {
        _bulkheads[operationKey]?.release();
      }
    }
  }

  Future<T> _executeWithCircuitBreaker<T>(
    String operationKey,
    Future<T> Function() operation,
  ) async {
    final breaker = _breakers.putIfAbsent(
      operationKey,
      () => _CircuitBreakerState(),
    );

    if (breaker.isOpen) {
      if (breaker.shouldReset()) {
        _log('Circuit breaker reset for $operationKey', RetryLogLevel.info);
        breaker.reset();
      } else {
        _log('Circuit breaker open for $operationKey', RetryLogLevel.warning);
        throw Exception('Circuit breaker is open');
      }
    }

    try {
      final result = await operation();
      breaker.reset();
      return result;
    } catch (e) {
      breaker.recordFailure();
      rethrow;
    }
  }

  Future<T> _executeWithRetry<T>(
    Future<T> Function() operation,
    bool Function(Exception)? shouldRetry,
    bool validateResponse,
    bool Function(T)? responseValidator,
  ) async {
    int attempts = 0;

    while (true) {
      try {
        attempts++;
        _log('Attempting operation (attempt $attempts)', RetryLogLevel.debug);

        T result;
        if (options.timeoutStrategy != null) {
          final timeout = options.timeoutStrategy!.calculateTimeout(attempts);
          result = await operation().timeout(timeout);
        } else {
          result = await operation();
        }

        // Response validation
        if (validateResponse &&
            responseValidator != null &&
            !responseValidator(result)) {
          throw RetryException('Response validation failed');
        }

        return result;
      } on Exception catch (e) {
        if (attempts >= options.maxAttempts ||
            (shouldRetry != null && !shouldRetry(e))) {
          _log('Operation failed permanently: $e', RetryLogLevel.error);
          throw RetryException('Maximum retry attempts reached', e);
        }

        final delay = options.backoffStrategy.calculateDelay(
          attempts,
          options.initialDelay,
        );

        _log('Operation failed, retrying in ${delay.inMilliseconds}ms: $e',
            RetryLogLevel.warning);
        await Future.delayed(delay);
      }
    }
  }

  // Diğer yardımcı metodlar...
  void _log(String message, RetryLogLevel level) {
    options.logger?.call(message, level);
  }

  // Metrics
  Map<String, Map<String, dynamic>> getMetrics() => metrics.getMetrics();

  // Cache yönetimi
  void clearCache() => _cache.clear();

  // Circuit Breaker yönetimi
  void resetCircuitBreaker(String operationKey) {
    _breakers[operationKey]?.reset();
  }

  // Rate Limiter durumu
  bool checkRateLimit(String operationKey) {
    return options.rateLimiter?.checkLimit(operationKey) ?? true;
  }
}

class _CircuitBreakerState {
  int failureCount = 0;
  DateTime? lastFailureTime;
  bool isOpen = false;
  final int failureThreshold;
  final Duration resetTimeout;

  _CircuitBreakerState({
    this.failureThreshold = 5,
    this.resetTimeout = const Duration(minutes: 1),
  });

  bool shouldReset() {
    return isOpen &&
        lastFailureTime != null &&
        DateTime.now().difference(lastFailureTime!) >= resetTimeout;
  }

  void recordFailure() {
    failureCount++;
    lastFailureTime = DateTime.now();
    if (failureCount >= failureThreshold) {
      isOpen = true;
    }
  }

  void reset() {
    isOpen = false;
    failureCount = 0;
    lastFailureTime = null;
  }
}
