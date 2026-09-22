import 'package:flutter/material.dart';

import '../../../core/app_colors.dart';
import '../../private_sector/meeting/meeting_request_detail_screen.dart';
import '../../../translations/app_localizations.dart';

class CdcMeetingRequestTab extends StatelessWidget {
  const CdcMeetingRequestTab({super.key});

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Theme.of(context).brightness == Brightness.dark
          ? AppColors.darkBackground
          : const Color(0xFFF7F7F8),
      child: Column(
        children: [
          const _MeetingRequestCard(
            title: 'អនុគណៈកម្មាធិការផ្នែកកសិកម្ម និងកសិឧស្សាហកម្ម',
            group: 'Agriculture and Agro-Industry',
            date: '10 Aug, 2025',
            totalIssues: '3',
            status: _MeetingStatus.submitted,
          ),
          const _MeetingRequestCard(
            title: 'កិច្ចពិភាក្សាជាមួយក្រុមការងារផ្នែកកសិកម្ម',
            group: 'Agriculture and Agro-Industry',
            date: '12 Aug, 2025',
            totalIssues: '2',
            status: _MeetingStatus.underReview,
          ),
          const _MeetingRequestCard(
            title:
                'ការកំណត់ការងារបន្ត និងកិច្ចប្រជុំ Online សម្រាប់ក្រុមការងារ',
            group: 'Agriculture and Agro-Industry',
            date: '12 Aug, 2025',
            totalIssues: '5',
            status: _MeetingStatus.submitted,
          ),
        ],
      ),
    );
  }
}

enum _MeetingStatus { drafted, submitted, completed, underReview }

class _MeetingRequestCard extends StatelessWidget {
  const _MeetingRequestCard({
    required this.title,
    required this.group,
    required this.date,
    required this.totalIssues,
    required this.status,
  });

  final String title;
  final String group;
  final String date;
  final String totalIssues;
  final _MeetingStatus status;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => MeetingRequestDetailScreen(title: title),
          ),
        );
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipOval(
                  child: Image.asset(
                    'assets/images/maff.jpg',
                    width: 32,
                    height: 32,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        group,
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _MeetingInfo(
                    icon: Icons.calendar_month_outlined,
                    label: AppLocalizations.of(context).text('meetingDate'),
                    value: date,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _MeetingInfo(
                    icon: Icons.file_copy_outlined,
                    label: AppLocalizations.of(context).text('totalIssues'),
                    value: totalIssues,
                    iconColor: const Color(0xFFB642FF),
                    iconBackground: const Color(0xFFF2DDFF),
                  ),
                ),
                _StatusBadge(status: status),
              ],
            ),
            const Divider(height: 18),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkCard : Colors.white,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: isDark
                      ? AppColors.darkBorder
                      : const Color(0xFFE5E8ED),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.link, color: Color(0xFF4C5563), size: 14),
                  const SizedBox(width: 6),
                  Text(
                    AppLocalizations.of(context).text('twoAttachments'),
                    style: const TextStyle(
                      color: Color(0xFF4C5563),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MeetingInfo extends StatelessWidget {
  const _MeetingInfo({
    required this.icon,
    required this.label,
    required this.value,
    this.iconColor = AppColors.primary,
    this.iconBackground = const Color(0xFFDDEEFF),
  });

  final IconData icon;
  final String label;
  final String value;
  final Color iconColor;
  final Color iconBackground;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      children: [
        Container(
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            color: isDark ? iconColor.withValues(alpha: 0.16) : iconBackground,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Icon(icon, color: iconColor, size: 14),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: isDark
                      ? AppColors.secondaryText(context)
                      : AppColors.mutedText,
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontSize: 11,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final _MeetingStatus status;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final config = switch (status) {
      _MeetingStatus.drafted => (
        label: AppLocalizations.of(context).text('drafted'),
        color: isDark ? const Color(0xFFD1D5DB) : const Color(0xFF6B7280),
        background: isDark ? const Color(0xFF222835) : const Color(0xFFF3F4F6),
        border: isDark ? const Color(0xFF4B5563) : const Color(0xFFD1D5DB),
      ),
      _MeetingStatus.submitted => (
        label: AppLocalizations.of(context).text('submitted'),
        color: isDark ? const Color(0xFF75BFFF) : const Color(0xFF1675C6),
        background: isDark ? const Color(0xFF142E45) : const Color(0xFFF0F8FF),
        border: isDark ? const Color(0xFF356992) : const Color(0xFFB8DCFA),
      ),
      _MeetingStatus.completed => (
        label: AppLocalizations.of(context).text('completed'),
        color: isDark ? const Color(0xFF86EFAC) : const Color(0xFF16A34A),
        background: isDark ? const Color(0xFF123B2A) : const Color(0xFFEAFBF0),
        border: isDark ? const Color(0xFF166534) : const Color(0xFF9BE2B4),
      ),
      _MeetingStatus.underReview => (
        label: AppLocalizations.of(context).text('underReview'),
        color: isDark ? const Color(0xFFFBBF24) : const Color(0xFFFF8A00),
        background: isDark ? const Color(0xFF423415) : const Color(0xFFFFF6E8),
        border: isDark ? const Color(0xFF92400E) : const Color(0xFFFFC166),
      ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: config.background,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: config.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              border: Border.all(color: config.color),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            config.label,
            style: TextStyle(
              color: config.color,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
