import 'package:flutter/material.dart';

import '../../../core/app_colors.dart';
import '../../../translations/app_localizations.dart';
import '../../../widgets/app_header.dart';
import '../../private_sector/dashboard/dashboard_screen.dart';
import '../../private_sector/meetings/meeting_screen.dart';
import '../issues/issues_screen.dart';

/// The CDC G-PSF working-group section follows the Web navigation hierarchy.
class CdcWorkingGroupScreen extends StatefulWidget {
  const CdcWorkingGroupScreen({super.key});

  @override
  State<CdcWorkingGroupScreen> createState() => _CdcWorkingGroupScreenState();
}

class _CdcWorkingGroupScreenState extends State<CdcWorkingGroupScreen> {
  int _selectedTab = 0;
  final _visited = <int>{0};
  static const _pages = <Widget>[
    DashboardPage(initialScopeTab: 1, showAppHeader: false),
    MeetingScreen(initialTab: 0, showTabs: false, embedded: true),
    MeetingScreen(initialTab: 1, showTabs: false, embedded: true),
    MeetingScreen(initialTab: 2, showTabs: false, embedded: true),
    CdcSecretariatIssuesScreenView(
      initialTab: 1,
      showTabs: false,
      embedded: true,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final labels = [
      l10n.api('dashboard.title', fallback: l10n.text('dashboard')),
      l10n.api('meeting_requests.title', fallback: l10n.text('meetingRequest')),
      l10n.api(
        'meeting_calendar.title',
        fallback: l10n.text('meetingCalendar'),
      ),
      l10n.api('meeting_summary.title', fallback: l10n.text('meetingSummary')),
      l10n.api('issue_matrix.title', fallback: l10n.text('issuesMatrix')),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const AppHeader(),
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
          child: Text(
            labels[_selectedTab],
            style: TextStyle(
              color: AppColors.primaryText(context),
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 0, 14, 8),
          child: Container(
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.cardBackground(context),
              border: Border.all(color: AppColors.border(context)),
              borderRadius: BorderRadius.circular(9),
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.all(4),
              child: Row(
                children: List.generate(labels.length, (index) {
                  final selected = index == _selectedTab;
                  return Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: Semantics(
                      selected: selected,
                      button: true,
                      child: InkWell(
                        key: ValueKey('cdc-working-group-tab-$index'),
                        onTap: () => setState(() {
                          _selectedTab = index;
                          _visited.add(index);
                        }),
                        borderRadius: BorderRadius.circular(6),
                        child: Container(
                          alignment: Alignment.center,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: selected
                                ? AppColors.accent(context)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            labels[index],
                            style: TextStyle(
                              color: selected
                                  ? Colors.white
                                  : AppColors.mutedText,
                              fontSize: 12,
                              fontWeight: selected
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),
        ),
        Expanded(
          child: IndexedStack(
            index: _selectedTab,
            children: List.generate(
              _pages.length,
              (index) => _visited.contains(index)
                  ? _pages[index]
                  : const SizedBox.shrink(),
            ),
          ),
        ),
      ],
    );
  }
}
