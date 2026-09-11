import 'package:flutter/material.dart';

import '../../core/app_colors.dart';
import '../../translations/app_localizations.dart';
import 'tabs/calendar_tab.dart';
import 'tabs/meeting_request_tab.dart';

class MeetingScreen extends StatefulWidget {
  const MeetingScreen({super.key});

  @override
  State<MeetingScreen> createState() => _MeetingScreenState();
}

class _MeetingScreenState extends State<MeetingScreen> {
  int _selectedTab = 0;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final contentBackground = isDark
        ? AppColors.darkBackground
        : _selectedTab == 0
        ? const Color(0xFFF7F7F8)
        : Colors.white;
    final headerBackground = isDark ? AppColors.darkBackground : Colors.white;

    return ColoredBox(
      color: contentBackground,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          Container(
            color: headerBackground,
            padding: const EdgeInsets.fromLTRB(14, 34, 14, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _selectedTab == 0
                      ? l10n.text('meetingRequests')
                      : l10n.text('calendar'),
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 14),
                _MeetingTabs(
                  selectedIndex: _selectedTab,
                  onSelected: (index) => setState(() => _selectedTab = index),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 96),
            child: Container(
              width: double.infinity,
              color: contentBackground,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 180),
                child: _selectedTab == 0
                    ? const MeetingRequestTab(key: ValueKey('requests'))
                    : const CalendarTab(key: ValueKey('calendar')),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MeetingTabs extends StatelessWidget {
  const _MeetingTabs({required this.selectedIndex, required this.onSelected});

  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tabs = [l10n.text('meetingRequest'), l10n.text('calendar')];

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
          (index) => Expanded(
            child: _MeetingTabPill(
              icon: index == 0
                  ? Icons.calendar_month_outlined
                  : Icons.event_available_outlined,
              label: tabs[index],
              selected: selectedIndex == index,
              onTap: () => onSelected(index),
            ),
          ),
        ),
      ),
    );
  }
}

class _MeetingTabPill extends StatelessWidget {
  const _MeetingTabPill({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? AppColors.accent(context) : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: selected ? Colors.white : AppColors.mutedText,
              size: 15,
            ),
            const SizedBox(width: 5),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: selected ? Colors.white : AppColors.mutedText,
                  fontSize: 12,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
