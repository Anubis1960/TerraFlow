import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'file_downloader_stub.dart'
  if (dart.library.io) 'mobile_file_downloader.dart'
  if (dart.library.html) 'web_file_downloader.dart';

abstract class FileDownloader {
  Future<void> downloadFile(BuildContext context, Uint8List fileData, String fileName);

  static FileDownloader getFileDownloaderFactory() => getFileDownloader();
}