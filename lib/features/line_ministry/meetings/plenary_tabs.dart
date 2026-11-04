import 'package:flutter/material.dart';
import '../../../core/app_colors.dart';
import '../../../core/status_colors.dart';
import '../../../screens/report/plenary_detail_screen.dart';
import '../../../translations/app_localizations.dart';
import '../../shared/issues/widgets/issue_display.dart';
import '../../shared/meetings/data/plenary.dart';
import '../../shared/meetings/widgets/plenaries_loader.dart';
import '../../shared/meetings/widgets/rgc_decisions_loader.dart';
import '../../cdc_section/reports/rgc_decision_details.dart' show plenaryDate;
import '../../cdc_secretariat/reports/rgc_decision_card.dart';

class LineMinistryRgcDecisionTab extends StatelessWidget {
  const LineMinistryRgcDecisionTab({super.key});
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

class LineMinistryPlenaryTab extends StatelessWidget {
  const LineMinistryPlenaryTab({super.key});

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
              numberOfRgcDecision: AppLocalizations.of(
                context,
              ).number(plenary.numberOfRgcDecisions),
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
    final statusColor = StatusColors.plenaryChip(context, status);

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
                  color: statusColor.withValues(alpha: .08),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: statusColor.withValues(alpha: .3)),
                ),
                child: Text(
                  AppLocalizations.of(context).status(translatedStatus),
                  style: TextStyle(
                    color: statusColor,
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
