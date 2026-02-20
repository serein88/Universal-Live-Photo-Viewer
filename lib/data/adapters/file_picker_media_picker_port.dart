import 'package:file_picker/file_picker.dart';
import 'package:universal_live_photo_viewer/application/ports/media_picker_port.dart';

class FilePickerMediaPickerPort implements MediaPickerPort {
  @override
  Future<String?> pickDirectoryPath() {
    return FilePicker.platform.getDirectoryPath();
  }

  @override
  Future<List<String>> pickFilePaths() async {
    final result = await FilePicker.platform.pickFiles(allowMultiple: true);
    return result?.paths.whereType<String>().toList() ?? const <String>[];
  }
}
