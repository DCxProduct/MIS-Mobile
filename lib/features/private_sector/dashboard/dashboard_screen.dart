import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/app_colors.dart';
import '../../../core/app_settings.dart';
import '../../../core/config/module_config.dart';
import '../../../screens/account/account_screen.dart';
import '../../../screens/notification/notification_screen.dart';
import '../../../translations/app_localizations.dart';
import '../../../widgets/app_bottom_nav_bar.dart';
import '../../../widgets/app_header.dart';

import '../../cdc_secretariat/dashboard/dashboard_screen.dart';
import '../../cdc_secretariat/issues/issues_screen.dart';
import '../../cdc_secretariat/meeting/meeting_screen.dart';
import '../../cdc_secretariat/profile/profile_screen.dart';
import '../../cdc_secretariat/reports/reports_screen.dart';

import '../../cdc_section/dashboard/dashboard_screen.dart';
import '../../cdc_section/issues/issues_screen.dart';
import '../../cdc_section/meeting/meeting_screen.dart';
import '../../cdc_section/profile/profile_screen.dart';
import '../../cdc_section/reports/reports_screen.dart';

import '../../cefp/dashboard/dashboard_screen.dart';
import '../../cefp/issues/issues_screen.dart';
import '../../cefp/meeting/meeting_screen.dart';
import '../../cefp/profile/profile_screen.dart';
import '../../cefp/reports/reports_screen.dart';

import '../../line_ministry/dashboard/dashboard_screen.dart';
import '../../line_ministry/issues/issues_screen.dart';
import '../../line_ministry/meeting/meeting_screen.dart';
import '../../line_ministry/profile/profile_screen.dart';
import '../../line_ministry/reports/reports_screen.dart';

import '../issues/issues_screen.dart';
import '../meeting/meeting_screen.dart';
import '../reports/reports_screen.dart';
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
          1 => const CdcSectionMeetingScreenView(),
          2 => const CdcSectionIssuesScreenView(),
          3 => const CdcSectionReportsScreenView(),
          _ => const CdcSectionProfileScreenView(),
        },
      AppModuleType.cefp => switch (index) {
          0 => const CefpDashboardScreenView(),
          1 => const CefpMeetingScreenView(),
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
          0 => const _DashboardPage(),
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
    final background =
        isDark ? AppColors.darkBackground : const Color(0xFFF5F7FB);
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
        extendBody: true,
        body: body,
        bottomNavigationBar: AppBottomNavBar(
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

  Set<String> _selectedYears = {};
  Set<String> _selectedStatuses = {};
  Set<String> _selectedAgencies = {};
  Set<String> _selectedProgressReports = {};

  Future<void> _openFilterSheet(BuildContext context) async {
    final result = await showModalBottomSheet<_FilterResult>(
      context: context,
      isScrollControlled: true,
      useSafeArea: false,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return _GroupFilterSheet(
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

  @override
  Widget build(BuildContext context) {
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
                    _ScopeTitle(selectedIndex: _selectedScopeTab),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        _ScopeSelector(
                          selectedIndex: _selectedScopeTab,
                          onSelected: (index) {
                            setState(() => _selectedScopeTab = index);
                          },
                        ),
                        const Spacer(),
                        _FilterBar(
                          onTap: () => _openFilterSheet(context),
                          activeCount:
                              _selectedYears.length +
                              _selectedStatuses.length +
                              _selectedAgencies.length +
                              _selectedProgressReports.length,
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
  State<DashboardLoadingScreen> createState() =>
      _DashboardLoadingScreenState();
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
  const _ScopeSelector({
    required this.selectedIndex,
    required this.onSelected,
  });

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
  const _FilterBar({
    required this.onTap,
    required this.activeCount,
  });

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

class _FilterResult {
  const _FilterResult({
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

class _GroupFilterSheet extends StatefulWidget {
  const _GroupFilterSheet({
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
  State<_GroupFilterSheet> createState() => _GroupFilterSheetState();
}

class _GroupFilterSheetState extends State<_GroupFilterSheet> {
  late Set<String> _years;
  late Set<String> _statuses;
  late Set<String> _agencies;
  late Set<String> _progressReports;

  bool _showAllAgencies = true;

  static const _yearItems = ['2026', '2025', '2024', '2023'];

  static const _statusItems = [
    'Solved',
    'In Progress',
    'Not Address',
  ];

  static const _agencyItems = [
    'GDT',
    'MFF',
    'GDCE',
    'MLVT',
    'MPTC',
    'MAFF',
    'MoH',
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
    _years = {...widget.selectedYears};
    _statuses = {...widget.selectedStatuses};
    _agencies = {...widget.selectedAgencies};
    _progressReports = {...widget.selectedProgressReports};
  }

  void _toggle(Set<String> values, String value) {
    setState(() {
      if (values.contains(value)) {
        values.remove(value);
      } else {
        values.add(value);
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
                      _FilterGridSection(
                        title: l10n.text('year'),
                        items: _yearItems,
                        columns: 4,
                        selectedItems: _years,
                        onChanged: (value) => _toggle(_years, value),
                      ),

                      const SizedBox(height: 25),

                      _FilterGridSection(
                        title: l10n.text('status'),
                        items: _statusItems,
                        columns: 3,
                        selectedItems: _statuses,
                        onChanged: (value) => _toggle(_statuses, value),
                      ),

                      const SizedBox(height: 25),

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
                        _FilterResult(
                          years: {..._years},
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
                child: _FilterCheckItem(
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

class _FilterCheckItem extends StatelessWidget {
  const _FilterCheckItem({
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
      borderRadius: BorderRadius.circular(4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 140),
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              color: selected
                  ? AppColors.accent(context)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: selected
                    ? AppColors.accent(context)
                    : (isDark
                        ? AppColors.darkBorder
                        : const Color(0xFFCED7E1)),
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
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _localizeLabel(context, label),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.mutedText,
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

String _localizeLabel(BuildContext context, String text) {
  final l10n = AppLocalizations.of(context);
  return switch (text) {
    'Solved' => l10n.text('solved'),
    'In Progress' => l10n.text('inProgress'),
    'Not Address' || 'Not Addressed' => l10n.text('notAddressed'),
    'Both' => l10n.text('both'),
    'Sent' => l10n.text('sent'),
    'Draft' => l10n.text('draft'),
    'View All' => l10n.text('viewAll'),
    'View Less' => l10n.text('viewLess'),
    'View More' => l10n.text('viewAll'),
    _ => text,
  };
}

class _MetricGrid extends StatelessWidget {
  const _MetricGrid({required this.isWorkingGroup});

  final bool isWorkingGroup;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final moduleType = AppSettings.of(context).moduleType;
    final isLineMinistry = moduleType == AppModuleType.lineMinistry;

    final totalIssues = isWorkingGroup ? '20' : (isLineMinistry ? '56' : '20');
    final solved =
        isWorkingGroup ? '15/20' : (isLineMinistry ? '30/56' : '15/20');
    final inProgress =
        isWorkingGroup ? '4/20' : (isLineMinistry ? '16/56' : '4/20');
    final notAddressed =
        isWorkingGroup ? '1/20' : (isLineMinistry ? '10/56' : '1/20');

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
      _ => const OverallTab(),
    };
  }
}
