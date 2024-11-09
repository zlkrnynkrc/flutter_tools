import 'dart:math' as math;

class RetryMetrics {
  final _metrics = <String, _OperationMetrics>{};

  void recordSuccess(String operationKey, Duration duration) {
    _metrics.putIfAbsent(operationKey, () => _OperationMetrics())
      ..recordSuccess(duration);
  }

  void recordFailure(String operationKey, Duration duration) {
    _metrics.putIfAbsent(operationKey, () => _OperationMetrics())
      ..recordFailure(duration);
  }

  Map<String, Map<String, dynamic>> getMetrics() {
    return _metrics.map((key, value) => MapEntry(key, value.toMap()));
  }
}

class _OperationMetrics {
  int successCount = 0;
  int failureCount = 0;
  Duration totalDuration = Duration.zero;
  Duration? minDuration;
  Duration? maxDuration;

  void recordSuccess(Duration duration) {
    successCount++;
    _updateDuration(duration);
  }

  void recordFailure(Duration duration) {
    failureCount++;
    _updateDuration(duration);
  }

  void _updateDuration(Duration duration) {
    totalDuration += duration;
    minDuration = minDuration == null
        ? duration
        : Duration(
            microseconds:
                math.min(minDuration!.inMicroseconds, duration.inMicroseconds));
    maxDuration = maxDuration == null
        ? duration
        : Duration(
            microseconds:
                math.max(maxDuration!.inMicroseconds, duration.inMicroseconds));
  }

  Map<String, dynamic> toMap() {
    return {
      'successCount': successCount,
      'failureCount': failureCount,
      'totalDuration': totalDuration.inMilliseconds,
      'minDuration': minDuration?.inMilliseconds,
      'maxDuration': maxDuration?.inMilliseconds,
      'averageDuration': successCount + failureCount > 0
          ? totalDuration.inMilliseconds / (successCount + failureCount)
          : null,
      'successRate': successCount + failureCount > 0
          ? successCount / (successCount + failureCount)
          : null,
    };
  }
}
