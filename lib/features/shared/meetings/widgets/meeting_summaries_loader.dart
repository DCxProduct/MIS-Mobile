import '../../../../core/widgets/filters/api_filter_scope.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../../core/app_settings.dart';
import '../../../../translations/app_localizations.dart';
import '../data/meeting_summary.dart';

class MeetingSummariesLoader extends StatefulWidget {
  const MeetingSummariesLoader({super.key, required this.builder});

  final Widget Function(List<MeetingSummary>) builder;

  @override
  State<MeetingSummariesLoader> createState() => _MeetingSummariesLoaderState();
}

class _MeetingSummariesLoaderState extends State<MeetingSummariesLoader> {
  Future<List<MeetingSummary>>? _future;

  Map<String, String>? _query;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final query = ApiFilterScope.query(context, 'meeting-summaries');
    if (_future == null || !mapEquals(_query, query)) {
      _query = Map.of(query);
      _future = AppSettings.of(
        context,
      ).meetingSummaries.getSummaries(filters: query);
    }
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<List<MeetingSummary>>(
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
            Text(l10n.text('meetingSummariesLoadError')),
            TextButton(
              onPressed: () => setState(() {
                _future = AppSettings.of(
                  context,
                ).meetingSummaries.getSummaries(filters: _query ?? const {});
              }),
              child: Text(l10n.text('retry')),
            ),
          ],
        );
      }
      final selection = ApiFilterScope.selection(context, 'meeting-summaries');
      final summaries = (snapshot.data ?? const <MeetingSummary>[])
          .where((item) => selection.matchesLocal(item.filterValues))
          .toList();
      if (summaries.isEmpty) return Text(l10n.text('noMeetingSummaries'));
      return widget.builder(summaries);
    },
  );
}
