import 'package:flutter/material.dart';
import '../../../shared/dashboard/widgets/working_group_live_tab.dart';
import '../../../shared/dashboard/widgets/working_group_list.dart';
import '../../../shared/dashboard/widgets/pswg_live_dashboard.dart';
import '../../../shared/dashboard/data/working_group_summary.dart';

class WorkingGroupTab extends StatelessWidget {
  const WorkingGroupTab({super.key, this.groups});

  final List<WorkingGroupSummary>? groups;

  @override
  Widget build(BuildContext context) {
    final data = groups ?? PswgDataScope.maybeOf(context)?.workingGroups;
    if (data == null) {
      return WorkingGroupLiveTab(
        builder: (groups) => WorkingGroupList(groups: groups),
      );
    }
    return WorkingGroupList(groups: data);
  }
}
