import 'package:flutter/material.dart';

import '../translations/app_language.dart';

class AppSettingsController extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;
  AppLanguage _language = AppLanguage.english;

  ThemeMode get themeMode => _themeMode;
  AppLanguage get language => _language;

  Locale get locale {
    return Locale(_language == AppLanguage.khmer ? 'km' : 'en');
  }

  void setThemeMode(ThemeMode value) {
    if (_themeMode == value) return;
    _themeMode = value;
    notifyListeners();
  }

  void setLanguage(AppLanguage value) {
    if (_language == value) return;
    _language = value;
    notifyListeners();
  }
}

class AppSettings extends InheritedNotifier<AppSettingsController> {
  const AppSettings({
    super.key,
    required AppSettingsController controller,
    required super.child,
  }) : super(notifier: controller);

  static AppSettingsController of(BuildContext context) {
    final settings = context.dependOnInheritedWidgetOfExactType<AppSettings>();
    assert(settings != null, 'AppSettings was not found in the widget tree.');
    return settings!.notifier!;
  }
}
