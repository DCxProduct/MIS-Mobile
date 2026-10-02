import '../../../core/app_settings.dart';
import '../../../core/widgets/filters/api_filter_sheet.dart';
import '../../shared/issues/data/working_group_issue.dart';
import '../../shared/issues/widgets/wg_issues_list.dart';
import '../../shared/issues/widgets/issue_display.dart';
import '../../shared/issues/data/wg_issue_summary.dart';
import '../../shared/issues/widgets/wg_issue_summary_loader.dart';
import 'package:flutter/material.dart';

import '../../../core/app_colors.dart';
import '../../../core/widgets/pdf_attachment_preview.dart';
import '../../../translations/app_localizations.dart';
import 'issue_detail_screen.dart';

class IssuesScreen extends StatefulWidget {
  const IssuesScreen({super.key});

  @override
  State<IssuesScreen> createState() => _IssuesScreenState();
}

class _IssuesScreenState extends State<IssuesScreen> {
  int _selectedTab = 0;
  String _searchQuery = '';

  final _filters = [FilterSelection(), FilterSelection()];

  Future<void> _openIssuesFilterSheet(BuildContext context) async {
    final tab = _selectedTab;
    final catalogs = AppSettings.of(context).filters;
    final result = await Navigator.of(context).push<FilterSelection>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => ApiFilterSheet(
          initial: _filters[tab],
          load: () => catalogs.pswgIssues(matrix: tab == 1),
        ),
      ),
    );
    if (!mounted || result == null) return;
    setState(() => _filters[tab] = result);
  }

  int get _activeFilterCount => _filters[_selectedTab].count;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final contentBackground = isDark
        ? AppColors.darkBackground
        : const Color(0xFFF7F7F8);
    final headerBackground = isDark ? AppColors.darkBackground : Colors.white;

    final title = _selectedTab == 0
        ? l10n.text('wgIssues')
        : l10n.text('issuesMatrix');

    final topPadding = MediaQuery.of(context).viewPadding.top;

    return ColoredBox(
      color: contentBackground,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          Container(
            color: headerBackground,
            padding: EdgeInsets.fromLTRB(
              14,
              topPadding > 0 ? topPadding + 12 : 34,
              14,
              12,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 14),
                _IssueTabs(
                  selectedIndex: _selectedTab,
                  onSelected: (index) => setState(() => _selectedTab = index),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 96),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 38,
                        child: TextField(
                          onChanged: (val) {
                            setState(() {
                              _searchQuery = val;
                            });
                          },
                          style: const TextStyle(fontSize: 13),
                          decoration: InputDecoration(
                            hintText: l10n.text('searchIssues'),
                            hintStyle: const TextStyle(
                              color: AppColors.mutedText,
                              fontSize: 12,
                            ),
                            prefixIcon: const Icon(
                              Icons.search,
                              size: 18,
                              color: AppColors.mutedText,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 8,
                            ),
                            filled: true,
                            fillColor: isDark
                                ? AppColors.darkCard
                                : Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(
                                color: isDark
                                    ? AppColors.darkBorder
                                    : const Color(0xFFE2E7ED),
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(
                                color: isDark
                                    ? AppColors.darkBorder
                                    : const Color(0xFFE2E7ED),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    _FilterButton(
                      activeCount: _activeFilterCount,
                      onTap: () => _openIssuesFilterSheet(context),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                _selectedTab == 0
                    ? WgIssueSummaryLoader(
                        builder: (summary) =>
                            _IssueMetricGrid(summary: summary),
                      )
                    : WgIssueSummaryLoader(
                        matrix: true,
                        builder: (summary) =>
                            _IssueMetricGrid(summary: summary),
                      ),
                const SizedBox(height: 14),
                _selectedTab == 0
                    ? _WgIssuesList(
                        query: _searchQuery,
                        apiFilters: _filters[0].toQuery(),
                        selection: _filters[0],
                      )
                    : _IssuesMatrixList(
                        query: _searchQuery,
                        apiFilters: _filters[1].toQuery(),
                        selection: _filters[1],
                      ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterButton extends StatelessWidget {
  const _FilterButton({required this.activeCount, required this.onTap});

  final int activeCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(7),
      child: Container(
        height: 38,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isDark ? AppColors.darkBorder : const Color(0xFFE3E7EC),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              AppLocalizations.of(context).text('filter'),
              style: const TextStyle(
                color: AppColors.mutedText,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (activeCount > 0) ...[
              const SizedBox(width: 6),
              Container(
                constraints: const BoxConstraints(minWidth: 18),
                height: 18,
                padding: const EdgeInsets.symmetric(horizontal: 5),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.accent(context),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Text(
                  '$activeCount',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
            const SizedBox(width: 7),
            Icon(
              Icons.filter_list,
              color: Theme.of(context).colorScheme.onSurface,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }
}

class _IssueTabs extends StatelessWidget {
  const _IssueTabs({required this.selectedIndex, required this.onSelected});

  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
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
                          : Icons.event_note_outlined,
                      color: selectedIndex == index
                          ? Colors.white
                          : AppColors.mutedText,
                      size: 15,
                    ),
                    const SizedBox(width: 5),
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

class _IssueMetricGrid extends StatelessWidget {
  const _IssueMetricGrid({this.summary});

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
        _IssueMetricCard(
          label: l10n.text('totalIssues'),
          value: summary == null ? '20' : '${summary!.totalIssues}',
          background: const Color(0xFFDDEEFF),
          icon: Icons.library_books_outlined,
        ),
        _IssueMetricCard(
          label: l10n.text('solved'),
          value: summary == null
              ? '15/20'
              : '${summary!.solved}/${summary!.totalIssues}',
          background: const Color(0xFFE5FAEF),
          icon: Icons.fact_check_outlined,
        ),
        _IssueMetricCard(
          label: l10n.text('inProgress'),
          value: summary == null
              ? '4/20'
              : '${summary!.inProgress}/${summary!.totalIssues}',
          background: const Color(0xFFFFF8DC),
          icon: Icons.add_box_outlined,
        ),
        _IssueMetricCard(
          label: l10n.text('notAddressed'),
          value: summary == null
              ? '1/20'
              : '${summary!.notAddressed}/${summary!.totalIssues}',
          background: const Color(0xFFFFEEEE),
          icon: Icons.assignment_late_outlined,
        ),
      ],
    );
  }
}

class _IssueMetricCard extends StatelessWidget {
  const _IssueMetricCard({
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

class _WgIssuesList extends StatelessWidget {
  const _WgIssuesList({
    this.query = '',
    this.apiFilters = const {},
    this.selection,
  });
  final Map<String, String> apiFilters;
  final FilterSelection? selection;
  final String query;
  @override
  Widget build(BuildContext context) => WgIssuesList(
    query: query,
    apiFilters: apiFilters,
    selection: selection,
    itemBuilder: (issue) => _IssueCard(
      title: issue.title,
      category: issue.category.isEmpty ? '—' : issue.category,
      status: _statusForIssue(issue),
      issue: issue,
    ),
  );
}

_IssueCardStatus _statusForIssue(WorkingGroupIssue issue) =>
    switch (issue.statusCode.toUpperCase()) {
      'SOLVED' => _IssueCardStatus.solved,
      'IN_PROGRESS' => _IssueCardStatus.inProgress,
      _ => _IssueCardStatus.notAddressed,
    };

class _IssuesMatrixList extends StatelessWidget {
  const _IssuesMatrixList({
    this.query = '',
    this.apiFilters = const {},
    this.selection,
  });
  final Map<String, String> apiFilters;
  final FilterSelection? selection;

  final String query;

  @override
  Widget build(BuildContext context) => WgIssuesList(
    matrix: true,
    query: query,
    apiFilters: apiFilters,
    selection: selection,
    itemBuilder: (issue) => _IssueCard(
      title: issue.title,
      category: issue.category.isEmpty ? '—' : issue.category,
      status: _statusForIssue(issue),
      issue: issue,
    ),
  );
}

enum _IssueCardStatus { solved, inProgress, notAddressed }

class _IssueCard extends StatelessWidget {
  const _IssueCard({
    required this.title,
    required this.category,
    required this.status,
    this.issue,
  });

  final WorkingGroupIssue? issue;
  final String title;
  final String category;
  final _IssueCardStatus status;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => IssueDetailScreen(
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
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
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
                Container(
                  width: 32,
                  height: 32,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [Color(0xFF1E73BE), Color(0xFF1EA45B)],
                    ),
                  ),
                  child: const Icon(
                    Icons.account_balance,
                    color: Colors.white,
                    size: 17,
                  ),
                ),
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
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        category,
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                _IssueStatusBadge(
                  status: status,
                  label: issue == null
                      ? null
                      : issueStatusLabel(context, issue!),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _IssueMeta(
                    icon: Icons.calendar_month_outlined,
                    label: AppLocalizations.of(context).text('submissionDate'),
                    value: issue == null
                        ? 'July 24, 2025'
                        : issueDate(context, issue!.createdAt),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _IssueMeta(
                    icon: Icons.person_outline,
                    label: AppLocalizations.of(context).text('submittedBy'),
                    value: issue == null
                        ? 'Agriculture and Agro...'
                        : (issue!.submittedBy.isEmpty
                              ? '—'
                              : issue!.submittedBy),
                    iconColor: const Color(0xFFB642FF),
                    iconBackground: const Color(0xFFF2DDFF),
                  ),
                ),
              ],
            ),
            const Divider(height: 18),
            Text(
              issue == null
                  ? 'The private sector said that the Economic Land Concession (ELCs), which invest in rubber, cashew, plantations, etc., are now fully developed and som...'
                  : issue!.description,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: AppColors.secondaryText(context),
                fontSize: 12,
                height: 1.35,
                fontWeight: FontWeight.w500,
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
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkCard : Colors.white,
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
                      issue == null
                          ? AppLocalizations.of(context).text('twoAttachments')
                          : '${issue!.attachmentCount} ${AppLocalizations.of(context).text('attachmentsLabel')}',
                      style: const TextStyle(
                        color: Color(0xFF4C5563),
                        fontSize: 12,
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

class _IssueMeta extends StatelessWidget {
  const _IssueMeta({
    required this.icon,
    required this.label,
    required this.value,
    this.iconColor = AppColors.primary,
    this.iconBackground = const Color(0xFFDDEEFF),
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

class _IssueStatusBadge extends StatelessWidget {
  const _IssueStatusBadge({required this.status, this.label});

  final _IssueCardStatus status;
  final String? label;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final config = switch (status) {
      _IssueCardStatus.solved => (
        label: l10n.text('solved'),
        color: isDark ? const Color(0xFF86EFAC) : const Color(0xFF16A34A),
        background: isDark ? const Color(0xFF123B2A) : const Color(0xFFEAFBF0),
        border: isDark ? const Color(0xFF166534) : const Color(0xFF6EE7A0),
      ),
      _IssueCardStatus.inProgress => (
        label: l10n.text('inProgress'),
        color: isDark ? const Color(0xFFFBBF24) : const Color(0xFFFF8A00),
        background: isDark ? const Color(0xFF423415) : const Color(0xFFFFF6E8),
        border: isDark ? const Color(0xFF92400E) : const Color(0xFFFFC166),
      ),
      _IssueCardStatus.notAddressed => (
        label: l10n.text('notAddressed'),
        color: isDark ? const Color(0xFFD1D5DB) : const Color(0xFF6B7280),
        background: isDark ? const Color(0xFF222835) : const Color(0xFFF3F4F6),
        border: isDark ? const Color(0xFF4B5563) : const Color(0xFFD1D5DB),
      ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: config.background,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: config.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              color: config.color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            label ?? config.label,
            style: TextStyle(
              color: config.color,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
