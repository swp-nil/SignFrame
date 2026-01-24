import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:provider/provider.dart';

import '../models/annotation_model.dart';
import '../models/video_metadata.dart';
import '../providers/project_state.dart';
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
  final int _fps = 30; // will try tio get from video metadata later

  @override
  void initState() {
    super.initState();
    _player = Player();
    _controller = VideoController(_player);
    _initializeVideo();
  }

  Future<void> _initializeVideo() async {
    await _player.open(Media(widget.video.path));
    // Listen to streams if needed, but Player handles most.
    _player.stream.completed.listen((completed) {
      if (completed) {
        // handle loop or stop
      }
    });
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.video.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: () {
              context.read<ProjectState>().saveAnnotations();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Annotations Saved")),
              );
            },
          ),
        ],
      ),
      body: Row(
        children: [
          Expanded(
            flex: 3,
            child: Column(
              children: [
                Expanded(
                  child: Center(child: Video(controller: _controller)),
                ),
                _buildControls(),
              ],
            ),
          ),
          // sidebar
          Container(
            width: 300,
            decoration: BoxDecoration(
              border: Border(
                left: BorderSide(color: Theme.of(context).dividerColor),
              ),
              color: Theme.of(context).colorScheme.surface,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    "Instances",
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                Expanded(
                  child: Consumer<ProjectState>(
                    builder: (context, state, child) {
                      final instances = state.getInstancesForVideo(
                        widget.video.name,
                      );
                      if (instances.isEmpty) {
                        return const Center(child: Text("No instances yet"));
                      }
                      return ListView.builder(
                        itemCount: instances.length,
                        itemBuilder: (context, index) {
                          final inst = instances[index];
                          final startMs = (inst.frameStart / inst.fps * 1000)
                              .round();
                          final endMs = (inst.frameEnd / inst.fps * 1000)
                              .round();

                          return Card(
                            margin: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            child: ListTile(
                              title: Text(inst.videoId),
                              subtitle: Text(
                                "Frames: ${inst.frameStart} - ${inst.frameEnd}\n"
                                "Time: ${_formatDuration(Duration(milliseconds: startMs))} - ${_formatDuration(Duration(milliseconds: endMs))}",
                              ),
                              isThreeLine: true,
                              trailing: IconButton(
                                icon: const Icon(
                                  Icons.delete,
                                  color: Colors.redAccent,
                                ),
                                onPressed: () {
                                  state.removeInstance(widget.video.name, inst);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text("Instance deleted"),
                                    ),
                                  );
                                },
                              ),
                              onTap: () {
                                _player.seek(Duration(milliseconds: startMs));
                              },
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControls() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Theme.of(context).cardColor,
      child: StreamBuilder<Duration>(
        stream: _player.stream.position,
        builder: (context, snapshot) {
          final position = snapshot.data ?? Duration.zero;
          final duration = _player.state.duration;

          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // seek Bar
              Row(
                children: [
                  Text(_formatDuration(position)),
                  Expanded(
                    child: Consumer<ProjectState>(
                      builder: (context, state, _) {
                        final instances = state.getInstancesForVideo(
                          widget.video.name,
                        );
                        return LayoutBuilder(
                          builder: (context, constraints) {
                            return Stack(
                              alignment: Alignment.centerLeft,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 24.0,
                                  ),
                                  child: CustomPaint(
                                    size: Size(constraints.maxWidth - 48, 10),
                                    painter: InstancePainter(
                                      instances: instances,
                                      videoDuration: duration,
                                      fps: _fps,
                                    ),
                                  ),
                                ),
                                Slider(
                                  value: position.inMilliseconds
                                      .toDouble()
                                      .clamp(
                                        0,
                                        duration.inMilliseconds.toDouble(),
                                      ),
                                  min: 0,
                                  max: duration.inMilliseconds.toDouble(),
                                  onChanged: (value) {
                                    _player.seek(
                                      Duration(milliseconds: value.toInt()),
                                    );
                                  },
                                ),
                              ],
                            );
                          },
                        );
                      },
                    ),
                  ),
                  Text(_formatDuration(duration)),
                ],
              ),
              // controls
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  IconButton(
                    icon: const Icon(Icons.replay_10),
                    onPressed: () {
                      _player.seek(position - const Duration(seconds: 1));
                    },
                  ),
                  StreamBuilder<bool>(
                    stream: _player.stream.playing,
                    builder: (context, snapshot) {
                      final playing = snapshot.data ?? false;
                      return IconButton(
                        icon: Icon(playing ? Icons.pause : Icons.play_arrow),
                        iconSize: 48,
                        onPressed: () {
                          _player.playOrPause();
                        },
                      );
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.forward_10),
                    onPressed: () {
                      _player.seek(position + const Duration(seconds: 1));
                    },
                  ),
                  // speed
                  StreamBuilder<double>(
                    stream: _player.stream.rate,
                    builder: (context, snapshot) {
                      final rate = snapshot.data ?? 1.0;
                      return DropdownButton<double>(
                        value: rate,
                        items: const [0.5, 1.0, 1.5, 2.0].map((speed) {
                          return DropdownMenuItem(
                            value: speed,
                            child: Text("${speed}x"),
                          );
                        }).toList(),
                        onChanged: (speed) {
                          if (speed != null) {
                            _player.setRate(speed);
                          }
                        },
                      );
                    },
                  ),
                ],
              ),
              const Divider(),
              // Annotation Controls
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _startMarker = position;
                      });
                    },
                    child: Text(
                      "Set Start: ${_startMarker != null ? _formatDuration(_startMarker!) : '-'}",
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _endMarker = position;
                      });
                    },
                    child: Text(
                      "Set End: ${_endMarker != null ? _formatDuration(_endMarker!) : '-'}",
                    ),
                  ),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.add),
                    label: const Text("Add Instance"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                    ),
                    onPressed:
                        (_startMarker != null &&
                            _endMarker != null &&
                            _endMarker! > _startMarker!)
                        ? () => _addInstance()
                        : null,
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
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

    final fileBaseName = widget.video.name
        .replaceAll('.mp4', '')
        .replaceAll('.mov', '');
    final videoId = "${fileBaseName}_${nextId.toString().padLeft(3, '0')}";

    final startFrame = (_startMarker!.inMilliseconds / 1000 * _fps).round();
    final endFrame = (_endMarker!.inMilliseconds / 1000 * _fps).round();

    final newInstance = Instance(
      fps: _fps,
      frameStart: startFrame,
      frameEnd: endFrame,
      instanceId: nextId,
      url: widget.video.name,
      videoId: videoId,
    );

    state.addInstance(widget.video.name, newInstance);

    setState(() {
      _startMarker = null;
      _endMarker = null;
    });

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text("Instance Added")));
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.toString().padLeft(2, '0');
    final seconds = (d.inSeconds % 60).toString().padLeft(2, '0');
    final millis = (d.inMilliseconds % 1000).toString().padLeft(3, '0');
    return "$minutes:$seconds.$millis";
  }
}
