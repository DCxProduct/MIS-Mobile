import '../../shared/issues/widgets/issue_display.dart';
import '../../shared/issues/widgets/issue_agency_logo.dart';
import '../../../core/widgets/editor_content.dart';
import 'package:flutter/material.dart';

import '../../../../core/app_colors.dart';
import '../../../../core/app_settings.dart';
import '../../../../core/config/module_config.dart';
import '../../cdc_secretariat/meetings/summary_issue_details.dart';
import '../../../../core/widgets/pdf_attachment_preview.dart';
import '../../shared/meetings/data/meeting_summary.dart';
import '../../../../translations/app_localizations.dart';

class MeetingSummaryDetailScreen extends StatefulWidget {
  const MeetingSummaryDetailScreen({
    super.key,
    this.id,
    this.summary,
    this.summaryTitle = '',
  });

  final int? id;
  final MeetingSummary? summary;
  // The detail endpoint may omit summaryTitle and return only meeting.title.
  final String summaryTitle;

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
            appBar: AppBar(
              title: Text(
                AppLocalizations.of(
                  context,
                  page: 'meeting_summary',
                ).text('meetingSummaryDetails'),
              ),
            ),
            body: const Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasError || snapshot.data == null) {
          return Scaffold(
            appBar: AppBar(
              title: Text(
                AppLocalizations.of(
                  context,
                  page: 'meeting_summary',
                ).text('meetingSummaryDetails'),
              ),
            ),
            body: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    AppLocalizations.of(
                      context,
                      page: 'meeting_summary',
                    ).text('meetingSummariesLoadError'),
                  ),
                  TextButton(
                    onPressed: () => setState(() {
                      _future = AppSettings.of(
                        context,
                      ).meetingSummaries.getSummary(widget.id!);
                    }),
                    child: Text(
                      AppLocalizations.of(
                        context,
                        page: 'meeting_summary',
                      ).text('retry'),
                    ),
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
    final title = [summary.title, widget.summaryTitle, summary.detailTitle]
        .map((value) => value.trim())
        .firstWhere((value) => value.isNotEmpty, orElse: () => '—');
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
            page: 'meeting_summary',
          ).text('meetingSummaryDetails'),
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
        child:
            AppSettings.of(context).moduleType == AppModuleType.cdcSecretariat
            ? ListView(
                padding: const EdgeInsets.fromLTRB(14, 16, 14, 28),
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      height: 1.45,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 20),
                  _CdcSummaryInfo(summary: summary),
                  const SizedBox(height: 20),
                  if (summary.summaryDocumentPath != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      AppLocalizations.of(
                        context,
                      ).text('summaryReferenceDocument'),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 12),
                    PdfAttachmentPreview(
                      path: summary.summaryDocumentPath!,
                      name: summary.summaryDocumentName,
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: AppColors.border(
                              context,
                            ).withValues(alpha: 0.45),
                            width: 0.7,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.picture_as_pdf,
                              color: Colors.red,
                              size: 32,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    pdfAttachmentName(
                                      summary.summaryDocumentPath!,
                                      name: summary.summaryDocumentName,
                                    ),
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                  if (summary.summaryDocumentSize != null) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      '${(summary.summaryDocumentSize! / (1024 * 1024)).toStringAsFixed(1)} MB',
                                      style: const TextStyle(
                                        fontSize: 10,
                                        color: AppColors.mutedText,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  const _AllIssuesTabHeader(),
                  const SizedBox(height: 14),
                  if (summary.issues.isEmpty)
                    Text(AppLocalizations.of(context).text('noIssuesFound')),
                  for (final issue in summary.issues) ...[
                    _ClimateIssueCard(
                      issue: issue,
                      onTap: () => _showIssueDetails(context, issue),
                    ),
                    const SizedBox(height: 14),
                  ],
                ],
              )
            : Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(14, 16, 14, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
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
                              AppLocalizations.of(
                                context,
                                page: 'meeting_summary',
                              ).text('noIssuesFound'),
                            ),
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.fromLTRB(14, 14, 14, 28),
                            itemCount: summary.issues.length,
                            separatorBuilder: (_, _) =>
                                const SizedBox(height: 14),
                            itemBuilder: (context, index) => _ClimateIssueCard(
                              issue: summary.issues[index],
                              onTap: () => _showIssueDetails(
                                context,
                                summary.issues[index],
                              ),
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
      builder: (context) =>
          issue != null &&
              AppSettings.of(context).moduleType == AppModuleType.cdcSecretariat
          ? CdcSummaryIssueDetails(issue: issue)
          : _IssueDetailsSheet(issue: issue),
    );
  }
}

class _CdcSummaryInfo extends StatelessWidget {
  const _CdcSummaryInfo({required this.summary});
  final MeetingSummary summary;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context, page: 'meeting_summary');
    Widget field(String key, String value) =>
        _InfoBlock(label: l10n.text(key), value: value.isEmpty ? '—' : value);
    Widget grid(List<Widget> fields) => LayoutBuilder(
      builder: (context, constraints) => Wrap(
        spacing: 18,
        runSpacing: 18,
        children: [
          for (final item in fields)
            SizedBox(width: (constraints.maxWidth - 18) / 2, child: item),
        ],
      ),
    );
    Widget heading(String key) => Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(
        l10n.text(key),
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
      ),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        heading('meetingRequest'),
        grid([
          field('workingGroup', summary.pswg),
          _DocumentBlock(
            label: l10n.text('meetingRequestDocument'),
            path: summary.requestDocumentPath,
            name: summary.requestDocumentName,
          ),
          field(
            'submittedDate',
            issueDateWithYear(context, summary.requestedDate?.toLocal()),
          ),
        ]),
        const SizedBox(height: 20),
        Divider(
          color: AppColors.border(context).withValues(alpha: 0.4),
          thickness: 0.6,
        ),
        const SizedBox(height: 12),
        heading('meetingInformation'),
        grid([
          field(
            'workingGroup',
            summary.meetingPswg.isEmpty ? summary.pswg : summary.meetingPswg,
          ),
          _DocumentBlock(
            label: l10n.text('meetingDocument'),
            path: summary.meetingDocumentPath,
            name: summary.meetingDocumentName,
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.text('governmentAgency'),
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.mutedText,
                ),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  if (summary.governmentAgency.isNotEmpty) ...[
                    IssueAgencyLogo(
                      path: summary.agencyLogo,
                      size: 22,
                      iconSize: 14,
                    ),
                    const SizedBox(width: 6),
                  ],
                  Expanded(
                    child: Text(
                      summary.governmentAgency.isEmpty
                          ? '—'
                          : summary.governmentAgency,
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ],
          ),
          field('sentBy', summary.sentBy),
          field(
            'meetingTime',
            _SummaryInfoGrid(summary: summary)._meetingTime(context),
          ),
          field(
            'scheduleMeeting',
            issueDateWithYear(context, summary.detailDate?.toLocal()),
          ),
          field('location', summary.location),
        ]),
      ],
    );
  }
}

class _SummaryInfoGrid extends StatelessWidget {
  const _SummaryInfoGrid({required this.summary});

  final MeetingSummary summary;

  String _meetingTime(BuildContext context) {
    final raw = summary.startTime.trim();
    // The web calendar treats ISO startTime as a stored clock time (UTC hours).
    final date = DateTime.tryParse(raw)?.toUtc();
    final clock = RegExp(r'^(\d{1,2}):(\d{2})(?::\d{2})?$').firstMatch(raw);
    final int? hour =
        date?.hour ?? (clock == null ? null : int.tryParse(clock[1]!));
    final int? minute =
        date?.minute ?? (clock == null ? null : int.tryParse(clock[2]!));
    if (hour == null || minute == null || hour > 23 || minute > 59) return '—';
    return MaterialLocalizations.of(
      context,
    ).formatTimeOfDay(TimeOfDay(hour: hour, minute: minute));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _InfoBlock(
                label: AppLocalizations.of(
                  context,
                  page: 'meeting_summary',
                ).text('meetingTime'),
                value: _meetingTime(context),
              ),
            ),
            SizedBox(width: 24),
            Expanded(
              child: _InfoBlock(
                label: AppLocalizations.of(
                  context,
                  page: 'meeting_summary',
                ).text('scheduleMeeting'),
                value: issueDateWithYear(
                  context,
                  summary.detailDate?.toLocal(),
                ),
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
                label: AppLocalizations.of(
                  context,
                  page: 'meeting_summary',
                ).text('location'),
                value: summary.location.isEmpty ? '—' : summary.location,
              ),
            ),
            SizedBox(width: 24),
            Expanded(
              child: _DocumentBlock(
                label: AppLocalizations.of(
                  context,
                  page: 'meeting_summary',
                ).text('meetingRequestDocument'),
                path:
                    summary.requestDocumentPath ?? summary.meetingDocumentPath,
                name: summary.requestDocumentPath != null
                    ? summary.requestDocumentName
                    : summary.meetingDocumentName,
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
  const _DocumentBlock({required this.label, this.path, this.name});

  final String label;
  final String? path;
  final String? name;

  @override
  Widget build(BuildContext context) {
    return PdfAttachmentPreview(
      path: path ?? '',
      name: pdfAttachmentName(path ?? '', name: name),
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
                      pdfAttachmentName(path ?? '', name: name),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: AppColors.primaryText(context),
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 1),
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
    return SizedBox(
      height: 40,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Text(
              AppLocalizations.of(
                context,
                page: 'meeting_summary',
              ).text('allIssues'),
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
                    AppLocalizations.of(
                      context,
                      page: 'meeting_summary_issue',
                    ).status(issue?.status ?? ''),
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
                      AppLocalizations.of(
                        context,
                        page: 'meeting_summary_issue',
                      ).text('issuesDetails'),
                      style: TextStyle(
                        color: AppColors.primaryText(context),
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    issue?.title.isNotEmpty == true ? issue!.title : '—',
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
                          label: AppLocalizations.of(
                            context,
                            page: 'meeting_summary_issue',
                          ).text('submittedBy'),
                          name: issue?.submittedBy.isNotEmpty == true
                              ? issue!.submittedBy
                              : '—',
                        ),
                        const SizedBox(width: 10),
                        _DatePill(
                          label: AppLocalizations.of(
                            context,
                            page: 'meeting_summary_issue',
                          ).text('submittedDate'),
                          name: issueDateWithYear(
                            context,
                            issue?.submittedDate?.toLocal(),
                          ),
                        ),
                        for (final order in [1, 2, 3, 4, 5]) ...[
                          const SizedBox(width: 10),
                          _DatePill(
                            label:
                                AppLocalizations.of(
                                  context,
                                  page: 'meeting_summary_issue',
                                ).text(switch (order) {
                                  1 => 'governmentAgency',
                                  2 => 'governmentSecondAgency',
                                  3 => 'governmentThirdAgency',
                                  4 => 'governmentFourthAgency',
                                  _ => 'governmentFifthAgency',
                                }),
                            name: issue?.governmentAgencies[order] ?? '—',
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  _ReadMorePanel(
                    title: AppLocalizations.of(
                      context,
                      page: 'meeting_summary_issue',
                    ).text('issuesDescriptions'),
                    body: issue?.descriptionHtml ?? issue?.description,
                  ),
                  const SizedBox(height: 18),
                  _ReadMorePanel(
                    title: AppLocalizations.of(
                      context,
                      page: 'meeting_summary_issue',
                    ).text('recommendations'),
                    body: issue?.recommendationHtml ?? issue?.recommendation,
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
                label: AppLocalizations.of(
                  context,
                  page: 'meeting_summary_issue',
                ).text('submittedBy'),
                value: issue?.submittedBy.isNotEmpty == true
                    ? issue!.submittedBy
                    : '—',
              ),
            ),
            SizedBox(width: 18),
            Expanded(
              child: _InfoBlock(
                label: AppLocalizations.of(
                  context,
                  page: 'meeting_summary_issue',
                ).text('status'),
                value:
                    '• ${AppLocalizations.of(context, page: 'meeting_summary_issue').status(issue?.status ?? '')}',
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
                label: AppLocalizations.of(
                  context,
                  page: 'meeting_summary_issue',
                ).text('categories'),
                value: issue?.category.isNotEmpty == true
                    ? issue!.category
                    : '—',
              ),
            ),
            SizedBox(width: 18),
            Expanded(
              child: _DocumentBlock(
                label: AppLocalizations.of(
                  context,
                  page: 'meeting_summary_issue',
                ).text('issueDocument'),
                path: issue?.attachmentPath ?? issue?.referencePath,
                name: issue?.attachmentPath != null
                    ? issue?.attachmentName
                    : issue?.referenceName,
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
  Widget build(BuildContext context) => Column(
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
        child: ExpandableEditorContent(
          body?.isNotEmpty == true ? body! : '—',
          style: TextStyle(
            color: AppColors.secondaryText(context),
            fontSize: 12,
            height: 1.5,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    ],
  );
}
