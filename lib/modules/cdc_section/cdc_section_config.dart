import '../../core/config/module_config.dart';

class CdcSectionConfig extends ModuleConfig {
  @override
  AppModuleType get type => AppModuleType.cdcSection;

  @override
  String get name => 'CDC Section';

  @override
  String get title => 'CDC Section Module';

  @override
  bool get canCreateMeetingRequest => false;

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
