import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/app_colors.dart';
import '../../../screens/issues/issue_detail_screen.dart';
import '../../../translations/app_localizations.dart';

class CdcSectionMeetingScreenView extends StatefulWidget {
  const CdcSectionMeetingScreenView({super.key});

  @override
  State<CdcSectionMeetingScreenView> createState() =>
      _CdcSectionMeetingScreenViewState();
}

class _CdcSectionMeetingScreenViewState
    extends State<CdcSectionMeetingScreenView> {
  Set<String> _selectedCategories = {};
  Set<String> _selectedStatuses = {};
  Set<String> _selectedPswgs = {};
  Set<String> _selectedYears = {};
  Set<String> _selectedEscalations = {};

  Future<void> _openFilterSheet(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: false,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return _CdcIssuesFilterSheet(
          selectedCategories: _selectedCategories,
          selectedStatuses: _selectedStatuses,
          selectedPswgs: _selectedPswgs,
          selectedYears: _selectedYears,
          selectedEscalations: _selectedEscalations,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final contentBackground = isDark
        ? AppColors.darkBackground
        : const Color(0xFFF7F7F8);
    final headerBackground = isDark ? AppColors.darkBackground : Colors.white;

    final topPadding = MediaQuery.of(context).viewPadding.top;

    return ColoredBox(
      color: contentBackground,
      child: Column(
        children: [
          // STICKY HEADER
          Container(
            color: headerBackground,
            padding: EdgeInsets.fromLTRB(16, topPadding > 0 ? topPadding + 12 : 34, 16, 14),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.text('cdcIssuesMatrix'),
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                _FilterButton(
                  activeCount: 0,
                  onTap: () => _openFilterSheet(context),
                ),
              ],
            ),
          ),
          // SCROLLABLE CONTENT
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 96),
              children: [
                // METRICS GRID 2x2
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  padding: EdgeInsets.zero,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                  childAspectRatio: 2.26,
                  children: [
                    _MetricCard(
                      label: l10n.text('totalIssues'),
                      value: '56',
                      background: const Color(0xFFDDEEFF),
                      icon: Icons.library_books_outlined,
                    ),
                    _MetricCard(
                      label: l10n.text('solved'),
                      value: '30/56',
                      background: const Color(0xFFE5FAEF),
                      icon: Icons.fact_check_outlined,
                    ),
                    _MetricCard(
                      label: l10n.text('inProgress'),
                      value: '16/56',
                      background: const Color(0xFFFFF8DC),
                      icon: Icons.add_box_outlined,
                    ),
                    _MetricCard(
                      label: l10n.text('notAddressed'),
                      value: '10/56',
                      background: const Color(0xFFFFEEEE),
                      icon: Icons.assignment_late_outlined,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const _TotalPrimaryAgenciesCard(value: '14'),
                const SizedBox(height: 16),

                // CDC ISSUES CARDS LIST
                const _CdcIssueListCard(
                  title: 'Joint Inspection',
                  category: 'Procedure',
                  status: 'In Progress',
                  submissionDate: 'July 24, 2025',
                  submittedBy: 'Agriculture and Agro..',
                  description:
                      'The private sector said that the Economic Land Concession (ELCs), which invest in rubber, cashew, plantations, etc., are now fully developed and some...',
                  attachmentCount: '2 Attachement',
                ),
                const _CdcIssueListCard(
                  title: 'Law on Contract Farming & ...',
                  category: 'Legislation',
                  status: 'In Progress',
                  submissionDate: 'July 24, 2025',
                  submittedBy: 'Agriculture and Agro..',
                  description:
                      'The private sector requested the government to review and expedite the draft Law on Contract Farming to support agricultural investments...',
                  attachmentCount: '2 Attachement',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CdcIssueListCard extends StatelessWidget {
  const _CdcIssueListCard({
    required this.title,
    required this.category,
    required this.status,
    required this.submissionDate,
    required this.submittedBy,
    required this.description,
    required this.attachmentCount,
  });

  final String title;
  final String category;
  final String status;
  final String submissionDate;
  final String submittedBy;
  final String description;
  final String attachmentCount;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context);

    return InkWell(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => IssueDetailScreen(title: title, category: category),
          ),
        );
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark ? AppColors.darkBorder : const Color(0xFFF0F2F5),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [Color(0xFF216AAA), Color(0xFF1EA45B)],
                    ),
                  ),
                  child: const Icon(
                    Icons.account_balance,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        category,
                        style: const TextStyle(
                          color: Color(0xFF7C3AED),
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF423415)
                        : const Color(0xFFFFF6E8),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDark
                          ? const Color(0xFF92400E)
                          : const Color(0xFFFFC166),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: Color(0xFFF97316),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        l10n.text('inProgress'),
                        style: const TextStyle(
                          color: Color(0xFFF97316),
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _MetaInfo(
                    icon: Icons.calendar_month_outlined,
                    label: l10n.text('submissionDate'),
                    value: submissionDate,
                    iconColor: AppColors.primary,
                    iconBackground: const Color(0xFFDDEEFF),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _MetaInfo(
                    icon: Icons.person_outline,
                    label: l10n.text('submittedBy'),
                    value: submittedBy,
                    iconColor: const Color(0xFFB642FF),
                    iconBackground: const Color(0xFFF2DDFF),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              description,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: AppColors.secondaryText(context),
                fontSize: 11,
                height: 1.45,
                fontWeight: FontWeight.w400,
              ),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkCard : const Color(0xFFFAFAFA),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: isDark ? AppColors.darkBorder : const Color(0xFFE5E8ED),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.link, color: Color(0xFF4C5563), size: 14),
                  const SizedBox(width: 6),
                  Text(
                    attachmentCount == '2 Attachement'
                        ? l10n.text('twoAttachments')
                        : attachmentCount,
                    style: const TextStyle(
                      color: Color(0xFF4C5563),
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MetaInfo extends StatelessWidget {
  const _MetaInfo({
    required this.icon,
    required this.label,
    required this.value,
    required this.iconColor,
    required this.iconBackground,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color iconColor;
  final Color iconBackground;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Row(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkBorder : iconBackground,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(icon, color: iconColor, size: 15),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.mutedText,
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CdcIssuesFilterSheet extends StatefulWidget {
  const _CdcIssuesFilterSheet({
    required this.selectedCategories,
    required this.selectedStatuses,
    required this.selectedPswgs,
    required this.selectedYears,
    required this.selectedEscalations,
  });

  final Set<String> selectedCategories;
  final Set<String> selectedStatuses;
  final Set<String> selectedPswgs;
  final Set<String> selectedYears;
  final Set<String> selectedEscalations;

  @override
  State<_CdcIssuesFilterSheet> createState() => _CdcIssuesFilterSheetState();
}

class _CdcIssuesFilterSheetState extends State<_CdcIssuesFilterSheet> {
  late Set<String> _categories;
  late Set<String> _statuses;
  late Set<String> _pswgs;
  late Set<String> _years;
  late Set<String> _escalations;

  bool _isCategoriesExpanded = false;

  static const _defaultCategories = [
    'Agriculture and Agro-Industry',
    'Tourism',
    'SMEs, Manufacturing, and Services',
    'Law, Tax, and Governance',
    'Banking and Financial Services',
  ];

  static const _extraCategories = [
    'Industrial Relations',
    'Energy and Mineral Resources',
    'Construction and Real Estate',
    'Export Processing and Trade Facilitation',
    'Rice and Paddy',
  ];

  static const _statusRow1 = ['Drafted', 'New Submission', 'In Progress'];
  static const _statusRow2 = ['Solved', 'Not Addressed'];
  static const _pswgItems = ['CRF', 'ABC', 'GDCE', 'IBC', 'CTF'];
  static const _yearItems = ['2026', '2025', '2024', '2023'];
  static const _escalationItems = ['Yes', 'No'];

  @override
  void initState() {
    super.initState();
    _categories = {...widget.selectedCategories};
    _statuses = {...widget.selectedStatuses};
    _pswgs = {...widget.selectedPswgs};
    _years = {...widget.selectedYears};
    _escalations = {...widget.selectedEscalations};
  }

  void _toggle(Set<String> set, String value) {
    setState(() {
      if (set.contains(value)) {
        set.remove(value);
      } else {
        set.add(value);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final background = isDark ? AppColors.darkBackground : Colors.white;

    final viewPadding = MediaQuery.of(context).viewPadding;
    final topInset = viewPadding.top > 48.0 ? viewPadding.top : 48.0;
    final bottomInset = viewPadding.bottom;

    final displayedCategories = _isCategoriesExpanded
        ? [..._defaultCategories, ..._extraCategories]
        : _defaultCategories;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
      ),
      child: FractionallySizedBox(
        heightFactor: 1.0,
        child: Container(
          color: background,
          child: Column(
            children: [
              // HEADER
              Container(
                padding: EdgeInsets.fromLTRB(22, topInset + 24, 22, 12),
                child: Row(
                  children: [
                    const SizedBox(width: 28),
                    Expanded(
                      child: Text(
                        l10n.text('filters'),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    InkWell(
                      onTap: () => Navigator.pop(context),
                      child: const Icon(Icons.close, size: 25),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 25,
                    vertical: 20,
                  ),
                  children: [
                    // SECTION 1: CATEGORY
                    Text(
                      l10n.text('category'),
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Column(
                      children: displayedCategories.map((item) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: InkWell(
                            onTap: () => _toggle(_categories, item),
                            child: Row(
                              children: [
                                AnimatedContainer(
                                  duration: const Duration(milliseconds: 140),
                                  width: 16,
                                  height: 16,
                                  decoration: BoxDecoration(
                                    color: _categories.contains(item)
                                        ? AppColors.accent(context)
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(
                                      color: _categories.contains(item)
                                          ? AppColors.accent(context)
                                          : (isDark
                                              ? AppColors.darkBorder
                                              : const Color(0xFFCED7E1)),
                                      width: 1,
                                    ),
                                  ),
                                  child: _categories.contains(item)
                                      ? const Icon(
                                          Icons.check,
                                          size: 11,
                                          color: Colors.white,
                                        )
                                      : null,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    item,
                                    style: TextStyle(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurface,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w400,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 4),
                    Center(
                      child: InkWell(
                        onTap: () {
                          setState(() {
                            _isCategoriesExpanded = !_isCategoriesExpanded;
                          });
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _isCategoriesExpanded
                                    ? l10n.text('viewLess')
                                    : l10n.text('viewAll'),
                                style: const TextStyle(
                                  color: AppColors.primary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Icon(
                                _isCategoriesExpanded
                                    ? Icons.keyboard_arrow_up
                                    : Icons.keyboard_arrow_down,
                                color: AppColors.primary,
                                size: 16,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // SECTION 2: STATUS
                    Text(
                      l10n.text('status'),
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 16,
                      runSpacing: 10,
                      children: _statusRow1.map((item) {
                        return _InlineCheckbox(
                          label: item,
                          checked: _statuses.contains(item),
                          onTap: () => _toggle(_statuses, item),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 16,
                      runSpacing: 10,
                      children: _statusRow2.map((item) {
                        return _InlineCheckbox(
                          label: item,
                          checked: _statuses.contains(item),
                          onTap: () => _toggle(_statuses, item),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 24),

                    // SECTION 3: ALL PSWGS
                    const Text(
                      'All PSWGS',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 18,
                      runSpacing: 10,
                      children: _pswgItems.map((item) {
                        return _InlineCheckbox(
                          label: item,
                          checked: _pswgs.contains(item),
                          onTap: () => _toggle(_pswgs, item),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 24),

                    // SECTION 4: YEAR
                    Text(
                      l10n.text('year'),
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 20,
                      runSpacing: 10,
                      children: _yearItems.map((item) {
                        return _InlineCheckbox(
                          label: item,
                          checked: _years.contains(item),
                          onTap: () => _toggle(_years, item),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 24),

                    // SECTION 5: PLENARY ESCALATION
                    Text(
                      l10n.text('plenaryEscalation'),
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 20,
                      runSpacing: 10,
                      children: _escalationItems.map((item) {
                        return _InlineCheckbox(
                          label: item,
                          checked: _escalations.contains(item),
                          onTap: () => _toggle(_escalations, item),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.fromLTRB(
                  16,
                  13,
                  16,
                  bottomInset > 0 ? bottomInset + 10 : 12,
                ),
                child: SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accent(context),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      l10n.text('applyFilters'),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InlineCheckbox extends StatelessWidget {
  const _InlineCheckbox({
    required this.label,
    required this.checked,
    required this.onTap,
  });

  final String label;
  final bool checked;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context);

    String translatedLabel = label;
    if (label == 'Drafted') translatedLabel = l10n.text('drafted');
    if (label == 'New Submission') translatedLabel = l10n.text('newSubmission');
    if (label == 'In Progress') translatedLabel = l10n.text('inProgress');
    if (label == 'Solved') translatedLabel = l10n.text('solved');
    if (label == 'Not Addressed') translatedLabel = l10n.text('notAddressed');

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 140),
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                color: checked ? AppColors.accent(context) : Colors.transparent,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: checked
                      ? AppColors.accent(context)
                      : (isDark
                          ? AppColors.darkBorder
                          : const Color(0xFFCED7E1)),
                  width: 1,
                ),
              ),
              child: checked
                  ? const Icon(
                      Icons.check,
                      size: 11,
                      color: Colors.white,
                    )
                  : null,
            ),
            const SizedBox(width: 8),
            Text(
              translatedLabel,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontSize: 12,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterButton extends StatelessWidget {
  const _FilterButton({
    required this.activeCount,
    required this.onTap,
  });

  final int activeCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(7),
      child: Container(
        height: 34,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : Colors.white,
          borderRadius: BorderRadius.circular(7),
          border: Border.all(
            color: isDark ? AppColors.darkBorder : const Color(0xFFE3E7EC),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              AppLocalizations.of(context).text('filter'),
              style: const TextStyle(
                color: AppColors.mutedText,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 6),
            Icon(
              Icons.filter_list,
              color: Theme.of(context).colorScheme.onSurface,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.label,
    required this.value,
    required this.background,
    required this.icon,
  });

  final String label;
  final String value;
  final Color background;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.fromLTRB(11, 10, 10, 9),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : background,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : Colors.transparent,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: isDark
                        ? AppColors.secondaryText(context)
                        : AppColors.mutedText,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 7),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    value,
                    style: TextStyle(
                      color: isDark ? Colors.white : const Color(0xFF27364A),
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.darkBorder
                  : Colors.white.withValues(alpha: 0.86),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: isDark ? const Color(0xFFE3E8EF) : const Color(0xFF4C5563),
              size: 21,
            ),
          ),
        ],
      ),
    );
  }
}

class _TotalPrimaryAgenciesCard extends StatelessWidget {
  const _TotalPrimaryAgenciesCard({required this.value});

  final String value;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : const Color(0xFFE5E8ED),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppLocalizations.of(context).text('totalPrimaryAgencies'),
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
                  color: Theme.of(context).colorScheme.onSurface,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkBorder : const Color(0xFFFAFAFA),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isDark ? AppColors.darkBorder : const Color(0xFFE5E8ED),
              ),
            ),
            child: const Icon(
              Icons.calendar_month_outlined,
              color: Color(0xFF4C5563),
              size: 20,
            ),
          ),
        ],
      ),
    );
  }
}
