import 'package:flutter/material.dart';
import '../../../../core/app_settings.dart';
import '../../../../translations/app_localizations.dart';
import '../data/wg_issue_summary.dart';

/// Supplies data to existing metric cards without changing their layout.
class WgIssueSummaryLoader extends StatefulWidget {
  const WgIssueSummaryLoader({
    super.key,
    required this.builder,
    this.matrix = false,
  });

  final Widget Function(WgIssueSummary) builder;
  final bool matrix;

  @override
  State<WgIssueSummaryLoader> createState() => _WgIssueSummaryLoaderState();
}

class _WgIssueSummaryLoaderState extends State<WgIssueSummaryLoader> {
  Future<WgIssueSummary>? _request;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _request ??= widget.matrix
        ? AppSettings.of(context).issues.getIssueMatrixSummary()
        : AppSettings.of(context).issues.getMyWorkingGroupSummary();
  }

  @override
  void didUpdateWidget(covariant WgIssueSummaryLoader oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.matrix != widget.matrix) {
      _request = widget.matrix
          ? AppSettings.of(context).issues.getIssueMatrixSummary()
          : AppSettings.of(context).issues.getMyWorkingGroupSummary();
    }
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<WgIssueSummary>(
    future: _request,
    builder: (context, snapshot) {
      if (snapshot.connectionState != ConnectionState.done) {
        return const Padding(
          padding: EdgeInsets.all(24),
          child: Center(child: CircularProgressIndicator()),
        );
      }
      if (snapshot.hasError) {
        final l10n = AppLocalizations.of(context);
        return Column(
          children: [
            Text(l10n.text('issuesSummaryLoadError')),
            TextButton(
              onPressed: () => setState(() {
                _request = widget.matrix
                    ? AppSettings.of(context).issues.getIssueMatrixSummary()
                    : AppSettings.of(context).issues.getMyWorkingGroupSummary();
              }),
              child: Text(l10n.text('retry')),
            ),
          ],
        );
      }
      return widget.builder(snapshot.data!);
    },
  );
}
