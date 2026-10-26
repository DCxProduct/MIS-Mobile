import 'package:flutter/material.dart';
import '../core/formatters/number_formatter.dart' as numbers;
import '../core/formatters/date_formatter.dart' as dates;

import '../core/app_settings.dart';
import '../core/config/module_config.dart';
import 'app_language.dart';
import 'en.dart';
import 'km.dart';
import 'pswg_translation_keys.dart';
import 'ministry_translation_keys.dart';
import 'cdcgpsf_translation_keys.dart';
import 'cdc_translation_keys.dart';
import 'cefp_translation_keys.dart';
import 'account_translation_keys.dart';
import 'account_translation_scope.dart';

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
    this.module = AppModuleType.privateSector,
  });

  final AppLanguage language;
  String number(Object? value, {int? decimalPlaces}) => numbers.formatNumber(
    value,
    language: language,
    decimalPlaces: decimalPlaces,
  );
  String date(
    DateTime? value, {
    dates.AppDateStyle style = dates.AppDateStyle.medium,
  }) => dates.formatDate(value, language: language, style: style);
  String time(DateTime? value, {bool use24Hour = false}) =>
      dates.formatTime(value, language: language, use24Hour: use24Hour);
  String dateTime(DateTime? value, {bool use24Hour = false}) =>
      dates.formatDateTime(value, language: language, use24Hour: use24Hour);
  final Map<String, String> dictionary;
  final String? page;
  final AppModuleType module;
  bool get _isMinistry => module == AppModuleType.lineMinistry;
  bool get _isCdcGpsf => module == AppModuleType.cdcSecretariat;
  bool get _isCdc => module == AppModuleType.cdcSection;
  bool get _isCefp => module == AppModuleType.cefp;
  bool get _usesSharedWebKeys => _isMinistry || _isCdcGpsf;
  Map<String, Map<String, String>> get _pageKeys => _isCefp
      ? cefpPageKeys
      : _isCdc
      ? cdcPageKeys
      : _isCdcGpsf
      ? cdcGpsfPageKeys
      : _isMinistry
      ? ministryPageKeys
      : pswgPageKeys;
  Map<String, String> get _commonKeys => _isCefp
      ? cefpCommonKeys
      : _isCdc
      ? cdcCommonKeys
      : _isCdcGpsf
      ? cdcGpsfCommonKeys
      : _isMinistry
      ? ministryCommonKeys
      : pswgCommonKeys;
  Map<String, String> get _pageParents => _isCefp
      ? cefpPageParents
      : _isCdc
      ? cdcPageParents
      : _isCdcGpsf
      ? cdcGpsfPageParents
      : _isMinistry
      ? ministryPageParents
      : pswgPageParents;

  static AppLocalizations of(BuildContext context, {String? page}) {
    final settings = AppSettings.of(context);
    final account = AccountTranslationData.maybeOf(context);
    final accountPage =
        account != null && (page == null || page == 'account_setting');
    return AppLocalizations(
      settings.language,
      dictionary: accountPage ? account.dictionary : settings.translations,
      page: accountPage
          ? 'account_setting'
          : page ?? TranslationPageScope.maybeOf(context),
      module: settings.moduleType,
    );
  }

  String api(String key, {required String fallback}) {
    final value =
        dictionary[_isCefp
            ? cefpApiKey(key)
            : _isCdc
            ? cdcApiKey(key)
            : _usesSharedWebKeys
            ? ministryApiKey(key, page)
            : key];
    return value == null || value.trim().isEmpty ? fallback : value;
  }

  String filterLabel(String key) => api(
    (_isCefp
            ? cefpFilterKeys
            : _isCdc
            ? cdcFilterKeys
            : _isCdcGpsf
            ? cdcGpsfFilterKeys
            : _isMinistry
            ? ministryFilterKeys
            : pswgFilterKeys)[page]?[key] ??
        '',
    fallback: text(key),
  );

  String? _apiStatus(String code) {
    final normalized = code.toLowerCase();
    final token = normalized == 'drafted' ? 'draft' : normalized;
    if (_isCdc || _isCefp) {
      final prefix = switch (page) {
        'cdc_rgc' ||
        'cdc_rgc_detail' ||
        'cdc_rgc_report' => 'rgc_decision.status',
        'cdc_issue_matrix' || 'cdc_issue_detail' => 'cdc_issue_matrix.status',
        _ => null,
      };
      final key = '$prefix.$token';
      final value = dictionary[_isCefp ? cefpApiKey(key) : key];
      if (value != null && value.trim().isNotEmpty) return value;
    }
    if (_isCdcGpsf) {
      final statusKey = switch (page) {
        'cdc_rgc' || 'cdc_rgc_detail' || 'plenary_rgc_decisions' =>
          'issue_matrix_rgc_decision.rgc.status.$token',
        'cdc_progress_ministries' =>
          'progress_reports.values.${token.replaceAll('_', ' ')}',
        _ => null,
      };
      final value = dictionary[statusKey];
      if (value != null && value.trim().isNotEmpty) return value;
    }
    if (_usesSharedWebKeys) {
      final keys = switch (page) {
        'plenary_plenaries' ||
        'plenary_rgc_decisions' => ['$page.rgc.$token', '$page.core.$token'],
        'meeting_summary' => ['meeting_summary.status_labels.$token'],
        'meeting_calendar' => ['meeting_calendar.status_labels.$token'],
        'wg_issues' => ['issue_matrix.value_labels.$token'],
        _ => <String>[],
      };
      for (final key in keys) {
        final value = dictionary[key];
        if (value != null && value.trim().isNotEmpty) return value;
      }
    }
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
      'issue_matrix' ||
      'issue_matrix_detail' ||
      'issue_report' => ['issue_matrix.value_labels.$token'],
      'dashboard_plenary' || 'dashboard_working_group' => ['$page.$token'],
      _ => <String>[],
    };
    for (final key in candidates) {
      final value =
          dictionary[_usesSharedWebKeys ? ministryApiKey(key, page) : key];
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
      'DRAFTED' => 'drafted',
      'SAVED' => 'saved',
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
        'saved',
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
    if (page == 'account_setting') {
      final value = dictionary[accountTranslationKeys[key] ?? key];
      return value != null && value.trim().isNotEmpty ? value : null;
    }
    final pages = _pageKeys;
    final common = _commonKeys;
    final parent = _pageParents[page];
    final inheritedKey = pages[parent]?[key];
    final apiKey =
        pages[page]?[key] ??
        (_usesSharedWebKeys && inheritedKey != null
            ? ministryApiKey(inheritedKey, page)
            : inheritedKey) ??
        common[key];
    final remote = dictionary[apiKey ?? key];
    return remote != null && remote.trim().isNotEmpty ? remote : null;
  }

  String text(String key) {
    final remote = remoteText(key);
    if (remote != null) return remote;
    const statusCodes = {
      'draft': 'DRAFT',
      'drafted': 'DRAFTED',
      'saved': 'SAVED',
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
