import 'dart:io';
import 'dart:typed_data';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:mobile_app/util/export/file_downloader.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

class MobileFileDownloader extends FileDownloader {
  @override
  Future<void> downloadFile(BuildContext context, Uint8List fileData, String fileName) async {
    if (Platform.isAndroid) {
      AndroidDeviceInfo build = await DeviceInfoPlugin().androidInfo;
      if (build.version.sdkInt >= 30) {
        var status = await Permission.manageExternalStorage.status;
        if (!status.isGranted) {
          return;
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

  // 🔹 Request storage permission (Android and iOS only)
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

  // 🔹 Get the save directory
  Future<Directory?> getSaveDirectory() async {
    if (Platform.isAndroid || Platform.isIOS) {
      return await getExternalStorageDirectory(); // For Android and iOS
    } else if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
      return await getDownloadsDirectory(); // For desktop platforms
    }
    return null;
  }
}

//Provides MobileFileDownloader
FileDownloader getFileDownloader() => MobileFileDownloader();