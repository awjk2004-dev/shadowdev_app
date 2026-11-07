import 'dart:math' as math;
import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

Path chamferedPath(Rect rect, double cut) {
  final c = math.min(cut, math.min(rect.width, rect.height) / 2);
  return Path()
    ..moveTo(rect.left + c, rect.top)
    ..lineTo(rect.right - c, rect.top)
    ..lineTo(rect.right, rect.top + c)
    ..lineTo(rect.right, rect.bottom - c)
    ..lineTo(rect.right - c, rect.bottom)
    ..lineTo(rect.left + c, rect.bottom)
    ..lineTo(rect.left, rect.bottom - c)
    ..lineTo(rect.left, rect.top + c)
    ..close();
}

void drawDashedPath(
  Canvas canvas,
  Path path,
  Paint paint, {
  double dash = 6,
  double gap = 4,
}) {
  for (final metric in path.computeMetrics()) {
    var distance = 0.0;
    while (distance < metric.length) {
      final end = math.min(distance + dash, metric.length);
      canvas.drawPath(metric.extractPath(distance, end), paint);
      distance = end + gap;
    }
  }
}

/// A sharp, cut-corner frame used across the whole System UI.
///
/// The border can be solid (active), dashed (locked), and can render a cheap
/// two-stroke glow without any blur or multi-layer shadow.
class ChamferedBorder extends OutlinedBorder {
  const ChamferedBorder({
    super.side,
    this.cut = 12,
    this.dashed = false,
    this.glow = false,
  });

  @override
  ChamferedBorder copyWith({
    BorderSide? side,
    double? cut,
    bool? dashed,
    bool? glow,
  }) {
    return ChamferedBorder(
      side: side ?? this.side,
      cut: cut ?? this.cut,
      dashed: dashed ?? this.dashed,
      glow: glow ?? this.glow,
    );
  }

  final double cut;
  final bool dashed;
  final bool glow;

  @override
  EdgeInsetsGeometry get dimensions => EdgeInsets.all(side.width);

  @override
  ShapeBorder scale(double t) => ChamferedBorder(
        side: side.scale(t),
        cut: cut * t,
        dashed: dashed,
        glow: glow,
      );

  @override
  ShapeBorder? lerpFrom(ShapeBorder? a, double t) {
    if (a is ChamferedBorder) {
      return ChamferedBorder(
        side: BorderSide.lerp(a.side, side, t),
        cut: lerpDouble(a.cut, cut, t)!,
        dashed: t < 0.5 ? a.dashed : dashed,
        glow: t < 0.5 ? a.glow : glow,
      );
    }
    return super.lerpFrom(a, t);
  }

  @override
  ShapeBorder? lerpTo(ShapeBorder? b, double t) {
    if (b is ChamferedBorder) {
      return ChamferedBorder(
        side: BorderSide.lerp(side, b.side, t),
        cut: lerpDouble(cut, b.cut, t)!,
        dashed: t < 0.5 ? dashed : b.dashed,
        glow: t < 0.5 ? glow : b.glow,
      );
    }
    return super.lerpTo(b, t);
  }

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) {
    return chamferedPath(rect, cut);
  }

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) {
    final inset = math.min(cut, rect.shortestSide / 2);
    return chamferedPath(
      rect.deflate(side.width),
      math.max(0, cut - inset * 0.35),
    );
  }

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {
    if (side.style == BorderStyle.none || side.width <= 0) return;

    final path = getOuterPath(
      rect.deflate(side.width / 2),
      textDirection: textDirection,
    );
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = side.width
      ..strokeCap = StrokeCap.square
      ..color = side.color;

    if (glow) {
      canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = side.width + 5
          ..color = side.color.withValues(alpha: 0.16),
      );
    }

    if (dashed) {
      drawDashedPath(canvas, path, stroke, dash: 7, gap: 5);
    } else {
      canvas.drawPath(path, stroke);
    }
  }

  @override
  bool operator ==(Object other) {
    return other is ChamferedBorder &&
        other.side == side &&
        other.cut == cut &&
        other.dashed == dashed &&
        other.glow == glow;
  }

  @override
  int get hashCode => Object.hash(side, cut, dashed, glow);
}

class ChamferedClipper extends CustomClipper<Path> {
  const ChamferedClipper({this.cut = 12});

  final double cut;

  @override
  Path getClip(Size size) => chamferedPath(Offset.zero & size, cut);

  @override
  bool shouldReclip(covariant ChamferedClipper oldClipper) {
    return oldClipper.cut != cut;
  }
}
