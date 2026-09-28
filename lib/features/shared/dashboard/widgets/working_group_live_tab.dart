import 'package:flutter/material.dart';
import '../../../../core/app_settings.dart';
import '../../../../translations/app_localizations.dart';
import '../data/working_group_summary.dart';

class WorkingGroupLiveTab extends StatefulWidget {
  const WorkingGroupLiveTab({super.key, required this.builder});

  final Widget Function(List<WorkingGroupSummary>) builder;

  @override
  State<WorkingGroupLiveTab> createState() => _WorkingGroupLiveTabState();
}

class _WorkingGroupLiveTabState extends State<WorkingGroupLiveTab> {
  Future<List<WorkingGroupSummary>>? _request;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _request ??= AppSettings.of(context).dashboard.getWorkingGroups();
  }

  @override
  Widget build(BuildContext context) =>
      FutureBuilder<List<WorkingGroupSummary>>(
        future: _request,
        builder: (context, snapshot) {
          final l10n = AppLocalizations.of(context);
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Column(
              children: [
                Text(l10n.text('workingGroupsLoadError')),
                TextButton(
                  onPressed: () => setState(() {
                    _request = AppSettings.of(
                      context,
                    ).dashboard.getWorkingGroups();
                  }),
                  child: Text(l10n.text('retry')),
                ),
              ],
            );
          }
          if (snapshot.data!.isEmpty) return Text(l10n.text('noWorkingGroups'));
          return widget.builder(snapshot.data!);
        },
      );
}
