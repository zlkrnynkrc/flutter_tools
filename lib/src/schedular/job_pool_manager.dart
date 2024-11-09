import 'dart:async';

import 'package:object_tools/src/schedular/models.dart';

/// İş havuzu yöneticisi
class JobPoolManager {
  final int maxConcurrentJobs;
  final Map<String, Completer<void>> _runningJobs = {};

  JobPoolManager({this.maxConcurrentJobs = 5});

  Future<void> executeJob(Job job, Future<void> Function() execution) async {
    while (_runningJobs.length >= maxConcurrentJobs) {
      await Future.wait(_runningJobs.values.map((c) => c.future));
    }

    final completer = Completer<void>();
    _runningJobs[job.id] = completer;

    try {
      await execution();
    } finally {
      _runningJobs.remove(job.id);
      completer.complete();
    }
  }
}
