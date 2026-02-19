import 'dart:io';

abstract class FileSystemPort {
  Future<List<File>> listFilesRecursively(String rootPath);

  Future<void> deleteFile(String path);
}
