import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/video_metadata.dart';
import '../providers/player_session_provider.dart';
import '../providers/project_state.dart';
import '../theme/app_colors.dart';
import '../utils/shortcuts.dart';
import '../widgets/player/annotation_controls.dart';
import '../widgets/player/playback_controls.dart';
import '../widgets/player/sidebar_widget.dart';
import '../widgets/player/timeline_slider.dart';
import '../widgets/player/video_viewport.dart';

class PlayerScreen extends StatelessWidget {
  final VideoMetadata video;

  const PlayerScreen({super.key, required this.video});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (ctx) => PlayerSessionProvider(video: video, context: ctx),
      child: const _PlayerScreenContent(),
    );
  }
}

class _PlayerScreenContent extends StatelessWidget {
  const _PlayerScreenContent();

  @override
  Widget build(BuildContext context) {
    final session = context.watch<PlayerSessionProvider>();
    final colorScheme = Theme.of(context).colorScheme;

    return Shortcuts(
      shortcuts: appShortcuts,
      child: Actions(
        actions: <Type, Action<Intent>>{
          PlayPauseIntent: CallbackAction<PlayPauseIntent>(
            onInvoke: (_) => session.player.playOrPause(),
          ),
          SkipBackIntent: CallbackAction<SkipBackIntent>(
            onInvoke: (_) => session.skipBack(),
          ),
          SkipForwardIntent: CallbackAction<SkipForwardIntent>(
            onInvoke: (_) => session.skipForward(),
          ),
          MarkStartIntent: CallbackAction<MarkStartIntent>(
            onInvoke: (_) => session.markStart(),
          ),
          MarkEndIntent: CallbackAction<MarkEndIntent>(
            onInvoke: (_) => session.markEnd(),
          ),
          CancelAnnotationIntent: CallbackAction<CancelAnnotationIntent>(
            onInvoke: (_) => session.cancelAnnotation(),
          ),
          SaveAnnotationsIntent: CallbackAction<SaveAnnotationsIntent>(
            onInvoke: (_) => session.saveAnnotations(),
          ),
        },
        child: Focus(
          autofocus: true,
          child: Scaffold(
            backgroundColor: AppColors.background,
            appBar: _buildAppBar(context, session, colorScheme),
            body: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Column(
                    children: [
                      const VideoViewport(),
                      _buildControls(context, session, colorScheme),
                    ],
                  ),
                ),
                const SidebarWidget(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(
    BuildContext context,
    PlayerSessionProvider session,
    ColorScheme colorScheme,
  ) {
    return AppBar(
      backgroundColor: AppColors.surface,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => Navigator.pop(context),
      ),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: colorScheme.primary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              ProjectState.extractGloss(session.video.name),
              style: TextStyle(
                color: colorScheme.primary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              session.video.name,
              style: const TextStyle(fontSize: 16),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
      actions: [
        TextButton.icon(
          onPressed: session.saveAnnotations,
          icon: Icon(Icons.save_outlined, color: colorScheme.primary, size: 18),
          label: Text('Save', style: TextStyle(color: colorScheme.primary)),
        ),
        const SizedBox(width: 8),
        Consumer<ProjectState>(
          builder: (context, state, _) {
            final isCompleted = state.isVideoCompleted(session.video.name);
            return Container(
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: isCompleted
                    ? Colors.green.withValues(alpha: 0.15)
                    : Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(8),
              ),
              child: InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () => state.toggleVideoCompleted(session.video.name),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isCompleted
                            ? Icons.check_circle
                            : Icons.circle_outlined,
                        color: isCompleted ? Colors.green : Colors.white54,
                        size: 18,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        isCompleted ? 'Done' : 'Mark Done',
                        style: TextStyle(
                          color: isCompleted ? Colors.green : Colors.white70,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildControls(
    BuildContext context,
    PlayerSessionProvider session,
    ColorScheme colorScheme,
  ) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: StreamBuilder<Duration>(
        stream: session.player.stream.position,
        builder: (context, snapshot) {
          final position = snapshot.data ?? Duration.zero;
          final duration = session.player.state.duration;

          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TimelineSlider(position: position, duration: duration),
              const SizedBox(height: 20),
              const PlaybackControls(),
              const SizedBox(height: 16),
              const Divider(height: 1),
              const SizedBox(height: 16),
              const AnnotationControls(),
            ],
          );
        },
      ),
    );
  }
}
