import 'package:flutter/material.dart';

import 'meeting_request_detail_screen.dart';

class PrivateSectorMeetingDetailScreen extends StatelessWidget {
  const PrivateSectorMeetingDetailScreen({
    super.key,
    required this.title,
  });

  final String title;

  @override
  Widget build(BuildContext context) {
    return MeetingRequestDetailScreen(title: title);
  }
}
