// Kullanım örneği:
import 'package:object_tools/src/retry/retry.dart';

void example() async {
  final policy = RetryPolicy(
    RetryOptions(
      maxAttempts: 3,
      initialDelay: const Duration(milliseconds: 200),
      backoffStrategy: const ExponentialBackoff(
        multiplier: 2.0,
        maxDelay: Duration(seconds: 10),
      ),
      timeoutStrategy: ProgressiveTimeout(
        initialTimeout: const Duration(seconds: 1),
        multiplier: 1.5,
        maxTimeout: const Duration(seconds: 5),
      ),
      rateLimiter: RateLimiter(
        maxRequests: 100,
        window: const Duration(minutes: 1),
      ),
      useCache: true,
      cacheTtl: const Duration(minutes: 5),
      validateResponse: true,
      responseValidator: (response) {
        // Örnek response validasyonu
        if (response is Map) {
          return response.containsKey('status') &&
              response['status'] == 'success';
        }
        return true;
      },
      logger: (message, level) => print('[$level] $message'),
    ),
  );

  try {
    final result = await policy.execute(
      'api-call',
      () => someApiCall(),
      useCircuitBreaker: true,
      useBulkhead: true,
      maxConcurrent: 5,
      responseValidator: (response) {
        // Özel response validasyonu
        return response.isEmpty;
      },
    );

    print('Operation succeeded: $result');

    // Metrikleri kontrol et
    print('Metrics: ${policy.getMetrics()}');
  } on RetryException catch (e) {
    print('Retry failed: $e');
  } on CircuitBreakerException catch (e) {
    print('Circuit breaker open: $e');
  } on RateLimitException catch (e) {
    print('Rate limit exceeded: $e');
  }
}
