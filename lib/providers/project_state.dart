import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/annotation_model.dart';
import '../models/video_metadata.dart';

class ProjectState extends ChangeNotifier {
  String? currentFolderPath;
  List<VideoMetadata> videos = [];
  Map<String, GlossData> annotations = {}; // key: gloss name
  Set<String> completedVideos = {}; // marked as done

  bool isLoading = false;
  String? errorMessage;

  static const _lastFolderKey = 'last_folder_path';

  /// init and load last opened folder
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final savedPath = prefs.getString(_lastFolderKey);
    if (savedPath != null && Directory(savedPath).existsSync()) {
      setFolderPath(savedPath);
    }
  }

  void setFolderPath(String path) {
    currentFolderPath = path;
    // Clear old data before loading new folder
    annotations.clear();
    completedVideos.clear();
    videos = [];
    _saveLastFolder(path);
    _scanFolder();
    _loadAnnotations();
    _loadProgress();
    notifyListeners();
  }

  Future<void> _saveLastFolder(String path) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastFolderKey, path);
  }

  Future<void> _scanFolder() async {
    if (currentFolderPath == null) return;
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final dir = Directory(currentFolderPath!);
      final List<VideoMetadata> loadedVideos = [];

      await for (final entity in dir.list()) {
        if (entity is File) {
          final ext = p.extension(entity.path).toLowerCase();
          if (['.mp4', '.mov', '.avi', '.mkv'].contains(ext)) {
            loadedVideos.add(
              VideoMetadata(name: p.basename(entity.path), path: entity.path),
            );
          }
        }
      }

      // sort alphabetically
      loadedVideos.sort((a, b) => a.name.compareTo(b.name));

      videos = loadedVideos;
    } catch (e) {
      errorMessage = "Error scanning folder: $e";
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _loadAnnotations() async {
    if (currentFolderPath == null) return;
    final file = File(p.join(currentFolderPath!, 'annotations.json'));
    if (await file.exists()) {
      try {
        final jsonString = await file.readAsString();
        final dynamic jsonData = jsonDecode(jsonString);

        annotations.clear();

        // handle both new format (with 'glosses' key) and legacy format (direct list)
        if (jsonData is Map && jsonData['glosses'] != null) {
          for (var item in jsonData['glosses']) {
            final glossData = GlossData.fromJson(item);
            annotations[glossData.gloss] = glossData;
          }
        } else if (jsonData is List) {
          // legacy format: direct list of glosses
          for (var item in jsonData) {
            final glossData = GlossData.fromJson(item);
            annotations[glossData.gloss] = glossData;
          }
        }

        notifyListeners();
      } catch (e) {
        debugPrint("Error loading annotations: $e");
      }
    }
  }

  Future<void> _loadProgress() async {
    if (currentFolderPath == null) return;
    final file = File(p.join(currentFolderPath!, 'progress.json'));
    if (await file.exists()) {
      try {
        final jsonString = await file.readAsString();
        final Map<String, dynamic> jsonData = jsonDecode(jsonString);

        completedVideos.clear();
        if (jsonData['completed_videos'] != null) {
          completedVideos = Set<String>.from(jsonData['completed_videos']);
        }

        notifyListeners();
      } catch (e) {
        debugPrint("Error loading progress: $e");
      }
    }
  }

  Future<void> saveAnnotations() async {
    if (currentFolderPath == null) return;
    final file = File(p.join(currentFolderPath!, 'annotations.json'));
    final jsonList = annotations.values.map((e) => e.toJson()).toList();
    await file.writeAsString(
      const JsonEncoder.withIndent('  ').convert(jsonList),
    );
  }

  Future<void> _saveProgress() async {
    if (currentFolderPath == null) return;
    final file = File(p.join(currentFolderPath!, 'progress.json'));
    final jsonData = {
      'completed_videos': completedVideos.toList(),
      'last_updated': DateTime.now().toIso8601String(),
    };
    await file.writeAsString(
      const JsonEncoder.withIndent('  ').convert(jsonData),
    );
  }

  void addInstance(String videoName, Instance instance) {
    String gloss = _extractGloss(videoName);

    if (!annotations.containsKey(gloss)) {
      annotations[gloss] = GlossData(gloss: gloss, instances: []);
    }

    annotations[gloss]!.instances.add(instance);
    notifyListeners();
    saveAnnotations(); // auto-save
  }

  void removeInstance(String videoName, Instance instance) {
    String gloss = _extractGloss(videoName);
    if (annotations.containsKey(gloss)) {
      annotations[gloss]!.instances.removeWhere(
        (i) => i.videoId == instance.videoId,
      );
      if (annotations[gloss]!.instances.isEmpty) {
        annotations.remove(gloss);
      }
      notifyListeners();
      saveAnnotations();
    }
  }

  String _extractGloss(String filename) {
    final name = p.basenameWithoutExtension(filename);

    final parts = name.split('_');
    if (parts.length > 1) {
      final lastPart = parts.last;
      // check if last part is numeric with optional version suffix (e.g., "001", "001v2")
      if (RegExp(r'^\d+(v\d+)?$', caseSensitive: false).hasMatch(lastPart)) {
        return parts.sublist(0, parts.length - 1).join('_');
      }
    }
    return name; // fallback
  }

  List<Instance> getInstancesForVideo(String videoName) {
    //yeah this should be fineeee :p
    final List<Instance> result = [];
    for (var glossData in annotations.values) {
      for (var inst in glossData.instances) {
        // loose match
        if (inst.source.endsWith(videoName) || inst.source == videoName) {
          result.add(inst);
        }
      }
    }
    return result;
  }

  // completion status
  bool isVideoCompleted(String videoName) {
    return completedVideos.contains(videoName);
  }

  void toggleVideoCompleted(String videoName) {
    if (completedVideos.contains(videoName)) {
      completedVideos.remove(videoName);
    } else {
      completedVideos.add(videoName);
    }
    notifyListeners();
    _saveProgress();
  }

  void setVideoCompleted(String videoName, bool completed) {
    if (completed) {
      completedVideos.add(videoName);
    } else {
      completedVideos.remove(videoName);
    }
    notifyListeners();
    _saveProgress();
  }
}
