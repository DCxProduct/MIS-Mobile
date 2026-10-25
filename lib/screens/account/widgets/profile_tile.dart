import 'package:flutter/material.dart';

import '../../../features/auth/data/auth_user.dart';
import 'profile_loader.dart';

class ProfileTile extends StatelessWidget {
  const ProfileTile({super.key, this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => ProfileLoader(builder: _buildProfile);

  Widget _buildProfile(BuildContext context, AuthUser user) {
    final colors = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            ProfileAvatar(path: user.avatar, size: 34),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.name,
                    style: TextStyle(
                      color: colors.onSurface,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    user.position ?? user.email,
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
