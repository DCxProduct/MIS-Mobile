import '../../translations/app_localizations.dart';
import '../../translations/account_translation_scope.dart';
import 'package:flutter/material.dart';

import '../../core/app_colors.dart';
import '../../features/auth/data/auth_user.dart';
import 'widgets/profile_loader.dart';

class ProfileDetailScreen extends StatelessWidget {
  const ProfileDetailScreen({super.key});

  @override
  Widget build(BuildContext context) =>
      AccountTranslationScope(builder: _buildContent);

  Widget _buildContent(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pageBackground(context),
      appBar: AppBar(
        backgroundColor: AppColors.pageBackground(context),
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        centerTitle: true,
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: AppColors.primaryText(context),
            size: 19,
          ),
        ),
        title: Text(
          AppLocalizations.of(context).text('profile'),
          style: TextStyle(
            color: AppColors.primaryText(context),
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: ProfileLoader(
        builder: (context, user) => SafeArea(
          top: false,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
            children: [
              _ProfileCard(user: user),
              const SizedBox(height: 20),
              _SectionTitle(
                title: AppLocalizations.of(context).text('personalInformation'),
              ),
              const SizedBox(height: 10),
              _InfoCard(
                children: [
                  _InfoItem(
                    icon: Icons.person_outline_rounded,
                    label: AppLocalizations.of(context).text('gender'),
                    value: _genderLabel(context, user.gender),
                  ),
                  _InfoItem(
                    icon: Icons.calendar_month_outlined,
                    label: AppLocalizations.of(context).text('dateOfBirth'),
                    value: user.dateOfBirth?.split('T').first ?? '—',
                  ),
                  _InfoItem(
                    icon: Icons.location_on_outlined,
                    label: AppLocalizations.of(context).text('address'),
                    value: user.address ?? '—',
                    showDivider: false,
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _SectionTitle(
                title: AppLocalizations.of(context).text('contact'),
              ),
              const SizedBox(height: 10),
              _InfoCard(
                children: [
                  _InfoItem(
                    icon: Icons.phone_outlined,
                    label: AppLocalizations.of(context).text('phone'),
                    value: user.phoneNumber ?? '—',
                  ),
                  _InfoItem(
                    icon: Icons.email_outlined,
                    label: AppLocalizations.of(context).text('email'),
                    value: user.email,
                    showDivider: false,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _genderLabel(BuildContext context, String? gender) {
    final key = gender?.trim().toLowerCase();
    if (key == 'male' || key == 'female') {
      return AppLocalizations.of(context).remoteText(key!) ?? gender!;
    }
    return gender ?? '—';
  }
}

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({required this.user});
  final AuthUser user;

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkBackground : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border(context)),
      ),
      child: Row(
        children: [
          ProfileAvatar(path: user.avatar, size: 58),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.name,
                  style: TextStyle(
                    color: AppColors.primaryText(context),
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  user.position ?? '—',
                  style: TextStyle(
                    color: AppColors.secondaryText(context),
                    fontSize: 12,
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

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: TextStyle(
        color: AppColors.primaryText(context),
        fontSize: 14,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkBackground : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border(context)),
      ),
      child: Column(children: children),
    );
  }
}

class _InfoItem extends StatelessWidget {
  const _InfoItem({
    required this.icon,
    required this.label,
    required this.value,
    this.showDivider = true,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.darkElevated
                      : AppColors.subtleBackground(context),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  color: isDark
                      ? AppColors.darkPrimary
                      : AppColors.secondaryText(context),
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        color: AppColors.secondaryText(context),
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      value,
                      style: TextStyle(
                        color: AppColors.primaryText(context),
                        fontSize: 13,
                        height: 1.3,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (showDivider)
          Divider(
            height: 1,
            indent: 62,
            endIndent: 14,
            color: AppColors.border(context),
          ),
      ],
    );
  }
}
