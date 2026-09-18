enum AppModuleType {
  privateSector,
  lineMinistry,
  cdcSection,
  cefp,
  cdcSecretariat,
}

abstract class ModuleConfig {
  AppModuleType get type;
  String get name;
  String get title;
  bool get canCreateMeetingRequest;
  bool get canCreateIssue;
  bool get canApproveReport;
  List<String> get availableTabs;
}
