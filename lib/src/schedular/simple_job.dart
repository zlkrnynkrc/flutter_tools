import 'package:object_tools/src/schedular/enums.dart';
import 'package:object_tools/src/schedular/models.dart';

class SimpleJob extends Job {
  SimpleJob({
    required super.id,
    required super.description,
    super.groupName,
    super.priority,
    super.status,
    super.maxRetries,
    super.retryDelay,
    super.jobData,
  });

  @override
  Future<void> execute() async {
    // İşin yapılması gereken işlemler burada tanımlanır.
    print('Executing SimpleJob: $id');
  }

  factory SimpleJob.fromJson(Map<String, dynamic> json) {
    return SimpleJob(
      id: json['id'],
      description: json['description'],
      groupName: json['groupName'] ?? 'DEFAULT',
      priority: JobPriority.values
          .firstWhere((e) => e.toString() == json['priority']),
      status:
          JobStatus.values.firstWhere((e) => e.toString() == json['status']),
      maxRetries: json['maxRetries'] ?? 3,
      retryDelay: Duration(seconds: json['retryDelay'] ?? 30),
      jobData: json['jobData'] ?? {},
    );
  }
}
