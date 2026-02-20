import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:universal_live_photo_viewer/domain/live_photo_entity.dart';
import 'package:universal_live_photo_viewer/domain/live_photo_type.dart';
import 'package:universal_live_photo_viewer/main.dart';
import 'package:universal_live_photo_viewer/ui/playback/video_overlay_player.dart';

class FakeVideoOverlayPlayer implements VideoOverlayPlayer {
  final ValueNotifier<bool> _isPlaying = ValueNotifier<bool>(false);
  int startCallCount = 0;
  int stopCallCount = 0;
  String? lastVideoPath;

  @override
  ValueListenable<bool> get isPlayingListenable => _isPlaying;

  @override
  Future<void> start(String videoPath) async {
    startCallCount += 1;
    lastVideoPath = videoPath;
    _isPlaying.value = true;
  }

  @override
  Future<void> stop() async {
    stopCallCount += 1;
    _isPlaying.value = false;
  }

  void finishPlayback() {
    _isPlaying.value = false;
  }

  @override
  Widget buildVideoLayer() {
    return const ColoredBox(
      key: Key('fake_video_layer'),
      color: Colors.black,
      child: SizedBox.expand(),
    );
  }

  @override
  Future<void> dispose() async {
    _isPlaying.dispose();
  }
}

void main() {
  testWidgets('scan flow renders recognized list after selecting directory', (
    WidgetTester tester,
  ) async {
    var scanCallCount = 0;

    Future<String?> pickDirectory() async {
      return 'sample';
    }

    Future<List<LivePhotoEntity>> scanDirectory(String rootPath) async {
      scanCallCount += 1;
      return const <LivePhotoEntity>[
        LivePhotoEntity(
          id: 'ios_01',
          imagePath: 'sample/iphone-13p-live-1.JPG',
          videoPath: 'sample/iphone-13p-live-1.MOV',
          type: LivePhotoType.ios,
        ),
      ];
    }

    await tester.pumpWidget(
      ULPVApp(directoryPicker: pickDirectory, directoryScanner: scanDirectory),
    );

    expect(find.byKey(const Key('empty_scan_result_text')), findsOneWidget);

    await tester.tap(find.byKey(const Key('pick_directory_button')));
    await tester.pumpAndSettle();

    expect(scanCallCount, 1);
    expect(find.byKey(const Key('scan_result_list')), findsOneWidget);
    expect(find.text('已识别 1 项'), findsOneWidget);
    expect(find.text('iphone-13p-live-1.JPG'), findsOneWidget);
  });

  testWidgets('refresh button triggers rescan on selected directory', (
    WidgetTester tester,
  ) async {
    var scanCallCount = 0;

    Future<String?> pickDirectory() async {
      return 'sample';
    }

    Future<List<LivePhotoEntity>> scanDirectory(String rootPath) async {
      scanCallCount += 1;
      return const <LivePhotoEntity>[
        LivePhotoEntity(
          id: 'motion_01',
          imagePath: 'sample/xiaomi-live-1.jpg',
          videoPath: 'tmp/xiaomi-live-1.mp4',
          type: LivePhotoType.motionPhoto,
        ),
      ];
    }

    await tester.pumpWidget(
      ULPVApp(directoryPicker: pickDirectory, directoryScanner: scanDirectory),
    );

    await tester.tap(find.byKey(const Key('pick_directory_button')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('refresh_scan_button')));
    await tester.pumpAndSettle();

    expect(scanCallCount, 2);
  });

  testWidgets(
    'video overlay appears on play and falls back after playback ends',
    (WidgetTester tester) async {
      final fakePlayer = FakeVideoOverlayPlayer();

      Future<String?> pickDirectory() async {
        return 'sample';
      }

      Future<List<LivePhotoEntity>> scanDirectory(String rootPath) async {
        return const <LivePhotoEntity>[
          LivePhotoEntity(
            id: 'motion_01',
            imagePath: 'sample/xiaomi-live-1.jpg',
            videoPath: 'tmp/xiaomi-live-1.mp4',
            type: LivePhotoType.motionPhoto,
          ),
        ];
      }

      await tester.pumpWidget(
        ULPVApp(
          directoryPicker: pickDirectory,
          directoryScanner: scanDirectory,
          videoOverlayPlayer: fakePlayer,
        ),
      );

      await tester.tap(find.byKey(const Key('pick_directory_button')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('play_selected_button')));
      await tester.pumpAndSettle();

      expect(fakePlayer.startCallCount, 1);
      expect(fakePlayer.lastVideoPath, 'tmp/xiaomi-live-1.mp4');
      expect(find.byKey(const Key('video_overlay_layer')), findsOneWidget);
      expect(find.byKey(const Key('fake_video_layer')), findsOneWidget);

      fakePlayer.finishPlayback();
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('video_overlay_layer')), findsNothing);
    },
  );

  testWidgets('keyboard and wheel can switch selected item', (
    WidgetTester tester,
  ) async {
    Future<String?> pickDirectory() async {
      return 'sample';
    }

    Future<List<LivePhotoEntity>> scanDirectory(String rootPath) async {
      return const <LivePhotoEntity>[
        LivePhotoEntity(
          id: 'item_01',
          imagePath: 'sample/iphone-13p-live-1.JPG',
          videoPath: 'sample/iphone-13p-live-1.MOV',
          type: LivePhotoType.ios,
        ),
        LivePhotoEntity(
          id: 'item_02',
          imagePath: 'sample/xiaomi-live-1.jpg',
          videoPath: 'tmp/xiaomi-live-1.mp4',
          type: LivePhotoType.motionPhoto,
        ),
      ];
    }

    await tester.pumpWidget(
      ULPVApp(directoryPicker: pickDirectory, directoryScanner: scanDirectory),
    );

    await tester.tap(find.byKey(const Key('pick_directory_button')));
    await tester.pumpAndSettle();

    expect(find.text('当前: iphone-13p-live-1.JPG'), findsOneWidget);

    await tester.sendKeyDownEvent(LogicalKeyboardKey.arrowRight);
    await tester.pumpAndSettle();

    expect(find.text('当前: xiaomi-live-1.jpg'), findsOneWidget);

    final center = tester.getCenter(
      find.byKey(const Key('gallery_pointer_listener')),
    );
    GestureBinding.instance.handlePointerEvent(
      PointerScrollEvent(position: center, scrollDelta: const Offset(0, -80)),
    );
    await tester.pumpAndSettle();

    expect(find.text('当前: iphone-13p-live-1.JPG'), findsOneWidget);
  });
}
