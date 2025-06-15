
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'dart:html' as html;
import 'file_downloader.dart';

/// A class for downloading files in web applications.
class WebFileDownloader extends FileDownloader {

  /// Initiates the file download process for web applications.
  /// @param context The build context of the application.
  /// @param fileData The data of the file to be downloaded.
  /// @param fileName The name of the file to be downloaded.
  /// @return A [Future] that completes when the download is initiated.
  @override
  Future<void> downloadFile(BuildContext context, Uint8List fileData, String fileName) async {
    print('WebFileDownloader: downloadFile called');
    // 🔹 Save the file
    final blob = html.Blob([fileData], 'application/octet-stream');
    final url = html.Url.createObjectUrlFromBlob(blob);
    final anchor = html.AnchorElement(href: url)
      ..setAttribute('download', fileName)
      ..click();
    html.Url.revokeObjectUrl(url);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('File downloaded: $fileName'), backgroundColor: Colors.green),
    );
  }
}

/// Returns the web file downloader instance.
FileDownloader getFileDownloader() => WebFileDownloader();