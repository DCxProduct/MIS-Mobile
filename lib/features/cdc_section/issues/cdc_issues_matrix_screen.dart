import 'package:flutter/material.dart';

import '../../../core/app_settings.dart';
import '../../line_ministry/issues/issues_screen.dart';
import 'issue_detail_screen.dart';

class CdcSectionIssuesMatrixScreen extends StatelessWidget {
  const CdcSectionIssuesMatrixScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return LineMinistryIssuesScreenView(
      titleKey: 'cdcIssuesMatrix',
      showTabs: false,
      staticPreview: AppSettings.of(context).auth.isStaticSession,
      issueDetailBuilder: (title, category, issue) =>
          CdcSectionIssueDetailScreen(
            title: title,
            category: category,
            issue: issue,
          ),
    );
  }
}
