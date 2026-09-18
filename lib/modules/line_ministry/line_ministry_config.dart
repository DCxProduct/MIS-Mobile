import '../../core/config/module_config.dart';

class LineMinistryConfig extends ModuleConfig {
  @override
  AppModuleType get type => AppModuleType.lineMinistry;

  @override
  String get name => 'Line Ministry';

  @override
  String get title => 'Line Ministry Module';

  @override
  bool get canCreateMeetingRequest => true;

  @override
  bool get canCreateIssue => true;

  @override
  bool get canApproveReport => false;

  @override
  List<String> get availableTabs => [
        'Dashboard',
        'Meeting',
        'Issues',
        'Report',
        'Account',
      ];
}
