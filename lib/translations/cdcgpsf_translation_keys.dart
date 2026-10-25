import 'ministry_translation_keys.dart';

// Shared web pages expose the same keys in ministry and cdcgpsf dictionaries.
// CDC-only pages are mapped separately; values always come from cdcgpsf.
final cdcGpsfCommonKeys = <String, String>{
  ...ministryCommonKeys,
  'wgMeeting': 'meeting_calendar.title',
  'plenaries': 'plenary_plenaries.title',
  'rgcDecision': 'issue_matrix_rgc_decision.rgc.page.title',
};

const cdcGpsfPageParents = <String, String>{
  ...ministryPageParents,
  'cdc_rgc_detail': 'cdc_rgc',
  'cdc_rgc_report': 'cdc_rgc_detail',
  'cdc_progress_ministries': 'progress_report',
};

const _rgcKeys = <String, String>{
  'wgIssues': 'issue_matrix_rgc_decision.rgc.page.title',
  'rgcDecision': 'issue_matrix_rgc_decision.rgc.page.title',
  'rgcDecisionDetails': 'issue_matrix_rgc_decision.rgc.detail.title',
  'categories': 'issue_matrix_rgc_decision.rgc.column.category',
  'focalPerson': 'issue_matrix_rgc_decision.rgc.column.focal_person',
  'focalPersonHE': 'issue_matrix_rgc_decision.rgc.column.focal_person',
  'meetingDate': 'issue_matrix_rgc_decision.rgc.column.meeting_date',
  'status': 'issue_matrix_rgc_decision.rgc.column.status',
  'totalIssues': 'issue_matrix_rgc_decision.stats.total_issues',
  'solved': 'issue_matrix_rgc_decision.stats.solved',
  'inProgress': 'issue_matrix_rgc_decision.stats.in_progress',
  'notAddressed': 'issue_matrix_rgc_decision.stats.not_addressed',
  'viewDetails': 'issue_matrix_rgc_decision.rgc.action.view_detail',
  'noRgcDecisions': 'issue_matrix_rgc_decision.rgc.empty',
  'rgcDecisionsLoadError': 'issue_matrix_rgc_decision.rgc.error.load',
  'noData': 'issue_matrix_rgc_decision.rgc.grid.empty',
  'filter': 'issue_matrix_rgc_decision.rgc.filter_panel.filter',
  'filters': 'issue_matrix_rgc_decision.rgc.filter_panel.filters',
  'applyFilters': 'issue_matrix_rgc_decision.rgc.filter_panel.applyFilters',
  'clearAllFilters': 'issue_matrix_rgc_decision.rgc.filter_panel.clearAll',
  'viewAll': 'issue_matrix_rgc_decision.rgc.filter_panel.viewAll',
  'viewLess': 'issue_matrix_rgc_decision.rgc.filter_panel.viewLess',
};

final _rgcDetailKeys = <String, String>{
  ..._rgcKeys,
  'rgcDecision': 'issue_matrix_rgc_decision.rgc.detail.rgc_decision',
  'plenary': 'issue_matrix_rgc_decision.rgc.detail.plenary',
  'categories': 'issue_matrix_rgc_decision.rgc.detail.category',
  'status': 'issue_matrix_rgc_decision.rgc.detail.status',
  'governmentAgency': 'issue_matrix_rgc_decision.rgc.detail.ministry',
  'primaryAgency': 'issue_matrix_rgc_decision.rgc.detail.ministry',
  'focalPerson': 'issue_matrix_rgc_decision.rgc.detail.focal_person',
  'focalPersonHE': 'issue_matrix_rgc_decision.rgc.detail.focal_person',
  'meetingDate': 'issue_matrix_rgc_decision.rgc.detail.meeting_date',
  'issuesDescription':
      'issue_matrix_rgc_decision.rgc.detail.issues_description',
  'recommendations': 'issue_matrix_rgc_decision.rgc.detail.recommendations',
  'indicators': 'issue_matrix_rgc_decision.rgc.detail.indicators',
  'progressSolution': 'issue_matrix_rgc_decision.rgc.detail.progress_solution',
  'implementationChallenges':
      'issue_matrix_rgc_decision.rgc.detail.implementation_challenges',
  'nextStep': 'issue_matrix_rgc_decision.rgc.detail.next_step',
  'request': 'issue_matrix_rgc_decision.rgc.detail.request',
  'sourceOfVerification':
      'issue_matrix_rgc_decision.rgc.detail.source_of_verification',
  'linkToVerificationSource':
      'issue_matrix_rgc_decision.rgc.detail.verification_link',
  'governmentSecondAgency': 'issue_matrix_rgc_decision.column.second_agency',
  'governmentThirdAgency': 'issue_matrix_rgc_decision.column.third_agency',
  'governmentFourthAgency': 'issue_matrix_rgc_decision.column.fourth_agency',
  'governmentFifthAgency': 'issue_matrix_rgc_decision.column.fifth_agency',
};

final cdcGpsfPageKeys = <String, Map<String, String>>{
  ...ministryPageKeys,
  'meeting_summary_issue': {
    ...ministryPageKeys['meeting_summary_issue']!,
    'issueEscalation': 'meeting_summary.issue_dialog.escalation',
    'solutionReferenceDocument':
        'meeting_summary.issue_dialog.solution_reference',
    'rgcDecision': 'meeting_summary.issue_dialog.rgc_decision',
    'nextStep': 'meeting_summary.issue_dialog.next_step',
    'remark': 'meeting_summary.issue_dialog.remark',
  },
  // CDC's API currently exposes only a title for the standalone plenary page.
  'plenary_plenaries': {'plenary': 'plenary_plenaries.title'},
  'plenary_rgc_decisions': _rgcDetailKeys,
  'cdc_rgc': _rgcKeys,
  'cdc_rgc_detail': _rgcDetailKeys,
  'cdc_rgc_report': {
    'rgcReportNoReference': 'issue_matrix_rgc_decision.rgc.report.not_available',
    'rgcReportReferenceName':
        'issue_matrix_rgc_decision.rgc.report.referenceName',
    'rgcReportReferenceAttachment':
        'issue_matrix_rgc_decision.rgc.report.issue_attachment',
    'rgcReportSolutionIndicators':
        'issue_matrix_rgc_decision.rgc.report.solutionIndicators',
    'rgcReportChallenges': 'issue_matrix_rgc_decision.rgc.report.challenges',
    'requests': 'issue_matrix_rgc_decision.rgc.report.requests',
    'noProgressReports': 'issue_matrix_rgc_decision.rgc.report.no_progress',
    'implementationDate':
        'issue_matrix_rgc_decision.rgc.report.implementationDate',
    'referenceName': 'issue_matrix_rgc_decision.rgc.report.referenceName',
    'attachmentsLabel': 'issue_matrix_rgc_decision.rgc.report.issue_attachment',
    'progressSolution': 'issue_matrix_rgc_decision.rgc.report.progressSolution',
    'indicators': 'issue_matrix_rgc_decision.rgc.report.solutionIndicators',
    'implementationChallenges':
        'issue_matrix_rgc_decision.rgc.report.challenges',
    'request': 'issue_matrix_rgc_decision.rgc.report.requests',
    'rgcDecision': 'issue_matrix_rgc_decision.rgc.report.rgcDecision',
    'linkToVerificationSource':
        'issue_matrix_rgc_decision.rgc.report.referenceLink',
  },
  'cdc_progress_ministries': {
    'status': 'progress_reports.table.detail.columns.status',
    'allIssues': 'progress_reports.table.detail.columns.issue_count',
    'requestDocument': 'progress_reports.table.detail.columns.request_document',
    'approvalReport': 'progress_reports.table.detail.columns.attachment',
    'progressReportDetails': 'progress_reports.table.detail.page_title',
    'progressReportsLoadError': 'progress_reports.table.detail.load_error',
    'descriptions': 'progress_reports.table.detail.description',
    'year': 'progress_reports.table.detail.year',
    'governmentAgency': 'progress_reports.table.detail.grid_view',
    'viewDetails': 'progress_reports.table.detail.view_detail',
    'reportDraftSemester': 'progress_reports.table.detail.draft_semester',
    'reportFinalSemester': 'progress_reports.table.detail.final_semester',
    'reportInitialDeadline':
        'progress_reports.table.detail.schedule_names.deadline',
    'reportNumberedMeeting':
        'progress_reports.table.detail.schedule_names.meeting',
    'reportRevisionDeadline':
        'progress_reports.table.detail.schedule_names.revision_deadline',
    'reportRequested':
        'progress_reports.table.detail.ministry_statuses.requested',
    'preparing': 'progress_reports.table.detail.ministry_statuses.preparing',
    'reportReturned':
        'progress_reports.table.detail.ministry_statuses.returned',
    'reportUpdating':
        'progress_reports.table.detail.ministry_statuses.updating',
    'reportResubmitted':
        'progress_reports.table.detail.ministry_statuses.resubmitted',
    'reportReReviewing':
        'progress_reports.table.detail.ministry_statuses.cdc_re_reviewing',
    'reportSharedWithPswg':
        'progress_reports.table.detail.ministry_statuses.shared_with_pswg',
    'pswgReviewed':
        'progress_reports.table.detail.ministry_statuses.pswg_reviewed',
    'reportSubmitted':
        'progress_reports.table.detail.ministry_statuses.submitted',
    'underReview':
        'progress_reports.table.detail.ministry_statuses.cdc_under_review',
    'reviewed': 'progress_reports.table.detail.ministry_statuses.completed',
  },
};

const _rgcFilterKeys = <String, String>{
  'status': 'issue_matrix_rgc_decision.rgc.filter.status',
  'categories': 'issue_matrix_rgc_decision.rgc.filter.category',
  'category': 'issue_matrix_rgc_decision.rgc.filter.category',
  'primaryAgency': 'issue_matrix_rgc_decision.rgc.filter.primary_agency',
  'meetingDate': 'issue_matrix_rgc_decision.rgc.filter.meeting_date',
};

const cdcGpsfFilterKeys = <String, Map<String, String>>{
  ...ministryFilterKeys,
  'cdc_rgc': _rgcFilterKeys,
  'cdc_rgc_detail': _rgcFilterKeys,
  'plenary_rgc_decisions': _rgcFilterKeys,
};
