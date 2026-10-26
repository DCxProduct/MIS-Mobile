import 'dart:async';

import 'progress_report_status.dart';
import '../../shared/issues/widgets/issue_agency_logo.dart';
import '../../../core/widgets/editor_content.dart';
import '../../../core/widgets/pdf_attachment_preview.dart';
import '../../shared/issues/widgets/issue_display.dart';
import 'package:flutter/material.dart';

import '../../../core/app_colors.dart';
import '../../../core/app_settings.dart';
import '../../../screens/report/progress_report_detail_loader.dart';
import '../../../translations/app_localizations.dart';
import '../../../translations/app_language.dart';
import '../../shared/meetings/data/progress_report.dart';

class CdcProgressReportMinistriesScreen extends StatefulWidget {
  const CdcProgressReportMinistriesScreen({super.key, required this.report});
  final ProgressReport report;

  @override
  State<CdcProgressReportMinistriesScreen> createState() => _MinistriesState();
}

class _MinistriesState extends State<CdcProgressReportMinistriesScreen>
    with WidgetsBindingObserver {
  Future<(ProgressReport, List<ProgressReportMinistry>)>? _future;
  Timer? _refreshTimer;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (ModalRoute.of(context)?.isCurrent == true &&
          WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed) {
        unawaited(_refresh());
      }
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed &&
        ModalRoute.of(context)?.isCurrent == true) {
      unawaited(_refresh());
    }
  }

  Future<void> _refresh() async {
    if (!mounted || _loading) return;
    final future = _load();
    setState(() {
      _future = future;
    });
    try {
      await future;
    } catch (_) {
      // FutureBuilder presents the error and retry action.
    }
  }

  Future<(ProgressReport, List<ProgressReportMinistry>)> _load() async {
    _loading = true;
    try {
      final repository = AppSettings.of(context).progressReports;
      final result = await Future.wait<Object>([
        repository.getDetail(widget.report.id),
        repository.getMinistries(widget.report.id),
      ]);
      return (
        result[0] as ProgressReport,
        result[1] as List<ProgressReportMinistry>,
      );
    } finally {
      _loading = false;
    }
  }

  @override
  Widget build(BuildContext context) => TranslationPageScope(
    page: 'cdc_progress_ministries',
    child: Builder(builder: _buildContent),
  );

  Widget _buildContent(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    _future ??= _load();
    return Scaffold(
      backgroundColor: AppColors.pageBackground(context),
      appBar: AppBar(
        title: Text(
          l10n.text('progressReportDetails'),
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      body: FutureBuilder<(ProgressReport, List<ProgressReportMinistry>)>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done &&
              !snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(l10n.text('progressReportsLoadError')),
                  TextButton(
                    onPressed: () => setState(() {
                      _future = null;
                    }),
                    child: Text(l10n.text('retry')),
                  ),
                ],
              ),
            );
          }
          final report = snapshot.data!.$1;
          final ministries = snapshot.data!.$2;
          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  report.title.isEmpty
                      ? '${l10n.text('semester')} ${l10n.number(report.semester)} ${l10n.number(report.year)}'
                      : report.title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Wrap(
                        spacing: 16,
                        runSpacing: 8,
                        children: [
                          Text(
                            '${l10n.text('year')}: ${report.year == 0 ? '—' : l10n.number(report.year)}',
                          ),
                          Text(
                            '${l10n.text('semester')}: ${report.semester.isEmpty ? '—' : l10n.number(report.semester)}',
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Align(
                        alignment: Alignment.topLeft,
                        child: Text(
                          '${l10n.text('status')}: ${l10n.status(report.status)}',
                          textAlign: TextAlign.left,
                        ),
                      ),
                    ),
                  ],
                ),
                if (report.schedule.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final singleColumn =
                          constraints.maxWidth < 300 ||
                          MediaQuery.textScalerOf(context).scale(14) > 20;
                      final width = singleColumn
                          ? constraints.maxWidth
                          : (constraints.maxWidth - 20) / 2;
                      return Wrap(
                        spacing: 20,
                        runSpacing: 12,
                        children: [
                          for (final entry in report.schedule)
                            SizedBox(
                              width: width,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(_scheduleLabel(l10n, entry)),
                                  const SizedBox(height: 4),
                                  Text(issueDateWithYear(context, entry.date)),
                                ],
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                ],
                for (final document in [
                  (
                    l10n.text('reportDraftSemester'),
                    report.draftSemesterDocument,
                  ),
                  (
                    l10n.text('reportFinalSemester'),
                    report.finalSemesterDocument,
                  ),
                ])
                  if (document.$2.isNotEmpty)
                    _MinistryDocument(
                      label: document.$1,
                      path: document.$2,
                      name: report.documentNames[document.$2] ?? '',
                    )
                  else ...[
                    const SizedBox(height: 12),
                    Text(document.$1),
                    const SizedBox(height: 4),
                    const Text('—'),
                  ],
                if (report.description.trim().isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text(
                    l10n.text('descriptions'),
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  EditorContent(
                    report.description,
                    style: const TextStyle(fontSize: 14, height: 1.5),
                  ),
                ],
                const SizedBox(height: 16),
                Text(
                  '${l10n.text('governmentAgency')} (${l10n.number(ministries.length)})',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                if (ministries.isEmpty) Text(l10n.text('noProgressReports')),
                for (final ministry in ministries)
                  Container(
                    margin: const EdgeInsets.only(bottom: 14),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.cardBackground(context),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.border(context)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            IssueAgencyLogo(path: ministry.logo, size: 30),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                ministry.name,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (ministry.description.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(
                            ministry.description,
                            style: const TextStyle(fontSize: 13),
                          ),
                        ],
                        const SizedBox(height: 8),
                        ProgressReportMinistryStatus(status: ministry.status),
                        const SizedBox(height: 8),
                        Text(
                          '${l10n.text('allIssues')}: ${l10n.number(ministry.issues)}',
                          style: const TextStyle(fontSize: 13),
                        ),
                        if (ministry.submittedToCdc &&
                            ministry.attachment.isNotEmpty)
                          _MinistryDocument(
                            label: l10n.text('approvalReport'),
                            path: ministry.attachment,
                            name: ministry.attachmentName,
                          ),
                        if (ministry.requestDocument.isNotEmpty)
                          _MinistryDocument(
                            label: l10n.text('requestDocument'),
                            path: ministry.requestDocument,
                            name: ministry.requestDocumentName,
                          ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton(
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColors.accent(
                                context,
                              ).withValues(alpha: .1),
                              foregroundColor: AppColors.accent(context),
                            ),
                            onPressed: () async {
                              await Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (_) => ProgressReportDetailLoader(
                                    id: widget.report.id,
                                    ministryId: ministry.ministryId,
                                  ),
                                ),
                              );
                              await _refresh();
                            },
                            child: Text(l10n.text('viewDetails')),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

String _scheduleLabel(
  AppLocalizations l10n,
  ProgressReportScheduleEntry entry,
) {
  if (!entry.isMeeting && entry.number == 0) {
    return l10n.text('reportInitialDeadline');
  }
  final number = entry.number;
  String formatted;
  if (l10n.language == AppLanguage.khmer) {
    formatted = l10n.number(number);
  } else {
    final suffix = number % 100 >= 11 && number % 100 <= 13
        ? 'th'
        : switch (number % 10) {
            1 => 'st',
            2 => 'nd',
            3 => 'rd',
            _ => 'th',
          };
    formatted = '$number$suffix';
  }
  return l10n
      .text(
        entry.isMeeting ? 'reportNumberedMeeting' : 'reportRevisionDeadline',
      )
      .replaceAll('{number}', formatted);
}

class _MinistryDocument extends StatelessWidget {
  const _MinistryDocument({
    required this.label,
    required this.path,
    required this.name,
  });
  final String label, path, name;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 12),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: AppColors.mutedText),
        ),
        const SizedBox(height: 4),
        PdfAttachmentPreview(
          path: path,
          name: pdfAttachmentName(path, name: name),
          child: Row(
            children: [
              const Icon(
                Icons.picture_as_pdf,
                color: Color(0xFFE53935),
                size: 18,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  pdfAttachmentName(path, name: name),
                  style: const TextStyle(fontSize: 13),
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
