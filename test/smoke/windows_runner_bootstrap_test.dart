import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('windows runner uses ULPV title and minimum size constraints', () {
    final mainCpp = File('windows/runner/main.cpp').readAsStringSync();
    final win32WindowCpp =
        File('windows/runner/win32_window.cpp').readAsStringSync();

    expect(mainCpp, contains('Universal Live Photo Viewer'));
    expect(win32WindowCpp, contains('WM_GETMINMAXINFO'));
    expect(win32WindowCpp, contains('ptMinTrackSize.x'));
    expect(win32WindowCpp, contains('ptMinTrackSize.y'));
  });
}
