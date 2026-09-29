import 'package:flutter/material.dart';
import '../../../../core/app_settings.dart';
import '../../../../translations/app_localizations.dart';
import '../data/working_group_issue.dart';

class WgIssuesList extends StatefulWidget {
  const WgIssuesList({
    super.key,
    required this.itemBuilder,
    this.query = '',
    this.matrix = false,
    this.filter,
  });
  final Widget Function(WorkingGroupIssue) itemBuilder;
  final String query;
  final bool matrix;
  final bool Function(WorkingGroupIssue issue)? filter;
  @override
  State<WgIssuesList> createState() => _WgIssuesListState();
}

class _WgIssuesListState extends State<WgIssuesList> {
  Future<List<WorkingGroupIssue>>? _request;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _request ??= widget.matrix
        ? AppSettings.of(context).issues.getIssueMatrix()
        : AppSettings.of(context).issues.getMyWorkingGroupIssues();
  }

  @override
  void didUpdateWidget(covariant WgIssuesList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.matrix != widget.matrix) {
      _request = widget.matrix
          ? AppSettings.of(context).issues.getIssueMatrix()
          : AppSettings.of(context).issues.getMyWorkingGroupIssues();
    }
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<List<WorkingGroupIssue>>(
    future: _request,
    builder: (context, snapshot) {
      final l10n = AppLocalizations.of(context);
      if (snapshot.connectionState != ConnectionState.done) {
        return const Padding(
          padding: EdgeInsets.all(24),
          child: Center(child: CircularProgressIndicator()),
        );
      }
      if (snapshot.hasError) {
        return Column(
          children: [
            Text(l10n.text('issuesListLoadError')),
            TextButton(
              onPressed: () => setState(() {
                _request = widget.matrix
                    ? AppSettings.of(context).issues.getIssueMatrix()
                    : AppSettings.of(context).issues.getMyWorkingGroupIssues();
              }),
              child: Text(l10n.text('retry')),
            ),
          ],
        );
      }
      final query = widget.query.trim().toLowerCase();
      final items = snapshot.data!
          .where(
            (issue) =>
                (widget.filter?.call(issue) ?? true) &&
                (query.isEmpty ||
                    '${issue.title} ${issue.category} ${issue.description}'
                        .toLowerCase()
                        .contains(query)),
          )
          .toList();
      if (items.isEmpty) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Text(l10n.text('noIssuesFound')),
        );
      }
      return Column(
        children: [
          for (final issue in items)
            KeyedSubtree(
              key: ValueKey('wg-issue-${issue.id}'),
              child: widget.itemBuilder(issue),
            ),
        ],
      );
    },
  );
}
