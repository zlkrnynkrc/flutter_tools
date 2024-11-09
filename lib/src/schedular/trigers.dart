import 'package:object_tools/src/schedular/models.dart';

class SimpleTrigger extends Trigger {
  final Duration interval;
  final int repeatCount;
  final int _currentCount = 0;

  SimpleTrigger(this.interval, {this.repeatCount = -1});

  @override
  DateTime? getNextFireTime(DateTime lastFireTime) {
    if (isFinished()) return null;
    return lastFireTime.add(interval);
  }

  @override
  bool isFinished() {
    return repeatCount != -1 && _currentCount >= repeatCount;
  }

  factory SimpleTrigger.fromJson(Map<String, dynamic> json) {
    return SimpleTrigger(
      Duration(seconds: json['interval']),
      repeatCount: json['repeatCount'] ?? -1,
    );
  }
}
