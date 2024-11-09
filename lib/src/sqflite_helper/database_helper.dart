// Enhanced database helper
import 'package:object_tools/src/sqflite_helper/database_configuration.dart';
import 'package:object_tools/src/sqflite_helper/database_logger.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  static Database? _database;
  final DatabaseConfig config;
  final DatabaseLogger logger;

  ///```dart
  ///void main() async {
  ///   Database configuration
  /// const config = DatabaseConfig(
  ///   databaseName: 'my_app.db',
  ///   version: 1,
  ///   migrationScripts: [
  ///     '''
  ///     CREATE TABLE users (
  ///       id INTEGER PRIMARY KEY AUTOINCREMENT,
  ///       name TEXT NOT NULL,
  ///       age INTEGER,
  ///       created_at TEXT,
  ///       updated_at TEXT
  ///     )
  ///     '''
  ///   ],
  ///   logQueries: true,
  ///   enableForeignKeys: true,
  /// );
  ///  Initialize database helper
  /// final dbHelper = DatabaseHelper(config: config);
  ///  Create repository
  /// final userRepo = Repository<User>(
  ///   dbHelper,
  ///   'users',
  ///   () => User(),
  /// );
  /// try {
  ///   // Complex query example
  ///   final queryBuilder = QueryBuilder<User>('users')
  ///       .select(['id', 'name', 'age'])
  ///       .where('age > ?', [16])
  ///       .where('name LIKE ?', ['%ali%'])
  ///       .orderBy('age', desc: true)
  ///       .limit(10);
  ///   final users = await userRepo.query(queryBuilder);
  ///  Transaction example
  ///   await userRepo.transaction((db) async {
  ///     final user = User(name: 'Ali', age: 25);
  ///     await userRepo.insert(user);
  ///     user.age = 26;
  ///     await userRepo.update(user);
  ///   });
  /// } catch (e) {
  ///   print('An error occurred: $e');
  /// }
  ///
  ///  Example model
  ///lass User extends BaseEntity {
  /// String? name;
  /// int? age;
  /// User({this.name, this.age});
  /// @override
  /// Map<String, dynamic> toMap() {
  ///   return {
  ///     'id': id,
  ///     'name': name,
  ///     'age': age,
  ///   };
  /// }
////// @override
  /// void fromMap(Map<String, dynamic> map) {
  ///   id = map['id'];
  ///   name = map['name'];
  ///   age = map['age'];
  /// }
  ///```
  DatabaseHelper({
    required this.config,
    DatabaseLogger? logger,
  }) : logger = logger ?? DatabaseLogger();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await initDatabase();
    return _database!;
  }

  Future<Database> initDatabase() async {
    try {
      String path = join(await getDatabasesPath(), config.databaseName);

      return await openDatabase(
        path,
        version: config.version,
        onCreate: _onCreate,
        onUpgrade: _onUpgrade,
        onConfigure: _onConfigure,
      );
    } catch (e, stackTrace) {
      logger.logError('Failed to initialize database', e, stackTrace);
      rethrow;
    }
  }

  Future<void> _onConfigure(Database db) async {
    if (config.enableForeignKeys) {
      await db.execute('PRAGMA foreign_keys = ON');
    }
  }

  Future<void> _onCreate(Database db, int version) async {
    try {
      for (var script in config.migrationScripts) {
        await db.execute(script);
        logger.logInfo('Executed migration script: $script');
      }
    } catch (e, stackTrace) {
      logger.logError('Failed to create database', e, stackTrace);
      rethrow;
    }
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    try {
      for (var i = oldVersion; i < newVersion; i++) {
        if (i < config.migrationScripts.length) {
          await db.execute(config.migrationScripts[i]);
          logger.logInfo('Executed upgrade script ${i + 1}');
        }
      }
    } catch (e, stackTrace) {
      logger.logError('Failed to upgrade database', e, stackTrace);
      rethrow;
    }
  }
}
