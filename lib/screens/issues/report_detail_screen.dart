import 'package:flutter/material.dart';

import '../../core/app_colors.dart';
import '../../translations/app_localizations.dart';

class ReportDetailScreen extends StatefulWidget {
  const ReportDetailScreen({super.key});

  @override
  State<ReportDetailScreen> createState() => _ReportDetailScreenState();
}

class _ReportDetailScreenState extends State<ReportDetailScreen> {
  bool _expandDescription = false;
  bool _expandSolution = false;
  bool _expandChallenges = false;
  bool _expandRequests = false;
  bool _expandRgcDecision = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : const Color(0xFFFAFAFA),
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.darkBackground : Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: Theme.of(context).colorScheme.onSurface,
            size: 22,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Issue Details',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(
            height: 1,
            color: isDark ? AppColors.darkBorder : const Color(0xFFF0F2F5),
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        children: [
          // ISSUE TITLE
          Text(
            'Climate Issue',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 14),

          // INFO GRID 2x2
          const _ReportInfoGrid(),
          const SizedBox(height: 16),

          // KHMER DESCRIPTION TEXT
          Text(
            'ខ្ញុំសូមស្នើសុំរៀបចំកិច្ចប្រជុំពិសេសមួយ ដើម្បីដោះស្រាយបញ្ហាប្រឈមចំពោះបញ្ហាបច្ចុប្បន្នចំនួន ៤ ដែលគំរោងមានឥទ្ធិពលលើការងាររបស់យើងគោលបំណងនៃកិច្ចប្រជុំនេះគឺដើម្បីប្រមូលអ្នកពាក់ព័ន្ធទាំងអស់រួមទាំងសមាជិកក្រុម និងអ្នកធ្វើសេចក្តីសម្រេចនៅក្នុងបរិបទសហការដែលអាចពិភាក្សាបញ្ហាទាំងអស់បញ្ហាឫសគល់ហេតុដើម ស្វែងរកដំណោះស្រាយសក្តិសមនិងកំណត់ផែនការអនុវត្តជាក់លាក់។របៀបវារៈនឹងត្រូវរៀបចំជាផ្នែក ៤ ដោយផ្នែកនីមួយៗផ្តោតលើបញ្ហាប្រឈមមួយៗ ក្នុងផ្នែកនីមួយៗ យើងនឹង៖\n'
            '  ១. បង្ហាញសេចក្តីលម្អិតអំពីបញ្ហាប្រឈម ឬទិន្នន័យ ឬឧទាហរណ៍ដែលបង្ហាញពីបញ្ហា។\n'
            '  ២. វិភាគមូលហេតុ និងកត្តាដែលបង្ក។\n'
            '  ៣. ពិភាក្សាអំពីដំណោះស្រាយសក្តិសម ពិនិត្យលទ្ធភាព ហានិភ័យ និងអត្ថប្រយោជន៍។\n'
            '  ៤. សម្រេចយុទ្ធសាស្ត្រជាក់លាក់ ដោយកំណត់អ្នកទទួលខុសត្រូវ',
            maxLines: _expandDescription ? 100 : 12,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: isDark ? AppColors.secondaryText(context) : const Color(0xFF334155),
              fontSize: 12,
              height: 1.55,
              fontWeight: FontWeight.w400,
            ),
          ),
          const SizedBox(height: 6),
          InkWell(
            onTap: () {
              setState(() => _expandDescription = !_expandDescription);
            },
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _expandDescription ? 'View Less' : 'View Details',
                  style: const TextStyle(
                    color: Color(0xFF1E73BE),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  _expandDescription
                      ? Icons.keyboard_arrow_up
                      : Icons.keyboard_arrow_down,
                  color: const Color(0xFF1E73BE),
                  size: 16,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // 1. SOLUTION INDICATORS | សូចនាករដំណោះស្រាយ
          _SectionBlock(
            title: 'Solution Indicators | សូចនាករដំណោះស្រាយ',
            content:
                'ផ្នែកឯកជនស្នើស្រាវជ្រាវសម្រួលក្នុងឆន្ទានុសិទ្ធិរបស់ក្រសួងកសិកម្មរុក្ខាប្រមាញ់ និងនេសាទដើម្បីផ្តល់ព័ត៌មានស្តីពីសេរីភាពនៃការវិនិយោគ និងការសម្របសម្រួលការនាំចេញបន្ថែមវិញ។',
            isExpanded: _expandSolution,
            onReadMoreToggle: () {
              setState(() => _expandSolution = !_expandSolution);
            },
          ),
          const SizedBox(height: 18),

          // 2. CHALLENGES | បញ្ហាប្រឈម
          _SectionBlock(
            title: 'Challenges | បញ្ហាប្រឈម',
            content:
                'ផ្នែកឯកជនស្នើស្រាវជ្រាវសម្រួលក្នុងឆន្ទានុសិទ្ធិរបស់ក្រសួងកសិកម្មរុក្ខាប្រមាញ់ និងនេសាទដើម្បីផ្តល់ព័ត៌មានស្តីពីសេរីភាពនៃការវិនិយោគ និងការសម្របសម្រួលការនាំចេញបន្ថែមវិញ។',
            isExpanded: _expandChallenges,
            onReadMoreToggle: () {
              setState(() => _expandChallenges = !_expandChallenges);
            },
          ),
          const SizedBox(height: 18),

          // 3. REQUESTS | សំណូមពរ
          _SectionBlock(
            title: 'Requests | សំណូមពរ',
            content:
                'ផ្នែកឯកជនស្នើស្រាវជ្រាវសម្រួលក្នុងឆន្ទានុសិទ្ធិរបស់ក្រសួងកសិកម្មរុក្ខាប្រមាញ់ និងនេសាទដើម្បីផ្តល់ព័ត៌មានស្តីពីសេរីភាពនៃការវិនិយោគ និងការសម្របសម្រួលការនាំចេញបន្ថែមវិញ។',
            isExpanded: _expandRequests,
            onReadMoreToggle: () {
              setState(() => _expandRequests = !_expandRequests);
            },
          ),
          const SizedBox(height: 18),

          // 4. RGC DECISION
          _SectionBlock(
            title: 'RGC Decision',
            content:
                'ផ្នែកឯកជនស្នើស្រាវជ្រាវសម្រួលក្នុងឆន្ទានុសិទ្ធិរបស់ក្រសួងកសិកម្មរុក្ខាប្រមាញ់ និងនេសាទដើម្បីផ្តល់ព័ត៌មានស្តីពីសេរីភាពនៃការវិនិយោគ និងការសម្របសម្រួលការនាំចេញបន្ថែមវិញ។',
            isExpanded: _expandRgcDecision,
            onReadMoreToggle: () {
              setState(() => _expandRgcDecision = !_expandRgcDecision);
            },
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

class _ReportInfoGrid extends StatelessWidget {
  const _ReportInfoGrid();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Expanded(
              child: _InfoField(
                label: 'Implementation Date',
                value: 'June 29, 2025 | 2:00-3:00PM',
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: _InfoField(
                label: 'Status :',
                value: 'Complete',
                valueColor: Color(0xFF1E73BE),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Expanded(
              child: _DocumentField(
                label: 'Meeting Reference Document :',
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: _InfoField(
                label: 'Reference Name',
                value: 'របាយការណ៍',
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _InfoField extends StatelessWidget {
  const _InfoField({
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
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: AppColors.mutedText,
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: valueColor ?? Theme.of(context).colorScheme.onSurface,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _DocumentField extends StatelessWidget {
  const _DocumentField({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: AppColors.mutedText,
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 5),
        Row(
          children: [
            const Icon(Icons.picture_as_pdf, color: Color(0xFFEF4444), size: 18),
            const SizedBox(width: 6),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Request Doc',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Text(
                    '200 KB',
                    style: TextStyle(
                      color: AppColors.mutedText,
                      fontSize: 9,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _SectionBlock extends StatelessWidget {
  const _SectionBlock({
    required this.title,
    required this.content,
    required this.isExpanded,
    required this.onReadMoreToggle,
  });

  final String title;
  final String content;
  final bool isExpanded;
  final VoidCallback onReadMoreToggle;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkCard : const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isDark ? AppColors.darkBorder : const Color(0xFFE2E8F0),
              width: 1.1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                content,
                maxLines: isExpanded ? 100 : 3,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: isDark
                      ? AppColors.secondaryText(context)
                      : const Color(0xFF475569),
                  fontSize: 12,
                  height: 1.5,
                  fontWeight: FontWeight.w400,
                ),
              ),
              const SizedBox(height: 6),
              InkWell(
                onTap: onReadMoreToggle,
                child: Text(
                  isExpanded ? 'Show less' : 'Read more',
                  style: const TextStyle(
                    color: Color(0xFF1E73BE),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
