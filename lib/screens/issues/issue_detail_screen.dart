import 'package:flutter/material.dart';

import '../../core/app_colors.dart';
import '../../translations/app_localizations.dart';
import 'tabs/issue_descriptions_tab.dart';
import 'tabs/issue_progress_report_tab.dart';

class IssueDetailScreen extends StatefulWidget {
  const IssueDetailScreen({
    super.key,
    required this.title,
    required this.category,
  });

  final String title;
  final String category;

  @override
  State<IssueDetailScreen> createState() => _IssueDetailScreenState();
}

class _IssueDetailScreenState extends State<IssueDetailScreen> {
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
          'Issue Details',
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
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'សំណើប្រជុំពិភាក្សាដោះស្រាយបញ្ហាចំនួន ៣ ដែលបានដាក់ជូនក្រសួងខាងក្រោម ។',
                    style: TextStyle(
                      color: AppColors.primaryText(context),
                      fontSize: 15,
                      height: 1.35,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _IssueInfoGrid(category: widget.category),
                  const SizedBox(height: 14),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: const [
                        _DatePill(
                          label: 'Submitted Date',
                          value: 'July 24, 2025',
                        ),
                        SizedBox(width: 10),
                        _DatePill(
                          label: 'Meeting Date',
                          value: 'June 29, 2025 2:00PM5:00PM',
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            _IssueDetailTabs(
              selectedIndex: _selectedTab,
              onSelected: (index) => setState(() => _selectedTab = index),
            ),
            Expanded(
              child: _selectedTab == 0
                  ? const IssueDescriptionsTab()
                  : const IssueProgressReportTab(),
            ),
          ],
        ),
      ),
    );
  }
}

class _IssueInfoGrid extends StatelessWidget {
  const _IssueInfoGrid({required this.category});

  final String category;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Expanded(
              child: _InfoBlock(
                label: 'Government Agency :',
                value: 'MAFF',
                leading: _AgencyLogo(),
              ),
            ),
            SizedBox(width: 20),
            Expanded(
              child: _InfoBlock(
                label: 'Status :',
                value: 'In Progress',
                valueColor: Color(0xFFFF8A00),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _InfoBlock(label: 'Category', value: category),
            ),
            const SizedBox(width: 20),
            const Expanded(
              child: _DocumentBlock(
                label: 'Meeting Request Document:',
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _InfoBlock extends StatelessWidget {
  const _InfoBlock({
    required this.label,
    required this.value,
    this.valueColor,
    this.leading,
  });

  final String label;
  final String value;
  final Color? valueColor;
  final Widget? leading;

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
        const SizedBox(height: 6),
        Row(
          children: [
            if (leading != null) ...[leading!, const SizedBox(width: 6)],
            Expanded(
              child: Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: valueColor ?? AppColors.primaryText(context),
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _AgencyLogo extends StatelessWidget {
  const _AgencyLogo();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 14,
      height: 14,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1E73BE), Color(0xFF1EA45B)],
        ),
      ),
      child: const Icon(Icons.account_balance, color: Colors.white, size: 9),
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
        const SizedBox(height: 6),
        Row(
          children: [
            const Icon(Icons.picture_as_pdf, color: Color(0xFFE53935), size: 18),
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
        style: const TextStyle(fontSize: 11),
      ),
    );
  }
}

class _IssueDetailTabs extends StatelessWidget {
  const _IssueDetailTabs({
    required this.selectedIndex,
    required this.onSelected,
  });

  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final labels = ['Descriptions', 'Progress Report'];

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
