import 'package:flutter/material.dart';

import '../translations/app_language.dart';
import 'config/module_config.dart';

class AppSettingsController extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;
  AppLanguage _language = AppLanguage.english;
  AppModuleType _moduleType = AppModuleType.lineMinistry;
  String _userEmail = 'ministry@gmail.com';

  ThemeMode get themeMode => _themeMode;
  AppLanguage get language => _language;
  AppModuleType get moduleType => _moduleType;
  String get userEmail => _userEmail;

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

  void setModuleType(AppModuleType value) {
    if (_moduleType == value) return;
    _moduleType = value;
    notifyListeners();
  }

  void setUserEmail(String email) {
    final e = email.trim().toLowerCase();
    _userEmail = e;
    if (e == 'ministry@gmail.com' || e.contains('ministry')) {
      _moduleType = AppModuleType.lineMinistry;
    } else if (e == 'privatesector@gmail.com' || e.contains('private')) {
      _moduleType = AppModuleType.privateSector;
    } else if (e == 'cdc@gmail.com' || e.contains('section')) {
      _moduleType = AppModuleType.cdcSection;
    } else if (e == 'cdcgpsf@gmail.com' || e.contains('secretariat')) {
      _moduleType = AppModuleType.cdcSecretariat;
    } else if (e == 'cefp@gmail.com' || e.contains('cefp')) {
      _moduleType = AppModuleType.cefp;
    } else {
      _moduleType = AppModuleType.lineMinistry;
    }
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
