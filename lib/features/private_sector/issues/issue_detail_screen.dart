import 'package:flutter/material.dart';

import '../../../screens/issues/issue_detail_screen.dart' as shared;

class IssueDetailScreen extends StatelessWidget {
  const IssueDetailScreen({
    super.key,
    required this.title,
    required this.category,
  });

  final String title;
  final String category;

  @override
  Widget build(BuildContext context) {
    return shared.IssueDetailScreen(title: title, category: category);
  }
}
