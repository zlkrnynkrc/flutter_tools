// Enhanced query builder
import 'package:object_tools/src/sqflite_helper/base_entity.dart';

class QueryBuilder<T extends BaseEntity> {
  final String _tableName;
  final List<String> _conditions = [];
  final List<dynamic> _parameters = [];
  final List<String> _joins = [];
  String _orderBy = '';
  String _groupBy = '';
  String _having = '';
  int? _limit;
  int? _offset;
  final List<String> _selectedFields;

  /// Complex query example
  ///```dart
  ///final queryBuilder = QueryBuilder<User>('users')
  ///    .select(['id', 'name', 'age'])
  ///    .where('age > ?', [16])
  ///    .where('name LIKE ?', ['%ali%'])
  ///    .orderBy('age', desc: true)
  ///    .limit(10);
  ///final users = await userRepo.query(queryBuilder);
  ///```
  QueryBuilder(this._tableName, [this._selectedFields = const ['*']]);

  QueryBuilder<T> select(List<String> fields) {
    _selectedFields.clear();
    _selectedFields.addAll(fields);
    return this;
  }

  QueryBuilder<T> where(String condition, [List<dynamic>? params]) {
    _conditions.add('($condition)');
    if (params != null) {
      _parameters.addAll(params);
    }
    return this;
  }

  QueryBuilder<T> join(String table, String condition) {
    _joins.add('JOIN $table ON $condition');
    return this;
  }

  QueryBuilder<T> leftJoin(String table, String condition) {
    _joins.add('LEFT JOIN $table ON $condition');
    return this;
  }

  QueryBuilder<T> groupBy(String field) {
    _groupBy = 'GROUP BY $field';
    return this;
  }

  QueryBuilder<T> having(String condition) {
    _having = 'HAVING $condition';
    return this;
  }

  QueryBuilder<T> orderBy(String field, {bool desc = false}) {
    _orderBy = 'ORDER BY $field ${desc ? 'DESC' : 'ASC'}';
    return this;
  }

  QueryBuilder<T> limit(int limit, {int? offset}) {
    _limit = limit;
    _offset = offset;
    return this;
  }

  String buildQuery() {
    final fields = _selectedFields.join(', ');
    var query = 'SELECT $fields FROM $_tableName';

    if (_joins.isNotEmpty) {
      query += ' ${_joins.join(' ')}';
    }

    if (_conditions.isNotEmpty) {
      query += ' WHERE ${_conditions.join(' AND ')}';
    }

    if (_groupBy.isNotEmpty) {
      query += ' $_groupBy';
    }

    if (_having.isNotEmpty) {
      query += ' $_having';
    }

    if (_orderBy.isNotEmpty) {
      query += ' $_orderBy';
    }

    if (_limit != null) {
      query += ' LIMIT $_limit';
      if (_offset != null) {
        query += ' OFFSET $_offset';
      }
    }

    return query;
  }

  List<dynamic> get parameters => _parameters;
}
