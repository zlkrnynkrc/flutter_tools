import 'dart:math' as math;

// Backoff stratejileri için abstract class
abstract class BackoffStrategy {
  Duration calculateDelay(int attempt, Duration initialDelay);
}

class ExponentialBackoff implements BackoffStrategy {
  final double multiplier;
  final Duration? maxDelay;

  const ExponentialBackoff({this.multiplier = 2.0, this.maxDelay});

  @override
  Duration calculateDelay(int attempt, Duration initialDelay) {
    final delay = Duration(
      milliseconds:
          (initialDelay.inMilliseconds * math.pow(multiplier, attempt - 1))
              .toInt(),
    );
    return maxDelay != null && delay > maxDelay! ? maxDelay! : delay;
  }
}

// Linear backoff stratejisi
class LinearBackoff implements BackoffStrategy {
  final Duration increment;
  final Duration? maxDelay;

  LinearBackoff({this.increment = const Duration(seconds: 1), this.maxDelay});

  @override
  Duration calculateDelay(int attempt, Duration initialDelay) {
    final delay = initialDelay + (increment * (attempt - 1));
    return maxDelay != null
        ? Duration(
            milliseconds:
                math.min(delay.inMilliseconds, maxDelay!.inMilliseconds))
        : delay;
  }
}
