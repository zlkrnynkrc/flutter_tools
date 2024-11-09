import 'package:object_tools/src/schedular/enums.dart';
import 'package:object_tools/src/schedular/exceptions.dart';

/// Zamanlama kuralları için sınıf
class Schedule {
  final ScheduleType type;
  final Duration interval;
  final DateTime? startTime;
  final DateTime? endTime;

  Schedule({
    required this.type,
    required this.interval,
    this.startTime,
    this.endTime,
  });
}

abstract class Job {
  final String id;
  final String groupName;
  final String description;
  final JobPriority priority;
  JobStatus status;
  DateTime? lastRun;
  DateTime? nextRun;
  int retryCount;
  final int maxRetries;
  final Duration retryDelay;
  Map<String, dynamic> jobData;

  Job({
    required this.id,
    required this.description,
    this.groupName = 'DEFAULT',
    this.priority = JobPriority.normal,
    this.status = JobStatus.idle,
    this.maxRetries = 3,
    this.retryDelay = const Duration(seconds: 30),
    Map<String, dynamic>? jobData,
  })  : retryCount = 0,
        jobData = jobData ?? {};

  Future<void> execute();

  Map<String, dynamic> toJson() => {
        'id': id,
        'groupName': groupName,
        'description': description,
        'priority': priority.toString(),
        'status': status.toString(),
        'lastRun': lastRun?.toIso8601String(),
        'nextRun': nextRun?.toIso8601String(),
        'retryCount': retryCount,
        'jobData': jobData,
      };

  factory Job.fromJson(Map<String, dynamic> json) {
    switch (json['type']) {
      case 'SimpleJob':
        return Job.fromJson(json);
      default:
        throw SchedulerException('Unknown job type: ${json['type']}');
    }
  }
}

abstract class Trigger {
  DateTime? getNextFireTime(DateTime lastFireTime);
  bool isFinished();
}
