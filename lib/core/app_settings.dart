import 'package:flutter/material.dart';
import '../features/shared/meetings/data/meetings_repository.dart';

import '../translations/app_language.dart';
import 'config/module_config.dart';
import 'network/api_client.dart';
import 'config/role_modules.dart';
import '../features/auth/data/auth_repository.dart';
import '../features/auth/data/auth_user.dart';
import '../features/shared/dashboard/data/dashboard_repository.dart';
import '../features/shared/issues/data/issues_repository.dart';
import '../features/shared/meetings/data/meeting_requests_repository.dart';
import '../features/shared/meetings/data/meeting_summaries_repository.dart';
import '../features/shared/meetings/data/progress_reports_repository.dart';
import '../features/shared/meetings/data/plenaries_repository.dart';
import '../features/shared/meetings/data/rgc_decisions_repository.dart';

class AppSettingsController extends ChangeNotifier {
  AppSettingsController({AuthRepository? authRepository})
    : auth = authRepository ?? AuthRepository(ApiClient());

  final AuthRepository auth;
  late final DashboardRepository dashboard = DashboardRepository(
    auth.apiClient,
  );
  late final IssuesRepository issues = IssuesRepository(auth.apiClient);
  late final MeetingRequestsRepository meetingRequests =
      MeetingRequestsRepository(auth.apiClient);
  late final MeetingsRepository meetings = MeetingsRepository(auth.apiClient);
  late final MeetingSummariesRepository meetingSummaries =
      MeetingSummariesRepository(auth.apiClient);
  late final ProgressReportsRepository progressReports =
      ProgressReportsRepository(auth.apiClient);
  late final PlenariesRepository plenaries = PlenariesRepository(
    auth.apiClient,
  );
  late final RgcDecisionsRepository rgcDecisions = RgcDecisionsRepository(
    auth.apiClient,
  );
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
