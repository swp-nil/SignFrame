import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/project_state.dart';
import 'player_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  Future<void> _pickFolder(BuildContext context) async {
    String? selectedDirectory = await FilePicker.platform.getDirectoryPath();
    if (selectedDirectory != null) {
      if (context.mounted) {
        context.read<ProjectState>().setFolderPath(selectedDirectory);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<ProjectState>();
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [colorScheme.primary, colorScheme.secondary],
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.sign_language,
                size: 20,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 12),
            const Text('SignFrame'),
          ],
        ),
        actions: [
          if (state.currentFolderPath != null)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: TextButton.icon(
                onPressed: () => _pickFolder(context),
                icon: const Icon(Icons.folder_open, size: 18),
                label: const Text('Change Folder'),
                style: TextButton.styleFrom(foregroundColor: Colors.white70),
              ),
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: state.isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: colorScheme.primary),
                  const SizedBox(height: 16),
                  Text(
                    'Loading videos...',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            )
          : state.currentFolderPath == null
          ? _buildEmptyState(context, colorScheme)
          : state.errorMessage != null
          ? _buildErrorState(context, state.errorMessage!)
          : _buildVideoList(context, state, colorScheme),
    );
  }

  Widget _buildEmptyState(BuildContext context, ColorScheme colorScheme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  colorScheme.primary.withValues(alpha: 0.2),
                  colorScheme.secondary.withValues(alpha: 0.2),
                ],
              ),
            ),
            child: Icon(
              Icons.video_library_outlined,
              size: 64,
              color: colorScheme.primary,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Welcome to SignFrame',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Select a folder containing sign language videos to begin annotating',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.6),
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () => _pickFolder(context),
            icon: const Icon(Icons.folder_open),
            label: const Text('Select Folder'),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Theme.of(context).colorScheme.error,
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _pickFolder(context),
            icon: const Icon(Icons.refresh),
            label: const Text('Try Again'),
          ),
        ],
      ),
    );
  }

  Widget _buildVideoList(
    BuildContext context,
    ProjectState state,
    ColorScheme colorScheme,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header with folder info
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF161B22),
            border: Border(
              bottom: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
            ),
          ),
          child: Row(
            children: [
              Icon(Icons.folder, color: colorScheme.primary, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  state.currentFolderPath ?? '',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 13,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.check_circle,
                      color: Colors.green,
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${state.completedVideos.length}',
                      style: const TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  '${state.videos.length} videos',
                  style: TextStyle(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
        // Video list
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: state.videos.length,
            itemBuilder: (context, index) {
              final video = state.videos[index];
              final instances = state.getInstancesForVideo(video.name);
              final hasAnnotations = instances.isNotEmpty;
              final isCompleted = state.isVideoCompleted(video.name);

              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Material(
                  color: const Color(0xFF161B22),
                  borderRadius: BorderRadius.circular(12),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => PlayerScreen(video: video),
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isCompleted
                              ? Colors.green.withValues(alpha: 0.3)
                              : hasAnnotations
                              ? colorScheme.primary.withValues(alpha: 0.3)
                              : Colors.white.withValues(alpha: 0.1),
                        ),
                      ),
                      child: Row(
                        children: [
                          // Video icon with status
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: isCompleted
                                  ? Colors.green.withValues(alpha: 0.15)
                                  : hasAnnotations
                                  ? colorScheme.primary.withValues(alpha: 0.15)
                                  : Colors.white.withValues(alpha: 0.05),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              isCompleted
                                  ? Icons.check_circle
                                  : hasAnnotations
                                  ? Icons.edit_note
                                  : Icons.movie_creation_outlined,
                              color: isCompleted
                                  ? Colors.green
                                  : hasAnnotations
                                  ? colorScheme.primary
                                  : Colors.white54,
                            ),
                          ),
                          const SizedBox(width: 16),
                          // Video info
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  video.name,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 15,
                                    color: isCompleted
                                        ? Colors.white.withValues(alpha: 0.6)
                                        : Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    if (isCompleted)
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 2,
                                        ),
                                        margin: const EdgeInsets.only(right: 8),
                                        decoration: BoxDecoration(
                                          color: Colors.green.withValues(
                                            alpha: 0.2,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            4,
                                          ),
                                        ),
                                        child: const Text(
                                          'Done',
                                          style: TextStyle(
                                            color: Colors.green,
                                            fontSize: 10,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    if (hasAnnotations)
                                      Text(
                                        '${instances.length} instance${instances.length > 1 ? 's' : ''}',
                                        style: TextStyle(
                                          color: isCompleted
                                              ? Colors.white.withValues(
                                                  alpha: 0.4,
                                                )
                                              : colorScheme.primary,
                                          fontSize: 12,
                                        ),
                                      )
                                    else
                                      Text(
                                        'Not annotated',
                                        style: TextStyle(
                                          color: Colors.white.withValues(
                                            alpha: 0.5,
                                          ),
                                          fontSize: 12,
                                        ),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          // Arrow
                          Icon(
                            Icons.chevron_right,
                            color: Colors.white.withValues(alpha: 0.5),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
