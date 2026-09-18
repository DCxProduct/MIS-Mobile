import 'package:flutter/material.dart';

import '../../../../core/app_colors.dart';

class MeetingSummaryDetailScreen extends StatelessWidget {
  const MeetingSummaryDetailScreen({super.key});

  static const _title =
      'សិក្ខាសាលាប្រចាំឆ្នាំរបស់ក្រុមការងារ ៣ ដែលមាននាង\nទ្រព្យអ្នកប្រតិបត្តិការ ៤';

  @override
  Widget build(BuildContext context) {
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
          'Meeting Summary Details',
          style: TextStyle(
            color: AppColors.primaryText(context),
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.more_horiz,
              color: AppColors.primaryText(context),
              size: 22,
            ),
            onPressed: () {},
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 16, 14, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _title,
                    style: TextStyle(
                      color: AppColors.primaryText(context),
                      fontSize: 15,
                      height: 1.45,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 14),
                  const _SummaryInfoGrid(),
                  const SizedBox(height: 16),
                  const _AllIssuesTabHeader(),
                ],
              ),
            ),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 28),
                itemCount: 3,
                separatorBuilder: (_, _) => const SizedBox(height: 14),
                itemBuilder: (context, index) =>
                    _ClimateIssueCard(onTap: () => _showIssueDetails(context)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showIssueDetails(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      isDismissible: true,
      enableDrag: true,
      barrierColor: Colors.black54,
      backgroundColor: Colors.transparent,
      builder: (context) => const _IssueDetailsSheet(),
    );
  }
}

class _SummaryInfoGrid extends StatelessWidget {
  const _SummaryInfoGrid();

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _InfoBlock(
                label: 'Meeting Time',
                value: '2:00 PM - 4:00 PM',
              ),
            ),
            SizedBox(width: 24),
            Expanded(
              child: _InfoBlock(
                label: 'Schedule Meeting :',
                value: 'September 22, 2025',
              ),
            ),
          ],
        ),
        SizedBox(height: 17),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _InfoBlock(label: 'Location', value: 'Chbar Ompov'),
            ),
            SizedBox(width: 24),
            Expanded(child: _DocumentBlock(label: 'Meeting Request Document:')),
          ],
        ),
      ],
    );
  }
}

class _InfoBlock extends StatelessWidget {
  const _InfoBlock({required this.label, required this.value});

  final String label;
  final String value;

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
        const SizedBox(height: 7),
        Text(
          value,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: AppColors.primaryText(context),
            fontSize: 12,
            height: 1.35,
            fontWeight: FontWeight.w700,
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
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: AppColors.mutedText,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 7),
        Row(
          children: [
            const Icon(
              Icons.picture_as_pdf,
              color: Color(0xFFE53935),
              size: 18,
            ),
            const SizedBox(width: 7),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Request Doc',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: AppColors.primaryText(context),
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 1),
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
            ),
          ],
        ),
      ],
    );
  }
}

class _AllIssuesTabHeader extends StatelessWidget {
  const _AllIssuesTabHeader();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 40,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Text(
              'All Issues',
              style: TextStyle(
                color: AppColors.primary,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          SizedBox(height: 9),
          Divider(height: 2, thickness: 2, color: AppColors.primary),
        ],
      ),
    );
  }
}

class _ClimateIssueCard extends StatelessWidget {
  const _ClimateIssueCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 13, 14, 13),
        decoration: BoxDecoration(
          color: AppColors.subtleBackground(context),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Climate Issue',
                    style: TextStyle(
                      color: AppColors.primaryText(context),
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.cardBackground(context),
                    borderRadius: BorderRadius.circular(5),
                    border: Border.all(color: AppColors.border(context)),
                  ),
                  child: Text(
                    'Not Addressed',
                    style: TextStyle(
                      color: AppColors.secondaryText(context),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            const Text(
              'Governance',
              style: TextStyle(
                color: Color(0xFF7C3AED),
                fontSize: 12,
                fontWeight: FontWeight.w600,
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

class _IssueDetailsSheet extends StatelessWidget {
  const _IssueDetailsSheet();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => Navigator.of(context).pop(),
      child: Align(
        alignment: Alignment.bottomCenter,
        child: GestureDetector(
          onTap: () {},
          child: FractionallySizedBox(
            heightFactor: 0.74,
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.cardBackground(context),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(10),
                ),
              ),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(14, 16, 14, 28),
                children: [
                  Center(
                    child: Text(
                      'Issues Details',
                      style: TextStyle(
                        color: AppColors.primaryText(context),
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  SizedBox(height: 24),
                  Text(
                    MeetingSummaryDetailScreen._title,
                    style: TextStyle(
                      color: AppColors.primaryText(context),
                      fontSize: 15,
                      height: 1.45,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: 18),
                  const _IssueSheetInfoGrid(),
                  const SizedBox(height: 10),
                  const Row(
                    children: [
                      Expanded(
                        child: _DatePill(
                          label: 'Submitted By',
                          value: 'Sabada',
                        ),
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: _DatePill(
                          label: 'Submitted Date',
                          value: 'Jun 24 2025',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const _ReadMorePanel(title: 'Issues Descriptions'),
                  const SizedBox(height: 18),
                  const _ReadMorePanel(title: 'Recommendations'),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _IssueSheetInfoGrid extends StatelessWidget {
  const _IssueSheetInfoGrid();

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _InfoBlock(
                label: 'Submitted by',
                value: 'Agriculture and Agro-In...',
              ),
            ),
            SizedBox(width: 18),
            Expanded(
              child: _InfoBlock(label: 'Status :', value: '• Not Addressed'),
            ),
          ],
        ),
        SizedBox(height: 16),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _InfoBlock(label: 'Categories', value: 'Legislation'),
            ),
            SizedBox(width: 18),
            Expanded(child: _DocumentBlock(label: 'Meeting Request Document:')),
          ],
        ),
      ],
    );
  }
}

class _DatePill extends StatelessWidget {
  const _DatePill({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 31,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      alignment: Alignment.centerLeft,
      decoration: BoxDecoration(
        color: AppColors.fieldBackground(context),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: AppColors.border(context)),
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
              text: value,
              style: TextStyle(
                color: AppColors.primaryText(context),
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontSize: 11),
      ),
    );
  }
}

class _ReadMorePanel extends StatelessWidget {
  const _ReadMorePanel({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            color: AppColors.primaryText(context),
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
          decoration: BoxDecoration(
            color: AppColors.cardBackground(context),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: AppColors.border(context)),
          ),
          child: Text.rich(
            TextSpan(
              text:
                  'ទំនុកចិត្តរបស់វិស័យឯកជនបានលើកឡើងថាការដាំដុះពឹងផ្អែកទៅលើអាកាសធាតុ និងការជូនដំណឹងអំពីអាកាសធាតុនៅតាមតំបន់មិនទាន់បានច្បាស់លាស់គ្រប់គ្រាន់...',
              children: [
                TextSpan(
                  text: '\nRead more',
                  style: TextStyle(
                    color: AppColors.primary,
                    decoration: TextDecoration.underline,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            maxLines: 7,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: AppColors.secondaryText(context),
              fontSize: 11,
              height: 1.45,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}
