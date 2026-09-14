import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/app_colors.dart';
import '../../translations/app_localizations.dart';
import 'issue_detail_screen.dart';

class IssuesScreen extends StatefulWidget {
  const IssuesScreen({super.key});

  @override
  State<IssuesScreen> createState() => _IssuesScreenState();
}

class _IssuesScreenState extends State<IssuesScreen> {
  int _selectedTab = 0;
  String _searchQuery = '';

  Set<String> _selectedYears = {};
  Set<String> _selectedStatuses = {};
  Set<String> _selectedAgencies = {};
  Set<String> _selectedProgressReports = {};

  Future<void> _openIssuesFilterSheet(BuildContext context) async {
    final result = await showModalBottomSheet<_IssuesFilterResult>(
      context: context,
      isScrollControlled: true,
      useSafeArea: false,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return _IssuesFilterSheet(
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

    final title =
        _selectedTab == 0 ? l10n.text('wgIssues') : l10n.text('issuesMatrix');

    return ColoredBox(
      color: contentBackground,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          Container(
            color: headerBackground,
            padding: const EdgeInsets.fromLTRB(14, 34, 14, 12),
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
                const _IssueMetricGrid(),
                const SizedBox(height: 14),
                _selectedTab == 0
                    ? const _WgIssuesList()
                    : const _IssuesMatrixList(),
              ],
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
  const _IssueMetricGrid();

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
          value: '20',
          background: const Color(0xFFDDEEFF),
          icon: Icons.library_books_outlined,
        ),
        _IssueMetricCard(
          label: l10n.text('solved'),
          value: '15/20',
          background: const Color(0xFFE5FAEF),
          icon: Icons.fact_check_outlined,
        ),
        _IssueMetricCard(
          label: l10n.text('inProgress'),
          value: '4/20',
          background: const Color(0xFFFFF8DC),
          icon: Icons.add_box_outlined,
        ),
        _IssueMetricCard(
          label: l10n.text('notAddressed'),
          value: '1/20',
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
  const _WgIssuesList();

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        _IssueCard(
          title: 'Joint Inspection',
          category: 'Procedure',
          status: _IssueCardStatus.solved,
        ),
        _IssueCard(
          title: 'Issues for local aquaculture and agriculture...',
          category: 'Governance',
          status: _IssueCardStatus.inProgress,
        ),
      ],
    );
  }
}

class _IssuesMatrixList extends StatelessWidget {
  const _IssuesMatrixList();

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        _IssueCard(
          title: 'Joint Inspection',
          category: 'Procedure',
          status: _IssueCardStatus.solved,
        ),
        _IssueCard(
          title: 'Issues for local aquaculture and agriculture...',
          category: 'Governance',
          status: _IssueCardStatus.inProgress,
        ),
        _IssueCard(
          title: 'Climate resilience and water supply concern...',
          category: 'Governance',
          status: _IssueCardStatus.notAddressed,
        ),
      ],
    );
  }
}

enum _IssueCardStatus { solved, inProgress, notAddressed }

class _IssueCard extends StatelessWidget {
  const _IssueCard({
    required this.title,
    required this.category,
    required this.status,
  });

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
            builder: (_) => IssueDetailScreen(title: title, category: category),
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
                    value: 'July 24, 2025',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _IssueMeta(
                    icon: Icons.person_outline,
                    label: AppLocalizations.of(context).text('submittedBy'),
                    value: 'Agriculture and Agro...',
                    iconColor: const Color(0xFFB642FF),
                    iconBackground: const Color(0xFFF2DDFF),
                  ),
                ),
              ],
            ),
            const Divider(height: 18),
            Text(
              'The private sector said that the Economic Land Concession (ELCs), which invest in rubber, cashew, plantations, etc., are now fully developed and som...',
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
                    AppLocalizations.of(context).text('twoAttachments'),
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
              color: config.color,
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

class _IssuesFilterResult {
  const _IssuesFilterResult({
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

class _IssuesFilterSheet extends StatefulWidget {
  const _IssuesFilterSheet({
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
  State<_IssuesFilterSheet> createState() => _IssuesFilterSheetState();
}

class _IssuesFilterSheetState extends State<_IssuesFilterSheet> {
  late Set<String> _years;
  late Set<String> _statuses;
  late Set<String> _agencies;
  late Set<String> _progressReports;

  bool _showAllAgencies = false;

  static const _yearItems = ['2026', '2025', '2024', '2023'];
  static const _statusItems = ['Sent', 'Draft'];
  static const _agencyItems = [
    'GDT',
    'MFF',
    'GDCE',
    'MLVT',
    'MPTC',
    'MAFF',
    'Moh',
    'NBC',
    'MoC',
    'MoT',
    'MLMUPC',
    'MoI',
    'CDC',
    'MPWT',
    'MISTI',
  ];
  static const _progressReportItems = ['Both', 'S1', 'S2'];

  @override
  void initState() {
    super.initState();
    _years = {...widget.selectedYears};
    _statuses = {...widget.selectedStatuses};
    _agencies = {...widget.selectedAgencies};
    _progressReports = {...widget.selectedProgressReports};
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
    final borderColor =
        isDark ? AppColors.darkBorder : const Color(0xFFE6E9ED);

    final viewPadding = MediaQuery.of(context).viewPadding;
    final topInset = viewPadding.top > 48.0 ? viewPadding.top : 48.0;
    final bottomInset = viewPadding.bottom;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
        statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
      ),
      child: FractionallySizedBox(
        heightFactor: 1.0,
        child: Container(
          decoration: BoxDecoration(
            color: background,
          ),
          child: Column(
            children: [
              // ================= FILTER HEADER =================
              Container(
                padding: EdgeInsets.fromLTRB(
                  22,
                  topInset + 24,
                  22,
                  12,
                ),
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
                      borderRadius: BorderRadius.circular(18),
                      child: const SizedBox(
                        width: 28,
                        height: 28,
                        child: Icon(
                          Icons.close,
                          size: 25,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // ================= FILTER CONTENT =================
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(
                    25,
                    20,
                    25,
                    22,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Section 1: Year
                      _FilterGridSection(
                        title: l10n.text('year'),
                        items: _yearItems,
                        columns: 4,
                        selectedItems: _years,
                        onChanged: (year) => _toggle(_years, year),
                      ),

                      const SizedBox(height: 25),

                      // Section 2: Status
                      _FilterGridSection(
                        title: l10n.text('status'),
                        items: _statusItems,
                        columns: 3,
                        selectedItems: _statuses,
                        onChanged: (status) => _toggle(_statuses, status),
                      ),

                      const SizedBox(height: 25),

                      // Section 3: Primary Agency
                      Text(
                        l10n.text('primaryAgency'),
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _FilterGrid(
                        items: _showAllAgencies
                            ? _agencyItems
                            : _agencyItems.take(10).toList(),
                        columns: 5,
                        selectedItems: _agencies,
                        onChanged: (agency) => _toggle(_agencies, agency),
                      ),
                      const SizedBox(height: 10),
                      Center(
                        child: InkWell(
                          onTap: () {
                            setState(() {
                              _showAllAgencies = !_showAllAgencies;
                            });
                          },
                          borderRadius: BorderRadius.circular(6),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  _showAllAgencies
                                      ? l10n.text('viewLess')
                                      : l10n.text('viewAll'),
                                  style: TextStyle(
                                    color: AppColors.accent(context),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(width: 7),
                                Icon(
                                  _showAllAgencies
                                      ? Icons.keyboard_arrow_up
                                      : Icons.keyboard_arrow_down,
                                  color: AppColors.accent(context),
                                  size: 15,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 12),

                      // Section 4: Progress Report
                      _FilterGridSection(
                        title: l10n.text('progressReport'),
                        items: _progressReportItems,
                        columns: 3,
                        selectedItems: _progressReports,
                        onChanged: (item) => _toggle(_progressReports, item),
                      ),
                    ],
                  ),
                ),
              ),

              // ================= APPLY BUTTON =================
              Container(
                padding: EdgeInsets.fromLTRB(
                  16,
                  13,
                  16,
                  bottomInset > 0 ? bottomInset + 10 : 12,
                ),
                decoration: BoxDecoration(
                  color: background,
                  border: Border(
                    top: BorderSide(
                      color: borderColor,
                    ),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 8,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accent(context),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(9),
                      ),
                    ),
                    onPressed: () {
                      Navigator.pop(
                        context,
                        _IssuesFilterResult(
                          years: {..._years},
                          statuses: {..._statuses},
                          agencies: {..._agencies},
                          progressReports: {..._progressReports},
                        ),
                      );
                    },
                    child: Text(
                      l10n.text('applyFilters'),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
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

class _FilterGridSection extends StatelessWidget {
  const _FilterGridSection({
    required this.title,
    required this.items,
    required this.columns,
    required this.selectedItems,
    required this.onChanged,
  });

  final String title;
  final List<String> items;
  final int columns;
  final Set<String> selectedItems;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),
        _FilterGrid(
          items: items,
          columns: columns,
          selectedItems: selectedItems,
          onChanged: onChanged,
        ),
      ],
    );
  }
}

class _FilterGrid extends StatelessWidget {
  const _FilterGrid({
    required this.items,
    required this.columns,
    required this.selectedItems,
    required this.onChanged,
  });

  final List<String> items;
  final int columns;
  final Set<String> selectedItems;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    const horizontalGap = 8.0;
    const verticalGap = 15.0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final itemWidth =
            (constraints.maxWidth - horizontalGap * (columns - 1)) / columns;

        return Wrap(
          spacing: horizontalGap,
          runSpacing: verticalGap,
          children: [
            for (final item in items)
              SizedBox(
                width: itemWidth,
                child: _CheckTile(
                  label: item,
                  selected: selectedItems.contains(item),
                  onTap: () => onChanged(item),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _CheckTile extends StatelessWidget {
  const _CheckTile({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _CheckTileBox(selected: selected),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _localizeLabel(context, label),
              style: const TextStyle(
                color: AppColors.mutedText,
                fontSize: 12,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

String _localizeLabel(BuildContext context, String text) {
  final l10n = AppLocalizations.of(context);
  return switch (text) {
    'Drafted' => l10n.text('drafted'),
    'Submitted' => l10n.text('submitted'),
    'Under Review' => l10n.text('underReview'),
    'Scheduled' => l10n.text('scheduled'),
    'Completed' => l10n.text('completed'),
    'Solved' => l10n.text('solved'),
    'In Progress' => l10n.text('inProgress'),
    'Not Address' || 'Not Addressed' => l10n.text('notAddressed'),
    'Both' => l10n.text('both'),
    'Sent' => l10n.text('sent'),
    'Draft' => l10n.text('draft'),
    'View All' => l10n.text('viewAll'),
    'View Less' => l10n.text('viewLess'),
    _ => text,
  };
}

class _CheckTileBox extends StatelessWidget {
  const _CheckTileBox({required this.selected});

  final bool selected;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 140),
      width: 16,
      height: 16,
      decoration: BoxDecoration(
        color: selected ? AppColors.accent(context) : Colors.transparent,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: selected
              ? AppColors.accent(context)
              : (isDark ? AppColors.darkBorder : const Color(0xFFCED7E1)),
          width: 1,
        ),
      ),
      child: selected
          ? const Icon(
              Icons.check,
              size: 11,
              color: Colors.white,
            )
          : null,
    );
  }
}
