import 'package:flutter/material.dart';

import '../../../../core/app_colors.dart';
import '../../../../translations/app_localizations.dart';

class MeetingRequestDetailScreen extends StatefulWidget {
  const MeetingRequestDetailScreen({super.key, required this.title});

  final String title;

  @override
  State<MeetingRequestDetailScreen> createState() =>
      _MeetingRequestDetailScreenState();
}

class _MeetingRequestDetailScreenState
    extends State<MeetingRequestDetailScreen> {
  int _selectedTab = 0;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final background = isDark ? AppColors.darkBackground : Colors.white;

    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        backgroundColor: background,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: colors.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          l10n.text('meetingRequestDetails'),
          style: TextStyle(
            color: colors.onSurface,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 14, 18, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: colors.onSurface,
                      fontSize: 15,
                      height: 1.25,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 18),
                  const _DetailInfoGrid(),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: _PersonChip(
                          label: l10n.text('submittedBy'),
                          name: 'Sabada',
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: _PersonChip(
                          label: l10n.text('receivedBy'),
                          name: 'Sambath',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _DetailTabs(
              selectedIndex: _selectedTab,
              onSelected: (index) => setState(() => _selectedTab = index),
            ),
            Expanded(
              child: _selectedTab == 0
                  ? const _DescriptionsView()
                  : const _AllIssuesView(),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailInfoGrid extends StatelessWidget {
  const _DetailInfoGrid();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _DetailInfoBlock(
                label: l10n.text('submittedDate'),
                value: 'Aug 10, 2025',
              ),
            ),
            const SizedBox(width: 22),
            Expanded(
              child: _DetailInfoBlock(
                label: '${l10n.text('status')} :',
                value: l10n.text('submitted'),
                valueColor: const Color(0xFF16A34A),
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _DetailInfoBlock(
                label: '${l10n.text('governmentAgency')} :',
                value: '🌐  MAFF',
              ),
            ),
            const SizedBox(width: 22),
            Expanded(
              child: _DocumentBlock(label: l10n.text('meetingRequestDocument')),
            ),
          ],
        ),
      ],
    );
  }
}

class _DetailInfoBlock extends StatelessWidget {
  const _DetailInfoBlock({
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
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            color: valueColor ?? Theme.of(context).colorScheme.onSurface,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _DocumentBlock extends StatelessWidget {
  const _DocumentBlock({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$label:',
          style: const TextStyle(
            color: AppColors.mutedText,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            const Icon(
              Icons.picture_as_pdf,
              color: Color(0xFFE53935),
              size: 22,
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'Request Doc',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                  Text(
                    '200 KB',
                    style: TextStyle(
                      color: AppColors.mutedText,
                      fontSize: 8,
                      fontWeight: FontWeight.w600,
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

class _PersonChip extends StatelessWidget {
  const _PersonChip({required this.label, required this.name});

  final String label;
  final String name;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: 30,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : const Color(0xFFFAFAFA),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : const Color(0xFFE4E7EC),
        ),
      ),
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: '$label : ',
              style: const TextStyle(color: AppColors.mutedText),
            ),
            TextSpan(
              text: name,
              style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
            ),
          ],
        ),
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _DetailTabs extends StatelessWidget {
  const _DetailTabs({required this.selectedIndex, required this.onSelected});

  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final labels = [l10n.text('descriptions'), l10n.text('allIssues')];

    return Container(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.border(context))),
      ),
      child: Row(
        children: List.generate(
          labels.length,
          (index) => Expanded(
            child: InkWell(
              onTap: () => onSelected(index),
              child: Container(
                height: 42,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: selectedIndex == index
                          ? AppColors.accent(context)
                          : Colors.transparent,
                      width: 1.5,
                    ),
                  ),
                ),
                child: Text(
                  labels[index],
                  style: TextStyle(
                    color: selectedIndex == index
                        ? AppColors.accent(context)
                        : AppColors.mutedText,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DescriptionsView extends StatelessWidget {
  const _DescriptionsView();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 24),
      children: [
        Text(
          'ខ្លឹមសារនៃកិច្ចប្រជុំនេះផ្តោតលើការតាមដានវឌ្ឍនភាពនៃការដោះស្រាយបញ្ហា និងការកំណត់ជំហានបន្ទាប់សម្រាប់ក្រុមការងារ។ កិច្ចប្រជុំនេះក៏ពិភាក្សាអំពីបញ្ហាប្រឈម សំណើ និងការសម្របសម្រួលជាមួយស្ថាប័នពាក់ព័ន្ធ។\n\n'
          '1. ពិនិត្យស្ថានភាពបញ្ហាដែលកំពុងដំណើរការ និងលទ្ធផលដែលសម្រេចបាន។\n'
          '2. កំណត់ចំណុចដែលត្រូវការសកម្មភាពបន្ថែមពីក្រុមការងារ។\n'
          '3. ពិភាក្សាពីការរៀបចំរបាយការណ៍វឌ្ឍនភាព និងឯកសារគាំទ្រ។\n'
          '4. ស្នើសុំការសហការពីស្ថាប័នពាក់ព័ន្ធ ដើម្បីធានាថាការអនុវត្តមានប្រសិទ្ធភាព។\n\n'
          'ការសម្រេចចិត្ត និងភារកិច្ចបន្តត្រូវបានកំណត់សម្រាប់អ្នកទទួលខុសត្រូវនីមួយៗ ដើម្បីតាមដាន និងរាយការណ៍លទ្ធផលនៅកិច្ចប្រជុំបន្ទាប់។',
          style: TextStyle(
            color: AppColors.secondaryText(context),
            fontSize: 12,
            height: 1.55,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _AllIssuesView extends StatelessWidget {
  const _AllIssuesView();

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 24),
      itemCount: 4,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) => const _IssueCard(),
    );
  }
}

class _IssueCard extends StatelessWidget {
  const _IssueCard();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : const Color(0xFFFAFAFB),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  'Climate Issue',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF222835) : Colors.white,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: isDark
                        ? const Color(0xFF4B5563)
                        : const Color(0xFFE1E5EA),
                  ),
                ),
                child: Text(
                  AppLocalizations.of(context).text('notAddressed'),
                  style: TextStyle(
                    color: isDark
                        ? const Color(0xFFD1D5DB)
                        : const Color(0xFF4B5563),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'Governance',
            style: TextStyle(
              color: Color(0xFF9C27B0),
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'The private sector stated that cultivation is largely dependent on the weather (rain), and the private sector also observed that the Ministry of Water Resources and...',
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: AppColors.secondaryText(context),
              fontSize: 12,
              height: 1.45,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
