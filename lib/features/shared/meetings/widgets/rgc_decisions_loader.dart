import '../../../../core/config/module_config.dart';
import '../../../../core/widgets/filters/api_filter_scope.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../../core/app_settings.dart';
import '../../../../translations/app_localizations.dart';
import '../data/rgc_decision.dart';

class RgcDecisionScorecardLoader extends StatefulWidget {
  const RgcDecisionScorecardLoader({super.key, required this.builder});

  final Widget Function(RgcDecisionScorecard) builder;

  @override
  State<RgcDecisionScorecardLoader> createState() =>
      _RgcDecisionScorecardLoaderState();
}

class _RgcDecisionScorecardLoaderState
    extends State<RgcDecisionScorecardLoader> {
  Future<RgcDecisionScorecard>? _future;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _future ??= AppSettings.of(context).rgcDecisions.getScorecard();
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<RgcDecisionScorecard>(
    future: _future,
    builder: (context, snapshot) {
      final l10n = AppLocalizations.of(context);
      if (snapshot.connectionState != ConnectionState.done) {
        return const Padding(
          padding: EdgeInsets.all(24),
          child: Center(child: CircularProgressIndicator()),
        );
      }
      if (snapshot.hasError) {
        return Column(
          children: [
            Text(l10n.text('rgcDecisionsLoadError')),
            TextButton(
              onPressed: () => setState(() {
                _future = AppSettings.of(context).rgcDecisions.getScorecard();
              }),
              child: Text(l10n.text('retry')),
            ),
          ],
        );
      }
      return widget.builder(snapshot.data!);
    },
  );
}

class RgcDecisionsLoader extends StatefulWidget {
  const RgcDecisionsLoader({super.key, required this.builder});

  final Widget Function(List<RgcDecision>) builder;

  @override
  State<RgcDecisionsLoader> createState() => _RgcDecisionsLoaderState();
}

class _RgcDecisionsLoaderState extends State<RgcDecisionsLoader> {
  Future<List<RgcDecision>>? _future;
  Map<String, String>? _query;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final query = ApiFilterScope.query(context, 'rgc-decisions');
    if (_future == null || !mapEquals(_query, query)) {
      _query = Map.of(query);
      _future = AppSettings.of(context).rgcDecisions.getDecisions(
        includePlenaryDetails: true,
        filters: query,
        cdcGpsf:
            AppSettings.of(context).moduleType == AppModuleType.cdcSecretariat,
      );
    }
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<List<RgcDecision>>(
    future: _future,
    builder: (context, snapshot) {
      final l10n = AppLocalizations.of(context);
      if (snapshot.connectionState != ConnectionState.done) {
        return const Padding(
          padding: EdgeInsets.all(24),
          child: Center(child: CircularProgressIndicator()),
        );
      }
      if (snapshot.hasError) {
        return Column(
          children: [
            Text(l10n.text('rgcDecisionsLoadError')),
            TextButton(
              onPressed: () => setState(() {
                _future = AppSettings.of(context).rgcDecisions.getDecisions(
                  includePlenaryDetails: true,
                  filters: _query ?? const {},
                  cdcGpsf:
                      AppSettings.of(context).moduleType ==
                      AppModuleType.cdcSecretariat,
                );
              }),
              child: Text(l10n.text('retry')),
            ),
          ],
        );
      }
      final selection = ApiFilterScope.selection(context, 'rgc-decisions');
      final decisions = (snapshot.data ?? const <RgcDecision>[])
          .where((decision) => selection.matchesLocal(decision.filterValues))
          .toList();
      if (decisions.isEmpty) {
        return Text(l10n.text('noRgcDecisions'));
      }
      return widget.builder(decisions);
    },
  );
}
