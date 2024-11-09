enum JobLogLevel { debug, info, warning, error, fatal }

/// İş önceliklerini temsil eder
enum JobPriority { low, normal, high, critical }

/// İş durumlarını temsil eder
enum JobStatus { idle, scheduled, running, completed, failed, blocked, paused }

enum ScheduleType { oneTime, recurring }
