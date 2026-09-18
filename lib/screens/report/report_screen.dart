import 'package:flutter/material.dart';

import '../../core/app_settings.dart';
import '../../core/config/module_config.dart';
import '../../features/cdc_secretariat/reports/reports_screen.dart';
import '../../features/cdc_section/reports/reports_screen.dart';
import '../../features/cefp/reports/reports_screen.dart';
import '../../features/line_ministry/reports/reports_screen.dart';
import '../../features/private_sector/reports/reports_screen.dart' as ps;

class ReportScreen extends StatelessWidget {
  const ReportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final moduleType = AppSettings.of(context).moduleType;
    return switch (moduleType) {
      AppModuleType.lineMinistry => const LineMinistryReportsScreenView(),
      AppModuleType.cdcSection => const CdcSectionReportsScreenView(),
      AppModuleType.cefp => const CefpReportsScreenView(),
      AppModuleType.cdcSecretariat => const CdcSecretariatReportsScreenView(),
      AppModuleType.privateSector => const ps.ReportScreen(),
    };
  }
}
