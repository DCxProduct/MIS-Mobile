import 'package:gpsf_app/core/widgets/pdf_icon.dart';
import 'package:gpsf_app/core/status_colors.dart';

import 'package:flutter/material.dart';

import '../../../core/app_colors.dart';
import '../../../core/text/html_text.dart';
import '../../../core/widgets/editor_content.dart';
import '../../../core/widgets/pdf_attachment_preview.dart';
import '../../../translations/app_localizations.dart';
import '../../cdc_section/issues/detail_widgets.dart';
import '../../shared/issues/data/issue_progress_report.dart';
import '../../shared/issues/data/working_group_issue.dart';
import '../../shared/issues/widgets/issue_display.dart';

class IssueProgressReportDetailScreen extends StatelessWidget {
  const IssueProgressReportDetailScreen({
    super.key,
    required this.title,
    required this.report,
    this.issue,
    this.issueStatus = '',
    this.meetingDocumentPath = '',
    this.meetingDocumentName = '',
  });

  final String title;
  final WorkingGroupIssue? issue;
  final IssueProgressReport report;
  final String issueStatus;
  final String meetingDocumentPath;
  final String meetingDocumentName;

  @override
  Widget build(BuildContext context) => TranslationPageScope(
    page: 'issue_report',
    child: Builder(builder: _buildContent),
  );

  Widget _buildContent(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final documentPath = report.attachmentPath;
    final documentName = report.attachmentName;
    final statusColor = StatusColors.workflow(context, issueStatus);
    String displayValue(String value) =>
        htmlToPlainText(value).trim().isEmpty ? l10n.text('noData') : value;
    String reportValue(String key, String value) =>
        displayValue(report.localizedText(key, l10n.language, fallback: value));
    Widget section(String key, String value, {String? labelKey}) => Padding(
      padding: const EdgeInsets.only(top: 18),
      child: CdcDetailTextPanel(
        key: ValueKey('report-$key'),
        label: l10n.text(labelKey ?? key),
        body: reportValue(key, value),
        collapsedLines: 3,
        inlineLink: true,
      ),
    );
    Widget document(
      String path,
      String? name, {
      bool showSize = false,
    }) => PdfAttachmentPreview(
      path: path,
      name: pdfAttachmentName(path, name: name),
      child: Row(
        children: [
          const PdfIcon(size: 19),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  pdfAttachmentName(path, name: name),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 11),
                ),
                if (showSize && report.attachmentSize != null)
                  Text(
                    report.attachmentSize! >= 1024 * 1024
                        ? '${AppLocalizations.of(context).number(report.attachmentSize! / (1024 * 1024), decimalPlaces: 1)} MB'
                        : '${AppLocalizations.of(context).number((report.attachmentSize! / 1024).round())} KB',
                    style: const TextStyle(
                      fontSize: 9,
                      color: AppColors.mutedText,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
    return Scaffold(
      backgroundColor: AppColors.pageBackground(context),
      appBar: AppBar(
        backgroundColor: AppColors.pageBackground(context),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          tooltip: MaterialLocalizations.of(context).backButtonTooltip,
          icon: const Icon(Icons.arrow_back, size: 22),
        ),
        title: Text(
          report.title.isEmpty
              ? l10n.text('progressReportDetails')
              : issueProgressReportTitle(context, report),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(
            height: 1,
            color: AppColors.border(context).withValues(alpha: 0.5),
          ),
        ),
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          key: const ValueKey('private-issue-report-scroll'),
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
          children: [
            Text(
              issue?.localizedText('title', l10n.language) ?? title,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 3,
                  child: _InfoBlock(
                    showBorder: false,
                    label: l10n.text('implementationDate'),
                    child: Text(
                      report.implementationDate == null
                          ? l10n.text('noData')
                          : issueDate(context, report.implementationDate),
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 2,
                  child: _InfoBlock(
                    showBorder: false,
                    label: '${l10n.text('status')} :',
                    child: Text(
                      issueStatus.isEmpty
                          ? l10n.text('noData')
                          : l10n.status(issueStatus),
                      style: TextStyle(fontSize: 12, color: statusColor),
                    ),
                  ),
                ),
              ],
            ),
            section('referenceName', report.referenceName),
            const SizedBox(height: 18),
            _InfoBlock(
              key: const ValueKey('report-referenceLink'),
              label: l10n.text('linkToVerificationSource'),
              child: documentPath.isNotEmpty
                  ? document(documentPath, documentName, showSize: true)
                  : Row(
                      children: [
                        const PdfIcon(size: 24),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            l10n.text('noData'),
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                      ],
                    ),
            ),
            const SizedBox(height: 20),
            _InfoBlock(
              key: const ValueKey('report-progressSolution'),
              label: l10n.text('progressSolution'),
              child: _ReportDescription(
                text: reportValue('description', report.description),
              ),
            ),
            section(
              'indicators',
              report.indicators,
              labelKey: 'solutionIndicators',
            ),
            section(
              'implementationChallenges',
              report.implementationChallenges,
              labelKey: 'challenges',
            ),
            section('requests', report.requests),
            section('rgcDecision', report.rgcDecision),
            if (report
                .localizedText(
                  'nextStep',
                  l10n.language,
                  fallback: report.nextStep,
                )
                .isNotEmpty)
              section('nextStep', report.nextStep),
            for (final path in report.attachmentPaths)
              if (path != documentPath)
                Padding(
                  padding: const EdgeInsets.only(top: 18),
                  child: document(
                    path,
                    report.attachmentNames[path],
                    showSize: report.attachmentPaths.length == 1,
                  ),
                ),
          ],
        ),
      ),
    );
  }
}

class _InfoBlock extends StatelessWidget {
  const _InfoBlock({
    super.key,
    required this.label,
    required this.child,
    this.showBorder = true,
  });
  final String label;
  final Widget child;
  final bool showBorder;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: const TextStyle(fontSize: 12, color: AppColors.mutedText),
      ),
      const SizedBox(height: 7),
      Container(
        width: double.infinity,
        constraints: const BoxConstraints(minHeight: 52),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          border: showBorder
              ? Border.all(color: AppColors.border(context))
              : null,
          borderRadius: BorderRadius.circular(7),
        ),
        child: child,
      ),
    ],
  );
}

class _ReportDescription extends StatefulWidget {
  const _ReportDescription({required this.text});
  final String text;

  @override
  State<_ReportDescription> createState() => _ReportDescriptionState();
}

class _ReportDescriptionState extends State<_ReportDescription> {
  bool _expanded = false;
  bool _canExpand = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Stack(
          children: [
            EditorContent(
              widget.text,
              key: const ValueKey('report-description'),
              maxLines: _expanded ? null : 12,
              onOverflowChanged: (value) {
                if (mounted && value != _canExpand) {
                  setState(() => _canExpand = value);
                }
              },
              style: TextStyle(
                fontSize: 13,
                height: 1.5,
                color: AppColors.primaryText(context),
              ),
            ),
            if (_canExpand && !_expanded)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                height: 80,
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          AppColors.pageBackground(
                            context,
                          ).withValues(alpha: 0),
                          AppColors.pageBackground(context),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
        if (_canExpand)
          Center(
            child: TextButton.icon(
              key: const ValueKey('report-description-toggle'),
              onPressed: () => setState(() => _expanded = !_expanded),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.accent(context),
                padding: const EdgeInsets.symmetric(horizontal: 8),
                minimumSize: const Size(0, 28),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                textStyle: const TextStyle(fontSize: 12),
              ),
              label: Text(l10n.text(_expanded ? 'showLess' : 'viewDetails')),
              icon: Icon(
                _expanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                size: 18,
              ),
              iconAlignment: IconAlignment.end,
            ),
          ),
      ],
    );
  }
}
