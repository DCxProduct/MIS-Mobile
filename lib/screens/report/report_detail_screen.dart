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

String _formatDate(DateTime? date) {
  if (date == null) return '—';
  final local = date.toLocal();
  return '${local.day}/${local.month}/${local.year}';
}

String _meetingTime(ProgressReport? report) {
  final meeting = report?.latestMeeting ?? const <String, dynamic>{};
  final rawDate = meeting['meetingDate'];
  final date = rawDate is String ? DateTime.tryParse(rawDate) : null;
  if (date == null) return '—';
  final time = meeting['startTime'];
  return '${_formatDate(date)}${time is String && time.isNotEmpty ? '\n$time' : ''}';
}

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
  Widget build(BuildContext context) {
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
          'Progress Report Details',
          style: TextStyle(
            color: AppColors.primaryText(context),
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.more_horiz,
              color: AppColors.primaryText(context),
              size: 22,
            ),
            onPressed: () {},
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 17, 16, 28),
          children: [
            Text(
              widget.report?.ministry.isNotEmpty == true
                  ? widget.report!.ministry
                  : widget.title,
              style: TextStyle(
                color: AppColors.primaryText(context),
                fontSize: 20,
                height: 1.22,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 14),
            if (widget.report != null) ...[
              Row(
                children: [
                  Expanded(
                    child: _InfoBlock(
                      label: 'Year',
                      value: widget.report!.year == 0
                          ? '—'
                          : '${widget.report!.year}',
                    ),
                  ),
                  Expanded(
                    child: _InfoBlock(
                      label: 'Semester',
                      value: _value(widget.report!.semester),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
            ],
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
      ),
      2 => _IssueListTab(
        items: widget.report?.rgcDecisions ?? const [],
        type: ProgressReportItemType.rgcDecision,
        requestDocument: widget.report?.requestDocument,
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
    final l10n = AppLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(
          title:
              '${report?.ministry.isNotEmpty == true ? report!.ministry : 'Ministry'} Info',
        ),
        const SizedBox(height: 11),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _InfoBlock(
                label: l10n.text('submittedDate'),
                value: _formatDate(report?.submittedAt),
              ),
            ),
            const SizedBox(width: 18),
            Expanded(
              child: _PersonInfoBlock(
                label: 'Prepare by',
                name: _value(report?.preparedBy),
                date: '',
              ),
            ),
          ],
        ),
        const SizedBox(height: 13),
        _DocumentInfoBlock(
          label: 'Approval Report',
          path: report?.approvalDocument,
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
    final l10n = AppLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHeader(title: 'CDC Info'),
        const SizedBox(height: 11),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _InfoBlock(
                label: l10n.text('status'),
                value: _value(report?.cdcStatus),
                valueColor: const Color(0xFFFF8A00),
              ),
            ),
            const SizedBox(width: 18),
            Expanded(
              child: _PersonInfoBlock(
                label: 'Review by',
                name: _value(report?.reviewedBy),
                date: '',
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
                label: 'Last Update',
                value: _formatDate(report?.updatedAt),
              ),
            ),
            SizedBox(width: 18),
            Expanded(
              child: _DocumentInfoBlock(
                label: 'Meeting Request Document:',
                path: report?.requestDocument,
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
                label: 'Meeting Date & Time',
                value: _meetingTime(report),
              ),
            ),
            SizedBox(width: 18),
            Expanded(
              child: _PersonInfoBlock(
                label: 'Review by',
                name: _value(report?.reviewedBy),
                date: '',
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
                    fontSize: 9,
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
  const _DocumentInfoBlock({required this.label, this.path});

  final String label;
  final String? path;

  @override
  Widget build(BuildContext context) {
    if (path == null || path!.isEmpty) {
      return _InfoBlock(label: label, value: '—');
    }
    return PdfAttachmentPreview(
      path: path ?? '',
      name: path == null ? null : pdfAttachmentName(path!),
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
                      pdfAttachmentName(path!),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: AppColors.primaryText(context),
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
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
    final l10n = AppLocalizations.of(context);
    final labels = [
      l10n.text('descriptions'),
      l10n.text('allIssues'),
      l10n.text('rgcDecision'),
      l10n.text('attachment'),
    ];

    return SizedBox(
      height: 40,
      child: Row(
        children: List.generate(labels.length, (index) {
          final selected = selectedIndex == index;
          return Expanded(
            child: InkWell(
              onTap: () => onSelected(index),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    labels[index],
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: selected
                          ? AppColors.accent(context)
                          : AppColors.mutedText,
                      fontSize: 12,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 9),
                  Container(
                    height: 2,
                    color: selected
                        ? AppColors.accent(context)
                        : Colors.transparent,
                  ),
                ],
              ),
            ),
          );
        }),
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
      child: Text(
        _value(htmlToPlainText(description)),
        style: TextStyle(
          color: AppColors.secondaryText(context),
          fontSize: 12,
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
  });
  final List<Map<String, dynamic>> items;
  final ProgressReportItemType type;
  final String? requestDocument;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: Column(
        children: items.isEmpty
            ? [Text(AppLocalizations.of(context).text('noIssuesFound'))]
            : [
                for (final item in items)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: _ReportIssueCard(
                      item: item,
                      type: type,
                      requestDocument: requestDocument,
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
  });
  final Map<String, dynamic> item;
  final ProgressReportItemType type;
  final String? requestDocument;

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
                    style: TextStyle(
                      color: AppColors.primaryText(context),
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                _SmallStatusBadge(
                  label: _value(status),
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
              _value(_named(item['category'])),
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
                  _AttachmentCard(title: pdfAttachmentName(path), path: path),
              ]
            : [Text(AppLocalizations.of(context).text('noData'))],
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
