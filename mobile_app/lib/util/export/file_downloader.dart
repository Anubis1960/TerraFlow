import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'file_downloader_stub.dart'
  if (dart.library.io) 'mobile_file_downloader.dart'
  if (dart.library.html) 'web_file_downloader.dart';

/// A utility class for downloading files across different platforms.
abstract class FileDownloader {

  /// Initiates the file download process.
  Future<void> downloadFile(BuildContext context, Uint8List fileData, String fileName);

  /// Returns the appropriate file downloader implementation based on the platform.
  static FileDownloader getFileDownloaderFactory() => getFileDownloader();
}