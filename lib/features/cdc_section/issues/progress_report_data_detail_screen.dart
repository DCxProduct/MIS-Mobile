import 'package:flutter/material.dart';

import '../../../core/app_colors.dart';
import '../../../core/widgets/pdf_attachment_preview.dart';
import '../../../translations/app_localizations.dart';
import '../../shared/issues/data/issue_progress_report.dart';
import '../../shared/issues/widgets/issue_display.dart';
import 'detail_widgets.dart';

/// The report detail shown after opening a report from an issue.
class CdcIssueProgressReportDataDetailScreen extends StatelessWidget {
  const CdcIssueProgressReportDataDetailScreen({
    super.key,
    required this.report,
    required this.issueTitle,
    this.issueStatus = '',
    this.meetingDocumentPath = '',
    this.meetingDocumentName = '',
  });

  final IssueProgressReport report;
  final String issueTitle;
  final String issueStatus;
  final String meetingDocumentPath;
  final String meetingDocumentName;

  String _fileSize(int bytes) => bytes >= 1024 * 1024
      ? '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB'
      : '${(bytes / 1024).round()} KB';

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final hasMeetingDocument = meetingDocumentPath.isNotEmpty;
    final documentPath = hasMeetingDocument
        ? meetingDocumentPath
        : report.attachmentPaths.isNotEmpty
        ? report.attachmentPaths.first
        : '';
    final documentName = hasMeetingDocument
        ? meetingDocumentName
        : report.attachmentName;

    Widget section(String labelKey, String text, int lines) => Padding(
      padding: const EdgeInsets.only(top: 18),
      child: CdcDetailTextPanel(
        key: ValueKey('progress-$labelKey'),
        label: l10n.text(labelKey),
        body: text,
        collapsedLines: lines,
        inlineLink: true,
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
          tooltip: MaterialLocalizations.of(context).backButtonTooltip,
          onPressed: () => Navigator.of(context).pop(),
          icon: Icon(Icons.arrow_back, color: AppColors.primaryText(context)),
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
        child: ListView(
          key: const ValueKey('cdc-progress-report-data-scroll'),
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
          children: [
            Text(
              issueTitle,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 3,
                  child: CdcDetailInfoValue(
                    label: l10n.text('implementationDate'),
                    value: issueDateWithTime(
                      context,
                      report.implementationDate,
                    ),
                  ),
                ),
                if (issueStatus.isNotEmpty) ...[
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 2,
                    child: CdcDetailInfoValue(
                      label: '${l10n.text('status')}:',
                      value: issueStatus,
                      color: AppColors.accent(context),
                    ),
                  ),
                ],
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
                        l10n.text(
                          hasMeetingDocument
                              ? 'meetingReferenceDocument'
                              : 'attachmentsLabel',
                        ),
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.mutedText,
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (documentPath.isNotEmpty)
                        PdfAttachmentPreview(
                          path: documentPath,
                          name: documentName,
                          child: Row(
                            children: [
                              const Icon(
                                Icons.picture_as_pdf,
                                color: Color(0xFFFF4842),
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      documentName.isNotEmpty
                                          ? documentName
                                          : pdfAttachmentName(documentPath),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                    if (!hasMeetingDocument &&
                                        report.attachmentSize != null)
                                      Text(
                                        _fileSize(report.attachmentSize!),
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
                        )
                      else
                        const Text('—', style: TextStyle(fontSize: 13)),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 2,
                  child: _ExpandableReferenceName(
                    label: l10n.text('referenceName'),
                    value: report.referenceName,
                  ),
                ),
              ],
            ),
            if (report.description.isNotEmpty) ...[
              const SizedBox(height: 18),
              _ExpandableProgressText(text: report.description),
            ],
            if (report.indicators.isNotEmpty)
              section('indicators', report.indicators, 3),
            if (report.implementationChallenges.isNotEmpty)
              section(
                'implementationChallenges',
                report.implementationChallenges,
                3,
              ),
            if (report.requests.isNotEmpty)
              section('request', report.requests, 3),
            if (report.nextStep.isNotEmpty)
              section('nextStep', report.nextStep, 3),
            if (report.rgcDecision.isNotEmpty)
              section('rgcDecision', report.rgcDecision, 3),
            for (final path in report.attachmentPaths)
              if (path != documentPath) ...[
                const SizedBox(height: 12),
                PdfAttachmentPreview(
                  path: path,
                  child: ListTile(
                    leading: const Icon(
                      Icons.picture_as_pdf,
                      color: Color(0xFFFF4842),
                    ),
                    title: Text(
                      pdfAttachmentName(path),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ],
          ],
        ),
      ),
    );
  }
}

class _ExpandableReferenceName extends StatefulWidget {
  const _ExpandableReferenceName({required this.label, required this.value});

  final String label;
  final String value;

  @override
  State<_ExpandableReferenceName> createState() =>
      _ExpandableReferenceNameState();
}

class _ExpandableReferenceNameState extends State<_ExpandableReferenceName> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        widget.label,
        style: const TextStyle(fontSize: 12, color: AppColors.mutedText),
      ),
      const SizedBox(height: 8),
      GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.value.isEmpty
            ? null
            : () => setState(() => _expanded = !_expanded),
        child: Text(
          widget.value.isEmpty ? 'â€”' : widget.value,
          key: const ValueKey('progress-reference-name'),
          maxLines: _expanded ? null : 2,
          overflow: _expanded ? TextOverflow.visible : TextOverflow.ellipsis,
          style: TextStyle(fontSize: 13, color: AppColors.primaryText(context)),
        ),
      ),
    ],
  );
}

class _ExpandableProgressText extends StatefulWidget {
  const _ExpandableProgressText({required this.text});

  final String text;

  @override
  State<_ExpandableProgressText> createState() =>
      _ExpandableProgressTextState();
}

class _ExpandableProgressTextState extends State<_ExpandableProgressText> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final style = TextStyle(
      fontSize: 13,
      height: 1.35,
      color: AppColors.primaryText(context),
    );
    return LayoutBuilder(
      builder: (context, constraints) {
        final painter = TextPainter(
          text: TextSpan(text: widget.text, style: style),
          textDirection: Directionality.of(context),
          textScaler: MediaQuery.textScalerOf(context),
          maxLines: 10,
        )..layout(maxWidth: constraints.maxWidth);
        final canExpand = painter.didExceedMaxLines;
        painter.dispose();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              widget.text,
              maxLines: _expanded ? null : 10,
              overflow: _expanded ? TextOverflow.visible : TextOverflow.fade,
              style: style,
            ),
            if (canExpand) ...[
              const SizedBox(height: 2),
              Center(
                child: TextButton.icon(
                  onPressed: () => setState(() => _expanded = !_expanded),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.accent(context),
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    visualDensity: VisualDensity.compact,
                  ),
                  label: Text(
                    l10n.text(_expanded ? 'showLess' : 'viewDetails'),
                  ),
                  icon: Icon(
                    _expanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    size: 18,
                  ),
                  iconAlignment: IconAlignment.end,
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}
