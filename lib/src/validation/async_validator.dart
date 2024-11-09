// async_validator.dart
import 'package:object_tools/src/validation/localization.dart';
import 'package:object_tools/src/validation/models.dart';
import 'package:object_tools/src/validation/validation_rule.dart';

class AsyncValidator<T> {
  final List<AsyncValidationRule<T>> _rules = [];
  final I18n _i18n;

  AsyncValidator(this._i18n);

  Future<ValidationResult> validateAsync(
    T value, {
    Set<ValidationGroup>? groups,
    ValidationSeverity? minimumSeverity,
  }) async {
    final errors = <ValidationError>[];
    final activeGroups =
        _expandGroups(groups ?? {const ValidationGroup('default')});

    for (var rule in _rules) {
      if (rule.groups.any((g) => activeGroups.contains(g)) &&
          (minimumSeverity == null ||
              rule.severity.level >= minimumSeverity.level)) {
        if (!await rule.validateAsync(value)) {
          errors.add(ValidationError(
            propertyName: T.toString(),
            message: _i18n.translate(rule.messageKey, rule.messageArgs),
            errorCode: rule.errorCode,
            severity: rule.severity,
            args: rule.messageArgs,
          ));
        }
      }
    }

    return ValidationResult(isValid: errors.isEmpty, errors: errors);
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
