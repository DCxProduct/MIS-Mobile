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
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _future ??= AppSettings.of(context).meetings.getMeetings();
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
                _future = AppSettings.of(context).meetings.getMeetings();
              }),
              child: Text(l10n.text('retry')),
            ),
          ],
        );
      if (snapshot.data!.isEmpty) return Text(l10n.text('noMeetings'));
      return widget.builder(snapshot.data!);
    },
  );
}
