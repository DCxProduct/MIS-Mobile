import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../core/app_settings.dart';
import '../../../features/auth/data/auth_user.dart';
import '../../../translations/app_localizations.dart';

class ProfileLoader extends StatefulWidget {
  const ProfileLoader({super.key, required this.builder});
  final Widget Function(BuildContext, AuthUser) builder;
  @override
  State<ProfileLoader> createState() => _ProfileLoaderState();
}

class _ProfileLoaderState extends State<ProfileLoader> {
  Future<AuthUser>? _request;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _request ??= AppSettings.of(context).auth.getProfile();
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<AuthUser>(
    future: _request,
    builder: (context, snapshot) {
      if (snapshot.hasData) return widget.builder(context, snapshot.data!);
      if (snapshot.hasError) {
        return Center(
          child: TextButton.icon(
            onPressed: () => setState(() {
              _request = AppSettings.of(context).auth.getProfile();
            }),
            icon: const Icon(Icons.refresh),
            label: Text(AppLocalizations.of(context).text('retry')),
          ),
        );
      }
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: CircularProgressIndicator(),
        ),
      );
    },
  );
}

class ProfileAvatar extends StatelessWidget {
  const ProfileAvatar({super.key, required this.path, this.size = 40});
  final String? path;
  final double size;
  @override
  Widget build(BuildContext context) {
    final fallback = CircleAvatar(
      radius: size / 2,
      child: const Icon(Icons.person),
    );
    final avatarPath = path?.trim() ?? '';
    if (avatarPath.isEmpty) return fallback;
    final parsed = Uri.tryParse(avatarPath);
    if (parsed == null) return fallback;
    // The API's generated default avatar is not an uploaded profile photo.
    if (parsed.host.toLowerCase() == 'api.dicebear.com') return fallback;
    final uri = AppSettings.of(
      context,
    ).auth.apiClient.serverOrigin.resolveUri(parsed);
    if (uri.scheme != 'https' && uri.scheme != 'http') return fallback;
    final svg = uri.path.endsWith('.svg') || uri.path.endsWith('/svg');
    return ClipOval(
      child: SizedBox(
        width: size,
        height: size,
        child: svg
            ? SvgPicture.network(
                uri.toString(),
                fit: BoxFit.cover,
                placeholderBuilder: (_) => fallback,
                errorBuilder: (_, error, stack) => fallback,
              )
            : Image.network(
                uri.toString(),
                fit: BoxFit.cover,
                errorBuilder: (_, error, stack) => fallback,
              ),
      ),
    );
  }
}
