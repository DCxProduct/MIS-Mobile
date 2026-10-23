import 'package:flutter/material.dart';

import '../../../core/app_colors.dart';
import '../../../core/widgets/editor_content.dart';
import '../../../core/widgets/pdf_attachment_preview.dart';
import '../../../translations/app_localizations.dart';
import '../../shared/issues/widgets/issue_agency_logo.dart';
import '../../shared/issues/widgets/issue_display.dart';
import '../../shared/meetings/data/meeting_summary.dart';

class CdcSummaryIssueDetails extends StatelessWidget {
  const CdcSummaryIssueDetails({super.key, required this.issue});
  final MeetingSummaryIssue issue;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context, page: 'meeting_summary_issue');
    Widget text(String value) => Text(
      value.isEmpty ? '—' : value,
      style: const TextStyle(fontSize: 12, height: 1.5),
    );
    Widget field(String key, Widget value) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.text(key),
          style: const TextStyle(fontSize: 12, color: AppColors.mutedText),
        ),
        const SizedBox(height: 6),
        value,
      ],
    );
    Widget document(String? path, String? name) => path == null
        ? text('')
        : PdfAttachmentPreview(
            path: path,
            name: name,
            child: Row(
              children: [
                const Icon(Icons.picture_as_pdf, color: Colors.red, size: 18),
                const SizedBox(width: 5),
                Expanded(
                  child: Text(
                    pdfAttachmentName(path, name: name),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 11),
                  ),
                ),
              ],
            ),
          );
    Widget agency(int order) => Row(
      children: [
        if (issue.governmentAgencies.containsKey(order)) ...[
          IssueAgencyLogo(
            path: issue.agencyLogos[order] ?? '',
            size: 22,
            iconSize: 14,
          ),
          const SizedBox(width: 6),
        ],
        Expanded(child: text(issue.governmentAgencies[order] ?? '')),
      ],
    );
    final fields = [
      field('submittedBy', text(issue.submittedBy)),
      field(
        'submittedDate',
        text(issueDateWithYear(context, issue.submittedDate?.toLocal())),
      ),
      field(
        'issueDocument',
        document(issue.attachmentPath, issue.attachmentName),
      ),
      field('categories', text(issue.category)),
      field('governmentAgency', agency(1)),
      field(
        'status',
        Text(
          l10n.status(issue.status),
          style: TextStyle(
            fontSize: 12,
            color: switch (issue.status.toUpperCase()) {
              'IN_PROGRESS' => const Color(0xFFFF8A00),
              'SOLVED' => const Color(0xFF16A34A),
              _ => const Color(0xFFEF4444),
            },
          ),
        ),
      ),
      field('governmentSecondAgency', agency(2)),
      field('governmentThirdAgency', agency(3)),
      field('governmentFourthAgency', agency(4)),
      field('governmentFifthAgency', agency(5)),
      field('issueEscalation', text(issue.escalation)),
      field(
        'solutionReferenceDocument',
        document(issue.referencePath, issue.referenceName),
      ),
    ];
    final sections = <String, String>{
      'issuesDescriptions': issue.descriptionHtml,
      'recommendations': issue.recommendationHtml,
      'rgcDecision': issue.rgcDecisionHtml,
      'nextStep': issue.nextStepHtml,
      'remark': issue.remarkHtml,
    };
    return FractionallySizedBox(
      heightFactor: 0.9,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.cardBackground(context),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 8, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      l10n.text('issuesDetails'),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Text(
                    issue.title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 24),
                  LayoutBuilder(
                    builder: (context, constraints) => Wrap(
                      spacing: 16,
                      runSpacing: 20,
                      children: [
                        for (final item in fields)
                          SizedBox(
                            width: (constraints.maxWidth - 16) / 2,
                            child: item,
                          ),
                      ],
                    ),
                  ),
                  for (final section in sections.entries) ...[
                    const SizedBox(height: 20),
                    const Divider(),
                    const SizedBox(height: 12),
                    Text(
                      l10n.text(section.key),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 12),
                    EditorContent(
                      section.value.isEmpty ? '—' : section.value,
                      style: const TextStyle(fontSize: 13, height: 1.6),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
