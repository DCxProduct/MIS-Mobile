import '../../../core/widgets/filters/api_filter_sheet.dart';
import '../../shared/dashboard/data/dashboard_repository.dart';
import '../../shared/dashboard/widgets/pswg_live_dashboard.dart';
import '../../cdc_secretariat/dashboard/filter_sheet.dart';
import '../../cdc_secretariat/dashboard/categories_tab.dart';
import '../../cdc_secretariat/dashboard/working_group_tab.dart';
import '../../cdc_secretariat/dashboard/agencies_tab.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/app_colors.dart';
import '../../../core/app_settings.dart';
import '../../../core/config/module_config.dart';
import '../../../screens/account/account_screen.dart';
import '../../../translations/app_localizations.dart';
import '../../../widgets/app_bottom_nav_bar.dart';
import '../../../widgets/app_header.dart';

import '../../cdc_secretariat/dashboard/dashboard_screen.dart';
import '../../cdc_secretariat/issues/issues_screen.dart';
import '../../cdc_secretariat/meetings/meeting_screen.dart';
import '../../cdc_secretariat/profile/profile_screen.dart';
import '../../cdc_secretariat/reports/reports_screen.dart';

import '../../cdc_section/dashboard/dashboard_screen.dart';
import '../../cdc_section/issues/issues_screen.dart';
import '../../cdc_section/issues/cdc_issues_matrix_screen.dart';
import '../../cdc_section/profile/profile_screen.dart';
import '../../cdc_section/reports/reports_screen.dart';

import '../../cefp/dashboard/dashboard_screen.dart';
import '../../cefp/issues/issues_screen.dart';
import '../../cefp/issues/cdc_issues_matrix_screen.dart';
import '../../cefp/profile/profile_screen.dart';
import '../../cefp/reports/reports_screen.dart';

import '../../line_ministry/dashboard/dashboard_screen.dart';
import '../../line_ministry/issues/issues_screen.dart';
import '../../line_ministry/meetings/meeting_screen.dart';
import '../../line_ministry/profile/profile_screen.dart';
import '../../line_ministry/reports/reports_screen.dart';

import '../issues/issues_screen.dart';
import '../meetings/meeting_screen.dart';
import '../reports/reports_screen.dart';
import 'tabs/agencies_tab.dart';
import 'tabs/categories_tab.dart';
import 'tabs/overall_tab.dart';
import '../../cdc_secretariat/dashboard/overall_tab.dart';
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

  Widget _buildBodyForModule(AppModuleType moduleType, int index) {
    return switch (moduleType) {
      AppModuleType.lineMinistry => switch (index) {
        0 => const LineMinistryDashboardScreen(),
        1 => const LineMinistryMeetingScreenView(),
        2 => const LineMinistryIssuesScreenView(),
        3 => const LineMinistryReportsScreenView(),
        _ => const LineMinistryProfileScreenView(),
      },
      AppModuleType.cdcSection => switch (index) {
        0 => const CdcSectionDashboardScreenView(),
        1 => const CdcSectionIssuesMatrixScreen(),
        2 => const CdcSectionIssuesScreenView(),
        3 => const CdcSectionReportsScreenView(),
        _ => const CdcSectionProfileScreenView(),
      },
      AppModuleType.cefp => switch (index) {
        0 => const CefpDashboardScreenView(),
        1 => const CefpIssuesMatrixScreen(),
        2 => const CefpIssuesScreenView(),
        3 => const CefpReportsScreenView(),
        _ => const CefpProfileScreenView(),
      },
      AppModuleType.cdcSecretariat => switch (index) {
        0 => const CdcSecretariatDashboardScreenView(),
        1 => const CdcSecretariatMeetingScreenView(),
        2 => const CdcSecretariatIssuesScreenView(),
        3 => const CdcSecretariatReportsScreenView(),
        _ => const CdcSecretariatProfileScreenView(),
      },
      AppModuleType.privateSector => switch (index) {
        0 => const DashboardPage(),
        1 => const MeetingScreen(),
        2 => const IssuesScreen(),
        3 => const ReportScreen(),
        _ => const AccountScreen(),
      },
    };
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const DashboardLoadingScreen();
    }

    final moduleType = AppSettings.of(context).moduleType;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final background = isDark
        ? AppColors.darkBackground
        : const Color(0xFFF5F7FB);
    final body = _buildBodyForModule(moduleType, _selectedIndex);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
        statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
        systemNavigationBarColor: background,
        systemNavigationBarIconBrightness: isDark
            ? Brightness.light
            : Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: background,
        extendBody:
            !(_selectedIndex == 0 &&
                (moduleType == AppModuleType.cdcSection ||
                    moduleType == AppModuleType.cefp)),
        body: body,
        bottomNavigationBar: AppBottomNavBar(
          selectedIndex: _selectedIndex,
          onSelected: (index) => setState(() => _selectedIndex = index),
        ),
      ),
    );
  }
}

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => DashboardPageState();
}

class DashboardPageState extends State<DashboardPage> {
  CdcDashboardFilters _cdcFilters = CdcDashboardFilters();
  int _selectedScopeTab = 0;
  int _selectedStatusTab = 0;

  final _dashboardFilters = [FilterSelection(), FilterSelection()];
  int get _filterTab =>
      AppSettings.of(context).moduleType == AppModuleType.cdcSecretariat
      ? 1
      : _selectedScopeTab;
  Future<void> _openFilterSheet(BuildContext context) async {
    final tab = _filterTab;
    final catalogs = AppSettings.of(context).filters;
    final result = await Navigator.of(context).push<FilterSelection>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => ApiFilterSheet(
          initial: _dashboardFilters[tab],
          load: () => catalogs.dashboard(tab == 0 ? 'plenary' : 'pswg'),
        ),
      ),
    );
    if (!mounted || result == null) return;
    setState(() {
      _dashboardFilters[tab] = result;
      _cdcFilters = result;
    });
  }

  int? get _reportId => int.tryParse(
    _dashboardFilters[_filterTab].toQuery()['progressReportId'] ?? '',
  );

  @override
  Widget build(BuildContext context) {
    final module = AppSettings.of(context).moduleType;
    if (module == AppModuleType.privateSector || module == AppModuleType.cefp) {
      return PswgDataLoader(
        selection: _dashboardFilters[_filterTab],
        progressReportId: _reportId,
        scope: _selectedScopeTab == 0
            ? DashboardScope.plenary
            : DashboardScope.pswg,
        builder: _buildContent,
      );
    }
    if (module == AppModuleType.cdcSecretariat) {
      return PswgDataLoader(
        selection: _dashboardFilters[_filterTab],
        scope: DashboardScope.pswg,
        progressReportId: _reportId,
        builder: _buildContent,
      );
    }
    if (_selectedStatusTab == 2) {
      return PswgDataLoader(
        selection: _dashboardFilters[_filterTab],
        progressReportId: _reportId,
        builder: _buildContent,
      );
    }
    return _buildContent(context);
  }

  Widget _buildContent(BuildContext context) {
    final moduleType = AppSettings.of(context).moduleType;
    if (moduleType == AppModuleType.lineMinistry) {
      return const LineMinistryDashboardScreen();
    }

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
                    if (moduleType != AppModuleType.cdcSecretariat)
                      _ScopeTitle(selectedIndex: _selectedScopeTab),
                    const SizedBox(height: 10),
                    if (moduleType == AppModuleType.privateSector)
                      Row(
                        children: [
                          Expanded(
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: _ScopeSelector(
                                selectedIndex: _selectedScopeTab,
                                onSelected: (index) {
                                  setState(() => _selectedScopeTab = index);
                                },
                              ),
                            ),
                          ),
                          _FilterBar(
                            onTap: () => _openFilterSheet(context),
                            activeCount: _dashboardFilters[_filterTab].count,
                          ),
                        ],
                      )
                    else if (moduleType == AppModuleType.cdcSecretariat)
                      Row(
                        children: [
                          Text(
                            l10n.text('dashboard'),
                            style: TextStyle(
                              color: colors.onSurface,
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const Spacer(),
                          _FilterBar(
                            onTap: () => _openFilterSheet(context),
                            activeCount: _cdcFilters.count,
                          ),
                        ],
                      )
                    else
                      Wrap(
                        alignment: WrapAlignment.spaceBetween,
                        runSpacing: 8,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          _ScopeSelector(
                            selectedIndex: _selectedScopeTab,
                            onSelected: (index) {
                              setState(() => _selectedScopeTab = index);
                            },
                          ),
                          _FilterBar(
                            onTap: () => _openFilterSheet(context),
                            activeCount: _dashboardFilters[_filterTab].count,
                          ),
                        ],
                      ),
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
        ),
      ],
    );
  }

  String _statusTitleKey(int selectedIndex, AppLocalizations l10n) {
    return switch (selectedIndex) {
      1 => l10n.text('agencies'),
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
                      Color(0xFFF2F2F2),
                      Color(0xFFE2E2E2),
                    ],
            ),
          ),
        );
      },
    );
  }

  Widget cardSkeleton({double height = 72}) {
    return Container(
      width: double.infinity,
      height: height,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.cardBackground(context),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          skeleton(width: 80, height: 10, radius: 4),
          const SizedBox(height: 10),
          skeleton(width: 110, height: 14, radius: 4),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pageBackground(context),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  skeleton(width: 120, height: 26, radius: 6),
                  const Spacer(),
                  skeleton(width: 32, height: 32, radius: 16),
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
                      Expanded(
                        child: Center(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: skeleton(
                              width: 206,
                              height: 206,
                              radius: 120,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
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

class _ScopeTitle extends StatelessWidget {
  const _ScopeTitle({required this.selectedIndex});

  final int selectedIndex;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).colorScheme;
    final labels = [l10n.text('plenary'), l10n.text('workingGroup')];

    return Text(
      labels[selectedIndex],
      style: TextStyle(
        color: colors.onSurface,
        fontSize: 18,
        fontWeight: FontWeight.w500,
      ),
    );
  }
}

class _ScopeSelector extends StatelessWidget {
  const _ScopeSelector({required this.selectedIndex, required this.onSelected});

  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final labels = [l10n.text('plenary'), l10n.text('workingGroup')];

    return Container(
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
  const _FilterBar({required this.onTap, required this.activeCount});

  final VoidCallback onTap;
  final int activeCount;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Align(
      alignment: Alignment.centerRight,
      child: InkWell(
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
    final moduleType = AppSettings.of(context).moduleType;
    final isLineMinistry = moduleType == AppModuleType.lineMinistry;

    final isSecretariat = moduleType == AppModuleType.cdcSecretariat;
    final demoTotalIssues = isSecretariat
        ? '179'
        : isWorkingGroup
        ? '20'
        : (isLineMinistry ? '56' : '20');
    final demoSolved = isSecretariat
        ? '166/179'
        : isWorkingGroup
        ? '15/20'
        : (isLineMinistry ? '30/56' : '15/20');
    final demoInProgress = isSecretariat
        ? '13/179'
        : isWorkingGroup
        ? '4/20'
        : (isLineMinistry ? '16/56' : '4/20');
    final demoNotAddressed = isSecretariat
        ? '0/179'
        : isWorkingGroup
        ? '1/20'
        : (isLineMinistry ? '10/56' : '1/20');

    final cards = PswgDataScope.maybeOf(context)?.cards;
    final totalIssues = cards == null
        ? demoTotalIssues
        : '${cards['totalIssues']}';
    final solved = cards == null
        ? demoSolved
        : '${cards['solved']}/$totalIssues';
    final inProgress = cards == null
        ? demoInProgress
        : '${cards['inProgress']}/$totalIssues';
    final notAddressed = cards == null
        ? demoNotAddressed
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
          color: isDark ? AppColors.darkBorder : const Color(0xFFE0E5EB),
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
                  '${PswgDataScope.maybeOf(context)?.cards['totalPrimaryAgencies'] ?? 0}',
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
    final isCdcGpsf =
        AppSettings.of(context).moduleType == AppModuleType.cdcSecretariat;
    final tabs = [
      l10n.text('overall'),
      l10n.text('agencies'),
      l10n.text('workingGroup'),
      l10n.text('categories'),
    ];

    return Container(
      height: isCdcGpsf ? 38 : 38,
      padding: EdgeInsets.all(isCdcGpsf ? 3 : 4),
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
                    fontSize: isCdcGpsf ? 10 : 12,
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
    if (AppSettings.of(context).moduleType == AppModuleType.cdcSecretariat) {
      return switch (selectedIndex) {
        1 => const CdcSecretariatAgenciesTab(),
        2 => const CdcSecretariatWorkingGroupTab(),
        3 => const CdcSecretariatCategoriesTab(),
        _ => const CdcSecretariatOverallTab(),
      };
    }
    return switch (selectedIndex) {
      1 => const AgenciesTab(),
      2 => const WorkingGroupTab(),
      3 => const CategoriesTab(),
      _ => const OverallTab(),
    };
  }
}
