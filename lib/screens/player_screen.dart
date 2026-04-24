import 'dart:async';

import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:path/path.dart' as p;
import 'package:provider/provider.dart';

import '../models/annotation_model.dart';
import '../models/video_metadata.dart';
import '../providers/project_state.dart';
import '../theme/app_colors.dart';
import '../widgets/instance_painter.dart';

class PlayerScreen extends StatefulWidget {
  final VideoMetadata video;

  const PlayerScreen({super.key, required this.video});

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  late final Player _player;
  late final VideoController _controller;

  // Annotation state
  Duration? _startMarker;
  Duration? _endMarker;
  double _fps = 60.0; // not even going to bother with this

  bool _isAnnotating = false;
  double _savedRate = 1.0;
  double _slowMoSpeed = 0.25;

  String? _sidebarMessage;
  Instance? _playingInstance;

  StreamSubscription? _tracksSub;
  StreamSubscription? _positionSub;
  StreamSubscription? _completedSub;

  @override
  void initState() {
    super.initState();
    _player = Player();
    _controller = VideoController(_player);
    _initializeVideo();
  }

  Future<void> _initializeVideo() async {
    await _player.open(Media(widget.video.path));

    _tracksSub = _player.stream.tracks.listen((tracks) {
      if (!mounted) return;
      final videoTrack = tracks.video.firstOrNull;
      if (videoTrack != null) {
        // If fps property exists:
        if (videoTrack.fps != null && videoTrack.fps! > 0) {
          setState(() {
            _fps = videoTrack.fps!;
          });
        }
        // fallback to parsing if direct access fails or is missing (API version diffs)
        else {
          final str = videoTrack.toString();
          final match = RegExp(
            r'(?:frameRate|fps):\s*(\d+(\.\d+)?)',
          ).firstMatch(str);
          if (match != null) {
            final val = double.tryParse(match.group(1)!);
            if (val != null && val > 0) {
              setState(() {
                _fps = val;
              });
            }
          }
        }
      }
    });

    // listen for position changes to stop at instance end
    _positionSub = _player.stream.position.listen((position) {
      if (_playingInstance != null) {
        final endMs = _playingInstance!.endMs;
        if (position.inMilliseconds >= endMs) {
          _player.pause();
          setState(() => _playingInstance = null);
        }
      }
    });

    _completedSub = _player.stream.completed.listen((completed) {
      if (completed) {
        setState(() => _playingInstance = null);
      }
    });
  }

  @override
  void dispose() {
    _tracksSub?.cancel();
    _positionSub?.cancel();
    _completedSub?.cancel();
    _player.dispose();
    super.dispose();
  }

  void _showSidebarMessage(String message) {
    setState(() => _sidebarMessage = message);
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted && _sidebarMessage == message) {
        setState(() => _sidebarMessage = null);
      }
    });
  }

  void _playInstance(Instance inst) {
    setState(() => _playingInstance = inst);
    _player.seek(Duration(milliseconds: inst.startMs));
    _player.play();
    _showSidebarMessage(
      'Playing instance #${inst.instanceId.toString().padLeft(3, '0')}',
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
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
                ProjectState.extractGloss(widget.video.name),
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
                widget.video.name,
                style: const TextStyle(fontSize: 16),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        actions: [
          TextButton.icon(
            onPressed: () {
              context.read<ProjectState>().saveAnnotations();
              _showSidebarMessage('Annotations saved');
            },

            icon: Icon(
              Icons.save_outlined,
              color: colorScheme.primary,
              size: 18,
            ),
            label: Text('Save', style: TextStyle(color: colorScheme.primary)),
          ),
          const SizedBox(width: 8),
          // Completion toggle
          Consumer<ProjectState>(
            builder: (context, state, _) {
              final isCompleted = state.isVideoCompleted(widget.video.name);
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
                  onTap: () => state.toggleVideoCompleted(widget.video.name),
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
      ),
      body: Row(
        children: [
          // Main Content: Player + Controls
          Expanded(
            flex: 3,
            child: Column(
              children: [
                // Video Player
                Expanded(
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
                    child: Video(controller: _controller),
                  ),
                ),
                // Controls
                _buildControls(colorScheme),
              ],
            ),
          ),
          // Sidebar: Instances
          _buildSidebar(colorScheme),
        ],
      ),
    );
  }

  Widget _buildSidebar(ColorScheme colorScheme) {
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
          // Sidebar Header
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
                        .getInstancesForVideo(widget.video.name)
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
                final instances = state.getInstancesForVideo(widget.video.name);
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
                          onTap: () {
                            _player.seek(Duration(milliseconds: startMs));
                          },
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.05),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      height: 28,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.cyanAccent.withValues(
                                          alpha: 0.2,
                                        ),
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
                                    // Play instance button
                                    Material(
                                      color: colorScheme.primary.withValues(
                                        alpha: 0.15,
                                      ),
                                      borderRadius: BorderRadius.circular(6),
                                      child: InkWell(
                                        onTap: () => _playInstance(inst),
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
                                    // Delete instance button
                                    Material(
                                      color: colorScheme.error.withValues(
                                        alpha: 0.1,
                                      ),
                                      borderRadius: BorderRadius.circular(6),
                                      child: InkWell(
                                        onTap: () {
                                          state.removeInstance(
                                            widget.video.name,
                                            inst,
                                          );
                                          _showSidebarMessage(
                                            'Instance deleted',
                                          );
                                        },
                                        borderRadius: BorderRadius.circular(6),
                                        child: Container(
                                          height: 28,
                                          width: 28,
                                          alignment: Alignment.center,
                                          child: Icon(
                                            Icons.delete_outline,
                                            color: colorScheme.error.withValues(
                                              alpha: 0.7,
                                            ),
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
                                      _formatDuration(
                                        Duration(milliseconds: startMs),
                                      ),
                                      colorScheme.primary,
                                    ),
                                    const SizedBox(width: 8),
                                    Icon(
                                      Icons.arrow_forward,
                                      size: 14,
                                      color: Colors.white.withValues(
                                        alpha: 0.3,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    _buildTimeChip(
                                      'End',
                                      _formatDuration(
                                        Duration(milliseconds: endMs),
                                      ),
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
                  },
                );
              },
            ),
          ),
          // Sidebar notification
          if (_sidebarMessage != null)
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
                      _sidebarMessage!,
                      style: const TextStyle(
                        color: Colors.orange,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => setState(() => _sidebarMessage = null),
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

  Widget _buildControls(ColorScheme colorScheme) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: StreamBuilder<Duration>(
        stream: _player.stream.position,
        builder: (context, snapshot) {
          final position = snapshot.data ?? Duration.zero;
          final duration = _player.state.duration;

          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Timeline with markers
              _buildTimeline(position, duration, colorScheme),
              const SizedBox(height: 20),
              // Playback Controls
              _buildPlaybackControls(position, colorScheme),
              const SizedBox(height: 16),
              const Divider(height: 1),
              const SizedBox(height: 16),
              // Annotation Controls
              _buildAnnotationControls(position, colorScheme),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTimeline(
    Duration position,
    Duration duration,
    ColorScheme colorScheme,
  ) {
    return Column(
      children: [
        // Time display
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              _formatDuration(position),
              style: TextStyle(
                color: colorScheme.primary,
                fontSize: 13,
                fontFamily: 'monospace',
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              _formatDuration(duration),
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.5),
                fontSize: 13,
                fontFamily: 'monospace',
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        // Seek bar with instance overlay
        Consumer<ProjectState>(
          builder: (context, state, _) {
            final instances = state.getInstancesForVideo(widget.video.name);
            return LayoutBuilder(
              builder: (context, constraints) {
                return Stack(
                  alignment: Alignment.centerLeft,
                  children: [
                    // Instance markers (must match slider track)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: CustomPaint(
                        size: Size(constraints.maxWidth - 24, 8),
                        painter: InstancePainter(
                          instances: instances,
                          videoDuration: duration,
                          fps: _fps,
                        ),
                      ),
                    ),
                    // Slider
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
                          _player.seek(Duration(milliseconds: value.toInt()));
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

  Widget _buildPlaybackControls(Duration position, ColorScheme colorScheme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Skip back
        _buildControlButton(
          icon: Icons.replay_5,
          onPressed: () {
            final target = position - const Duration(seconds: 1);
            _player.seek(target < Duration.zero ? Duration.zero : target);
          },
          tooltip: 'Back 1s',
        ),
        const SizedBox(width: 12),
        // Play/Pause
        StreamBuilder<bool>(
          stream: _player.stream.playing,
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
                onPressed: () => _player.playOrPause(),
              ),
            );
          },
        ),
        const SizedBox(width: 12),
        // Skip forward
        _buildControlButton(
          icon: Icons.forward_5,
          onPressed: () {
            final duration = _player.state.duration;
            final target = position + const Duration(seconds: 1);
            _player.seek(target > duration ? duration : target);
          },
          tooltip: 'Forward 1s',
        ),
        const SizedBox(width: 24),
        // Speed control - segmented button style
        StreamBuilder<double>(
          stream: _player.stream.rate,
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
                  // SPEED label
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
                  // Speed buttons
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
                          onTap: () => _player.setRate(speed),
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

  Widget _buildAnnotationControls(Duration position, ColorScheme colorScheme) {
    return Row(
      children: [
        // main action button
        Expanded(child: _buildMainActionButton(position, colorScheme)),
        const SizedBox(width: 12),
        // slow-mo speed selector
        Container(
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: _isAnnotating
                ? Colors.orange.withValues(alpha: 0.15)
                : Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(10),
            border: _isAnnotating
                ? Border.all(color: Colors.orange.withValues(alpha: 0.3))
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.slow_motion_video,
                size: 16,
                color: _isAnnotating ? Colors.orange : Colors.white54,
              ),
              const SizedBox(width: 6),
              DropdownButtonHideUnderline(
                child: DropdownButton<double>(
                  value: _slowMoSpeed,
                  isDense: true,
                  dropdownColor: AppColors.surfaceElevated,
                  icon: Icon(
                    Icons.arrow_drop_down,
                    color: _isAnnotating ? Colors.orange : Colors.white54,
                    size: 18,
                  ),
                  items: const [0.1, 0.15, 0.25, 0.5].map((speed) {
                    return DropdownMenuItem(
                      value: speed,
                      child: Text(
                        '${speed}x',
                        style: TextStyle(
                          color: speed == _slowMoSpeed
                              ? (_isAnnotating ? Colors.orange : Colors.white)
                              : Colors.white54,
                          fontSize: 13,
                          fontWeight: speed == _slowMoSpeed
                              ? FontWeight.w600
                              : FontWeight.normal,
                        ),
                      ),
                    );
                  }).toList(),
                  onChanged: (speed) {
                    if (speed != null) {
                      setState(() {
                        _slowMoSpeed = speed;
                      });
                      if (_isAnnotating) {
                        _player.setRate(speed);
                      }
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMainActionButton(Duration position, ColorScheme colorScheme) {
    if (!_isAnnotating) {
      // start button
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
            onTap: () {
              setState(() {
                _startMarker = position;
                _endMarker = null;
                _isAnnotating = true;
                _savedRate = _player.state.rate;
              });
              _player.setRate(_slowMoSpeed);
            },
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
                onTap: () {
                  setState(() {
                    _startMarker = null;
                    _endMarker = null;
                    _isAnnotating = false;
                  });
                  _player.setRate(_savedRate);
                },
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
                  onTap: () {
                    final endPos = position;
                    if (_startMarker != null && endPos > _startMarker!) {
                      setState(() {
                        _endMarker = endPos;
                      });
                      _addInstance();
                      setState(() {
                        _startMarker = null;
                        _endMarker = null;
                        _isAnnotating = false;
                      });
                      _player.setRate(_savedRate);
                    } else {
                      _showSidebarMessage('End must be after start');
                    }
                  },
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



  void _addInstance() {
    final state = context.read<ProjectState>();
    final instances = state.getInstancesForVideo(widget.video.name);

    int nextId = 1;
    if (instances.isNotEmpty) {
      int maxId = 0;
      for (var i in instances) {
        if (i.instanceId > maxId) maxId = i.instanceId;
      }
      nextId = maxId + 1;
    }

    final fileBaseName = p.basenameWithoutExtension(widget.video.name);
    final videoId = "${fileBaseName}_${nextId.toString().padLeft(3, '0')}";

    final startFrame = (_startMarker!.inMilliseconds / 1000 * _fps).round();
    final endFrame = (_endMarker!.inMilliseconds / 1000 * _fps).round();

    final newInstance = Instance(
      fps: _fps,
      frameStart: startFrame,
      frameEnd: endFrame,
      startMs: _startMarker!.inMilliseconds,
      endMs: _endMarker!.inMilliseconds,
      instanceId: nextId,
      source: widget.video.name,
      videoId: videoId,
    );

    state.addInstance(widget.video.name, newInstance);

    _showSidebarMessage('Instance #${nextId.toString().padLeft(3, '0')} added');
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.toString().padLeft(2, '0');
    final seconds = (d.inSeconds % 60).toString().padLeft(2, '0');
    final millis = (d.inMilliseconds % 1000).toString().padLeft(3, '0');
    return "$minutes:$seconds.$millis";
  }
}
