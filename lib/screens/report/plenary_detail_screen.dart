import 'package:flutter/material.dart';

import '../../core/app_settings.dart';
import '../../core/app_colors.dart';
import '../../core/widgets/pdf_attachment_preview.dart';
import '../../core/text/html_text.dart';
import '../../features/shared/meetings/data/plenary.dart';
import '../../features/shared/meetings/data/rgc_decision.dart';

class PlenaryDetailScreen extends StatelessWidget {
  const PlenaryDetailScreen({
    super.key,
    this.id,
    required this.title,
    this.documentReference,
    this.plenary,
    this.approvalReports,
  });

  final int? id;
  final String title;
  final String? documentReference;
  final Plenary? plenary;
  final List<RgcDecisionDetail>? approvalReports;

  @override
  Widget build(BuildContext context) {
    if (id != null) return _ApiPlenaryDetailScreen(id: id!);

    final detailTitle = plenary?.name ?? title;
    final detailDocument = plenary?.documentReference ?? documentReference;
    final detailDeadline = plenary == null
        ? 'June 07, 2025'
        : _date(plenary!.deadline);
    final detailMeetingDate = plenary == null
        ? 'Ouk Sabda ( June 01, 2025 )'
        : _date(plenary!.meetingDate);
    final detailDecisionCount =
        plenary?.numberOfRgcDecisions.toString() ?? '179';
    final detailStatus = plenary == null ? '• Sent' : '• ${plenary!.status}';

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
          detailTitle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: AppColors.primaryText(context),
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(height: 1, color: AppColors.border(context)),
        ),
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _DetailBlock(label: 'Deadline', value: detailDeadline),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: _DetailBlock(
                    label: 'Meeting Date',
                    value: detailMeetingDate,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _DetailBlock(
                    label: 'Number of RGC Decision',
                    value: detailDecisionCount,
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: _DetailBlock(
                    label: 'Status :',
                    value: detailStatus,
                    valueColor: Color(0xFF1E73BE),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'Approval Report',
              style: TextStyle(
                color: AppColors.mutedText,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            PdfAttachmentPreview(
              path: detailDocument ?? '',
              name: detailDocument == null
                  ? null
                  : pdfAttachmentName(detailDocument),
              child: Row(
                children: [
                  const Icon(
                    Icons.picture_as_pdf,
                    color: Color(0xFFE53935),
                    size: 18,
                  ),
                  const SizedBox(width: 6),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        detailDocument == null
                            ? 'Request Doc'
                            : pdfAttachmentName(detailDocument),
                        style: TextStyle(
                          color: AppColors.primaryText(context),
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const Text(
                        'PDF',
                        style: TextStyle(
                          color: AppColors.mutedText,
                          fontSize: 7,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            ..._approvalCards(),
          ],
        ),
      ),
    );
  }

  List<Widget> _approvalCards() {
    final reports = approvalReports;
    if (reports == null) {
      return const [
        _PlenaryIssueItemCard(
          meetingDate: 'Jun 20, 2025',
          category: 'Procedure',
          focalPerson: 'Dith Tina',
          description:
              'The Ministry of Agriculture, Forestry and Fisheries (MAFF) agreed to have joint inspections and not multiple inspections. Inspections are only conducte...',
          status: 'Solved',
        ),
        SizedBox(height: 14),
        _PlenaryIssueItemCard(
          meetingDate: 'Jun 20, 2025',
          category: 'Procedure',
          focalPerson: 'Dith Tina',
          description:
              'The Ministry of Agriculture, Forestry and Fisheries (MAFF) agreed to have joint inspections and not multiple inspections. Inspections are only conducte...',
          status: 'Solved',
        ),
        SizedBox(height: 14),
        _PlenaryIssueItemCard(
          meetingDate: 'Jun 20, 2025',
          category: 'Procedure',
          focalPerson: 'Dith Tina',
          description:
              'The Ministry of Agriculture, Forestry and Fisheries (MAFF) agreed to have joint inspections and not multiple inspections. Inspections are only conducte...',
          status: 'Solved',
        ),
      ];
    }
    if (reports.isEmpty) return const [];
    final cards = <Widget>[];
    for (final report in reports) {
      final issues = report.issues.isEmpty
          ? <RgcDecisionIssue?>[null]
          : report.issues;
      for (final issue in issues) {
        if (cards.isNotEmpty) cards.add(const SizedBox(height: 14));
        cards.add(
          _PlenaryIssueItemCard(
            meetingDate: _date(report.decision.meetingDate),
            category: issue?.category.isNotEmpty == true
                ? issue!.category
                : report.decision.category,
            focalPerson: issue?.focalPerson.isNotEmpty == true
                ? issue!.focalPerson
                : report.decision.focalPerson,
            description: htmlToPlainText(
              issue?.description.isNotEmpty == true
                  ? issue!.description
                  : report.approvalReport,
            ),
            status: report.decision.status,
            report: report,
            issue: issue,
          ),
        );
      }
    }
    return cards;
  }

  static String _date(DateTime? date) {
    if (date == null) return '—';
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}

class _ApiPlenaryDetailScreen extends StatefulWidget {
  const _ApiPlenaryDetailScreen({required this.id});

  final int id;

  @override
  State<_ApiPlenaryDetailScreen> createState() =>
      _ApiPlenaryDetailScreenState();
}

class _ApiPlenaryDetailScreenState extends State<_ApiPlenaryDetailScreen> {
  Future<_PlenaryApiData>? _future;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _future ??= _load();
  }

  Future<_PlenaryApiData> _load() async {
    final settings = AppSettings.of(context);
    final results = await Future.wait<Object>([
      settings.plenaries.getPlenary(widget.id),
      settings.rgcDecisions.getDecisionsByPlenary(widget.id),
    ]);
    return _PlenaryApiData(
      results[0] as Plenary,
      results[1] as List<RgcDecisionDetail>,
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_PlenaryApiData>(
      future: _future,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Scaffold(
            backgroundColor: AppColors.pageBackground(context),
            appBar: AppBar(title: const Text('Plenary Details')),
            body: Center(
              child: snapshot.hasError
                  ? TextButton(
                      onPressed: () => setState(() {
                        _future = _load();
                      }),
                      child: const Text('Retry'),
                    )
                  : const CircularProgressIndicator(),
            ),
          );
        }
        final data = snapshot.data!;
        final plenary = data.plenary;
        return PlenaryDetailScreen(
          title: plenary.name,
          documentReference: plenary.documentReference,
          plenary: plenary,
          approvalReports: data.approvalReports,
        );
      },
    );
  }
}

class _PlenaryApiData {
  const _PlenaryApiData(this.plenary, this.approvalReports);

  final Plenary plenary;
  final List<RgcDecisionDetail> approvalReports;
}

class _DetailBlock extends StatelessWidget {
  const _DetailBlock({
    required this.label,
    required this.value,
    this.valueColor,
  });

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
        const SizedBox(height: 6),
        Text(
          value,
          style: TextStyle(
            color: valueColor ?? AppColors.primaryText(context),
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _PlenaryIssueItemCard extends StatelessWidget {
  const _PlenaryIssueItemCard({
    required this.meetingDate,
    required this.category,
    required this.focalPerson,
    required this.description,
    required this.status,
    this.report,
    this.issue,
  });

  final String meetingDate;
  final String category;
  final String focalPerson;
  final String description;
  final String status;
  final RgcDecisionDetail? report;
  final RgcDecisionIssue? issue;

  void _openRgcDecisionBottomSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return _RgcDecisionBottomSheet(
          status: status,
          report: report,
          issue: issue,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final statusColor = _statusColor(status);

    return InkWell(
      onTap: () => _openRgcDecisionBottomSheet(context),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isDark ? AppColors.darkBorder : const Color(0xFFE5E8ED),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: _MetaItem(
                    icon: Icons.calendar_month_outlined,
                    label: 'Meeting Date',
                    value: meetingDate,
                    color: const Color(0xFF1E73BE),
                  ),
                ),
                Expanded(
                  child: _MetaItem(
                    icon: Icons.grid_view_outlined,
                    label: 'Categories',
                    value: category,
                    color: const Color(0xFF7C3AED),
                  ),
                ),
                Expanded(
                  child: _MetaItem(
                    icon: Icons.person_outline,
                    label: 'Focal Person',
                    value: focalPerson,
                    color: const Color(0xFF059669),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              description,
              style: TextStyle(
                color: AppColors.secondaryText(context),
                fontSize: 12,
                height: 1.45,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              height: 38,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: statusColor, width: 1),
              ),
              child: Text(
                status,
                style: TextStyle(
                  color: statusColor,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Color _statusColor(String status) => switch (status.toLowerCase()) {
  'solved' => const Color(0xFF16A34A),
  'in progress' => const Color(0xFFFF8A00),
  'not addressed' => const Color(0xFFEF4444),
  _ => const Color(0xFF64748B),
};

class _RgcDecisionBottomSheet extends StatelessWidget {
  const _RgcDecisionBottomSheet({
    required this.status,
    this.report,
    this.issue,
  });

  final String status;
  final RgcDecisionDetail? report;
  final RgcDecisionIssue? issue;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final background = isDark ? AppColors.darkCard : Colors.white;
    final decision = report?.decision;
    final submittedBy = issue?.submittedBy.isNotEmpty == true
        ? issue!.submittedBy
        : decision?.agencyName ?? '—';
    final category = issue?.category.isNotEmpty == true
        ? issue!.category
        : decision?.category ?? '—';
    final focalPerson = issue?.focalPerson.isNotEmpty == true
        ? issue!.focalPerson
        : decision?.focalPerson ?? '—';
    final rgcDecision = issue?.rgcDecision.isNotEmpty == true
        ? issue!.rgcDecision
        : decision?.decisionText.isNotEmpty == true
        ? htmlToPlainText(decision!.decisionText)
        : '—';
    final verificationLink = decision?.verificationLink ?? '';

    return DraggableScrollableSheet(
      initialChildSize: 0.82,
      minChildSize: 0.5,
      maxChildSize: 0.92,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: background,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                child: Row(
                  children: [
                    InkWell(
                      onTap: () => Navigator.of(context).pop(),
                      child: Icon(
                        Icons.arrow_back,
                        color: Theme.of(context).colorScheme.onSurface,
                        size: 20,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        'RGC Decision',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 20),
                  ],
                ),
              ),
              const Divider(height: 1, color: Color(0xFFF0F2F5)),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: _FieldBlock(
                            label: 'Submitted by',
                            value: submittedBy,
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: _FieldBlock(
                            label: 'Status :',
                            value: '• $status',
                            valueColor: _statusColor(status),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: _FieldBlock(
                            label: 'Categories',
                            value: category,
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: _FieldBlock(
                            label: 'Focal Person (H.E) :',
                            value: focalPerson,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'RGC Decision',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.darkBackground
                            : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isDark
                              ? AppColors.darkBorder
                              : const Color(0xFFE2E8F0),
                        ),
                      ),
                      child: Text(
                        rgcDecision,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontSize: 12,
                          height: 1.5,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Link to Verification Source',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.darkBackground
                            : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isDark
                              ? AppColors.darkBorder
                              : const Color(0xFFE2E8F0),
                        ),
                      ),
                      child: SelectableText(
                        verificationLink.isEmpty ? '—' : verificationLink,
                        style: const TextStyle(
                          color: Color(0xFF1E73BE),
                          fontSize: 11,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _FieldBlock extends StatelessWidget {
  const _FieldBlock({
    required this.label,
    required this.value,
    this.valueColor,
  });

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
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: valueColor ?? Theme.of(context).colorScheme.onSurface,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _MetaItem extends StatelessWidget {
  const _MetaItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: color, size: 14),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.mutedText,
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 3),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: AppColors.primaryText(context),
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}
