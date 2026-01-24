import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;

import '../models/annotation_model.dart';
import '../models/video_metadata.dart';

class ProjectState extends ChangeNotifier {
  String? currentFolderPath;
  List<VideoMetadata> videos = [];
  Map<String, GlossData> annotations = {}; // key: gloss name

  // Loading state
  bool isLoading = false;
  String? errorMessage;

  void setFolderPath(String path) {
    currentFolderPath = path;
    _scanFolder();
    _loadAnnotations(); // try to load existing annotations
    notifyListeners();
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
        final List<dynamic> jsonList = jsonDecode(jsonString);
        annotations.clear();
        for (var item in jsonList) {
          final glossData = GlossData.fromJson(item);
          annotations[glossData.gloss] = glossData;
        }
        notifyListeners();
      } catch (e) {
        debugPrint("Error loading annotations: $e");
      }
    }
  }

  Future<void> saveAnnotations() async {
    if (currentFolderPath == null) return;
    final file = File(p.join(currentFolderPath!, 'annotations.json'));
    final jsonList = annotations.values.map((e) => e.toJson()).toList();
    await file.writeAsString(jsonEncode(jsonList));
  }

  void addInstance(String videoName, Instance instance) {
    String gloss = _extractGloss(videoName);

    if (!annotations.containsKey(gloss)) {
      annotations[gloss] = GlossData(gloss: gloss, instances: []);
    }

    annotations[gloss]!.instances.add(instance);
    notifyListeners();
    saveAnnotations(); // auto save
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
      return parts.sublist(0, parts.length - 1).join('_');
    }
    return name;
  }

  List<Instance> getInstancesForVideo(String videoName) {
    final List<Instance> result = [];
    for (var glossData in annotations.values) {
      for (var inst in glossData.instances) {
        // loose match
        if (inst.url.endsWith(videoName) || inst.url == videoName) {
          result.add(inst);
        }
      }
    }
    return result;
  }
}
