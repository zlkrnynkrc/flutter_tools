// Custom exceptions
class DbException implements Exception {
  final String message;
  final String? sql;
  final dynamic originalError;

  DbException(this.message, {this.sql, this.originalError});

  @override
  String toString() =>
      'DatabaseException: $message${sql != null ? '\nSQL: $sql' : ''}';
}
