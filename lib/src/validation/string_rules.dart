import 'package:object_tools/src/validation/validation_rule.dart';

class NotEmptyRule extends ValidationRule<String> {
  NotEmptyRule({
    super.messageKey = 'value.not_empty',
    super.errorCode = 'E_NOT_EMPTY',
    super.severity,
    super.groups,
    super.priority,
    super.messageArgs,
  });

  @override
  bool validate(String value) => value.isNotEmpty;
}

///```dart
/// final usernameMinLengthRule = MinLengthRule(
///    3,
///    messageKey: 'value.min_length',
///    errorCode: 'E002',
///    severity: ValidationSeverity.warning,
///    priority: 0,
///  );
///```
class MinLengthRule extends ValidationRule<String> {
  final int minLength;

  MinLengthRule(
    this.minLength, {
    super.messageKey = 'value.min_length',
    super.errorCode = 'E_MIN_LENGTH',
    super.severity,
    super.groups,
    super.priority,
    Map<String, dynamic> messageArgs = const {},
  }) : super(
          messageArgs: {...messageArgs, 'minLength': minLength},
        );

  @override
  bool validate(String value) => value.length >= minLength;
}

///```dart
///final emailRule = EmailRule(
///    messageKey: 'value.invalid_email',
///    errorCode: 'E003',
///    severity: ValidationSeverity.error,
///    priority: 1,
///  );
///```
class EmailRule extends ValidationRule<String> {
  EmailRule({
    super.messageKey = 'value.invalid_email',
    super.errorCode = 'E_INVALID_EMAIL',
    super.severity,
    super.groups,
    super.priority,
    super.messageArgs,
  });

  @override
  bool validate(String value) {
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    return emailRegex.hasMatch(value);
  }
}
