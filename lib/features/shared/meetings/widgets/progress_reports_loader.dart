import 'package:flutter/material.dart';

import '../../../../core/app_settings.dart';
import '../../../../translations/app_localizations.dart';
import '../data/progress_report.dart';

class ProgressReportsLoader extends StatefulWidget {
  const ProgressReportsLoader({super.key, required this.builder});
  final Widget Function(List<ProgressReport>) builder;

  @override
  State<ProgressReportsLoader> createState() => _ProgressReportsLoaderState();
}

class _ProgressReportsLoaderState extends State<ProgressReportsLoader> {
  Future<List<ProgressReport>>? _future;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _future ??= AppSettings.of(context).progressReports.getReports();
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<List<ProgressReport>>(
    future: _future,
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
            Text(l10n.text('progressReportsLoadError')),
            TextButton(
              onPressed: () => setState(() {
                _future = AppSettings.of(context).progressReports.getReports();
              }),
              child: Text(l10n.text('retry')),
            ),
          ],
        );
      }
      final reports = snapshot.data ?? const <ProgressReport>[];
      if (reports.isEmpty) return Text(l10n.text('noProgressReports'));
      return widget.builder(reports);
    },
  );
}
