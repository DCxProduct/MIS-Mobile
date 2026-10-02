import 'package:flutter/material.dart';

import '../../core/app_settings.dart';
import '../../core/config/module_config.dart';
import '../../core/network/api_client.dart';
import '../../features/shared/meetings/data/progress_report.dart';
import '../../features/shared/meetings/data/progress_reports_repository.dart';
import '../../translations/app_localizations.dart';
import 'report_detail_screen.dart';

/// Loads the complete detail rather than rendering a partial list record.
class ProgressReportDetailLoader extends StatefulWidget {
  const ProgressReportDetailLoader({super.key, required this.id, this.scope});
  final int id;
  final ProgressReportDetailScope? scope;

  @override
  State<ProgressReportDetailLoader> createState() =>
      _ProgressReportDetailLoaderState();
}

class _ProgressReportDetailLoaderState
    extends State<ProgressReportDetailLoader> {
  Future<ProgressReport>? _future;

  Future<ProgressReport> _load() {
    final settings = AppSettings.of(context);
    final scope =
        widget.scope ??
        switch (settings.moduleType) {
          AppModuleType.lineMinistry => ProgressReportDetailScope.ministry,
          AppModuleType.privateSector =>
            ProgressReportDetailScope.sharedAssignment,
          _ => ProgressReportDetailScope.report,
        };
    return settings.progressReports.getDetail(widget.id, scope: scope);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _future ??= _load();
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<ProgressReport>(
    future: _future,
    builder: (context, snapshot) {
      if (snapshot.hasData) {
        return ReportDetailScreen(
          title: snapshot.data!.title,
          report: snapshot.data!,
        );
      }
      final l10n = AppLocalizations.of(context);
      return Scaffold(
        appBar: AppBar(title: const Text('Progress Report Details')),
        body: snapshot.hasError
            ? Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      snapshot.error is ApiException
                          ? (snapshot.error as ApiException).message
                          : l10n.text('notificationDetailError'),
                      textAlign: TextAlign.center,
                    ),
                    TextButton(
                      onPressed: () => setState(() {
                        _future = _load();
                      }),
                      child: Text(l10n.text('retry')),
                    ),
                  ],
                ),
              )
            : const Center(child: CircularProgressIndicator()),
      );
    },
  );
}
