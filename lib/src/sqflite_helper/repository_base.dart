// Enhanced repository
import 'package:object_tools/src/sqflite_helper/base_entity.dart';
import 'package:object_tools/src/sqflite_helper/database_helper.dart';
import 'package:object_tools/src/sqflite_helper/exceptions.dart';
import 'package:object_tools/src/sqflite_helper/query_builder.dart';
import 'package:sqflite/sqflite.dart';

class Repository<T extends BaseEntity> {
  final DatabaseHelper _dbHelper;
  final String tableName;
  final T Function() createEntity;

  ///```dart
  ///final userRepo = Repository<User>(
  ///   dbHelper,
  ///   'users',
  ///   () => User(),
  /// );
  ///```
  Repository(this._dbHelper, this.tableName, this.createEntity);

  Future<List<T>> query(QueryBuilder<T> builder) async {
    try {
      final db = await _dbHelper.database;
      final String query = builder.buildQuery();

      if (_dbHelper.config.logQueries) {
        _dbHelper.logger.logQuery(query, builder.parameters);
      }

      final List<Map<String, dynamic>> maps = await db.rawQuery(
        query,
        builder.parameters,
      );

      return maps.map((map) {
        final entity = createEntity();
        entity.fromMapWithMetadata(map);
        return entity;
      }).toList();
    } catch (e, stackTrace) {
      _dbHelper.logger.logError(
        'Failed to execute query: ${builder.buildQuery()}',
        e,
        stackTrace,
      );
      throw DbException(
        'Query execution failed',
        sql: builder.buildQuery(),
        originalError: e,
      );
    }
  }

  Future<T?> findById(int id) async {
    try {
      final results = await query(
          QueryBuilder<T>(tableName).where('id = ?', [id]).limit(1));
      return results.isEmpty ? null : results.first;
    } catch (e, stackTrace) {
      _dbHelper.logger
          .logError('Failed to find entity by ID: $id', e, stackTrace);
      rethrow;
    }
  }

  Future<int> insert(T entity) async {
    try {
      final db = await _dbHelper.database;
      entity.createdAt = DateTime.now();
      entity.updatedAt = entity.createdAt;

      final map = entity.toMapWithMetadata();
      if (_dbHelper.config.logQueries) {
        _dbHelper.logger.logQuery('INSERT INTO $tableName', [map]);
      }

      return await db.insert(tableName, map);
    } catch (e, stackTrace) {
      _dbHelper.logger.logError('Failed to insert entity', e, stackTrace);
      throw DbException('Insert operation failed', originalError: e);
    }
  }

  Future<int> update(T entity) async {
    try {
      final db = await _dbHelper.database;
      entity.updatedAt = DateTime.now();

      final map = entity.toMapWithMetadata();
      if (_dbHelper.config.logQueries) {
        _dbHelper.logger
            .logQuery('UPDATE $tableName WHERE id = ${entity.id}', [map]);
      }

      return await db.update(
        tableName,
        map,
        where: 'id = ?',
        whereArgs: [entity.id],
      );
    } catch (e, stackTrace) {
      _dbHelper.logger.logError('Failed to update entity', e, stackTrace);
      throw DbException('Update operation failed', originalError: e);
    }
  }

  Future<void> delete(int id) async {
    try {
      final db = await _dbHelper.database;
      if (_dbHelper.config.logQueries) {
        _dbHelper.logger.logQuery('DELETE FROM $tableName WHERE id = ?', [id]);
      }

      await db.delete(
        tableName,
        where: 'id = ?',
        whereArgs: [id],
      );
    } catch (e, stackTrace) {
      _dbHelper.logger.logError('Failed to delete entity', e, stackTrace);
      throw DbException('Delete operation failed', originalError: e);
    }
  }

  Future<void> transaction(Future<void> Function(Database) action) async {
    try {
      final db = await _dbHelper.database;
      await db.transaction((txn) async {
        await action(db);
      });
    } catch (e, stackTrace) {
      _dbHelper.logger.logError('Transaction failed', e, stackTrace);
      throw DbException('Transaction failed', originalError: e);
    }
  }
}
