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

  /// Translate known status codes or English labels while preserving unknown values.
  String status(String value) {
    final normalized = value.trim().toUpperCase().replaceAll(
      RegExp(r'[\s-]+'),
      '_',
    );
    var key = switch (normalized) {
      'DRAFT' => 'draft',
      'DRAFTED' || 'SAVED' => 'drafted',
      'NEW_SUBMISSION' => 'newSubmission',
      'LIVE' => 'live',
      'REVIEWED' => 'reviewed',
      'PSWG_REVIEWED' => 'pswgReviewed',
      'SUBMITTED' => 'submitted',
      'COMPLETED' => 'completed',
      'COMPLETE' => 'complete',
      'UNDER_REVIEW' => 'underReview',
      'SCHEDULED' => 'scheduled',
      'SOLVED' => 'solved',
      'IN_PROGRESS' => 'inProgress',
      'NOT_ADDRESSED' => 'notAddressed',
      'SENT' => 'sent',
      'SHARED' => 'shared',
      'APPROVED' => 'approved',
      'REJECTED' => 'rejected',
      'PENDING' => 'pending',
      'REQUESTED' => 'requested',
      'PREPARING' => 'preparing',
      'CANCELLED' || 'CANCELED' => 'cancelled',
      'EARLY_PROGRESS' => 'earlyProgress',
      'MID_PROGRESS' => 'midProgress',
      _ => null,
    };
    // A sheet may have received an already translated status before a switch.
    if (key == null) {
      const statusKeys = [
        'newSubmission',
        'live',
        'reviewed',
        'pswgReviewed',
        'draft',
        'drafted',
        'submitted',
        'completed',
        'complete',
        'underReview',
        'scheduled',
        'solved',
        'inProgress',
        'notAddressed',
        'sent',
        'shared',
        'approved',
        'rejected',
        'pending',
        'requested',
        'preparing',
        'cancelled',
        'earlyProgress',
        'midProgress',
      ];
      for (final candidate in statusKeys) {
        if (_translations.values.any((map) => map[candidate] == value.trim())) {
          key = candidate;
          break;
        }
      }
    }
    return key == null ? (value.trim().isEmpty ? '—' : value) : text(key);
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
