import 'package:flutter/material.dart';

import '../../../core/app_colors.dart';
import '../../../screens/report/plenary_detail_screen.dart';
import '../../../screens/report/rgc_decision_detail_screen.dart';
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

  Set<String> _selectedProgressYears = {};
  Set<String> _selectedSemesters = {};
  Set<String> _selectedProgressStatuses = {};

  Set<String> _selectedSummaryStatuses = {};
  Set<String> _selectedSummaryYears = {};
  Set<String> _selectedSummaryIssues = {};

  Future<void> _openProgressReportFilterSheet(BuildContext context) async {
    final result = await showModalBottomSheet<_LineMinistryProgressReportFilterResult>(
      context: context,
      isScrollControlled: true,
      useSafeArea: false,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return _LineMinistryProgressReportFilterSheet(
          selectedYears: _selectedProgressYears,
          selectedSemesters: _selectedSemesters,
          selectedStatuses: _selectedProgressStatuses,
        );
      },
    );

    if (result != null) {
      setState(() {
        _selectedProgressYears = result.years;
        _selectedSemesters = result.semesters;
        _selectedProgressStatuses = result.statuses;
      });
    }
  }

  Future<void> _openMeetingSummaryFilterSheet(BuildContext context) async {
    final result = await showModalBottomSheet<_LineMinistrySummaryFilterResult>(
      context: context,
      isScrollControlled: true,
      useSafeArea: false,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return _LineMinistrySummaryFilterSheet(
          selectedStatuses: _selectedSummaryStatuses,
          selectedYears: _selectedSummaryYears,
          selectedNumberOfIssues: _selectedSummaryIssues,
        );
      },
    );

    if (result != null) {
      setState(() {
        _selectedSummaryStatuses = result.statuses;
        _selectedSummaryYears = result.years;
        _selectedSummaryIssues = result.numberOfIssues;
      });
    }
  }

  int get _activeFilterCount {
    if (_selectedTab == 0) {
      return _selectedProgressYears.length +
          _selectedSemesters.length +
          _selectedProgressStatuses.length;
    } else {
      return _selectedSummaryStatuses.length +
          _selectedSummaryYears.length +
          _selectedSummaryIssues.length;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final contentBackground = isDark
        ? AppColors.darkBackground
        : const Color(0xFFF7F7F8);
    final headerBackground = isDark ? AppColors.darkBackground : Colors.white;

    final topPadding = MediaQuery.of(context).viewPadding.top;

    return ColoredBox(
      color: contentBackground,
      child: Column(
        children: [
          // STICKY HEADER
          Container(
            color: headerBackground,
            padding: EdgeInsets.fromLTRB(14, topPadding > 0 ? topPadding + 12 : 34, 14, 12),
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
                      onTap: () {
                        if (_selectedTab == 1 || _selectedTab == 3) {
                          showModalBottomSheet<void>(
                            context: context,
                            isScrollControlled: true,
                            useSafeArea: false,
                            backgroundColor: Colors.transparent,
                            builder: (context) {
                              return const _LineMinistryDashboardFilterSheet();
                            },
                          );
                        } else if (_selectedTab == 2) {
                          showModalBottomSheet<void>(
                            context: context,
                            isScrollControlled: true,
                            useSafeArea: false,
                            backgroundColor: Colors.transparent,
                            builder: (context) {
                              return _LineMinistryPlenaryFilterSheet(
                                selectedStatuses: _selectedSummaryStatuses,
                              );
                            },
                          );
                        } else if (_selectedTab == 0) {
                          _openProgressReportFilterSheet(context);
                        } else {
                          _openMeetingSummaryFilterSheet(context);
                        }
                      },
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
                if (_selectedTab == 0) ...const [
                  _ProgressReportCard(
                    title: 'Semester 2',
                    year: '2026',
                    deadline: 'Oct 30, 2025',
                    firstMeeting: 'Jun 07, 2025',
                    secondDeadline: 'Jun 07, 2025',
                    secondMeeting: 'Jun 07, 2025',
                  ),
                  _ProgressReportCard(
                    title: 'Semester 2',
                    year: '2026',
                    deadline: 'Oct 30, 2025',
                    firstMeeting: 'Jun 07, 2025',
                    secondDeadline: 'Jun 07, 2025',
                    secondMeeting: 'Jun 07, 2025',
                  ),
                  _ProgressReportCard(
                    title: 'Semester 2',
                    year: '2026',
                    deadline: 'Oct 30, 2025',
                    firstMeeting: 'Jun 07, 2025',
                    secondDeadline: 'Jun 07, 2025',
                    secondMeeting: 'Jun 07, 2025',
                  ),
                ] else if (_selectedTab == 1) ...const [
                  _ReportDashboardTab(),
                ] else if (_selectedTab == 2) ...const [
                  _PlenaryTab(),
                ] else ...const [
                  _RgcDecisionTab(),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RgcDecisionTab extends StatelessWidget {
  const _RgcDecisionTab();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: const [
        _RgcDecisionCard(
          agencyName: 'MPWT',
          status: 'In Progress',
          meetingDate: 'Oct 30, 2025',
          category: 'Legislation',
          focalPerson: 'Peng Ponea',
          linkCount: '2 Link',
        ),
        _RgcDecisionCard(
          agencyName: 'MPWT',
          status: 'In Progress',
          meetingDate: 'Oct 30, 2025',
          category: 'Legislation',
          focalPerson: 'Peng Ponea',
          linkCount: '2 Link',
        ),
      ],
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
        : (status == 'Solved' ? l10n.text('solved') : l10n.text('notAddressed'));

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
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
                  linkCount == '2 Link' ? (isKhmer ? '2 តំណភ្ជាប់' : '2 Link') : linkCount,
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
                    builder: (_) => RgcDecisionDetailScreen(agencyName: agencyName),
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
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
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
    return Column(
      children: const [
        _PlenaryCard(
          title: '19th G-PSF. Plenary',
          status: 'Sent',
          meetingDate: 'Oct 30, 2025',
          numberOfRgcDecision: 'Jun 07, 2025',
          deadline: 'Jun 07, 2025',
          attachmentCount: '2 Attachement',
        ),
        _PlenaryCard(
          title: '18th G-PSF. Plenary',
          status: 'Sent',
          meetingDate: 'Oct 30, 2025',
          numberOfRgcDecision: 'Jun 07, 2025',
          deadline: 'Jun 07, 2025',
          attachmentCount: '2 Attachement',
        ),
      ],
    );
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
          _ReportRow(label: l10n.text('rgcDecision'), value: numberOfRgcDecision),
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
                  attachmentCount == '2 Attachement' ? l10n.text('twoAttachments') : attachmentCount,
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
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
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
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context);

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
              value: '179',
              background: Color(0xFFDDEEFF),
              icon: Icons.library_books_outlined,
            ),
            _MetricCard(
              label: l10n.text('solved'),
              value: '166/179',
              background: Color(0xFFE5FAEF),
              icon: Icons.fact_check_outlined,
            ),
            _MetricCard(
              label: l10n.text('inProgress'),
              value: '13/179',
              background: Color(0xFFFFF8DC),
              icon: Icons.add_box_outlined,
            ),
            _MetricCard(
              label: l10n.text('notAddressed'),
              value: '0/179',
              background: Color(0xFFFFEEEE),
              icon: Icons.assignment_late_outlined,
            ),
          ],
        ),
        const SizedBox(height: 12),
        const _TotalPrimaryAgenciesCard(value: '14'),
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
                        const Icon(Icons.square, color: Color(0xFF10B981), size: 10),
                        const SizedBox(width: 6),
                        Text(l10n.text('solved'), style: const TextStyle(fontSize: 12)),
                      ],
                    ),
                    Text('(166)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.square, color: Color(0xFFF59E0B), size: 10),
                        const SizedBox(width: 6),
                        Text(l10n.text('inProgress'), style: const TextStyle(fontSize: 12)),
                      ],
                    ),
                    Text('(13)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
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
                    Text('(165)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
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
                    Text('(14)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
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
  const _AgenciesListCard({
    required this.title,
    required this.items,
  });

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
            painter: _DonutChartPainter(
              slices: slices,
              startAngle: startAngle,
            ),
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
  _DonutChartPainter({
    required this.slices,
    required this.startAngle,
  });

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
      final totalSweep = slice.percentage * 2 * 3.141592653589793;
      final drawSweep = (totalSweep - gapAngle).clamp(0.01, totalSweep);

      final paint = Paint()
        ..color = slice.color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.butt;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        currentAngle + gapAngle / 2,
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
  const _PercentageBadge({
    required this.percentText,
    required this.dotColor,
  });

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
            decoration: BoxDecoration(
              color: dotColor,
              shape: BoxShape.circle,
            ),
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
  const _FilterButton({
    required this.activeCount,
    required this.onTap,
  });

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
          children: List.generate(
            tabs.length,
            (index) {
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
                          color: isSelected
                              ? Colors.white
                              : AppColors.mutedText,
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
            },
          ),
        ),
      ),
    );
  }
}

String _translateFilterLabel(String item, AppLocalizations l10n) {
  switch (item) {
    case 'Drafted':
      return l10n.text('drafted');
    case 'Submitted':
      return l10n.text('submitted');
    case 'Under Review':
      return l10n.text('underReview');
    case 'Scheduled':
      return l10n.text('scheduled');
    case 'Completed':
      return l10n.text('completed');
    case 'Solved':
      return l10n.text('solved');
    case 'In Progress':
      return l10n.text('inProgress');
    case 'Not Address':
    case 'Not Addressed':
      return l10n.text('notAddressed');
    case 'Sent':
      return l10n.text('sent');
    case 'Draft':
      return l10n.text('draft');
    default:
      return item;
  }
}

class _FilterChipCheckbox extends StatelessWidget {
  const _FilterChipCheckbox({
    required this.label,
    required this.checked,
    required this.onTap,
  });

  final String label;
  final bool checked;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context);
    final translatedLabel = _translateFilterLabel(label, l10n);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 18,
              height: 18,
              child: Checkbox(
                value: checked,
                onChanged: (_) => onTap(),
                activeColor: AppColors.accent(context),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(3),
                ),
                side: BorderSide(
                  color: isDark ? AppColors.darkBorder : const Color(0xFFCBD5E1),
                ),
              ),
            ),
            const SizedBox(width: 6),
            Text(
              translatedLabel,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LineMinistryProgressReportFilterResult {
  const _LineMinistryProgressReportFilterResult({
    required this.years,
    required this.semesters,
    required this.statuses,
  });

  final Set<String> years;
  final Set<String> semesters;
  final Set<String> statuses;
}

class _LineMinistryProgressReportFilterSheet extends StatefulWidget {
  const _LineMinistryProgressReportFilterSheet({
    required this.selectedYears,
    required this.selectedSemesters,
    required this.selectedStatuses,
  });

  final Set<String> selectedYears;
  final Set<String> selectedSemesters;
  final Set<String> selectedStatuses;

  @override
  State<_LineMinistryProgressReportFilterSheet> createState() =>
      _LineMinistryProgressReportFilterSheetState();
}

class _LineMinistryProgressReportFilterSheetState
    extends State<_LineMinistryProgressReportFilterSheet> {
  late Set<String> _statuses;
  late Set<String> _years;
  late Set<String> _numberOfIssues;

  static const _statusOptions = [
    'Drafted',
    'Submitted',
    'Under Review',
    'Scheduled',
    'Completed',
  ];

  static const _yearOptions = ['2026', '2025', '2024', '2023'];

  static const _issuesOptions = ['1', '2', '3', '4', '5'];

  @override
  void initState() {
    super.initState();
    _statuses = {...widget.selectedStatuses};
    _years = {...widget.selectedYears};
    _numberOfIssues = {...widget.selectedSemesters};
  }

  void _toggle(Set<String> set, String value) {
    setState(() {
      if (set.contains(value)) {
        set.remove(value);
      } else {
        set.add(value);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final background = isDark ? AppColors.darkBackground : Colors.white;

    final viewPadding = MediaQuery.of(context).viewPadding;
    final topInset = viewPadding.top > 48.0 ? viewPadding.top : 48.0;

    return Material(
      color: background,
      child: FractionallySizedBox(
        heightFactor: 1.0,
        child: Column(
          children: [
            // HEADER
            Container(
              padding: EdgeInsets.fromLTRB(22, topInset + 16, 22, 16),
              child: Row(
                children: [
                  const SizedBox(width: 28),
                  Expanded(
                    child: Text(
                      'Filters',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  InkWell(
                    onTap: () => Navigator.pop(context),
                    child: Icon(
                      Icons.close,
                      color: Theme.of(context).colorScheme.onSurface,
                      size: 22,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: Color(0xFFF0F2F5)),
            // FILTER SECTIONS
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 20),
                children: [
                  // SECTION 1: STATUS
                  const Text(
                    'Status',
                    style: TextStyle(
                      color: AppColors.mutedText,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 12,
                    runSpacing: 8,
                    children: _statusOptions.map((item) {
                      return _FilterChipCheckbox(
                        label: item,
                        checked: _statuses.contains(item),
                        onTap: () => _toggle(_statuses, item),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),
                  // SECTION 2: YEAR
                  const Text(
                    'Year',
                    style: TextStyle(
                      color: AppColors.mutedText,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 20,
                    runSpacing: 8,
                    children: _yearOptions.map((item) {
                      return _FilterChipCheckbox(
                        label: item,
                        checked: _years.contains(item),
                        onTap: () => _toggle(_years, item),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),
                  // SECTION 3: NUMBER OF ISSUES
                  const Text(
                    'Number of Issues',
                    style: TextStyle(
                      color: AppColors.mutedText,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 24,
                    runSpacing: 8,
                    children: _issuesOptions.map((item) {
                      return _FilterChipCheckbox(
                        label: item,
                        checked: _numberOfIssues.contains(item),
                        onTap: () => _toggle(_numberOfIssues, item),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            // APPLY BUTTON
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
              child: SizedBox(
                width: double.infinity,
                height: 46,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.accent(context),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: () {
                    Navigator.pop(
                      context,
                      _LineMinistryProgressReportFilterResult(
                        years: {..._years},
                        semesters: {..._numberOfIssues},
                        statuses: {..._statuses},
                      ),
                    );
                  },
                  child: const Text(
                    'Apply Filters',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LineMinistrySummaryFilterResult {
  const _LineMinistrySummaryFilterResult({
    required this.statuses,
    required this.years,
    required this.numberOfIssues,
  });

  final Set<String> statuses;
  final Set<String> years;
  final Set<String> numberOfIssues;
}

class _LineMinistrySummaryFilterSheet extends StatefulWidget {
  const _LineMinistrySummaryFilterSheet({
    required this.selectedStatuses,
    required this.selectedYears,
    required this.selectedNumberOfIssues,
  });

  final Set<String> selectedStatuses;
  final Set<String> selectedYears;
  final Set<String> selectedNumberOfIssues;

  @override
  State<_LineMinistrySummaryFilterSheet> createState() =>
      _LineMinistrySummaryFilterSheetState();
}

class _LineMinistrySummaryFilterSheetState
    extends State<_LineMinistrySummaryFilterSheet> {
  late Set<String> _statuses;
  late Set<String> _years;
  late Set<String> _numberOfIssues;

  static const _statusOptions = [
    'Drafted',
    'Submitted',
    'Under Review',
    'Scheduled',
    'Completed',
  ];

  static const _yearOptions = ['2026', '2025', '2024', '2023'];

  static const _issuesOptions = ['1', '2', '3', '4', '5'];

  @override
  void initState() {
    super.initState();
    _statuses = {...widget.selectedStatuses};
    _years = {...widget.selectedYears};
    _numberOfIssues = {...widget.selectedNumberOfIssues};
  }

  void _toggle(Set<String> set, String value) {
    setState(() {
      if (set.contains(value)) {
        set.remove(value);
      } else {
        set.add(value);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final background = isDark ? AppColors.darkBackground : Colors.white;

    final viewPadding = MediaQuery.of(context).viewPadding;
    final topInset = viewPadding.top > 48.0 ? viewPadding.top : 48.0;

    return Material(
      color: background,
      child: FractionallySizedBox(
        heightFactor: 1.0,
        child: Column(
          children: [
            // HEADER
            Container(
              padding: EdgeInsets.fromLTRB(22, topInset + 16, 22, 16),
              child: Row(
                children: [
                  const SizedBox(width: 28),
                  Expanded(
                    child: Text(
                      'Filters',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  InkWell(
                    onTap: () => Navigator.pop(context),
                    child: Icon(
                      Icons.close,
                      color: Theme.of(context).colorScheme.onSurface,
                      size: 22,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: Color(0xFFF0F2F5)),
            // FILTER SECTIONS
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 20),
                children: [
                  // SECTION 1: STATUS
                  const Text(
                    'Status',
                    style: TextStyle(
                      color: AppColors.mutedText,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 12,
                    runSpacing: 8,
                    children: _statusOptions.map((item) {
                      return _FilterChipCheckbox(
                        label: item,
                        checked: _statuses.contains(item),
                        onTap: () => _toggle(_statuses, item),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),
                  // SECTION 2: YEAR
                  const Text(
                    'Year',
                    style: TextStyle(
                      color: AppColors.mutedText,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 20,
                    runSpacing: 8,
                    children: _yearOptions.map((item) {
                      return _FilterChipCheckbox(
                        label: item,
                        checked: _years.contains(item),
                        onTap: () => _toggle(_years, item),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),
                  // SECTION 3: NUMBER OF ISSUES
                  const Text(
                    'Number of Issues',
                    style: TextStyle(
                      color: AppColors.mutedText,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 24,
                    runSpacing: 8,
                    children: _issuesOptions.map((item) {
                      return _FilterChipCheckbox(
                        label: item,
                        checked: _numberOfIssues.contains(item),
                        onTap: () => _toggle(_numberOfIssues, item),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            // APPLY BUTTON
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
              child: SizedBox(
                width: double.infinity,
                height: 46,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.accent(context),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: () {
                    Navigator.pop(
                      context,
                      _LineMinistrySummaryFilterResult(
                        statuses: {..._statuses},
                        years: {..._years},
                        numberOfIssues: {..._numberOfIssues},
                      ),
                    );
                  },
                  child: const Text(
                    'Apply Filters',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LineMinistryPlenaryFilterSheet extends StatefulWidget {
  const _LineMinistryPlenaryFilterSheet({
    required this.selectedStatuses,
  });

  final Set<String> selectedStatuses;

  @override
  State<_LineMinistryPlenaryFilterSheet> createState() =>
      _LineMinistryPlenaryFilterSheetState();
}

class _LineMinistryPlenaryFilterSheetState
    extends State<_LineMinistryPlenaryFilterSheet> {
  late Set<String> _statuses;

  static const _statusOptions = ['Sent', 'Draft'];

  @override
  void initState() {
    super.initState();
    _statuses = {...widget.selectedStatuses};
  }

  void _toggle(Set<String> set, String value) {
    setState(() {
      if (set.contains(value)) {
        set.remove(value);
      } else {
        set.add(value);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final background = isDark ? AppColors.darkBackground : Colors.white;

    final viewPadding = MediaQuery.of(context).viewPadding;
    final topInset = viewPadding.top > 48.0 ? viewPadding.top : 48.0;

    return Material(
      color: background,
      child: FractionallySizedBox(
        heightFactor: 1.0,
        child: Column(
          children: [
            // HEADER
            Container(
              padding: EdgeInsets.fromLTRB(22, topInset + 16, 22, 16),
              child: Row(
                children: [
                  const SizedBox(width: 28),
                  Expanded(
                    child: Text(
                      'Filters',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  InkWell(
                    onTap: () => Navigator.pop(context),
                    child: Icon(
                      Icons.close,
                      color: Theme.of(context).colorScheme.onSurface,
                      size: 22,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: Color(0xFFF0F2F5)),
            // FILTER SECTIONS
            Expanded(
              child: ListView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 22, vertical: 20),
                children: [
                  const Text(
                    'Status',
                    style: TextStyle(
                      color: AppColors.mutedText,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 24,
                    runSpacing: 8,
                    children: _statusOptions.map((item) {
                      return _FilterChipCheckbox(
                        label: item,
                        checked: _statuses.contains(item),
                        onTap: () => _toggle(_statuses, item),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            // APPLY BUTTON
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
              child: SizedBox(
                width: double.infinity,
                height: 46,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.accent(context),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: () => Navigator.pop(context, _statuses),
                  child: const Text(
                    'Apply Filters',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LineMinistryDashboardFilterSheet extends StatefulWidget {
  const _LineMinistryDashboardFilterSheet();

  @override
  State<_LineMinistryDashboardFilterSheet> createState() =>
      _LineMinistryDashboardFilterSheetState();
}

class _LineMinistryDashboardFilterSheetState
    extends State<_LineMinistryDashboardFilterSheet> {
  final Set<String> _plenaries = {};
  final Set<String> _statuses = {};
  final Set<String> _workingGroups = {};
  final Set<String> _agencies = {};
  final Set<String> _categories = {};
  final Set<String> _dates = {};

  bool _expandWorkingGroup = false;
  bool _expandAgencies = false;
  bool _expandCategories = false;
  bool _expandDates = false;

  static const _plenaryOptions = [
    '19th G-PSF Plenary',
    '20th G-PSF Plenary',
    '21st G-PSF Plenary',
    '22nd G-PSF Plenary',
  ];

  static const _statusOptions = ['Solved', 'In Progress', 'Not Address'];

  static const _workingGroupItems = [
    'Agriculture and Agro-Industry',
    'Tourism',
    'SMEs, Manufacturing, and Services',
    'Law, Tax, and Governance',
    'Banking and Financial Services',
    'Transportation and Infrastructure',
    'Export Processing and Trade Facilitation',
    'Industrial Relations',
    'Rice and Paddy',
    'Energy and Mineral Resources',
    'Education',
    'Construction and Real Estate',
    'Non-Bank Financial Services Other issues',
    'Digital Economy, Society and Telecommunication',
    'Land Administration, Security, Public Order',
  ];

  static const _agencyItems = [
    'GDT', 'MFF', 'GDCE', 'MLVT', 'MPTC',
    'MAFF', 'Moh', 'NBC', 'MoC', 'MoT',
    'MLMUPC', 'Mol', 'CDC', 'MPWT',
    'MISTI', 'MME', 'SHV Admin', 'MOC',
  ];

  static const _categoryItems = [
    'Law, Tax, and Governance',
    'Tourism',
    'Construction and Real Estate',
    'Energy and Mineral Resources',
    'Non-Bank Financial Services Other issues',
    'Industrial Relations',
    'Banking and Financial Services',
    'Agriculture and Agro-Industry',
    'Other issues',
    'SMEs, Manufacturing, and Services',
    'Export Processing and Trad',
    'Rice and Paddy',
    'Transportation and Infrastructure',
  ];

  static const _dateItems = [
    'Not Specify',
    '2024-01-24',
    '2024-11-23',
    'Not Specified',
    '2024-01-23',
    '2024-10-23',
    '2024-06-24',
    'Not applicable',
  ];

  void _toggle(Set<String> set, String value) {
    setState(() {
      if (set.contains(value)) {
        set.remove(value);
      } else {
        set.add(value);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final background = isDark ? AppColors.darkBackground : Colors.white;

    final viewPadding = MediaQuery.of(context).viewPadding;
    final topInset = viewPadding.top > 48.0 ? viewPadding.top : 48.0;

    final visibleWg = _expandWorkingGroup
        ? _workingGroupItems
        : _workingGroupItems.take(5).toList();

    final visibleAgencies = _expandAgencies
        ? _agencyItems
        : _agencyItems.take(10).toList();

    final visibleCategories = _expandCategories
        ? _categoryItems
        : _categoryItems.take(5).toList();

    final visibleDates =
        _expandDates ? _dateItems : _dateItems.take(2).toList();

    return Material(
      color: background,
      child: FractionallySizedBox(
        heightFactor: 1.0,
        child: Column(
          children: [
            // HEADER
            Container(
              padding: EdgeInsets.fromLTRB(22, topInset + 16, 22, 16),
              child: Row(
                children: [
                  const SizedBox(width: 28),
                  Expanded(
                    child: Text(
                      'Filters',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  InkWell(
                    onTap: () => Navigator.pop(context),
                    child: Icon(
                      Icons.close,
                      color: Theme.of(context).colorScheme.onSurface,
                      size: 22,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: Color(0xFFF0F2F5)),
            // SCROLLABLE FILTER SECTIONS
            Expanded(
              child: ListView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 22, vertical: 20),
                children: [
                  // 1. PLENARY
                  const Text(
                    'Plenary',
                    style: TextStyle(
                      color: AppColors.mutedText,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    childAspectRatio: 4.5,
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8,
                    children: _plenaryOptions.map((item) {
                      return _FilterChipCheckbox(
                        label: item,
                        checked: _plenaries.contains(item),
                        onTap: () => _toggle(_plenaries, item),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),

                  // 2. STATUS
                  const Text(
                    'Status',
                    style: TextStyle(
                      color: AppColors.mutedText,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 16,
                    runSpacing: 8,
                    children: _statusOptions.map((item) {
                      return _FilterChipCheckbox(
                        label: item,
                        checked: _statuses.contains(item),
                        onTap: () => _toggle(_statuses, item),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),

                  // 3. WORKING GROUP
                  const Text(
                    'Working Group',
                    style: TextStyle(
                      color: AppColors.mutedText,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: visibleWg.map((item) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: _FilterChipCheckbox(
                          label: item,
                          checked: _workingGroups.contains(item),
                          onTap: () => _toggle(_workingGroups, item),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 8),
                  Center(
                    child: InkWell(
                      onTap: () => setState(
                          () => _expandWorkingGroup = !_expandWorkingGroup),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _expandWorkingGroup ? 'View Less' : 'View All',
                            style: const TextStyle(
                              color: Color(0xFF1E73BE),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            _expandWorkingGroup
                                ? Icons.keyboard_arrow_up
                                : Icons.keyboard_arrow_down,
                            color: const Color(0xFF1E73BE),
                            size: 16,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // 4. PRIMARY AGENCY
                  const Text(
                    'Primary Agency',
                    style: TextStyle(
                      color: AppColors.mutedText,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 12,
                    runSpacing: 8,
                    children: visibleAgencies.map((item) {
                      return _FilterChipCheckbox(
                        label: item,
                        checked: _agencies.contains(item),
                        onTap: () => _toggle(_agencies, item),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 8),
                  Center(
                    child: InkWell(
                      onTap: () =>
                          setState(() => _expandAgencies = !_expandAgencies),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _expandAgencies ? 'View Less' : 'View All',
                            style: const TextStyle(
                              color: Color(0xFF1E73BE),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            _expandAgencies
                                ? Icons.keyboard_arrow_up
                                : Icons.keyboard_arrow_down,
                            color: const Color(0xFF1E73BE),
                            size: 16,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // 5. MEASURE CATEGORY
                  const Text(
                    'Measure Category',
                    style: TextStyle(
                      color: AppColors.mutedText,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: visibleCategories
                        .map(
                          (item) => Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: _FilterChipCheckbox(
                              label: item,
                              checked: _categories.contains(item),
                              onTap: () => _toggle(_categories, item),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                  const SizedBox(height: 8),
                  Center(
                    child: InkWell(
                      onTap: () => setState(
                          () => _expandCategories = !_expandCategories),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _expandCategories ? 'View Less' : 'View All',
                            style: const TextStyle(
                              color: Color(0xFF1E73BE),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            _expandCategories
                                ? Icons.keyboard_arrow_up
                                : Icons.keyboard_arrow_down,
                            color: const Color(0xFF1E73BE),
                            size: 16,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // 6. DECISION DATE
                  const Text(
                    'Decision Date',
                    style: TextStyle(
                      color: AppColors.mutedText,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    childAspectRatio: 4.5,
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8,
                    children: visibleDates.map((item) {
                      return _FilterChipCheckbox(
                        label: item,
                        checked: _dates.contains(item),
                        onTap: () => _toggle(_dates, item),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 8),
                  Center(
                    child: InkWell(
                      onTap: () => setState(() => _expandDates = !_expandDates),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _expandDates ? 'View Less' : 'View All',
                            style: const TextStyle(
                              color: Color(0xFF1E73BE),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            _expandDates
                                ? Icons.keyboard_arrow_up
                                : Icons.keyboard_arrow_down,
                            color: const Color(0xFF1E73BE),
                            size: 16,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // APPLY BUTTON
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
              child: SizedBox(
                width: double.infinity,
                height: 46,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.accent(context),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    'Apply Filters',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
