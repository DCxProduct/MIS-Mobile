import 'package:flutter/material.dart';

import '../../app_colors.dart';
import '../../../translations/app_localizations.dart';
import 'filter_models.dart';
import 'filter_sheet_header.dart';

export 'filter_models.dart';

/// Shared filter UI. Each screen supplies its own sections and selection rules.
class AppFilterSheet extends StatefulWidget {
  const AppFilterSheet({
    super.key,
    required this.initial,
    required this.sections,
    this.compact = false,
    this.onApply,
    this.onClose,
  });

  final FilterSelection initial;
  final List<FilterSection> sections;
  final bool compact;
  final ValueChanged<FilterSelection>? onApply;
  final VoidCallback? onClose;

  @override
  State<AppFilterSheet> createState() => _AppFilterSheetState();
}

class _AppFilterSheetState extends State<AppFilterSheet> {
  late final FilterSelection _draft = FilterSelection(widget.initial.values);
  final Set<String> _expanded = {};

  void _clearAndClose() {
    setState(() {
      _draft.values.clear();
      _expanded.clear();
    });
    final cleared = FilterSelection();
    widget.onApply?.call(cleared);
    if (widget.onClose != null) {
      widget.onClose!();
    } else if (widget.onApply == null) {
      Navigator.pop(context, cleared);
    }
  }

  void _toggle(FilterSection section, String value) {
    setState(() {
      final selected = _draft.values.putIfAbsent(section.id, () => <String>{});
      if (!selected.remove(value)) {
        if (section.singleSelection ||
            section.exclusiveValues.contains(value)) {
          selected.clear();
        } else {
          selected.removeAll(section.exclusiveValues);
        }
        selected.add(value);
        if (widget.sections.any((item) => item.id == 'progressReportId')) {
          if (section.id == 'local.year') {
            _draft.values.remove('progressReportId');
          }
          if (section.id == 'progressReportId') {
            for (final option in section.options) {
              if (option.value == value && option.year != null) {
                _draft.values['local.year'] = {option.year!};
                break;
              }
            }
          }
        }
      }
    });
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
              FilterSheetHeader(
                title: l10n.text('filters'),
                onClose: _clearAndClose,
                titleStyle: TextStyle(
                  color: isDark
                      ? AppColors.primaryText(context)
                      : const Color(0xFF181B20),
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Divider(height: 1, color: border),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 18, 16, 12),
                  itemCount: widget.sections.length,
                  separatorBuilder: (_, _) =>
                      SizedBox(height: widget.compact ? 14 : 18),
                  itemBuilder: (context, index) =>
                      _section(widget.sections[index]),
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
                  height: widget.compact ? 46 : 50,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF2167AA),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () {
                      final result = FilterSelection(_draft.values);
                      if (widget.onApply != null) {
                        widget.onApply!(result);
                      } else {
                        Navigator.pop(context, result);
                      }
                    },
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

  Widget _section(FilterSection section) {
    final l10n = AppLocalizations.of(context);
    final selectedYear = _draft['local.year'].firstOrNull;
    final items =
        section.id == 'progressReportId' &&
            selectedYear != null &&
            section.options.every((option) => option.year != null)
        ? section.options
              .where((option) => option.year == selectedYear)
              .toList()
        : section.options;
    final limit = section.collapsedItemCount ?? items.length;
    final expanded = _expanded.contains(section.id);
    final visible = (expanded ? items : items.take(limit)).toList();
    final columns = section.columns;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          section.title,
          style: TextStyle(
            color: Theme.of(context).brightness == Brightness.dark
                ? AppColors.primaryText(context)
                : const Color(0xFF141519),
            fontSize: widget.compact ? 13 : 14,
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
                    child: _option(section, item),
                  ),
              ],
            );
          },
        ),
        if (items.length > limit)
          Center(
            child: TextButton(
              key: ValueKey('filter-expand-${section.id}'),
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).brightness == Brightness.dark
                    ? AppColors.accent(context)
                    : const Color(0xFF397FBE),
                minimumSize: const Size(80, 36),
              ),
              onPressed: () => setState(() {
                if (!_expanded.remove(section.id)) {
                  _expanded.add(section.id);
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

  Widget _option(FilterSection section, FilterOption item) {
    final selected = _draft.values[section.id]?.contains(item.value) ?? false;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Semantics(
      label: item.label,
      checked: selected,
      enabled: item.enabled,
      onTap: item.enabled ? () => _toggle(section, item.value) : null,
      child: ExcludeSemantics(
        child: InkWell(
          key: ValueKey('filter-${section.id}-${item.value}'),
          onTap: item.enabled ? () => _toggle(section, item.value) : null,
          borderRadius: BorderRadius.circular(4),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 36),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 7),
              child: Row(
                children: [
                  Container(
                    width: widget.compact ? 15 : 16,
                    height: widget.compact ? 15 : 16,
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
                  SizedBox(width: widget.compact ? 8 : 10),
                  Expanded(
                    child: Text(
                      item.label,
                      maxLines: section.id == 'local.pswgs' ? 1 : null,
                      overflow: section.id == 'local.pswgs'
                          ? TextOverflow.ellipsis
                          : null,
                      style: TextStyle(
                        color: !item.enabled
                            ? Theme.of(context).disabledColor
                            : isDark
                            ? AppColors.secondaryText(context)
                            : const Color(0xFF707887),
                        fontSize: 12,
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
      ),
    );
  }
}
