import 'package:flutter/material.dart';
import '../../../translations/app_localizations.dart';

String progressReportMinistryStatusLabel(AppLocalizations l10n, String status) {
  final key = switch (status.trim().toUpperCase()) {
    'REQUESTED' => 'reportRequested',
    'PREPARING' => 'preparing',
    'RETURNED' => 'reportReturned',
    'UPDATING' => 'reportUpdating',
    'RESUBMITTED' => 'reportResubmitted',
    'CDC_RE_REVIEWING' => 'reportReReviewing',
    'SHARED_WITH_PSWG' => 'reportSharedWithPswg',
    'PSWG_REVIEWED' => 'pswgReviewed',
    'SUBMITTED' => 'reportSubmitted',
    'CDC_UNDER_REVIEW' => 'underReview',
    'COMPLETED' => 'reviewed',
    _ => null,
  };
  return key == null ? l10n.status(status) : l10n.text(key);
}

class ProgressReportMinistryStatus extends StatelessWidget {
  const ProgressReportMinistryStatus({super.key, required this.status});
  final String status;

  @override
  Widget build(BuildContext context) {
    final color = switch (status.trim().toUpperCase()) {
      'COMPLETED' => const Color(0xFF32D583),
      'SUBMITTED' || 'RESUBMITTED' => const Color(0xFF079455),
      'REQUESTED' || 'SHARED_WITH_PSWG' => const Color(0xFF175CD3),
      'PSWG_REVIEWED' => const Color(0xFF6941C6),
      'RETURNED' => const Color(0xFFB93815),
      'PREPARING' ||
      'UPDATING' ||
      'CDC_UNDER_REVIEW' ||
      'CDC_RE_REVIEWING' => const Color(0xFFF79009),
      _ => const Color(0xFF717680),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .06),
        border: Border.all(color: color.withValues(alpha: .3)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        progressReportMinistryStatusLabel(AppLocalizations.of(context), status),
        style: TextStyle(fontSize: 13, color: color),
      ),
    );
  }
}
