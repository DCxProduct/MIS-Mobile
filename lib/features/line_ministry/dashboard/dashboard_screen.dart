import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/app_colors.dart';
import '../../../screens/dashboard/tabs/agencies_tab.dart';
import '../../../screens/dashboard/tabs/categories_tab.dart';
import '../../../screens/dashboard/tabs/working_group_tab.dart';
import '../../../translations/app_localizations.dart';
import '../../../widgets/app_header.dart';

class LineMinistryDashboardScreen extends StatefulWidget {
  const LineMinistryDashboardScreen({super.key});

  @override
  State<LineMinistryDashboardScreen> createState() =>
      _LineMinistryDashboardScreenState();
}

class _LineMinistryDashboardScreenState
    extends State<LineMinistryDashboardScreen> {
  int _selectedStatusTab = 0;

  Set<String> _selectedWorkingGroups = {};
  Set<String> _selectedStatuses = {};
  Set<String> _selectedAgencies = {};
  Set<String> _selectedProgressReports = {};

  Future<void> _openFilterSheet(BuildContext context) async {
    final result = await showModalBottomSheet<_LineMinistryFilterResult>(
      context: context,
      isScrollControlled: true,
      useSafeArea: false,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return _LineMinistryFilterSheet(
          selectedWorkingGroups: _selectedWorkingGroups,
          selectedStatuses: _selectedStatuses,
          selectedAgencies: _selectedAgencies,
          selectedProgressReports: _selectedProgressReports,
        );
      },
    );

    if (result != null) {
      setState(() {
        _selectedWorkingGroups = result.workingGroups;
        _selectedStatuses = result.statuses;
        _selectedAgencies = result.agencies;
        _selectedProgressReports = result.progressReports;
      });
    }
  }

  int get _activeFilterCount {
    return _selectedWorkingGroups.length +
        _selectedStatuses.length +
        _selectedAgencies.length +
        _selectedProgressReports.length;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const AppHeader(),
        Expanded(
          child: ColoredBox(
            color: isDark ? AppColors.darkBackground : const Color(0xFFF5F7FB),
            child: Material(
              color: Colors.transparent,
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 96),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          l10n.text('plenary'),
                          style: TextStyle(
                            color: colors.onSurface,
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const Spacer(),
                        _FilterButton(
                          activeCount: _activeFilterCount,
                          onTap: () => _openFilterSheet(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    const _MetricGrid(isWorkingGroup: false),
                    const SizedBox(height: 8),
                    const _WideMetricCard(),
                    const SizedBox(height: 20),
                    _DashboardTabs(
                      selectedIndex: _selectedStatusTab,
                      onSelected: (index) {
                        setState(() => _selectedStatusTab = index);
                      },
                    ),
                    const SizedBox(height: 14),
                    Text(
                      _statusTitleKey(_selectedStatusTab, l10n),
                      style: TextStyle(
                        color: colors.onSurface,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _StatusTabContent(selectedIndex: _selectedStatusTab),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  String _statusTitleKey(int selectedIndex, AppLocalizations l10n) {
    return switch (selectedIndex) {
      1 => l10n.text('overallStatus'),
      2 => l10n.text('workingGroup'),
      3 => l10n.text('categoriesOfIssues'),
      _ => l10n.text('overallStatus'),
    };
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

class _MetricGrid extends StatelessWidget {
  const _MetricGrid({required this.isWorkingGroup});

  final bool isWorkingGroup;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final totalIssues = isWorkingGroup ? '20' : '56';
    final solved = isWorkingGroup ? '15/20' : '30/56';
    final inProgress = isWorkingGroup ? '4/20' : '16/56';
    final notAddressed = isWorkingGroup ? '1/20' : '10/56';

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
          value: totalIssues,
          background: const Color(0xFFDDEEFF),
          icon: Icons.library_books_outlined,
        ),
        _MetricCard(
          label: l10n.text('solved'),
          value: solved,
          background: const Color(0xFFE5FAEF),
          icon: Icons.fact_check_outlined,
        ),
        _MetricCard(
          label: l10n.text('inProgress'),
          value: inProgress,
          background: const Color(0xFFFFF8DC),
          icon: Icons.add_box_outlined,
        ),
        _MetricCard(
          label: l10n.text('notAddressed'),
          value: notAddressed,
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
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
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
              borderRadius: BorderRadius.circular(10),
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

class _WideMetricCard extends StatelessWidget {
  const _WideMetricCard();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      constraints: const BoxConstraints(minHeight: 30),
      padding: const EdgeInsets.fromLTRB(14, 9, 14, 9),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
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
                  l10n.text('totalPrimaryAgencies'),
                  style: const TextStyle(
                    color: AppColors.mutedText,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '14',
                  style: TextStyle(
                    color: isDark ? Colors.white : const Color(0xFF27364A),
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkBorder : const Color(0xFFF4F6F8),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.calendar_month_outlined,
              color: isDark ? const Color(0xFFE3E8EF) : const Color(0xFF4C5563),
              size: 23,
            ),
          ),
        ],
      ),
    );
  }
}

class _DashboardTabs extends StatelessWidget {
  const _DashboardTabs({
    required this.selectedIndex,
    required this.onSelected,
  });

  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tabs = [
      l10n.text('overall'),
      l10n.text('agencies'),
      l10n.text('workingGroup'),
      l10n.text('categories'),
    ];

    return Container(
      height: 38,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
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
                child: Text(
                  tabs[index],
                  style: TextStyle(
                    color: selectedIndex == index
                        ? Colors.white
                        : AppColors.mutedText,
                    fontSize: 12,
                    fontWeight: selectedIndex == index
                        ? FontWeight.w700
                        : FontWeight.w500,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _StatusTabContent extends StatelessWidget {
  const _StatusTabContent({required this.selectedIndex});

  final int selectedIndex;

  @override
  Widget build(BuildContext context) {
    return switch (selectedIndex) {
      1 => const AgenciesTab(),
      2 => const WorkingGroupTab(),
      3 => const CategoriesTab(),
      _ => const LineMinistryOverallTab(),
    };
  }
}

class LineMinistryOverallTab extends StatelessWidget {
  const LineMinistryOverallTab({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkBackground : Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : const Color(0xFFE9EDF2),
        ),
      ),
      child: Column(
        children: [
          SizedBox(
            width: 320,
            height: 195,
            child: CustomPaint(
              painter: _LineMinistryDonutPainter(isDark: isDark),
            ),
          ),
          const SizedBox(height: 12),
          _ChartLegendRow(
            color: isDark ? AppColors.darkPrimary : const Color(0xFF216AAA),
            label: l10n.text('totalIssues'),
            value: '(56)',
          ),
          _ChartLegendRow(
            color: const Color(0xFF009F5C),
            label: l10n.text('solved'),
            value: '(30)',
          ),
          _ChartLegendRow(
            color: const Color(0xFFF7B51D),
            label: l10n.text('inProgress'),
            value: '(16)',
          ),
          _ChartLegendRow(
            color: const Color(0xFFFF3B30),
            label: l10n.text('notAddressed'),
            value: '(10)',
          ),
        ],
      ),
    );
  }
}

class _LineMinistryDonutPainter extends CustomPainter {
  const _LineMinistryDonutPainter({required this.isDark});

  final bool isDark;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final outerRadius = math.min(size.width, size.height) * 0.43;
    final innerRadius = outerRadius * 0.65;
    const gapAngle = 0.02;

    var startAngle = -math.pi / 2;

    final segments = [
      (
        percent: 0.3154,
        color: isDark ? AppColors.darkPrimary : const Color(0xFF216AAA),
        label: '31.54%',
        offset: const Offset(100, -20),
      ),
      (
        percent: 0.2813,
        color: const Color(0xFF009F5C),
        label: '28.13%',
        offset: const Offset(78, 58),
      ),
      (
        percent: 0.142,
        color: const Color(0xFFFF3B30),
        label: '14.2%',
        offset: const Offset(-92, 34),
      ),
      (
        percent: 0.26,
        color: const Color(0xFFF7B51D),
        label: '25%',
        offset: const Offset(-78, -50),
      ),
    ];

    for (final segment in segments) {
      final sweep = segment.percent * math.pi * 2;

      final path = Path()
        ..addArc(
          Rect.fromCircle(center: center, radius: outerRadius),
          startAngle + gapAngle / 2,
          sweep - gapAngle,
        )
        ..arcTo(
          Rect.fromCircle(center: center, radius: innerRadius),
          startAngle + sweep - gapAngle / 2,
          -(sweep - gapAngle),
          false,
        )
        ..close();

      canvas.drawPath(
        path,
        Paint()
          ..color = segment.color
          ..style = PaintingStyle.fill
          ..isAntiAlias = true,
      );

      startAngle += sweep;
    }

    // Draw center white label
    final painter = TextPainter(
      textAlign: TextAlign.center,
      text: TextSpan(
        children: [
          TextSpan(
            text: 'Total Issues\n',
            style: TextStyle(
              color: isDark ? const Color(0xFFB8C0CC) : const Color(0xFF6C7480),
              fontSize: 11,
              height: 1.25,
              fontWeight: FontWeight.w500,
            ),
          ),
          TextSpan(
            text: '20',
            style: TextStyle(
              color: isDark ? Colors.white : AppColors.text,
              fontSize: 16,
              height: 1.1,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    painter.paint(
      canvas,
      center - Offset(painter.width / 2, painter.height / 2),
    );

    // Draw percent chips
    for (final segment in segments) {
      _drawPercentChip(
        canvas,
        center + segment.offset,
        segment.label,
        segment.color,
      );
    }
  }

  void _drawPercentChip(
    Canvas canvas,
    Offset center,
    String text,
    Color color,
  ) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: const TextStyle(
          color: AppColors.text,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    final chipRect = Rect.fromCenter(
      center: center,
      width: painter.width + 24,
      height: 24,
    );

    final rrect = RRect.fromRectAndRadius(chipRect, const Radius.circular(5));

    canvas.drawShadow(
      Path()..addRRect(rrect),
      Colors.black.withValues(alpha: 0.22),
      5,
      true,
    );

    canvas.drawRRect(rrect, Paint()..color = Colors.white);

    canvas.drawCircle(
      Offset(chipRect.left + 9, center.dy),
      2.2,
      Paint()..color = color,
    );

    painter.paint(
      canvas,
      Offset(chipRect.left + 14, center.dy - painter.height / 2),
    );
  }

  @override
  bool shouldRepaint(covariant _LineMinistryDonutPainter oldDelegate) =>
      oldDelegate.isDark != isDark;
}

class _ChartLegendRow extends StatelessWidget {
  const _ChartLegendRow({
    required this.color,
    required this.label,
    required this.value,
  });

  final Color color;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Row(
        children: [
          Container(
            width: 9,
            height: 9,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: colors.onSurfaceVariant,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: colors.onSurface,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _LineMinistryFilterResult {
  const _LineMinistryFilterResult({
    required this.workingGroups,
    required this.statuses,
    required this.agencies,
    required this.progressReports,
  });

  final Set<String> workingGroups;
  final Set<String> statuses;
  final Set<String> agencies;
  final Set<String> progressReports;
}

class _LineMinistryFilterSheet extends StatefulWidget {
  const _LineMinistryFilterSheet({
    required this.selectedWorkingGroups,
    required this.selectedStatuses,
    required this.selectedAgencies,
    required this.selectedProgressReports,
  });

  final Set<String> selectedWorkingGroups;
  final Set<String> selectedStatuses;
  final Set<String> selectedAgencies;
  final Set<String> selectedProgressReports;

  @override
  State<_LineMinistryFilterSheet> createState() =>
      _LineMinistryFilterSheetState();
}

class _LineMinistryFilterSheetState
    extends State<_LineMinistryFilterSheet> {
  late Set<String> _workingGroups;
  late Set<String> _statuses;
  late Set<String> _agencies;
  late Set<String> _progressReports;

  bool _showAllGroups = false;
  bool _showAllAgencies = false;

  static const _workingGroupItems = [
    'Law, Tax, and Governance',
    'Tourism',
    'Construction and Real Estate',
    'Energy and Mineral Resources',
    'Non-Bank Financial Services Other issues',
    'Agriculture and Agro-Industry',
    'Manufacturing and Industry',
  ];

  static const _statusItems = [
    'Drafted',
    'Submitted',
    'Under Review',
    'Scheduled',
    'Completed',
  ];

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
    'MME',
    'SHV Admin',
    'MOC',
  ];

  static const _progressItems = [
    'Both',
    'S1',
    'S2',
  ];

  @override
  void initState() {
    super.initState();
    _workingGroups = {...widget.selectedWorkingGroups};
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
                      // Section 1: Working Group
                      Text(
                        l10n.text('workingGroup'),
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 14),
                      _WorkingGroupList(
                        items: _showAllGroups
                            ? _workingGroupItems
                            : _workingGroupItems.take(5).toList(),
                        selectedItems: _workingGroups,
                        onChanged: (value) => _toggle(_workingGroups, value),
                      ),
                      const SizedBox(height: 8),
                      Center(
                        child: InkWell(
                          onTap: () {
                            setState(() {
                              _showAllGroups = !_showAllGroups;
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
                                  _showAllGroups
                                      ? l10n.text('viewLess')
                                      : l10n.text('viewAll'),
                                  style: TextStyle(
                                    color: AppColors.accent(context),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Icon(
                                  _showAllGroups
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

                      const SizedBox(height: 24),

                      // Section 2: Status
                      _FilterGridSection(
                        title: l10n.text('status'),
                        items: _statusItems,
                        columns: 3,
                        selectedItems: _statuses,
                        onChanged: (value) => _toggle(_statuses, value),
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
                        onChanged: (value) => _toggle(_agencies, value),
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
                        items: _progressItems,
                        columns: 3,
                        selectedItems: _progressReports,
                        onChanged: (value) =>
                            _toggle(_progressReports, value),
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
                        _LineMinistryFilterResult(
                          workingGroups: {..._workingGroups},
                          statuses: {..._statuses},
                          agencies: {..._agencies},
                          progressReports: {
                            ..._progressReports,
                          },
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

class _WorkingGroupList extends StatelessWidget {
  const _WorkingGroupList({
    required this.items,
    required this.selectedItems,
    required this.onChanged,
  });

  final List<String> items;
  final Set<String> selectedItems;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: items.map((item) {
        final selected = selectedItems.contains(item);
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _CheckTile(
            label: item,
            selected: selected,
            onTap: () => onChanged(item),
          ),
        );
      }).toList(),
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
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.filterLabel,
                fontSize: 11,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
        ],
      ),
    );
  }
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
              : (isDark ? AppColors.darkBorder : AppColors.filterOutline),
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
