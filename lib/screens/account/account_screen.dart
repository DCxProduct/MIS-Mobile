import 'package:flutter/material.dart';

import '../../translations/app_localizations.dart';
import 'language_switch_sheet.dart';
import 'logout_sheet.dart';
import 'profile_detail_screen.dart';
import 'privacy_policy_screen.dart';
import 'support_center_screen.dart';
import 'theme_switch_sheet.dart';
import 'widgets/profile_tile.dart';
import 'widgets/setting_tile.dart';

class AccountScreen extends StatelessWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).colorScheme;
    final topPadding = MediaQuery.of(context).viewPadding.top;

    return Padding(
      padding: EdgeInsets.fromLTRB(20, topPadding > 0 ? topPadding + 12 : 34, 20, 96),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.text('setting'),
            style: TextStyle(
              color: colors.onSurface,
              fontSize: 24,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 28),
          ProfileTile(
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const ProfileDetailScreen(),
                ),
              );
            },
          ),
          const SizedBox(height: 22),
          Divider(color: colors.outlineVariant),
          SettingTile(
            icon: Icons.light_mode_outlined,
            label: l10n.text('darkMode'),
            onTap: () => showThemeSwitchSheet(context),
          ),
          SettingTile(
            icon: Icons.lock_outline,
            label: l10n.text('privacyPolicy'),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const PrivacyPolicyScreen(),
                ),
              );
            },
          ),
          SettingTile(
            icon: Icons.translate_outlined,
            label: l10n.text('language'),
            onTap: () => showLanguageSwitchSheet(context),
          ),
          SettingTile(
            icon: Icons.mail_outline,
            label: l10n.text('supportTeam'),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const SupportCenterScreen(),
                ),
              );
            },
          ),
          SettingTile(
            icon: Icons.logout,
            label: l10n.text('logout'),
            onTap: () => showLogoutSheet(context),
          ),
          const Spacer(),
          Center(
            child: Text(
              l10n.text('version'),
              style: TextStyle(color: colors.onSurfaceVariant, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}
