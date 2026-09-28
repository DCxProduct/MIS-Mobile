import 'package:flutter/material.dart';
import 'detail_widgets.dart';

import '../../../core/app_colors.dart';
import '../../../core/widgets/pdf_attachment_preview.dart';
import '../../../translations/app_localizations.dart';
import '../../shared/issues/data/working_group_issue.dart';
import '../../shared/issues/widgets/issue_display.dart';
import 'progress_report_card.dart';

class CdcSectionIssueDetailScreen extends StatelessWidget {
  const CdcSectionIssueDetailScreen({
    super.key,
    required this.title,
    required this.category,
    this.issue,
    this.generalIssue = false,
  });

  final String title;
  final String category;
  final WorkingGroupIssue? issue;
  final bool generalIssue;

  static const _description =
      'The private sector said that the Economic Land Concession (ELCs), which invest in rubber, cashew, plantations, etc., are now fully developed and some are not yet fully developed due to some challenges that require resolutions. Most ELCs complain to the relevant authorities, especially about random inspections conducted by individual ministry/authority to their concession areas.';
  static const _recommendation =
      'The private sector requests relevant institutions to cooperate with the Ministry of Agriculture, Forestry and Fisheries to have a group or joint inspection.';
  static const _decision =
      'The Ministry of Agriculture, Forestry and Fisheries (MAFF) agreed to have joint inspections and not multiple inspections. Inspections are only conducted by the relevant institutions together to coordinate their work and avoid repeated visits.';

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final documentPath = generalIssue
        ? issue?.meetingRequestDocumentPath ?? ''
        : issue?.attachmentPath ?? '';
    final status = issue == null
        ? l10n.text(generalIssue ? 'complete' : 'inProgress')
        : issueStatusLabel(context, issue!);
    final statusColor = generalIssue && issue == null ? AppColors.accent(context) : switch (issue?.statusCode) {
      'SOLVED' => const Color(0xFF16A34A),
      'NOT_ADDRESSED' => const Color(0xFFEF4444),
      _ => const Color(0xFFFF8A00),
    };
    return Scaffold(
      backgroundColor: AppColors.pageBackground(context),
      appBar: AppBar(
        backgroundColor: AppColors.pageBackground(context),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          tooltip: MaterialLocalizations.of(context).backButtonTooltip,
          onPressed: () => Navigator.of(context).pop(),
          icon: Icon(
            Icons.arrow_back,
            size: 22,
            color: AppColors.primaryText(context),
          ),
        ),
        title: Text(
          l10n.text('issueDetails'),
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(height: 1, color: AppColors.border(context)),
        ),
      ),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          key: const ValueKey('cdc-issue-detail-scroll'),
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                generalIssue ? issue?.title ?? 'Climate Issue' : l10n.text('submitDetail'),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 3,
                    child: CdcDetailInfoValue(
                      label: '${l10n.text('governmentPrimaryAgency')}:',
                      value: issue == null ? 'MAFF' : issue!.agency,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 2,
                    child: CdcDetailInfoValue(
                      label: '${l10n.text('status')} :',
                      value: status,
                      color: statusColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.text(generalIssue ? 'meetingReferenceDocument' : 'issueDocument'),
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.mutedText,
                          ),
                        ),
                        const SizedBox(height: 8),
                        PdfAttachmentPreview(
                          path: documentPath,
                          child: Row(
                            children: [
                              const Icon(
                                Icons.picture_as_pdf,
                                size: 18,
                                color: Color(0xFFFF4842),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      issue == null
                                          ? 'Request Doc'
                                          : documentPath.isEmpty
                                          ? '—'
                                          : pdfAttachmentName(documentPath),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                    if (issue == null)
                                      const Text(
                                        '200 KB',
                                        style: TextStyle(
                                          fontSize: 7,
                                          color: AppColors.mutedText,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 2,
                    child: CdcDetailInfoValue(
                      label: l10n.text('issueCategory'),
                      value: category,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    CdcDetailDateChip(
                      label: l10n.text('meetingDate'),
                      value: issue == null
                          ? 'Jun 29 2025'
                          : issueDate(context, issue!.meetingDate),
                    ),
                    const SizedBox(width: 16),
                    CdcDetailDateChip(
                      label: l10n.text('submittedDate'),
                      value: issue == null
                          ? 'Jun 24 2025'
                          : issueDate(context, issue!.createdAt),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              CdcDetailTextPanel(
                label: l10n.text('issuesDescriptions'),
                body: issue?.description ?? _description,
                collapsedLines: 7,
              ),
              const SizedBox(height: 16),
              CdcDetailTextPanel(
                label: l10n.text('recommendations'),
                body: issue?.recommendation ?? (generalIssue
                    ? 'The private sector, through the Ministry of Agriculture, Forestry and Fisheries, has requested the Ministry of Water Resources and Meteorology to consider establishing meteorological stations in every province and city to provide farmers with accurate weather information.'
                    : _recommendation),
                collapsedLines: 3,
                inlineLink: !generalIssue,
              ),
              const SizedBox(height: 16),
              if (generalIssue)
                issue == null
                    ? const CdcIssueProgressReportCard()
                    : Text(l10n.text('noIssueProgressData'))
              else ...[
              CdcDetailTextPanel(
                label: l10n.text('rgcDecision'),
                body: issue == null ? _decision : '',
                collapsedLines: 3,
              ),
              for (final key in [
                'indicators',
                'progressSolution',
                'implementationChallenges',
                'request',
                'nextStep',
                'sourceOfVerification',
                'linkToVerificationSource',
              ]) ...[
                const SizedBox(height: 16),
                Text(l10n.text(key), style: const TextStyle(fontSize: 13)),
                const SizedBox(height: 10),
                Container(
                  key: ValueKey('cdc-detail-$key'),
                  width: double.infinity,
                  height: 52,
                  decoration: BoxDecoration(
                    color: AppColors.pageBackground(context),
                    borderRadius: BorderRadius.circular(7),
                    border: Border.all(
                      color: AppColors.fieldBorder.withValues(
                        alpha: AppColors.isDark(context) ? 0.15 : 1,
                      ),
                    ),
                  ),
                ),
              ],
              ],
            ],
          ),
        ),
      ),
    );
  }
}
