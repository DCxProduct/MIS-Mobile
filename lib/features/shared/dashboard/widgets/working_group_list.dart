import 'package:flutter/material.dart';

import '../../../../core/app_colors.dart';
import '../../../../translations/app_localizations.dart';
import '../data/working_group_summary.dart';
import '../data/working_group_order.dart';

const _solvedColor = Color(0xFF0DA365);
const _inProgressColor = Color(0xFFF5B324);
const _notAddressedColor = Color(0xFFFF3B40);

class WorkingGroupList extends StatefulWidget {
  const WorkingGroupList({super.key, required this.groups});

  final List<WorkingGroupSummary> groups;

  @override
  State<WorkingGroupList> createState() => _WorkingGroupListState();
}

class _WorkingGroupListState extends State<WorkingGroupList> {
  static const _previewCount = 8;
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final sorted = sortWorkingGroupsByKhmerCode(widget.groups);
    final visible = _expanded ? sorted : sorted.take(_previewCount).toList();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 10, 0, 8),
      decoration: BoxDecoration(
        color: AppColors.cardBackground(context),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border(context)),
      ),
      child: Column(
        children: [
          if (visible.isEmpty) Text(l10n.text('noWorkingGroups')),
          for (var index = 0; index < visible.length; index++)
            _WorkingGroupRow(
              key: ValueKey('working-group-${visible[index].id}'),
              label: visible[index].displayName(l10n.language),
              group: visible[index],
              showDivider: index != visible.length - 1,
            ),
          if (sorted.length > _previewCount)
            TextButton(
              onPressed: () => setState(() => _expanded = !_expanded),
              child: Text(l10n.text(_expanded ? 'viewLess' : 'viewAll')),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(0, 12, 16, 8),
            child: Wrap(
              spacing: 16,
              runSpacing: 10,
              children: [
                for (final status in const [
                  ('solved', _solvedColor),
                  ('inProgress', _inProgressColor),
                  ('notAddressed', _notAddressedColor),
                ])
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: status.$2,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        l10n.text(status.$1),
                        style: TextStyle(
                          fontSize: 11,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _WorkingGroupRow extends StatelessWidget {
  const _WorkingGroupRow({
    super.key,
    required this.label,
    required this.showDivider,
    required this.group,
  });

  final WorkingGroupSummary group;
  final String label;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.fromLTRB(0, 10, 0, 12),
      decoration: BoxDecoration(
        border: showDivider
            ? Border(
                bottom: BorderSide(
                  color: colors.outlineVariant.withValues(alpha: 0.9),
                ),
              )
            : null,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: colors.onSurface,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 8),
          _MiniStatusBars(group: group),
          const SizedBox(width: 12),
        ],
      ),
    );
  }
}

class _MiniStatusBars extends StatelessWidget {
  const _MiniStatusBars({required this.group});

  final WorkingGroupSummary group;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 22,
      height: 18,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          _MiniBar(
            color: _inProgressColor,
            height: group.total == 0 ? 0 : 18 * group.inProgress / group.total,
          ),
          const SizedBox(width: 4),
          _MiniBar(
            color: _notAddressedColor,
            height: group.total == 0
                ? 0
                : 18 * group.notAddressed / group.total,
          ),
          const SizedBox(width: 4),
          _MiniBar(
            color: _solvedColor,
            height: group.total == 0 ? 0 : 18 * group.solved / group.total,
          ),
        ],
      ),
    );
  }
}

class _MiniBar extends StatelessWidget {
  const _MiniBar({required this.color, required this.height});

  final Color color;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 4,
      height: height,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(3),
      ),
    );
  }
}
