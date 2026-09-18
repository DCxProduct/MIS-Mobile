import 'package:flutter/material.dart';

import '../../core/app_colors.dart';
import '../../core/app_settings.dart';
import '../../core/config/module_config.dart';

class ProfileDetailScreen extends StatelessWidget {
  const ProfileDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = AppSettings.of(context);
    final email = settings.userEmail.isNotEmpty
        ? settings.userEmail
        : 'ministry@gmail.com';

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
          'Profile',
          style: TextStyle(
            color: AppColors.primaryText(context),
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
          children: [
            const _ProfileCard(),
            const SizedBox(height: 20),
            const _SectionTitle(title: 'Personal information'),
            const SizedBox(height: 10),
            const _InfoCard(
              children: [
                _InfoItem(
                  icon: Icons.person_outline_rounded,
                  label: 'Gender',
                  value: 'Male',
                ),
                _InfoItem(
                  icon: Icons.calendar_month_outlined,
                  label: 'Date of birth',
                  value: '09 March 2000',
                ),
                _InfoItem(
                  icon: Icons.location_on_outlined,
                  label: 'Address',
                  value: 'Phumi Ti 1, Sangkat Ti 1, Khan Toul Kouk',
                  showDivider: false,
                ),
              ],
            ),
            const SizedBox(height: 20),
            const _SectionTitle(title: 'Contact'),
            const SizedBox(height: 10),
            _InfoCard(
              children: [
                const _InfoItem(
                  icon: Icons.phone_outlined,
                  label: 'Phone',
                  value: '016 446 646',
                ),
                _InfoItem(
                  icon: Icons.email_outlined,
                  label: 'Email',
                  value: email,
                  showDivider: false,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileCard extends StatelessWidget {
  const _ProfileCard();

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);
    final settings = AppSettings.of(context);
    final moduleName = switch (settings.moduleType) {
      AppModuleType.lineMinistry => 'Line Ministry',
      AppModuleType.privateSector => 'Private Sector',
      AppModuleType.cdcSection => 'CDC Section',
      AppModuleType.cefp => 'CEFP',
      AppModuleType.cdcSecretariat => 'CDC Secretariat',
    };

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkBackground : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border(context)),
      ),
      child: Row(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.darkPrimaryContainer
                  : AppColors.subtleBackground(context),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.person_rounded,
              color: isDark
                  ? AppColors.darkPrimary
                  : AppColors.secondaryText(context),
              size: 34,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'KHON VAKHIM',
                  style: TextStyle(
                    color: AppColors.primaryText(context),
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  moduleName,
                  style: TextStyle(
                    color: AppColors.secondaryText(context),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
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
              Icons.edit_outlined,
              color: isDark
                  ? AppColors.darkPrimary
                  : AppColors.secondaryText(context),
              size: 18,
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
