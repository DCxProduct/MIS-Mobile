import 'package:flutter/material.dart';

import '../../core/app_settings.dart';
import '../../core/config/module_config.dart';
import '../../features/cdc_secretariat/issues/issues_screen.dart';
import '../../features/cdc_section/issues/issues_screen.dart';
import '../../features/cefp/issues/issues_screen.dart';
import '../../features/line_ministry/issues/issues_screen.dart';
import '../../features/private_sector/issues/issues_screen.dart' as ps;

class IssuesScreen extends StatelessWidget {
  const IssuesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final moduleType = AppSettings.of(context).moduleType;
    return switch (moduleType) {
      AppModuleType.lineMinistry => const LineMinistryIssuesScreenView(),
      AppModuleType.cdcSection => const CdcSectionIssuesScreenView(),
      AppModuleType.cefp => const CefpIssuesScreenView(),
      AppModuleType.cdcSecretariat => const CdcSecretariatIssuesScreenView(),
      AppModuleType.privateSector => const ps.IssuesScreen(),
    };
  }
}
