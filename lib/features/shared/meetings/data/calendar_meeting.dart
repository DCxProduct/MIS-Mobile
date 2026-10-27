import 'meeting_request.dart';

class CalendarMeeting {
  CalendarMeeting._(
    this.details,
    this.date,
    this.startTime,
    this.location,
    this.guestCount,
  );
  final MeetingRequest details;
  final DateTime? date, startTime;
  final String location;
  final int guestCount;

  factory CalendarMeeting.fromJson(Map<String, dynamic> json) {
    final requests = <Map<String, dynamic>>[
      if (json['meetingRequest'] != null)
        json['meetingRequest'] as Map<String, dynamic>,
      for (final link in json['linkedMeetingRequests'] as List? ?? [])
        link['meetingRequest'] as Map<String, dynamic>,
    ];
    final issues = <int, Map<String, dynamic>>{};
    final agencies = <String, dynamic>{};
    // Detail responses may include issues/agencies directly as well as through
    // linked meeting requests. Merge both sources instead of dropping either.
    for (final raw in [
      ...json['issues'] as List? ?? [],
      for (final link in json['linkedIssues'] as List? ?? []) link['issue'],
    ]) {
      final issue = raw as Map<String, dynamic>;
      issues[issue['id'] as int] = issue;
    }
    for (final agency in json['governmentAgencies'] as List? ?? []) {
      agencies['${agency['stakeholder']['id'] ?? agency['stakeholder']['name']}'] =
          agency;
    }
    for (final request in requests) {
      for (final raw in [
        ...request['issues'] as List? ?? [],
        for (final link in request['linkedIssues'] as List? ?? [])
          link['issue'],
      ]) {
        final issue = raw as Map<String, dynamic>;
        issues.putIfAbsent(
          issue['id'] as int,
          () => {...issue, 'user': issue['user'] ?? request['user']},
        );
      }
      for (final agency in request['governmentAgencies'] as List? ?? []) {
        agencies['${agency['stakeholder']['id'] ?? agency['stakeholder']['name']}'] =
            agency;
      }
    }
    final firstRequest = requests.isEmpty
        ? const <String, dynamic>{}
        : requests.first;
    final document =
        json['documentReference'] ?? firstRequest['meetingRequestLetter'];
    final user =
        (json['user'] ?? firstRequest['user']) as Map<String, dynamic>?;
    final group = json['workingGroupName'] ?? firstRequest['privateSectorWG'];
    final details = MeetingRequest({
      ...json,
      'receivedBy': json['receivedBy'] ?? firstRequest['receivedBy'],
      'submittedAt':
          json['submittedAt'] ??
          json['createdAt'] ??
          firstRequest['submittedAt'],
      'user': {
        ...?user,
        'stakeholders': (group == null
            ? (user?['stakeholders'] ?? [])
            : [
                {
                  'stakeholder': {
                    'name': group,
                    'khName': json['workingGroupKhName'],
                  },
                },
              ]),
      },
      'governmentAgencies': agencies.values.toList(),
      'issues': issues.values.toList(),
      'issuesCount': json['issueCount'] ?? issues.length,
      'meetingRequestLetter': document is String
          ? {'path': document, 'name': document.split('/').last}
          : document,
    });
    return CalendarMeeting._(
      details,
      json['meetingDate'] == null
          ? null
          : DateTime.parse(json['meetingDate'] as String),
      json['startTime'] == null
          ? null
          : DateTime.parse(json['startTime'] as String),
      json['location'] as String? ?? '',
      (json['guests'] as List? ?? []).length,
    );
  }
}
