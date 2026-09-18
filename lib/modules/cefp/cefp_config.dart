import '../../core/config/module_config.dart';

class CefpConfig extends ModuleConfig {
  @override
  AppModuleType get type => AppModuleType.cefp;

  @override
  String get name => 'CEFP';

  @override
  String get title => 'CEFP Module';

  @override
  bool get canCreateMeetingRequest => true;

  @override
  bool get canCreateIssue => true;

  @override
  bool get canApproveReport => true;

  @override
  List<String> get availableTabs => [
        'Dashboard',
        'Meeting',
        'Issues',
        'Report',
        'Account',
      ];
}
