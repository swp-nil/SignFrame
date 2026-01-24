class VideoMetadata {
  final String name;
  final String path;
  final Duration? duration;
  final String? thumbnailPath;

  VideoMetadata({
    required this.name,
    required this.path,
    this.duration,
    this.thumbnailPath,
  });
}
