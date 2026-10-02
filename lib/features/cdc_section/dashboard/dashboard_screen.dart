import 'overall_status_card.dart';
import '../../cdc_secretariat/dashboard/filter_sheet.dart';
import '../../shared/dashboard/data/dashboard_repository.dart';
import '../../shared/dashboard/widgets/pswg_live_dashboard.dart';
import '../../shared/dashboard/data/working_group_summary.dart';
import 'package:flutter/material.dart';

import '../../../core/app_colors.dart';
import '../../../core/app_settings.dart';
import '../../../translations/app_localizations.dart';
import '../../../widgets/app_logo.dart';
import '../../../widgets/notification_bell.dart';
import '../../../core/widgets/filters/api_filter_sheet.dart';
import 'working_group_filter_sheet.dart';
import '../../cdc_secretariat/reports/report_filter_sheet.dart';

class CdcSectionDashboardScreenView extends StatefulWidget {
  const CdcSectionDashboardScreenView({super.key});

  @override
  State<CdcSectionDashboardScreenView> createState() =>
      _CdcSectionDashboardScreenViewState();
}

class _CdcSectionDashboardScreenViewState
    extends State<CdcSectionDashboardScreenView> {
  int _mainTab = 0; // 0: Plenary, 1: Working Group
  CdcDashboardFilters _workingGroupFilters = CdcDashboardFilters();
  CdcDashboardFilters _plenaryFilters = CdcDashboardFilters();

  Future<void> _openDashboardFilters() async {
    final tab = _mainTab;
    final result = await Navigator.of(context).push<CdcDashboardFilters>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => AppSettings.of(context).auth.isStaticSession
            ? (tab == 0
                  ? CdcReportFilterSheet(initial: _plenaryFilters)
                  : CdcWorkingGroupDashboardFilterSheet(
                      initial: _workingGroupFilters,
                    ))
            : ApiFilterSheet(
                initial: tab == 0 ? _plenaryFilters : _workingGroupFilters,
                load: () => AppSettings.of(
                  context,
                ).filters.dashboard(tab == 0 ? 'plenary' : 'pswg'),
              ),
      ),
    );
    if (!mounted || result == null) return;
    setState(() {
      if (tab == 0) {
        _plenaryFilters = result;
      } else {
        _workingGroupFilters = result;
      }
    });
  }

  int _subFilter =
      0; // 0: Over All, 1: Agencies, 2: Working Group, 3: Categories

  static const _workingGroupItems = [
    '(A) Agriculture and Agro-industry',
    '(E) Banking and Financial Services',
    '(M) Construction and Real Estate',
    '(O) Digital Economy, Society and Telecommunications',
    '(G) Export Processing and Trade Facilitation',
    '(H) Industrial Relations',
    '(D) Law, Tax, and Governance',
    '(N) Non-Bank Financial Services Other issues',
    '(I) Rice and Paddy',
  ];

  @override
  Widget build(BuildContext context) {
    if (AppSettings.of(context).auth.isStaticSession) {
      return _buildContent(context);
    }
    return PswgDataLoader(
      selection: _mainTab == 0 ? _plenaryFilters : _workingGroupFilters,
      scope: _mainTab == 0 ? DashboardScope.plenary : DashboardScope.pswg,
      progressReportId: int.tryParse(
        (_mainTab == 0 ? _plenaryFilters : _workingGroupFilters)
                .toQuery()['progressReportId'] ??
            '',
      ),
      builder: _buildContent,
    );
  }

  Widget _buildContent(BuildContext context) {
    final data = PswgDataScope.maybeOf(context);
    final cards = data?.cards;
    final total = cards?['totalIssues'] ?? 179;
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final background = isDark
        ? AppColors.darkBackground
        : const Color(0xFFF5F6FB);
    final labels = ['overall', 'agencies', 'workingGroup', 'categories'];
    return ColoredBox(
      color: background,
      child: Column(
        children: [
          Container(
            color: isDark ? background : Colors.white,
            padding: EdgeInsets.fromLTRB(
              20,
              MediaQuery.of(context).viewPadding.top + 20,
              20,
              20,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [const AppLogo(width: 88), const NotificationBell()],
            ),
          ),
          Expanded(
            child: ListView(
              key: const ValueKey('cdc-dashboard-scroll'),
              padding: const EdgeInsets.fromLTRB(14, 16, 14, 20),
              children: [
                Text(
                  l10n.text('dashboard'),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              color: isDark ? AppColors.darkCard : Colors.white,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                for (final entry in [
                                  'plenary',
                                  'workingGroup',
                                ].indexed)
                                  InkWell(
                                    key: ValueKey(
                                      'cdc-dashboard-main-${entry.$1}',
                                    ),
                                    onTap: () => setState(() {
                                      _mainTab = entry.$1;
                                      _subFilter = 0;
                                    }),
                                    borderRadius: BorderRadius.circular(20),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: _mainTab == entry.$1
                                            ? const Color(0xFF1D66AD)
                                            : Colors.transparent,
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        l10n.text(entry.$2),
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: _mainTab == entry.$1
                                              ? Colors.white
                                              : const Color(0xFF1D66AD),
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    _FilterButton(
                      activeCount: _mainTab == 1
                          ? _workingGroupFilters.count
                          : _plenaryFilters.count,
                      onTap: _openDashboardFilters,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  padding: EdgeInsets.zero,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                  childAspectRatio: 2.2,
                  children: [
                    _MetricCard(
                      label: l10n.text('totalIssues'),
                      value: '$total',
                      background: const Color(0xFFDDEEFF),
                      icon: Icons.library_books_outlined,
                    ),
                    _MetricCard(
                      label: l10n.text('solved'),
                      value: '${cards?['solved'] ?? 166}/$total',
                      background: const Color(0xFFECFCF4),
                      icon: Icons.fact_check_outlined,
                    ),
                    _MetricCard(
                      label: l10n.text('inProgress'),
                      value: '${cards?['inProgress'] ?? 13}/$total',
                      background: const Color(0xFFFFFAEB),
                      icon: Icons.add_box_outlined,
                    ),
                    _MetricCard(
                      label: l10n.text('notAddressed'),
                      value: '${cards?['notAddressed'] ?? 0}/$total',
                      background: const Color(0xFFFFF3F4),
                      icon: Icons.assignment_late_outlined,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                _TotalPrimaryAgenciesCard(
                  value: '${cards?['totalPrimaryAgencies'] ?? 14}',
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkCard : Colors.white,
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Row(
                    children: [
                      for (final entry in labels.indexed)
                        Expanded(
                          flex: entry.$1 == 2 ? 14 : 10,
                          child: _SubFilterChip(
                            label: l10n.text(entry.$2),
                            selected: _subFilter == entry.$1,
                            onTap: () => setState(() => _subFilter = entry.$1),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                if (_subFilter == 1)
                  const _AgenciesHorizontalBarChartCard()
                else if (_subFilter == 2)
                  _AgenciesListCard(
                    title: l10n.text('workingGroup'),
                    items:
                        data?.workingGroups.map((row) => row.name).toList() ??
                        _workingGroupItems,
                    rows: data?.workingGroups,
                  )
                else if (_subFilter == 3)
                  _PlenaryCategoriesListCard(workingGroup: _mainTab == 1)
                else
                  CdcOverallStatusCard(
                    cards: cards,
                    workingGroup: _mainTab == 1,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AgenciesHorizontalBarChartCard extends StatelessWidget {
  const _AgenciesHorizontalBarChartCard();

  static const _agencyBars = [
    (name: 'CDC', value: 5.2),
    (name: 'GDCE', value: 6.2),
    (name: 'GDT', value: 4.8),
    (name: 'MAFF', value: 2.2),
    (name: 'MFF', value: 8.5),
    (name: 'MISTI', value: 3.5),
    (name: 'MLMUPC', value: 8.2),
    (name: 'MLVT', value: 9.0),
    (name: 'MPTC', value: 1.8),
  ];

  @override
  Widget build(BuildContext context) {
    final rows = PswgDataScope.maybeOf(context)?.agencies;
    final bars =
        rows
            ?.map((row) => (name: row.name, value: row.total.toDouble()))
            .toList() ??
        _agencyBars;
    final maximum = rows == null
        ? 10.0
        : bars.fold<double>(1, (max, row) => row.value > max ? row.value : max);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context).text('agencies'),
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
              ...bars.map((item) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 17),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 72,
                        child: Text(
                          item.name,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Stack(
                          children: [
                            Container(
                              height: 8,
                              decoration: BoxDecoration(
                                color: isDark
                                    ? AppColors.darkBorder
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                            FractionallySizedBox(
                              widthFactor: (item.value / maximum).clamp(
                                0.0,
                                1.0,
                              ),
                              child: Container(
                                height: 11,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1E73BE),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const SizedBox(width: 72),
                  for (final step in [0, 1, 2, 3, 4])
                    Text(
                      '${(maximum * step / 4).round()}',
                      style: const TextStyle(
                        color: AppColors.mutedText,
                        fontSize: 10,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PlenaryCategoriesListCard extends StatelessWidget {
  const _PlenaryCategoriesListCard({this.workingGroup = false});

  final bool workingGroup;

  static const _items = [
    '1. Adjusting business and investment climate',
    '10. Construction and real estate sector',
    '11. Other issues',
    '2. Easing the burden on compliance',
    '3. Facilitation of businesses under tax authorities',
    '4. Trade facilitation under customs jurisdiction',
    '5. Improving transportation and infrastructure',
    '6. Rehabilitation and development of tourism',
    '7. (A) Agricultural and agro-industrial development',
    '8. (E) Banking and Finance Sector',
    '9. Mining and energy sector',
  ];

  @override
  Widget build(BuildContext context) {
    final rows = PswgDataScope.maybeOf(context)?.categories;
    final items =
        rows?.map((row) => row.name).toList() ??
        (workingGroup
            ? [
                'Government',
                'Taxation',
                'Human Resource',
                'Trade',
                'Legislation',
                'Procedure',
                'Market',
                'Policy',
                'Strategy',
              ]
            : _items);
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
            itemCount: items.length,
            separatorBuilder: (_, _) => const SizedBox(height: 14),
            itemBuilder: (context, index) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          items[index],
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${rows?[index].total ?? 3}',
                        style: TextStyle(
                          color: AppColors.mutedText,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: SizedBox(
                      height: 6,
                      width: double.infinity,
                      child: Row(
                        children: [
                          if (rows != null && rows[index].notAddressed > 0)
                            Expanded(
                              flex: rows[index].notAddressed,
                              child: Container(color: const Color(0xFFFF3B30)),
                            ),
                          if (rows == null || rows[index].solved > 0)
                            Expanded(
                              flex: rows?[index].solved ?? 3,
                              child: Container(color: const Color(0xFF009F59)),
                            ),
                          const SizedBox(width: 2),
                          if (rows == null || rows[index].inProgress > 0)
                            Expanded(
                              flex: rows?[index].inProgress ?? 1,
                              child: Container(color: const Color(0xFFF97316)),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
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
        height: 34,
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
              '${AppLocalizations.of(context).text('filter')}${activeCount > 0 ? ' ($activeCount)' : ''}',
              style: const TextStyle(
                color: AppColors.mutedText,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 6),
            Icon(
              Icons.filter_list,
              color: Theme.of(context).colorScheme.onSurface,
              size: 16,
            ),
          ],
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
              Icons.event_note_outlined,
              color: Color(0xFF4C5563),
              size: 20,
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
        padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 7),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.accent(context)
              : (isDark ? AppColors.darkCard : Colors.white),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: selected ? AppColors.accent(context) : Colors.transparent,
          ),
        ),
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: selected
                ? Colors.white
                : (isDark
                      ? AppColors.secondaryText(context)
                      : const Color(0xFF4C5563)),
            fontSize: 11,
            fontWeight: FontWeight.w400,
          ),
        ),
      ),
    );
  }
}

class _AgenciesListCard extends StatelessWidget {
  const _AgenciesListCard({
    required this.title,
    required this.items,
    this.rows,
  });

  final List<WorkingGroupSummary>? rows;
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
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    _MiniBarChart(data: rows?[index]),
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

class _MiniBarChart extends StatelessWidget {
  const _MiniBarChart({this.data});

  final WorkingGroupSummary? data;

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
            height: data == null
                ? 8
                : data!.total == 0
                ? 0
                : 18 * data!.inProgress / data!.total,
            decoration: BoxDecoration(
              color: const Color(0xFFF97316),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 3),
          Container(
            width: 3.5,
            height: data == null
                ? 4
                : data!.total == 0
                ? 0
                : 18 * data!.notAddressed / data!.total,
            decoration: BoxDecoration(
              color: const Color(0xFFEF4444),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 3),
          Container(
            width: 3.5,
            height: data == null
                ? 16
                : data!.total == 0
                ? 0
                : 18 * data!.solved / data!.total,
            decoration: BoxDecoration(
              color: const Color(0xFF009F59),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ],
      ),
    );
  }
}
