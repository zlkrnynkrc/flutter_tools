import 'dart:async';
import 'dart:collection';

class BulkheadSemaphore {
  final int maxConcurrent;
  int _currentCount = 0;
  final Queue<Completer<void>> _waitingQueue = Queue();

  BulkheadSemaphore(this.maxConcurrent);

  Future<void> acquire() {
    if (_currentCount < maxConcurrent) {
      _currentCount++;
      return Future.value();
    } else {
      final completer = Completer<void>();
      _waitingQueue.add(completer);
      return completer.future;
    }
  }

  void release() {
    if (_waitingQueue.isNotEmpty) {
      final next = _waitingQueue.removeFirst();
      next.complete();
    } else {
      _currentCount--;
    }
  }
}
