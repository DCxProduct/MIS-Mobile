import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/app_colors.dart';
import '../../../translations/app_localizations.dart';

class CdcSecretariatOverallTab extends StatelessWidget {
  const CdcSecretariatOverallTab({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 5, 18, 16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkBackground : Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : const Color(0xFFE9EDF2),
        ),
      ),
      child: Column(
        children: [
          SizedBox(
            width: 320,
            height: 195,
            child: CustomPaint(painter: _DonutChartPainter(isDark: isDark)),
          ),
          const SizedBox(height: 2),
          _ChartLegendRow(
            color: isDark ? AppColors.darkPrimary : const Color(0xFF2D7DBF),
            label: l10n.text('totalIssues'),
            value: '(100)',
          ),
          _ChartLegendRow(
            color: const Color(0xFF009F5C),
            label: l10n.text('solved'),
            value: '(67)',
          ),
          _ChartLegendRow(
            color: const Color(0xFFE8A61A),
            label: l10n.text('inProgress'),
            value: '(23)',
          ),
          _ChartLegendRow(
            color: const Color(0xFFFF3B30),
            label: l10n.text('notAddressed'),
            value: '(10)',
          ),
        ],
      ),
    );
  }
}

class _DonutChartPainter extends CustomPainter {
  const _DonutChartPainter({required this.isDark});

  final bool isDark;

  static const double _cornerRadius = 6;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final outerRadius = math.min(size.width, size.height) * 0.43;
    final innerRadius = outerRadius * 0.65;
    const gapAngle = 0.02;

    var startAngle = -math.pi * 0.15;

    final segments = [
      (
        percent: 0.67,
        color: const Color(0xFF009F5C),
        label: '67%',
        offset: const Offset(90, 52),
      ),
      (
        percent: 0.10,
        color: const Color(0xFFFF3B30),
        label: '10%',
        offset: const Offset(-100, 0),
      ),
      (
        percent: 0.23,
        color: const Color(0xFFE8A61A),
        label: '23%',
        offset: const Offset(60, -78),
      ),
    ];

    for (final segment in segments) {
      final sweep = segment.percent * math.pi * 2;

      final path = _roundedDonutSegment(
        center: center,
        outerRadius: outerRadius,
        innerRadius: innerRadius,
        startAngle: startAngle + gapAngle / 2,
        sweepAngle: sweep - gapAngle,
        cornerRadius: _cornerRadius,
      );

      canvas.drawPath(
        path,
        Paint()
          ..color = segment.color
          ..style = PaintingStyle.fill
          ..isAntiAlias = true,
      );

      startAngle += sweep;
    }

    _drawCenterLabel(canvas, center);

    for (final segment in segments) {
      _drawPercentChip(
        canvas,
        center + segment.offset,
        segment.label,
        segment.color,
      );
    }
  }

  Offset _point(Offset center, double radius, double angle) {
    return Offset(
      center.dx + radius * math.cos(angle),
      center.dy + radius * math.sin(angle),
    );
  }

  Path _roundedDonutSegment({
    required Offset center,
    required double outerRadius,
    required double innerRadius,
    required double startAngle,
    required double sweepAngle,
    required double cornerRadius,
  }) {
    final endAngle = startAngle + sweepAngle;

    final outerRect = Rect.fromCircle(center: center, radius: outerRadius);
    final innerRect = Rect.fromCircle(center: center, radius: innerRadius);

    final outerCut = cornerRadius / outerRadius;
    final innerCut = cornerRadius / innerRadius;

    final path = Path();

    path.moveTo(
      _point(center, outerRadius, startAngle + outerCut).dx,
      _point(center, outerRadius, startAngle + outerCut).dy,
    );

    path.arcTo(
      outerRect,
      startAngle + outerCut,
      sweepAngle - outerCut * 2,
      false,
    );

    path.quadraticBezierTo(
      _point(center, outerRadius, endAngle).dx,
      _point(center, outerRadius, endAngle).dy,
      _point(center, outerRadius - cornerRadius, endAngle).dx,
      _point(center, outerRadius - cornerRadius, endAngle).dy,
    );

    path.lineTo(
      _point(center, innerRadius + cornerRadius, endAngle).dx,
      _point(center, innerRadius + cornerRadius, endAngle).dy,
    );

    path.quadraticBezierTo(
      _point(center, innerRadius, endAngle).dx,
      _point(center, innerRadius, endAngle).dy,
      _point(center, innerRadius, endAngle - innerCut).dx,
      _point(center, innerRadius, endAngle - innerCut).dy,
    );

    path.arcTo(
      innerRect,
      endAngle - innerCut,
      -sweepAngle + innerCut * 2,
      false,
    );

    path.quadraticBezierTo(
      _point(center, innerRadius, startAngle).dx,
      _point(center, innerRadius, startAngle).dy,
      _point(center, innerRadius + cornerRadius, startAngle).dx,
      _point(center, innerRadius + cornerRadius, startAngle).dy,
    );

    path.lineTo(
      _point(center, outerRadius - cornerRadius, startAngle).dx,
      _point(center, outerRadius - cornerRadius, startAngle).dy,
    );

    path.quadraticBezierTo(
      _point(center, outerRadius, startAngle).dx,
      _point(center, outerRadius, startAngle).dy,
      _point(center, outerRadius, startAngle + outerCut).dx,
      _point(center, outerRadius, startAngle + outerCut).dy,
    );

    path.close();
    return path;
  }

  void _drawPercentChip(
    Canvas canvas,
    Offset center,
    String text,
    Color color,
  ) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: const TextStyle(
          color: AppColors.text,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    final chipRect = Rect.fromCenter(
      center: center,
      width: painter.width + 24,
      height: 24,
    );

    final rrect = RRect.fromRectAndRadius(chipRect, const Radius.circular(5));

    canvas.drawShadow(
      Path()..addRRect(rrect),
      Colors.black.withValues(alpha: 0.22),
      5,
      true,
    );

    canvas.drawRRect(rrect, Paint()..color = Colors.white);

    canvas.drawCircle(
      Offset(chipRect.left + 9, center.dy),
      2.2,
      Paint()..color = color,
    );

    painter.paint(
      canvas,
      Offset(chipRect.left + 14, center.dy - painter.height / 2),
    );
  }

  void _drawCenterLabel(Canvas canvas, Offset center) {
    final painter = TextPainter(
      textAlign: TextAlign.center,
      text: TextSpan(
        children: [
          TextSpan(
            text: 'Total Issues\n',
            style: TextStyle(
              color: isDark ? const Color(0xFFB8C0CC) : const Color(0xFF6C7480),
              fontSize: 11,
              height: 1.25,
              fontWeight: FontWeight.w500,
            ),
          ),
          TextSpan(
            text: '100',
            style: TextStyle(
              color: isDark ? Colors.white : AppColors.text,
              fontSize: 16,
              height: 1.1,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    painter.paint(
      canvas,
      center - Offset(painter.width / 2, painter.height / 2),
    );
  }

  @override
  bool shouldRepaint(covariant _DonutChartPainter oldDelegate) =>
      oldDelegate.isDark != isDark;
}

class _ChartLegendRow extends StatelessWidget {
  const _ChartLegendRow({
    required this.color,
    required this.label,
    required this.value,
  });

  final Color color;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Row(
        children: [
          Container(
            width: 9,
            height: 9,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: colors.onSurfaceVariant,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: colors.onSurface,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
