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
    final maximum = sorted.fold<int>(1, (max, group) {
      final count = group.solved + group.inProgress + group.notAddressed;
      return count > max ? count : max;
    });
    final visible = _expanded ? sorted : sorted.take(_previewCount).toList();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 8),
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
              label: l10n.workingGroup(
                visible[index].displayName(l10n.language),
              ),
              group: visible[index],
              maximum: maximum,
            ),
          if (sorted.length > _previewCount)
            TextButton(
              onPressed: () => setState(() => _expanded = !_expanded),
              child: Text(
                l10n.text(
                  _expanded ? 'dashboardShowLess' : 'dashboardShowMore',
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(0, 12, 0, 8),
            child: Wrap(
              alignment: WrapAlignment.center,
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
    required this.group,
    required this.maximum,
  });

  final WorkingGroupSummary group;
  final int maximum;
  final String label;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final counts = [group.solved, group.inProgress, group.notAddressed];
    final total = counts.fold<int>(0, (sum, count) => sum + count);
    const colors = [_solvedColor, _inProgressColor, _notAddressedColor];
    const statuses = ['solved', 'inProgress', 'notAddressed'];
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            flex: 5,
            child: Text(
              label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: AppColors.primaryText(context),
                fontSize: 12,
                height: 1.5,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            width: 2,
            height: 20,
            color: Theme.of(context).colorScheme.onSurface,
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 5,
            child: Semantics(
              label: label,
              value: List.generate(
                3,
                (i) => '${l10n.text(statuses[i])}: ${l10n.number(counts[i])}',
              ).join(', '),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: Container(
                  key: ValueKey('group-track-${group.id}'),
                  height: 20,
                  color: AppColors.isDark(context)
                      ? AppColors.darkElevated
                      : const Color(0xFFEBF2F7),
                  child: total == 0
                      ? null
                      : Row(
                          children: [
                            for (var i = 0; i < counts.length; i++)
                              if (counts[i] > 0)
                                Expanded(
                                  flex: counts[i],
                                  child: ColoredBox(
                                    key: ValueKey(
                                      'group-${group.id}-${statuses[i]}',
                                    ),
                                    color: colors[i],
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 4,
                                      ),
                                      child: SizedBox.expand(
                                        child: FittedBox(
                                          fit: BoxFit.scaleDown,
                                          alignment: Alignment.centerRight,
                                          child: Text(
                                            l10n.number(counts[i]),
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 11,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                            if (maximum > total) Spacer(flex: maximum - total),
                          ],
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
