import 'dart:async';

import 'package:object_tools/src/schedular/enums.dart';
import 'package:object_tools/src/schedular/exceptions.dart';
import 'package:object_tools/src/schedular/job_loger.dart';
import 'package:object_tools/src/schedular/job_pool_manager.dart';
import 'package:object_tools/src/schedular/models.dart';
import 'package:object_tools/src/schedular/persistence_manager.dart';
import 'package:object_tools/src/schedular/trigers.dart';

/// Ana zamanlayıcı sınıfı
class JobScheduler {
  final JobLogger _logger;
  final JobPoolManager _poolManager;
  final PersistenceManager _persistenceManager;
  final Map<String, Job> _jobs = {};
  final Map<String, Trigger> _triggers = {};
  final Map<String, Timer> _timers = {};
  final Map<String, List<Job>> _jobGroups = {};
  bool _isRunning = false;

  JobScheduler({
    required String logDirectory,
    required String storageDirectory,
    int maxConcurrentJobs = 5,
  })  : _logger = JobLogger(logDirectory: logDirectory),
        _poolManager = JobPoolManager(maxConcurrentJobs: maxConcurrentJobs),
        _persistenceManager =
            PersistenceManager(storageDirectory: storageDirectory);

  Future<void> initialize() async {
    try {
      final state = await _persistenceManager.loadState();

      if (state.containsKey('jobs')) {
        final jobsJson = state['jobs'] as Map<String, dynamic>;
        for (var jobEntry in jobsJson.entries) {
          final job = Job.fromJson(jobEntry.value);
          _jobs[job.id] = job;
          _jobGroups.putIfAbsent(job.groupName, () => []).add(job);
        }
      }

      if (state.containsKey('triggers')) {
        final triggersJson = state['triggers'] as Map<String, dynamic>;
        for (var triggerEntry in triggersJson.entries) {
          Trigger trigger;
          switch (triggerEntry.value['type']) {
            case 'SimpleTrigger':
              trigger = SimpleTrigger.fromJson(triggerEntry.value);
              break;
            default:
              throw SchedulerException(
                  'Unknown trigger type: ${triggerEntry.value['type']}');
          }
          _triggers[triggerEntry.key] = trigger;
        }
      }

      for (var job in _jobs.values) {
        await _scheduleNextRun(job.id);
      }

      _isRunning = true;
      await _logger.log(
          JobLogLevel.info, 'Scheduler initialized with persisted state');
    } catch (e, stackTrace) {
      await _logger.log(
        JobLogLevel.error,
        'Failed to initialize scheduler',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  Future<void> scheduleJob(Job job, Trigger trigger) async {
    try {
      _jobs[job.id] = job;
      _triggers[job.id] = trigger;
      _jobGroups.putIfAbsent(job.groupName, () => []).add(job);

      await _scheduleNextRun(job.id);
      await _persistenceManager.saveState(_getCurrentState());

      await _logger.log(
        JobLogLevel.info,
        'Scheduled job: ${job.id} (${job.description})',
      );
    } catch (e, stackTrace) {
      await _logger.log(
        JobLogLevel.error,
        'Failed to schedule job: ${job.id}',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  Future<void> pauseJob(String jobId) async {
    final job = _jobs[jobId];
    if (job == null) return;

    job.status = JobStatus.paused;
    _timers[jobId]?.cancel();
    await _persistenceManager.saveState(_getCurrentState());
    await _logger.log(JobLogLevel.info, 'Paused job: $jobId');
  }

  Future<void> resumeJob(String jobId) async {
    final job = _jobs[jobId];
    if (job == null) return;

    job.status = JobStatus.scheduled;
    await _scheduleNextRun(jobId);
    await _persistenceManager.saveState(_getCurrentState());
    await _logger.log(JobLogLevel.info, 'Resumed job: $jobId');
  }

  Future<void> deleteJob(String jobId) async {
    final job = _jobs.remove(jobId);
    if (job == null) return;

    _triggers.remove(jobId);
    _timers[jobId]?.cancel();
    _timers.remove(jobId);
    _jobGroups[job.groupName]?.remove(job);

    await _persistenceManager.saveState(_getCurrentState());
    await _logger.log(JobLogLevel.info, 'Deleted job: $jobId');
  }

  Future<void> pauseGroup(String groupName) async {
    final jobs = _jobGroups[groupName] ?? [];
    for (final job in jobs) {
      await pauseJob(job.id);
    }
  }

  Future<void> resumeGroup(String groupName) async {
    final jobs = _jobGroups[groupName] ?? [];
    for (final job in jobs) {
      await resumeJob(job.id);
    }
  }

  Future<void> _scheduleNextRun(String jobId) async {
    final job = _jobs[jobId];
    final trigger = _triggers[jobId];

    if (job == null || trigger == null || job.status == JobStatus.paused)
      return;

    final lastRun = job.lastRun ?? DateTime.now();
    final nextRun = trigger.getNextFireTime(lastRun);

    if (nextRun == null || trigger.isFinished()) {
      job.status = JobStatus.completed;
      await _persistenceManager.saveState(_getCurrentState());
      return;
    }

    job.nextRun = nextRun;
    job.status = JobStatus.scheduled;

    _timers[jobId]?.cancel();
    _timers[jobId] =
        Timer(nextRun.difference(DateTime.now()), () => _executeJob(job));
  }

  Future<void> _executeJob(Job job) async {
    if (!_isRunning || job.status == JobStatus.paused) return;

    await _poolManager.executeJob(job, () async {
      try {
        job.status = JobStatus.running;
        await _persistenceManager.saveState(_getCurrentState());

        await _logger.log(JobLogLevel.info, 'Starting job: ${job.id}');
        await job.execute();

        job.lastRun = DateTime.now();
        job.status = JobStatus.completed;
        job.retryCount = 0;

        await _logger.log(JobLogLevel.info, 'Completed job: ${job.id}');
      } catch (e, stackTrace) {
        job.status = JobStatus.failed;

        await _logger.log(
          JobLogLevel.error,
          'Job execution failed: ${job.id}',
          error: e,
          stackTrace: stackTrace,
        );

        if (job.retryCount < job.maxRetries) {
          job.retryCount++;
          await _logger.log(
            JobLogLevel.info,
            'Retrying job ${job.id} (Attempt ${job.retryCount} of ${job.maxRetries})',
          );

          Timer(job.retryDelay, () => _executeJob(job));
          return;
        }
      } finally {
        await _persistenceManager.saveState(_getCurrentState());
        await _scheduleNextRun(job.id);
      }
    });
  }

  Map<String, dynamic> _getCurrentState() {
    return {
      'jobs': _jobs.map((id, job) => MapEntry(id, job.toJson())),
      'jobGroups': _jobGroups.map(
          (group, jobs) => MapEntry(group, jobs.map((j) => j.id).toList())),
    };
  }

  Future<void> shutdown() async {
    _isRunning = false;
    for (final timer in _timers.values) {
      timer.cancel();
    }
    _timers.clear();
    await _persistenceManager.saveState(_getCurrentState());
    await _logger.log(JobLogLevel.info, 'Scheduler shutdown completed');
  }
}
