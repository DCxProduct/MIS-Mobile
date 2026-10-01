import 'package:flutter/material.dart';

import '../../../core/app_colors.dart';
import '../../../core/app_settings.dart';
import '../../../core/widgets/pdf_attachment_preview.dart';
import '../../shared/meetings/data/meeting_request.dart';
import '../../shared/meetings/data/rgc_decision.dart';
import '../../../translations/app_localizations.dart';
import '../issues/detail_widgets.dart';

Color cdcReportBackground(BuildContext context) => AppColors.isDark(context)
    ? AppColors.darkBackground
    : const Color(0xFFF8F9FA);

BoxDecoration cdcReportCardDecoration(BuildContext context) => BoxDecoration(
  color: AppColors.cardBackground(context),
  borderRadius: BorderRadius.circular(12),
  border: Border.all(color: AppColors.border(context)),
);

String rgcDate(DateTime? date) {
  if (date == null) return '—';
  // API timestamps are UTC; show their calendar date in Cambodia (UTC+7).
  // Values without a timezone already represent a calendar date.
  final displayDate = date.isUtc ? date.add(const Duration(hours: 7)) : date;
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  return '${months[displayDate.month - 1]} ${displayDate.day}, ${displayDate.year}';
}

String rgcValue(String value) => value.trim().isEmpty ? '—' : value;

Color _statusColor(String status) => status.toLowerCase() == 'solved'
    ? const Color(0xFF00BA36)
    : const Color(0xFFFF8A00);

class CdcRgcStatus extends StatelessWidget {
  const CdcRgcStatus({super.key, required this.status, this.fullWidth = false});
  final String status;
  final bool fullWidth;

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(status);
    return Container(
      width: fullWidth ? double.infinity : null,
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .04),
        border: Border.all(color: color.withValues(alpha: .5)),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: fullWidth ? MainAxisSize.max : MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (!fullWidth) ...[
            Icon(Icons.circle_outlined, size: 10, color: color),
            const SizedBox(width: 4),
          ],
          Text(
            rgcValue(status),
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 11, color: color),
          ),
        ],
      ),
    );
  }
}

AppBar _appBar(BuildContext context) => AppBar(
  backgroundColor: AppColors.cardBackground(context),
  surfaceTintColor: Colors.transparent,
  elevation: 0,
  centerTitle: true,
  title: Text(
    AppLocalizations.of(context).text('rgcDecisionDetails'),
    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
  ),
);

class CdcRgcDecisionOverviewScreen extends StatefulWidget {
  const CdcRgcDecisionOverviewScreen({super.key, required this.decisionId});
  final int decisionId;
  @override
  State<CdcRgcDecisionOverviewScreen> createState() => _OverviewState();
}

class _OverviewState extends State<CdcRgcDecisionOverviewScreen> {
  Future<RgcDecisionDetail>? _detail;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _detail ??= AppSettings.of(
      context,
    ).rgcDecisions.getDecision(widget.decisionId);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: cdcReportBackground(context),
      appBar: _appBar(context),
      body: FutureBuilder<RgcDecisionDetail>(
        future: _detail,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            if (snapshot.hasError) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(l10n.text('rgcDecisionsLoadError')),
                    TextButton(
                      onPressed: () => setState(
                        () => _detail = AppSettings.of(
                          context,
                        ).rgcDecisions.getDecision(widget.decisionId),
                      ),
                      child: Text(l10n.text('retry')),
                    ),
                  ],
                ),
              );
            }
            return const Center(child: CircularProgressIndicator());
          }
          final detail = snapshot.data!;
          final decision = detail.decision;
          return ListView(
            key: const ValueKey('cdc-rgc-overview'),
            children: [
              Container(
                color: AppColors.cardBackground(context),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: CdcDetailInfoValue(
                            label: l10n.text('deadline'),
                            value: rgcDate(detail.deadline),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: CdcDetailInfoValue(
                            label: l10n.text('meetingDate'),
                            value: rgcDate(decision.meetingDate),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: CdcDetailInfoValue(
                            label: l10n.text('numberOfRgcDecision'),
                            value: '${decision.id}',
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: CdcDetailInfoValue(
                            label: l10n.text('status'),
                            value: rgcValue(decision.status),
                            color: _statusColor(decision.status),
                          ),
                        ),
                      ],
                    ),
                    if (detail.approvalReport.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      Text(
                        l10n.text('approvalReport'),
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.mutedText,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(
                            Icons.picture_as_pdf,
                            size: 18,
                            color: Color(0xFFFF4842),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              detail.approvalReport,
                              style: const TextStyle(fontSize: 11),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 16, 14, 24),
                child: detail.issues.isEmpty
                    ? Center(child: Text(l10n.text('noRgcDecisions')))
                    : Column(
                        children: [
                          for (final issue in detail.issues) ...[
                            _DecisionIssueCard(detail: detail, issue: issue),
                            const SizedBox(height: 14),
                          ],
                        ],
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _DecisionIssueCard extends StatelessWidget {
  const _DecisionIssueCard({required this.detail, required this.issue});
  final RgcDecisionDetail detail;
  final RgcDecisionIssue issue;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Material(
      color: AppColors.cardBackground(context),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppColors.border(context)),
      ),
      child: InkWell(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) =>
                CdcRgcDecisionIssueScreen(detail: detail, issue: issue),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 12,
                    child: _Info(
                      icon: Icons.calendar_month_outlined,
                      color: const Color(0xFF1890FF),
                      label: l10n.text('meetingDate'),
                      value: rgcDate(
                        issue.meetingDate ?? detail.decision.meetingDate,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    flex: 10,
                    child: _Info(
                      icon: Icons.file_copy_outlined,
                      color: const Color(0xFFB437FF),
                      label: l10n.text('categories'),
                      value: rgcValue(
                        issue.category.isEmpty
                            ? detail.decision.category
                            : issue.category,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    flex: 10,
                    child: _Info(
                      icon: Icons.person_outline,
                      color: AppColors.primaryText(context),
                      label: l10n.text('focalPerson'),
                      value: rgcValue(
                        issue.focalPerson.isEmpty
                            ? detail.decision.focalPerson
                            : issue.focalPerson,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                rgcValue(issue.rgcDecision),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12, height: 1.35),
              ),
              const SizedBox(height: 14),
              Divider(height: 1, color: AppColors.border(context)),
              const SizedBox(height: 14),
              CdcRgcStatus(
                status: issue.status.isEmpty
                    ? detail.decision.status
                    : issue.status,
                fullWidth: true,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Info extends StatelessWidget {
  const _Info({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
  });
  final IconData icon;
  final Color color;
  final String label, value;
  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Container(
        width: 22,
        height: 22,
        color: color.withValues(alpha: .08),
        child: Icon(icon, size: 17, color: color),
      ),
      const SizedBox(width: 6),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 10, color: AppColors.mutedText),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 11),
            ),
          ],
        ),
      ),
    ],
  );
}

class CdcRgcDecisionIssueScreen extends StatefulWidget {
  const CdcRgcDecisionIssueScreen({
    super.key,
    required this.detail,
    required this.issue,
  });
  final RgcDecisionDetail detail;
  final RgcDecisionIssue issue;

  @override
  State<CdcRgcDecisionIssueScreen> createState() => _IssueScreenState();
}

class _IssueScreenState extends State<CdcRgcDecisionIssueScreen> {
  Future<MeetingRequest?>? _meetingRequest;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_meetingRequest == null &&
        widget.issue.meetingRequestDocumentPath.isEmpty &&
        widget.issue.meetingRequestId > 0) {
      _meetingRequest = _loadMeetingRequest();
    }
  }

  Future<MeetingRequest?> _loadMeetingRequest() async {
    try {
      final requests = await AppSettings.of(
        context,
      ).meetingRequests.getRequests();
      for (final request in requests) {
        if (request.id == widget.issue.meetingRequestId) return request;
      }
    } catch (_) {
      // A missing or restricted request must not block the decision detail.
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final issue = widget.issue;
    final detail = widget.detail;
    final sections = [
      ('issuesDescription', issue.description),
      ('recommendations', issue.recommendations),
      ('rgcDecision', issue.rgcDecision),
      ('indicators', issue.indicators),
      ('progressSolution', issue.progressSolution),
      ('implementationChallenges', issue.implementationChallenges),
      ('request', issue.request),
      ('nextStep', issue.nextStep),
      ('sourceOfVerification', issue.sourceOfVerification),
      ('linkToVerificationSource', issue.verificationLink),
    ];
    return Scaffold(
      backgroundColor: cdcReportBackground(context),
      appBar: _appBar(context),
      body: ListView(
        key: const ValueKey('cdc-rgc-issue-details'),
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: CdcDetailInfoValue(
                  label: l10n.text('submittedBy'),
                  value: rgcValue(issue.submittedBy),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: CdcDetailInfoValue(
                  label: l10n.text('status'),
                  value: rgcValue(
                    issue.status.isEmpty
                        ? detail.decision.status
                        : issue.status,
                  ),
                  color: _statusColor(issue.status),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: CdcDetailInfoValue(
                  label: l10n.text('categories'),
                  value: rgcValue(
                    issue.category.isEmpty
                        ? detail.decision.category
                        : issue.category,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.text('meetingRequestDocument'),
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.mutedText,
                      ),
                    ),
                    const SizedBox(height: 8),
                    FutureBuilder<MeetingRequest?>(
                      future: _meetingRequest,
                      builder: (context, snapshot) {
                        final request = snapshot.data;
                        final path = issue.meetingRequestDocumentPath.isNotEmpty
                            ? issue.meetingRequestDocumentPath
                            : request?.letterPath ?? '';
                        final name = issue.meetingRequestDocumentPath.isNotEmpty
                            ? (issue.meetingRequestDocumentName.isNotEmpty
                                  ? issue.meetingRequestDocumentName
                                  : pdfAttachmentName(path))
                            : request?.letterName ?? '';
                        if (path.isEmpty) {
                          return const Text(
                            '—',
                            style: TextStyle(fontSize: 12),
                          );
                        }
                        return PdfAttachmentPreview(
                          path: path,
                          name: name,
                          child: Row(
                            children: [
                              const Icon(
                                Icons.picture_as_pdf,
                                size: 18,
                                color: Color(0xFFFF4842),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  name.isNotEmpty
                                      ? name
                                      : pdfAttachmentName(path),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 11),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                CdcDetailDateChip(
                  label: l10n.text('submittedBy'),
                  value: rgcValue(issue.submittedByName),
                ),
                const SizedBox(width: 20),
                CdcDetailDateChip(
                  label: l10n.text('submittedDate'),
                  value: rgcDate(issue.submittedDate),
                ),
                const SizedBox(width: 20),
                for (var order = 1; order <= 5; order++) ...[
                  if (order > 1) const SizedBox(width: 20),
                  CdcDetailDateChip(
                    label: l10n.text(
                      [
                        'governmentAgency',
                        'governmentSecondAgency',
                        'governmentThirdAgency',
                        'governmentFourthAgency',
                        'governmentFifthAgency',
                      ][order - 1],
                    ),
                    value:
                        issue.governmentAgencies[order]?.trim().isNotEmpty ==
                            true
                        ? issue.governmentAgencies[order]!
                        : l10n.text('noData'),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 20),
          for (final section in sections) ...[
            Text(l10n.text(section.$1), style: const TextStyle(fontSize: 13)),
            const SizedBox(height: 10),
            Container(
              constraints: const BoxConstraints(minHeight: 52),
              padding: const EdgeInsets.all(11),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.fieldBorder),
              ),
              child: section.$1 == 'linkToVerificationSource'
                  ? SelectableText(
                      section.$2,
                      style: const TextStyle(
                        fontSize: 12,
                        decoration: TextDecoration.underline,
                      ),
                    )
                  : Text(
                      section.$2,
                      style: const TextStyle(fontSize: 12, height: 1.35),
                    ),
            ),
            const SizedBox(height: 16),
          ],
        ],
      ),
    );
  }
}
