import '../../../shared/meetings/data/meeting_request.dart';
import '../../../shared/meetings/widgets/meeting_requests_list.dart';
import '../../../shared/issues/widgets/issue_display.dart';
import '../../../shared/issues/widgets/issue_agency_logo.dart';
import 'package:flutter/material.dart';

import '../../../../core/app_colors.dart';
import '../meeting_request_detail_screen.dart';
import '../../../../translations/app_localizations.dart';

class MeetingRequestTab extends StatelessWidget {
  const MeetingRequestTab({super.key});

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Theme.of(context).brightness == Brightness.dark
          ? AppColors.darkBackground
          : const Color(0xFFF7F7F8),
      child: MeetingRequestsList(
        itemBuilder: (request) => _MeetingRequestCard(request: request),
      ),
    );
  }
}

class _MeetingRequestCard extends StatelessWidget {
  const _MeetingRequestCard({required this.request});
  final MeetingRequest request;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final title = request.title;
    final group = request.group.isEmpty ? '—' : request.group;
    final date = issueDate(context, request.meetingDate);
    final totalIssues = AppLocalizations.of(
      context,
    ).number(request.issuesCount);
    final status = request.status;
    final attachmentCount =
        '${AppLocalizations.of(context).number(request.attachmentCount)} ${AppLocalizations.of(context, page: 'meeting_requests').text('attachmentsLabel')}';
    return InkWell(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) =>
                MeetingRequestDetailScreen(title: title, request: request),
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
                IssueAgencyLogo(
                  path: request.agencyLogo,
                  size: 32,
                  iconSize: 17,
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
                    fitValue: true,
                    label: AppLocalizations.of(
                      context,
                      page: 'meeting_requests',
                    ).text('meetingDate'),
                    value: date,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _MeetingInfo(
                    icon: Icons.file_copy_outlined,
                    label: AppLocalizations.of(
                      context,
                      page: 'meeting_requests',
                    ).text('totalIssues'),
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
                    attachmentCount,
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
    this.fitValue = false,
    this.iconColor = AppColors.primary,
    this.iconBackground = const Color(0xFFDDEEFF),
  });

  final IconData icon;
  final String label;
  final String value;
  final bool fitValue;
  final Color iconColor;
  final Color iconBackground;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final valueText = Text(
      value,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        color: Theme.of(context).colorScheme.onSurface,
        fontSize: 11,
        fontWeight: FontWeight.w400,
      ),
    );
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
              fitValue
                  ? FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: valueText,
                    )
                  : valueText,
            ],
          ),
        ),
      ],
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final config = switch (status) {
      'DRAFT' || 'DRAFTED' => (
        label: AppLocalizations.of(
          context,
          page: 'meeting_requests',
        ).text('drafted'),
        color: isDark ? const Color(0xFFD1D5DB) : const Color(0xFF6B7280),
        background: isDark ? const Color(0xFF222835) : const Color(0xFFF3F4F6),
        border: isDark ? const Color(0xFF4B5563) : const Color(0xFFD1D5DB),
      ),
      'SUBMITTED' => (
        label: AppLocalizations.of(
          context,
          page: 'meeting_requests',
        ).text('submitted'),
        color: isDark ? const Color(0xFF5EEAD4) : const Color(0xFF0E9384),
        background: isDark ? const Color(0xFF123B3A) : const Color(0xFFE6FFFB),
        border: isDark ? const Color(0xFF0F766E) : const Color(0xFF79D7CD),
      ),
      'COMPLETED' => (
        label: AppLocalizations.of(
          context,
          page: 'meeting_requests',
        ).text('completed'),
        color: isDark ? const Color(0xFF86EFAC) : const Color(0xFF16A34A),
        background: isDark ? const Color(0xFF123B2A) : const Color(0xFFEAFBF0),
        border: isDark ? const Color(0xFF166534) : const Color(0xFF9BE2B4),
      ),
      'UNDER_REVIEW' => (
        label: AppLocalizations.of(
          context,
          page: 'meeting_requests',
        ).text('underReview'),
        color: isDark ? const Color(0xFFFBBF24) : const Color(0xFFFF8A00),
        background: isDark ? const Color(0xFF423415) : const Color(0xFFFFF6E8),
        border: isDark ? const Color(0xFF92400E) : const Color(0xFFFFC166),
      ),
      _ => (
        label: status == 'SCHEDULED'
            ? AppLocalizations.of(
                context,
                page: 'meeting_requests',
              ).text('scheduled')
            : AppLocalizations.of(
                context,
                page: 'meeting_requests',
              ).status(status),
        color: isDark ? const Color(0xFF75BFFF) : const Color(0xFF1675C6),
        background: isDark ? const Color(0xFF142E45) : const Color(0xFFF0F8FF),
        border: isDark ? const Color(0xFF356992) : const Color(0xFFB8DCFA),
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
              color: config.color,
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
