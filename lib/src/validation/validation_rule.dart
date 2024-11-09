// validation_rule.dart
import 'package:object_tools/src/validation/models.dart';

abstract class ValidationRule<T> {
  String messageKey;
  String errorCode;
  ValidationSeverity severity;
  Set<ValidationGroup> groups;
  int priority;
  Map<String, dynamic> messageArgs;

  ValidationRule({
    required this.messageKey,
    required this.errorCode,
    this.severity = ValidationSeverity.error,
    Set<ValidationGroup>? groups,
    this.priority = 0,
    this.messageArgs = const {},
  }) : groups = groups ?? {const ValidationGroup('default')};

  bool validate(T value);

  ValidationRule<T> withMessage(String message) {
    messageKey = message;
    return this;
  }

  ValidationRule<T> withErrorCode(String code) {
    errorCode = code;
    return this;
  }

  ValidationRule<T> withSeverity(ValidationSeverity sev) {
    severity = sev;
    return this;
  }

  ValidationRule<T> withGroups(Set<ValidationGroup> validationGroups) {
    groups = validationGroups;
    return this;
  }

  ValidationRule<T> withPriority(int p) {
    priority = p;
    return this;
  }

  ValidationRule<T> withMessageArgs(Map<String, dynamic> args) {
    messageArgs = args;
    return this;
  }
}

abstract class AsyncValidationRule<T> extends ValidationRule<T> {
  AsyncValidationRule({required super.messageKey, required super.errorCode});

  Future<bool> validateAsync(T value);
}

class PropertyRule<T, P> extends ValidationRule<T> {
  final P Function(T) propertySelector;
  final List<ValidationRule<P>> rules;

  PropertyRule(
    this.propertySelector,
    this.rules, {
    required super.messageKey,
    required super.errorCode,
    super.severity,
    super.groups,
    super.priority,
    super.messageArgs,
  });

  @override
  bool validate(T value) {
    final propertyValue = propertySelector(value);
    return rules.every((rule) => rule.validate(propertyValue));
  }
}
