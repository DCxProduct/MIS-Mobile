import '../network/api_client.dart';
import '../../features/shared/notifications/data/notifications_repository.dart';
import '../network/filter_catalog_repository.dart';
import '../../features/shared/dashboard/data/dashboard_repository.dart';
import '../../features/shared/issues/data/issues_repository.dart';
import '../../features/shared/issues/data/cdc_issue_matrix_repository.dart';
import '../../features/shared/meetings/data/meeting_requests_repository.dart';
import '../../features/shared/meetings/data/meetings_repository.dart';
import '../../features/shared/meetings/data/meeting_summaries_repository.dart';
import '../../features/shared/meetings/data/progress_reports_repository.dart';
import '../../features/shared/meetings/data/plenaries_repository.dart';
import '../../features/shared/meetings/data/rgc_decisions_repository.dart';

/// Data sources for a module, independent of the widgets it shares.
/// Supply a module's API client or override individual repositories when its
/// endpoint paths or response models differ. Defaults preserve the current API.
class ModuleRepositories {
  ModuleRepositories({
    required ApiClient apiClient,
    DashboardRepository? dashboard,
    IssuesRepository? issues,
    CdcIssueMatrixRepository? cdcIssueMatrix,
    MeetingRequestsRepository? meetingRequests,
    MeetingsRepository? meetings,
    MeetingSummariesRepository? meetingSummaries,
    ProgressReportsRepository? progressReports,
    PlenariesRepository? plenaries,
    RgcDecisionsRepository? rgcDecisions,
    NotificationsRepository? notifications,
  }) : filters = FilterCatalogRepository(apiClient),
       dashboard = dashboard ?? DashboardRepository(apiClient),
       issues = issues ?? IssuesRepository(apiClient),
       cdcIssueMatrix = cdcIssueMatrix ?? CdcIssueMatrixRepository(apiClient),
       meetingRequests =
           meetingRequests ?? MeetingRequestsRepository(apiClient),
       meetings = meetings ?? MeetingsRepository(apiClient),
       meetingSummaries =
           meetingSummaries ?? MeetingSummariesRepository(apiClient),
       progressReports =
           progressReports ?? ProgressReportsRepository(apiClient),
       plenaries = plenaries ?? PlenariesRepository(apiClient),
       rgcDecisions = rgcDecisions ?? RgcDecisionsRepository(apiClient),
       notifications = notifications ?? NotificationsRepository(apiClient);

  final DashboardRepository dashboard;
  final FilterCatalogRepository filters;
  final IssuesRepository issues;
  final CdcIssueMatrixRepository cdcIssueMatrix;
  final MeetingRequestsRepository meetingRequests;
  final MeetingsRepository meetings;
  final MeetingSummariesRepository meetingSummaries;
  final ProgressReportsRepository progressReports;
  final PlenariesRepository plenaries;
  final RgcDecisionsRepository rgcDecisions;
  final NotificationsRepository notifications;
}
