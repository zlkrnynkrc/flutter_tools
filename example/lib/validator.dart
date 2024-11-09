import 'package:object_tools/src/validation/validator.dart';

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
