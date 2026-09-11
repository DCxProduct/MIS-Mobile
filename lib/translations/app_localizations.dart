import 'package:flutter/material.dart';

import '../core/app_settings.dart';
import 'app_language.dart';
import 'en.dart';
import 'km.dart';

class AppLocalizations {
  const AppLocalizations(this.language);

  final AppLanguage language;

  static AppLocalizations of(BuildContext context) {
    return AppLocalizations(AppSettings.of(context).language);
  }

  String text(String key) {
    return _translations[language]?[key] ??
        _translations[AppLanguage.english]?[key] ??
        key;
  }
}

const Map<AppLanguage, Map<String, String>> _translations = {
  AppLanguage.english: enTranslations,
  AppLanguage.khmer: kmTranslations,
};
