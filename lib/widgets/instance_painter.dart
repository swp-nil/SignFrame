import 'package:flutter/material.dart';
import '../models/annotation_model.dart';

class InstancePainter extends CustomPainter {
  final double fps;
  final Duration videoDuration;
  final List<Instance> instances;

  InstancePainter({
    required this.instances,
    required this.videoDuration,
    this.fps = 60.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (videoDuration.inMilliseconds == 0) return;

    final totalMs = videoDuration.inMilliseconds.toDouble();

    for (int i = 0; i < instances.length; i++) {
      final inst = instances[i];
      final startMs = inst.startMs.toDouble();
      final endMs = inst.endMs.toDouble();

      final startX = (startMs / totalMs) * size.width;
      final width = ((endMs - startMs) / totalMs) * size.width;

      // Bright, visible colors - cyan/teal base with variation
      // final color = HSLColor.fromAHSL(
      //   1.0,
      //   (170 + i * 25) % 360, // cycle through hues starting at cyan
      //   0.9, // high saturation
      //   0.55, // brighter lightness
      // ).toColor();

      final color = Colors.greenAccent;

      final paint = Paint()
        ..color = color
        ..style = PaintingStyle.fill;

      // rounded rect for each instance
      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(startX, 0, width.clamp(4, double.infinity), size.height),
        const Radius.circular(4),
      );
      canvas.drawRRect(rect, paint);

      // add brighter border
      final borderPaint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;
      canvas.drawRRect(rect, borderPaint);
    }
  }

  @override
  bool shouldRepaint(covariant InstancePainter oldDelegate) {
    return oldDelegate.instances != instances ||
        oldDelegate.videoDuration != videoDuration;
  }
}
