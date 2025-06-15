import 'file_downloader.dart';

/// A stub implementation of the FileDownloader for unsupported platforms.
FileDownloader getFileDownloader() {
  throw UnsupportedError("Platform not supported");
}