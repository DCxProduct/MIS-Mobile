import 'package:flutter/material.dart';

import '../../core/app_settings.dart';
import '../../core/config/module_config.dart';
import '../../features/cdc_secretariat/meeting/meeting_screen.dart';
import '../../features/cdc_section/meeting/meeting_screen.dart';
import '../../features/cefp/meeting/meeting_screen.dart';
import '../../features/line_ministry/meeting/meeting_screen.dart';
import '../../features/private_sector/meeting/meeting_screen.dart' as ps;

class MeetingScreen extends StatelessWidget {
  const MeetingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final moduleType = AppSettings.of(context).moduleType;
    return switch (moduleType) {
      AppModuleType.lineMinistry => const LineMinistryMeetingScreenView(),
      AppModuleType.cdcSection => const CdcSectionMeetingScreenView(),
      AppModuleType.cefp => const CefpMeetingScreenView(),
      AppModuleType.cdcSecretariat => const CdcSecretariatMeetingScreenView(),
      AppModuleType.privateSector => const ps.MeetingScreen(),
    };
  }
}
