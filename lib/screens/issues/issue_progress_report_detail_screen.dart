import 'package:flutter/material.dart';

import '../../core/app_colors.dart';
import '../../translations/app_localizations.dart';

class IssueProgressReportDetailScreen extends StatelessWidget {
  const IssueProgressReportDetailScreen({super.key, required this.title});

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
          'Progress Report Details',
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
      body: ListView(
        padding: const EdgeInsets.fromLTRB(10, 14, 10, 28),
        children: [
          Text(
            'Climate Issue',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 17),
          const _ReportInfoGrid(),
          const SizedBox(height: 14),
          const _KhmerDescription(),
          const SizedBox(height: 8),
          _ViewDetailsButton(
            label: AppLocalizations.of(context).text('viewDetails'),
          ),
          const SizedBox(height: 18),
          const _SectionTitle(
            title: 'Solution Indicators | សូចនាករនៃដំណោះស្រាយ',
          ),
          const SizedBox(height: 8),
          const _ReadMoreCard(
            body:
                'ត្រូវការសម្របសម្រួលរវាងក្រុមការងារនិងស្ថាប័នពាក់ព័ន្ធដើម្បីអនុវត្តសេចក្តីសម្រេចនេះឱ្យមានប្រសិទ្ធភាព។',
          ),
          const SizedBox(height: 16),
          const _SectionTitle(
            title: 'Solution Indicators | សូចនាករនៃដំណោះស្រាយ',
          ),
          const SizedBox(height: 8),
          const _ReadMoreCard(
            body:
                'ត្រូវការសម្របសម្រួលរវាងក្រុមការងារនិងស្ថាប័នពាក់ព័ន្ធដើម្បីអនុវត្តសេចក្តីសម្រេចនេះឱ្យមានប្រសិទ្ធភាព។',
          ),
          const SizedBox(height: 16),
          const _SectionTitle(title: 'Challenges | បញ្ហាប្រឈម'),
          const SizedBox(height: 8),
          const _ReadMoreCard(
            body:
                'ត្រូវការសម្របសម្រួលរវាងក្រុមការងារនិងស្ថាប័នពាក់ព័ន្ធដើម្បីអនុវត្តសេចក្តីសម្រេចនេះឱ្យមានប្រសិទ្ធភាព។',
          ),
          const SizedBox(height: 16),
          const _SectionTitle(title: 'Requests | សំណូមពរ'),
          const SizedBox(height: 8),
          const _ReadMoreCard(
            body:
                'ត្រូវការសម្របសម្រួលរវាងក្រុមការងារនិងស្ថាប័នពាក់ព័ន្ធដើម្បីអនុវត្តសេចក្តីសម្រេចនេះឱ្យមានប្រសិទ្ធភាព។',
          ),
          const SizedBox(height: 16),
          const _SectionTitle(title: 'RGC Decision'),
          const SizedBox(height: 8),
          const _ReadMoreCard(
            body:
                'ត្រូវការសម្របសម្រួលរវាងក្រុមការងារនិងស្ថាប័នពាក់ព័ន្ធដើម្បីអនុវត្តសេចក្តីសម្រេចនេះឱ្យមានប្រសិទ្ធភាព។',
          ),
        ],
      ),
    );
  }
}

class _ReportInfoGrid extends StatelessWidget {
  const _ReportInfoGrid();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Expanded(
              child: _InfoBlock(
                label: 'Implementation Date',
                value: 'Oct 23, 2025 | 2:00-3:00 PM',
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _InfoBlock(
                label: '${l10n.text('status')} :',
                value: l10n.text('solved'),
                valueColor: const Color(0xFF16A34A),
              ),
            ),
          ],
        ),
        const SizedBox(height: 13),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Expanded(
              child: _DocumentInfoBlock(label: 'Meeting Reference Document :'),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _InfoBlock(
                label: l10n.text('referenceName'),
                value: 'ឯកសាររដ្ឋ',
              ),
            ),
          ],
        ),
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
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: valueColor ?? Theme.of(context).colorScheme.onSurface,
            fontSize: 12,
            height: 1.3,
            fontWeight: FontWeight.w600,
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

class _KhmerDescription extends StatelessWidget {
  const _KhmerDescription();

  @override
  Widget build(BuildContext context) {
    return Text(
      'សូមជម្រាបជូនដល់ក្រុមការងារសូមពិនិត្យលើបញ្ហាអាកាសធាតុ។ '
      'ឯកសារនេះបង្ហាញអំពីការអនុវត្ត ស្ថានភាពដំណោះស្រាយ និងការតាមដានបន្តរបស់ស្ថាប័នពាក់ព័ន្ធ។ '
      'សូមក្រុមការងារបន្តពិនិត្យ និងផ្តល់យោបល់សម្រាប់ជំហានបន្ទាប់។\n'
      'ប្រជុំខាងមុខត្រូវបានរៀបចំដើម្បីពិនិត្យលទ្ធផល និងពិភាក្សាពីការសម្រេចរបស់រាជរដ្ឋាភិបាល។ '
      'សេចក្តីសម្រេចនឹងត្រូវបានកត់ត្រាទុកជាឯកសារយោង។',
      maxLines: 9,
      overflow: TextOverflow.fade,
      style: TextStyle(
        color: AppColors.secondaryText(context),
        fontSize: 13,
        height: 1.58,
        fontWeight: FontWeight.w500,
      ),
    );
  }
}

class _ViewDetailsButton extends StatelessWidget {
  const _ViewDetailsButton({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: TextButton.icon(
        onPressed: () {},
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          minimumSize: const Size(0, 30),
          padding: const EdgeInsets.symmetric(horizontal: 8),
        ),
        label: Text(
          label,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        ),
        iconAlignment: IconAlignment.end,
        icon: const Icon(Icons.keyboard_arrow_down, size: 17),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: TextStyle(
        color: Theme.of(context).colorScheme.onSurface,
        fontSize: 14,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

class _ReadMoreCard extends StatelessWidget {
  const _ReadMoreCard({required this.body});

  final String body;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 9),
      decoration: BoxDecoration(
        color: AppColors.cardBackground(context),
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: AppColors.border(context)),
      ),
      child: RichText(
        text: TextSpan(
          style: TextStyle(
            color: AppColors.primaryText(context),
            fontSize: 12,
            height: 1.45,
            fontWeight: FontWeight.w500,
          ),
          children: [
            TextSpan(text: body),
            const TextSpan(text: '  '),
            const TextSpan(
              text: 'Read more',
              style: TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
