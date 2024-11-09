// validation_builder.dart
import 'package:object_tools/src/validation/models.dart';
import 'package:object_tools/src/validation/validation_rule.dart';

class ValidationBuilder<T> {
  final List<ValidationRule<T>> rules = [];

  ValidationBuilder<T> ruleFor(ValidationRule<T> rule) {
    rules.add(rule);
    return this;
  }

  ValidationBuilder<T> withMessage(String message) {
    rules.last.withMessage(message);
    return this;
  }

  ValidationBuilder<T> withErrorCode(String code) {
    rules.last.withErrorCode(code);
    return this;
  }

  ValidationBuilder<T> withSeverity(ValidationSeverity severity) {
    rules.last.withSeverity(severity);
    return this;
  }

  ValidationBuilder<T> withGroups(Set<ValidationGroup> groups) {
    rules.last.withGroups(groups);
    return this;
  }

  ValidationBuilder<T> withPriority(int priority) {
    rules.last.withPriority(priority);
    return this;
  }
}
