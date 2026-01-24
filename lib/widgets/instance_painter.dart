import 'package:flutter/material.dart';
import '../models/annotation_model.dart';

class InstancePainter extends CustomPainter {
  final List<Instance> instances;
  final Duration videoDuration;
  final int fps;

  InstancePainter({
    required this.instances,
    required this.videoDuration,
    this.fps = 30,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (videoDuration.inMilliseconds == 0) return;

    final paint = Paint()
      ..color = const Color.fromARGB(255, 243, 72, 33).withValues(alpha: 0.5)
      ..style = PaintingStyle.fill;

    final totalMs = videoDuration.inMilliseconds.toDouble();

    for (var inst in instances) {
      final startMs = (inst.frameStart / fps * 1000);
      final endMs = (inst.frameEnd / fps * 1000);

      final startX = (startMs / totalMs) * size.width;
      final width = ((endMs - startMs) / totalMs) * size.width;

      canvas.drawRect(Rect.fromLTWH(startX, 0, width, size.height), paint);
    }
  }

  @override
  bool shouldRepaint(covariant InstancePainter oldDelegate) {
    return oldDelegate.instances != instances ||
        oldDelegate.videoDuration != videoDuration;
  }
}
