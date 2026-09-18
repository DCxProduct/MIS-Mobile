import 'package:flutter/material.dart';

import '../../../../core/app_colors.dart';
import '../../../../screens/notification/notification_screen.dart';
import '../../../../widgets/app_logo.dart';

class DashboardHeader extends StatelessWidget {
  const DashboardHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      color: isDark
          ? AppColors.darkBackground
          : Theme.of(context).scaffoldBackgroundColor,
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          const AppLogo(width: 106),
          const Spacer(),
          InkWell(
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const NotificationScreen(),
                ),
              );
            },
            customBorder: const CircleBorder(),
            child: Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.darkPrimaryContainer
                    : const Color(0xFFE4F2FF),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.notifications,
                color: isDark ? AppColors.darkPrimary : const Color(0xFF5AA7E8),
                size: 22,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
