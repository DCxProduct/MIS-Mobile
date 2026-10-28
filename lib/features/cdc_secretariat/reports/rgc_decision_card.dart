import 'package:gpsf_app/core/status_colors.dart';
import 'package:flutter/material.dart';

import '../../../core/app_colors.dart';
import '../../../screens/report/rgc_decision_detail_screen.dart';
import '../../../translations/app_localizations.dart';
import '../../shared/issues/widgets/issue_agency_logo.dart';
import '../../shared/issues/widgets/issue_display.dart';
import '../../shared/meetings/data/rgc_decision.dart';

class CdcGpsfRgcDecisionCard extends StatelessWidget {
  const CdcGpsfRgcDecisionCard({super.key, required this.decision});
  final RgcDecision decision;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final statusColor = StatusColors.workflow(
      context,
      decision.statusCode.isEmpty ? decision.status : decision.statusCode,
    );
    Widget row(String label, String value) => Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontSize: 12, color: AppColors.mutedText),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value.isEmpty ? '—' : value,
              textAlign: TextAlign.right,
              style: const TextStyle(fontSize: 12),
            ),
          ),
        ],
      ),
    );
    return Container(
      key: ValueKey('cdc-gpsf-rgc-${decision.id}'),
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cardBackground(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IssueAgencyLogo(
                path: decision.agencyLogo,
                size: 24,
                iconSize: 14,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  decision.agencyName.isEmpty ? '—' : decision.agencyName,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    l10n.status(decision.status),
                    textAlign: TextAlign.right,
                    style: TextStyle(fontSize: 11, color: statusColor),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            decision.content.isEmpty ? '—' : decision.content,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 13, height: 1.5),
          ),
          row(
            l10n.text('meetingDate'),
            issueDate(context, decision.meetingDate),
          ),
          row(l10n.text('categories'), l10n.category(decision.category)),
          row(l10n.text('focalPersonHE'), decision.focalPerson),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 40,
            child: FilledButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) =>
                      RgcDecisionDetailScreen(decisionId: decision.id),
                ),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.accent(
                  context,
                ).withValues(alpha: 0.1),
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
                    style: const TextStyle(fontSize: 12),
                  ),
                  const SizedBox(width: 6),
                  const Icon(Icons.chevron_right, size: 18),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
