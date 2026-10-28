import 'package:gpsf_app/core/status_colors.dart';
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
    final color = StatusColors.workflow(context, status);
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
