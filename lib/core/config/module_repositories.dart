import '../network/api_client.dart';
import '../../features/shared/dashboard/data/dashboard_repository.dart';
import '../../features/shared/issues/data/issues_repository.dart';
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
    MeetingRequestsRepository? meetingRequests,
    MeetingsRepository? meetings,
    MeetingSummariesRepository? meetingSummaries,
    ProgressReportsRepository? progressReports,
    PlenariesRepository? plenaries,
    RgcDecisionsRepository? rgcDecisions,
  }) : dashboard = dashboard ?? DashboardRepository(apiClient),
       issues = issues ?? IssuesRepository(apiClient),
       meetingRequests =
           meetingRequests ?? MeetingRequestsRepository(apiClient),
       meetings = meetings ?? MeetingsRepository(apiClient),
       meetingSummaries =
           meetingSummaries ?? MeetingSummariesRepository(apiClient),
       progressReports =
           progressReports ?? ProgressReportsRepository(apiClient),
       plenaries = plenaries ?? PlenariesRepository(apiClient),
       rgcDecisions = rgcDecisions ?? RgcDecisionsRepository(apiClient);

  final DashboardRepository dashboard;
  final IssuesRepository issues;
  final MeetingRequestsRepository meetingRequests;
  final MeetingsRepository meetings;
  final MeetingSummariesRepository meetingSummaries;
  final ProgressReportsRepository progressReports;
  final PlenariesRepository plenaries;
  final RgcDecisionsRepository rgcDecisions;
}
