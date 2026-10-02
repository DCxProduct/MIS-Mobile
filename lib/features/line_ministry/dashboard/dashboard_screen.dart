import '../../../core/app_settings.dart';
import '../../../core/widgets/filters/api_filter_sheet.dart';
import '../../shared/dashboard/widgets/pswg_live_dashboard.dart';
import '../../shared/dashboard/data/dashboard_repository.dart';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/app_colors.dart';
import '../../private_sector/dashboard/tabs/agencies_tab.dart';
import '../../private_sector/dashboard/tabs/categories_tab.dart';
import '../../private_sector/dashboard/tabs/working_group_tab.dart';
import '../../private_sector/dashboard/tabs/overall_tab.dart';
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

  FilterSelection _filters = FilterSelection();
  Future<void> _openFilterSheet(BuildContext context) async {
    final catalogs = AppSettings.of(context).filters;
    final result = await Navigator.of(context).push<FilterSelection>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => ApiFilterSheet(
          initial: _filters,
          load: () => catalogs.dashboard('pswg'),
        ),
      ),
    );
    if (!mounted || result == null) return;
    setState(() => _filters = result);
  }

  int get _activeFilterCount => _filters.count;

  @override
  Widget build(BuildContext context) {
    return PswgDataLoader(
      selection: _filters,
      scope: DashboardScope.pswg,
      progressReportId: int.tryParse(
        _filters.toQuery()['progressReportId'] ?? '',
      ),
      builder: _buildContent,
    );
  }

  Widget _buildContent(BuildContext context) {
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

class _MetricGrid extends StatelessWidget {
  const _MetricGrid({required this.isWorkingGroup});

  final bool isWorkingGroup;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cards = PswgDataScope.maybeOf(context)?.cards;
    final totalIssues = cards == null
        ? (isWorkingGroup ? '20' : '56')
        : '${cards['totalIssues']}';
    final solved = cards == null
        ? (isWorkingGroup ? '15/20' : '30/56')
        : '${cards['solved']}/$totalIssues';
    final inProgress = cards == null
        ? (isWorkingGroup ? '4/20' : '16/56')
        : '${cards['inProgress']}/$totalIssues';
    final notAddressed = cards == null
        ? (isWorkingGroup ? '1/20' : '10/56')
        : '${cards['notAddressed']}/$totalIssues';

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
                  '${PswgDataScope.maybeOf(context)?.cards['totalPrimaryAgencies'] ?? 14}',
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
  const _DashboardTabs({required this.selectedIndex, required this.onSelected});

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
      _ => const OverallTab(),
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
