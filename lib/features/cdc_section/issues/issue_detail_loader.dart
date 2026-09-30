import 'package:flutter/material.dart';

import '../../../core/app_settings.dart';
import '../../../translations/app_localizations.dart';
import '../../shared/issues/data/working_group_issue.dart';
import 'issue_detail_screen.dart';

/// List responses may omit relations and files; fetch the selected issue detail.
class CdcIssueDetailLoader extends StatefulWidget {
  const CdcIssueDetailLoader({
    super.key,
    required this.issueId,
    this.generalIssue = false,
    this.initialIssue,
  });
  final int issueId;
  final bool generalIssue;
  final WorkingGroupIssue? initialIssue;

  @override
  State<CdcIssueDetailLoader> createState() => _CdcIssueDetailLoaderState();
}

class _CdcIssueDetailLoaderState extends State<CdcIssueDetailLoader> {
  Future<WorkingGroupIssue>? _request;
  Future<WorkingGroupIssue> _load() {
    final settings = AppSettings.of(context);
    return widget.generalIssue
        ? settings.issues.getIssue(widget.issueId)
        : settings.cdcIssueMatrix.getDisplayIssue(widget.issueId);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _request ??= _load();
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<WorkingGroupIssue>(
    future: _request,
    builder: (context, snapshot) {
      if (snapshot.hasData) {
        final issue = snapshot.data!;
        return CdcSectionIssueDetailScreen(
          title: issue.title,
          category: issue.category,
          issue: issue,
          generalIssue: widget.generalIssue,
          progressReportsFallback: widget.initialIssue?.progressReports,
        );
      }
      final l10n = AppLocalizations.of(context);
      return Scaffold(
        appBar: AppBar(title: Text(l10n.text('issueDetails'))),
        body: Center(
          child: snapshot.hasError
              ? Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(l10n.text('issuesListLoadError')),
                    TextButton(
                      onPressed: () => setState(() {
                        _request = _load();
                      }),
                      child: Text(l10n.text('retry')),
                    ),
                  ],
                )
              : const CircularProgressIndicator(),
        ),
      );
    },
  );
}
