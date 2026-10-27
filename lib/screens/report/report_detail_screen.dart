import '../../features/shared/issues/widgets/issue_display.dart';
import '../../core/widgets/editor_content.dart';
import 'package:flutter/material.dart';

import '../../core/app_colors.dart';
import '../../core/text/html_text.dart';
import '../../core/widgets/pdf_attachment_preview.dart';
import '../../features/shared/meetings/data/progress_report.dart';
import '../../features/shared/meetings/data/progress_reports_repository.dart';
import '../../translations/app_localizations.dart';
import 'report_item_detail_sheet.dart';

String _value(String? value) =>
    value == null || value.trim().isEmpty ? '—' : value;

String _named(Object? value) => value is Map
    ? '${value['name'] ?? value['code'] ?? ''}'
    : value is String
    ? value
    : '';

String _formatDate(BuildContext context, DateTime? date) =>
    issueDateWithYear(context, date?.toLocal());

String _meetingTime(BuildContext context, ProgressReport? report) {
  final meeting = report?.latestMeeting ?? const <String, dynamic>{};
  final rawDate = meeting['meetingDate'];
  final date = rawDate is String ? DateTime.tryParse(rawDate) : null;
  if (date == null) return '—';
  String clock(Object? raw) {
    if (raw is! String || raw.trim().isEmpty) return '';
    final iso = DateTime.tryParse(raw);
    final match = RegExp(r'^(\d{1,2}):(\d{2})').firstMatch(raw);
    final hour = iso?.hour ?? (match == null ? null : int.tryParse(match[1]!));
    final minute =
        iso?.minute ?? (match == null ? null : int.tryParse(match[2]!));
    if (hour == null || minute == null || hour > 23 || minute > 59) return '';
    return AppLocalizations.of(
      context,
    ).time(DateTime(2000, 1, 1, hour, minute));
  }

  final start = clock(meeting['startTime']);
  final end = clock(meeting['endTime']);
  return '${_formatDate(context, date)}${start.isEmpty ? '' : '\n$start${end.isEmpty ? '' : '–$end'}'}';
}

String _reportStatus(BuildContext context, String? raw) => AppLocalizations.of(
  context,
  page: 'progress_report',
).status(_value(raw).replaceFirst(RegExp(r'^CDC_'), ''));

class ReportDetailScreen extends StatefulWidget {
  const ReportDetailScreen({super.key, required this.title, this.report});

  final String title;
  final ProgressReport? report;

  @override
  State<ReportDetailScreen> createState() => _ReportDetailScreenState();
}

class _ReportDetailScreenState extends State<ReportDetailScreen> {
  int _selectedTab = 0;

  @override
  Widget build(BuildContext context) => TranslationPageScope(
    page: 'progress_report',
    child: Builder(builder: _buildContent),
  );

  Widget _buildContent(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pageBackground(context),
      appBar: AppBar(
        backgroundColor: AppColors.pageBackground(context),
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: AppColors.primaryText(context),
            size: 22,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          AppLocalizations.of(
            context,
            page: 'progress_report',
          ).text('progressReportDetails'),
          style: TextStyle(
            color: AppColors.primaryText(context),
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 17, 16, 28),
          children: [
            Text(
              widget.report?.ministry.isNotEmpty == true
                  ? widget.report!.ministryDisplayName
                  : widget.title,
              style: TextStyle(
                color: AppColors.primaryText(context),
                fontSize: 14,
                height: 1.22,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 14),
            _MaffInfoSection(title: widget.title, report: widget.report),
            const SizedBox(height: 9),
            _CdcInfoSection(report: widget.report),
            const SizedBox(height: 6),
            _ReportDetailTabs(
              selectedIndex: _selectedTab,
              onSelected: (index) => setState(() => _selectedTab = index),
            ),
            _buildTabContent(),
          ],
        ),
      ),
    );
  }

  Widget _buildTabContent() {
    return switch (_selectedTab) {
      0 => _DescriptionTab(description: widget.report?.description ?? ''),
      1 => _IssueListTab(
        items: widget.report?.openIssues ?? const [],
        requestDocument: widget.report?.requestDocument,
        requestDocumentName:
            widget.report?.documentNames[widget.report?.requestDocument],
      ),
      2 => _IssueListTab(
        items: widget.report?.rgcDecisions ?? const [],
        type: ProgressReportItemType.rgcDecision,
        requestDocument: widget.report?.requestDocument,
        requestDocumentName:
            widget.report?.documentNames[widget.report?.requestDocument],
      ),
      _ => _AttachmentTab(report: widget.report),
    };
  }
}

class _MaffInfoSection extends StatelessWidget {
  const _MaffInfoSection({required this.title, this.report});

  final String title;
  final ProgressReport? report;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context, page: 'progress_report');
    final ministry = report?.ministry.isNotEmpty == true
        ? report!.ministry
        : l10n.text('governmentAgency');
    final information = l10n.remoteText('information');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(
          title: information == null
              ? l10n.text('ministryInfo').replaceAll('{ministry}', ministry)
              : '$ministry $information',
        ),
        const SizedBox(height: 11),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _InfoBlock(
                label: l10n.text('submittedDate'),
                value: _formatDate(context, report?.submittedAt),
              ),
            ),
            const SizedBox(width: 18),
            Expanded(
              child: _PersonInfoBlock(
                label: AppLocalizations.of(
                  context,
                  page: 'progress_report',
                ).text('prepareBy'),
                name: _value(report?.preparedBy),
                date: report?.submittedAt == null
                    ? ''
                    : _formatDate(context, report?.submittedAt),
              ),
            ),
          ],
        ),
        const SizedBox(height: 13),
        _DocumentInfoBlock(
          label: AppLocalizations.of(
            context,
            page: 'progress_report',
          ).text('approvalReport'),
          path: report?.approvalDocument,
          name: report?.documentNames[report?.approvalDocument],
        ),
      ],
    );
  }
}

class _CdcInfoSection extends StatelessWidget {
  const _CdcInfoSection({this.report});

  final ProgressReport? report;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context, page: 'progress_report');
    final information = l10n.remoteText('information');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(
          title: information == null
              ? l10n.text('cdcInfo')
              : 'CDC $information',
        ),
        const SizedBox(height: 11),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _InfoBlock(
                label: l10n.text('status'),
                value: report?.cdcStatus.isNotEmpty == true
                    ? '• ${_reportStatus(context, report?.cdcStatus)}'
                    : '—',
                valueColor: switch (report?.cdcStatus.toUpperCase()) {
                  'COMPLETED' ||
                  'SOLVED' ||
                  'APPROVED' => const Color(0xFF16A34A),
                  'REJECTED' || 'NOT_ADDRESSED' => const Color(0xFFE53935),
                  _ => const Color(0xFFFF8A00),
                },
              ),
            ),
            const SizedBox(width: 18),
            Expanded(
              child: _PersonInfoBlock(
                label: AppLocalizations.of(
                  context,
                  page: 'progress_report',
                ).text('reviewBy'),
                name: _value(report?.reviewedBy),
                date: report?.reviewedAt == null
                    ? ''
                    : _formatDate(context, report?.reviewedAt),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _InfoBlock(
                label: AppLocalizations.of(
                  context,
                  page: 'progress_report',
                ).text('lastUpdate'),
                value: _formatDate(context, report?.updatedAt),
              ),
            ),
            SizedBox(width: 18),
            Expanded(
              child: _DocumentInfoBlock(
                label: AppLocalizations.of(
                  context,
                  page: 'progress_report',
                ).text('meetingRequestDocument'),
                path: report?.requestDocument,
                name: report?.documentNames[report?.requestDocument],
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _InfoBlock(
                label: AppLocalizations.of(
                  context,
                  page: 'progress_report',
                ).text('meetingDateTime'),
                value: _meetingTime(context, report),
              ),
            ),
            SizedBox(width: 18),
            Expanded(
              child: _PersonInfoBlock(
                label: AppLocalizations.of(
                  context,
                  page: 'progress_report',
                ).text('reviewBy'),
                name: _value(report?.reviewedBy),
                date: report?.reviewedAt == null
                    ? ''
                    : _formatDate(context, report?.reviewedAt),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            color: AppColors.primaryText(context),
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
        Divider(height: 1, color: AppColors.border(context)),
      ],
    );
  }
}

class _InfoBlock extends StatelessWidget {
  const _InfoBlock({required this.label, required this.value, this.valueColor});

  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppColors.mutedText,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 7),
        Text(
          value,
          style: TextStyle(
            color: valueColor ?? AppColors.primaryText(context),
            fontSize: 12,
            height: 1.35,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _PersonInfoBlock extends StatelessWidget {
  const _PersonInfoBlock({
    required this.label,
    required this.name,
    required this.date,
  });

  final String label;
  final String name;
  final String date;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppColors.mutedText,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 7),
        RichText(
          text: TextSpan(
            style: TextStyle(
              color: AppColors.primaryText(context),
              fontSize: 12,
              height: 1.35,
              fontWeight: FontWeight.w600,
            ),
            children: [
              TextSpan(text: name),
              if (date.isNotEmpty)
                TextSpan(
                  text: '  ( $date )',
                  style: const TextStyle(
                    color: AppColors.mutedText,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DocumentInfoBlock extends StatelessWidget {
  const _DocumentInfoBlock({required this.label, this.path, this.name});

  final String label;
  final String? path;
  final String? name;

  @override
  Widget build(BuildContext context) {
    if (path == null || path!.isEmpty) {
      return _InfoBlock(label: label, value: '—');
    }
    return PdfAttachmentPreview(
      path: path ?? '',
      name: path == null ? null : pdfAttachmentName(path!, name: name),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppColors.mutedText,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 7),
          Row(
            children: [
              Icon(Icons.picture_as_pdf, color: Color(0xFFE53935), size: 18),
              const SizedBox(width: 7),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      pdfAttachmentName(path!, name: name),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: AppColors.primaryText(context),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ReportDetailTabs extends StatelessWidget {
  const _ReportDetailTabs({
    required this.selectedIndex,
    required this.onSelected,
  });

  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context, page: 'progress_report');
    final labels = [
      l10n.text('descriptions'),
      l10n.text('allIssues'),
      l10n.api(
        'progress_report.shared.decisions.title',
        fallback: l10n.text('rgcDecision'),
      ),
      l10n.text('attachment'),
    ];

    return Container(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.border(context))),
      ),
      height: 44,
      child: SingleChildScrollView(
        key: const ValueKey('progress-detail-tabs'),
        scrollDirection: Axis.horizontal,
        child: Row(
          children: List.generate(labels.length, (index) {
            final selected = selectedIndex == index;
            return InkWell(
              onTap: () => onSelected(index),
              child: Container(
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: selected
                          ? AppColors.accent(context)
                          : Colors.transparent,
                      width: 2,
                    ),
                  ),
                ),
                child: Text(
                  labels[index],
                  style: TextStyle(
                    color: selected
                        ? AppColors.accent(context)
                        : AppColors.mutedText,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}

class _DescriptionTab extends StatelessWidget {
  const _DescriptionTab({required this.description});
  final String description;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: EditorContent(
        _value(description),
        style: TextStyle(
          color: AppColors.secondaryText(context),
          fontSize: 13,
          height: 1.62,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

class _IssueListTab extends StatelessWidget {
  const _IssueListTab({
    required this.items,
    this.type = ProgressReportItemType.issue,
    this.requestDocument,
    this.requestDocumentName,
  });
  final List<Map<String, dynamic>> items;
  final ProgressReportItemType type;
  final String? requestDocument;
  final String? requestDocumentName;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: Column(
        children: items.isEmpty
            ? [
                Text(
                  AppLocalizations.of(
                    context,
                    page: 'progress_report',
                  ).text('noIssuesFound'),
                ),
              ]
            : [
                for (final item in items)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: _ReportIssueCard(
                      item: item,
                      type: type,
                      requestDocument: requestDocument,
                      requestDocumentName: requestDocumentName,
                    ),
                  ),
              ],
      ),
    );
  }
}

class _ReportIssueCard extends StatelessWidget {
  const _ReportIssueCard({
    required this.item,
    required this.type,
    this.requestDocument,
    this.requestDocumentName,
  });
  final Map<String, dynamic> item;
  final ProgressReportItemType type;
  final String? requestDocument;
  final String? requestDocumentName;

  @override
  Widget build(BuildContext context) {
    final status = _named(item['status']);
    final solved = status.toUpperCase() == 'SOLVED';
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      key: ValueKey('report-${type.name}-${item['id']}'),
      onTap: () => showReportItemDetail(
        context,
        item: item,
        type: type,
        requestDocument: requestDocument,
        requestDocumentName: requestDocumentName,
      ),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(14, 13, 14, 13),
        decoration: BoxDecoration(
          color: AppColors.subtleBackground(context),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    _value(
                      htmlToPlainText(
                        '${item['title'] ?? item['decision'] ?? ''}',
                      ),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: AppColors.primaryText(context),
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                _SmallStatusBadge(
                  label: AppLocalizations.of(
                    context,
                    page: 'progress_report',
                  ).status(_value(status)),
                  color: solved
                      ? (isDark
                            ? const Color(0xFF86EFAC)
                            : const Color(0xFF16A34A))
                      : (isDark
                            ? const Color(0xFFD1D5DB)
                            : const Color(0xFF4B5563)),
                  background: solved
                      ? (isDark
                            ? const Color(0xFF123B2A)
                            : const Color(0xFFF0FDF4))
                      : AppColors.cardBackground(context),
                  border: solved
                      ? (isDark
                            ? const Color(0xFF166534)
                            : const Color(0xFF86EFAC))
                      : (isDark
                            ? const Color(0xFF4B5563)
                            : const Color(0xFFE5E7EB)),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              _value(
                AppLocalizations.of(context).category(_named(item['category'])),
              ),
              style: TextStyle(
                color: Color(0xFF7C3AED),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              _value(
                htmlToPlainText(
                  '${item['description'] ?? item['recommendation'] ?? ''}',
                ),
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: AppColors.secondaryText(context),
                fontSize: 12,
                height: 1.45,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SmallStatusBadge extends StatelessWidget {
  const _SmallStatusBadge({
    required this.label,
    required this.color,
    required this.background,
    required this.border,
  });

  final String label;
  final Color color;
  final Color background;
  final Color border;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: border),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

class _AttachmentTab extends StatelessWidget {
  const _AttachmentTab({this.report});

  final ProgressReport? report;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Column(
        children: report?.attachmentPaths?.isNotEmpty == true
            ? [
                for (final path in report!.attachmentPaths!)
                  _AttachmentCard(
                    title: pdfAttachmentName(
                      path,
                      name: report!.documentNames[path],
                    ),
                    path: path,
                  ),
              ]
            : [
                Text(
                  AppLocalizations.of(
                    context,
                    page: 'progress_report',
                  ).text('noData'),
                ),
              ],
      ),
    );
  }
}

class _AttachmentCard extends StatelessWidget {
  const _AttachmentCard({required this.title, this.path});

  final String title;
  final String? path;

  @override
  Widget build(BuildContext context) {
    return PdfAttachmentPreview(
      path: path ?? '',
      name: title,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.cardBackground(context),
          borderRadius: BorderRadius.circular(9),
          border: Border.all(color: AppColors.border(context)),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.picture_as_pdf,
              color: Color(0xFFE53935),
              size: 18,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  color: AppColors.primaryText(context),
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const Text(
              'PDF',
              style: TextStyle(
                color: AppColors.mutedText,
                fontSize: 9,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
