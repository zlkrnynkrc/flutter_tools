import 'package:object_tools/src/validation/localization.dart';
import 'package:object_tools/src/validation/models.dart';
import 'package:object_tools/src/validation/validation_rule.dart';

///```dart
///final validator = AdvancedValidator<User>(i18n);
///
///  validator
///    ..addRule(PropertyRule((user) => user.username, [usernameRule, usernameMinLengthRule]))
///    ..addRule(PropertyRule((user) => user.email, [emailRule]))
///    ..addRule(PropertyRule((user) => user.age, [ageRule]));
///
///  // Validation yapma
///  final validationResult = validator.validate(user);
///
///  // Sonuçları yazdırma
///  printValidationResult(validationResult);
///}
///```
class AdvancedValidator<T> {
  final List<ValidationRule<T>> _rules = [];
  final I18n _i18n;

  AdvancedValidator(this._i18n);
  void addRule(ValidationRule<T> rule) {
    _rules.add(rule);
  }

  ValidationResult validate(
    T value, {
    Set<ValidationGroup>? groups,
    ValidationSeverity? minimumSeverity,
  }) {
    final errors = <ValidationError>[];
    final activeGroups =
        _expandGroups(groups ?? {const ValidationGroup('default')});

    // Sort rules by priority
    final activeRules = _rules
        .where((rule) => rule.groups.any((g) => activeGroups.contains(g)))
        .where((rule) =>
            minimumSeverity == null ||
            rule.severity.level >= minimumSeverity.level)
        .toList()
      ..sort((a, b) => b.priority.compareTo(a.priority));

    for (var rule in activeRules) {
      if (!rule.validate(value)) {
        errors.add(ValidationError(
          propertyName: T.toString(),
          message: _i18n.translate(rule.messageKey, rule.messageArgs),
          errorCode: rule.errorCode,
          severity: rule.severity,
          args: rule.messageArgs,
        ));
      }
    }

    return ValidationResult(
      isValid: errors.isEmpty,
      errors: errors,
    );
  }

  Set<ValidationGroup> _expandGroups(Set<ValidationGroup> groups) {
    final expandedGroups = <ValidationGroup>{};

    void expandGroup(ValidationGroup group) {
      if (expandedGroups.add(group)) {
        for (final includedGroup in group.includedGroups) {
          expandGroup(ValidationGroup(includedGroup));
        }
      }
    }

    for (final group in groups) {
      expandGroup(group);
    }

    return expandedGroups;
  }
}
