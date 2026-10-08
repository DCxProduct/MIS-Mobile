import '../../../../core/config/module_config.dart';
import 'system_notification.dart';

enum NotificationDestinationKind {
  meetingRequest,
  scheduledMeeting,
  calendar,
  plenary,
  progressReport,
  sharedProgressReport,
  meetingSummary,
  editMeetingSummary,
  rgcDecision,
  rgcDecisions,
  issueMatrix,
  issue,
}

class NotificationDestination {
  const NotificationDestination(this.kind, this.route, {this.id});
  final NotificationDestinationKind kind;
  final String route;
  final int? id;

  String? get endpoint => switch (kind) {
    NotificationDestinationKind.meetingRequest => 'meeting-requests/$id',
    NotificationDestinationKind.scheduledMeeting => 'meetings/$id',
    NotificationDestinationKind.plenary => 'plenaries/$id',
    NotificationDestinationKind.progressReport =>
      'progress-reports/$id/ministries/me',
    NotificationDestinationKind.sharedProgressReport =>
      'progress-reports/assignments/$id',
    NotificationDestinationKind.meetingSummary ||
    NotificationDestinationKind.editMeetingSummary => 'meeting-summaries/$id',
    NotificationDestinationKind.issue => 'working-group-issues/$id',
    NotificationDestinationKind.rgcDecision => 'rgc-decisions/$id',
    _ => null,
  };

  /// The URL identifies the notification's recipient module. Accept only the
  /// documented internal route for its type; never open arbitrary data URLs.
  static NotificationDestination? resolve(
    SystemNotification notification,
    AppModuleType module,
  ) {
    if (notification.type == 'ISSUE_ESCALATED') return null;
    final url = notification.url;
    if (url != null) return _fromUrl(notification, url);
    final ministry = module == AppModuleType.lineMinistry;
    final pswg = module == AppModuleType.privateSector;
    final gpsf = module == AppModuleType.cdcSecretariat;
    int? id;
    String? route;
    switch (notification.type) {
      case 'MEETING_REQUEST' when ministry:
        id =
            notification.resourceId('meetingRequestId') ??
            notification.meetingRequestId;
        if (id != null) route = '/ministry/meeting-requests/$id';
      case 'MEETING_SCHEDULED' when pswg || gpsf:
        id = notification.resourceId('meetingId');
        route = gpsf
            ? '/cdc-gpsf/meeting-calendar'
            : id != null
            ? '/pswg/meeting-requests?view=calendar&meetingId=$id'
            : null;
      case 'PLENARY_SENT' when ministry:
        id = notification.resourceId('plenaryId');
        if (id != null) route = '/ministry/plenary/plenaries/$id';
      case 'PROGRESS_REPORT_SENT' ||
              'PROGRESS_REPORT_COMPLETED' ||
              'PROGRESS_REPORT_PSWG_REVIEWED'
          when ministry:
        id = notification.resourceId('progressReportId');
        if (id != null) route = '/ministry/progress-reports/$id';
      case 'PROGRESS_REPORT_SHARED' when pswg:
        // Shared report URLs identify a ministry assignment, not the parent
        // progress report. Never substitute progressReportId for this ID.
        id = notification.resourceId('assignmentId');
        if (id != null) route = '/pswg/progress-report/$id';
      case 'MEETING_SUMMARY_SENT_BACK' when ministry:
        id = notification.resourceId('meetingSummaryId');
        if (id != null) route = '/ministry/meeting-summary/$id/edit';
      case 'MEETING_SUMMARY_SHARED' when pswg:
        id = notification.resourceId('meetingSummaryId');
        if (id != null) route = '/pswg/meeting-summary/$id';
      case 'MEETING_SUMMARY_SUBMITTED' when gpsf:
        id = notification.resourceId('meetingSummaryId');
        if (id != null) route = '/cdc-gpsf/meeting-summary/$id';
      case 'RGC_DECISION_SUBMITTED':
        final decisionId = notification.resourceId('rgcDecisionId');
        if (decisionId != null &&
            (ministry || gpsf || module == AppModuleType.cefp)) {
          return NotificationDestination(
            NotificationDestinationKind.rgcDecision,
            '/rgc-decisions/$decisionId',
            id: decisionId,
          );
        }
        id = notification.resourceId('plenaryId');
        if (module == AppModuleType.cefp) {
          route = '/cefp/plenary/rgc-decision';
        } else if (id != null && (ministry || gpsf)) {
          route =
              '/${ministry ? 'ministry' : 'cdc-gpsf'}/plenary/plenaries/$id';
        }
      case 'ISSUE_AGENCY_REASSIGNED' when ministry || pswg:
        id = notification.resourceId('issueId');
        route = ministry
            ? '/ministry/issue-matrix'
            : id != null
            ? '/pswg/wg-issues/$id'
            : null;
    }
    return route == null ? null : _fromUrl(notification, route);
  }

  static NotificationDestination? _fromUrl(SystemNotification n, String url) {
    final uri = Uri.tryParse(url);
    if (uri == null || uri.hasScheme || uri.hasAuthority || uri.hasFragment) {
      return null;
    }
    final path = uri.path;
    NotificationDestination? detail(
      String pattern,
      NotificationDestinationKind kind,
    ) {
      final match = RegExp(pattern).firstMatch(path);
      final id = match == null ? null : int.tryParse(match.group(1)!);
      return id != null && id > 0
          ? NotificationDestination(kind, url, id: id)
          : null;
    }

    return switch (n.type) {
      'MEETING_REQUEST' => detail(
        r'^/ministry/meeting-requests/(\d+)$',
        NotificationDestinationKind.meetingRequest,
      ),
      'PLENARY_SENT' => detail(
        r'^/ministry/plenary/plenaries/(\d+)$',
        NotificationDestinationKind.plenary,
      ),
      'PROGRESS_REPORT_SENT' ||
      'PROGRESS_REPORT_COMPLETED' ||
      'PROGRESS_REPORT_PSWG_REVIEWED' => detail(
        r'^/ministry/progress-reports/(\d+)$',
        NotificationDestinationKind.progressReport,
      ),
      'PROGRESS_REPORT_SHARED' => detail(
        r'^/pswg/progress-report/(\d+)$',
        NotificationDestinationKind.sharedProgressReport,
      ),
      'MEETING_SUMMARY_SENT_BACK' => detail(
        r'^/ministry/meeting-summary/(\d+)/edit$',
        NotificationDestinationKind.editMeetingSummary,
      ),
      'MEETING_SUMMARY_SHARED' => detail(
        r'^/pswg/meeting-summary/(\d+)$',
        NotificationDestinationKind.meetingSummary,
      ),
      'MEETING_SUMMARY_SUBMITTED' => detail(
        r'^/cdc-gpsf/meeting-summary/(\d+)$',
        NotificationDestinationKind.meetingSummary,
      ),
      'RGC_DECISION_SUBMITTED' => _rgcDecision(n, path, url),
      'ISSUE_AGENCY_REASSIGNED' =>
        path == '/ministry/issue-matrix'
            ? NotificationDestination(
                NotificationDestinationKind.issueMatrix,
                url,
              )
            : detail(
                r'^/pswg/wg-issues/(\d+)$',
                NotificationDestinationKind.issue,
              ),
      'MEETING_SCHEDULED' => _scheduledMeeting(n, uri, url),
      _ => null,
    };
  }

  static NotificationDestination? _rgcDecision(
    SystemNotification n,
    String path,
    String url,
  ) {
    final cefp = path == '/cefp/plenary/rgc-decision';
    final match = RegExp(
      r'^/(?:ministry|cdc-gpsf)/plenary/plenaries/(\d+)$',
    ).firstMatch(path);
    final plenaryId = match == null ? null : int.tryParse(match.group(1)!);
    if (!cefp && (plenaryId == null || plenaryId <= 0)) return null;
    final decisionId = n.resourceId('rgcDecisionId');
    if (decisionId != null) {
      return NotificationDestination(
        NotificationDestinationKind.rgcDecision,
        url,
        id: decisionId,
      );
    }
    // Older notifications without a decision ID still open their linked
    // plenary or decision list; the plenary ID must not become a decision ID.
    return NotificationDestination(
      cefp
          ? NotificationDestinationKind.rgcDecisions
          : NotificationDestinationKind.plenary,
      url,
      id: plenaryId,
    );
  }

  static NotificationDestination? _scheduledMeeting(
    SystemNotification n,
    Uri uri,
    String url,
  ) {
    if (uri.path == '/cdc-gpsf/meeting-calendar') {
      final id = n.resourceId('meetingId');
      return NotificationDestination(
        id == null
            ? NotificationDestinationKind.calendar
            : NotificationDestinationKind.scheduledMeeting,
        url,
        id: id,
      );
    }
    final id = int.tryParse(uri.queryParameters['meetingId'] ?? '');
    if (uri.path != '/pswg/meeting-requests' ||
        uri.queryParameters['view'] != 'calendar' ||
        id == null ||
        id <= 0) {
      return null;
    }
    return NotificationDestination(
      NotificationDestinationKind.scheduledMeeting,
      url,
      id: id,
    );
  }
}
