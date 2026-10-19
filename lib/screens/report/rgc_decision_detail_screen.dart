import '../../translations/app_localizations.dart';
import 'package:flutter/material.dart';

import '../../core/app_colors.dart';

class RgcDecisionDetailScreen extends StatelessWidget {
  const RgcDecisionDetailScreen({super.key, required this.agencyName});

  final String agencyName;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: AppColors.pageBackground(context),
      appBar: AppBar(
        backgroundColor: AppColors.pageBackground(context),
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: AppColors.primaryText(context),
            size: 22,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          AppLocalizations.of(context).text('rgcDecision'),
          style: TextStyle(
            color: AppColors.primaryText(context),
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(height: 1, color: AppColors.border(context)),
        ),
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _DetailBlock(
                    label: AppLocalizations.of(context).text('submittedBy'),
                    value: 'Agriculture and Agro-In...',
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: _DetailBlock(
                    label: AppLocalizations.of(context).text('status'),
                    value:
                        '• ${AppLocalizations.of(context).status('Not Addressed')}',
                    valueColor: Color(0xFFEF4444),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _DetailBlock(
                    label: AppLocalizations.of(context).text('categories'),
                    value: 'Legislation',
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppLocalizations.of(
                          context,
                        ).text('meetingRequestDocument'),
                        style: TextStyle(
                          color: AppColors.mutedText,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(
                            Icons.picture_as_pdf,
                            color: Color(0xFFE53935),
                            size: 18,
                          ),
                          const SizedBox(width: 6),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '—',
                                style: TextStyle(
                                  color: AppColors.primaryText(context),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _MetaChip(
                    label:
                        '${AppLocalizations.of(context).text('submittedBy')} : Sabada',
                  ),
                  SizedBox(width: 8),
                  _MetaChip(
                    label:
                        '${AppLocalizations.of(context).text('submittedDate')} : Jun 24 2025',
                  ),
                  SizedBox(width: 8),
                  _MetaChip(
                    label:
                        '${AppLocalizations.of(context).text('governmentAgency')} : MAFF',
                  ),
                  SizedBox(width: 8),
                  _MetaChip(
                    label:
                        "${AppLocalizations.of(context).text('governmentSecondAgency')} : ${AppLocalizations.of(context).text('noData')}",
                  ),
                  SizedBox(width: 8),
                  _MetaChip(
                    label:
                        "${AppLocalizations.of(context).text('governmentThirdAgency')} : ${AppLocalizations.of(context).text('noData')}",
                  ),
                  SizedBox(width: 8),
                  _MetaChip(
                    label:
                        "${AppLocalizations.of(context).text('governmentFourthAgency')} : ${AppLocalizations.of(context).text('noData')}",
                  ),
                  SizedBox(width: 8),
                  _MetaChip(
                    label:
                        "${AppLocalizations.of(context).text('governmentFifthAgency')} : ${AppLocalizations.of(context).text('noData')}",
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            _SectionBlock(
              title: AppLocalizations.of(context).text('issuesDescription'),
              content: '',
              minHeight: 50,
            ),
            const SizedBox(height: 16),
            _SectionBlock(
              title: AppLocalizations.of(context).text('recommendations'),
              content: '',
              minHeight: 50,
            ),
            const SizedBox(height: 16),
            _SectionBlock(
              title: AppLocalizations.of(context).text('rgcDecision'),
              content:
                  '5. Entrust His Excellency Peng Ponea, Minister of Public Works and Transport to amend the relevant laws and regulations with comprehensive study of technical aspects to determine the type of vehicles and the type of roads that can be used for increasing the weight level of trucks from 40 tons to 45 tons (per truck).',
            ),
            const SizedBox(height: 16),
            _SectionBlock(
              title: AppLocalizations.of(context).text('indicators'),
              content: '',
              minHeight: 50,
            ),
            const SizedBox(height: 16),
            _SectionBlock(
              title: AppLocalizations.of(context).text('progressSolution'),
              content: '',
              minHeight: 50,
            ),
            const SizedBox(height: 16),
            _SectionBlock(
              title: AppLocalizations.of(
                context,
              ).text('implementationChallenges'),
              content: '',
              minHeight: 50,
            ),
            const SizedBox(height: 16),
            _SectionBlock(
              title: AppLocalizations.of(context).text('request'),
              content: '',
              minHeight: 50,
            ),
            const SizedBox(height: 16),
            _SectionBlock(
              title: AppLocalizations.of(context).text('nextStep'),
              content: '',
              minHeight: 50,
            ),
            const SizedBox(height: 16),
            _SectionBlock(
              title: AppLocalizations.of(context).text('sourceOfVerification'),
              content:
                  'Announement No. 002 Dated on 27-02-2024 និង កំណត់ហេតុស្តីពីកិច្ចប្រជុំអន្តរក្រសួងស្តីពីការដោះស្រាយបញ្ហាប្រឈមពាក់ព័ន្ធនឹងការគ្រប់គ្រងលើវិស័យដឹកជញ្ជូនផ្លូវគោក ក្រសួងសាធារណការ និងដឹកជញ្ជូន និងក្រសួងអភិវឌ្ឍន៍ជនបទ',
            ),
            const SizedBox(height: 16),
            Text(
              AppLocalizations.of(context).text('linkToVerificationSource'),
              style: TextStyle(
                color: AppColors.primaryText(context),
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkCard : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isDark
                      ? AppColors.darkBorder
                      : const Color(0xFFE2E8F0),
                ),
              ),
              child: const SelectableText(
                'https://drive.google.com/file/d/1edtgGRPmhe3RXUP5nOWsJW-xn23rrAPR/view?usp=drive_link',
                style: TextStyle(
                  color: Color(0xFF1E73BE),
                  fontSize: 11,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailBlock extends StatelessWidget {
  const _DetailBlock({
    required this.label,
    required this.value,
    this.valueColor,
  });

  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppColors.mutedText,
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: TextStyle(
            color: valueColor ?? AppColors.primaryText(context),
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _SectionBlock extends StatelessWidget {
  const _SectionBlock({
    required this.title,
    required this.content,
    this.minHeight,
  });

  final String title;
  final String content;
  final double? minHeight;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            color: AppColors.primaryText(context),
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          constraints: BoxConstraints(minHeight: minHeight ?? 0),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkCard : const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isDark ? AppColors.darkBorder : const Color(0xFFE2E8F0),
            ),
          ),
          child: Text(
            content,
            style: TextStyle(
              color: AppColors.primaryText(context),
              fontSize: 12,
              height: 1.5,
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
      ],
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : const Color(0xFFE2E8F0),
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: AppColors.secondaryText(context),
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
