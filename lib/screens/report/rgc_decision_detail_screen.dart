import 'package:flutter/material.dart';

import '../../core/app_colors.dart';

class RgcDecisionDetailScreen extends StatelessWidget {
  const RgcDecisionDetailScreen({
    super.key,
    required this.agencyName,
  });

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
          'RGC Decision',
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
              children: const [
                Expanded(
                  child: _DetailBlock(
                    label: 'Submitted by',
                    value: 'Agriculture and Agro-In...',
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: _DetailBlock(
                    label: 'Status :',
                    value: '• Not Addressed',
                    valueColor: Color(0xFFEF4444),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Expanded(
                  child: _DetailBlock(
                    label: 'Categories',
                    value: 'Legislation',
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Meeting Request Document:',
                        style: TextStyle(
                          color: AppColors.mutedText,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.picture_as_pdf, color: Color(0xFFE53935), size: 18),
                          const SizedBox(width: 6),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Request Doc',
                                style: TextStyle(
                                  color: AppColors.primaryText(context),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const Text(
                                '200 KB',
                                style: TextStyle(
                                  color: AppColors.mutedText,
                                  fontSize: 7,
                                  fontWeight: FontWeight.w500,
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
                children: const [
                  _MetaChip(label: 'Submitted By : Sabada'),
                  SizedBox(width: 8),
                  _MetaChip(label: 'Submitted Date : Jun 24 2025'),
                  SizedBox(width: 8),
                  _MetaChip(label: 'Government Agency : MAFF'),
                  SizedBox(width: 8),
                  _MetaChip(label: "Gov't Second Agency : Not Data"),
                  SizedBox(width: 8),
                  _MetaChip(label: "Gov't Third Agency : Not Data"),
                  SizedBox(width: 8),
                  _MetaChip(label: "Gov't Fourth Agency : Not Data"),
                  SizedBox(width: 8),
                  _MetaChip(label: "Gov't Fifth Agency : Not Data"),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const _SectionBlock(
              title: 'Issues Description',
              content: '',
              minHeight: 50,
            ),
            const SizedBox(height: 16),
            const _SectionBlock(
              title: 'Recommendations',
              content: '',
              minHeight: 50,
            ),
            const SizedBox(height: 16),
            const _SectionBlock(
              title: 'RGC Decision',
              content:
                  '5. Entrust His Excellency Peng Ponea, Minister of Public Works and Transport to amend the relevant laws and regulations with comprehensive study of technical aspects to determine the type of vehicles and the type of roads that can be used for increasing the weight level of trucks from 40 tons to 45 tons (per truck).',
            ),
            const SizedBox(height: 16),
            const _SectionBlock(
              title: 'Indicators',
              content: '',
              minHeight: 50,
            ),
            const SizedBox(height: 16),
            const _SectionBlock(
              title: 'Progress Solution',
              content: '',
              minHeight: 50,
            ),
            const SizedBox(height: 16),
            const _SectionBlock(
              title: 'Implementation Challenges',
              content: '',
              minHeight: 50,
            ),
            const SizedBox(height: 16),
            const _SectionBlock(
              title: 'Request',
              content: '',
              minHeight: 50,
            ),
            const SizedBox(height: 16),
            const _SectionBlock(
              title: 'Next Step',
              content: '',
              minHeight: 50,
            ),
            const SizedBox(height: 16),
            const _SectionBlock(
              title: 'Source of Verification',
              content:
                  'Announement No. 002 Dated on 27-02-2024 និង កំណត់ហេតុស្តីពីកិច្ចប្រជុំអន្តរក្រសួងស្តីពីការដោះស្រាយបញ្ហាប្រឈមពាក់ព័ន្ធនឹងការគ្រប់គ្រងលើវិស័យដឹកជញ្ជូនផ្លូវគោក ក្រសួងសាធារណការ និងដឹកជញ្ជូន និងក្រសួងអភិវឌ្ឍន៍ជនបទ',
            ),
            const SizedBox(height: 16),
            Text(
              'Link to Verification Source',
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
                  color: isDark ? AppColors.darkBorder : const Color(0xFFE2E8F0),
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
