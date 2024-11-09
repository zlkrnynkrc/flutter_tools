// Geliştirilmiş RetryOptions
import 'package:object_tools/src/retry/backoff_strategy.dart';
import 'package:object_tools/src/retry/enums.dart';
import 'package:object_tools/src/retry/rate_limiter.dart';
import 'package:object_tools/src/retry/time_strategy.dart';

class RetryOptions {
  final int maxAttempts;
  final Duration initialDelay;
  final BackoffStrategy backoffStrategy;
  final TimeoutStrategy? timeoutStrategy;
  final dynamic Function(dynamic)? fallbackValue;
  final void Function(String, RetryLogLevel)? logger;
  final Duration? cacheTtl;
  final bool useCache;
  final RateLimiter? rateLimiter;
  final bool validateResponse;
  final bool Function(dynamic)? responseValidator;

  const RetryOptions({
    this.maxAttempts = 3,
    this.initialDelay = const Duration(milliseconds: 200),
    this.backoffStrategy = const ExponentialBackoff(),
    this.timeoutStrategy,
    this.fallbackValue,
    this.logger,
    this.cacheTtl,
    this.useCache = false,
    this.rateLimiter,
    this.validateResponse = false,
    this.responseValidator,
  });
}
