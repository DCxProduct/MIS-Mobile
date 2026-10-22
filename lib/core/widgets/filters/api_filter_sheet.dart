import 'package:flutter/material.dart';
import '../../../translations/app_localizations.dart';
import '../../../translations/app_language.dart';
import 'app_filter_sheet.dart';
import 'filter_sheet_header.dart';

export 'filter_models.dart';

/// The common filter presentation. Each screen supplies its own API catalog.
/// Failed lookups stay visible and retryable; they never become demo options.
class ApiFilterSheet extends StatefulWidget {
  const ApiFilterSheet({
    super.key,
    required this.initial,
    required this.load,
    this.translationPage,
  });
  final String? translationPage;
  final FilterSelection initial;
  final Future<List<FilterSection>> Function() load;

  @override
  State<ApiFilterSheet> createState() => _ApiFilterSheetState();
}

class _ApiFilterSheetState extends State<ApiFilterSheet> {
  late Future<List<FilterSection>> _request = widget.load();

  String _optionLabel(
    AppLocalizations l10n,
    FilterSection section,
    FilterOption option,
  ) {
    final key = switch (option.label.trim().toLowerCase()) {
      'both' => 'both',
      'yes' => 'yes',
      'no' => 'no',
      'no data' || 'not data' => 'noData',
      's1' || 'semester 1' => 's1',
      's2' || 'semester 2' => 's2',
      _ => null,
    };
    if (key != null) {
      final remote = l10n.remoteText(key);
      if (remote != null) return remote;
    }
    if (section.title == 'status') {
      final remote =
          l10n.remoteStatus(option.value) ?? l10n.remoteStatus(option.label);
      if (remote != null) return remote;
    }
    final khmerLabel = option.khmerLabel?.trim();
    if (l10n.language == AppLanguage.khmer &&
        khmerLabel != null &&
        khmerLabel.isNotEmpty) {
      return khmerLabel;
    }
    if (section.title == 'status') {
      final fromCode = l10n.status(option.value);
      return fromCode != option.value ? fromCode : l10n.status(option.label);
    }
    if (key != null) return l10n.text(key);
    return option.label;
  }

  @override
  Widget build(BuildContext context) => TranslationPageScope(
    page: widget.translationPage ?? TranslationPageScope.maybeOf(context) ?? '',
    child: Builder(builder: _buildContent),
  );

  Widget _buildContent(BuildContext context) =>
      FutureBuilder<List<FilterSection>>(
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
                    title: l10n.filterLabel(section.title),
                    options: [
                      for (final option in section.options)
                        FilterOption(
                          value: option.value,
                          label: _optionLabel(l10n, section, option),
                          enabled: option.enabled,
                          year: option.year,
                        ),
                    ],
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
