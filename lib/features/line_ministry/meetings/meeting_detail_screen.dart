import 'package:flutter/material.dart';

import '../../../core/app_settings.dart';
import '../../../translations/app_localizations.dart';
import '../../shared/meetings/data/calendar_meeting.dart';
import 'meeting_request_detail_screen.dart';

class LineMinistryMeetingDetailScreen extends StatefulWidget {
  const LineMinistryMeetingDetailScreen({super.key, required this.meetingId});
  final int meetingId;

  @override
  State<LineMinistryMeetingDetailScreen> createState() =>
      _LineMinistryMeetingDetailScreenState();
}

class _LineMinistryMeetingDetailScreenState
    extends State<LineMinistryMeetingDetailScreen> {
  Future<CalendarMeeting>? _future;

  Future<CalendarMeeting> _load() =>
      AppSettings.of(context).meetings.getMeeting(widget.meetingId);

  @override
  void didUpdateWidget(covariant LineMinistryMeetingDetailScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.meetingId != widget.meetingId) _future = null;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context, page: 'meeting_calendar');
    return FutureBuilder<CalendarMeeting>(
      future: _future ??= _load(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done &&
            snapshot.hasData) {
          return LineMinistryMeetingRequestDetailScreen(
            request: snapshot.data!.details,
            translationPage: 'meeting_calendar',
          );
        }
        return Scaffold(
          appBar: AppBar(title: Text(l10n.text('meetingRequestDetails'))),
          body: Center(
            child:
                snapshot.connectionState == ConnectionState.done &&
                    snapshot.hasError
                ? Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(l10n.text('meetingsLoadError')),
                      TextButton(
                        onPressed: () => setState(() {
                          _future = null;
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
}
