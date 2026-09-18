import 'package:flutter/material.dart';

import '../../../../core/app_colors.dart';

class AgenciesTab extends StatelessWidget {
  const AgenciesTab({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      height: 340,
      padding: const EdgeInsets.fromLTRB(16, 5, 8, 16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkBackground : Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : const Color(0xFFE9EDF2),
        ),
      ),
      child: const CustomPaint(painter: _AgenciesBarChartPainter()),
    );
  }
}

class _AgenciesBarChartPainter extends CustomPainter {
  const _AgenciesBarChartPainter();

  static const _labels = [
    'CDC',
    'GDCE',
    'GDT',
    'MAFF',
    'MFF',
    'MISTI',
    'MLMUPC',
    'MLVT',
    'MPTC',
  ];

  static const _values = [5.6, 6.6, 5.2, 3.8, 7.8, 4.6, 7.6, 8.6, 3.2];

  @override
  void paint(Canvas canvas, Size size) {
    const labelWidth = 50.0;
    const rightPadding = 4.0;
    const bottomAxisHeight = 28.0;

    final chartLeft = labelWidth + 10;
    final chartTop = 8.0;
    final chartRight = size.width - rightPadding;
    final chartBottom = size.height - bottomAxisHeight;
    final rowHeight = (chartBottom - chartTop) / _labels.length;

    const maxValue = 9.0;

    final labelStyle = const TextStyle(
      color: Color(0xFF3D4652),
      fontSize: 10,
      fontWeight: FontWeight.w600,
    );

    final axisStyle = labelStyle.copyWith(
      fontSize: 9,
      fontWeight: FontWeight.w500,
    );

    final gridPaint = Paint()
      ..color = const Color(0xFFD8DDE4)
      ..strokeWidth = 1
      ..isAntiAlias = true;

    final barPaint = Paint()
      ..color = const Color(0xFF216AAA)
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    for (var i = 0; i < _labels.length; i++) {
      final centerY = chartTop + rowHeight * i + rowHeight / 2;

      _paintText(
        canvas,
        _labels[i],
        Offset(0, centerY),
        labelStyle,
        verticalCenter: true,
      );

      canvas.drawLine(
        Offset(chartLeft - 9, centerY),
        Offset(chartLeft, centerY),
        gridPaint,
      );

      final barWidth = (_values[i] / maxValue) * (chartRight - chartLeft);

      final barRect = Rect.fromLTWH(chartLeft, centerY - 5, barWidth, 10);

      final barPath = Path()
        ..moveTo(barRect.left, barRect.top)
        ..lineTo(barRect.right - 6, barRect.top)
        ..quadraticBezierTo(
          barRect.right,
          barRect.top,
          barRect.right,
          barRect.top + 6,
        )
        ..lineTo(barRect.right, barRect.bottom - 6)
        ..quadraticBezierTo(
          barRect.right,
          barRect.bottom,
          barRect.right - 6,
          barRect.bottom,
        )
        ..lineTo(barRect.left, barRect.bottom)
        ..close();

      canvas.drawPath(barPath, barPaint);
    }

    canvas.drawLine(
      Offset(chartLeft, chartTop),
      Offset(chartLeft, chartBottom),
      gridPaint,
    );

    canvas.drawLine(
      Offset(chartLeft, chartBottom),
      Offset(chartRight, chartBottom),
      gridPaint,
    );

    const ticks = ['2', '3', '4', '6', '7'];

    final spacing = (chartRight - chartLeft) / (ticks.length - 1);

    for (int i = 0; i < ticks.length; i++) {
      final x = chartLeft + spacing * i;

      canvas.drawLine(
        Offset(x, chartBottom),
        Offset(x, chartBottom + 5),
        gridPaint,
      );

      _paintText(
        canvas,
        ticks[i],
        Offset(x, chartBottom + 14),
        axisStyle,
        horizontalCenter: true,
      );
    }
  }

  void _paintText(
    Canvas canvas,
    String text,
    Offset offset,
    TextStyle style, {
    bool horizontalCenter = false,
    bool verticalCenter = false,
  }) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
    )..layout();

    painter.paint(
      canvas,
      Offset(
        horizontalCenter ? offset.dx - painter.width / 2 : offset.dx,
        verticalCenter ? offset.dy - painter.height / 2 : offset.dy,
      ),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
