import 'package:flutter/material.dart';

import '../core/app_colors.dart';
import 'notification_bell.dart';
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
        padding: EdgeInsets.only(top: topPadding > 0 ? topPadding + 4 : 28),
        child: Padding(
          padding: padding,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              AppLogo(width: logoWidth),
              const NotificationBell(),
            ],
          ),
        ),
      ),
    );
  }
}
