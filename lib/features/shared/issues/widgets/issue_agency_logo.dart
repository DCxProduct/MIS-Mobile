import 'package:flutter/material.dart';

/// Shows the responsible ministry logo, with a fallback for unavailable images.
class IssueAgencyLogo extends StatelessWidget {
  const IssueAgencyLogo({super.key, required this.path});
  final String path;

  @override
  Widget build(BuildContext context) {
    final fallback = Container(
      width: 34,
      height: 34,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [Color(0xFF216AAA), Color(0xFF1EA45B)],
        ),
      ),
      child: const Icon(Icons.account_balance, color: Colors.white, size: 18),
    );
    if (path.trim().isEmpty) return fallback;
    const baseUrl = String.fromEnvironment(
      'API_BASE_URL',
      defaultValue: 'https://admin-mis-stage.datacolabx.com/api/v1',
    );
    final base = Uri.parse(baseUrl);
    final asset = Uri.parse(path.trim());
    final url = asset.hasScheme
        ? asset
        : base.resolve('/${path.trim().replaceFirst(RegExp(r'^/+'), '')}');
    if (url.scheme != 'https' && url.scheme != 'http') return fallback;
    return ClipOval(
      child: Image.network(
        url.toString(),
        width: 34,
        height: 34,
        fit: BoxFit.cover,
        errorBuilder: (_, error, stackTrace) => fallback,
        loadingBuilder: (_, child, progress) =>
            progress == null ? child : fallback,
      ),
    );
  }
}
