import 'package:flutter/material.dart';

import '../../../../core/app_colors.dart';
import '../../../../core/app_settings.dart';
import '../../../../core/widgets/pdf_attachment_preview.dart';
import '../../shared/meetings/data/meeting_summary.dart';
import '../../../../translations/app_localizations.dart';

class MeetingSummaryDetailScreen extends StatefulWidget {
  const MeetingSummaryDetailScreen({super.key, this.id, this.summary});

  final int? id;
  final MeetingSummary? summary;

  @override
  State<MeetingSummaryDetailScreen> createState() =>
      _MeetingSummaryDetailScreenState();
}

class _MeetingSummaryDetailScreenState
    extends State<MeetingSummaryDetailScreen> {
  Future<MeetingSummary>? _future;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _future ??= widget.summary != null
        ? Future.value(widget.summary!)
        : AppSettings.of(context).meetingSummaries.getSummary(widget.id!);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<MeetingSummary>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return Scaffold(
            appBar: AppBar(title: const Text('Meeting Summary Details')),
            body: const Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasError || snapshot.data == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Meeting Summary Details')),
            body: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    AppLocalizations.of(
                      context,
                    ).text('meetingSummariesLoadError'),
                  ),
                  TextButton(
                    onPressed: () => setState(() {
                      _future = AppSettings.of(
                        context,
                      ).meetingSummaries.getSummary(widget.id!);
                    }),
                    child: Text(AppLocalizations.of(context).text('retry')),
                  ),
                ],
              ),
            ),
          );
        }
        return _buildContent(context, snapshot.data!);
      },
    );
  }

  Widget _buildContent(BuildContext context, MeetingSummary summary) {
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
          'Meeting Summary Details',
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
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(height: 1, color: AppColors.border(context)),
        ),
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 16, 14, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    summary.detailTitle.isEmpty ? '—' : summary.detailTitle,
                    style: TextStyle(
                      color: AppColors.primaryText(context),
                      fontSize: 15,
                      height: 1.45,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 14),
                  _SummaryInfoGrid(summary: summary),
                  const SizedBox(height: 16),
                  const _AllIssuesTabHeader(),
                ],
              ),
            ),
            Expanded(
              child: summary.issues.isEmpty
                  ? Center(
                      child: Text(
                        AppLocalizations.of(context).text('noIssuesFound'),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(14, 14, 14, 28),
                      itemCount: summary.issues.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 14),
                      itemBuilder: (context, index) => _ClimateIssueCard(
                        issue: summary.issues[index],
                        onTap: () =>
                            _showIssueDetails(context, summary.issues[index]),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  void _showIssueDetails(BuildContext context, MeetingSummaryIssue? issue) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      isDismissible: true,
      enableDrag: true,
      barrierColor: Colors.black54,
      backgroundColor: Colors.transparent,
      builder: (context) => _IssueDetailsSheet(issue: issue),
    );
  }
}

class _SummaryInfoGrid extends StatelessWidget {
  const _SummaryInfoGrid({required this.summary});

  final MeetingSummary summary;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _InfoBlock(
                label: 'Meeting Time',
                value: summary.detailDate == null
                    ? '—'
                    : MaterialLocalizations.of(context).formatTimeOfDay(
                        TimeOfDay.fromDateTime(summary.detailDate!.toLocal()),
                      ),
              ),
            ),
            SizedBox(width: 24),
            Expanded(
              child: _InfoBlock(
                label: 'Schedule Meeting :',
                value: summary.detailDate == null
                    ? '—'
                    : MaterialLocalizations.of(
                        context,
                      ).formatMediumDate(summary.detailDate!.toLocal()),
              ),
            ),
          ],
        ),
        SizedBox(height: 17),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _InfoBlock(
                label: 'Location',
                value: summary.location.isEmpty ? '—' : summary.location,
              ),
            ),
            SizedBox(width: 24),
            Expanded(
              child: _DocumentBlock(
                label: 'Meeting Request Document:',
                path:
                    summary.requestDocumentPath ?? summary.meetingDocumentPath,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _InfoBlock extends StatelessWidget {
  const _InfoBlock({required this.label, required this.value});

  final String label;
  final String value;

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
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: AppColors.primaryText(context),
            fontSize: 12,
            height: 1.35,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _DocumentBlock extends StatelessWidget {
  const _DocumentBlock({required this.label, this.path});

  final String label;
  final String? path;

  @override
  Widget build(BuildContext context) {
    return PdfAttachmentPreview(
      path: path ?? '',
      name: path == null ? null : pdfAttachmentName(path!),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.mutedText,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 7),
          Row(
            children: [
              const Icon(
                Icons.picture_as_pdf,
                color: Color(0xFFE53935),
                size: 18,
              ),
              const SizedBox(width: 7),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Request Doc',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: AppColors.primaryText(context),
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 1),
                    const Text(
                      '200 KB',
                      style: TextStyle(
                        color: AppColors.mutedText,
                        fontSize: 7,
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

class _AllIssuesTabHeader extends StatelessWidget {
  const _AllIssuesTabHeader();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 40,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Text(
              'All Issues',
              style: TextStyle(
                color: AppColors.primary,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          SizedBox(height: 9),
          Divider(height: 2, thickness: 2, color: AppColors.primary),
        ],
      ),
    );
  }
}

class _ClimateIssueCard extends StatelessWidget {
  const _ClimateIssueCard({required this.onTap, this.issue});

  final VoidCallback onTap;
  final MeetingSummaryIssue? issue;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 13, 14, 13),
        decoration: BoxDecoration(
          color: AppColors.subtleBackground(context),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    issue?.title.isNotEmpty == true ? issue!.title : '—',
                    style: TextStyle(
                      color: AppColors.primaryText(context),
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.cardBackground(context),
                    borderRadius: BorderRadius.circular(5),
                    border: Border.all(color: AppColors.border(context)),
                  ),
                  child: Text(
                    issue?.status.isNotEmpty == true ? issue!.status : '—',
                    style: TextStyle(
                      color: AppColors.secondaryText(context),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              issue?.category.isNotEmpty == true ? issue!.category : '—',
              style: TextStyle(
                color: Color(0xFF7C3AED),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              issue?.description.isNotEmpty == true ? issue!.description : '',
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

class _IssueDetailsSheet extends StatelessWidget {
  const _IssueDetailsSheet({this.issue});

  final MeetingSummaryIssue? issue;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => Navigator.of(context).pop(),
      child: Align(
        alignment: Alignment.bottomCenter,
        child: GestureDetector(
          onTap: () {},
          child: FractionallySizedBox(
            heightFactor: 0.76,
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.cardBackground(context),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
              ),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
                children: [
                  Center(
                    child: Container(
                      width: 38,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.border(context),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Center(
                    child: Text(
                      'Issues Details',
                      style: TextStyle(
                        color: AppColors.primaryText(context),
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    issue?.title.isNotEmpty == true
                        ? issue!.title
                        : '—',
                    style: TextStyle(
                      color: AppColors.primaryText(context),
                      fontSize: 15,
                      height: 1.45,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 18),
                  _IssueSheetInfoGrid(issue: issue),
                  const SizedBox(height: 14),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _DatePill(
                          label: 'Submitted By',
                          name: issue?.agency.isNotEmpty == true
                              ? issue!.agency
                              : '—',
                        ),
                        SizedBox(width: 10),
                        _DatePill(label: 'Submitted Date', name: 'Jun 24 2025'),
                        SizedBox(width: 10),
                        _DatePill(label: 'Government Agency', name: 'MAFF'),
                        SizedBox(width: 10),
                        _DatePill(
                          label: "Gov't Second Agency",
                          name: 'Not Data',
                        ),
                        SizedBox(width: 10),
                        _DatePill(
                          label: "Gov't Third Agency",
                          name: 'Not Data',
                        ),
                        SizedBox(width: 10),
                        _DatePill(
                          label: "Gov't Fourth Agency",
                          name: 'Not Data',
                        ),
                        SizedBox(width: 10),
                        _DatePill(
                          label: "Gov't Fifth Agency",
                          name: 'Not Data',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  _ReadMorePanel(
                    title: 'Issues Descriptions',
                    body: issue?.description,
                  ),
                  const SizedBox(height: 18),
                  _ReadMorePanel(
                    title: 'Recommendations',
                    body: issue?.recommendation,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _IssueSheetInfoGrid extends StatelessWidget {
  const _IssueSheetInfoGrid({this.issue});

  final MeetingSummaryIssue? issue;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _InfoBlock(
                label: 'Submitted by',
                value: issue?.agency.isNotEmpty == true ? issue!.agency : '—',
              ),
            ),
            SizedBox(width: 18),
            Expanded(
              child: _InfoBlock(
                label: 'Status :',
                value:
                    '• ${issue?.status.isNotEmpty == true ? issue!.status : '—'}',
              ),
            ),
          ],
        ),
        SizedBox(height: 16),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _InfoBlock(
                label: 'Categories',
                value: issue?.category.isNotEmpty == true
                    ? issue!.category
                    : '—',
              ),
            ),
            SizedBox(width: 18),
            Expanded(
              child: _DocumentBlock(
                label: 'Meeting Request Document:',
                path: issue?.attachmentPath ?? issue?.referencePath,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _DatePill extends StatelessWidget {
  const _DatePill({required this.label, required this.name});

  final String label;
  final String name;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 31,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      alignment: Alignment.centerLeft,
      decoration: BoxDecoration(
        color: AppColors.fieldBackground(context),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: AppColors.border(context)),
      ),
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: '$label : ',
              style: const TextStyle(
                color: AppColors.mutedText,
                fontWeight: FontWeight.w500,
              ),
            ),
            TextSpan(
              text: name,
              style: TextStyle(
                color: AppColors.primaryText(context),
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        style: const TextStyle(fontSize: 11),
      ),
    );
  }
}

class _ReadMorePanel extends StatelessWidget {
  const _ReadMorePanel({required this.title, this.body});

  final String title;
  final String? body;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            color: AppColors.primaryText(context),
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.cardBackground(context),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: AppColors.border(context)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                body?.isNotEmpty == true ? body! : '—',
                style: TextStyle(
                  color: AppColors.secondaryText(context),
                  fontSize: 12,
                  height: 1.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 6),
              InkWell(
                onTap: () {},
                child: const Text(
                  'Read more',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
