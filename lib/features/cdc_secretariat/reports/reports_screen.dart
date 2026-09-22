import 'package:flutter/material.dart';
import '../../../translations/app_language.dart';
import '../../../core/app_colors.dart';
import '../../../screens/report/plenary_detail_screen.dart';
import '../../../screens/report/rgc_decision_detail_screen.dart';
import '../../../translations/app_localizations.dart';
import '../dashboard/filter_sheet.dart';
import 'agencies_tab.dart';
import 'categories_tab.dart';

class CdcSecretariatReportsScreenView extends StatefulWidget {
  const CdcSecretariatReportsScreenView({super.key});
  @override
  State<CdcSecretariatReportsScreenView> createState() => _CdcReportsState();
}

class _CdcReportsState extends State<CdcSecretariatReportsScreenView> {
  int _tab = 0;
  final _filters = List.generate(3, (_) => CdcDashboardFilters());
  Future<void> _openFilters() async {
    final tab = _tab;
    final result = await Navigator.of(context).push<CdcDashboardFilters>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => CdcDashboardFilterSheet(
          initial: _filters[tab],
          groups: tab == 1
              ? const {
                  'status': ['Sent', 'Draft'],
                  'year': ['2026', '2025', '2024', '2023'],
                }
              : null,
        ),
      ),
    );
    if (!mounted || result == null) return;
    setState(() => _filters[tab] = result);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return ColoredBox(
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
                        l10n.text(['report', 'plenary', 'rgcDecision'][_tab]),
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    OutlinedButton(
                      onPressed: _openFilters,
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: AppColors.border(context)),
                        minimumSize: const Size(0, 30),
                        padding: const EdgeInsets.symmetric(horizontal: 9),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${l10n.text('filter')}${_filters[_tab].count == 0 ? '' : ' (${_filters[_tab].count})'}',
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
                _ReportTabs(
                  selectedIndex: _tab,
                  onSelected: (tab) => setState(() => _tab = tab),
                ),
              ],
            ),
          ),
          Expanded(
            child: IndexedStack(
              index: _tab,
              children: [
                for (final child in const [
                  _ReportDashboardTab(),
                  _PlenaryTab(),
                  _RgcDecisionTab(),
                ])
                  SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 18, 16, 100),
                    child: child,
                  ),
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
          meetingDate: 'Nov 13, 2023',
          category: 'Legislation',
          focalPerson: 'Peng Ponea',
          linkCount: '2 Link',
        ),
        _RgcDecisionCard(
          agencyName: 'MPWT',
          status: 'Solved',
          meetingDate: 'Apr 28, 2025',
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
                        : const Color(0xFFFAA15A),
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
    return Column(
      children: const [
        _PlenaryCard(
          title: '19th G-PSF. Plenary',
          status: 'Sent',
          meetingDate: 'Apr 08, 2025',
          numberOfRgcDecision: '179',
          deadline: 'Apr 15, 2025',
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
              Expanded(child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              )),
              const SizedBox(width: 8),
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

class _ReportRow extends StatelessWidget {
  const _ReportRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(child: Text(
          label,
          style: const TextStyle(
            color: AppColors.mutedText,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        )),
        const SizedBox(width: 12),
        Flexible(child: Text(
          value,
          textAlign: TextAlign.right,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        )),
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

  static const _workingGroupItems = [
    '(A) Agriculture and Agro-industry',
    '(E) Banking and Financial Services',
    '(M) Construction and Real Estate',
    '(J) Energy and Mineral Resources',
    '(G) Export Processing and Trade Facilitation',
    '(H) Industrial Relations',
    '(D) Law, Tax, and Governance',
    '(N) Non-Bank Financial Services Other issues',
    '(I) Rice and Paddy',
    '(C) SMEs, Manufacturing, and Services',
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
        const _TotalPrimaryAgenciesCard(value: '14/14'),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: AppColors.cardBackground(context),
            borderRadius: BorderRadius.circular(9),
          ),
          child: Row(
            children: [
              for (var index = 0; index < 4; index++)
                Expanded(
                  child: _SubFilterChip(
                    label: l10n.text(
                      [
                        'overall',
                        'agencies',
                        'workingGroup',
                        'categories',
                      ][index],
                    ),
                    selected: _selectedFilter == index,
                    onTap: () => setState(() => _selectedFilter = index),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        if (_selectedFilter == 1) ...[
          Text(l10n.text('agencies')),
          const SizedBox(height: 12),
          const CdcReportAgenciesTab(),
        ] else if (_selectedFilter == 2) ...[
          _AgenciesListCard(
            title: l10n.text('workingGroup'),
            items: _workingGroupItems,
          ),
        ] else if (_selectedFilter == 3) ...[
          Text(l10n.text('categoriesOfIssues')),
          const SizedBox(height: 12),
          const CdcReportCategoriesTab(),
        ] else ...[
          Text(
            l10n.text('overallStatus'),
            style: const TextStyle(fontSize: 14),
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
                      percentage: 0.9273,
                      color: Color(0xFF009F5C),
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
                  badge1DotColor: Color(0xFF009F5C),
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
                          color: Color(0xFF009F5C),
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
                      color: Color(0xFFFAA15A),
                      label: 'Mid Progress',
                    ),
                    DonutChartData(
                      percentage: 0.077,
                      color: Color(0xFFF1DAA7),
                      label: 'Early Progress',
                    ),
                  ],
                  centerTitle: l10n.text('inProgress'),
                  centerValue: '13',
                  badge1Text: '92.3%',
                  badge1DotColor: Color(0xFFFAA15A),
                  badge2Text: '7.7%',
                  badge2DotColor: Color(0xFFF1DAA7),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    Row(
                      children: [
                        Icon(Icons.square, color: Color(0xFFFAA15A), size: 10),
                        SizedBox(width: 6),
                        Text('Mid Progress', style: TextStyle(fontSize: 12)),
                      ],
                    ),
                    Text(
                      '(12)',
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
                        Icon(Icons.square, color: Color(0xFFF1DAA7), size: 10),
                        SizedBox(width: 6),
                        Text('Early Progress', style: TextStyle(fontSize: 12)),
                      ],
                    ),
                    Text(
                      '(1)',
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
              color: const Color(0xFFFAA15A),
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
              color: const Color(0xFF009F5C),
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
        child: FittedBox(
          fit: BoxFit.scaleDown,
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

class _ReportTabs extends StatelessWidget {
  const _ReportTabs({required this.selectedIndex, required this.onSelected});
  final int selectedIndex;
  final ValueChanged<int> onSelected;
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Container(
      height: 38,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.cardBackground(context),
        border: Border.all(color: AppColors.border(context)),
        borderRadius: BorderRadius.circular(9),
      ),
      child: Row(
        children: [
          for (var index = 0; index < 3; index++)
            Expanded(
              child: InkWell(
                onTap: () => onSelected(index),
                borderRadius: BorderRadius.circular(6),
                child: Container(
                  alignment: Alignment.center,
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  decoration: BoxDecoration(
                    color: selectedIndex == index
                        ? AppColors.accent(context)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.event_note_outlined,
                          size: 15,
                          color: selectedIndex == index
                              ? Colors.white
                              : AppColors.mutedText,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          l10n.text(
                            ['dashboard', 'plenaries', 'rgcDecision'][index],
                          ),
                          style: TextStyle(
                            fontSize: 12,
                            color: selectedIndex == index
                                ? Colors.white
                                : AppColors.mutedText,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
