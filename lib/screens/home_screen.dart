import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

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
          // GitHub link - subtle
          IconButton(
            onPressed: () =>
                launchUrl(Uri.parse('https://github.com/swp-nil/SignFrame')),
            icon: Icon(
              Icons.code,
              size: 20,
              color: Colors.white.withValues(alpha: 0.4),
            ),
            tooltip: 'View on GitHub',
          ),
          const SizedBox(width: 4),
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
    // group videos by gloss
    final Map<String, List<dynamic>> glossGroups = {};
    for (final video in state.videos) {
      final gloss = _extractGloss(video.name);
      glossGroups.putIfAbsent(gloss, () => []);
      glossGroups[gloss]!.add(video);
    }

    // sort glosses alphabetically
    final sortedGlosses = glossGroups.keys.toList()..sort();

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
                  color: colorScheme.secondary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  '${sortedGlosses.length} glosses',
                  style: TextStyle(
                    color: colorScheme.secondary,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
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
        // Grouped video list
        Expanded(
          child: state.videos.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.videocam_off_outlined,
                        size: 64,
                        color: Colors.white.withValues(alpha: 0.3),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No videos found',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.7),
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '＼（〇_ｏ）／',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.5),
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        'This folder doesn\'t contain any video files',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.5),
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 24),
                      OutlinedButton.icon(
                        onPressed: () => _pickFolder(context),
                        icon: const Icon(Icons.folder_open, size: 18),
                        label: const Text('Choose Another Folder'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: colorScheme.primary,
                          side: BorderSide(
                            color: colorScheme.primary.withValues(alpha: 0.5),
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: sortedGlosses.length,
                  itemBuilder: (context, index) {
                    final gloss = sortedGlosses[index];
                    final videos = glossGroups[gloss]!;
                    return _buildGlossGroup(
                      context,
                      state,
                      colorScheme,
                      gloss,
                      videos,
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildGlossGroup(
    BuildContext context,
    ProjectState state,
    ColorScheme colorScheme,
    String gloss,
    List<dynamic> videos,
  ) {
    // Calculate stats for this gloss group
    int totalInstances = 0;
    int completedCount = 0;
    for (final video in videos) {
      totalInstances += state.getInstancesForVideo(video.name).length;
      if (state.isVideoCompleted(video.name)) {
        completedCount++;
      }
    }
    final allCompleted = completedCount == videos.length && completedCount > 0;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF161B22),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: allCompleted
                ? Colors.green.withValues(alpha: 0.3)
                : totalInstances > 0
                ? colorScheme.primary.withValues(alpha: 0.2)
                : Colors.white.withValues(alpha: 0.1),
          ),
        ),
        child: Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            tilePadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 4,
            ),
            childrenPadding: const EdgeInsets.only(
              left: 16,
              right: 16,
              bottom: 12,
            ),
            leading: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: allCompleted
                    ? Colors.green.withValues(alpha: 0.15)
                    : totalInstances > 0
                    ? colorScheme.primary.withValues(alpha: 0.15)
                    : Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                allCompleted
                    ? Icons.check_circle
                    : totalInstances > 0
                    ? Icons.sign_language
                    : Icons.gesture,
                color: allCompleted
                    ? Colors.green
                    : totalInstances > 0
                    ? colorScheme.primary
                    : Colors.white54,
                size: 22,
              ),
            ),
            title: Text(
              gloss.toUpperCase(),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: allCompleted
                    ? Colors.white.withValues(alpha: 0.7)
                    : Colors.white,
                letterSpacing: 0.5,
              ),
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Row(
                children: [
                  // Video count
                  _buildStatChip(
                    '${videos.length} video${videos.length > 1 ? 's' : ''}',
                    Colors.white54,
                    Colors.white.withValues(alpha: 0.05),
                  ),
                  const SizedBox(width: 8),
                  // Instance count
                  if (totalInstances > 0)
                    _buildStatChip(
                      '$totalInstances instance${totalInstances > 1 ? 's' : ''}',
                      colorScheme.primary,
                      colorScheme.primary.withValues(alpha: 0.15),
                    ),
                  const SizedBox(width: 8),
                  // Completion status
                  if (completedCount > 0)
                    _buildStatChip(
                      '$completedCount/${videos.length} done',
                      Colors.green,
                      Colors.green.withValues(alpha: 0.15),
                    ),
                ],
              ),
            ),
            iconColor: Colors.white54,
            collapsedIconColor: Colors.white54,
            children: videos.map<Widget>((video) {
              return _buildVideoItem(context, state, colorScheme, video);
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildStatChip(String text, Color textColor, Color bgColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: textColor,
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildVideoItem(
    BuildContext context,
    ProjectState state,
    ColorScheme colorScheme,
    dynamic video,
  ) {
    final instances = state.getInstancesForVideo(video.name);
    final hasAnnotations = instances.isNotEmpty;
    final isCompleted = state.isVideoCompleted(video.name);

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Material(
        color: const Color(0xFF21262D),
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => PlayerScreen(video: video)),
            );
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isCompleted
                    ? Colors.green.withValues(alpha: 0.3)
                    : hasAnnotations
                    ? colorScheme.primary.withValues(alpha: 0.2)
                    : Colors.transparent,
              ),
            ),
            child: Row(
              children: [
                // Status icon
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: isCompleted
                        ? Colors.green.withValues(alpha: 0.15)
                        : hasAnnotations
                        ? colorScheme.primary.withValues(alpha: 0.15)
                        : Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(
                    isCompleted
                        ? Icons.check_circle
                        : hasAnnotations
                        ? Icons.edit_note
                        : Icons.movie_outlined,
                    color: isCompleted
                        ? Colors.green
                        : hasAnnotations
                        ? colorScheme.primary
                        : Colors.white38,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                // Video name
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        video.name,
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 13,
                          color: isCompleted
                              ? Colors.white.withValues(alpha: 0.5)
                              : Colors.white.withValues(alpha: 0.9),
                        ),
                      ),
                      if (hasAnnotations)
                        Text(
                          '${instances.length} instance${instances.length > 1 ? 's' : ''}',
                          style: TextStyle(
                            color: isCompleted
                                ? Colors.white.withValues(alpha: 0.3)
                                : colorScheme.primary.withValues(alpha: 0.8),
                            fontSize: 11,
                          ),
                        ),
                    ],
                  ),
                ),
                // Arrow
                Icon(
                  Icons.chevron_right,
                  color: Colors.white.withValues(alpha: 0.3),
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _extractGloss(String filename) {
    // Remove extension
    final name = filename.replaceAll(
      RegExp(r'\.(mp4|mov|avi|mkv)$', caseSensitive: false),
      '',
    );
    // Split by '_' and remove last part if it's a signer ID (with optional version suffix)
    // Matches: "001", "42", "001v2", "001_v3", etc.
    final parts = name.split('_');
    if (parts.length > 1) {
      final lastPart = parts.last;
      // Check if last part is numeric with optional version suffix (e.g., "001", "42", "001v2")
      if (RegExp(r'^\d+(v\d+)?$', caseSensitive: false).hasMatch(lastPart)) {
        return parts.sublist(0, parts.length - 1).join('_');
      }
    }
    return name;
  }
}
