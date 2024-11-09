# object_tools flutter tools
Feel free to any use, change etc.
** Not tested yet

validator example
```dart
void main() {
  // Translations setup
  final translations = {
    'en': {
      'email.required': 'Email is required',
      'email.invalid': 'Invalid email format: {email}',
      'age.range': 'Age must be between {min} and {max}',
    },
    'tr': {
      'email.required': 'E-posta gereklidir',
      'email.invalid': 'Geçersiz e-posta formatı: {email}',
      'age.range': 'Yaş {min} ile {max} arasında olmalıdır',
    },
  };

  final i18n = DefaultI18n(
    translations: translations,
    defaultLocale: 'en',
  );

  // Validation groups
  const basicGroup = ValidationGroup('basic');
  const premiumGroup = ValidationGroup('premium', includedGroups: ['basic']);

  // Validator setup
  final validator = AdvancedValidator<User>(i18n);

  // Email validation rules
  final emailRule = NotEmptyRule(
    messageKey: 'email.required',
    errorCode: 'E001',
    priority: 1,
  ).withGroups({basicGroup});

  final emailFormatRule = EmailRule(
    messageKey: 'email.invalid',
    errorCode: 'E002',
    priority: 0,
  ).withMessageArgs({'email': 'test@example.com'}).withGroups({basicGroup});

  // Age validation rule
  final ageRule = RangeRule(
    18,
    100,
    messageKey: 'age.range',
    errorCode: 'A001',
    severity: ValidationSeverity.warning,
  ).withMessageArgs({'min': 18, 'max': 100}).withGroups({premiumGroup});

  validator
    ..addRule(PropertyRule((user) => user.email, [emailRule, emailFormatRule],
        messageKey: 'email.invalid', errorCode: 'E002'))
    ..addRule(PropertyRule((user) => user.age, [ageRule],
        messageKey: 'age.range', errorCode: 'A001'));

  // Test validation with different configurations
  final user = User(email: '', age: 16);

  // Validate with specific group
  final basicResult = validator.validate(
    user,
    groups: {basicGroup},
  );

  // Validate with minimum severity
  final severeResult = validator.validate(
    user,
    minimumSeverity: ValidationSeverity.error,
  );

  // Change language and validate
  i18n.setLocale('tr');
  final localizedResult = validator.validate(user);

  // Print results
  void printValidationResult(String title, ValidationResult result) {
    print('\n$title:');
    if (!result.isValid) {
      for (var error in result.errors) {
        print('''
          Property: ${error.propertyName}
          Message: ${error.message}
          Code: ${error.errorCode}
          Severity: ${error.severity}
        ''');
      }
    }
  }

  printValidationResult('Basic Validation', basicResult);
  printValidationResult('Severe Validation', severeResult);
  printValidationResult('Localized Validation', localizedResult);
}

// User model for example
class User {
  final String email;
  final int age;

  User({
    required this.email,
    required this.age,
  });
}
```
 Example usage of sqlite helper
```dart
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
```
 Retry Kullanım örneği:
```dart 

void example() async {
  final policy = RetryPolicy(
    RetryOptions(
      maxAttempts: 3,
      initialDelay: const Duration(milliseconds: 200),
      backoffStrategy: const ExponentialBackoff(
        multiplier: 2.0,
        maxDelay: Duration(seconds: 10),
      ),
      timeoutStrategy: ProgressiveTimeout(
        initialTimeout: const Duration(seconds: 1),
        multiplier: 1.5,
        maxTimeout: const Duration(seconds: 5),
      ),
      rateLimiter: RateLimiter(
        maxRequests: 100,
        window: const Duration(minutes: 1),
      ),
      useCache: true,
      cacheTtl: const Duration(minutes: 5),
      validateResponse: true,
      responseValidator: (response) {
        // Örnek response validasyonu
        if (response is Map) {
          return response.containsKey('status') &&
              response['status'] == 'success';
        }
        return true;
      },
      logger: (message, level) => print('[$level] $message'),
    ),
  );

  try {
    final result = await policy.execute(
      'api-call',
      () => someApiCall(),
      useCircuitBreaker: true,
      useBulkhead: true,
      maxConcurrent: 5,
      responseValidator: (response) {
        // Özel response validasyonu
        return response.isEmpty;
      },
    );

    print('Operation succeeded: $result');

    // Metrikleri kontrol et
    print('Metrics: ${policy.getMetrics()}');
  } on RetryException catch (e) {
    print('Retry failed: $e');
  } on CircuitBreakerException catch (e) {
    print('Circuit breaker open: $e');
  } on RateLimitException catch (e) {
    print('Rate limit exceeded: $e');
  }
}

```
Logger kullanım örneği
```dart
void main() async {
  // Basit kullanım
  final logger = Logger.create(
    appName: 'MyApp',
    useConsole: true,
    useFile: true,
  );

  // Temel logging
  logger.information('Uygulama başlatıldı');

  // Properties ile logging
  logger.information(
    'Kullanıcı girişi yapıldı',
    properties: {
      'userId': 123,
      'userName': 'John',
    },
  );

  // Exception logging
  try {
    throw Exception('Bir hata oluştu');
  } catch (e, stackTrace) {
    logger.error(
      'İşlem başarısız',
      exception: e,
      properties: {'operation': 'userLogin'},
    );
  }

  // Uygulamayı kapatırken
  await logger.dispose();
}
```
Schedular SimpLeJob için örnek sınıfı inceleyin büyük ihtimaller çalışmayacak çalışırsa bana da söyleyin.
```dart
## Getting Started

This project is a starting point for a Flutter
[plug-in package](https://flutter.dev/to/develop-plugins),
a specialized package that includes platform-specific implementation code for
Android and/or iOS.

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
