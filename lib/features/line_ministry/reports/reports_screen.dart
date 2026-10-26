import '../../shared/issues/widgets/issue_display.dart';
import '../../cdc_section/reports/rgc_decision_details.dart' show plenaryDate;

import '../../../core/app_settings.dart';
import '../../../core/widgets/filters/api_filter_sheet.dart';
import '../../../core/widgets/filters/api_filter_scope.dart';
import 'package:flutter/material.dart';

import '../../../core/app_colors.dart';
import '../../shared/dashboard/data/dashboard_repository.dart';
import '../../shared/dashboard/widgets/pswg_live_dashboard.dart';
import '../../private_sector/dashboard/dashboard_screen.dart'
    show SharedDashboardCharts;

import '../../../screens/report/plenary_detail_screen.dart';
import '../../cdc_secretariat/reports/rgc_decision_card.dart';
import '../../../screens/report/tabs/report_progress_report_tab.dart';
import '../../../features/shared/meetings/data/plenary.dart';
import '../../../features/shared/meetings/widgets/plenaries_loader.dart';
import '../../../features/shared/meetings/widgets/rgc_decisions_loader.dart';
import '../../../translations/app_language.dart';
import '../../../translations/app_localizations.dart';

class LineMinistryReportsScreenView extends StatefulWidget {
  const LineMinistryReportsScreenView({super.key});

  @override
  State<LineMinistryReportsScreenView> createState() =>
      _LineMinistryReportsScreenViewState();
}

class _LineMinistryReportsScreenViewState
    extends State<LineMinistryReportsScreenView> {
  int _selectedTab = 0;
  static const _translationPages = [
    'progress_report',
    'dashboard_plenary',
    'plenary_plenaries',
    'plenary_rgc_decisions',
  ];

  final _filters = List.generate(4, (_) => FilterSelection());
  static const _resources = [
    'progress-reports',
    'dashboard',
    'plenaries',
    'rgc-decisions',
  ];
  Future<void> _openFilters() async {
    final tab = _selectedTab;
    final catalogs = AppSettings.of(context).filters;
    final result = await Navigator.of(context).push<FilterSelection>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => ApiFilterSheet(
          translationPage: _translationPages[tab],
          initial: _filters[tab],
          load: switch (tab) {
            0 => catalogs.progressReports,
            1 => () => catalogs.dashboard('plenary'),
            2 => catalogs.plenaries,
            _ => catalogs.rgc,
          },
        ),
      ),
    );
    if (!mounted || result == null) return;
    setState(() => _filters[tab] = result);
  }

  int get _activeFilterCount => _filters[_selectedTab].count;

  @override
  Widget build(BuildContext context) => TranslationPageScope(
    page: _translationPages[_selectedTab],
    child: Builder(builder: _buildContent),
  );

  Widget _buildContent(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final contentBackground = isDark
        ? AppColors.darkBackground
        : const Color(0xFFF7F7F8);
    final headerBackground = isDark ? AppColors.darkBackground : Colors.white;

    final topPadding = MediaQuery.of(context).viewPadding.top;

    return ApiFilterScope(
      selections: {
        for (var i = 0; i < _filters.length; i++) _resources[i]: _filters[i],
      },
      queries: {
        for (var i = 0; i < _filters.length; i++)
          _resources[i]: _filters[i].toQuery(),
      },
      child: ColoredBox(
        color: contentBackground,
        child: Column(
          children: [
            // STICKY HEADER
            Container(
              color: headerBackground,
              padding: EdgeInsets.fromLTRB(
                14,
                topPadding > 0 ? topPadding + 12 : 34,
                14,
                12,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          AppLocalizations.of(context).text('report'),
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface,
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      _FilterButton(
                        activeCount: _activeFilterCount,
                        onTap: _openFilters,
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  _ReportTabs(
                    selectedIndex: _selectedTab,
                    onSelected: (index) => setState(() => _selectedTab = index),
                  ),
                ],
              ),
            ),
            // SCROLLABLE CONTENT
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 96),
                children: [
                  if (_selectedTab == 0)
                    const ReportProgressReportTab()
                  else if (_selectedTab == 1) ...const [
                    _ReportDashboardTab(),
                  ] else if (_selectedTab == 2) ...const [
                    _PlenaryTab(),
                  ] else ...const [_RgcDecisionTab()],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RgcDecisionTab extends StatelessWidget {
  const _RgcDecisionTab();
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return RgcDecisionsLoader(
      includePlenaryDetails: false,
      builder: (decisions) {
        final total = decisions.length;
        int count(String code) =>
            decisions.where((d) => d.statusCode.toUpperCase() == code).length;
        final cards = [
          _MetricCard(
            label: l10n.text('totalIssues'),
            value: '$total',
            background: const Color(0xFFDDEEFF),
            icon: Icons.description_outlined,
          ),
          _MetricCard(
            label: l10n.status('Solved'),
            value: '${count('SOLVED')}/$total',
            background: const Color(0xFFE3FAF1),
            icon: Icons.task_alt,
          ),
          _MetricCard(
            label: l10n.status('In Progress'),
            value: '${count('IN_PROGRESS')}/$total',
            background: const Color(0xFFFFF8DB),
            icon: Icons.pending_actions,
          ),
          _MetricCard(
            label: l10n.status('Not Addressed'),
            value: '${count('NOT_ADDRESSED')}/$total',
            background: const Color(0xFFFFEEEE),
            icon: Icons.assignment_late_outlined,
          ),
        ];
        return Column(
          children: [
            for (var i = 0; i < cards.length; i += 2) ...[
              Row(
                children: [
                  Expanded(child: cards[i]),
                  const SizedBox(width: 8),
                  Expanded(child: cards[i + 1]),
                ],
              ),
              const SizedBox(height: 8),
            ],
            _TotalPrimaryAgenciesCard(
              value:
                  '${decisions.map((d) => d.agencyName).where((name) => name.isNotEmpty).toSet().length}',
            ),
            const SizedBox(height: 16),
            for (final decision in decisions)
              CdcGpsfRgcDecisionCard(decision: decision),
          ],
        );
      },
    );
  }
}

class _PlenaryTab extends StatelessWidget {
  const _PlenaryTab();

  @override
  Widget build(BuildContext context) {
    return PlenariesLoader(
      builder: (plenaries) => Column(
        children: [
          for (final plenary in plenaries)
            _PlenaryCard(
              plenaryId: plenary.id,
              title: plenary.name,
              status: plenary.status,
              documentReference: plenary.documentReference,
              documentReferenceName: plenary.documentReferenceName,
              meetingDate: plenaryDate(plenary.meetingDate, context: context),
              numberOfRgcDecision: '${plenary.numberOfRgcDecisions}',
              deadline: _formatDate(context, plenary.deadline),
              attachmentCount: _attachmentLabel(context, plenary),
            ),
        ],
      ),
    );
  }

  static String _formatDate(BuildContext context, DateTime? value) {
    if (value == null) return '-';
    return issueDateWithYear(context, value.toLocal());
  }

  static String _attachmentLabel(BuildContext context, Plenary plenary) {
    return '${AppLocalizations.of(context).number(plenary.attachmentCount)} ${AppLocalizations.of(context).text('attachmentsLabel')}';
  }
}

class _PlenaryCard extends StatelessWidget {
  const _PlenaryCard({
    required this.plenaryId,
    required this.title,
    required this.status,
    required this.meetingDate,
    required this.numberOfRgcDecision,
    required this.deadline,
    required this.attachmentCount,
    this.documentReference,
    this.documentReferenceName,
  });

  final String? documentReference, documentReferenceName;
  final int plenaryId;
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
              Text(
                title,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
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
                  AppLocalizations.of(context).status(translatedStatus),
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
            label: l10n.text('numberOfRgcDecision'),
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
                    builder: (_) => PlenaryDetailScreen(
                      plenaryId: plenaryId,
                      title: title,
                      documentReference: documentReference,
                      documentReferenceName: documentReferenceName,
                    ),
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

// Kept for the legacy report layout used by older saved screens.
// ignore: unused_element
class _ProgressReportCard extends StatelessWidget {
  const _ProgressReportCard({
    required this.title,
    required this.year,
    required this.deadline,
    required this.firstMeeting,
    required this.secondDeadline,
    required this.secondMeeting,
  });

  final String title;
  final String year;
  final String deadline;
  final String firstMeeting;
  final String secondDeadline;
  final String secondMeeting;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context);
    final isKhmer = l10n.language == AppLanguage.khmer;
    final translatedTitle = title == 'Semester 2'
        ? (isKhmer ? 'ឆមាសទី ២' : 'Semester 2')
        : title;

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
            children: [
              Text(
                translatedTitle,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF3B2352)
                      : const Color(0xFFF5E8FF),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  year,
                  style: TextStyle(
                    color: isDark
                        ? const Color(0xFFD8B4FE)
                        : const Color(0xFF9333EA),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _ReportRow(label: l10n.text('deadline'), value: deadline),
          const SizedBox(height: 8),
          _ReportRow(
            label: isKhmer ? 'កិច្ចប្រជុំលើកទី១' : '1st Meeting',
            value: firstMeeting,
          ),
          const SizedBox(height: 8),
          _ReportRow(
            label: isKhmer ? 'កាលបរិច្ឆេទកំណត់លើកទី២' : '2nd Deadline',
            value: secondDeadline,
          ),
          const SizedBox(height: 8),
          _ReportRow(
            label: isKhmer ? 'កិច្ចប្រជុំលើកទី២' : '2nd Meeting',
            value: secondMeeting,
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 36,
            child: FilledButton(
              onPressed: () {},
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
        Text(
          label,
          style: const TextStyle(
            color: AppColors.mutedText,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _ReportDashboardTab extends StatelessWidget {
  const _ReportDashboardTab();
  @override
  Widget build(BuildContext context) {
    final selection = ApiFilterScope.selection(context, 'dashboard');
    return PswgDataLoader(
      scope: DashboardScope.plenary,
      selection: selection,
      progressReportId: int.tryParse(
        selection.toQuery()['progressReportId'] ?? '',
      ),
      builder: (_) => const SharedDashboardCharts(plenary: true),
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

class _ReportTabs extends StatelessWidget {
  const _ReportTabs({required this.selectedIndex, required this.onSelected});

  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context);
    final tabs = [
      (icon: Icons.calendar_month_outlined, label: l10n.text('progressReport')),
      (
        icon: Icons.add_box_outlined,
        label: l10n.api(
          'plenary_dashboard.title',
          fallback: l10n.text('dashboard'),
        ),
      ),
      (
        icon: Icons.calendar_month_outlined,
        label: l10n.api(
          'plenary_plenaries.title',
          fallback: l10n.text('plenary'),
        ),
      ),
      (
        icon: Icons.assignment_outlined,
        label: l10n.api(
          'plenary_rgc_decisions.title',
          fallback: l10n.text('rgcDecision'),
        ),
      ),
    ];

    return Container(
      height: 42,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkBackground : Colors.white,
        borderRadius: BorderRadius.circular(9),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : const Color(0xFFE8EBF0),
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: List.generate(tabs.length, (index) {
            final isSelected = selectedIndex == index;
            return Padding(
              padding: const EdgeInsets.only(right: 4),
              child: InkWell(
                onTap: () => onSelected(index),
                borderRadius: BorderRadius.circular(6),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.accent(context)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        tabs[index].icon,
                        color: isSelected ? Colors.white : AppColors.mutedText,
                        size: 15,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        tabs[index].label,
                        style: TextStyle(
                          color: isSelected
                              ? Colors.white
                              : AppColors.mutedText,
                          fontSize: 12,
                          fontWeight: isSelected
                              ? FontWeight.w700
                              : FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}

class LineMinistryDashboardFilterSheet extends StatelessWidget {
  const LineMinistryDashboardFilterSheet({super.key});
  @override
  Widget build(BuildContext context) => ApiFilterSheet(
    translationPage: 'dashboard_plenary',
    initial: FilterSelection(),
    load: () => AppSettings.of(context).filters.dashboard('plenary'),
  );
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
                    AppLocalizations.of(context).number(value),
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
                AppLocalizations.of(context).number(value),
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
