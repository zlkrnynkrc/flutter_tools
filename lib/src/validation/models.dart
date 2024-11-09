// validation_severity.dart
enum ValidationSeverity {
  info(0),
  warning(1),
  error(2);

  final int level;
  const ValidationSeverity(this.level);
}

class ValidationResult {
  final bool isValid;
  final List<ValidationError> errors;

  ValidationResult({
    required this.isValid,
    required this.errors,
  });
}

// validation_error.dart
class ValidationError {
  final String propertyName;
  final String message;
  final String errorCode;
  final ValidationSeverity severity;
  final Map<String, dynamic> args;

  ValidationError({
    required this.propertyName,
    required this.message,
    required this.errorCode,
    this.severity = ValidationSeverity.error,
    this.args = const {},
  });
}

// validation_group.dart
class ValidationGroup {
  final String name;
  final List<String> includedGroups;

  const ValidationGroup(this.name, {this.includedGroups = const []});
}
