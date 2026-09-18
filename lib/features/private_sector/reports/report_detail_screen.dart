import 'package:flutter/material.dart';

import '../../../../core/app_colors.dart';
import '../../../../translations/app_localizations.dart';

class ReportDetailScreen extends StatefulWidget {
  const ReportDetailScreen({super.key, required this.title});

  final String title;

  @override
  State<ReportDetailScreen> createState() => _ReportDetailScreenState();
}

class _ReportDetailScreenState extends State<ReportDetailScreen> {
  int _selectedTab = 0;

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
          'Progress Report Details',
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
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 17, 16, 28),
          children: [
            Text(
              'Ministry of Agriculture Forestry\nand Fisheries',
              style: TextStyle(
                color: AppColors.primaryText(context),
                fontSize: 20,
                height: 1.22,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 14),
            _MaffInfoSection(title: widget.title),
            const SizedBox(height: 9),
            const _CdcInfoSection(),
            const SizedBox(height: 6),
            _ReportDetailTabs(
              selectedIndex: _selectedTab,
              onSelected: (index) => setState(() => _selectedTab = index),
            ),
            _buildTabContent(),
          ],
        ),
      ),
    );
  }

  Widget _buildTabContent() {
    return switch (_selectedTab) {
      0 => const _DescriptionTab(),
      1 => const _IssueListTab(status: _ReportIssueStatus.notAddressed),
      2 => const _IssueListTab(status: _ReportIssueStatus.solved),
      _ => const _AttachmentTab(),
    };
  }
}

class _MaffInfoSection extends StatelessWidget {
  const _MaffInfoSection({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHeader(title: 'MAFF Info'),
        const SizedBox(height: 11),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _InfoBlock(
                label: l10n.text('submittedDate'),
                value: 'June 07, 2025',
              ),
            ),
            const SizedBox(width: 18),
            const Expanded(
              child: _PersonInfoBlock(
                label: 'Prepare by',
                name: 'Ouk Sabda',
                date: 'June 01, 2025',
              ),
            ),
          ],
        ),
        const SizedBox(height: 13),
        const _DocumentInfoBlock(label: 'Approval Report'),
      ],
    );
  }
}

class _CdcInfoSection extends StatelessWidget {
  const _CdcInfoSection();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHeader(title: 'CDC Info'),
        const SizedBox(height: 11),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _InfoBlock(
                label: l10n.text('status'),
                value: '• ${l10n.text('underReview')}',
                valueColor: const Color(0xFFFF8A00),
              ),
            ),
            const SizedBox(width: 18),
            const Expanded(
              child: _PersonInfoBlock(
                label: 'Review by',
                name: 'Seng Phanat',
                date: 'June 01, 2025',
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        const Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _InfoBlock(label: 'Last Update', value: '2025'),
            ),
            SizedBox(width: 18),
            Expanded(
              child: _DocumentInfoBlock(label: 'Meeting Request Document:'),
            ),
          ],
        ),
        const SizedBox(height: 14),
        const Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _InfoBlock(
                label: 'Meeting Date & Time',
                value: 'September 22, 2025,\n2:00PM-5:00PM',
              ),
            ),
            SizedBox(width: 18),
            Expanded(
              child: _PersonInfoBlock(
                label: 'Review by',
                name: 'Seng Phanat',
                date: 'June 01, 2025',
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

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
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
        Divider(height: 1, color: AppColors.border(context)),
      ],
    );
  }
}

class _InfoBlock extends StatelessWidget {
  const _InfoBlock({required this.label, required this.value, this.valueColor});

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
        const SizedBox(height: 7),
        Text(
          value,
          style: TextStyle(
            color: valueColor ?? AppColors.primaryText(context),
            fontSize: 12,
            height: 1.35,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _PersonInfoBlock extends StatelessWidget {
  const _PersonInfoBlock({
    required this.label,
    required this.name,
    required this.date,
  });

  final String label;
  final String name;
  final String date;

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
        RichText(
          text: TextSpan(
            style: TextStyle(
              color: AppColors.primaryText(context),
              fontSize: 12,
              height: 1.35,
              fontWeight: FontWeight.w600,
            ),
            children: [
              TextSpan(text: name),
              TextSpan(
                text: '  ( $date )',
                style: const TextStyle(
                  color: AppColors.mutedText,
                  fontSize: 9,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DocumentInfoBlock extends StatelessWidget {
  const _DocumentInfoBlock({required this.label});

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
        const SizedBox(height: 7),
        Row(
          children: [
            Icon(Icons.picture_as_pdf, color: Color(0xFFE53935), size: 18),
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

class _ReportDetailTabs extends StatelessWidget {
  const _ReportDetailTabs({
    required this.selectedIndex,
    required this.onSelected,
  });

  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final labels = [
      l10n.text('descriptions'),
      l10n.text('allIssues'),
      l10n.text('rgcDecision'),
      l10n.text('attachment'),
    ];

    return SizedBox(
      height: 40,
      child: Row(
        children: List.generate(labels.length, (index) {
          final selected = selectedIndex == index;
          return Expanded(
            child: InkWell(
              onTap: () => onSelected(index),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    labels[index],
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: selected
                          ? AppColors.accent(context)
                          : AppColors.mutedText,
                      fontSize: 12,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 9),
                  Container(
                    height: 2,
                    color: selected
                        ? AppColors.accent(context)
                        : Colors.transparent,
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _DescriptionTab extends StatelessWidget {
  const _DescriptionTab();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: Text(
        'The private sector stated that cultivation is largely dependent on the '
        'weather (rain), and the private sector also observed that the Ministry '
        'of Water Resources and Meteorology often issues announcements '
        'regarding weather forecasting nationwide, which results in farmers in '
        'each region not receiving clear information.',
        style: TextStyle(
          color: AppColors.secondaryText(context),
          fontSize: 12,
          height: 1.62,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

enum _ReportIssueStatus { solved, notAddressed }

class _IssueListTab extends StatelessWidget {
  const _IssueListTab({required this.status});

  final _ReportIssueStatus status;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: Column(
        children: List.generate(
          1,
          (index) => Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: _ReportIssueCard(title: 'Climate Issue', status: status),
          ),
        ),
      ),
    );
  }
}

class _ReportIssueCard extends StatelessWidget {
  const _ReportIssueCard({required this.title, required this.status});

  final String title;
  final _ReportIssueStatus status;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final solved = status == _ReportIssueStatus.solved;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 13, 14, 13),
      decoration: BoxDecoration(
        color: AppColors.subtleBackground(context),
        borderRadius: BorderRadius.circular(8),
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
                    color: AppColors.primaryText(context),
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              _SmallStatusBadge(
                label: solved ? l10n.text('solved') : l10n.text('notAddressed'),
                color: solved
                    ? (isDark
                          ? const Color(0xFF86EFAC)
                          : const Color(0xFF16A34A))
                    : (isDark
                          ? const Color(0xFFD1D5DB)
                          : const Color(0xFF4B5563)),
                background: solved
                    ? (isDark
                          ? const Color(0xFF123B2A)
                          : const Color(0xFFF0FDF4))
                    : AppColors.cardBackground(context),
                border: solved
                    ? (isDark
                          ? const Color(0xFF166534)
                          : const Color(0xFF86EFAC))
                    : (isDark
                          ? const Color(0xFF4B5563)
                          : const Color(0xFFE5E7EB)),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
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
    );
  }
}

class _SmallStatusBadge extends StatelessWidget {
  const _SmallStatusBadge({
    required this.label,
    required this.color,
    required this.background,
    required this.border,
  });

  final String label;
  final Color color;
  final Color background;
  final Color border;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: border),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

class _AttachmentTab extends StatelessWidget {
  const _AttachmentTab();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Column(
        children: const [
          _AttachmentCard(title: 'Request Doc'),
          SizedBox(height: 10),
          _AttachmentCard(title: 'Approval Report'),
        ],
      ),
    );
  }
}

class _AttachmentCard extends StatelessWidget {
  const _AttachmentCard({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.cardBackground(context),
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: AppColors.border(context)),
      ),
      child: Row(
        children: [
          const Icon(Icons.picture_as_pdf, color: Color(0xFFE53935), size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                color: AppColors.primaryText(context),
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
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
    );
  }
}
