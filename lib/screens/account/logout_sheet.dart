import 'package:flutter/material.dart';

import '../../translations/app_localizations.dart';
import '../auth/login_screen.dart';

void showLogoutSheet(BuildContext context) {
  final l10n = AppLocalizations.of(context);

  showDialog<void>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.55),
    builder: (dialogContext) {
      final colors = Theme.of(dialogContext).colorScheme;

      return Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 34),
        backgroundColor: colors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 22, 20, 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                l10n.text('logoutQuestion'),
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: colors.onSurface,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 26),
              Row(
                children: [
                  Expanded(
                    child: _LogoutActionButton(
                      label: l10n.text('cancel'),
                      foregroundColor: colors.onSurfaceVariant,
                      borderColor: colors.outlineVariant,
                      backgroundColor: colors.surface,
                      onPressed: () => Navigator.pop(dialogContext),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _LogoutActionButton(
                      label: l10n.text('logout'),
                      foregroundColor: Colors.white,
                      backgroundColor: const Color(0xFFE42C25),
                      onPressed: () {
                        Navigator.pop(dialogContext);
                        Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute<void>(
                            builder: (_) => const LoginScreen(),
                          ),
                          (route) => false,
                        );
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    },
  );
}

class _LogoutActionButton extends StatelessWidget {
  const _LogoutActionButton({
    required this.label,
    required this.foregroundColor,
    required this.backgroundColor,
    required this.onPressed,
    this.borderColor,
  });

  final String label;
  final Color foregroundColor;
  final Color backgroundColor;
  final Color? borderColor;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 33,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: foregroundColor,
          side: BorderSide(color: borderColor ?? backgroundColor),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
          textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
        ),
        child: Text(label),
      ),
    );
  }
}
