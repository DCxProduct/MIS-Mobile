import 'config/module_repositories.dart';
import 'package:flutter/material.dart';
import '../features/shared/meetings/data/meetings_repository.dart';

import '../translations/app_language.dart';
import 'config/module_config.dart';
import 'network/api_client.dart';
import 'network/filter_catalog_repository.dart';
import 'config/role_modules.dart';
import '../features/auth/data/auth_repository.dart';
import '../features/auth/data/auth_user.dart';
import '../features/shared/dashboard/data/dashboard_repository.dart';
import '../features/shared/issues/data/issues_repository.dart';
import '../features/shared/issues/data/cdc_issue_matrix_repository.dart';
import '../features/shared/meetings/data/meeting_requests_repository.dart';
import '../features/shared/meetings/data/meeting_summaries_repository.dart';
import '../features/shared/meetings/data/progress_reports_repository.dart';
import '../features/shared/meetings/data/plenaries_repository.dart';
import '../features/shared/meetings/data/rgc_decisions_repository.dart';

class AppSettingsController extends ChangeNotifier {
  AppSettingsController({
    AuthRepository? authRepository,
    Map<AppModuleType, ModuleRepositories> moduleRepositories = const {},
  }) : auth = authRepository ?? AuthRepository(ApiClient()),
       _moduleRepositories = Map.unmodifiable(moduleRepositories);

  final AuthRepository auth;
  final Map<AppModuleType, ModuleRepositories> _moduleRepositories;
  late final ModuleRepositories _defaultRepositories = ModuleRepositories(
    apiClient: auth.apiClient,
  );
  ModuleRepositories get _repositories =>
      _moduleRepositories[moduleType] ?? _defaultRepositories;

  DashboardRepository get dashboard => _repositories.dashboard;
  FilterCatalogRepository get filters => _repositories.filters;
  IssuesRepository get issues => _repositories.issues;
  CdcIssueMatrixRepository get cdcIssueMatrix => _repositories.cdcIssueMatrix;
  MeetingRequestsRepository get meetingRequests =>
      _repositories.meetingRequests;
  MeetingsRepository get meetings => _repositories.meetings;
  MeetingSummariesRepository get meetingSummaries =>
      _repositories.meetingSummaries;
  ProgressReportsRepository get progressReports =>
      _repositories.progressReports;
  PlenariesRepository get plenaries => _repositories.plenaries;
  RgcDecisionsRepository get rgcDecisions => _repositories.rgcDecisions;
  AuthUser? currentUser;

  void setCurrentUser(AuthUser user) {
    final module = moduleForRoles(user.roles);
    if (module == null) throw const UnsupportedRoleException();
    currentUser = user;
    _userEmail = user.email;
    _moduleType = module;
    notifyListeners();
  }

  void clearSession() {
    auth.clearSession();
    currentUser = null;
    _userEmail = '';
    _moduleType = AppModuleType.lineMinistry;
    notifyListeners();
  }

  @override
  void dispose() {
    auth.dispose();
    super.dispose();
  }

  ThemeMode _themeMode = ThemeMode.light;
  AppLanguage _language = AppLanguage.khmer;
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
