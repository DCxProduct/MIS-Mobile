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
    return LineMinistryIssuesScreenView(
      titleKey: titleKey,
      showTabs: false,
      cdcMatrix: AppSettings.of(context).moduleType == AppModuleType.cdcSection,
      staticPreview: AppSettings.of(context).auth.isStaticSession,
      issueDetailBuilder: (title, category, issue) =>
          AppSettings.of(context).moduleType == AppModuleType.cdcSection &&
              issue != null
          ? CdcIssueDetailLoader(issueId: issue.id)
          : CdcSectionIssueDetailScreen(
              title: title,
              category: category,
              issue: issue,
            ),
    );
  }
}
