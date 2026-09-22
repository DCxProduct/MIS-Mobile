import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/app_colors.dart';
import '../../../screens/issues/issue_detail_screen.dart';
import '../../../translations/app_localizations.dart';

class LineMinistryIssuesScreenView extends StatefulWidget {
  const LineMinistryIssuesScreenView({super.key});

  @override
  State<LineMinistryIssuesScreenView> createState() =>
      _LineMinistryIssuesScreenViewState();
}

class _LineMinistryIssuesScreenViewState
    extends State<LineMinistryIssuesScreenView> {
  int _selectedTab = 0;

  Set<String> _selectedYears = {};
  Set<String> _selectedStatuses = {};
  Set<String> _selectedAgencies = {};
  Set<String> _selectedProgressReports = {};

  Future<void> _openFilterSheet(BuildContext context) async {
    final result = await showModalBottomSheet<_LineMinistryIssuesFilterResult>(
      context: context,
      isScrollControlled: true,
      useSafeArea: false,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return _LineMinistryIssuesFilterSheet(
          selectedYears: _selectedYears,
          selectedStatuses: _selectedStatuses,
          selectedAgencies: _selectedAgencies,
          selectedProgressReports: _selectedProgressReports,
        );
      },
    );

    if (result != null) {
      setState(() {
        _selectedYears = result.years;
        _selectedStatuses = result.statuses;
        _selectedAgencies = result.agencies;
        _selectedProgressReports = result.progressReports;
      });
    }
  }

  int get _activeFilterCount {
    return _selectedYears.length +
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
                        l10n.text('issuesMatrix'),
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    _FilterButton(
                      activeCount: _activeFilterCount,
                      onTap: () => _openFilterSheet(context),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                _IssueTabs(
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
                const _LineMinistryMetricGrid(),
                const SizedBox(height: 12),
                const _TotalPrimaryAgenciesCard(value: '14'),
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
                const _LineMinistryIssuesList(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LineMinistryMetricGrid extends StatelessWidget {
  const _LineMinistryMetricGrid();

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
          value: '56',
          background: const Color(0xFFDDEEFF),
          icon: Icons.library_books_outlined,
        ),
        _MetricCard(
          label: l10n.text('solved'),
          value: '30/56',
          background: const Color(0xFFE5FAEF),
          icon: Icons.fact_check_outlined,
        ),
        _MetricCard(
          label: l10n.text('inProgress'),
          value: '16/56',
          background: const Color(0xFFFFF8DC),
          icon: Icons.add_box_outlined,
        ),
        _MetricCard(
          label: l10n.text('notAddressed'),
          value: '10/56',
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

class _LineMinistryIssuesList extends StatelessWidget {
  const _LineMinistryIssuesList();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: const [
        _LineMinistryIssueListCard(
          title: 'Joint Inspection',
          category: 'Procedure',
          status: 'Solved',
          submissionDate: 'July 24, 2025',
          submittedBy: 'Agriculture and Agro..',
          description:
              'The private sector said that the Economic Land Concession (ELCs), which invest in rubber, cashew, plantations, etc., are now fully developed and some...',
          attachmentCount: '2 Attachement',
        ),
        _LineMinistryIssueListCard(
          title: 'ពន្ធដារលើការនាំចូលផលិតផលកសិកម្ម...',
          category: 'Taxation & Custom',
          status: 'In Progress',
          submissionDate: 'July 24, 2025',
          submittedBy: 'Agriculture and Agro..',
          description:
              'ក្រុមហ៊ុនក្នុងវិស័យឯកជនបានស្វែងរកការអនុគ្រោះពន្ធ និងសម្រួលនីតិវិធីគយសម្រាប់ការនាំចូលថ្នាំកសិកម្ម និងជី...',
          attachmentCount: '2 Attachement',
        ),
        _LineMinistryIssueListCard(
          title: 'បញ្ហាប្រឈមនៃថ្លៃអគ្គិសនីសម្រាប់រោងចក្រ...',
          category: 'Energy & Mining',
          status: 'Not Addressed',
          submissionDate: 'July 24, 2025',
          submittedBy: 'Agriculture and Agro..',
          description:
              'ការចំណាយលើថាមពលអគ្គិសនីនៅតែជាបន្ទុកធ្ងន់ធ្ងរសម្រាប់សហគ្រាសផលិតកម្មក្នុងស្រុក...',
          attachmentCount: '2 Attachement',
        ),
      ],
    );
  }
}

class _LineMinistryIssueListCard extends StatelessWidget {
  const _LineMinistryIssueListCard({
    required this.title,
    required this.category,
    required this.status,
    required this.submissionDate,
    required this.submittedBy,
    required this.description,
    required this.attachmentCount,
  });

  final String title;
  final String category;
  final String status;
  final String submissionDate;
  final String submittedBy;
  final String description;
  final String attachmentCount;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final isSolved = status == 'Solved';
    final isProgress = status == 'In Progress';
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
            builder: (_) => IssueDetailScreen(title: title, category: category),
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
                Container(
                  width: 34,
                  height: 34,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [Color(0xFF216AAA), Color(0xFF1EA45B)],
                    ),
                  ),
                  child: const Icon(
                    Icons.account_balance,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        category,
                        style: const TextStyle(
                          color: Color(0xFF7C3AED),
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
            Text(
              description,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: AppColors.secondaryText(context),
                fontSize: 11,
                height: 1.45,
                fontWeight: FontWeight.w400,
              ),
            ),
            const SizedBox(height: 10),
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
                    Text(
                      tabs[index],
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

class _InlineCheckbox extends StatelessWidget {
  const _InlineCheckbox({
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
      borderRadius: BorderRadius.circular(4),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 140),
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                color: checked ? AppColors.accent(context) : Colors.transparent,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: checked
                      ? AppColors.accent(context)
                      : (isDark
                          ? AppColors.darkBorder
                          : AppColors.filterOutline),
                  width: 1,
                ),
              ),
              child: checked
                  ? const Icon(
                      Icons.check,
                      size: 11,
                      color: Colors.white,
                    )
                  : null,
            ),
            const SizedBox(width: 8),
            Text(
              translatedLabel,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontSize: 12,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LineMinistryIssuesFilterResult {
  const _LineMinistryIssuesFilterResult({
    required this.years,
    required this.statuses,
    required this.agencies,
    required this.progressReports,
  });

  final Set<String> years;
  final Set<String> statuses;
  final Set<String> agencies;
  final Set<String> progressReports;
}

class _LineMinistryIssuesFilterSheet extends StatefulWidget {
  const _LineMinistryIssuesFilterSheet({
    required this.selectedYears,
    required this.selectedStatuses,
    required this.selectedAgencies,
    required this.selectedProgressReports,
  });

  final Set<String> selectedYears;
  final Set<String> selectedStatuses;
  final Set<String> selectedAgencies;
  final Set<String> selectedProgressReports;

  @override
  State<_LineMinistryIssuesFilterSheet> createState() =>
      _LineMinistryIssuesFilterSheetState();
}

class _LineMinistryIssuesFilterSheetState
    extends State<_LineMinistryIssuesFilterSheet> {
  late Set<String> _categories;
  late Set<String> _statuses;
  late Set<String> _pswgs;
  late Set<String> _years;

  bool _isCategoriesExpanded = false;

  static const _defaultCategories = [
    'Law, Tax, and Governance',
    'Tourism',
    'Construction and Real Estate',
    'Energy and Mineral Resources',
    'Non-Bank Financial Services Other issues',
  ];

  static const _extraCategories = [
    'Industrial Relations',
    'Banking and Financial Services',
    'Agriculture and Agro-Industry',
    'Other issues',
    'SMEs, Manufacturing, and Services',
    'Export Processing and Trad',
    'Rice and Paddy',
    'Transportation and Infrastructure',
  ];

  static const _statusRow1 = ['Drafted', 'Submitted', 'Under Review'];
  static const _statusRow2 = ['Scheduled', 'Completed'];
  static const _pswgItems = ['CRF', 'ABC', 'GDCE', 'IBC', 'CTF'];
  static const _yearItems = ['2026', '2025', '2024', '2023'];

  @override
  void initState() {
    super.initState();
    _categories = {};
    _statuses = {...widget.selectedStatuses};
    _pswgs = {};
    _years = {...widget.selectedYears};
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
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final background = isDark ? AppColors.darkBackground : Colors.white;

    final viewPadding = MediaQuery.of(context).viewPadding;
    final topInset = viewPadding.top > 48.0 ? viewPadding.top : 48.0;
    final bottomInset = viewPadding.bottom;

    final displayedCategories = _isCategoriesExpanded
        ? [..._defaultCategories, ..._extraCategories]
        : _defaultCategories;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
      ),
      child: FractionallySizedBox(
        heightFactor: 1.0,
        child: Container(
          color: background,
          child: Column(
            children: [
              Container(
                padding: EdgeInsets.fromLTRB(22, topInset + 24, 22, 12),
                child: Row(
                  children: [
                    const SizedBox(width: 28),
                    Expanded(
                      child: Text(
                        l10n.text('filters'),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    InkWell(
                      onTap: () => Navigator.pop(context),
                      child: const Icon(Icons.close, size: 25),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 25,
                    vertical: 20,
                  ),
                  children: [
                    // SECTION 1: CATEGORIES
                    Text(
                      l10n.text('categories'),
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Column(
                      children: displayedCategories.map((item) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: InkWell(
                            onTap: () => _toggle(_categories, item),
                            child: Row(
                              children: [
                                AnimatedContainer(
                                  duration: const Duration(milliseconds: 140),
                                  width: 16,
                                  height: 16,
                                  decoration: BoxDecoration(
                                    color: _categories.contains(item)
                                        ? AppColors.accent(context)
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(
                                      color: _categories.contains(item)
                                          ? AppColors.accent(context)
                                          : (isDark
                                              ? AppColors.darkBorder
                                              : const Color(0xFFCED7E1)),
                                      width: 1,
                                    ),
                                  ),
                                  child: _categories.contains(item)
                                      ? const Icon(
                                          Icons.check,
                                          size: 11,
                                          color: Colors.white,
                                        )
                                      : null,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    item,
                                    style: TextStyle(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurface,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w400,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 4),
                    Center(
                      child: InkWell(
                        onTap: () {
                          setState(() {
                            _isCategoriesExpanded = !_isCategoriesExpanded;
                          });
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _isCategoriesExpanded
                                    ? l10n.text('viewLess')
                                    : l10n.text('viewAll'),
                                style: const TextStyle(
                                  color: AppColors.primary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Icon(
                                _isCategoriesExpanded
                                    ? Icons.keyboard_arrow_up
                                    : Icons.keyboard_arrow_down,
                                color: AppColors.primary,
                                size: 16,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // SECTION 2: STATUS
                    Text(
                      l10n.text('status'),
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 16,
                      runSpacing: 10,
                      children: _statusRow1.map((item) {
                        return _InlineCheckbox(
                          label: item,
                          checked: _statuses.contains(item),
                          onTap: () => _toggle(_statuses, item),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 16,
                      runSpacing: 10,
                      children: _statusRow2.map((item) {
                        return _InlineCheckbox(
                          label: item,
                          checked: _statuses.contains(item),
                          onTap: () => _toggle(_statuses, item),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 24),

                    // SECTION 3: ALL PSWGS
                    const Text(
                      'All PSWGS',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 18,
                      runSpacing: 10,
                      children: _pswgItems.map((item) {
                        return _InlineCheckbox(
                          label: item,
                          checked: _pswgs.contains(item),
                          onTap: () => _toggle(_pswgs, item),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 24),

                    // SECTION 4: YEAR
                    Text(
                      l10n.text('year'),
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 20,
                      runSpacing: 10,
                      children: _yearItems.map((item) {
                        return _InlineCheckbox(
                          label: item,
                          checked: _years.contains(item),
                          onTap: () => _toggle(_years, item),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.fromLTRB(
                  16,
                  13,
                  16,
                  bottomInset > 0 ? bottomInset + 10 : 12,
                ),
                child: SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accent(context),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: () {
                      Navigator.pop(
                        context,
                        _LineMinistryIssuesFilterResult(
                          years: {..._years},
                          statuses: {..._statuses},
                          agencies: {},
                          progressReports: {},
                        ),
                      );
                    },
                    child: Text(
                      l10n.text('applyFilters'),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
