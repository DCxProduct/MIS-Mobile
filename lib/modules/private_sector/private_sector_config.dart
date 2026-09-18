import '../../core/config/module_config.dart';

class PrivateSectorConfig extends ModuleConfig {
  @override
  AppModuleType get type => AppModuleType.privateSector;

  @override
  String get name => 'Private Sector';

  @override
  String get title => 'Private Sector Module';

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
