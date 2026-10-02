import 'package:flutter/material.dart';

import '../../../../core/app_colors.dart';
import '../../../../widgets/notification_bell.dart';
import '../../../../widgets/app_logo.dart';

class PrivateSectorDashboardHeader extends StatelessWidget {
  const PrivateSectorDashboardHeader({super.key});

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
          const NotificationBell(),
        ],
      ),
    );
  }
}
