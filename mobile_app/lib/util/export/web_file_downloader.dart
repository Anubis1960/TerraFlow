
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'dart:html' as html;
import 'file_downloader.dart';

class WebFileDownloader extends FileDownloader {
  @override
  Future<void> downloadFile(BuildContext context, Uint8List fileData, String fileName) async {
    // 🔹 Save the file
    final blob = html.Blob([fileData], 'application/octet-stream');
    final url = html.Url.createObjectUrlFromBlob(blob);
    html.Url.revokeObjectUrl(url);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('File downloaded: $fileName'), backgroundColor: Colors.green),
    );
  }
}

FileDownloader getFileDownloader() => WebFileDownloader();