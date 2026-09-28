import 'package:flutter/material.dart';

import '../../../core/app_colors.dart';
import '../../../core/widgets/pdf_attachment_preview.dart';
import '../../../features/shared/meetings/data/meeting_summary.dart';
import '../../../features/shared/meetings/widgets/meeting_summaries_loader.dart';
import '../../../features/private_sector/reports/meeting_summary_detail_screen.dart';
import '../../../translations/app_localizations.dart';

class MeetingSummaryTab extends StatelessWidget {
  const MeetingSummaryTab({
    super.key,
    this.statuses = const {},
    this.years = const {},
    this.issueCounts = const {},
  });

  final Set<String> statuses;
  final Set<String> years;
  final Set<String> issueCounts;

  @override
  Widget build(BuildContext context) {
    return MeetingSummariesLoader(
      builder: (summaries) {
        final filtered = summaries.where(_matches).toList();
        if (filtered.isEmpty) {
          return Padding(
            padding: const EdgeInsets.all(20),
            child: Text(
              AppLocalizations.of(context).text('noMeetingSummaries'),
            ),
          );
        }
        return Column(
          children: [
            for (final summary in filtered)
              _MeetingSummaryCard(summary: summary),
          ],
        );
      },
    );
  }

  bool _matches(MeetingSummary summary) {
    final statusMatch =
        statuses.isEmpty ||
        statuses.any(
          (value) =>
              value.toUpperCase().replaceAll(' ', '_') ==
              summary.status.toUpperCase(),
        );
    final yearMatch =
        years.isEmpty ||
        (summary.date != null &&
            years.contains('${summary.date!.toLocal().year}'));
    final issueMatch =
        issueCounts.isEmpty || issueCounts.contains('${summary.issueCount}');
    return statusMatch && yearMatch && issueMatch;
  }
}

class _MeetingSummaryCard extends StatelessWidget {
  const _MeetingSummaryCard({required this.summary});

  final MeetingSummary summary;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => MeetingSummaryDetailScreen(id: summary.id),
        ),
      ),
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
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 32,
                  height: 32,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [Color(0xFF1E73BE), Color(0xFF1EA45B)],
                    ),
                  ),
                  child: const Icon(
                    Icons.account_balance,
                    color: Colors.white,
                    size: 17,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        summary.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        summary.governmentAgency,
                        style: const TextStyle(
                          color: AppColors.mutedText,
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
                  child: _MeetingSummaryMeta(
                    icon: Icons.calendar_month_outlined,
                    label: AppLocalizations.of(context).text('meetingDate'),
                    value: _date(context, summary.date),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _MeetingSummaryMeta(
                    icon: Icons.file_copy_outlined,
                    label: AppLocalizations.of(context).text('totalIssues'),
                    value: '${summary.issueCount}',
                    iconColor: const Color(0xFFB642FF),
                    iconBackground: const Color(0xFFF2DDFF),
                  ),
                ),
                _StatusBadge(status: summary.status),
              ],
            ),
            const Divider(height: 18),
            Row(
              children: [
                Flexible(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.darkBackground
                          : const Color(0xFFF7F7F8),
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: Text(
                      summary.pswg,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                PdfAttachmentPreview(
                  path: summary.attachmentPaths.isEmpty
                      ? ''
                      : summary.attachmentPaths.first,
                  name: summary.attachmentPaths.isEmpty
                      ? null
                      : pdfAttachmentName(summary.attachmentPaths.first),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
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
                        const Icon(
                          Icons.link,
                          color: Color(0xFF4C5563),
                          size: 14,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '${summary.attachmentCount} ${AppLocalizations.of(context).text('attachmentsLabel')}',
                          style: const TextStyle(
                            color: Color(0xFF4C5563),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static String _date(BuildContext context, DateTime? value) => value == null
      ? '—'
      : MaterialLocalizations.of(context).formatMediumDate(value.toLocal());
}

class _MeetingSummaryMeta extends StatelessWidget {
  const _MeetingSummaryMeta({
    required this.icon,
    required this.label,
    required this.value,
    this.iconColor = AppColors.primary,
    this.iconBackground = const Color(0xFFDDEEFF),
  });
  final IconData icon;
  final String label, value;
  final Color iconColor, iconBackground;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      children: [
        Container(
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            color: isDark ? iconColor.withValues(alpha: .16) : iconBackground,
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
                  fontWeight: FontWeight.w600,
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
  final String status;

  @override
  Widget build(BuildContext context) {
    final shared = status.toUpperCase() == 'SHARED';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: shared ? const Color(0xFFE6F6FF) : const Color(0xFFF2F3F5),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: shared ? const Color(0xFF63B9EA) : const Color(0xFFD4D8DE),
        ),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: shared ? const Color(0xFF1475A8) : AppColors.mutedText,
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
