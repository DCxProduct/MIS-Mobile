import '../../../core/app_settings.dart';
import '../../../core/widgets/filters/api_filter_sheet.dart';
import '../../../core/widgets/filters/api_filter_scope.dart';
import 'package:flutter/material.dart';

import '../../../core/app_colors.dart';
import '../../shared/dashboard/data/dashboard_repository.dart';
import '../../shared/dashboard/widgets/pswg_live_dashboard.dart';
import '../../private_sector/dashboard/tabs/agencies_tab.dart';
import '../../private_sector/dashboard/tabs/categories_tab.dart';
import '../../private_sector/dashboard/tabs/overall_tab.dart';
import '../../private_sector/dashboard/tabs/working_group_tab.dart';
import '../../../screens/report/plenary_detail_screen.dart';
import '../../../screens/report/rgc_decision_detail_screen.dart';
import '../../../screens/report/tabs/report_progress_report_tab.dart';
import '../../../features/shared/meetings/data/plenary.dart';
import '../../../features/shared/meetings/widgets/plenaries_loader.dart';
import '../../../features/shared/meetings/widgets/rgc_decisions_loader.dart';
import '../../../translations/app_language.dart';
import '../../../translations/app_localizations.dart';

class LineMinistryReportsScreenView extends StatefulWidget {
  const LineMinistryReportsScreenView({super.key});

  @override
  State<LineMinistryReportsScreenView> createState() =>
      _LineMinistryReportsScreenViewState();
}

class _LineMinistryReportsScreenViewState
    extends State<LineMinistryReportsScreenView> {
  int _selectedTab = 0;

  final _filters = List.generate(4, (_) => FilterSelection());
  static const _resources = [
    'progress-reports',
    'dashboard',
    'plenaries',
    'rgc-decisions',
  ];
  Future<void> _openFilters() async {
    final tab = _selectedTab;
    final catalogs = AppSettings.of(context).filters;
    final result = await Navigator.of(context).push<FilterSelection>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => ApiFilterSheet(
          initial: _filters[tab],
          load: switch (tab) {
            0 => catalogs.progressReports,
            1 => () => catalogs.dashboard('plenary'),
            2 => catalogs.plenaries,
            _ => catalogs.rgc,
          },
        ),
      ),
    );
    if (!mounted || result == null) return;
    setState(() => _filters[tab] = result);
  }

  int get _activeFilterCount => _filters[_selectedTab].count;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final contentBackground = isDark
        ? AppColors.darkBackground
        : const Color(0xFFF7F7F8);
    final headerBackground = isDark ? AppColors.darkBackground : Colors.white;

    final topPadding = MediaQuery.of(context).viewPadding.top;

    return ApiFilterScope(
      selections: {for (var i = 0; i < _filters.length; i++) _resources[i]: _filters[i]},
      queries: {
        for (var i = 0; i < _filters.length; i++)
          _resources[i]: _filters[i].toQuery(),
      },
      child: ColoredBox(
        color: contentBackground,
        child: Column(
          children: [
            // STICKY HEADER
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
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          AppLocalizations.of(context).text('report'),
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface,
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      _FilterButton(
                        activeCount: _activeFilterCount,
                        onTap: _openFilters,
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  _ReportTabs(
                    selectedIndex: _selectedTab,
                    onSelected: (index) => setState(() => _selectedTab = index),
                  ),
                ],
              ),
            ),
            // SCROLLABLE CONTENT
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 96),
                children: [
                  if (_selectedTab == 0)
                    const ReportProgressReportTab()
                  else if (_selectedTab == 1) ...const [
                    _ReportDashboardTab(),
                  ] else if (_selectedTab == 2) ...const [
                    _PlenaryTab(),
                  ] else ...const [_RgcDecisionTab()],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RgcDecisionTab extends StatelessWidget {
  const _RgcDecisionTab();

  @override
  Widget build(BuildContext context) {
    return RgcDecisionsLoader(
      builder: (decisions) => Column(
        children: [
          for (final decision in decisions)
            _RgcDecisionCard(
              agencyName: decision.agencyName,
              status: decision.status,
              meetingDate: decision.meetingDate == null
                  ? '—'
                  : MaterialLocalizations.of(
                      context,
                    ).formatMediumDate(decision.meetingDate!.toLocal()),
              category: decision.category,
              focalPerson: decision.focalPerson,
              linkCount: '${decision.linkCount} Link',
            ),
        ],
      ),
    );
  }
}

class _RgcDecisionCard extends StatelessWidget {
  const _RgcDecisionCard({
    required this.agencyName,
    required this.status,
    required this.meetingDate,
    required this.category,
    required this.focalPerson,
    required this.linkCount,
  });

  final String agencyName;
  final String status;
  final String meetingDate;
  final String category;
  final String focalPerson;
  final String linkCount;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context);
    final isKhmer = l10n.language == AppLanguage.khmer;
    final translatedStatus = status == 'In Progress'
        ? l10n.text('inProgress')
        : (status == 'Solved'
              ? l10n.text('solved')
              : l10n.text('notAddressed'));

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: const BoxDecoration(
                      color: Color(0xFF1E73BE),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.account_balance_outlined,
                      color: Colors.white,
                      size: 14,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    agencyName,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF3E2312)
                      : const Color(0xFFFFF3E0),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: isDark
                        ? const Color(0xFFC2410C)
                        : const Color(0xFFFFCC80),
                  ),
                ),
                child: Text(
                  translatedStatus,
                  style: TextStyle(
                    color: isDark
                        ? const Color(0xFFFB923C)
                        : const Color(0xFFF97316),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _ReportRow(label: l10n.text('meetingDate'), value: meetingDate),
          const SizedBox(height: 8),
          _ReportRow(label: l10n.text('categories'), value: category),
          const SizedBox(height: 8),
          _ReportRow(
            label: isKhmer ? 'មន្ត្រីសម្របសម្រួល' : 'Focal Person (H.E)',
            value: focalPerson,
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkCard : const Color(0xFFFAFAFA),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: isDark ? AppColors.darkBorder : const Color(0xFFE5E8ED),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.link, color: Color(0xFF4C5563), size: 14),
                const SizedBox(width: 6),
                Text(
                  linkCount == '2 Link'
                      ? (isKhmer ? '2 តំណភ្ជាប់' : '2 Link')
                      : linkCount,
                  style: const TextStyle(
                    color: Color(0xFF4C5563),
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 36,
            child: FilledButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) =>
                        RgcDecisionDetailScreen(agencyName: agencyName),
                  ),
                );
              },
              style: FilledButton.styleFrom(
                backgroundColor: isDark
                    ? AppColors.accent(context).withValues(alpha: 0.18)
                    : const Color(0xFFF0F7FF),
                foregroundColor: AppColors.accent(context),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    l10n.text('viewDetails'),
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                  SizedBox(width: 4),
                  Icon(Icons.chevron_right, size: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PlenaryTab extends StatelessWidget {
  const _PlenaryTab();

  @override
  Widget build(BuildContext context) {
    return PlenariesLoader(
      builder: (plenaries) => Column(
        children: [
          for (final plenary in plenaries)
            _PlenaryCard(
              title: plenary.name,
              status: plenary.status,
              meetingDate: _formatDate(context, plenary.meetingDate),
              numberOfRgcDecision: '${plenary.numberOfRgcDecisions}',
              deadline: _formatDate(context, plenary.deadline),
              attachmentCount: _attachmentLabel(context, plenary),
            ),
        ],
      ),
    );
  }

  static String _formatDate(BuildContext context, DateTime? value) {
    if (value == null) return '-';
    return MaterialLocalizations.of(context).formatMediumDate(value.toLocal());
  }

  static String _attachmentLabel(BuildContext context, Plenary plenary) {
    if (plenary.attachmentCount == 2) return '2 Attachement';
    return '${plenary.attachmentCount} ${AppLocalizations.of(context).text('attachmentsLabel')}';
  }
}

class _PlenaryCard extends StatelessWidget {
  const _PlenaryCard({
    required this.title,
    required this.status,
    required this.meetingDate,
    required this.numberOfRgcDecision,
    required this.deadline,
    required this.attachmentCount,
  });

  final String title;
  final String status;
  final String meetingDate;
  final String numberOfRgcDecision;
  final String deadline;
  final String attachmentCount;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context);
    final translatedStatus = status == 'Sent' ? l10n.text('sent') : status;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF123B2A)
                      : const Color(0xFFEAFBF0),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: isDark
                        ? const Color(0xFF166534)
                        : const Color(0xFF9BE2B4),
                  ),
                ),
                child: Text(
                  translatedStatus,
                  style: TextStyle(
                    color: isDark
                        ? const Color(0xFF86EFAC)
                        : const Color(0xFF16A34A),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _ReportRow(label: l10n.text('meetingDate'), value: meetingDate),
          const SizedBox(height: 8),
          _ReportRow(
            label: l10n.text('rgcDecision'),
            value: numberOfRgcDecision,
          ),
          const SizedBox(height: 8),
          _ReportRow(label: l10n.text('deadline'), value: deadline),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkCard : const Color(0xFFFAFAFA),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: isDark ? AppColors.darkBorder : const Color(0xFFE5E8ED),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.link, color: Color(0xFF4C5563), size: 14),
                const SizedBox(width: 6),
                Text(
                  attachmentCount == '2 Attachement'
                      ? l10n.text('twoAttachments')
                      : attachmentCount,
                  style: const TextStyle(
                    color: Color(0xFF4C5563),
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 36,
            child: FilledButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => PlenaryDetailScreen(title: title),
                  ),
                );
              },
              style: FilledButton.styleFrom(
                backgroundColor: isDark
                    ? AppColors.accent(context).withValues(alpha: 0.18)
                    : const Color(0xFFF0F7FF),
                foregroundColor: AppColors.accent(context),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    l10n.text('viewDetails'),
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                  SizedBox(width: 4),
                  Icon(Icons.chevron_right, size: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Kept for the legacy report layout used by older saved screens.
// ignore: unused_element
class _ProgressReportCard extends StatelessWidget {
  const _ProgressReportCard({
    required this.title,
    required this.year,
    required this.deadline,
    required this.firstMeeting,
    required this.secondDeadline,
    required this.secondMeeting,
  });

  final String title;
  final String year;
  final String deadline;
  final String firstMeeting;
  final String secondDeadline;
  final String secondMeeting;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context);
    final isKhmer = l10n.language == AppLanguage.khmer;
    final translatedTitle = title == 'Semester 2'
        ? (isKhmer ? 'ឆមាសទី ២' : 'Semester 2')
        : title;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
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
            children: [
              Text(
                translatedTitle,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF3B2352)
                      : const Color(0xFFF5E8FF),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  year,
                  style: TextStyle(
                    color: isDark
                        ? const Color(0xFFD8B4FE)
                        : const Color(0xFF9333EA),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _ReportRow(label: l10n.text('deadline'), value: deadline),
          const SizedBox(height: 8),
          _ReportRow(
            label: isKhmer ? 'កិច្ចប្រជុំលើកទី១' : '1st Meeting',
            value: firstMeeting,
          ),
          const SizedBox(height: 8),
          _ReportRow(
            label: isKhmer ? 'កាលបរិច្ឆេទកំណត់លើកទី២' : '2nd Deadline',
            value: secondDeadline,
          ),
          const SizedBox(height: 8),
          _ReportRow(
            label: isKhmer ? 'កិច្ចប្រជុំលើកទី២' : '2nd Meeting',
            value: secondMeeting,
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 36,
            child: FilledButton(
              onPressed: () {},
              style: FilledButton.styleFrom(
                backgroundColor: isDark
                    ? AppColors.accent(context).withValues(alpha: 0.18)
                    : const Color(0xFFF0F7FF),
                foregroundColor: AppColors.accent(context),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    l10n.text('viewDetails'),
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                  SizedBox(width: 4),
                  Icon(Icons.chevron_right, size: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReportRow extends StatelessWidget {
  const _ReportRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppColors.mutedText,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _ReportDashboardTab extends StatefulWidget {
  const _ReportDashboardTab();

  @override
  State<_ReportDashboardTab> createState() => _ReportDashboardTabState();
}

class _ReportDashboardTabState extends State<_ReportDashboardTab> {
  int _selectedFilter = 0;

  static const _agenciesItems = [
    '1. Adjusting business and investment climate',
    '10. Construction and real estate sector',
    '11. Other issues',
    '2. Easing the burden on compliance',
    '3. Facilitation of businesses under tax authorities',
    '5. Improving transportation and infrastructure',
    '9. Mining and energy sector',
    '7. (A) Agricultural and agro-industrial development',
    '4. Trade facilitation under customs jurisdiction',
  ];

  static const _workingGroupItems = [
    '(A) Agriculture and Agro-Industry',
    '(E) Banking and Financial Services',
    '(M) Construction and Real Estate',
    '(J) Energy and Mineral Resources',
    '(G) Export Processing and Trade Facilitation',
    '(H) Industrial Relations',
    '(I) Rice and Paddy',
    '(B) Tourism',
    '(F) Transportation and Infrastructure',
  ];

  @override
  Widget build(BuildContext context) {
    return PswgDataLoader(
      scope: DashboardScope.plenary,
      builder: _buildContent,
    );
  }

  Widget _buildContent(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cards = PswgDataScope.maybeOf(context)?.cards;
    final totalIssues = cards?['totalIssues'] ?? 179;
    final solved = cards?['solved'] ?? 166;
    final inProgress = cards?['inProgress'] ?? 13;
    final notAddressed = cards?['notAddressed'] ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GridView.count(
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
              value: '$totalIssues',
              background: const Color(0xFFDDEEFF),
              icon: Icons.library_books_outlined,
            ),
            _MetricCard(
              label: l10n.text('solved'),
              value: '$solved/$totalIssues',
              background: const Color(0xFFE5FAEF),
              icon: Icons.fact_check_outlined,
            ),
            _MetricCard(
              label: l10n.text('inProgress'),
              value: '$inProgress/$totalIssues',
              background: const Color(0xFFFFF8DC),
              icon: Icons.add_box_outlined,
            ),
            _MetricCard(
              label: l10n.text('notAddressed'),
              value: '$notAddressed/$totalIssues',
              background: const Color(0xFFFFEEEE),
              icon: Icons.assignment_late_outlined,
            ),
          ],
        ),
        const SizedBox(height: 12),
        _TotalPrimaryAgenciesCard(
          value: '${cards?['totalPrimaryAgencies'] ?? 14}',
        ),
        const SizedBox(height: 16),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _SubFilterChip(
                label: l10n.text('overall'),
                selected: _selectedFilter == 0,
                onTap: () => setState(() => _selectedFilter = 0),
              ),
              const SizedBox(width: 8),
              _SubFilterChip(
                label: l10n.text('agencies'),
                selected: _selectedFilter == 1,
                onTap: () => setState(() => _selectedFilter = 1),
              ),
              const SizedBox(width: 8),
              _SubFilterChip(
                label: l10n.text('workingGroup'),
                selected: _selectedFilter == 2,
                onTap: () => setState(() => _selectedFilter = 2),
              ),
              const SizedBox(width: 8),
              _SubFilterChip(
                label: l10n.text('categories'),
                selected: _selectedFilter == 3,
                onTap: () => setState(() => _selectedFilter = 3),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        switch (_selectedFilter) {
          1 => const AgenciesTab(),
          2 => const WorkingGroupTab(),
          3 => const CategoriesTab(),
          _ => const OverallTab(),
        },
      ],
    );
  }

  // Legacy layout retained for compatibility with existing saved screens.
  // ignore: unused_element
  Widget _buildLegacyContent(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context);
    final cards = PswgDataScope.maybeOf(context)?.cards;
    final totalIssues = cards?['totalIssues'] ?? 179;
    final solved = cards?['solved'] ?? 166;
    final inProgress = cards?['inProgress'] ?? 13;
    final notAddressed = cards?['notAddressed'] ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GridView.count(
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
              value: '$totalIssues',
              background: Color(0xFFDDEEFF),
              icon: Icons.library_books_outlined,
            ),
            _MetricCard(
              label: l10n.text('solved'),
              value: '$solved/$totalIssues',
              background: Color(0xFFE5FAEF),
              icon: Icons.fact_check_outlined,
            ),
            _MetricCard(
              label: l10n.text('inProgress'),
              value: '$inProgress/$totalIssues',
              background: Color(0xFFFFF8DC),
              icon: Icons.add_box_outlined,
            ),
            _MetricCard(
              label: l10n.text('notAddressed'),
              value: '$notAddressed/$totalIssues',
              background: Color(0xFFFFEEEE),
              icon: Icons.assignment_late_outlined,
            ),
          ],
        ),
        const SizedBox(height: 12),
        _TotalPrimaryAgenciesCard(
          value: '${cards?['totalPrimaryAgencies'] ?? 14}',
        ),
        const SizedBox(height: 16),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _SubFilterChip(
                label: l10n.text('overall'),
                selected: _selectedFilter == 0,
                onTap: () => setState(() => _selectedFilter = 0),
              ),
              const SizedBox(width: 8),
              _SubFilterChip(
                label: l10n.text('agencies'),
                selected: _selectedFilter == 1,
                onTap: () => setState(() => _selectedFilter = 1),
              ),
              const SizedBox(width: 8),
              _SubFilterChip(
                label: l10n.text('workingGroup'),
                selected: _selectedFilter == 2,
                onTap: () => setState(() => _selectedFilter = 2),
              ),
              const SizedBox(width: 8),
              _SubFilterChip(
                label: l10n.text('categories'),
                selected: _selectedFilter == 3,
                onTap: () => setState(() => _selectedFilter = 3),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        if (_selectedFilter == 1) ...[
          _AgenciesListCard(
            title: l10n.text('agencies'),
            items: _agenciesItems,
          ),
        ] else if (_selectedFilter == 2) ...[
          _AgenciesListCard(
            title: l10n.text('workingGroup'),
            items: _workingGroupItems,
          ),
        ] else if (_selectedFilter == 3) ...const [
          _CategoriesOfIssuesCard(),
        ] else ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkCard : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark ? AppColors.darkBorder : const Color(0xFFE5E8ED),
              ),
            ),
            child: Column(
              children: [
                DonutChartWidget(
                  slices: const [
                    DonutChartData(
                      percentage: 0.9273,
                      color: Color(0xFF10B981),
                      label: 'Solved',
                    ),
                    DonutChartData(
                      percentage: 0.0727,
                      color: Color(0xFFF59E0B),
                      label: 'In Progress',
                    ),
                  ],
                  centerTitle: l10n.text('totalIssues'),
                  centerValue: '179',
                  badge1Text: '92.73%',
                  badge1DotColor: Color(0xFF10B981),
                  badge2Text: '7.27%',
                  badge2DotColor: Color(0xFFF59E0B),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.square,
                          color: Color(0xFF10B981),
                          size: 10,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          l10n.text('solved'),
                          style: const TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                    Text(
                      '(166)',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.square,
                          color: Color(0xFFF59E0B),
                          size: 10,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          l10n.text('inProgress'),
                          style: const TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                    Text(
                      '(13)',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            l10n.text('overallStatus'),
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkCard : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark ? AppColors.darkBorder : const Color(0xFFE5E8ED),
              ),
            ),
            child: Column(
              children: [
                DonutChartWidget(
                  slices: const [
                    DonutChartData(
                      percentage: 0.923,
                      color: Color(0xFFF97316),
                      label: 'Mid Progress',
                    ),
                    DonutChartData(
                      percentage: 0.077,
                      color: Color(0xFFFDE68A),
                      label: 'Early Progress',
                    ),
                  ],
                  centerTitle: l10n.text('inProgress'),
                  centerValue: '179',
                  badge1Text: '7.7%',
                  badge1DotColor: Color(0xFF10B981),
                  badge2Text: '92.3%',
                  badge2DotColor: Color(0xFFF59E0B),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    Row(
                      children: [
                        Icon(Icons.square, color: Color(0xFFF97316), size: 10),
                        SizedBox(width: 6),
                        Text('Mid Progress', style: TextStyle(fontSize: 12)),
                      ],
                    ),
                    Text(
                      '(165)',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    Row(
                      children: [
                        Icon(Icons.square, color: Color(0xFFFDE68A), size: 10),
                        SizedBox(width: 6),
                        Text('Early Progress', style: TextStyle(fontSize: 12)),
                      ],
                    ),
                    Text(
                      '(14)',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _CategoryProgressBarRow extends StatelessWidget {
  const _CategoryProgressBarRow({
    required this.agencyName,
    required this.solvedCount,
    required this.inProgressCount,
  });

  final String agencyName;
  final int solvedCount;
  final int inProgressCount;

  @override
  Widget build(BuildContext context) {
    final total = solvedCount + inProgressCount;
    final solvedFlex = total > 0 ? (solvedCount * 100 ~/ total) : 0;
    final inProgressFlex = total > 0 ? 100 - solvedFlex : 100;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              agencyName,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
            Row(
              children: [
                if (solvedCount > 0)
                  SizedBox(
                    width: 32,
                    child: Text(
                      '$solvedCount',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: AppColors.mutedText,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                if (inProgressCount > 0)
                  SizedBox(
                    width: 32,
                    child: Text(
                      '$inProgressCount',
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                        color: AppColors.mutedText,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: SizedBox(
            height: 8,
            width: double.infinity,
            child: Row(
              children: [
                if (solvedCount > 0)
                  Expanded(
                    flex: solvedFlex > 0 ? solvedFlex : 1,
                    child: Container(color: const Color(0xFF10B981)),
                  ),
                if (solvedCount > 0 && inProgressCount > 0)
                  const SizedBox(width: 3),
                if (inProgressCount > 0)
                  Expanded(
                    flex: inProgressFlex > 0 ? inProgressFlex : 1,
                    child: Container(color: const Color(0xFFF97316)),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _CategoriesOfIssuesCard extends StatelessWidget {
  const _CategoriesOfIssuesCard();

  static const _categoryData = [
    (name: 'SHV Admin', solved: 3, inProgress: 3),
    (name: 'MPWT', solved: 0, inProgress: 1),
    (name: 'MME', solved: 4, inProgress: 3),
    (name: 'MISTI', solved: 3, inProgress: 3),
    (name: 'CDC', solved: 3, inProgress: 3),
    (name: 'MOL', solved: 3, inProgress: 3),
    (name: 'NBC', solved: 3, inProgress: 3),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context).text('categoriesOfIssues'),
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkCard : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark ? AppColors.darkBorder : const Color(0xFFE5E8ED),
            ),
          ),
          child: ListView.separated(
            shrinkWrap: true,
            padding: const EdgeInsets.all(16),
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _categoryData.length,
            separatorBuilder: (_, _) => const SizedBox(height: 14),
            itemBuilder: (context, index) {
              final item = _categoryData[index];
              return _CategoryProgressBarRow(
                agencyName: item.name,
                solvedCount: item.solved,
                inProgressCount: item.inProgress,
              );
            },
          ),
        ),
      ],
    );
  }
}

class _MiniBarChart extends StatelessWidget {
  const _MiniBarChart();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 18,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Container(
            width: 3.5,
            height: 8,
            decoration: BoxDecoration(
              color: const Color(0xFFF97316),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 3),
          Container(
            width: 3.5,
            height: 11,
            decoration: BoxDecoration(
              color: const Color(0xFFEF4444),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 3),
          Container(
            width: 3.5,
            height: 16,
            decoration: BoxDecoration(
              color: const Color(0xFF10B981),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ],
      ),
    );
  }
}

class _AgenciesListCard extends StatelessWidget {
  const _AgenciesListCard({required this.title, required this.items});

  final String title;
  final List<String> items;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkCard : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark ? AppColors.darkBorder : const Color(0xFFE5E8ED),
            ),
          ),
          child: ListView.separated(
            shrinkWrap: true,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            physics: const NeverScrollableScrollPhysics(),
            itemCount: items.length,
            separatorBuilder: (_, _) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Divider(
                height: 1,
                color: isDark ? AppColors.darkBorder : const Color(0xFFF0F2F5),
              ),
            ),
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        items[index],
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    const _MiniBarChart(),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class DonutChartData {
  const DonutChartData({
    required this.percentage,
    required this.color,
    required this.label,
  });

  final double percentage;
  final Color color;
  final String label;
}

class DonutChartWidget extends StatelessWidget {
  const DonutChartWidget({
    super.key,
    required this.slices,
    required this.centerTitle,
    required this.centerValue,
    required this.badge1Text,
    required this.badge1DotColor,
    required this.badge2Text,
    required this.badge2DotColor,
    this.startAngle = 0.85,
  });

  final List<DonutChartData> slices;
  final String centerTitle;
  final String centerValue;
  final String badge1Text;
  final Color badge1DotColor;
  final String badge2Text;
  final Color badge2DotColor;
  final double startAngle;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 185,
      width: 240,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: const Size(165, 165),
            painter: _DonutChartPainter(slices: slices, startAngle: startAngle),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                centerTitle,
                style: const TextStyle(
                  color: AppColors.mutedText,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                centerValue,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          Positioned(
            top: 26,
            left: 6,
            child: _PercentageBadge(
              percentText: badge1Text,
              dotColor: badge1DotColor,
            ),
          ),
          Positioned(
            bottom: 24,
            right: 6,
            child: _PercentageBadge(
              percentText: badge2Text,
              dotColor: badge2DotColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _DonutChartPainter extends CustomPainter {
  _DonutChartPainter({required this.slices, required this.startAngle});

  final List<DonutChartData> slices;
  final double startAngle;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    const strokeWidth = 26.0;
    final radius = (size.width - strokeWidth) / 2;
    const gapAngle = 0.045;

    double currentAngle = startAngle;

    for (final slice in slices) {
      if (!slice.percentage.isFinite || slice.percentage <= 0) continue;
      final totalSweep = slice.percentage * 2 * 3.141592653589793;
      final effectiveGap = totalSweep < gapAngle ? 0.0 : gapAngle;
      final drawSweep = totalSweep - effectiveGap;

      final paint = Paint()
        ..color = slice.color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.butt;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        currentAngle + effectiveGap / 2,
        drawSweep,
        false,
        paint,
      );

      currentAngle += totalSweep;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutChartPainter oldDelegate) => true;
}

class _PercentageBadge extends StatelessWidget {
  const _PercentageBadge({required this.percentText, required this.dotColor});

  final String percentText;
  final Color dotColor;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(6),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(
          color: isDark ? AppColors.darkBorder : const Color(0xFFE5E8ED),
          width: 0.8,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 5,
            height: 5,
            decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
          ),
          const SizedBox(width: 5),
          Text(
            percentText,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _SubFilterChip extends StatelessWidget {
  const _SubFilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.accent(context)
              : (isDark ? AppColors.darkCard : Colors.white),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: selected
                ? AppColors.accent(context)
                : (isDark ? AppColors.darkBorder : const Color(0xFFE2E7ED)),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected
                ? Colors.white
                : (isDark
                      ? AppColors.secondaryText(context)
                      : const Color(0xFF4C5563)),
            fontSize: 12,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
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
        height: 36,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : Colors.white,
          borderRadius: BorderRadius.circular(7),
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

class _ReportTabs extends StatelessWidget {
  const _ReportTabs({required this.selectedIndex, required this.onSelected});

  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context);
    final tabs = [
      (icon: Icons.calendar_month_outlined, label: l10n.text('progressReport')),
      (icon: Icons.add_box_outlined, label: l10n.text('dashboard')),
      (icon: Icons.calendar_month_outlined, label: l10n.text('plenary')),
      (icon: Icons.assignment_outlined, label: l10n.text('rgcDecision')),
    ];

    return Container(
      height: 42,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkBackground : Colors.white,
        borderRadius: BorderRadius.circular(9),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : const Color(0xFFE8EBF0),
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: List.generate(tabs.length, (index) {
            final isSelected = selectedIndex == index;
            return Padding(
              padding: const EdgeInsets.only(right: 4),
              child: InkWell(
                onTap: () => onSelected(index),
                borderRadius: BorderRadius.circular(6),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.accent(context)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        tabs[index].icon,
                        color: isSelected ? Colors.white : AppColors.mutedText,
                        size: 15,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        tabs[index].label,
                        style: TextStyle(
                          color: isSelected
                              ? Colors.white
                              : AppColors.mutedText,
                          fontSize: 12,
                          fontWeight: isSelected
                              ? FontWeight.w700
                              : FontWeight.w600,
                        ),
                      ),
                    ],
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

class LineMinistryDashboardFilterSheet extends StatelessWidget {
  const LineMinistryDashboardFilterSheet({super.key});
  @override
  Widget build(BuildContext context) => ApiFilterSheet(
    initial: FilterSelection(),
    load: () => AppSettings.of(context).filters.dashboard('plenary'),
  );
}
