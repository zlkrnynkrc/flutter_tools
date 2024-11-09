///```dart
///final translations = {
///  'en': {
///    'value.not_empty': 'Value cannot be empty',
///    'value.min_length': 'Minimum length should be {minLength}',
///    'value.invalid_email': 'Invalid email format',
///    'value.out_of_range': 'Value must be between {min} and {max}',
///  },
///  'tr': {
///    'value.not_empty': 'Değer boş olamaz',
///    'value.min_length': 'Minimum uzunluk {minLength} olmalıdır',
///    'value.invalid_email': 'Geçersiz e-posta formatı',
///    'value.out_of_range': 'Değer {min} ile {max} arasında olmalıdır',
///  },
///};
///
///final i18n = DefaultI18n(
///  translations: translations,
///  defaultLocale: 'en',
///);
///```
abstract class I18n {
  String translate(String key, Map<String, dynamic> args);
}

class DefaultI18n implements I18n {
  final Map<String, Map<String, String>> _translations;
  final String _defaultLocale;
  String _currentLocale;

  DefaultI18n({
    required Map<String, Map<String, String>> translations,
    required String defaultLocale,
  })  : _translations = translations,
        _defaultLocale = defaultLocale,
        _currentLocale = defaultLocale;

  void setLocale(String locale) {
    if (_translations.containsKey(locale)) {
      _currentLocale = locale;
    }
  }

  @override
  String translate(String key, Map<String, dynamic> args) {
    final translations =
        _translations[_currentLocale] ?? _translations[_defaultLocale];
    var message = translations?[key] ?? key;

    args.forEach((key, value) {
      message = message.replaceAll('{$key}', value.toString());
    });

    return message;
  }
}
