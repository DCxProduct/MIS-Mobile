import 'package:flutter/material.dart';

import '../../core/app_colors.dart';
import '../../translations/app_localizations.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final background = isDark ? const Color(0xFF121212) : Colors.white;
    final cardColor = isDark ? AppColors.darkBackground : Colors.white;

    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        backgroundColor: background,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: colors.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          l10n.text('privacyPolicy'),
          style: TextStyle(
            color: colors.onSurface,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 28),
          children: [
            _PrivacyHero(cardColor: cardColor),
            const SizedBox(height: 16),
            Text(
              l10n.text('privacyIntro'),
              style: TextStyle(
                color: colors.onSurfaceVariant,
                fontSize: 13,
                height: 1.45,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 18),
            _PolicySection(
              icon: Icons.person_outline,
              title: l10n.text('privacyDataTitle'),
              body: l10n.text('privacyDataBody'),
              cardColor: cardColor,
            ),
            _PolicySection(
              icon: Icons.verified_user_outlined,
              title: l10n.text('privacyUseTitle'),
              body: l10n.text('privacyUseBody'),
              cardColor: cardColor,
            ),
            _PolicySection(
              icon: Icons.lock_outline,
              title: l10n.text('privacySecurityTitle'),
              body: l10n.text('privacySecurityBody'),
              cardColor: cardColor,
            ),
            _PolicySection(
              icon: Icons.share_outlined,
              title: l10n.text('privacySharingTitle'),
              body: l10n.text('privacySharingBody'),
              cardColor: cardColor,
            ),
            _PolicySection(
              icon: Icons.mail_outline,
              title: l10n.text('privacyContactTitle'),
              body: l10n.text('privacyContactBody'),
              cardColor: cardColor,
            ),
          ],
        ),
      ),
    );
  }
}

class _PrivacyHero extends StatelessWidget {
  const _PrivacyHero({required this.cardColor});

  final Color cardColor;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.outlineVariant.withValues(alpha: 0.8)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: AppColors.accent(context).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(
              Icons.shield_outlined,
              color: AppColors.accent(context),
              size: 32,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppLocalizations.of(context).text('privacyHeroTitle'),
                  style: TextStyle(
                    color: colors.onSurface,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  AppLocalizations.of(context).text('privacyHeroSubtitle'),
                  style: TextStyle(
                    color: colors.onSurfaceVariant,
                    fontSize: 12,
                    height: 1.3,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PolicySection extends StatelessWidget {
  const _PolicySection({
    required this.icon,
    required this.title,
    required this.body,
    required this.cardColor,
  });

  final IconData icon;
  final String title;
  final String body;
  final Color cardColor;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.outlineVariant.withValues(alpha: 0.8)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.accent(context).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(icon, color: AppColors.accent(context), size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: colors.onSurface,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  body,
                  style: TextStyle(
                    color: colors.onSurfaceVariant,
                    fontSize: 12,
                    height: 1.45,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
