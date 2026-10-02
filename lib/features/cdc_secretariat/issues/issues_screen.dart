import '../../../core/app_settings.dart';
import '../../../core/widgets/filters/api_filter_sheet.dart';
import '../../../core/widgets/filters/api_filter_scope.dart';
import '../../shared/issues/data/working_group_issue.dart';
import '../../shared/issues/widgets/wg_issues_list.dart';
import '../../shared/issues/widgets/issue_display.dart';
import '../../shared/issues/data/wg_issue_summary.dart';
import '../../shared/issues/widgets/wg_issue_summary_loader.dart';
import '../../shared/meetings/data/rgc_decision.dart';
import '../../shared/meetings/widgets/rgc_decisions_loader.dart';
import 'package:flutter/material.dart';
import '../../../core/app_colors.dart';
import '../../../translations/app_localizations.dart';
import '../../../screens/report/rgc_decision_detail_screen.dart';
import '../../private_sector/issues/issue_detail_screen.dart';

class CdcSecretariatIssuesScreenView extends StatefulWidget {
  const CdcSecretariatIssuesScreenView({super.key});

  @override
  State<CdcSecretariatIssuesScreenView> createState() => _CdcIssuesState();
}

class _CdcIssuesState extends State<CdcSecretariatIssuesScreenView> {
  int _tab = 0;
  final _filters = [FilterSelection(), FilterSelection()];
  Future<void> _openFilters() async {
    final tab = _tab;
    final catalogs = AppSettings.of(context).filters;
    final result = await Navigator.of(context).push<FilterSelection>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => ApiFilterSheet(
          initial: _filters[tab],
          load: tab == 0
              ? () => catalogs.rgc(cdcGpsf: true)
              : () => catalogs.issues(matrix: true, cdcDesign: true),
        ),
      ),
    );
    if (!mounted || result == null) return;
    setState(() => _filters[tab] = result);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return ApiFilterScope(
      selections: {'rgc-decisions': _filters[0]},
      queries: {'rgc-decisions': _filters[0].toQuery()},
      child: ColoredBox(
        color: AppColors.isDark(context)
            ? AppColors.darkBackground
            : const Color(0xFFF7F8FA),
        child: Column(
          children: [
            Container(
              color: AppColors.cardBackground(context),
              padding: EdgeInsets.fromLTRB(
                16,
                MediaQuery.of(context).viewPadding.top + 20,
                16,
                14,
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          l10n.text('wgIssues'),
                          style: TextStyle(
                            color: AppColors.primaryText(context),
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.secondaryText(context),
                          side: BorderSide(color: AppColors.border(context)),
                          minimumSize: const Size(0, 30),
                          padding: const EdgeInsets.symmetric(horizontal: 9),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        onPressed: _openFilters,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '${l10n.text('filter')}${_filters[_tab].count > 0 ? ' (${_filters[_tab].count})' : ''}',
                              style: const TextStyle(fontSize: 12),
                            ),
                            const SizedBox(width: 5),
                            const Icon(Icons.filter_list, size: 16),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  _IssueTabs(
                    selectedIndex: _tab,
                    onSelected: (value) => setState(() => _tab = value),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                key: ValueKey(_tab),
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 100),
                children: [
                  _tab == 0
                      ? RgcDecisionScorecardLoader(
                          builder: (scorecard) =>
                              _IssueMetricGrid(scorecard: scorecard),
                        )
                      : WgIssueSummaryLoader(
                          matrix: true,
                          builder: (summary) =>
                              _IssueMetricGrid(summary: summary),
                        ),
                  const SizedBox(height: 16),
                  if (_tab == 0) ...[
                    RgcDecisionsLoader(
                      builder: (decisions) => Column(
                        children: [
                          for (final decision in decisions)
                            _DecisionCard(decision: decision),
                        ],
                      ),
                    ),
                  ] else ...[
                    WgIssuesList(
                      matrix: true,
                      apiFilters: _filters[1].toQuery(),
                      selection: _filters[1],
                      itemBuilder: (issue) => _IssueCard(issue: issue),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DecisionCard extends StatelessWidget {
  const _DecisionCard({required this.decision});

  final RgcDecision decision;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    void openDetails() => Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) =>
            RgcDecisionDetailScreen(agencyName: decision.agencyName),
      ),
    );
    final status = switch (decision.statusCode.toUpperCase()) {
      'SOLVED' => _IssueCardStatus.solved,
      'IN_PROGRESS' => _IssueCardStatus.inProgress,
      _ => _IssueCardStatus.notAddressed,
    };
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: AppColors.cardBackground(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border(context)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.primary),
                ),
                child: const Icon(
                  Icons.account_balance_outlined,
                  size: 15,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  decision.agencyName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 13),
                ),
              ),
              _IssueStatusBadge(status: status),
            ],
          ),
          const SizedBox(height: 12),
          _row(
            context,
            l10n.text('meetingDate'),
            _formatDate(decision.meetingDate),
          ),
          _row(context, l10n.text('categories'), decision.category),
          _row(context, l10n.text('focalPersonHE'), decision.focalPerson),
          Align(
            alignment: Alignment.centerLeft,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.border(context)),
                borderRadius: BorderRadius.circular(5),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.link, size: 14),
                  const SizedBox(width: 5),
                  Text(
                    '${decision.linkCount} ${l10n.text('linksLabel')}',
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: TextButton(
              onPressed: openDetails,
              style: TextButton.styleFrom(
                backgroundColor: AppColors.isDark(context)
                    ? AppColors.darkPrimaryContainer
                    : const Color(0xFFECF8FE),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(7),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    l10n.text('viewDetails'),
                    style: const TextStyle(fontSize: 13),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.chevron_right, size: 19),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _row(BuildContext context, String label, String value) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color: AppColors.secondaryText(context),
              fontSize: 13,
            ),
          ),
        ),
        Flexible(
          child: Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 13),
          ),
        ),
      ],
    ),
  );

  String _formatDate(DateTime? date) {
    if (date == null) return '—';
    return '${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}/${date.year}';
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
    final tabs = [l10n.text('rgcDecision'), l10n.text('issuesMatrix')];

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
  const _IssueMetricGrid({this.summary, this.scorecard});

  final WgIssueSummary? summary;
  final RgcDecisionScorecard? scorecard;

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
          value: scorecard == null
              ? (summary == null ? '20' : '${summary!.totalIssues}')
              : '${scorecard!.total}',
          background: const Color(0xFFDDEEFF),
          icon: Icons.library_books_outlined,
        ),
        _IssueMetricCard(
          label: l10n.text('solved'),
          value: scorecard == null
              ? (summary == null
                    ? '15/20'
                    : '${summary!.solved}/${summary!.totalIssues}')
              : '${scorecard!.solved}/${scorecard!.total}',
          background: const Color(0xFFE5FAEF),
          icon: Icons.fact_check_outlined,
        ),
        _IssueMetricCard(
          label: l10n.text('inProgress'),
          value: scorecard == null
              ? (summary == null
                    ? '4/20'
                    : '${summary!.inProgress}/${summary!.totalIssues}')
              : '${scorecard!.inProgress}/${scorecard!.total}',
          background: const Color(0xFFFFF8DC),
          icon: Icons.add_box_outlined,
        ),
        _IssueMetricCard(
          label: l10n.text('notAddressed'),
          value: scorecard == null
              ? (summary == null
                    ? '1/20'
                    : '${summary!.notAddressed}/${summary!.totalIssues}')
              : '${scorecard!.notAddressed}/${scorecard!.total}',
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

enum _IssueCardStatus { solved, inProgress, notAddressed }

class _IssueCard extends StatelessWidget {
  const _IssueCard({required this.issue});

  final WorkingGroupIssue issue;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final status = switch (issue.statusCode.toUpperCase()) {
      'SOLVED' => _IssueCardStatus.solved,
      'IN_PROGRESS' => _IssueCardStatus.inProgress,
      _ => _IssueCardStatus.notAddressed,
    };

    return InkWell(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => IssueDetailScreen(
              title: issue.title,
              category: issue.category,
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
                ClipOval(
                  child: Image.asset(
                    'assets/images/maff.jpg',
                    width: 32,
                    height: 32,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        issue.title,
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
                        issue.category.isEmpty ? '—' : issue.category,
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                _IssueStatusBadge(status: status),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _IssueMeta(
                    icon: Icons.calendar_month_outlined,
                    label: AppLocalizations.of(context).text('submissionDate'),
                    value: issueDate(context, issue.meetingDate),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _IssueMeta(
                    icon: Icons.person_outline,
                    label: AppLocalizations.of(context).text('submittedBy'),
                    value: issue.submittedBy.isEmpty ? '—' : issue.submittedBy,
                    iconColor: const Color(0xFFB642FF),
                    iconBackground: const Color(0xFFF2DDFF),
                  ),
                ),
              ],
            ),
            const Divider(height: 18),
            Text(
              issue.description.isEmpty ? '—' : issue.description,
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
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
                    '${issue.linkCount} ${AppLocalizations.of(context).text('linksLabel')}',
                    style: const TextStyle(
                      color: Color(0xFF4C5563),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
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
  const _IssueStatusBadge({required this.status});

  final _IssueCardStatus status;

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
              border: Border.all(color: config.color),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            config.label,
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
