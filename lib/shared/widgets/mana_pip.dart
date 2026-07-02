import 'package:flutter/material.dart';

import '../../app/theme.dart';

/// The display size of a mana pip.
enum ManaPipSize {
  /// 15x15 — used on card tiles in the grid.
  compact(15),

  /// 26x26 — used in filter panels.
  filter(26),

  /// 20x20 — used in card detail views.
  detail(20);

  const ManaPipSize(this.dimension);
  final double dimension;
}

/// The interactive state of a filter pip.
enum ManaPipState {
  /// Included in the filter — solid dark border.
  selected,

  /// Neutral — thin per-color border.
  unselected,

  /// Explicitly excluded — dashed neutral border, faded.
  deselected,
}

/// A circular WUBRG+CM color indicator pip.
///
/// Renders a single letter (W, U, B, R, G, C, or M) in a colored circle whose
/// appearance varies by [size] and [state].
class ManaPip extends StatelessWidget {
  const ManaPip({
    super.key,
    required this.color,
    this.size = ManaPipSize.filter,
    this.state = ManaPipState.unselected,
    this.onTap,
  });

  /// One of "W", "U", "B", "R", "G", "C", "M".
  final String color;

  /// Controls the diameter of the pip.
  final ManaPipSize size;

  /// Controls border / color treatment for filter interactions.
  final ManaPipState state;

  /// Called when the pip is tapped (filter panels only).
  final VoidCallback? onTap;

  /// Resolve the [ManaPipColor] for the given letter.
  static ManaPipColor _pipColor(String letter) {
    switch (letter.toUpperCase()) {
      case 'W':
        return ManaPips.w;
      case 'U':
        return ManaPips.u;
      case 'B':
        return ManaPips.b;
      case 'R':
        return ManaPips.r;
      case 'G':
        return ManaPips.g;
      case 'C':
        return ManaPips.c;
      case 'M':
        return ManaPips.m;
      default:
        return ManaPips.c; // fallback
    }
  }

  double _fontSize() {
    switch (size) {
      case ManaPipSize.compact:
        return 9;
      case ManaPipSize.detail:
        return 10;
      case ManaPipSize.filter:
        return 12;
    }
  }

  @override
  Widget build(BuildContext context) {
    final pip = _pipColor(color);
    final dim = size.dimension;

    Color bgColor;
    Color textColor;
    Border? border;

    switch (state) {
      case ManaPipState.selected:
        bgColor = pip.background;
        textColor = pip.text;
        border = Border.all(color: AppColors.neutral900, width: 2);
      case ManaPipState.unselected:
        bgColor = pip.background;
        textColor = pip.text;
        border = Border.all(color: pip.border, width: 1);
      case ManaPipState.deselected:
        // Lighten the bg by blending with white.
        bgColor = Color.lerp(pip.background, AppColors.neutral0, 0.5)!;
        textColor = AppColors.neutral300;
        border = null; // dashed border handled via CustomPaint
    }

    Widget circle = Container(
      width: dim,
      height: dim,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: bgColor,
        border: state != ManaPipState.deselected ? border : null,
      ),
      alignment: Alignment.center,
      child: Text(
        color.toUpperCase(),
        style: AppTypography.pipText.copyWith(
          fontSize: _fontSize(),
          color: textColor,
        ),
      ),
    );

    // Wrap in dashed-border painter for deselected state.
    if (state == ManaPipState.deselected) {
      circle = CustomPaint(
        painter: _DashedCirclePainter(
          color: AppColors.neutral250,
          strokeWidth: 2,
          radius: dim / 2,
        ),
        child: circle,
      );
    }

    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        child: circle,
      );
    }

    return circle;
  }
}

/// Paints a dashed circle border for the [ManaPipState.deselected] state.
class _DashedCirclePainter extends CustomPainter {
  _DashedCirclePainter({
    required this.color,
    required this.strokeWidth,
    required this.radius,
  });

  final Color color;
  final double strokeWidth;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final center = Offset(size.width / 2, size.height / 2);
    const dashCount = 12;
    const gapFraction = 0.3;
    final totalArc = 2 * 3.141592653589793;
    final dashArc = totalArc / dashCount * (1 - gapFraction);
    final gapArc = totalArc / dashCount * gapFraction;

    final rect = Rect.fromCircle(
      center: center,
      radius: radius - strokeWidth / 2,
    );

    for (var i = 0; i < dashCount; i++) {
      final startAngle = i * (dashArc + gapArc);
      canvas.drawArc(rect, startAngle, dashArc, false, paint);
    }
  }

  @override
  bool shouldRepaint(_DashedCirclePainter oldDelegate) =>
      color != oldDelegate.color ||
      strokeWidth != oldDelegate.strokeWidth ||
      radius != oldDelegate.radius;
}
