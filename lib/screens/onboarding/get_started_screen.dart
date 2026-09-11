import 'package:flutter/material.dart';

import '../../core/app_assets.dart';
import '../../translations/app_localizations.dart';
import '../../widgets/primary_button.dart';
import '../auth/login_screen.dart';

class GetStartedScreen extends StatelessWidget {
  const GetStartedScreen({super.key});

  void _openLogin(BuildContext context) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => const LoginScreen()));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? const Color(0xFF14191E) : colors.surface;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        top: false,
        bottom: true,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Image.asset(
              isDark ? AppAssets.getStartedDark : AppAssets.getStarted,
              width: double.infinity,
              fit: BoxFit.cover,
              alignment: Alignment.topCenter,
            ),

            Container(
              height: 72,
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    isDark ? const Color(0xFF14191E) : const Color(0xFFE8F2FB),
                    backgroundColor,
                  ],
                ),
              ),
            ),

            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(28, 0, 28, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.text('welcome'),
                      style: TextStyle(
                        color: colors.onSurface,
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                      ),
                    ),

                    const SizedBox(height: 30),

                    Text(
                      l10n.text('systemName'),
                      style: TextStyle(
                        color: colors.onSurface,
                        fontSize: 33,
                        height: 1,
                        fontWeight: FontWeight.w700,
                      ),
                    ),

                    const SizedBox(height: 22),

                    Text(
                      l10n.text('intro'),
                      style: TextStyle(
                        fontSize: 16,
                        height: 1.18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),

                    const SizedBox(height: 52),

                    PrimaryButton(
                      label: l10n.text('getStartNow'),
                      onPressed: () => _openLogin(context),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
