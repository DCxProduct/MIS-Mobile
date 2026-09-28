import 'package:flutter/material.dart';

import '../../../../core/app_settings.dart';
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

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _future ??= AppSettings.of(context).plenaries.getPlenaries();
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
                _future = AppSettings.of(context).plenaries.getPlenaries();
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
