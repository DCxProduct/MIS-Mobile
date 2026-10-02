import '../../../../core/widgets/filters/api_filter_scope.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../../../core/app_settings.dart';
import '../../../../translations/app_localizations.dart';
import '../data/calendar_meeting.dart';

class MeetingsLoader extends StatefulWidget {
  const MeetingsLoader({super.key, required this.builder});
  final Widget Function(List<CalendarMeeting>) builder;
  @override
  State<MeetingsLoader> createState() => _MeetingsLoaderState();
}

class _MeetingsLoaderState extends State<MeetingsLoader> {
  Future<List<CalendarMeeting>>? _future;
  Map<String, String>? _query;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final query = ApiFilterScope.query(context, 'meetings');
    if (_future == null || !mapEquals(_query, query)) {
      _query = Map.of(query);
      _future = AppSettings.of(context).meetings.getMeetings(filters: query);
    }
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<List<CalendarMeeting>>(
    future: _future,
    builder: (context, snapshot) {
      final l10n = AppLocalizations.of(context);
      if (snapshot.connectionState != ConnectionState.done)
        return const Center(child: CircularProgressIndicator());
      if (snapshot.hasError)
        return Column(
          children: [
            Text(l10n.text('meetingsLoadError')),
            TextButton(
              onPressed: () => setState(() {
                _future = AppSettings.of(
                  context,
                ).meetings.getMeetings(filters: _query ?? const {});
              }),
              child: Text(l10n.text('retry')),
            ),
          ],
        );
      final selection = ApiFilterScope.selection(context, 'meetings');
      final items = snapshot.data!
          .where((item) => selection.matchesLocal(item.details.filterValues))
          .toList();
      if (items.isEmpty) return Text(l10n.text('noMeetings'));
      return widget.builder(items);
    },
  );
}
