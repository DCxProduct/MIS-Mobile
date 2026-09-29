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
    this.cdcMatrix = false,
  });

  final Widget Function(WgIssueSummary) builder;
  final bool matrix;
  final bool cdcMatrix;

  @override
  State<WgIssueSummaryLoader> createState() => _WgIssueSummaryLoaderState();
}

class _WgIssueSummaryLoaderState extends State<WgIssueSummaryLoader> {
  Future<WgIssueSummary>? _request;
  Future<WgIssueSummary> _load() {
    final settings = AppSettings.of(context);
    if (widget.cdcMatrix) return settings.cdcIssueMatrix.getSummary();
    return widget.matrix
        ? settings.issues.getIssueMatrixSummary()
        : settings.issues.getMyWorkingGroupSummary();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _request ??= _load();
  }

  @override
  void didUpdateWidget(covariant WgIssueSummaryLoader oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.matrix != widget.matrix ||
        oldWidget.cdcMatrix != widget.cdcMatrix) {
      _request = _load();
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
                _request = _load();
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
