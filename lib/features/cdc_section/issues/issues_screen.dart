import 'package:flutter/material.dart';

import '../../../core/app_settings.dart';
import '../../line_ministry/issues/issues_screen.dart';
import 'issue_detail_screen.dart';
import 'issue_detail_loader.dart';
import '../../../core/config/module_config.dart';

class CdcSectionIssuesScreenView extends StatelessWidget {
  const CdcSectionIssuesScreenView({super.key});

  @override
  Widget build(BuildContext context) {
    return LineMinistryIssuesScreenView(
      showTabs: false,
      staticPreview: AppSettings.of(context).auth.isStaticSession,
      previewStatus: 'Solved',
      issueDetailBuilder: (title, category, issue) =>
          issue != null &&
              AppSettings.of(context).moduleType == AppModuleType.cdcSection
          ? CdcIssueDetailLoader(
              issueId: issue.id,
              generalIssue: true,
              initialIssue: issue,
            )
          : CdcSectionIssueDetailScreen(
              title: title,
              category: category,
              issue: issue,
              generalIssue: true,
            ),
    );
  }
}
