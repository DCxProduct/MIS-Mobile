import '../../../core/app_settings.dart';
import '../../../core/widgets/filters/api_filter_sheet.dart';
import '../../shared/issues/data/working_group_issue.dart';
import '../../shared/issues/widgets/wg_issues_list.dart';
import '../../shared/issues/widgets/issue_display.dart';
import '../../shared/issues/widgets/issue_agency_logo.dart';
import '../../shared/issues/data/wg_issue_summary.dart';
import '../../shared/issues/widgets/wg_issue_summary_loader.dart';
import 'package:flutter/material.dart';
import '../../shared/widgets/list_screen_header.dart';

import '../../../core/app_colors.dart';
import '../../../core/widgets/pdf_attachment_preview.dart';
import '../../../screens/issues/issue_detail_screen.dart';
import '../../../translations/app_localizations.dart';
import '../../cdc_secretariat/dashboard/filter_sheet.dart';

import '../../cdc_secretariat/issues/issue_filter_sheet.dart';

class LineMinistryIssuesScreenView extends StatefulWidget {
  const LineMinistryIssuesScreenView({
    super.key,
    this.titleKey = 'issuesMatrix',
    this.showTabs = true,
    this.staticPreview = false,
    this.cdcMatrix = false,
    this.issueDetailBuilder,
    this.previewStatus = 'In Progress',
  });

  final String titleKey;
  final bool showTabs;
  final bool staticPreview;
  final bool cdcMatrix;
  final String previewStatus;
  final Widget Function(
    String title,
    String category,
    WorkingGroupIssue? issue,
  )?
  issueDetailBuilder;

  @override
  State<LineMinistryIssuesScreenView> createState() =>
      _LineMinistryIssuesScreenViewState();
}

class _LineMinistryIssuesScreenViewState
    extends State<LineMinistryIssuesScreenView> {
  int _selectedTab = 0;

  final _apiSelections = [FilterSelection(), FilterSelection()];

  Set<String> _selectedYears = {};
  Set<String> _selectedCategories = {};
  Set<String> _selectedStatuses = {};
  Set<String> _selectedAgencies = {};
  Set<String> _selectedProgressReports = {};

  Future<void> _openFilterSheet(BuildContext context) async {
    if (widget.staticPreview) {
      await _openPreviewFilters(context);
      return;
    }
    final tab = _selectedTab == 0 && widget.showTabs ? 0 : 1;
    final catalogs = AppSettings.of(context).filters;
    final result = await Navigator.of(context).push<FilterSelection>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => ApiFilterSheet(
          initial: _apiSelections[tab],
          load: () => widget.cdcMatrix
              ? catalogs.cdcIssues()
              : catalogs.issues(
                  matrix: tab == 1,
                  cdcDesign: widget.issueDetailBuilder != null,
                ),
        ),
      ),
    );
    if (!mounted || result == null) return;
    setState(() => _apiSelections[tab] = result);
  }

  Future<void> _openPreviewFilters(BuildContext context) async {
    final initial = CdcDashboardFilters({
      'categories': {..._selectedCategories},
      'status': {..._selectedStatuses},
      'allPswgs': {..._selectedAgencies},
      'year': {..._selectedYears},
      'plenaryEscalation': {..._selectedProgressReports},
    });
    final result = await Navigator.of(context).push<CdcDashboardFilters>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => CdcIssueFilterSheet(initial: initial),
      ),
    );
    if (!mounted || result == null) return;
    setState(() {
      _selectedCategories = {...?result.values['categories']};
      _selectedStatuses = {...?result.values['status']};
      _selectedAgencies = {...?result.values['allPswgs']};
      _selectedYears = {...?result.values['year']};
      _selectedProgressReports = {...?result.values['plenaryEscalation']};
    });
  }

  int get _activeFilterCount {
    if (!widget.staticPreview) {
      return _apiSelections[_selectedTab == 0 && widget.showTabs ? 0 : 1].count;
    }
    return _selectedCategories.length +
        _selectedYears.length +
        _selectedStatuses.length +
        _selectedAgencies.length +
        _selectedProgressReports.length;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final contentBackground = isDark
        ? AppColors.darkBackground
        : const Color(0xFFF7F7F8);

    return ColoredBox(
      color: contentBackground,
      child: Column(
        children: [
          ListScreenHeader(
            title: l10n.text(widget.titleKey),
            activeCount: _activeFilterCount,
            onFilter: () => _openFilterSheet(context),
            bottom: widget.showTabs
                ? _IssueTabs(
                    selectedIndex: _selectedTab,
                    onSelected: (index) => setState(() => _selectedTab = index),
                  )
                : null,
          ),
          // SCROLLABLE CONTENT
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 96),
              children: [
                if (widget.staticPreview) ...[
                  const _LineMinistryMetricGrid(),
                  const SizedBox(height: 8),
                  const _TotalPrimaryAgenciesCard(value: '14'),
                  const SizedBox(height: 16),
                  if ((_selectedYears.isEmpty ||
                          _selectedYears.contains('2025')) &&
                      (_selectedStatuses.isEmpty ||
                          _selectedStatuses.contains(widget.previewStatus)))
                    for (final title in [
                      'Joint Inspection',
                      'Law on Contract Farming & Agricultural Production',
                    ])
                      _LineMinistryIssueListCard(
                        title: title,
                        category: title == 'Joint Inspection'
                            ? 'Procedure'
                            : 'Legislation',
                        status: widget.previewStatus,
                        submissionDate: 'July 24, 2025',
                        submittedBy: 'Agriculture and Agro-industry',
                        description:
                            'The private sector said that the Economic Land Concession (ELCs), which invest in rubber, cashew, plantations, etc., are now fully developed and some are ready for production.',
                        attachmentCount: '2 ${l10n.text('attachmentsLabel')}',
                        matrixPreview: true,
                        detailBuilder: widget.issueDetailBuilder,
                      )
                  else
                    Text(
                      l10n.text('noIssuesFound'),
                      textAlign: TextAlign.center,
                    ),
                ] else ...[
                  WgIssueSummaryLoader(
                    cdcMatrix: widget.cdcMatrix,
                    matrix: !widget.showTabs || _selectedTab == 1,
                    builder: (summary) => Column(
                      children: [
                        _LineMinistryMetricGrid(summary: summary),
                        const SizedBox(height: 12),
                        _TotalPrimaryAgenciesCard(
                          value: '${summary.totalPrimaryAgencies}',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    l10n.text('allIssues'),
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _selectedTab == 0 && widget.showTabs
                      ? WgIssuesList(
                          apiFilters: _apiSelections[0].toQuery(),
                          selection: _apiSelections[0],
                          itemBuilder: (issue) => _LineMinistryIssueListCard(
                            title: issue.title,
                            category: issue.category.isEmpty
                                ? '—'
                                : issue.category,
                            status: issueStatusLabel(context, issue),
                            submissionDate: issueDate(context, issue.createdAt),
                            submittedBy: issue.submittedBy.isEmpty
                                ? '—'
                                : issue.submittedBy,
                            description: issue.description,
                            attachmentCount:
                                '${issue.attachmentCount} ${l10n.text('attachmentsLabel')}',
                            issue: issue,
                            detailBuilder: widget.issueDetailBuilder,
                          ),
                        )
                      : WgIssuesList(
                          cdcMatrix: widget.cdcMatrix,
                          matrix: true,
                          apiFilters: _apiSelections[1].toQuery(),
                          selection: _apiSelections[1],
                          itemBuilder: (issue) => _LineMinistryIssueListCard(
                            title: issue.title,
                            category: issue.category.isEmpty
                                ? '—'
                                : issue.category,
                            status: issueStatusLabel(context, issue),
                            submissionDate: issueDate(context, issue.createdAt),
                            submittedBy: issue.submittedBy.isEmpty
                                ? '—'
                                : issue.submittedBy,
                            description: issue.description,
                            attachmentCount:
                                '${issue.attachmentCount} ${l10n.text('attachmentsLabel')}',
                            issue: issue,
                            detailBuilder: widget.issueDetailBuilder,
                          ),
                        ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LineMinistryMetricGrid extends StatelessWidget {
  const _LineMinistryMetricGrid({this.summary});

  final WgIssueSummary? summary;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      padding: EdgeInsets.zero,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      childAspectRatio: 2.26,
      children: [
        _MetricCard(
          label: l10n.text('totalIssues'),
          value: summary == null ? '56' : '${summary!.totalIssues}',
          background: const Color(0xFFDDEEFF),
          icon: Icons.library_books_outlined,
        ),
        _MetricCard(
          label: l10n.text('solved'),
          value: summary == null
              ? '30/56'
              : '${summary!.solved}/${summary!.totalIssues}',
          background: const Color(0xFFE5FAEF),
          icon: Icons.fact_check_outlined,
        ),
        _MetricCard(
          label: l10n.text('inProgress'),
          value: summary == null
              ? '16/56'
              : '${summary!.inProgress}/${summary!.totalIssues}',
          background: const Color(0xFFFFF8DC),
          icon: Icons.add_box_outlined,
        ),
        _MetricCard(
          label: l10n.text('notAddressed'),
          value: summary == null
              ? '10/56'
              : '${summary!.notAddressed}/${summary!.totalIssues}',
          background: const Color(0xFFFFEEEE),
          icon: Icons.assignment_late_outlined,
        ),
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.label,
    required this.value,
    required this.background,
    required this.icon,
  });

  final String label;
  final String value;
  final Color background;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.fromLTRB(11, 10, 10, 9),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : background,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : Colors.transparent,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: isDark
                        ? AppColors.secondaryText(context)
                        : AppColors.mutedText,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 7),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    value,
                    style: TextStyle(
                      color: isDark ? Colors.white : const Color(0xFF27364A),
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.darkBorder
                  : Colors.white.withValues(alpha: 0.86),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: isDark ? const Color(0xFFE3E8EF) : const Color(0xFF4C5563),
              size: 21,
            ),
          ),
        ],
      ),
    );
  }
}

class _TotalPrimaryAgenciesCard extends StatelessWidget {
  const _TotalPrimaryAgenciesCard({required this.value});

  final String value;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : const Color(0xFFE5E8ED),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppLocalizations.of(context).text('totalPrimaryAgencies'),
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
                  color: Theme.of(context).colorScheme.onSurface,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkBorder : const Color(0xFFFAFAFA),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isDark ? AppColors.darkBorder : const Color(0xFFE5E8ED),
              ),
            ),
            child: const Icon(
              Icons.calendar_month_outlined,
              color: Color(0xFF4C5563),
              size: 20,
            ),
          ),
        ],
      ),
    );
  }
}

class _LineMinistryIssueListCard extends StatelessWidget {
  const _LineMinistryIssueListCard({
    required this.title,
    this.issue,
    required this.category,
    required this.status,
    required this.submissionDate,
    required this.submittedBy,
    required this.description,
    required this.attachmentCount,
    this.matrixPreview = false,
    this.detailBuilder,
  });

  final WorkingGroupIssue? issue;
  final String title;
  final String category;
  final String status;
  final String submissionDate;
  final String submittedBy;
  final String description;
  final String attachmentCount;
  final bool matrixPreview;
  final Widget Function(
    String title,
    String category,
    WorkingGroupIssue? issue,
  )?
  detailBuilder;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final isSolved = issue == null
        ? status == 'Solved'
        : issue!.statusCode == 'SOLVED';
    final isProgress = issue == null
        ? status == 'In Progress'
        : issue!.statusCode == 'IN_PROGRESS';
    final statusColor = isSolved
        ? (isDark ? const Color(0xFF86EFAC) : const Color(0xFF16A34A))
        : (isProgress
              ? (isDark ? const Color(0xFFFBBF24) : const Color(0xFFFF8A00))
              : (isDark ? const Color(0xFFFCA5A5) : const Color(0xFFFF4842)));
    final statusBg = isSolved
        ? (isDark ? const Color(0xFF123B2A) : const Color(0xFFEAFBF0))
        : (isProgress
              ? (isDark ? const Color(0xFF423415) : const Color(0xFFFFF6E8))
              : (isDark ? const Color(0xFF3B1212) : const Color(0xFFFFEEEE)));
    final statusBorder = isSolved
        ? (isDark ? const Color(0xFF166534) : const Color(0xFF9BE2B4))
        : (isProgress
              ? (isDark ? const Color(0xFF92400E) : const Color(0xFFFFC166))
              : (isDark ? const Color(0xFF991B1B) : const Color(0xFFFFB3B3)));

    return InkWell(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) =>
                detailBuilder?.call(title, category, issue) ??
                IssueDetailScreen(
                  title: title,
                  category: category,
                  issue: issue,
                ),
          ),
        );
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark ? AppColors.darkBorder : const Color(0xFFF0F2F5),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (matrixPreview)
                  ClipOval(
                    child: Image.asset(
                      'assets/images/maff.jpg',
                      width: 34,
                      height: 34,
                      fit: BoxFit.cover,
                    ),
                  )
                else
                  IssueAgencyLogo(path: issue?.agencyLogo ?? ''),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontSize: matrixPreview ? 13 : 14,
                          fontWeight: matrixPreview
                              ? FontWeight.w400
                              : FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        category,
                        style: TextStyle(
                          color: matrixPreview
                              ? AppColors.primary
                              : const Color(0xFF7C3AED),
                          fontSize: 12,
                          fontWeight: matrixPreview
                              ? FontWeight.w400
                              : FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: statusBg,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: statusBorder),
                  ),
                  child: Text(
                    '• $status',
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _MetaInfo(
                    icon: Icons.calendar_month_outlined,
                    label: 'Submission Date',
                    value: submissionDate,
                    iconColor: AppColors.primary,
                    iconBackground: const Color(0xFFDDEEFF),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _MetaInfo(
                    icon: Icons.person_outline,
                    label: 'Submitted by',
                    value: submittedBy,
                    iconColor: const Color(0xFFB642FF),
                    iconBackground: const Color(0xFFF2DDFF),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            if (matrixPreview) ...[
              Divider(height: 1, color: AppColors.border(context)),
              const SizedBox(height: 16),
            ],
            Text(
              description,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: AppColors.secondaryText(context),
                fontSize: matrixPreview ? 13 : 11,
                height: 1.45,
                fontWeight: FontWeight.w400,
              ),
            ),
            const SizedBox(height: 10),
            PdfAttachmentPreview(
              path: issue?.attachmentPath ?? '',
              name: issue?.attachmentPath.isNotEmpty == true
                  ? pdfAttachmentName(issue!.attachmentPath)
                  : null,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkCard : const Color(0xFFFAFAFA),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: isDark
                        ? AppColors.darkBorder
                        : const Color(0xFFE5E8ED),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.link, color: Color(0xFF4C5563), size: 14),
                    const SizedBox(width: 6),
                    Text(
                      attachmentCount,
                      style: const TextStyle(
                        color: Color(0xFF4C5563),
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MetaInfo extends StatelessWidget {
  const _MetaInfo({
    required this.icon,
    required this.label,
    required this.value,
    required this.iconColor,
    required this.iconBackground,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color iconColor;
  final Color iconBackground;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Row(
      children: [
        Container(
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            color: isDark ? iconColor.withValues(alpha: 0.16) : iconBackground,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Icon(icon, color: iconColor, size: 14),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: isDark
                      ? AppColors.secondaryText(context)
                      : AppColors.mutedText,
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
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

class _IssueTabs extends StatelessWidget {
  const _IssueTabs({required this.selectedIndex, required this.onSelected});

  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context);
    final tabs = [l10n.text('wgIssues'), l10n.text('issuesMatrix')];

    return Container(
      height: 38,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkBackground : Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : const Color(0xFFE8EBF0),
        ),
      ),
      child: Row(
        children: List.generate(
          tabs.length,
          (index) => Expanded(
            child: InkWell(
              onTap: () => onSelected(index),
              borderRadius: BorderRadius.circular(6),
              child: Container(
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: selectedIndex == index
                      ? AppColors.accent(context)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      index == 0
                          ? Icons.calendar_month_outlined
                          : Icons.add_box_outlined,
                      color: selectedIndex == index
                          ? Colors.white
                          : AppColors.mutedText,
                      size: 15,
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        tabs[index],
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: selectedIndex == index
                              ? Colors.white
                              : AppColors.mutedText,
                          fontSize: 12,
                          fontWeight: selectedIndex == index
                              ? FontWeight.w700
                              : FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
