class Instance {
  int fps;
  int frameStart;
  int frameEnd;
  int instanceId;
  String url; // Relative path or filename
  String videoId;

  Instance({
    required this.fps,
    required this.frameStart,
    required this.frameEnd,
    required this.instanceId,
    required this.url,
    required this.videoId,
  });

  Map<String, dynamic> toJson() {
    return {
      'fps': fps,
      'frame_start': frameStart,
      'frame_end': frameEnd,
      'instance_id': instanceId,
      'url': url,
      'video_id': videoId,
    };
  }

  factory Instance.fromJson(Map<String, dynamic> json) {
    return Instance(
      fps: json['fps'] ?? 60,
      frameStart: json['frame_start'] ?? 0,
      frameEnd: json['frame_end'] ?? 0,
      instanceId: json['instance_id'] ?? 0,
      url: json['url'] ?? '',
      videoId: json['video_id'] ?? '',
    );
  }
}

class GlossData {
  String gloss;
  List<Instance> instances;

  GlossData({required this.gloss, required this.instances});

  Map<String, dynamic> toJson() {
    return {
      'gloss': gloss,
      'instances': instances.map((e) => e.toJson()).toList(),
    };
  }

  factory GlossData.fromJson(Map<String, dynamic> json) {
    return GlossData(
      gloss: json['gloss'] ?? '',
      instances:
          (json['instances'] as List<dynamic>?)
              ?.map((e) => Instance.fromJson(e))
              .toList() ??
          [],
    );
  }
}
