import 'package:flutter/material.dart';

import '../core/app_colors.dart';
import '../screens/notification/notification_screen.dart';
import 'app_logo.dart';

class AppHeader extends StatelessWidget {
  const AppHeader({
    super.key,
    this.logoWidth = 106,
    this.padding = const EdgeInsets.fromLTRB(14, 10, 14, 12),
  });

  final double logoWidth;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final topPadding = MediaQuery.of(context).viewPadding.top;

    return Material(
      color: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkBackground : Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        padding: EdgeInsets.only(
          top: topPadding > 0 ? topPadding + 4 : 28,
        ),
        child: Padding(
          padding: padding,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              AppLogo(width: logoWidth),
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
                    color: isDark
                        ? AppColors.darkPrimary
                        : const Color(0xFF5AA7E8),
                    size: 22,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
