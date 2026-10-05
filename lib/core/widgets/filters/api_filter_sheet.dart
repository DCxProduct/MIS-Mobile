import 'package:flutter/material.dart';
import '../../../translations/app_localizations.dart';
import 'app_filter_sheet.dart';
import 'filter_sheet_header.dart';

export 'filter_models.dart';

/// The common filter presentation. Each screen supplies its own API catalog.
/// Failed lookups stay visible and retryable; they never become demo options.
class ApiFilterSheet extends StatefulWidget {
  const ApiFilterSheet({super.key, required this.initial, required this.load});
  final FilterSelection initial;
  final Future<List<FilterSection>> Function() load;

  @override
  State<ApiFilterSheet> createState() => _ApiFilterSheetState();
}

class _ApiFilterSheetState extends State<ApiFilterSheet> {
  late Future<List<FilterSection>> _request = widget.load();

  @override
  Widget build(BuildContext context) => FutureBuilder<List<FilterSection>>(
    future: _request,
    builder: (context, snapshot) {
      if (snapshot.hasData) {
        final l10n = AppLocalizations.of(context);
        return AppFilterSheet(
          initial: widget.initial,
          compact: true,
          sections: [
            for (final section in snapshot.data!)
              FilterSection(
                id: section.id,
                title: l10n.text(section.title),
                options: section.options,
                columns: section.columns,
                collapsedItemCount: section.collapsedItemCount,
                singleSelection: section.singleSelection,
                exclusiveValues: section.exclusiveValues,
              ),
          ],
        );
      }
      final l10n = AppLocalizations.of(context);
      return Material(
        color: Theme.of(context).colorScheme.surface,
        child: SafeArea(
          child: Column(
            children: [
              FilterSheetHeader(
                title: l10n.text('filters'),
                onClose: () => Navigator.pop(context, FilterSelection()),
                titleStyle: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Expanded(
                child: Center(
                  child: snapshot.hasError
                      ? Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(l10n.text('filtersLoadError')),
                            TextButton(
                              onPressed: () => setState(() {
                                _request = widget.load();
                              }),
                              child: Text(l10n.text('retry')),
                            ),
                          ],
                        )
                      : const CircularProgressIndicator(),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}
