import 'package:flutter/material.dart';

import '../../../core/app_colors.dart';
import '../../../translations/app_localizations.dart';

/// A separate draft is edited until the user applies the filters.
class CdcDashboardFilters {
  CdcDashboardFilters([Map<String, Set<String>>? values])
    : values = {
        for (final entry in (values ?? <String, Set<String>>{}).entries)
          entry.key: {...entry.value},
      };

  final Map<String, Set<String>> values;
  int get count =>
      values.values.fold(0, (count, items) => count + items.length);
}

class CdcDashboardFilterSheet extends StatefulWidget {
  const CdcDashboardFilterSheet({
    super.key,
    required this.initial,
    this.groups,
  });

  final CdcDashboardFilters initial;
  final Map<String, List<String>>? groups;

  @override
  State<CdcDashboardFilterSheet> createState() =>
      _CdcDashboardFilterSheetState();
}

class _CdcDashboardFilterSheetState extends State<CdcDashboardFilterSheet> {
  late final CdcDashboardFilters _draft = CdcDashboardFilters(
    widget.initial.values,
  );
  final Set<String> _expanded = {};

  static const _groups = <String, List<String>>{
    'status': ['Solved', 'In Progress', 'Not Addressed'],
    'primaryAgency': [
      'GDT',
      'MFF',
      'GDCE',
      'MLVT',
      'MPTC',
      'MAFF',
      'MoH',
      'NBC',
      'MoC',
      'MoT',
      'MLMUPC',
      'MoI',
      'CDC',
      'MPWT',
      'MISTI',
      'MME',
      'SHV Admin',
      'MOC',
    ],
    'workingGroup': [
      'Agriculture and Agro-Industry',
      'Tourism',
      'SMEs, Manufacturing and Services',
      'Law, Tax, and Governance',
      'Banking and Financial Services',
      'Transportation and Infrastructure',
      'Export Processing and Trade Facilitation',
      'Industrial Relations',
      'Rice and Paddy',
      'Energy and Mineral Resources',
      'Education',
      'Construction and Real Estate',
      'Non-Bank Financial Services Other issues',
      'Digital Economy, Society and Telecommunication',
      'Land Administration, Security, Public Order',
    ],
    'categories': [
      'Governance',
      'Human Resource',
      'Legislation',
      'Procedure',
      'Taxation',
      'Strategy',
      'Trade',
      'Policy',
      'Market',
    ],
    'year': ['2026', '2025', '2024', '2023'],
    'progressReport': ['Both', 'S1', 'S2'],
  };

  Map<String, List<String>> get _visibleGroups => widget.groups ?? _groups;

  void _toggle(String group, String value) {
    setState(() {
      final selected = _draft.values.putIfAbsent(group, () => <String>{});
      if (!selected.remove(value)) {
        // Both includes S1 and S2, so it is exclusive with either semester.
        if (group == 'progressReport') {
          if (value == 'Both') {
            selected.clear();
          } else {
            selected.remove('Both');
          }
        }
        selected.add(value);
      }
    });
  }

  String _label(String value) {
    final l10n = AppLocalizations.of(context);
    return switch (value) {
      'Solved' => l10n.text('solved'),
      'In Progress' => l10n.text('inProgress'),
      'Not Addressed' => l10n.text('notAddressed'),
      'Both' => l10n.text('both'),
      'Sent' => l10n.text('sent'),
      'Draft' => l10n.text('draft'),
      _ => value,
    };
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final background = isDark ? AppColors.darkBackground : Colors.white;
    final border = isDark ? AppColors.darkBorder : const Color(0xFFF0F1F4);
    return FractionallySizedBox(
      heightFactor: 1,
      child: Material(
        color: background,
        child: SafeArea(
          top: true,
          child: Column(
            children: [
              SizedBox(
                width: double.infinity,
                height: 58,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Text(
                      l10n.text('filters'),
                      style: TextStyle(
                        color: isDark
                            ? AppColors.primaryText(context)
                            : const Color(0xFF181B20),
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Positioned(
                      right: 6,
                      child: IconButton(
                        tooltip: MaterialLocalizations.of(
                          context,
                        ).closeButtonTooltip,
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close_rounded, size: 23),
                      ),
                    ),
                  ],
                ),
              ),
              Divider(height: 1, color: border),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                  itemCount: _visibleGroups.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 18),
                  itemBuilder: (context, index) =>
                      _section(_visibleGroups.keys.elementAt(index)),
                ),
              ),
              Container(
                padding: const EdgeInsets.fromLTRB(16, 18, 16, 14),
                decoration: BoxDecoration(
                  color: background,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: .04),
                      blurRadius: 6,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF2167AA),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () => Navigator.pop(context, _draft),
                    child: Text(
                      l10n.text('applyFilters'),
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
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

  Widget _section(String group) {
    final l10n = AppLocalizations.of(context);
    final items = _visibleGroups[group]!;
    final limit = switch (group) {
      'primaryAgency' => 10,
      'workingGroup' => 5,
      'categories' => 4,
      _ => items.length,
    };
    final expanded = _expanded.contains(group);
    final visible = (expanded ? items : items.take(limit)).toList();
    final columns = switch (group) {
      'workingGroup' => 1,
      'categories' => 2,
      'year' || 'progressReport' => 4,
      'primaryAgency' => 5,
      _ => 3,
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.text(group == 'categories' ? 'filterCategory' : group),
          style: TextStyle(
            color: Theme.of(context).brightness == Brightness.dark
                ? AppColors.primaryText(context)
                : const Color(0xFF141519),
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        LayoutBuilder(
          builder: (context, constraints) {
            return Wrap(
              children: [
                for (final item in visible)
                  SizedBox(
                    width: constraints.maxWidth / columns,
                    child: _option(group, item),
                  ),
              ],
            );
          },
        ),
        if (items.length > limit)
          Center(
            child: TextButton(
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).brightness == Brightness.dark
                    ? AppColors.accent(context)
                    : const Color(0xFF397FBE),
                minimumSize: const Size(80, 36),
              ),
              onPressed: () => setState(() {
                if (!_expanded.remove(group)) {
                  _expanded.add(group);
                }
              }),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    l10n.text(expanded ? 'viewLess' : 'viewAll'),
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  const SizedBox(width: 7),
                  Icon(
                    expanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    size: 17,
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _option(String group, String item) {
    final selected = _draft.values[group]?.contains(item) ?? false;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Semantics(
      label: _label(item),
      checked: selected,
      child: InkWell(
        key: ValueKey('filter-$group-$item'),
        onTap: () => _toggle(group, item),
        borderRadius: BorderRadius.circular(4),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 36),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 7),
            child: Row(
              children: [
                Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    color: selected
                        ? const Color(0xFF2167AA)
                        : Colors.transparent,
                    border: Border.all(
                      color: selected
                          ? const Color(0xFF2167AA)
                          : isDark
                          ? AppColors.darkBorder
                          : AppColors.filterOutline,
                    ),
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: selected
                      ? const Icon(Icons.check, size: 12, color: Colors.white)
                      : null,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _label(item),
                    style: TextStyle(
                      color: isDark
                          ? AppColors.secondaryText(context)
                          : const Color(0xFF1D1D1E),
                      fontSize: 13,
                      height: 1.3,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
