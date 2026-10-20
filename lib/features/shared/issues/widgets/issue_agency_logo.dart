import 'package:flutter/material.dart';

/// Shows the responsible ministry logo, with a fallback for unavailable images.
class IssueAgencyLogo extends StatelessWidget {
  const IssueAgencyLogo({
    super.key,
    required this.path,
    this.size = 34,
    this.iconSize = 18,
    this.fallbackColors = const [Color(0xFF216AAA), Color(0xFF1EA45B)],
  });
  final String path;
  final double size;
  final double iconSize;
  final List<Color> fallbackColors;

  @override
  Widget build(BuildContext context) {
    final fallback = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(colors: fallbackColors),
      ),
      child: Icon(Icons.account_balance, color: Colors.white, size: iconSize),
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
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, error, stackTrace) => fallback,
        loadingBuilder: (_, child, progress) =>
            progress == null ? child : fallback,
      ),
    );
  }
}
