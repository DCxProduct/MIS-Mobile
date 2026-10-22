import 'package:flutter/material.dart';

import '../core/app_settings.dart';
import 'app_language.dart';
import 'en.dart';
import 'km.dart';
import 'pswg_translation_keys.dart';

/// Carries the web page's translation namespace through shared widgets.
class TranslationPageScope extends InheritedWidget {
  const TranslationPageScope({
    super.key,
    required this.page,
    required super.child,
  });

  final String page;

  static String? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<TranslationPageScope>()?.page;

  @override
  bool updateShouldNotify(TranslationPageScope oldWidget) =>
      page != oldWidget.page;
}

class AppLocalizations {
  const AppLocalizations(
    this.language, {
    this.dictionary = const {},
    this.page,
  });

  final AppLanguage language;
  final Map<String, String> dictionary;
  final String? page;

  static AppLocalizations of(BuildContext context, {String? page}) {
    final settings = AppSettings.of(context);
    return AppLocalizations(
      settings.language,
      dictionary: settings.translations,
      page: page ?? TranslationPageScope.maybeOf(context),
    );
  }

  String api(String key, {required String fallback}) {
    final value = dictionary[key];
    return value == null || value.trim().isEmpty ? fallback : value;
  }

  String filterLabel(String key) =>
      api(pswgFilterKeys[page]?[key] ?? '', fallback: text(key));

  String? _apiStatus(String code) {
    final normalized = code.toLowerCase();
    final token = normalized == 'drafted' ? 'draft' : normalized;
    final candidates = switch (page) {
      'meeting_calendar' => ['meeting_requests.calendar_statuses.$token'],
      'meeting_requests' => [
        'meeting_requests.status.$normalized',
        'meeting_requests.status_labels.$token',
        'meeting_requests.calendar_statuses.$token',
      ],
      'meeting_summary' => ['meeting_summary.status.$token'],
      'meeting_summary_issue' => [
        'meeting_summary.issue_dialog.${token == 'new_submission' ? 'new_submitted' : token}',
      ],
      'progress_report' || 'progress_report_issue' => [
        'progress_report.values.${token == 're_reviewing' ? 're-reviewing' : token.replaceAll('_', ' ')}',
      ],
      'wg_issues' => ['wg_issues.status.$token'],
      'issue_matrix' || 'issue_report' => ['issue_matrix.value_labels.$token'],
      'dashboard_plenary' || 'dashboard_working_group' => ['$page.$token'],
      _ => <String>[],
    };
    for (final key in candidates) {
      final value = dictionary[key];
      if (value != null && value.trim().isNotEmpty) return value;
    }
    return null;
  }

  String? remoteStatus(String value) =>
      _apiStatus(value.trim().toUpperCase().replaceAll(RegExp(r'[\s-]+'), '_'));

  /// Translate known status codes or English labels while preserving unknown values.
  String status(String value) {
    final normalized = value.trim().toUpperCase().replaceAll(
      RegExp(r'[\s-]+'),
      '_',
    );
    final translated = _apiStatus(normalized);
    if (translated != null) return translated;
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

  String? remoteText(String key) {
    final apiKey =
        pswgPageKeys[page]?[key] ??
        pswgPageKeys[pswgPageParents[page]]?[key] ??
        pswgCommonKeys[key];
    final remote = dictionary[apiKey ?? key];
    return remote != null && remote.trim().isNotEmpty ? remote : null;
  }

  String text(String key) {
    final remote = remoteText(key);
    if (remote != null) return remote;
    const statusCodes = {
      'draft': 'DRAFT',
      'drafted': 'DRAFTED',
      'newSubmission': 'NEW_SUBMISSION',
      'submitted': 'SUBMITTED',
      'completed': 'COMPLETED',
      'complete': 'COMPLETED',
      'underReview': 'UNDER_REVIEW',
      'scheduled': 'SCHEDULED',
      'solved': 'SOLVED',
      'inProgress': 'IN_PROGRESS',
      'notAddressed': 'NOT_ADDRESSED',
      'sent': 'SENT',
      'shared': 'SHARED',
      'reviewed': 'REVIEWED',
      'pswgReviewed': 'PSWG_REVIEWED',
      'approved': 'APPROVED',
      'rejected': 'REJECTED',
      'requested': 'REQUESTED',
      'preparing': 'PREPARING',
    };
    final code = statusCodes[key];
    if (code != null) {
      final status = _apiStatus(code);
      if (status != null) return status;
    }
    return _translations[language]?[key] ??
        _translations[AppLanguage.english]?[key] ??
        key;
  }
}

const Map<AppLanguage, Map<String, String>> _translations = {
  AppLanguage.english: enTranslations,
  AppLanguage.khmer: kmTranslations,
};
