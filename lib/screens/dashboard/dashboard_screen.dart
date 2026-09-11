import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/app_colors.dart';
import '../../screens/account/account_screen.dart';
import '../../screens/issues/issues_screen.dart';
import '../../screens/meeting/meeting_screen.dart';
import '../../screens/notification/notification_screen.dart';
import '../../screens/report/report_screen.dart';
import '../../translations/app_localizations.dart';
import '../../widgets/app_logo.dart';
import 'tabs/agencies_tab.dart';
import 'tabs/categories_tab.dart';
import 'tabs/overall_tab.dart';
import 'tabs/working_group_tab.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool isLoading = true;
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() => isLoading = false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const DashboardLoadingScreen();
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final background = isDark ? AppColors.darkBackground : Colors.white;
    final body = switch (_selectedIndex) {
      0 => const _DashboardPage(),
      1 => const MeetingScreen(),
      2 => const IssuesScreen(),
      3 => const ReportScreen(),
      _ => const AccountScreen(),
    };

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: background,
        statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
        statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
        systemNavigationBarColor: background,
        systemNavigationBarIconBrightness: isDark
            ? Brightness.light
            : Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: background,
        extendBody: true,
        body: SafeArea(bottom: false, child: body),
        bottomNavigationBar: _BottomNavBar(
          selectedIndex: _selectedIndex,
          onSelected: (index) => setState(() => _selectedIndex = index),
        ),
      ),
    );
  }
}

class _DashboardPage extends StatefulWidget {
  const _DashboardPage();

  @override
  State<_DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<_DashboardPage> {
  int _selectedScopeTab = 0;
  int _selectedStatusTab = 0;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _DashboardHeader(),
        Expanded(
          child: ColoredBox(
            color: isDark ? AppColors.darkBackground : const Color(0xFFF5F7FB),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 96),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _ScopeHeader(
                    selectedIndex: _selectedScopeTab,
                    onSelected: (index) {
                      setState(() => _selectedScopeTab = index);
                    },
                  ),
                  const SizedBox(height: 12),
                  const _FilterBar(),
                  const SizedBox(height: 14),
                  _MetricGrid(isWorkingGroup: _selectedScopeTab == 1),
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

class DashboardLoadingScreen extends StatefulWidget {
  const DashboardLoadingScreen({super.key});

  @override
  State<DashboardLoadingScreen> createState() => _DashboardLoadingScreenState();
}

class _DashboardLoadingScreenState extends State<DashboardLoadingScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget skeleton({
    required double width,
    required double height,
    double radius = 8,
  }) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(radius),
            gradient: LinearGradient(
              begin: Alignment(-1 + _controller.value * 2, 0),
              end: Alignment(1 + _controller.value * 2, 0),
              colors: isDark
                  ? const [
                      Color(0xFF191B24),
                      Color(0xFF283143),
                      Color(0xFF191B24),
                    ]
                  : const [
                      Color(0xFFE2E2E2),
                      Color(0xFFF6F6F6),
                      Color(0xFFE2E2E2),
                    ],
            ),
          ),
        );
      },
    );
  }

  Widget cardSkeleton({double height = 90}) {
    return Builder(
      builder: (context) => Container(
        height: height,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.cardBackground(context),
          border: Border.all(color: AppColors.border(context)),
          borderRadius: BorderRadius.circular(9),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            skeleton(width: double.infinity, height: 8, radius: 4),
            const SizedBox(height: 14),
            skeleton(width: 54, height: 22, radius: 14),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pageBackground(context),
      body: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 36, 16, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  skeleton(width: 88, height: 30, radius: 18),
                  const Spacer(),
                  skeleton(width: 34, height: 34, radius: 18),
                ],
              ),
              const SizedBox(height: 58),
              skeleton(width: 158, height: 16, radius: 8),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(child: cardSkeleton()),
                  const SizedBox(width: 10),
                  Expanded(child: cardSkeleton()),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(child: cardSkeleton()),
                  const SizedBox(width: 10),
                  Expanded(child: cardSkeleton()),
                ],
              ),
              const SizedBox(height: 10),
              cardSkeleton(height: 92),
              const SizedBox(height: 24),
              skeleton(width: 235, height: 10, radius: 8),
              const SizedBox(height: 16),
              Expanded(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: AppColors.cardBackground(context),
                    border: Border.all(color: AppColors.border(context)),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    children: [
                      const SizedBox(height: 10),
                      skeleton(width: 206, height: 206, radius: 120),
                      const Spacer(),
                      Row(
                        children: [
                          Column(
                            children: [
                              skeleton(width: 102, height: 6, radius: 4),
                              const SizedBox(height: 14),
                              skeleton(width: 102, height: 6, radius: 4),
                            ],
                          ),
                          const Spacer(),
                          Column(
                            children: [
                              skeleton(width: 102, height: 6, radius: 4),
                              const SizedBox(height: 14),
                              skeleton(width: 102, height: 6, radius: 4),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Container(
        height: 82,
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
        decoration: BoxDecoration(
          color: AppColors.cardBackground(context),
          border: Border.all(color: AppColors.border(context)),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(
            5,
            (_) => Column(
              children: [
                skeleton(width: 30, height: 30, radius: 5),
                const SizedBox(height: 10),
                skeleton(width: 62, height: 6, radius: 4),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DashboardHeader extends StatelessWidget {
  const _DashboardHeader();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      color: isDark
          ? AppColors.darkBackground
          : Theme.of(context).scaffoldBackgroundColor,
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
      child: Row(
        children: [
          const AppLogo(width: 106),
          const Spacer(),
          InkWell(
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const NotificationScreen(),
                ),
              );
            },
            customBorder: const CircleBorder(),
            child: Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.darkPrimaryContainer
                    : const Color(0xFFE4F2FF),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.notifications,
                color: isDark ? AppColors.darkPrimary : const Color(0xFF5AA7E8),
                size: 22,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ScopeHeader extends StatelessWidget {
  const _ScopeHeader({required this.selectedIndex, required this.onSelected});

  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final labels = [l10n.text('plenary'), l10n.text('workingGroup')];

    return Row(
      children: [
        Expanded(
          child: Text(
            labels[selectedIndex],
            style: TextStyle(
              color: colors.onSurface,
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Container(
          height: 30,
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkPrimaryContainer : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? AppColors.darkBorder : const Color(0xFFE8EBF0),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(
              labels.length,
              (index) => _ScopePill(
                label: labels[index],
                selected: selectedIndex == index,
                onTap: () => onSelected(index),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ScopePill extends StatelessWidget {
  const _ScopePill({
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
      borderRadius: BorderRadius.circular(14),
      child: Container(
        height: 24,
        constraints: const BoxConstraints(minWidth: 64),
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 11),
        decoration: BoxDecoration(
          color: selected ? AppColors.accent(context) : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected
                ? Colors.white
                : (AppColors.isDark(context)
                      ? const Color(0xFFB9D7ED)
                      : AppColors.primary),
            fontSize: 12,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

class _FilterBar extends StatelessWidget {
  const _FilterBar();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return SizedBox(
      height: 36,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _FilterChip(label: l10n.text('year'), width: 108),
          const SizedBox(width: 8),
          _FilterChip(label: l10n.text('status'), width: 108),
          const SizedBox(width: 8),
          _FilterChip(label: l10n.text('primaryAgency'), width: 148),
          const SizedBox(width: 8),
          _FilterChip(label: l10n.text('progressReport'), width: 148),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({required this.label, required this.width});

  final String label;
  final double width;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : const Color(0xFFE8EBF0),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.mutedText,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Icon(
            Icons.keyboard_arrow_down,
            color: Theme.of(context).colorScheme.onSurface,
            size: 17,
          ),
        ],
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
    final totalIssues = isWorkingGroup ? '20' : '179';
    final solved = isWorkingGroup ? '15/20' : '166/179';
    final inProgress = isWorkingGroup ? '4/20' : '13/179';
    final notAddressed = isWorkingGroup ? '1/20' : '0/179';

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
                  '14/14',
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
        color: isDark ? AppColors.darkBackground : Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : const Color(0xFFE8EBF0),
        ),
      ),
      child: Row(
        children: List.generate(
          tabs.length,
          (index) => _TabPill(
            label: tabs[index],
            selected: selectedIndex == index,
            onTap: () => onSelected(index),
          ),
        ),
      ),
    );
  }
}

class _TabPill extends StatelessWidget {
  const _TabPill({
    required this.label,
    required this.onTap,
    this.selected = false,
  });

  final String label;
  final VoidCallback onTap;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? AppColors.accent(context) : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
          ),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              label,
              style: TextStyle(
                color: selected ? Colors.white : AppColors.mutedText,
                fontSize: 11,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
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

class _BottomNavBar extends StatelessWidget {
  const _BottomNavBar({required this.selectedIndex, required this.onSelected});

  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context);
    final items = [
      (icon: Icons.dashboard_outlined, label: l10n.text('dashboard')),
      (icon: Icons.calendar_month_outlined, label: l10n.text('meeting')),
      (icon: Icons.assignment_outlined, label: l10n.text('issues')),
      (icon: Icons.folder_outlined, label: l10n.text('report')),
      (icon: Icons.account_circle_outlined, label: l10n.text('account')),
    ];

    return Container(
      height: 82,
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkBackground : Colors.white,
        border: Border.all(
          color: isDark ? AppColors.darkBorder : const Color(0xFFE8EBF0),
        ),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
      ),
      child: Row(
        children: [
          for (var index = 0; index < items.length; index++)
            _NavItem(
              icon: items[index].icon,
              label: items[index].label,
              selected: selectedIndex == index,
              onTap: () => onSelected(index),
            ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.selected = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final color = selected
        ? AppColors.accent(context)
        : const Color(0xFFA4ABB4);

    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 23),
            const SizedBox(height: 3),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 12,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
