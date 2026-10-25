import 'package:flutter/material.dart';

import '../../../screens/issues/issue_detail_screen.dart';
import '../../shared/issues/data/working_group_issue.dart';

class LineMinistryIssueDetailScreen extends StatelessWidget {
  const LineMinistryIssueDetailScreen({
    super.key,
    required this.title,
    required this.category,
    this.issue,
  });

  final String title;
  final String category;
  final WorkingGroupIssue? issue;

  @override
  Widget build(BuildContext context) {
    return IssueDetailScreen(title: title, category: category, issue: issue);
  }
}
