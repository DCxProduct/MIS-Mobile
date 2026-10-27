import 'dart:async';

import '../../shared/issues/data/working_group_issue.dart';
import 'package:flutter/material.dart';

import '../../../core/app_colors.dart';
import '../../../core/app_settings.dart';
import '../../../translations/app_localizations.dart';
import '../../../core/widgets/pdf_attachment_preview.dart';
import '../../shared/issues/widgets/issue_agency_logo.dart';
import '../../shared/issues/widgets/issue_display.dart';
import 'tabs/issue_descriptions_tab.dart';
import 'tabs/issue_progress_report_tab.dart';

class IssueDetailScreen extends StatefulWidget {
  const IssueDetailScreen({
    super.key,
    required this.title,
    required this.category,
    this.issue,
    this.translationPage = 'wg_issues',
  });

  final WorkingGroupIssue? issue;
  final String translationPage;
  final String title;
  final String category;

  @override
  State<IssueDetailScreen> createState() => _IssueDetailScreenState();
}

class _IssueDetailScreenState extends State<IssueDetailScreen>
    with WidgetsBindingObserver {
  int _selectedTab = 0;
  WorkingGroupIssue? _detail;
  Object? _loadError;
  Future<void>? _refreshRequest;
  Timer? _refreshTimer;
  int _generation = 0;
  bool _resumed = true;
  bool _started = false;
  bool _openedProgress = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (_canAutoRefresh) unawaited(_refresh());
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_started && widget.issue != null) {
      _started = true;
      unawaited(_refresh());
    }
  }

  bool get _canAutoRefresh =>
      mounted &&
      _resumed &&
      _selectedTab == 1 &&
      widget.issue != null &&
      ModalRoute.of(context)?.isCurrent == true;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _resumed = state == AppLifecycleState.resumed;
    if (_canAutoRefresh) unawaited(_refresh());
  }

  Future<void> _refresh() {
    if (!mounted || widget.issue == null) return Future.value();
    return _refreshRequest ??= _fetchIssue();
  }

  Future<void> _fetchIssue() async {
    final generation = ++_generation;
    final settings = AppSettings.of(context);
    final repository = settings.issues;
    // Refresh web labels on entry and pull-to-refresh as well as periodic sync.
    unawaited(settings.loadTranslations(refresh: true));
    final issueId = widget.issue!.id;
    setState(() => _loadError = null);
    try {
      final issue = await repository.getIssue(issueId);
      if (mounted && generation == _generation) {
        setState(() => _detail = issue);
      }
    } catch (error) {
      if (mounted && generation == _generation) {
        setState(() => _loadError = error);
      }
    } finally {
      if (generation == _generation) _refreshRequest = null;
    }
  }

  void _selectTab(int index) {
    setState(() => _selectedTab = index);
    if (index == 1) {
      if (_openedProgress || (_detail == null && _loadError == null)) {
        unawaited(_refresh());
      }
      _openedProgress = true;
    }
  }

  @override
  void didUpdateWidget(covariant IssueDetailScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.issue?.id != widget.issue?.id) {
      _generation++;
      _refreshRequest = null;
      _detail = null;
      _loadError = null;
      _selectedTab = 0;
      _openedProgress = false;
      if (widget.issue != null) unawaited(_refresh());
    }
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Widget _loadFailure(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(l10n.text('issuesListLoadError')),
        TextButton(onPressed: _refresh, child: Text(l10n.text('retry'))),
      ],
    );
  }

  Widget _descriptions(BuildContext context) {
    if (widget.issue != null && _detail == null) {
      return Center(
        child: _loadError != null
            ? _loadFailure(context)
            : const CircularProgressIndicator(),
      );
    }
    return RefreshIndicator(
      onRefresh: _refresh,
      child: IssueDescriptionsTab(issue: _detail ?? widget.issue),
    );
  }

  Widget _progressReports(BuildContext context) {
    if (widget.issue == null) return const IssueProgressReportTab();
    if (_detail == null && _loadError == null) {
      return const Center(child: CircularProgressIndicator());
    }
    final errorMessage = _loadFailure(context);
    if (_detail == null) return Center(child: errorMessage);
    return Column(
      children: [
        if (_loadError != null) errorMessage,
        Expanded(
          child: RefreshIndicator(
            onRefresh: _refresh,
            child: IssueProgressReportTab(
              issue: _detail,
              fallbackIssue: widget.issue,
              onRefresh: _refresh,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) => TranslationPageScope(
    page: widget.translationPage,
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
          onPressed: () => Navigator.of(context).pop(),
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: AppColors.primaryText(context),
            size: 19,
          ),
        ),
        title: Text(
          AppLocalizations.of(context).text('issuesDetails'),
          style: TextStyle(
            color: AppColors.primaryText(context),
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            _IssueHeader(
              issue: _detail ?? widget.issue,
              title: widget.title,
              category: widget.category,
            ),
            _DetailTabs(selectedIndex: _selectedTab, onSelected: _selectTab),
            Expanded(
              child: _selectedTab == 0
                  ? _descriptions(context)
                  : _progressReports(context),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailTabs extends StatelessWidget {
  const _DetailTabs({required this.selectedIndex, required this.onSelected});

  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tabs = [l10n.text('descriptions'), l10n.text('progressReport')];
    return Container(
      height: 46,
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.border(context))),
      ),
      child: Row(
        children: List.generate(
          tabs.length,
          (index) => Expanded(
            child: InkWell(
              onTap: () => onSelected(index),
              child: Container(
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      width: 2,
                      color: selectedIndex == index
                          ? AppColors.accent(context)
                          : Colors.transparent,
                    ),
                  ),
                ),
                child: Text(
                  tabs[index],
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: selectedIndex == index
                        ? AppColors.accent(context)
                        : AppColors.mutedText,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _IssueHeader extends StatelessWidget {
  const _IssueHeader({
    required this.issue,
    required this.title,
    required this.category,
  });
  final WorkingGroupIssue? issue;
  final String title;
  final String category;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final documentPath = issue?.meetingRequestDocumentPath ?? '';
    final documentName = pdfAttachmentName(
      documentPath,
      name: issue?.meetingRequestDocumentName,
    );
    final statusColor = switch (issue?.statusCode.toUpperCase()) {
      'SOLVED' => const Color(0xFF16A34A),
      'IN_PROGRESS' => const Color(0xFFFF8A00),
      'NOT_ADDRESSED' => const Color(0xFFEF4444),
      _ => AppColors.mutedText,
    };
    Widget field(String label, Widget child) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: AppColors.mutedText, fontSize: 12),
        ),
        const SizedBox(height: 7),
        child,
      ],
    );
    Widget value(String text) => Text(
      text.isEmpty ? '—' : text,
      style: TextStyle(fontSize: 12, color: AppColors.primaryText(context)),
    );
    Widget dateChip(String label, DateTime? date) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.fieldBackground(context),
        border: Border.all(color: AppColors.border(context)),
        borderRadius: BorderRadius.circular(3),
      ),
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: '$label : ',
              style: const TextStyle(color: AppColors.mutedText),
            ),
            TextSpan(text: issueDate(context, date)),
          ],
        ),
        style: const TextStyle(fontSize: 11),
      ),
    );
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            issue?.title ?? title,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 14,
              height: 1.5,
              fontWeight: FontWeight.w600,
              color: AppColors.primaryText(context),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: field(
                  '${l10n.text('governmentAgency')} :',
                  Row(
                    children: [
                      IssueAgencyLogo(
                        path: issue?.agencyLogo ?? '',
                        size: 16,
                        iconSize: 10,
                      ),
                      const SizedBox(width: 8),
                      Expanded(child: value(issue?.agency ?? '')),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: field(
                  '${l10n.text('status')} :',
                  Text(
                    issue == null ? '—' : issueStatusLabel(context, issue!),
                    style: TextStyle(fontSize: 12, color: statusColor),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: field(
                  l10n.text('category'),
                  value(l10n.category(issue?.category ?? category)),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: field(
                  '${l10n.text('meetingReferenceDocument')}:',
                  documentPath.isEmpty
                      ? value('—')
                      : PdfAttachmentPreview(
                          path: documentPath,
                          name: documentName,
                          child: Row(
                            children: [
                              const Icon(
                                Icons.picture_as_pdf,
                                size: 18,
                                color: Color(0xFFFF4842),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Tooltip(
                                  message: documentName,
                                  child: Text(
                                    documentName,
                                    maxLines: 1,
                                    softWrap: false,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 11,
                                      height: 1.3,
                                      color: AppColors.primaryText(context),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                dateChip(l10n.text('submittedDate'), issue?.createdAt),
                const SizedBox(width: 12),
                dateChip(l10n.text('meetingDate'), issue?.meetingDate),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
