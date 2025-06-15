import 'dart:io';
import 'dart:typed_data';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:mobile_app/util/export/file_downloader.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

/// A mobile implementation of the FileDownloader that handles file downloads
class MobileFileDownloader extends FileDownloader {

  /// Initiates the file download process for mobile applications.
  /// @param context The build context of the application.
  /// @param fileData The data of the file to be downloaded.
  /// @param fileName The name of the file to be downloaded.
  /// @return A [Future] that completes when the download is initiated.
  @override
  Future<void> downloadFile(BuildContext context, Uint8List fileData, String fileName) async {
    if (Platform.isAndroid) {
      AndroidDeviceInfo build = await DeviceInfoPlugin().androidInfo;
      if (build.version.sdkInt >= 30) {
        var status = await Permission.manageExternalStorage.status;
        if (!status.isGranted) {
          var result = await Permission.manageExternalStorage.request();
          if (result.isGranted) {
            // Permission granted
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Storage permission denied'), backgroundColor: Colors.red),
            );
            return;
          }
        } else {
          // Permission already granted
        }
      }
      else{
        if (!await requestStoragePermission(context)) {
          return;
        }
      }
    }

    if (Platform.isIOS) {
      if (!await requestStoragePermission(context)) {
        return;
      }
    }

    // 🔹 Get the save directory
    final directory = await getSaveDirectory();
    if (directory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: Unable to get save directory'), backgroundColor: Colors.red),
      );
      return;
    }

    // 🔹 Save the file
    final filePath = '${directory.path}/$fileName';
    final file = File(filePath);
    await file.writeAsBytes(fileData);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('File saved to: $filePath'), backgroundColor: Colors.green),
    );
  }

  /// Requests storage permission for Android and iOS platforms.
  /// @param context The build context of the application.
  /// @return A [Future] that resolves to true if permission is granted, false otherwise.
  Future<bool> requestStoragePermission(BuildContext context) async {
    if (Platform.isAndroid || Platform.isIOS) {
      final status = await Permission.storage.request();
      if (!status.isGranted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Storage permission denied'), backgroundColor: Colors.red),
        );
        return false;
      }
    }
    return true;
  }

  /// Gets the directory where files can be saved based on the platform.
  /// @return A [Future] that resolves to the directory where files can be saved, or null if not applicable.
  Future<Directory?> getSaveDirectory() async {
    if (Platform.isAndroid || Platform.isIOS) {
      return await getExternalStorageDirectory(); // For Android and iOS
    } else if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
      return await getDownloadsDirectory(); // For desktop platforms
    }
    return null;
  }
}

/// Returns the mobile file downloader instance.
FileDownloader getFileDownloader() => MobileFileDownloader();