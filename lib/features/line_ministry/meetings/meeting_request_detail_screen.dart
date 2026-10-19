import 'package:flutter/material.dart';

import '../../private_sector/meetings/meeting_request_detail_screen.dart';
import '../../shared/meetings/data/meeting_request.dart';

/// Display the selected ministry meeting using the shared API-backed view.
class LineMinistryMeetingRequestDetailScreen extends StatelessWidget {
  const LineMinistryMeetingRequestDetailScreen({
    super.key,
    required this.request,
  });
  final MeetingRequest request;

  @override
  Widget build(BuildContext context) =>
      MeetingRequestDetailScreen(title: request.title, request: request);
}
