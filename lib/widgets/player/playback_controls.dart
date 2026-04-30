import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/player_session_provider.dart';
import '../../theme/app_colors.dart';

// Playback controls
class PlaybackControls extends StatelessWidget {
  const PlaybackControls({super.key});

  @override
  Widget build(BuildContext context) {
    final session = context.watch<PlayerSessionProvider>();
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildControlButton(
          icon: Icons.fast_rewind,
          onPressed: session.skipBack,
          tooltip: 'Back 1s',
        ),
        const SizedBox(width: 12),
        // Play/Pause
        StreamBuilder<bool>(
          stream: session.player.stream.playing,
          builder: (context, snapshot) {
            final playing = snapshot.data ?? false;
            return Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [colorScheme.primary, colorScheme.secondary],
                ),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: Icon(
                  playing ? Icons.pause : Icons.play_arrow,
                  color: Colors.white,
                ),
                iconSize: 32,
                onPressed: () => session.player.playOrPause(),
              ),
            );
          },
        ),
        const SizedBox(width: 12),
        _buildControlButton(
          icon: Icons.fast_forward,
          onPressed: session.skipForward,
          tooltip: 'Forward 1s',
        ),
        const SizedBox(width: 24),
        // Speed control
        StreamBuilder<double>(
          stream: session.player.stream.rate,
          builder: (context, snapshot) {
            final rate = snapshot.data ?? 1.0;
            return Container(
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    child: Text(
                      'SPEED',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.5),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.surfaceElevated,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    margin: const EdgeInsets.all(4),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [0.5, 1.0, 1.5, 2.0].map((speed) {
                        final isCurrentRate = rate == speed;
                        return GestureDetector(
                          onTap: () => session.player.setRate(speed),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: isCurrentRate
                                  ? Colors.white.withValues(alpha: 0.15)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              speed == 1.0 ? '1x' : '${speed}x',
                              style: TextStyle(
                                color: isCurrentRate
                                    ? Colors.white
                                    : Colors.white.withValues(alpha: 0.5),
                                fontSize: 12,
                                fontWeight: isCurrentRate
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required VoidCallback onPressed,
    String? tooltip,
  }) {
    return Tooltip(
      message: tooltip ?? '',
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(8),
        ),
        child: IconButton(
          icon: Icon(icon, size: 20),
          onPressed: onPressed,
          color: Colors.white70,
        ),
      ),
    );
  }
}
