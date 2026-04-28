import 'dart:async';

import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:path/path.dart' as p;
import 'package:provider/provider.dart';

import '../models/annotation_model.dart';
import '../models/video_metadata.dart';
import 'project_state.dart';

// player session state for a single video
class PlayerSessionProvider extends ChangeNotifier {
  final VideoMetadata video;
  final BuildContext _context;

  late final Player player;
  late final VideoController controller;

  // Annotation state
  Duration? startMarker;
  Duration? endMarker;
  double fps = 60.0;

  bool isAnnotating = false;
  double savedRate = 1.0;
  double slowMoSpeed = 0.25;

  String? sidebarMessage;
  Instance? playingInstance;

  StreamSubscription? _tracksSub;
  StreamSubscription? _positionSub;
  StreamSubscription? _completedSub;
  Timer? _messageTimer;

  bool _disposed = false;

  PlayerSessionProvider({required this.video, required BuildContext context})
    : _context = context {
    player = Player();
    controller = VideoController(player);
    _initializeVideo();
  }

  Future<void> _initializeVideo() async {
    await player.open(Media(video.path));

    _tracksSub = player.stream.tracks.listen((tracks) {
      if (_disposed) return;
      final videoTrack = tracks.video.firstOrNull;
      if (videoTrack != null) {
        if (videoTrack.fps != null && videoTrack.fps! > 0) {
          fps = videoTrack.fps!;
          notifyListeners();
        } else {
          final str = videoTrack.toString();
          final match = RegExp(
            r'(?:frameRate|fps):\s*(\d+(\.\d+)?)',
          ).firstMatch(str);
          if (match != null) {
            final val = double.tryParse(match.group(1)!);
            if (val != null && val > 0) {
              fps = val;
              notifyListeners();
            }
          }
        }
      }
    });

    _positionSub = player.stream.position.listen((position) {
      if (_disposed) return;
      if (playingInstance != null) {
        final endMs = playingInstance!.endMs;
        if (position.inMilliseconds >= endMs) {
          player.pause();
          playingInstance = null;
          notifyListeners();
        }
      }
    });

    _completedSub = player.stream.completed.listen((completed) {
      if (_disposed) return;
      if (completed) {
        playingInstance = null;
        notifyListeners();
      }
    });
  }

  // Actions

  void showSidebarMessage(String message) {
    sidebarMessage = message;
    notifyListeners();
    _messageTimer?.cancel();
    _messageTimer = Timer(const Duration(seconds: 3), () {
      if (!_disposed && sidebarMessage == message) {
        sidebarMessage = null;
        notifyListeners();
      }
    });
  }

  void dismissSidebarMessage() {
    sidebarMessage = null;
    notifyListeners();
  }

  void playInstance(Instance inst) {
    playingInstance = inst;
    notifyListeners();
    player.seek(Duration(milliseconds: inst.startMs));
    player.play();
    showSidebarMessage(
      'Playing instance #${inst.instanceId.toString().padLeft(3, '0')}',
    );
  }

  void skipBack() {
    final target = player.state.position - const Duration(seconds: 1);
    player.seek(target < Duration.zero ? Duration.zero : target);
  }

  void skipForward() {
    final duration = player.state.duration;
    final target = player.state.position + const Duration(seconds: 1);
    player.seek(target > duration ? duration : target);
  }

  void markStart() {
    if (isAnnotating) return;
    isAnnotating = true;
    startMarker = player.state.position;
    savedRate = player.state.rate;
    player.setRate(slowMoSpeed);
    notifyListeners();
  }

  void markEnd() {
    if (isAnnotating && startMarker != null) {
      final endPos = player.state.position;
      if (endPos > startMarker!) {
        endMarker = endPos;
        _addInstance();
        startMarker = null;
        endMarker = null;
        isAnnotating = false;
        player.setRate(savedRate);
        notifyListeners();
      }
    }
  }

  void cancelAnnotation() {
    if (isAnnotating) {
      startMarker = null;
      endMarker = null;
      isAnnotating = false;
      player.setRate(savedRate);
      notifyListeners();
    }
  }

  void saveAnnotations() {
    _context.read<ProjectState>().saveAnnotations();
    showSidebarMessage('Annotations saved');
  }

  void setSlowMoSpeed(double speed) {
    slowMoSpeed = speed;
    if (isAnnotating) {
      player.setRate(speed);
    }
    notifyListeners();
  }

  void _addInstance() {
    final state = _context.read<ProjectState>();
    final instances = state.getInstancesForVideo(video.name);

    int nextId = 1;
    if (instances.isNotEmpty) {
      int maxId = 0;
      for (var i in instances) {
        if (i.instanceId > maxId) maxId = i.instanceId;
      }
      nextId = maxId + 1;
    }

    final fileBaseName = p.basenameWithoutExtension(video.name);
    final videoId = "${fileBaseName}_${nextId.toString().padLeft(3, '0')}";

    final startFrame = (startMarker!.inMilliseconds / 1000 * fps).round();
    final endFrame = (endMarker!.inMilliseconds / 1000 * fps).round();

    final newInstance = Instance(
      fps: fps,
      frameStart: startFrame,
      frameEnd: endFrame,
      startMs: startMarker!.inMilliseconds,
      endMs: endMarker!.inMilliseconds,
      instanceId: nextId,
      source: video.name,
      videoId: videoId,
    );

    state.addInstance(video.name, newInstance);
    showSidebarMessage('Instance #${nextId.toString().padLeft(3, '0')} added');
  }

  // Utils

  String formatDuration(Duration d) {
    final minutes = d.inMinutes.toString().padLeft(2, '0');
    final seconds = (d.inSeconds % 60).toString().padLeft(2, '0');
    final millis = (d.inMilliseconds % 1000).toString().padLeft(3, '0');
    return "$minutes:$seconds.$millis";
  }

  @override
  void dispose() {
    _disposed = true;
    _messageTimer?.cancel();
    _tracksSub?.cancel();
    _positionSub?.cancel();
    _completedSub?.cancel();
    player.dispose();
    super.dispose();
  }
}
