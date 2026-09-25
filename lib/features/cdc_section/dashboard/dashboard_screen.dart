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

  static const _wgWorkingGroupItems = [
    '(A) Agriculture and Agro-industry',
    '(E) Banking and Financial Services',
    '(M) Construction and Real Estate',
    '(O) Digital Economy, Society and Telecommunication',
    '(G) Export Processing and Trade Facilitation',
    '(H) Industrial Relations',
    '(D) Law, Tax, and Governance',
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

    final isPlenary = _mainTab == 0;

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
                            if (isPlenary) {
                              return const CdcSectionDashboardFilterSheet();
                            } else {
                              return const CdcSectionWorkingGroupFilterSheet();
                            }
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
                      value: isPlenary ? '166/179' : '166/179',
                      background: const Color(0xFFE5FAEF),
                      icon: Icons.fact_check_outlined,
                    ),
                    _MetricCard(
                      label: l10n.text('inProgress'),
                      value: isPlenary ? '13/179' : '13/179',
                      background: const Color(0xFFFFF8DC),
                      icon: Icons.add_box_outlined,
                    ),
                    _MetricCard(
                      label: l10n.text('notAddressed'),
                      value: isPlenary ? '0/179' : '0/179',
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
                  if (isPlenary)
                    const _PlenaryAgenciesHorizontalBarChartCard()
                  else
                    const _WorkingGroupAgenciesHorizontalBarChartCard(),
                ] else if (_subFilter == 2) ...[
                  if (isPlenary)
                    const _PlenaryWorkingGroupListCard()
                  else
                    _AgenciesListCard(
                      title: l10n.text('workingGroup'),
                      items: _wgWorkingGroupItems,
                    ),
                ] else if (_subFilter == 3) ...[
                  if (isPlenary)
                    const _PlenaryCategoriesListCard()
                  else
                    const _WorkingGroupCategoriesListCard(),
                ] else ...[
                  // OVER ALL DONUT CHART
                  if (isPlenary) ...[
                    // PLENARY CHART 1
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
                    // PLENARY CHART 2
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
                  ] else ...[
                    // WORKING GROUP MAIN TAB OVERALL CHART (FIGMA 100% MATCH)
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
                          color: isDark
                              ? AppColors.darkBorder
                              : const Color(0xFFE5E8ED),
                        ),
                      ),
                      child: Column(
                        children: [
                          _WorkingGroupDonutChartWidget(
                            centerTitle: l10n.text('totalIssues'),
                            centerValue: '20',
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.square,
                                      color: Color(0xFF1E73BE), size: 10),
                                  const SizedBox(width: 6),
                                  Text(l10n.text('totalIssues'),
                                      style: const TextStyle(fontSize: 12)),
                                ],
                              ),
                              const Text('(56)',
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
                                      color: Color(0xFF10B981), size: 10),
                                  const SizedBox(width: 6),
                                  Text(l10n.text('solved'),
                                      style: const TextStyle(fontSize: 12)),
                                ],
                              ),
                              const Text('(30)',
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
                                      color: Color(0xFFEAB308), size: 10),
                                  const SizedBox(width: 6),
                                  Text(l10n.text('inProgress'),
                                      style: const TextStyle(fontSize: 12)),
                                ],
                              ),
                              const Text('(16)',
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
                                      color: Color(0xFFEF4444), size: 10),
                                  const SizedBox(width: 6),
                                  Text(l10n.text('notAddressed'),
                                      style: const TextStyle(fontSize: 12)),
                                ],
                              ),
                              const Text('(10)',
                                  style: TextStyle(
                                      fontSize: 12, fontWeight: FontWeight.w700)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DonutChartPainter extends CustomPainter {
  const _DonutChartPainter({
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

class _WorkingGroupDonutChartWidget extends StatelessWidget {
  const _WorkingGroupDonutChartWidget({
    required this.centerTitle,
    required this.centerValue,
  });

  final String centerTitle;
  final String centerValue;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 195,
      width: 250,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: const Size(165, 165),
            painter: _DonutChartPainter(
              slices: const [
                DonutChartData(
                  percentage: 0.5357,
                  color: Color(0xFF10B981),
                  label: 'Solved',
                ),
                DonutChartData(
                  percentage: 0.1786,
                  color: Color(0xFFEF4444),
                  label: 'Not Addressed',
                ),
                DonutChartData(
                  percentage: 0.2857,
                  color: Color(0xFFEAB308),
                  label: 'In Progress',
                ),
              ],
              startAngle: -0.4,
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
          // BADGE 1: Yellow Top-Right (28.57%)
          const Positioned(
            top: 25,
            right: 28,
            child: _PercentageBadge(
              percentText: '28.57%',
              dotColor: Color(0xFFEAB308),
            ),
          ),
          // BADGE 2: Red Left (17.86%)
          const Positioned(
            top: 60,
            left: -12,
            child: _PercentageBadge(
              percentText: '17.86%',
              dotColor: Color(0xFFEF4444),
            ),
          ),
          // BADGE 3: Green Bottom-Right (53.57%)
          const Positioned(
            bottom: 14,
            right: 18,
            child: _PercentageBadge(
              percentText: '53.57%',
              dotColor: Color(0xFF10B981),
            ),
          ),
        ],
      ),
    );
  }
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
            width: 6,
            height: 6,
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

class _PlenaryWorkingGroupListCard extends StatelessWidget {
  const _PlenaryWorkingGroupListCard();

  static const _items = [
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context).text('workingGroup'),
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
            itemCount: _items.length,
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
                        _items[index],
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

class _PlenaryAgenciesHorizontalBarChartCard extends StatelessWidget {
  const _PlenaryAgenciesHorizontalBarChartCard();

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

class _WorkingGroupAgenciesHorizontalBarChartCard extends StatelessWidget {
  const _WorkingGroupAgenciesHorizontalBarChartCard();

  static const _agencyBars = [
    (name: 'CDC', value: 6.8),
    (name: 'GDCE', value: 8.0),
    (name: 'GDT', value: 6.0),
    (name: 'MAFF', value: 3.2),
    (name: 'MFF', value: 9.2),
    (name: 'MISTI', value: 4.8),
    (name: 'MLMUPC', value: 8.8),
    (name: 'MLVT', value: 10.0),
    (name: 'MPTC', value: 2.5),
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

class _WorkingGroupCategoriesListCard extends StatelessWidget {
  const _WorkingGroupCategoriesListCard();

  static const _items = [
    'Government',
    'Taxation',
    'Human Resource',
    'Trade',
    'Legislation',
    'Procedure',
    'Market',
    'Policy',
    'Strategy',
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

class CdcSectionDashboardFilterSheet extends StatefulWidget {
  const CdcSectionDashboardFilterSheet({super.key});

  @override
  State<CdcSectionDashboardFilterSheet> createState() =>
      _CdcSectionDashboardFilterSheetState();
}

class _CdcSectionDashboardFilterSheetState extends State<CdcSectionDashboardFilterSheet> {
  final Set<String> _plenaries = {};
  final Set<String> _statuses = {};
  final Set<String> _workingGroups = {};
  final Set<String> _agencies = {};
  final Set<String> _years = {};
  final Set<String> _progressReports = {};

  bool _expandWorkingGroup = false;
  bool _expandAgencies = false;

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

  static const _yearItems = ['2026', '2025', '2024', '2023'];
  static const _progressItems = ['S1 2025', 'S2 2025'];

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
    final l10n = AppLocalizations.of(context);
    final background = isDark ? AppColors.darkBackground : Colors.white;

    final viewPadding = MediaQuery.of(context).viewPadding;
    final topInset = viewPadding.top > 48.0 ? viewPadding.top : 48.0;

    final visibleWg = _expandWorkingGroup
        ? _workingGroupItems
        : _workingGroupItems.take(5).toList();

    final visibleAgencies = _expandAgencies
        ? _agencyItems
        : _agencyItems.take(10).toList();

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
                      l10n.text('filters'),
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
                  Text(
                    l10n.text('plenary'),
                    style: const TextStyle(
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

                  // 2. WORKING GROUP
                  Text(
                    l10n.text('workingGroup'),
                    style: const TextStyle(
                      color: AppColors.mutedText,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: visibleWg
                        .map(
                          (item) => Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: _FilterChipCheckbox(
                              label: item,
                              checked: _workingGroups.contains(item),
                              onTap: () => _toggle(_workingGroups, item),
                            ),
                          ),
                        )
                        .toList(),
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
                            _expandWorkingGroup
                                ? l10n.text('viewLess')
                                : l10n.text('viewAll'),
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

                  // 3. STATUS
                  Text(
                    l10n.text('status'),
                    style: const TextStyle(
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

                  // 4. PRIMARY AGENCY
                  Text(
                    l10n.text('primaryAgency'),
                    style: const TextStyle(
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
                            _expandAgencies
                                ? l10n.text('viewLess')
                                : l10n.text('viewAll'),
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

                  // 5. YEAR
                  Text(
                    l10n.text('year'),
                    style: const TextStyle(
                      color: AppColors.mutedText,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 16,
                    runSpacing: 8,
                    children: _yearItems.map((item) {
                      return _FilterChipCheckbox(
                        label: item,
                        checked: _years.contains(item),
                        onTap: () => _toggle(_years, item),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),

                  // 6. PROGRESS REPORT
                  Text(
                    l10n.text('progressReport'),
                    style: const TextStyle(
                      color: AppColors.mutedText,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 16,
                    runSpacing: 8,
                    children: _progressItems.map((item) {
                      return _FilterChipCheckbox(
                        label: item,
                        checked: _progressReports.contains(item),
                        onTap: () => _toggle(_progressReports, item),
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
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    l10n.text('applyFilters'),
                    style: const TextStyle(
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
              label,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CdcSectionWorkingGroupFilterSheet extends StatefulWidget {
  const CdcSectionWorkingGroupFilterSheet({super.key});

  @override
  State<CdcSectionWorkingGroupFilterSheet> createState() =>
      _CdcSectionWorkingGroupFilterSheetState();
}

class _CdcSectionWorkingGroupFilterSheetState
    extends State<CdcSectionWorkingGroupFilterSheet> {
  final Set<String> _workingGroups = {};
  final Set<String> _statuses = {};
  final Set<String> _agencies = {};
  final Set<String> _years = {};
  final Set<String> _progressReports = {};

  bool _expandWorkingGroup = false;
  bool _expandAgencies = false;

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

  static const _statusOptions = ['Solved', 'In Progress', 'Not Address'];

  static const _agencyItems = [
    'GDT', 'MFF', 'GDCE', 'MLVT', 'MPTC',
    'MAFF', 'Moh', 'NBC', 'MoC', 'MoT',
    'MLMUPC', 'Mol', 'CDC', 'MPWT',
    'MISTI', 'MME', 'SHV Admin', 'MOC',
  ];

  static const _yearItems = ['2026', '2025', '2024', '2023'];
  static const _progressItems = ['S1 2025', 'S2 2025'];

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
    final l10n = AppLocalizations.of(context);
    final background = isDark ? AppColors.darkBackground : Colors.white;

    final viewPadding = MediaQuery.of(context).viewPadding;
    final topInset = viewPadding.top > 48.0 ? viewPadding.top : 48.0;

    final visibleWg = _expandWorkingGroup
        ? _workingGroupItems
        : _workingGroupItems.take(5).toList();

    final visibleAgencies = _expandAgencies
        ? _agencyItems
        : _agencyItems.take(10).toList();

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
                      l10n.text('filters'),
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
                padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 20),
                children: [
                  // 1. WORKING GROUP
                  Text(
                    l10n.text('workingGroup'),
                    style: const TextStyle(
                      color: AppColors.mutedText,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: visibleWg
                        .map(
                          (item) => Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: _FilterChipCheckbox(
                              label: item,
                              checked: _workingGroups.contains(item),
                              onTap: () => _toggle(_workingGroups, item),
                            ),
                          ),
                        )
                        .toList(),
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
                            _expandWorkingGroup
                                ? l10n.text('viewLess')
                                : l10n.text('viewAll'),
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

                  // 2. STATUS
                  Text(
                    l10n.text('status'),
                    style: const TextStyle(
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

                  // 3. PRIMARY AGENCY
                  Text(
                    l10n.text('primaryAgency'),
                    style: const TextStyle(
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
                            _expandAgencies
                                ? l10n.text('viewLess')
                                : l10n.text('viewAll'),
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

                  // 4. YEAR
                  Text(
                    l10n.text('year'),
                    style: const TextStyle(
                      color: AppColors.mutedText,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 16,
                    runSpacing: 8,
                    children: _yearItems.map((item) {
                      return _FilterChipCheckbox(
                        label: item,
                        checked: _years.contains(item),
                        onTap: () => _toggle(_years, item),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),

                  // 5. PROGRESS REPORT
                  Text(
                    l10n.text('progressReport'),
                    style: const TextStyle(
                      color: AppColors.mutedText,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 16,
                    runSpacing: 8,
                    children: _progressItems.map((item) {
                      return _FilterChipCheckbox(
                        label: item,
                        checked: _progressReports.contains(item),
                        onTap: () => _toggle(_progressReports, item),
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
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    l10n.text('applyFilters'),
                    style: const TextStyle(
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
