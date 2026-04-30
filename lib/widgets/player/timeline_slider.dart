import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/player_session_provider.dart';
import '../../providers/project_state.dart';
import 'instance_painter.dart';

// timeline scrubber with instance overlay and time labels
class TimelineSlider extends StatelessWidget {
  final Duration position;
  final Duration duration;

  const TimelineSlider({
    super.key,
    required this.position,
    required this.duration,
  });

  @override
  Widget build(BuildContext context) {
    final session = context.watch<PlayerSessionProvider>();
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              session.formatDuration(position),
              style: TextStyle(
                color: colorScheme.primary,
                fontSize: 13,
                fontFamily: 'monospace',
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              session.formatDuration(duration),
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.5),
                fontSize: 13,
                fontFamily: 'monospace',
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Consumer<ProjectState>(
          builder: (context, state, _) {
            final instances = state.getInstancesForVideo(session.video.name);
            return LayoutBuilder(
              builder: (context, constraints) {
                return Stack(
                  alignment: Alignment.centerLeft,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: CustomPaint(
                        size: Size(constraints.maxWidth - 24, 8),
                        painter: InstancePainter(
                          instances: instances,
                          videoDuration: duration,
                          fps: session.fps,
                        ),
                      ),
                    ),
                    SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        trackHeight: 8,
                        thumbShape: const RoundSliderThumbShape(
                          enabledThumbRadius: 8,
                        ),
                        overlayShape: const RoundSliderOverlayShape(
                          overlayRadius: 16,
                        ),
                        activeTrackColor: colorScheme.primary.withValues(
                          alpha: 0.5,
                        ),
                        inactiveTrackColor: Colors.white.withValues(alpha: 0.1),
                      ),
                      child: Slider(
                        value: position.inMilliseconds.toDouble().clamp(
                          0,
                          duration.inMilliseconds.toDouble(),
                        ),
                        min: 0,
                        max: duration.inMilliseconds.toDouble(),
                        onChanged: (value) {
                          session.player.seek(
                            Duration(milliseconds: value.toInt()),
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            );
          },
        ),
      ],
    );
  }
}
