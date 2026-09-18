import 'package:flutter/material.dart';

import '../../../../core/app_colors.dart';

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
          icon: Icon(Icons.arrow_back, color: colors.onSurface, size: 22),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Meeting Request Details',
          style: TextStyle(
            color: colors.onSurface,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.more_horiz, color: colors.onSurface, size: 22),
            onPressed: () {},
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(height: 1, color: AppColors.border(context)),
        ),
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                children: [
                  Text(
                    widget.title,
                    style: TextStyle(
                      color: colors.onSurface,
                      fontSize: 15,
                      height: 1.35,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const _PrivateSectorInfoGrid(),
                  const SizedBox(height: 14),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: const [
                        _PersonChip(
                          label: 'Submitted By',
                          name: 'Sabada',
                        ),
                        SizedBox(width: 10),
                        _PersonChip(
                          label: 'Received by',
                          name: 'Sambath',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  _DetailTabs(
                    selectedIndex: _selectedTab,
                    onSelected: (index) => setState(() => _selectedTab = index),
                  ),
                  const SizedBox(height: 16),
                  switch (_selectedTab) {
                    0 => const _DescriptionsView(),
                    _ => const _AllIssuesView(),
                  },
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PrivateSectorInfoGrid extends StatelessWidget {
  const _PrivateSectorInfoGrid();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Expanded(
              child: _DetailInfoBlock(
                label: 'Submitted Date:',
                value: 'Aug 10, 2025',
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: _DetailInfoBlock(
                label: 'Status :',
                value: 'Submitted',
                valueColor: Color(0xFF16A34A),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Government Agency :',
                    style: TextStyle(
                      color: AppColors.mutedText,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Container(
                        width: 14,
                        height: 14,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [Color(0xFF1E73BE), Color(0xFF1EA45B)],
                          ),
                        ),
                        child: const Icon(
                          Icons.account_balance,
                          color: Colors.white,
                          size: 9,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'MAFF',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            const Expanded(
              child: _PdfBlock(label: 'Meeting Request Document:'),
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
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          value,
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

class _PdfBlock extends StatelessWidget {
  const _PdfBlock({required this.label});

  final String label;

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
      height: 31,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      alignment: Alignment.centerLeft,
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
              style: const TextStyle(
                color: AppColors.mutedText,
                fontWeight: FontWeight.w500,
              ),
            ),
            TextSpan(
              text: name,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        style: const TextStyle(fontSize: 11),
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
    final labels = ['Descriptions', 'All Issues'];

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
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: selectedIndex == index
                          ? AppColors.accent(context)
                          : Colors.transparent,
                      width: 2,
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
                    fontWeight: selectedIndex == index
                        ? FontWeight.w700
                        : FontWeight.w600,
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
    return Text(
      'ខ្ញុំសូមស្នើឱ្យរៀបចំប្រជុំពិសេសមួយដើម្បីដោះស្រាយនិងឆ្លើយតបចំពោះបញ្ហាប្រឈមមធ្យមចំនួន ៥ ដែលកំពុងមានឥទ្ធិពលលើការងាររបស់យើង។ គោលបំណងនៃប្រជុំនេះគឺដើម្បីប្រមូលផ្តុំអ្នកពាក់ព័ន្ធទាំងអស់ រួមទាំងសមាជិកក្រុម និងអ្នកធ្វើសេចក្តីសម្រេច នៅក្នុងបរិយាកាសសហការដែលអាចពិភាក្សាភ្នាប់បញ្ហាទាំងអស់ បញ្ហាមូលហេតុដើម ស្វែងរកដំណោះស្រាយរួម និងកំណត់ផែនការអនុវត្តជាក់ស្តែង។ ប្រជុំនេះនឹងត្រូវរៀបចំជាផ្នែក ៥ ដោយផ្នែកនីមួយៗផ្តោតលើបញ្ហាប្រឈមមធ្យមមួយៗ។ ក្នុងផ្នែកនីមួយៗយើងនឹង៖\n'
      '  1. បង្ហាញសេចក្តីសង្ខេបអំពីបញ្ហាប្រឈម រួមទាំងទិន្នន័យ ឬឧទាហរណ៍ដែលបង្ហាញពីបញ្ហា។\n'
      '  2. វិភាគមូលហេតុ និងកត្តាដែលបណ្តាល។\n'
      '  3. ពិភាក្សាអំពីដំណោះស្រាយសក្តិសម ពិនិត្យលទ្ធភាព ហានិភ័យ និងអត្ថប្រយោជន៍។\n'
      '  4. សម្រេចយុទ្ធសាស្ត្រជាក់លាក់ ដោយកំណត់អ្នកទទួលខុសត្រូវ និងកាលកំណត់។\n\n'
      'លទ្ធផលដែលរំពឹងទុកពីប្រជុំនេះ៖\n'
      'គឺការទទួលបានឯកសារយុទ្ធការអំពើដោះស្រាយ និងផែនការតាមដាន ដើម្បីធានាថាការអនុវត្តមានប្រសិទ្ធភាព។ ការងាររួមគ្នានៅក្នុងប្រជុំពិសេស និងផ្តោតលើដំណោះស្រាយនេះ នឹងជួយបង្កើនការសហការរវាងក្រុម ធ្វើឱ្យការអនុវត្តមានប្រសិទ្ធភាព និងលុបបំបាត់ឧបសគ្គដែលរារាំងការរីកចម្រើន។\n'
      'ប្រជុំនេះមានសារៈសំខាន់ ដើម្បីធានាថាការងាររបស់យើងស្របគ្នា ការងារកំពុងដំណើរការមានភាពរលូន និងដោះស្រាយបញ្ហាប្រឈមទាំងនេះមុ...',
      style: TextStyle(
        color: AppColors.secondaryText(context),
        fontSize: 12,
        height: 1.6,
        fontWeight: FontWeight.w500,
      ),
    );
  }
}

class _AllIssuesView extends StatelessWidget {
  const _AllIssuesView();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: const [
        _IssueCard(
          title: 'Joint Inspection',
          category: 'Procedure',
          status: 'Solved',
        ),
        _IssueCard(
          title: 'Climate Issue',
          category: 'Governance',
          status: 'Not Addressed',
        ),
      ],
    );
  }
}

class _IssueCard extends StatelessWidget {
  const _IssueCard({
    required this.title,
    required this.category,
    required this.status,
  });

  final String title;
  final String category;
  final String status;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final isSolved = status == 'Solved';
    final statusColor = isSolved
        ? (isDark ? const Color(0xFF86EFAC) : const Color(0xFF16A34A))
        : (isDark ? const Color(0xFFD1D5DB) : const Color(0xFF6B7280));
    final statusBg = isSolved
        ? (isDark ? const Color(0xFF123B2A) : const Color(0xFFEAFBF0))
        : (isDark ? const Color(0xFF222835) : const Color(0xFFF3F4F6));
    final statusBorder = isSolved
        ? (isDark ? const Color(0xFF166534) : const Color(0xFF9BE2B4))
        : (isDark ? const Color(0xFF4B5563) : const Color(0xFFD1D5DB));

    return InkWell(
      onTap: () {
        _showIssueDetailsSheet(
          context,
          title: title,
          category: category,
          status: status,
        );
      },
      borderRadius: BorderRadius.circular(10),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : const Color(0xFFFAFAFB),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isDark ? AppColors.darkBorder : const Color(0xFFEAEAEA),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusBg,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: statusBorder),
                  ),
                  child: Text(
                    status,
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              category,
              style: const TextStyle(
                color: Color(0xFF7C3AED),
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
      ),
    );
  }
}

void _showIssueDetailsSheet(
  BuildContext context, {
  required String title,
  required String category,
  required String status,
}) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (context) {
      final isDark = Theme.of(context).brightness == Brightness.dark;
      final background = isDark ? AppColors.darkCard : Colors.white;

      return Container(
        decoration: BoxDecoration(
          color: background,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 38,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.darkBorder
                        : const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Center(
                child: Text(
                  'Issues Details',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'សំណើប្រជុំពិភាក្សាដោះស្រាយបញ្ហាចំនួន ៣ ដែលបានដាក់ជូនក្រសួងខាងក្រោម ។',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontSize: 15,
                  height: 1.35,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'Submitted by',
                          style: TextStyle(
                            color: AppColors.mutedText,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Agriculture and Agro-In...',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Status :',
                          style: TextStyle(
                            color: AppColors.mutedText,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '• $status',
                          style: TextStyle(
                            color: status == 'Solved'
                                ? const Color(0xFF16A34A)
                                : const Color(0xFFFF4842),
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Categories',
                          style: TextStyle(
                            color: AppColors.mutedText,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          category,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
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
                        const SizedBox(height: 4),
                        Row(
                          children: const [
                            Icon(Icons.picture_as_pdf,
                                color: Color(0xFFE53935), size: 16),
                            SizedBox(width: 6),
                            Text(
                              'Request Doc',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.darkBackground
                            : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                            color: isDark
                                ? AppColors.darkBorder
                                : const Color(0xFFE2E8F0)),
                      ),
                      child: const Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text: 'Submitted By : ',
                              style: TextStyle(color: AppColors.mutedText),
                            ),
                            TextSpan(
                              text: 'Sabada',
                              style: TextStyle(fontWeight: FontWeight.w700),
                            ),
                          ],
                        ),
                        style: TextStyle(fontSize: 11),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.darkBackground
                            : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                            color: isDark
                                ? AppColors.darkBorder
                                : const Color(0xFFE2E8F0)),
                      ),
                      child: const Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text: 'Submitted Date : ',
                              style: TextStyle(color: AppColors.mutedText),
                            ),
                            TextSpan(
                              text: 'Jun 24 2025',
                              style: TextStyle(fontWeight: FontWeight.w700),
                            ),
                          ],
                        ),
                        style: TextStyle(fontSize: 11),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Issues Descriptions',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              RichText(
                text: TextSpan(
                  style: TextStyle(
                    color: AppColors.secondaryText(context),
                    fontSize: 12,
                    height: 1.5,
                    fontWeight: FontWeight.w500,
                  ),
                  children: const [
                    TextSpan(
                      text:
                          'សូមស្នើឡើងរៀបចំប្រជុំពិសេសមួយដើម្បីដោះស្រាយនិងឆ្លើយតបចំពោះបញ្ហាប្រឈមមធ្យមចំនួន ៥ ដែលកំពុងមានឥទ្ធិពលលើការងាររបស់យើង។ គោលបំណងនៃប្រជុំនេះគឺដើម្បីប្រមូលផ្តុំអ្នកពាក់ព័ន្ធទាំងអស់... ',
                    ),
                    TextSpan(
                      text: 'Read more',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'Recommendations',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              RichText(
                text: TextSpan(
                  style: TextStyle(
                    color: AppColors.secondaryText(context),
                    fontSize: 12,
                    height: 1.5,
                    fontWeight: FontWeight.w500,
                  ),
                  children: const [
                    TextSpan(
                      text:
                          'ផ្អែកលើការស្នើសុំបណ្តោះអាសន្ន៖ ភ្នាក់ងារតាមដានរដ្ឋបាលនឹងសម្របសម្រួលជាមួយ... ',
                    ),
                    TextSpan(
                      text: 'Read more',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}
