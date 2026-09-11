import 'package:flutter/material.dart';

import '../../core/app_settings.dart';
import '../../translations/app_language.dart';
import '../../translations/app_localizations.dart';

void showLanguageSwitchSheet(BuildContext context) {
  final settings = AppSettings.of(context);
  final l10n = AppLocalizations.of(context);

  showDialog<void>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.55),
    builder: (dialogContext) {
      return AnimatedBuilder(
        animation: settings,
        builder: (context, _) {
          return Dialog(
            insetPadding: const EdgeInsets.symmetric(horizontal: 24),
            backgroundColor: Theme.of(context).colorScheme.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(26, 28, 26, 30),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    l10n.text('language'),
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),

                  const SizedBox(height: 18),

                  _LanguageOption(
                    flag: '🇰🇭',
                    label: l10n.text('khmer'),
                    value: AppLanguage.khmer,
                    groupValue: settings.language,
                    onChanged: (value) {
                      Navigator.pop(dialogContext);
                      settings.setLanguage(value);
                    },
                  ),

                  const SizedBox(height: 10),

                  _LanguageOption(
                    flag: '🇬🇧',
                    label: l10n.text('english'),
                    value: AppLanguage.english,
                    groupValue: settings.language,
                    onChanged: (value) {
                      Navigator.pop(dialogContext);
                      settings.setLanguage(value);
                    },
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  );
}

class _LanguageOption extends StatelessWidget {
  const _LanguageOption({
    required this.flag,
    required this.label,
    required this.value,
    required this.groupValue,
    required this.onChanged,
  });

  final String flag;
  final String label;
  final AppLanguage value;
  final AppLanguage groupValue;
  final ValueChanged<AppLanguage> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return InkWell(
      onTap: () => onChanged(value),
      borderRadius: BorderRadius.circular(8),
      child: Row(
        children: [
          SizedBox(
            width: 34,
            height: 34,
            child: ClipOval(
              child: Center(
                child: Text(flag, style: const TextStyle(fontSize: 25)),
              ),
            ),
          ),

          const SizedBox(width: 18),

          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: colors.onSurface,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
