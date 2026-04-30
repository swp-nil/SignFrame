import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/annotation_model.dart';
import '../../providers/player_session_provider.dart';
import '../../providers/project_state.dart';
import '../../theme/app_colors.dart';

// sidebar - annotation list, instance cards, and notification bar
class SidebarWidget extends StatelessWidget {
  const SidebarWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final session = context.watch<PlayerSessionProvider>();
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: 320,
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(
          left: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.list_alt, color: colorScheme.primary, size: 20),
                const SizedBox(width: 8),
                const Text(
                  'Annotations',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                ),
                const Spacer(),
                Consumer<ProjectState>(
                  builder: (context, state, _) {
                    final count = state
                        .getInstancesForVideo(session.video.name)
                        .length;
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: colorScheme.primary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '$count',
                        style: TextStyle(
                          color: colorScheme.primary,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          // Instance List
          Expanded(
            child: Consumer<ProjectState>(
              builder: (context, state, child) {
                final instances = state.getInstancesForVideo(
                  session.video.name,
                );
                if (instances.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.add_circle_outline,
                          size: 48,
                          color: Colors.white.withValues(alpha: 0.2),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'No annotations yet',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.5),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Set start and end markers below',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.3),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: instances.length,
                  itemBuilder: (context, index) {
                    final inst = instances[index];
                    return _buildInstanceCard(
                      session,
                      state,
                      inst,
                      colorScheme,
                    );
                  },
                );
              },
            ),
          ),
          // Sidebar notification
          if (session.sidebarMessage != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.15),
                border: Border(
                  top: BorderSide(color: Colors.orange.withValues(alpha: 0.3)),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.info_outline,
                    size: 16,
                    color: Colors.orange,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      session.sidebarMessage!,
                      style: const TextStyle(
                        color: Colors.orange,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: session.dismissSidebarMessage,
                    child: Icon(
                      Icons.close,
                      size: 14,
                      color: Colors.orange.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildInstanceCard(
    PlayerSessionProvider session,
    ProjectState state,
    Instance inst,
    ColorScheme colorScheme,
  ) {
    final startMs = inst.startMs;
    final endMs = inst.endMs;
    final durationMs = endMs - startMs;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () => session.player.seek(Duration(milliseconds: startMs)),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      height: 28,
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(
                        color: Colors.cyanAccent.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '#${inst.instanceId.toString().padLeft(3, '0')}',
                        style: TextStyle(
                          color: Colors.cyanAccent,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Material(
                      color: colorScheme.primary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                      child: InkWell(
                        onTap: () => session.playInstance(inst),
                        borderRadius: BorderRadius.circular(6),
                        child: Container(
                          height: 28,
                          width: 28,
                          alignment: Alignment.center,
                          child: Icon(
                            Icons.play_arrow_rounded,
                            color: colorScheme.primary,
                            size: 18,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Material(
                      color: colorScheme.error.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                      child: InkWell(
                        onTap: () {
                          state.removeInstance(session.video.name, inst);
                          session.showSidebarMessage('Instance deleted');
                        },
                        borderRadius: BorderRadius.circular(6),
                        child: Container(
                          height: 28,
                          width: 28,
                          alignment: Alignment.center,
                          child: Icon(
                            Icons.delete_outline,
                            color: colorScheme.error.withValues(alpha: 0.7),
                            size: 16,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _buildTimeChip(
                      'Start',
                      session.formatDuration(Duration(milliseconds: startMs)),
                      colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      Icons.arrow_forward,
                      size: 14,
                      color: Colors.white.withValues(alpha: 0.3),
                    ),
                    const SizedBox(width: 8),
                    _buildTimeChip(
                      'End',
                      session.formatDuration(Duration(milliseconds: endMs)),
                      colorScheme.primary,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Duration: ${durationMs}ms • Frames: ${inst.frameStart}-${inst.frameEnd}',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.4),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTimeChip(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.4),
            fontSize: 10,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 13,
            fontWeight: FontWeight.w600,
            fontFamily: 'monospace',
          ),
        ),
      ],
    );
  }
}
