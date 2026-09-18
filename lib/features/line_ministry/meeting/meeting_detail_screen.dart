import 'package:flutter/material.dart';

import '../../../screens/meeting/meeting_request_detail_screen.dart';

class LineMinistryMeetingDetailScreen extends StatelessWidget {
  const LineMinistryMeetingDetailScreen({
    super.key,
    required this.title,
  });

  final String title;

  @override
  Widget build(BuildContext context) {
    return MeetingRequestDetailScreen(title: title);
  }
}
