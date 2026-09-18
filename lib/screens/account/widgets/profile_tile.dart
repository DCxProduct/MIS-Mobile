import 'package:flutter/material.dart';

import '../../../core/app_settings.dart';
import '../../../core/config/module_config.dart';

class ProfileTile extends StatelessWidget {
  const ProfileTile({super.key, this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final settings = AppSettings.of(context);
    final email = settings.userEmail.isNotEmpty
        ? settings.userEmail
        : 'ministry@gmail.com';
    final moduleName = switch (settings.moduleType) {
      AppModuleType.lineMinistry => 'Line Ministry',
      AppModuleType.privateSector => 'Private Sector',
      AppModuleType.cdcSection => 'CDC Section',
      AppModuleType.cefp => 'CEFP',
      AppModuleType.cdcSecretariat => 'CDC Secretariat',
    };

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            CircleAvatar(
              radius: 17,
              backgroundColor: colors.primaryContainer,
              child: Icon(
                Icons.person,
                color: colors.onPrimaryContainer,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    email,
                    style: TextStyle(
                      color: colors.onSurface,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    moduleName,
                    style: TextStyle(
                      color: colors.onSurfaceVariant,
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.keyboard_arrow_down, color: colors.onSurfaceVariant),
          ],
        ),
      ),
    );
  }
}
