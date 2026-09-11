import 'package:flutter/material.dart';

import '../../core/app_settings.dart';
import '../../translations/app_localizations.dart';

void showThemeSwitchSheet(BuildContext context) {
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
              padding: const EdgeInsets.fromLTRB(26, 32, 26, 26),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _ThemeOption(
                    title: l10n.text('on'),
                    value: ThemeMode.dark,
                    groupValue: settings.themeMode,
                    onChanged: (value) {
                      Navigator.pop(dialogContext);
                      settings.setThemeMode(value);
                    },
                  ),

                  const SizedBox(height: 18),

                  _ThemeOption(
                    title: l10n.text('off'),
                    value: ThemeMode.light,
                    groupValue: settings.themeMode,
                    onChanged: (value) {
                      Navigator.pop(dialogContext);
                      settings.setThemeMode(value);
                    },
                  ),

                  const SizedBox(height: 18),

                  _ThemeOption(
                    title: l10n.text('system'),
                    subtitle: l10n.text('systemThemeHelp'),
                    value: ThemeMode.system,
                    groupValue: settings.themeMode,
                    onChanged: (value) {
                      Navigator.pop(dialogContext);
                      settings.setThemeMode(value);
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

class _ThemeOption extends StatelessWidget {
  const _ThemeOption({
    required this.title,
    required this.value,
    required this.groupValue,
    required this.onChanged,
    this.subtitle,
  });

  final String title;
  final String? subtitle;
  final ThemeMode value;
  final ThemeMode groupValue;
  final ValueChanged<ThemeMode> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final selected = value == groupValue;

    return InkWell(
      onTap: () => onChanged(value),
      borderRadius: BorderRadius.circular(8),
      child: Row(
        crossAxisAlignment: subtitle == null
            ? CrossAxisAlignment.center
            : CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 1),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: colors.onSurface,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      subtitle!,
                      style: TextStyle(
                        color: colors.onSurface.withValues(alpha: 0.55),
                        fontSize: 12,
                        height: 1.15,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),

          const SizedBox(width: 16),

          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: selected
                    ? colors.primary
                    : colors.outline.withValues(alpha: 0.35),
                width: selected ? 6 : 1,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
