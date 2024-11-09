///```dart
///const config = DatabaseConfig(
/// databaseName: 'my_app.db',
/// version: 1,
/// migrationScripts: [
///   '''
///   CREATE TABLE users (
///     id INTEGER PRIMARY KEY AUTOINCREMENT,
///     name TEXT NOT NULL,
///     age INTEGER,
///     created_at TEXT,
///     updated_at TEXT
///   )
///   '''
/// ],
/// logQueries: true,
/// enableForeignKeys: true,
/// );
/// ```
class DatabaseConfig {
  final String databaseName;
  final int version;
  final List<String> migrationScripts;
  final bool logQueries;
  final bool enableForeignKeys;

  const DatabaseConfig({
    required this.databaseName,
    required this.version,
    this.migrationScripts = const [],
    this.logQueries = false,
    this.enableForeignKeys = true,
  });
}
