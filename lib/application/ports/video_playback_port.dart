abstract class VideoPlaybackPort {
  Future<void> prepare(String videoPath);

  Future<void> play();

  Future<void> stop();

  Future<void> dispose();
}
