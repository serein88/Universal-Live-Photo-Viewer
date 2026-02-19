abstract class MediaPickerPort {
  Future<String?> pickDirectoryPath();

  Future<List<String>> pickFilePaths();
}
