import 'package:flutter/material.dart';

import '../../features/private_sector/issues/issue_detail_screen.dart'
    as shared;
import '../../features/shared/issues/data/working_group_issue.dart';

/// Ministry issue details use the same API-backed report flow as private sector.
class IssueDetailScreen extends StatelessWidget {
  const IssueDetailScreen({
    super.key,
    required this.title,
    required this.category,
    this.issue,
  });

  final WorkingGroupIssue? issue;
  final String title;
  final String category;

  @override
  Widget build(BuildContext context) => shared.IssueDetailScreen(
    title: title,
    category: category,
    issue: issue,
    translationPage: 'issue_matrix_detail',
  );
}
