// db_connection.dart
import 'package:mysql1/mysql1.dart';
import 'dart:async';

class DatabaseException implements Exception {
  final String message;
  final dynamic error;

  DatabaseException(this.message, [this.error]);

  @override
  String toString() => 'DatabaseException: $message ${error ?? ""}';
}

class DbConnection {
  final String host;
  final int port;
  final String user;
  final String password;
  final String database;
  MySqlConnection? _connection;

  DbConnection({
    required this.host,
    required this.port,
    required this.user,
    required this.password,
    required this.database,
  });

  Future<MySqlConnection> connect() async {
    try {
      final settings = ConnectionSettings(
        host: host,
        port: port,
        user: user,
        password: password,
        db: database,
      );
      _connection = await MySqlConnection.connect(settings);
      return _connection!;
    } catch (e) {
      throw DatabaseException('Connection failed', e);
    }
  }

  Future<void> close() async {
    await _connection?.close();
  }
}

// cache_manager.dart
class CacheManager {
  final Map<String, CacheEntry> _cache = {};
  final Duration defaultDuration;

  CacheManager({this.defaultDuration = const Duration(minutes: 5)});

  void set(String key, dynamic value, [Duration? duration]) {
    final expiry = DateTime.now().add(duration ?? defaultDuration);
    _cache[key] = CacheEntry(value, expiry);
  }

  dynamic get(String key) {
    final entry = _cache[key];
    if (entry == null) return null;

    if (DateTime.now().isAfter(entry.expiry)) {
      _cache.remove(key);
      return null;
    }

    return entry.value;
  }

  void clear() => _cache.clear();
}

class CacheEntry {
  final dynamic value;
  final DateTime expiry;

  CacheEntry(this.value, this.expiry);
}

// stored_procedure.dart
class StoredProcedure {
  final String name;
  final List<dynamic> parameters;

  StoredProcedure(this.name, [this.parameters = const []]);

  String get sql =>
      'CALL $name(${List.filled(parameters.length, '?').join(', ')})';
}

// bulk_operations.dart
class BulkOperation<T> {
  final String sql;
  final List<T> items;
  final List<dynamic> Function(T) parameterExtractor;

  BulkOperation({
    required this.sql,
    required this.items,
    required this.parameterExtractor,
  });
}

// dapper.dart
class Dapper {
  final DbConnection _connection;
  final CacheManager _cacheManager;
  static const int _defaultBatchSize = 1000;

  Dapper(this._connection) : _cacheManager = CacheManager();

  // Mevcut metodlar...

  // Stored Procedure desteği
  Future<List<Map<String, dynamic>>> executeProcedure(
    StoredProcedure procedure, {
    bool useCache = false,
    Duration? cacheDuration,
  }) async {
    try {
      if (useCache) {
        final cacheKey = '${procedure.name}_${procedure.parameters.join("_")}';
        final cachedResult = _cacheManager.get(cacheKey);
        if (cachedResult != null) return cachedResult;
      }

      final conn = await _connection.connect();
      final results = await conn.query(procedure.sql, procedure.parameters);
      final mappedResults = results.map((r) => r.fields).toList();

      if (useCache) {
        final cacheKey = '${procedure.name}_${procedure.parameters.join("_")}';
        _cacheManager.set(cacheKey, mappedResults, cacheDuration);
      }

      return mappedResults;
    } catch (e) {
      throw DatabaseException('Stored procedure execution failed', e);
    }
  }

  // Bulk Insert desteği
  Future<int> bulkInsert<T>(BulkOperation<T> operation) async {
    final conn = await _connection.connect();
    var totalAffected = 0;

    try {
      await conn.query('START TRANSACTION');

      for (var i = 0; i < operation.items.length; i += _defaultBatchSize) {
        final batch = operation.items.skip(i).take(_defaultBatchSize);
        final batchParams = batch.map(operation.parameterExtractor).toList();

        for (final params in batchParams) {
          final result = await conn.query(operation.sql, params);
          totalAffected += result.affectedRows ?? 0;
        }
      }

      await conn.query('COMMIT');
      return totalAffected;
    } catch (e) {
      await conn.query('ROLLBACK');
      throw DatabaseException('Bulk insert failed', e);
    }
  }

  // Async Streaming desteği
  Stream<T> queryStream<T>(
    String sql,
    T Function(Map<String, dynamic>) mapper, {
    Map<String, dynamic>? parameters,
  }) async* {
    try {
      final conn = await _connection.connect();
      final results = await conn.query(sql, parameters?.values.toList() ?? []);

      for (final row in results) {
        yield mapper(row.fields);
      }
    } catch (e) {
      throw DatabaseException('Stream query failed', e);
    }
  }

  // Cache destekli sorgular
  Future<List<T>> queryListCached<T>(
    String sql,
    T Function(Map<String, dynamic>) mapper, {
    Map<String, dynamic>? parameters,
    Duration? cacheDuration,
  }) async {
    final cacheKey = '$sql${parameters?.toString() ?? ""}';
    final cachedResult = _cacheManager.get(cacheKey);

    if (cachedResult != null) {
      return (cachedResult as List).map((item) => mapper(item)).toList();
    }

    final results = await queryList(sql, mapper, parameters: parameters);
    _cacheManager.set(cacheKey,
        results.map((r) => r as Map<String, dynamic>).toList(), cacheDuration);
    return results;
  }

  Future<List<Map<String, dynamic>>> query(
    String sql, {
    Map<String, dynamic>? parameters,
  }) async {
    try {
      final conn = await _connection.connect();
      final results = await conn.query(sql, parameters?.values.toList() ?? []);
      return results.map((r) => r.fields).toList();
    } catch (e) {
      throw DatabaseException('Query execution failed', e);
    }
  }

  Future<T> queryFirst<T>(
    String sql,
    T Function(Map<String, dynamic>) mapper, {
    Map<String, dynamic>? parameters,
  }) async {
    try {
      final results = await query(sql, parameters: parameters);
      if (results.isEmpty) {
        throw DatabaseException('No results found');
      }
      return mapper(results.first);
    } catch (e) {
      throw DatabaseException('QueryFirst execution failed', e);
    }
  }

  Future<T?> queryFirstOrNull<T>(
    String sql,
    T Function(Map<String, dynamic>) mapper, {
    Map<String, dynamic>? parameters,
  }) async {
    try {
      final results = await query(sql, parameters: parameters);
      if (results.isEmpty) return null;
      return mapper(results.first);
    } catch (e) {
      throw DatabaseException('QueryFirstOrNull execution failed', e);
    }
  }

  Future<List<T>> queryList<T>(
    String sql,
    T Function(Map<String, dynamic>) mapper, {
    Map<String, dynamic>? parameters,
  }) async {
    try {
      final results = await query(sql, parameters: parameters);
      return results.map(mapper).toList();
    } catch (e) {
      throw DatabaseException('QueryList execution failed', e);
    }
  }
}
/* 
// Örnek kullanım genişletmeleri
class BatchUser {
  final String name;
  final String email;
  final int age;

  BatchUser({
    required this.name,
    required this.email,
    required this.age,
  });
}

// Örnek kullanımlar:
void main() async {
  final db = DbConnection(
    host: 'localhost',
    port: 3306,
    user: 'root',
    password: 'password',
    database: 'test',
  );

  final dapper = Dapper(db);

  try {
    // 1. Stored Procedure Kullanımı
    final getUserProc = StoredProcedure('GetUserById', [1]);
    final user = await dapper.executeProcedure(
      getUserProc,
      useCache: true,
      cacheDuration: Duration(minutes: 10),
    );

    // 2. Bulk Insert Kullanımı
    final users = List.generate(
      1000,
      (i) => BatchUser(
        name: 'User $i',
        email: 'user$i@example.com',
        age: 20 + (i % 50),
      ),
    );

    final bulkOperation = BulkOperation<BatchUser>(
      sql: 'INSERT INTO users (name, email, age) VALUES (?, ?, ?)',
      items: users,
      parameterExtractor: (user) => [user.name, user.email, user.age],
    );

    final insertedCount = await dapper.bulkInsert(bulkOperation);
    print('Inserted $insertedCount records');

    // 3. Streaming Kullanımı
    await for (final user in dapper.queryStream<User>(
      'SELECT * FROM users',
      UserMapper().fromMap,
    )) {
      print('Streamed user: ${user.name}');
    }

    // 4. Cache'li Sorgu Kullanımı
    final cachedUsers = await dapper.queryListCached<User>(
      'SELECT * FROM users WHERE age > ?',
      UserMapper().fromMap,
      parameters: {'age': 25},
      cacheDuration: Duration(minutes: 15),
    );

  } catch (e) {
    print('Hata oluştu: $e');
  } finally {
    await db.close();
  }
} */