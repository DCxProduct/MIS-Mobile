import 'package:flutter/material.dart';

import '../../../core/app_settings.dart';
import '../../../core/config/module_config.dart';
import '../../line_ministry/issues/issues_screen.dart';
import 'issue_detail_screen.dart';
import 'issue_detail_loader.dart';

class CdcSectionIssuesMatrixScreen extends StatelessWidget {
  const CdcSectionIssuesMatrixScreen({
    super.key,
    this.titleKey = 'cdcIssuesMatrix',
  });

  final String titleKey;

  @override
  Widget build(BuildContext context) {
    final settings = AppSettings.of(context);
    // CDC and CEFP share /issues; the authenticated role selects the matrix.
    final issueMatrix =
        settings.moduleType == AppModuleType.cdcSection ||
        settings.moduleType == AppModuleType.cefp;
    return LineMinistryIssuesScreenView(
      titleKey: titleKey,
      showTabs: false,
      cdcMatrix: issueMatrix,
      staticPreview: settings.auth.isStaticSession,
      issueDetailBuilder: (title, category, issue) =>
          issueMatrix && issue != null
          ? CdcIssueDetailLoader(issueId: issue.id)
          : CdcSectionIssueDetailScreen(
              title: title,
              category: category,
              issue: issue,
            ),
    );
  }
}
