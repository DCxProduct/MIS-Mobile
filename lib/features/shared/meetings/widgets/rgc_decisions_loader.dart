import 'package:flutter/material.dart';

import '../../../../core/app_settings.dart';
import '../../../../translations/app_localizations.dart';
import '../data/rgc_decision.dart';

class RgcDecisionsLoader extends StatefulWidget {
  const RgcDecisionsLoader({super.key, required this.builder});

  final Widget Function(List<RgcDecision>) builder;

  @override
  State<RgcDecisionsLoader> createState() => _RgcDecisionsLoaderState();
}

class _RgcDecisionsLoaderState extends State<RgcDecisionsLoader> {
  Future<List<RgcDecision>>? _future;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _future ??= AppSettings.of(context).rgcDecisions.getDecisions();
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
                _future = AppSettings.of(context).rgcDecisions.getDecisions();
              }),
              child: Text(l10n.text('retry')),
            ),
          ],
        );
      }
      final decisions = snapshot.data ?? const <RgcDecision>[];
      if (decisions.isEmpty) {
        return Text(l10n.text('noRgcDecisions'));
      }
      return widget.builder(decisions);
    },
  );
}
