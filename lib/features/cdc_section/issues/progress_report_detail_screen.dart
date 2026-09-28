import 'package:flutter/material.dart';

import '../../../core/app_colors.dart';
import '../../../translations/app_localizations.dart';
import 'detail_widgets.dart';

class CdcIssueProgressReportDetailScreen extends StatefulWidget {
  const CdcIssueProgressReportDetailScreen({super.key});

  @override
  State<CdcIssueProgressReportDetailScreen> createState() => _CdcIssueProgressReportDetailScreenState();
}

class _CdcIssueProgressReportDetailScreenState extends State<CdcIssueProgressReportDetailScreen> {
  bool _expanded = false;
  static const _description =
      'ខ្ញុំសូមស្នើសុំរៀបចំកិច្ចប្រជុំពិសេសមួយ ដើម្បីដោះស្រាយបញ្ហាប្រឈមចំពោះបញ្ហាបច្ចុប្បន្នចំនួន ៤ ដែលគម្រោងមានឥទ្ធិពលលើការងាររបស់យើង។ គោលបំណងនៃកិច្ចប្រជុំនេះគឺដើម្បីប្រមូលអ្នកពាក់ព័ន្ធទាំងអស់ រួមទាំងសមាជិកក្រុម និងអ្នកធ្វើសេចក្តីសម្រេចនៅក្នុងបរិបទសហការ ដែលអាចពិភាក្សាបញ្ហាទាំងអស់ បញ្ហាឬស្គាល់ហេតុដើម ស្វែងរកដំណោះស្រាយសក្តិសម និងកំណត់ផែនការអនុវត្តជាក់លាក់។ របៀបវារៈនឹងត្រូវរៀបចំជាផ្នែក ៤ ដោយផ្នែកនីមួយៗផ្តោតលើបញ្ហាប្រឈមមួយៗ។ ក្នុងផ្នែកនីមួយៗ យើងនឹង៖\n'
      '១. បង្ហាញសេចក្តីលម្អិតអំពីបញ្ហាប្រឈម ឬទិន្នន័យ ឬឧទាហរណ៍ដែលបង្ហាញពីបញ្ហា។\n'
      '២. វិភាគមូលហេតុ និងកត្តាដែលបង្ក។\n'
      '៣. ពិភាក្សាអំពីដំណោះស្រាយសក្តិសម ពិនិត្យលទ្ធភាព ហានិភ័យ និងអត្ថប្រយោជន៍។\n'
      '៤. សម្រេចយុទ្ធសាស្ត្រជាក់លាក់ ដោយកំណត់អ្នកទទួលខុសត្រូវ និងពេលវេលាអនុវត្ត។';
  static const _sectionBody =
      'ផ្នែកឯកជនស្នើស្រាវជ្រាវសម្រួលក្នុងឆន្ទានុសិទ្ធិរបស់ក្រសួងកសិកម្មរុក្ខាប្រមាញ់ និងនេសាទដើម្បីផ្តល់ព័ត៌មានស្តីពីសេរីភាពនៃការវិនិយោគ និងការសម្របសម្រួលការនាំចេញបន្ថែមវិញ។';

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final background = AppColors.pageBackground(context);
    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        backgroundColor: background,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        centerTitle: true,
        leading: IconButton(tooltip: MaterialLocalizations.of(context).backButtonTooltip, onPressed: () => Navigator.pop(context), icon: const Icon(Icons.arrow_back, size: 22)),
        title: Text(l10n.text('issueDetails'), style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
        bottom: PreferredSize(preferredSize: const Size.fromHeight(1), child: Divider(height: 1, color: AppColors.border(context))),
      ),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          key: const ValueKey('cdc-progress-report-scroll'),
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Climate Issue', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
              const SizedBox(height: 16),
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Expanded(flex: 3, child: CdcDetailInfoValue(label: l10n.text('implementationDate'), value: 'June 29, 2025 | 2:00-3:00 PM')),
                const SizedBox(width: 16),
                Expanded(flex: 2, child: CdcDetailInfoValue(label: '${l10n.text('status')} :', value: l10n.text('complete'), color: AppColors.accent(context))),
              ]),
              const SizedBox(height: 16),
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Expanded(flex: 3, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('${l10n.text('meetingReferenceDocument')} :', style: const TextStyle(fontSize: 12, color: AppColors.mutedText)),
                  const SizedBox(height: 8),
                  const Row(children: [
                    Icon(Icons.picture_as_pdf, size: 18, color: Color(0xFFFF4842)),
                    SizedBox(width: 8),
                    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Request Doc', style: TextStyle(fontSize: 12)), Text('200 KB', style: TextStyle(fontSize: 7, color: AppColors.mutedText))]),
                  ]),
                ])),
                const SizedBox(width: 16),
                Expanded(flex: 2, child: CdcDetailInfoValue(label: l10n.text('referenceName'), value: 'របាយការណ៍')),
              ]),
              const SizedBox(height: 20),
              AnimatedSize(
                duration: const Duration(milliseconds: 200),
                alignment: Alignment.topCenter,
                child: Stack(children: [
                  Text(_description, key: const ValueKey('cdc-report-description'), maxLines: _expanded ? null : 13, overflow: TextOverflow.clip, style: TextStyle(fontSize: 13, height: 1.5, color: AppColors.primaryText(context))),
                  if (!_expanded) Positioned(left: 0, right: 0, bottom: 0, height: 90, child: IgnorePointer(child: DecoratedBox(decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [background.withValues(alpha: 0), background]))))),
                ]),
              ),
              Center(child: TextButton.icon(
                key: const ValueKey('cdc-report-expand'),
                onPressed: () => setState(() => _expanded = !_expanded),
                style: TextButton.styleFrom(foregroundColor: AppColors.accent(context), padding: EdgeInsets.zero, minimumSize: const Size(0, 28), tapTargetSize: MaterialTapTargetSize.shrinkWrap, textStyle: const TextStyle(fontSize: 12)),
                label: Text(l10n.text(_expanded ? 'showLess' : 'viewDetails')),
                iconAlignment: IconAlignment.end,
                icon: Icon(_expanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down, size: 18),
              )),
              const SizedBox(height: 16),
              for (final label in ['Solution Indicators | សូចនាករដំណោះស្រាយ', 'Challenges | បញ្ហាប្រឈម', 'Requests | សំណូមពរ', l10n.text('rgcDecision')]) ...[
                CdcDetailTextPanel(label: label, body: _sectionBody, collapsedLines: 3, inlineLink: true),
                const SizedBox(height: 16),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
