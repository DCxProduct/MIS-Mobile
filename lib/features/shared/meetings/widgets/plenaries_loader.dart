import '../../../../core/widgets/filters/api_filter_scope.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../../core/app_settings.dart';
import '../../../../core/config/module_config.dart';
import '../../../../translations/app_localizations.dart';
import '../data/plenary.dart';

class PlenariesLoader extends StatefulWidget {
  const PlenariesLoader({super.key, required this.builder});

  final Widget Function(List<Plenary>) builder;

  @override
  State<PlenariesLoader> createState() => _PlenariesLoaderState();
}

class _PlenariesLoaderState extends State<PlenariesLoader> {
  Future<List<Plenary>>? _future;
  Map<String, String>? _query;
  bool? _sentOnly;

  Future<List<Plenary>> _load() => AppSettings.of(context).plenaries
      .getPlenaries(filters: _query ?? const {}, sentOnly: _sentOnly ?? false);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final query = ApiFilterScope.query(context, 'plenaries');
    final sentOnly =
        AppSettings.of(context).moduleType == AppModuleType.lineMinistry;
    if (_future == null || !mapEquals(_query, query) || _sentOnly != sentOnly) {
      _query = Map.of(query);
      _sentOnly = sentOnly;
      _future = _load();
    }
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<List<Plenary>>(
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
            Text(l10n.text('plenariesLoadError')),
            TextButton(
              onPressed: () => setState(() {
                _future = _load();
              }),
              child: Text(l10n.text('retry')),
            ),
          ],
        );
      }
      final plenaries = snapshot.data ?? const <Plenary>[];
      if (plenaries.isEmpty) return Text(l10n.text('noPlenaries'));
      return widget.builder(plenaries);
    },
  );
}
