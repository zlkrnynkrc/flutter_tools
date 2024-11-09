// Example usage
import 'package:object_tools/src/sqflite_helper/sqflite_helper.dart';

void main() async {
  // Database configuration
  const config = DatabaseConfig(
    databaseName: 'my_app.db',
    version: 1,
    migrationScripts: [
      '''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        age INTEGER,
        created_at TEXT,
        updated_at TEXT
      )
      '''
    ],
    logQueries: true,
    enableForeignKeys: true,
  );

  // Initialize database helper
  final dbHelper = DatabaseHelper(config: config);

  // Create repository
  final userRepo = Repository<User>(
    dbHelper,
    'users',
    () => User(),
  );

  try {
    // Complex query example
    final queryBuilder = QueryBuilder<User>('users')
        .select(['id', 'name', 'age'])
        .where('age > ?', [16])
        .where('name LIKE ?', ['%ali%'])
        .orderBy('age', desc: true)
        .limit(10);

    final users = await userRepo.query(queryBuilder);
    print(users);
    // Transaction example
    await userRepo.transaction((db) async {
      final user = User(name: 'Ali', age: 25);
      await userRepo.insert(user);

      user.age = 26;
      await userRepo.update(user);
    });
  } catch (e) {
    print('An error occurred: $e');
  }
}

// Example model
class User extends BaseEntity {
  String? name;
  int? age;

  User({this.name, this.age});

  @override
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'age': age,
    };
  }

  @override
  void fromMap(Map<String, dynamic> map) {
    id = map['id'];
    name = map['name'];
    age = map['age'];
  }
}
