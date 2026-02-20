import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

abstract class VideoOverlayPlayer {
  ValueListenable<bool> get isPlayingListenable;

  Future<void> start(String videoPath);

  Future<void> stop();

  Widget buildVideoLayer();

  Future<void> dispose();
}

class VideoPlayerOverlayPlayer implements VideoOverlayPlayer {
  VideoPlayerOverlayPlayer();

  final ValueNotifier<bool> _isPlaying = ValueNotifier<bool>(false);
  VideoPlayerController? _controller;

  @override
  ValueListenable<bool> get isPlayingListenable => _isPlaying;

  @override
  Future<void> start(String videoPath) async {
    await stop();

    final controller = VideoPlayerController.file(File(videoPath));
    _controller = controller;
    await controller.initialize();
    controller.addListener(_onControllerTick);
    await controller.play();
    _isPlaying.value = true;
  }

  @override
  Future<void> stop() async {
    final controller = _controller;
    if (controller != null) {
      controller.removeListener(_onControllerTick);
      await controller.pause();
      await controller.dispose();
    }

    _controller = null;
    _isPlaying.value = false;
  }

  void _onControllerTick() {
    final controller = _controller;
    if (controller == null) {
      return;
    }

    final value = controller.value;
    if (value.hasError) {
      _isPlaying.value = false;
      return;
    }

    if (value.isInitialized &&
        !value.isPlaying &&
        value.duration > Duration.zero &&
        value.position >= value.duration) {
      _isPlaying.value = false;
    }
  }

  @override
  Widget buildVideoLayer() {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) {
      return const SizedBox.shrink();
    }

    return ColoredBox(
      color: Colors.black,
      child: Center(
        child: AspectRatio(
          aspectRatio: controller.value.aspectRatio,
          child: VideoPlayer(controller),
        ),
      ),
    );
  }

  @override
  Future<void> dispose() async {
    await stop();
    _isPlaying.dispose();
  }
}
