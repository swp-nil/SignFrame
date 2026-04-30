import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/player_session_provider.dart';
import '../../theme/app_colors.dart';

// Annotation controls - mark start/end, cancel and slow-mo selector
class AnnotationControls extends StatelessWidget {
  const AnnotationControls({super.key});

  @override
  Widget build(BuildContext context) {
    final session = context.watch<PlayerSessionProvider>();
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      children: [
        Expanded(child: _buildMainActionButton(session, colorScheme)),
        const SizedBox(width: 12),
        _buildSlowMoSelector(session),
      ],
    );
  }

  Widget _buildMainActionButton(
    PlayerSessionProvider session,
    ColorScheme colorScheme,
  ) {
    if (!session.isAnnotating) {
      return Container(
        height: 40,
        decoration: BoxDecoration(
          color: colorScheme.primary.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          child: InkWell(
            onTap: session.markStart,
            borderRadius: BorderRadius.circular(10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.flag, size: 16, color: colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'Mark Start',
                  style: TextStyle(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    } else {
      return Row(
        children: [
          // Cancel button
          Container(
            height: 40,
            decoration: BoxDecoration(
              color: Colors.red.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.red.withValues(alpha: 0.2)),
            ),
            child: Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(10),
              child: InkWell(
                onTap: session.cancelAnnotation,
                borderRadius: BorderRadius.circular(10),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.close,
                        size: 16,
                        color: Colors.red.withValues(alpha: 0.8),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Cancel',
                        style: TextStyle(
                          color: Colors.red.withValues(alpha: 0.8),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Mark End button
          Expanded(
            child: Container(
              height: 40,
              decoration: BoxDecoration(
                color: Colors.greenAccent.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Material(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(10),
                child: InkWell(
                  onTap: session.markEnd,
                  borderRadius: BorderRadius.circular(10),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check, size: 16, color: Colors.greenAccent),
                      SizedBox(width: 8),
                      Text(
                        'Mark End',
                        style: TextStyle(
                          color: Colors.greenAccent,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    }
  }

  Widget _buildSlowMoSelector(PlayerSessionProvider session) {
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: session.isAnnotating
            ? Colors.orange.withValues(alpha: 0.15)
            : Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(10),
        border: session.isAnnotating
            ? Border.all(color: Colors.orange.withValues(alpha: 0.3))
            : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.slow_motion_video,
            size: 16,
            color: session.isAnnotating ? Colors.orange : Colors.white54,
          ),
          const SizedBox(width: 6),
          DropdownButtonHideUnderline(
            child: DropdownButton<double>(
              value: session.slowMoSpeed,
              isDense: true,
              dropdownColor: AppColors.surfaceElevated,
              icon: Icon(
                Icons.arrow_drop_down,
                color: session.isAnnotating ? Colors.orange : Colors.white54,
                size: 18,
              ),
              items: const [0.1, 0.15, 0.25, 0.5].map((speed) {
                return DropdownMenuItem(
                  value: speed,
                  child: Text(
                    '${speed}x',
                    style: TextStyle(
                      color: speed == session.slowMoSpeed
                          ? (session.isAnnotating
                                ? Colors.orange
                                : Colors.white)
                          : Colors.white54,
                      fontSize: 13,
                      fontWeight: speed == session.slowMoSpeed
                          ? FontWeight.w600
                          : FontWeight.normal,
                    ),
                  ),
                );
              }).toList(),
              onChanged: (speed) {
                if (speed != null) session.setSlowMoSpeed(speed);
              },
            ),
          ),
        ],
      ),
    );
  }
}
