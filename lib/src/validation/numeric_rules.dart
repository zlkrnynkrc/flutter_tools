import 'package:object_tools/src/validation/models.dart';
import 'package:object_tools/src/validation/validation_rule.dart';

///```dart
///  final ageRule = RangeRule(
///    18, 100,
///    messageKey: 'value.out_of_range',
///    errorCode: 'E004',
///    severity: ValidationSeverity.warning,
///    priority: 2,
///  );
///```
class RangeRule extends ValidationRule<num> {
  final num min;
  final num max;

  RangeRule(
    this.min,
    this.max, {
    super.messageKey = 'value.out_of_range',
    super.errorCode = 'E_OUT_OF_RANGE',
    super.severity = ValidationSeverity.warning,
    super.groups,
    super.priority,
    Map<String, dynamic> messageArgs = const {},
  }) : super(
          messageArgs: {...messageArgs, 'min': min, 'max': max},
        );

  @override
  bool validate(num value) => value >= min && value <= max;
}
