import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:universal_live_photo_viewer/application/use_cases/scan_live_photos_use_case.dart';
import 'package:universal_live_photo_viewer/data/adapters/file_picker_media_picker_port.dart';
import 'package:universal_live_photo_viewer/data/adapters/local_file_system_port.dart';
import 'package:universal_live_photo_viewer/data/parsers/ios_parser.dart';
import 'package:universal_live_photo_viewer/data/parsers/motion_photo_parser.dart';
import 'package:universal_live_photo_viewer/domain/live_photo_entity.dart';
import 'package:universal_live_photo_viewer/domain/live_photo_parser.dart';
import 'package:universal_live_photo_viewer/ui/playback/video_overlay_player.dart';
import 'package:video_player_win/video_player_win.dart';

typedef DirectoryPicker = Future<String?> Function();
typedef DirectoryScanner =
    Future<List<LivePhotoEntity>> Function(String rootPath);
typedef VideoOverlayPlayerBuilder = VideoOverlayPlayer Function();

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  if (!kIsWeb && Platform.isWindows) {
    WindowsVideoPlayer.registerWith();
  }
  runApp(const ULPVApp());
}

class ULPVApp extends StatelessWidget {
  const ULPVApp({
    super.key,
    this.directoryPicker,
    this.directoryScanner,
    this.videoOverlayPlayer,
  });

  final DirectoryPicker? directoryPicker;
  final DirectoryScanner? directoryScanner;
  final VideoOverlayPlayer? videoOverlayPlayer;

  @override
  Widget build(BuildContext context) {
    final pickerPort = FilePickerMediaPickerPort();
    final scannerUseCase = ScanLivePhotosUseCase(
      fileSystemPort: LocalFileSystemPort(),
      parsers: <LivePhotoParser>[IOSParser(), MotionPhotoParser()],
    );

    return MaterialApp(
      title: 'Universal Live Photo Viewer',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2E7D32)),
      ),
      home: WindowsDirectoryScanPage(
        directoryPicker: directoryPicker ?? pickerPort.pickDirectoryPath,
        directoryScanner: directoryScanner ?? scannerUseCase.execute,
        videoOverlayPlayer: videoOverlayPlayer,
      ),
    );
  }
}

class WindowsDirectoryScanPage extends StatefulWidget {
  const WindowsDirectoryScanPage({
    super.key,
    required this.directoryPicker,
    required this.directoryScanner,
    this.videoOverlayPlayer,
    this.videoOverlayPlayerBuilder = VideoPlayerOverlayPlayer.new,
  });

  final DirectoryPicker directoryPicker;
  final DirectoryScanner directoryScanner;
  final VideoOverlayPlayer? videoOverlayPlayer;
  final VideoOverlayPlayerBuilder videoOverlayPlayerBuilder;

  @override
  State<WindowsDirectoryScanPage> createState() =>
      _WindowsDirectoryScanPageState();
}

class _WindowsDirectoryScanPageState extends State<WindowsDirectoryScanPage> {
  late final VideoOverlayPlayer _videoOverlayPlayer;
  late final bool _ownsVideoOverlayPlayer;

  final FocusNode _keyboardFocusNode = FocusNode(
    debugLabel: 'gallery_keyboard_focus',
  );

  String? _selectedDirectory;
  List<LivePhotoEntity> _entities = const <LivePhotoEntity>[];
  int? _selectedIndex;
  bool _showVideoOverlay = false;
  bool _isScanning = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    if (widget.videoOverlayPlayer != null) {
      _videoOverlayPlayer = widget.videoOverlayPlayer!;
      _ownsVideoOverlayPlayer = false;
    } else {
      _videoOverlayPlayer = widget.videoOverlayPlayerBuilder();
      _ownsVideoOverlayPlayer = true;
    }
    _videoOverlayPlayer.isPlayingListenable.addListener(
      _handlePlaybackStateChanged,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _keyboardFocusNode.requestFocus();
      }
    });
  }

  @override
  void dispose() {
    _videoOverlayPlayer.isPlayingListenable.removeListener(
      _handlePlaybackStateChanged,
    );
    if (_ownsVideoOverlayPlayer) {
      unawaited(_videoOverlayPlayer.dispose());
    }
    _keyboardFocusNode.dispose();
    super.dispose();
  }

  void _handlePlaybackStateChanged() {
    final isPlaying = _videoOverlayPlayer.isPlayingListenable.value;
    if (!isPlaying && _showVideoOverlay && mounted) {
      setState(() {
        _showVideoOverlay = false;
      });
    }
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) {
      return KeyEventResult.ignored;
    }

    if (event.logicalKey == LogicalKeyboardKey.arrowRight ||
        event.logicalKey == LogicalKeyboardKey.arrowDown) {
      unawaited(_selectByStep(1));
      return KeyEventResult.handled;
    }

    if (event.logicalKey == LogicalKeyboardKey.arrowLeft ||
        event.logicalKey == LogicalKeyboardKey.arrowUp) {
      unawaited(_selectByStep(-1));
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  void _handlePointerSignal(PointerSignalEvent event) {
    if (event is! PointerScrollEvent) {
      return;
    }

    if (event.scrollDelta.dy > 0) {
      unawaited(_selectByStep(1));
    } else if (event.scrollDelta.dy < 0) {
      unawaited(_selectByStep(-1));
    }
  }

  Future<void> _pickAndScan() async {
    final path = await widget.directoryPicker();
    if (path == null || path.trim().isEmpty) {
      return;
    }

    setState(() {
      _selectedDirectory = path;
    });

    await _scan(path);
  }

  Future<void> _refreshScan() async {
    final path = _selectedDirectory;
    if (path == null || path.trim().isEmpty) {
      return;
    }

    await _scan(path);
  }

  Future<void> _scan(String path) async {
    setState(() {
      _isScanning = true;
      _error = null;
    });

    await _stopPlayback();

    try {
      final entities = await widget.directoryScanner(path);
      if (!mounted) {
        return;
      }

      final nextSelectedIndex = entities.isEmpty
          ? null
          : (_selectedIndex ?? 0).clamp(0, entities.length - 1);

      setState(() {
        _entities = entities;
        _selectedIndex = nextSelectedIndex;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _error = '扫描失败: $error';
      });
    } finally {
      if (!mounted) {
        return;
      }
      setState(() {
        _isScanning = false;
      });
    }
  }

  Future<void> _stopPlayback() async {
    String? playbackStopError;
    try {
      await _videoOverlayPlayer.stop();
    } catch (error) {
      playbackStopError = '停止播放失败: $error';
    }

    if (!mounted) {
      return;
    }
    setState(() {
      _showVideoOverlay = false;
      if (playbackStopError != null) {
        _error = playbackStopError;
      }
    });
  }

  Future<void> _playSelected() async {
    final entity = _selectedEntity;
    final videoPath = entity?.videoPath;
    if (entity == null || videoPath == null || videoPath.trim().isEmpty) {
      return;
    }

    try {
      await _videoOverlayPlayer.start(videoPath);
      if (!mounted) {
        return;
      }
      setState(() {
        _showVideoOverlay = true;
        _error = null;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _showVideoOverlay = false;
        _error = '播放失败: $error';
      });
    }
  }

  Future<void> _selectByStep(int step) async {
    if (_entities.isEmpty) {
      return;
    }

    final current = _selectedIndex ?? 0;
    final next = (current + step).clamp(0, _entities.length - 1);
    if (next == current) {
      return;
    }

    await _stopPlayback();
    if (!mounted) {
      return;
    }
    setState(() {
      _selectedIndex = next;
    });
  }

  LivePhotoEntity? get _selectedEntity {
    final index = _selectedIndex;
    if (index == null || index < 0 || index >= _entities.length) {
      return null;
    }
    return _entities[index];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Universal Live Photo Viewer')),
      body: Listener(
        key: const Key('gallery_pointer_listener'),
        onPointerSignal: _handlePointerSignal,
        child: Focus(
          key: const Key('keyboard_navigation_focus'),
          focusNode: _keyboardFocusNode,
          autofocus: true,
          onKeyEvent: _handleKeyEvent,
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: () => _keyboardFocusNode.requestFocus(),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: <Widget>[
                      ElevatedButton.icon(
                        key: const Key('pick_directory_button'),
                        onPressed: _isScanning ? null : _pickAndScan,
                        icon: const Icon(Icons.folder_open),
                        label: const Text('选择目录并扫描'),
                      ),
                      OutlinedButton.icon(
                        key: const Key('refresh_scan_button'),
                        onPressed: _isScanning || _selectedDirectory == null
                            ? null
                            : _refreshScan,
                        icon: const Icon(Icons.refresh),
                        label: const Text('刷新重扫'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _selectedDirectory == null
                        ? '未选择目录'
                        : '目录: $_selectedDirectory',
                    key: const Key('selected_directory_text'),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '已识别 ${_entities.length} 项',
                    key: const Key('scan_summary_text'),
                  ),
                  if (_error != null) ...<Widget>[
                    const SizedBox(height: 8),
                    Text(
                      _error!,
                      key: const Key('scan_error_text'),
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ],
                  if (_isScanning) ...<Widget>[
                    const SizedBox(height: 12),
                    const LinearProgressIndicator(),
                  ],
                  const SizedBox(height: 12),
                  SizedBox(height: 240, child: _buildPreviewPane()),
                  const SizedBox(height: 12),
                  Expanded(
                    child: _entities.isEmpty
                        ? const Center(
                            child: Text(
                              '暂无识别结果',
                              key: Key('empty_scan_result_text'),
                            ),
                          )
                        : ListView.separated(
                            key: const Key('scan_result_list'),
                            itemCount: _entities.length,
                            separatorBuilder: (_, __) =>
                                const Divider(height: 1),
                            itemBuilder: (BuildContext context, int index) {
                              final entity = _entities[index];
                              final selected = _selectedIndex == index;
                              return ListTile(
                                key: Key('entity_tile_$index'),
                                selected: selected,
                                title: Text(_basename(entity.imagePath)),
                                subtitle: Text(
                                  '${entity.type.name} · ${entity.videoPath == null ? '无视频' : '含视频'}',
                                ),
                                dense: true,
                                onTap: () async {
                                  await _stopPlayback();
                                  if (!mounted) {
                                    return;
                                  }
                                  setState(() {
                                    _selectedIndex = index;
                                  });
                                },
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPreviewPane() {
    final selectedEntity = _selectedEntity;
    if (selectedEntity == null) {
      return const Card(child: Center(child: Text('请选择并扫描目录后查看预览')));
    }

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          _buildImageLayer(selectedEntity.imagePath),
          Positioned(
            left: 12,
            top: 12,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Text(
                  '当前: ${_basename(selectedEntity.imagePath)}',
                  key: const Key('selected_entity_text'),
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ),
          ),
          if (_showVideoOverlay)
            Positioned.fill(
              child: KeyedSubtree(
                key: const Key('video_overlay_layer'),
                child: _videoOverlayPlayer.buildVideoLayer(),
              ),
            ),
          Positioned(
            right: 12,
            bottom: 12,
            child: FilledButton.icon(
              key: const Key('play_selected_button'),
              onPressed: selectedEntity.videoPath == null || _isScanning
                  ? null
                  : _playSelected,
              icon: const Icon(Icons.play_arrow),
              label: Text(_showVideoOverlay ? '播放中' : '播放实况'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageLayer(String imagePath) {
    final file = File(imagePath);
    if (!file.existsSync()) {
      return Container(
        color: Colors.black12,
        alignment: Alignment.center,
        child: Text('图片文件不存在: ${_basename(imagePath)}'),
      );
    }

    return ColoredBox(
      color: Colors.black,
      child: Image.file(
        file,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) {
          return const Center(child: Text('图片加载失败'));
        },
      ),
    );
  }

  String _basename(String path) {
    final normalized = path.replaceAll('\\', '/');
    final segments = normalized.split('/');
    return segments.isEmpty ? path : segments.last;
  }
}
