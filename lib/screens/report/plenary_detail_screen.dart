import 'package:flutter/material.dart';

import '../../core/app_colors.dart';

class PlenaryDetailScreen extends StatelessWidget {
  const PlenaryDetailScreen({
    super.key,
    required this.title,
  });

  final String title;

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
          'Meeting Request Details',
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
                    label: 'Deadline',
                    value: 'June 07, 2025',
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: _DetailBlock(
                    label: 'Meeting Date',
                    value: 'Ouk Sabda ( June 01, 2025 )',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Expanded(
                  child: _DetailBlock(
                    label: 'Number of RGC Decision',
                    value: '179',
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: _DetailBlock(
                    label: 'Status :',
                    value: '• Sent',
                    valueColor: Color(0xFF1E73BE),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'Approval Report',
              style: TextStyle(
                color: AppColors.mutedText,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
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
            const SizedBox(height: 20),
            const _PlenaryIssueItemCard(
              meetingDate: 'Jun 20, 2025',
              category: 'Procedure',
              focalPerson: 'Dith Tina',
              description:
                  'The Ministry of Agriculture, Forestry and Fisheries (MAFF) agreed to have joint inspections and not multiple inspections. Inspections are only conducte...',
              status: 'Solved',
            ),
            const SizedBox(height: 14),
            const _PlenaryIssueItemCard(
              meetingDate: 'Jun 20, 2025',
              category: 'Procedure',
              focalPerson: 'Dith Tina',
              description:
                  'The Ministry of Agriculture, Forestry and Fisheries (MAFF) agreed to have joint inspections and not multiple inspections. Inspections are only conducte...',
              status: 'Solved',
            ),
            const SizedBox(height: 14),
            const _PlenaryIssueItemCard(
              meetingDate: 'Jun 20, 2025',
              category: 'Procedure',
              focalPerson: 'Dith Tina',
              description:
                  'The Ministry of Agriculture, Forestry and Fisheries (MAFF) agreed to have joint inspections and not multiple inspections. Inspections are only conducte...',
              status: 'Solved',
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
            fontSize: 12,
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

class _PlenaryIssueItemCard extends StatelessWidget {
  const _PlenaryIssueItemCard({
    required this.meetingDate,
    required this.category,
    required this.focalPerson,
    required this.description,
    required this.status,
  });

  final String meetingDate;
  final String category;
  final String focalPerson;
  final String description;
  final String status;

  void _openRgcDecisionBottomSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return const _RgcDecisionBottomSheet();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: () => _openRgcDecisionBottomSheet(context),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isDark ? AppColors.darkBorder : const Color(0xFFE5E8ED),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: _MetaItem(
                    icon: Icons.calendar_month_outlined,
                    label: 'Meeting Date',
                    value: meetingDate,
                    color: const Color(0xFF1E73BE),
                  ),
                ),
                Expanded(
                  child: _MetaItem(
                    icon: Icons.grid_view_outlined,
                    label: 'Categories',
                    value: category,
                    color: const Color(0xFF7C3AED),
                  ),
                ),
                Expanded(
                  child: _MetaItem(
                    icon: Icons.person_outline,
                    label: 'Focal Person',
                    value: focalPerson,
                    color: const Color(0xFF059669),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              description,
              style: TextStyle(
                color: AppColors.secondaryText(context),
                fontSize: 12,
                height: 1.45,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              height: 38,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: const Color(0xFF16A34A),
                  width: 1,
                ),
              ),
              child: const Text(
                'Solved',
                style: TextStyle(
                  color: Color(0xFF16A34A),
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RgcDecisionBottomSheet extends StatelessWidget {
  const _RgcDecisionBottomSheet();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final background = isDark ? AppColors.darkCard : Colors.white;

    return DraggableScrollableSheet(
      initialChildSize: 0.82,
      minChildSize: 0.5,
      maxChildSize: 0.92,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: background,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                child: Row(
                  children: [
                    InkWell(
                      onTap: () => Navigator.of(context).pop(),
                      child: Icon(
                        Icons.arrow_back,
                        color: Theme.of(context).colorScheme.onSurface,
                        size: 20,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        'RGC Decision',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 20),
                  ],
                ),
              ),
              const Divider(height: 1, color: Color(0xFFF0F2F5)),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Expanded(
                          child: _FieldBlock(
                            label: 'Submitted by',
                            value: 'Agriculture and Agro-In...',
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: _FieldBlock(
                            label: 'Status :',
                            value: '• Solved',
                            valueColor: Color(0xFF16A34A),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Expanded(
                          child: _FieldBlock(
                            label: 'Categories',
                            value: 'Procedure',
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: _FieldBlock(
                            label: 'Focal Person (H.E) :',
                            value: 'Dith Tina',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'RGC Decision',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkBackground : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isDark ? AppColors.darkBorder : const Color(0xFFE2E8F0),
                        ),
                      ),
                      child: Text(
                        '5. Entrust His Excellency Peng Ponea, Minister of Public Works and Transport to amend the relevant laws and regulations with comprehensive study of technical aspects to determine the type of vehicles and the type of roads that can be used for increasing the weight level of trucks from 40 tons to 45 tons (per truck).',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontSize: 12,
                          height: 1.5,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Link to Verification Source',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkBackground : const Color(0xFFF8FAFC),
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
            ],
          ),
        );
      },
    );
  }
}

class _FieldBlock extends StatelessWidget {
  const _FieldBlock({
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
        const SizedBox(height: 4),
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

class _MetaItem extends StatelessWidget {
  const _MetaItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: color, size: 14),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.mutedText,
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 3),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: AppColors.primaryText(context),
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}
