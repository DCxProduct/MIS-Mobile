import 'package:flutter/material.dart';

import '../core/app_assets.dart';

class AppLogo extends StatelessWidget {
  const AppLogo({super.key, required this.width});

  final double width;

  @override
  Widget build(BuildContext context) {
    final logo = Image.asset(AppAssets.logo, width: width, fit: BoxFit.contain);

    if (Theme.of(context).brightness != Brightness.dark) {
      return logo;
    }

    return ColorFiltered(
      colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
      child: logo,
    );
  }
}
