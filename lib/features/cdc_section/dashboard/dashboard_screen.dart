import 'package:flutter/material.dart';

import '../../../core/app_colors.dart';
import '../../../translations/app_localizations.dart';
import '../../../widgets/app_logo.dart';
import '../../line_ministry/reports/reports_screen.dart';

class CdcSectionDashboardScreenView extends StatefulWidget {
  const CdcSectionDashboardScreenView({super.key});

  @override
  State<CdcSectionDashboardScreenView> createState() =>
      _CdcSectionDashboardScreenViewState();
}

class _CdcSectionDashboardScreenViewState
    extends State<CdcSectionDashboardScreenView> {
  int _mainTab = 0; // 0: Plenary, 1: Working Group
  int _subFilter = 0; // 0: Over All, 1: Agencies, 2: Working Group, 3: Categories

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
    '(A) Agriculture and Agro-industry',
    '(E) Banking and Financial Services',
    '(M) Construction and Real Estate',
    '(J) Energy and Mineral Resources',
    '(G) Export Processing and Trade Facilitation',
    '(H) Industrial Relations',
    '(D) Law, Tax, and Governance',
    '(N) Non-Bank Financial Services Other issues',
    '(I) Rice and Paddy',
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context);
    final topPadding = MediaQuery.of(context).viewPadding.top;

    final contentBackground = isDark
        ? AppColors.darkBackground
        : const Color(0xFFF7F7F8);
    final headerBackground = isDark ? AppColors.darkBackground : Colors.white;

    return ColoredBox(
      color: contentBackground,
      child: Column(
        children: [
          // HEADER WITH LOGO AND NOTIFICATION BELL
          Container(
            color: headerBackground,
            padding: EdgeInsets.fromLTRB(16, topPadding > 0 ? topPadding + 10 : 32, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    AppLogo(width: 140),
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.darkBorder
                            : const Color(0xFFE0F2FE),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.notifications_none_outlined,
                        color: isDark ? Colors.white : const Color(0xFF0284C7),
                        size: 20,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  l10n.text('dashboard'),
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                // MAIN TABS (Plenary / Working Group) AND FILTER
                Row(
                  children: [
                    InkWell(
                      onTap: () => setState(() => _mainTab = 0),
                      borderRadius: BorderRadius.circular(20),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
                        decoration: BoxDecoration(
                          color: _mainTab == 0
                              ? AppColors.accent(context)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          l10n.text('plenary'),
                          style: TextStyle(
                            color: _mainTab == 0
                                ? Colors.white
                                : (isDark ? Colors.white70 : const Color(0xFF4C5563)),
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    InkWell(
                      onTap: () => setState(() => _mainTab = 1),
                      borderRadius: BorderRadius.circular(20),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
                        decoration: BoxDecoration(
                          color: _mainTab == 1
                              ? AppColors.accent(context)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          l10n.text('workingGroup'),
                          style: TextStyle(
                            color: _mainTab == 1
                                ? Colors.white
                                : (isDark ? Colors.white70 : const Color(0xFF4C5563)),
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const Spacer(),
                    _FilterButton(
                      activeCount: 0,
                      onTap: () {
                        showModalBottomSheet<void>(
                          context: context,
                          isScrollControlled: true,
                          useSafeArea: false,
                          backgroundColor: Colors.transparent,
                          builder: (context) {
                            return const LineMinistryDashboardFilterSheet();
                          },
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),

          // SCROLLABLE CONTENT
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 96),
              children: [
                // METRIC CARDS GRID (2x2)
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
                      background: const Color(0xFFDDEEFF),
                      icon: Icons.library_books_outlined,
                    ),
                    _MetricCard(
                      label: l10n.text('solved'),
                      value: '166/179',
                      background: const Color(0xFFE5FAEF),
                      icon: Icons.fact_check_outlined,
                    ),
                    _MetricCard(
                      label: l10n.text('inProgress'),
                      value: '13/179',
                      background: const Color(0xFFFFF8DC),
                      icon: Icons.add_box_outlined,
                    ),
                    _MetricCard(
                      label: l10n.text('notAddressed'),
                      value: '0/179',
                      background: const Color(0xFFFFEEEE),
                      icon: Icons.assignment_late_outlined,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const _TotalPrimaryAgenciesCard(value: '14'),
                const SizedBox(height: 16),

                // SUB FILTER CHIPS
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _SubFilterChip(
                        label: l10n.text('overall'),
                        selected: _subFilter == 0,
                        onTap: () => setState(() => _subFilter = 0),
                      ),
                      const SizedBox(width: 8),
                      _SubFilterChip(
                        label: l10n.text('agencies'),
                        selected: _subFilter == 1,
                        onTap: () => setState(() => _subFilter = 1),
                      ),
                      const SizedBox(width: 8),
                      _SubFilterChip(
                        label: l10n.text('workingGroup'),
                        selected: _subFilter == 2,
                        onTap: () => setState(() => _subFilter = 2),
                      ),
                      const SizedBox(width: 8),
                      _SubFilterChip(
                        label: l10n.text('categories'),
                        selected: _subFilter == 3,
                        onTap: () => setState(() => _subFilter = 3),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // SUB FILTER CONTENT
                if (_subFilter == 1) ...[
                  const _AgenciesHorizontalBarChartCard(),
                ] else if (_subFilter == 2) ...[
                  _AgenciesListCard(
                    title: l10n.text('workingGroup'),
                    items: _workingGroupItems,
                  ),
                ] else if (_subFilter == 3) ...const [
                  _PlenaryCategoriesListCard(),
                ] else ...[
                  // OVER ALL DONUT CHART 1
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkCard : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isDark
                            ? AppColors.darkBorder
                            : const Color(0xFFE5E8ED),
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
                          badge1DotColor: const Color(0xFF10B981),
                          badge2Text: '7.27%',
                          badge2DotColor: const Color(0xFFF59E0B),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.square,
                                    color: Color(0xFF10B981), size: 10),
                                const SizedBox(width: 6),
                                Text(l10n.text('solved'),
                                    style: const TextStyle(fontSize: 12)),
                              ],
                            ),
                            const Text('(166)',
                                style: TextStyle(
                                    fontSize: 12, fontWeight: FontWeight.w700)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.square,
                                    color: Color(0xFFF59E0B), size: 10),
                                const SizedBox(width: 6),
                                Text(l10n.text('inProgress'),
                                    style: const TextStyle(fontSize: 12)),
                              ],
                            ),
                            const Text('(13)',
                                style: TextStyle(
                                    fontSize: 12, fontWeight: FontWeight.w700)),
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

                  // OVER ALL DONUT CHART 2
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkCard : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isDark
                            ? AppColors.darkBorder
                            : const Color(0xFFE5E8ED),
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
                          badge1DotColor: const Color(0xFF10B981),
                          badge2Text: '92.3%',
                          badge2DotColor: const Color(0xFFF59E0B),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: const [
                            Row(
                              children: [
                                Icon(Icons.square,
                                    color: Color(0xFFF97316), size: 10),
                                SizedBox(width: 6),
                                Text('Mid Progress',
                                    style: TextStyle(fontSize: 12)),
                              ],
                            ),
                            Text('(165)',
                                style: TextStyle(
                                    fontSize: 12, fontWeight: FontWeight.w700)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: const [
                            Row(
                              children: [
                                Icon(Icons.square,
                                    color: Color(0xFFFDE68A), size: 10),
                                SizedBox(width: 6),
                                Text('Early Progress',
                                    style: TextStyle(fontSize: 12)),
                              ],
                            ),
                            Text('(14)',
                                style: TextStyle(
                                    fontSize: 12, fontWeight: FontWeight.w700)),
                          ],
                        ),
                      ],
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

class _AgenciesHorizontalBarChartCard extends StatelessWidget {
  const _AgenciesHorizontalBarChartCard();

  static const _agencyBars = [
    (name: 'SHV Admin', value: 5.2),
    (name: 'MPWT', value: 6.2),
    (name: 'MME', value: 4.8),
    (name: 'MISTI', value: 2.2),
    (name: 'CDC', value: 8.5),
    (name: 'MOL', value: 3.5),
    (name: 'NBC', value: 8.2),
    (name: 'MLMUPC', value: 9.0),
    (name: 'MAFF', value: 1.8),
  ];

  @override
  Widget build(BuildContext context) {
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
              ..._agencyBars.map((item) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
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
                                    : const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                            FractionallySizedBox(
                              widthFactor: (item.value / 10).clamp(0.05, 1.0),
                              child: Container(
                                height: 8,
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
                children: const [
                  SizedBox(width: 72),
                  Text('3',
                      style:
                          TextStyle(color: AppColors.mutedText, fontSize: 10)),
                  Text('2',
                      style:
                          TextStyle(color: AppColors.mutedText, fontSize: 10)),
                  Text('4',
                      style:
                          TextStyle(color: AppColors.mutedText, fontSize: 10)),
                  Text('6',
                      style:
                          TextStyle(color: AppColors.mutedText, fontSize: 10)),
                  Text('7',
                      style:
                          TextStyle(color: AppColors.mutedText, fontSize: 10)),
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
  const _PlenaryCategoriesListCard();

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
            itemCount: _items.length,
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
                          _items[index],
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        '3',
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
                          Expanded(
                            flex: 7,
                            child: Container(color: const Color(0xFF10B981)),
                          ),
                          const SizedBox(width: 2),
                          Expanded(
                            flex: 3,
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
              AppLocalizations.of(context).text('filter'),
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
