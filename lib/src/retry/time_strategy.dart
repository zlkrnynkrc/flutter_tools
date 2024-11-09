import 'dart:math' as math;

// Timeout stratejileri için abstract class
abstract class TimeoutStrategy {
  Duration calculateTimeout(int attempt);
}

class FixedTimeout implements TimeoutStrategy {
  final Duration timeout;

  FixedTimeout(this.timeout);

  @override
  Duration calculateTimeout(int attempt) => timeout;
}

class ProgressiveTimeout implements TimeoutStrategy {
  final Duration initialTimeout;
  final double multiplier;
  final Duration? maxTimeout;

  ProgressiveTimeout({
    required this.initialTimeout,
    this.multiplier = 1.5,
    this.maxTimeout,
  });

  @override
  Duration calculateTimeout(int attempt) {
    final timeout = Duration(
      milliseconds:
          (initialTimeout.inMilliseconds * math.pow(multiplier, attempt - 1))
              .round(),
    );
    return maxTimeout != null
        ? Duration(
            milliseconds:
                math.min(timeout.inMilliseconds, maxTimeout!.inMilliseconds))
        : timeout;
  }
}
