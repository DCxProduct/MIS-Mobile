import 'package:flutter/material.dart';

import '../../../screens/issues/issue_detail_screen.dart';

class LineMinistryIssueDetailScreen extends StatelessWidget {
  const LineMinistryIssueDetailScreen({
    super.key,
    required this.title,
    required this.category,
  });

  final String title;
  final String category;

  @override
  Widget build(BuildContext context) {
    return IssueDetailScreen(title: title, category: category);
  }
}
