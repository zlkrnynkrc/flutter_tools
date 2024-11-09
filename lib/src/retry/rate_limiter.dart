// Rate limiting implementasyonu
import 'dart:collection';

class RateLimiter {
  final int maxRequests;
  final Duration window;
  final Map<String, Queue<DateTime>> _requestTimes = {};

  RateLimiter({
    required this.maxRequests,
    required this.window,
  });

  bool checkLimit(String key) {
    final now = DateTime.now();
    final times = _requestTimes.putIfAbsent(key, () => Queue());

    // Remove expired timestamps
    while (times.isNotEmpty && now.difference(times.first) > window) {
      times.removeFirst();
    }

    if (times.length >= maxRequests) {
      return false;
    }

    times.addLast(now);
    return true;
  }

  Duration? getWaitTime(String key) {
    if (_requestTimes[key] == null || _requestTimes[key]!.isEmpty) {
      return null;
    }

    final oldestRequest = _requestTimes[key]!.first;
    final windowEnd = oldestRequest.add(window);
    final now = DateTime.now();

    if (now.isBefore(windowEnd)) {
      return windowEnd.difference(now);
    }
    return null;
  }
}
