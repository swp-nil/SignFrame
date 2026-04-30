import 'package:flutter/material.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:provider/provider.dart';

import '../../providers/player_session_provider.dart';

// video player view port
class VideoViewport extends StatelessWidget {
  const VideoViewport({super.key});

  @override
  Widget build(BuildContext context) {
    final session = context.watch<PlayerSessionProvider>();

    return Expanded(
      child: Container(
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.5),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Video(controller: session.controller),
      ),
    );
  }
}
