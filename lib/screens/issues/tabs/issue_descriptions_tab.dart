import 'package:flutter/material.dart';

import '../../../core/app_colors.dart';
import '../../../translations/app_localizations.dart';

class IssueDescriptionsTab extends StatelessWidget {
  const IssueDescriptionsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 24),
      children: [
        _TextPanel(
          title: l10n.text('issuesDescription'),
          body:
              'The private sector stated that cultivation is largely dependent on the weather (rain), and the private sector also observed that the Ministry of Water Resources and Meteorology often issues announcements regarding weather forecasting nationwide, which results in farmers in each region not receiving clear information.',
        ),
        const SizedBox(height: 14),
        _TextPanel(
          title: l10n.text('recommendation'),
          body:
              'The private sector, through the Ministry of Agriculture, Forestry and Fisheries, has requested the Ministry of Water Resources and Meteorology to consider establishing meteorological stations in every province and city to provide farmers with accurate weather information.',
        ),
      ],
    );
  }
}

class _TextPanel extends StatelessWidget {
  const _TextPanel({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: AppColors.mutedText,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
          decoration: BoxDecoration(
            color: AppColors.cardBackground(context),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.border(context)),
          ),
          child: Text(
            body,
            style: TextStyle(
              color: AppColors.secondaryText(context),
              fontSize: 12,
              height: 1.5,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}
