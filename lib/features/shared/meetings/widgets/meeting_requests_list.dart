import '../../../../core/widgets/filters/api_filter_scope.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../../../core/app_settings.dart';
import '../../../../translations/app_localizations.dart';
import '../data/meeting_request.dart';

class MeetingRequestsList extends StatefulWidget {
  const MeetingRequestsList({
    super.key,
    required this.itemBuilder,
    this.query = '',
  });
  final Widget Function(MeetingRequest) itemBuilder;
  final String query;
  @override
  State<MeetingRequestsList> createState() => _MeetingRequestsListState();
}

class _MeetingRequestsListState extends State<MeetingRequestsList> {
  Future<List<MeetingRequest>>? _request;
  Map<String, String>? _query;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final query = ApiFilterScope.query(context, 'meeting-requests');
    if (_request == null || !mapEquals(_query, query)) {
      _query = Map.of(query);
      _request = AppSettings.of(
        context,
      ).meetingRequests.getRequests(filters: query);
    }
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<List<MeetingRequest>>(
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
            Text(l10n.text('meetingRequestsLoadError')),
            TextButton(
              onPressed: () => setState(() {
                _request = AppSettings.of(
                  context,
                ).meetingRequests.getRequests(filters: _query ?? const {});
              }),
              child: Text(l10n.text('retry')),
            ),
          ],
        );
      }
      final query = widget.query.trim().toLowerCase();
      final selection = ApiFilterScope.selection(context, 'meeting-requests');
      final items = snapshot.data!
          .where((item) => selection.matchesLocal(item.filterValues))
          .where(
            (issue) =>
                query.isEmpty ||
                '${issue.title} ${issue.group} ${issue.description}'
                    .toLowerCase()
                    .contains(query),
          )
          .toList();
      if (items.isEmpty) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Text(l10n.text('noMeetingRequests')),
        );
      }
      return Column(
        children: [
          for (final issue in items)
            KeyedSubtree(
              key: ValueKey('meeting-request-${issue.id}'),
              child: widget.itemBuilder(issue),
            ),
        ],
      );
    },
  );
}
