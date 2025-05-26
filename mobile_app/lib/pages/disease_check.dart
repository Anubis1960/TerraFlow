// disease_check_screen.dart
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:http/http.dart' as http;

import '../components/top_bar.dart';
import '../util/constants.dart';
import '../util/storage/base_storage.dart';
import 'package:http_parser/http_parser.dart';

class DiseaseCheckScreen extends StatefulWidget {
  const DiseaseCheckScreen({Key? key}) : super(key: key);

  @override
  _DiseaseCheckScreenState createState() => _DiseaseCheckScreenState();
}

class _DiseaseCheckScreenState extends State<DiseaseCheckScreen> {
  XFile? _selectedImage;
  String _diseaseResult = "No disease detected";
  String _confidence = "Confidence: 0%";
  bool _isLoading = false;

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    try {
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
      );

      if (image != null) {
        setState(() {
          _selectedImage = image;
          _isLoading = true;
          _diseaseResult = "Processing...";
          _confidence = "Confidence: 0%";
        });

        String url = kIsWeb ? Server.WEB_BASE_URL : Server.MOBILE_BASE_URL;
        url += '${Server.USER_REST_URL}/predict-disease';

        var request = http.MultipartRequest('POST', Uri.parse(url));
        final token = await BaseStorage.getStorageFactory().getToken();

        var headers = {
          'Authorization': 'Bearer $token',
        };

        request.headers.addAll(headers);

        if (kIsWeb) {
          // Web-specific handling
          final bytes = await image.readAsBytes();
          request.files.add(
            http.MultipartFile.fromBytes(
              'image',
              bytes,
              filename: image.name,
              contentType: MediaType('image', 'jpeg'), // Or use MediaType.parse(mimeType)
            ),
          );
        } else {
          // Mobile-specific handling
          File imageFile = File(image.path);
          request.files.add(
            await http.MultipartFile.fromPath(
              'image',
              imageFile.path,
              filename: image.name,
            ),
          );
        }

        // Send the request
        var response = await request.send();
        if (response.statusCode == 200) {
          var responseData = await http.Response.fromStream(response);
          if (responseData.statusCode == 200) {
            var data = jsonDecode(responseData.body);
            String prediction = data['prediction'] ?? 'No prediction';
            String confidence = data['confidence'] != null
                ? '${(data['confidence'] * 100).toStringAsFixed(2)}%'
                : '0%';
            setState(() {
              _diseaseResult = "Disease Detected: ${prediction}";
              _confidence = "Confidence: ${confidence}";
            });
          } else {
            setState(() {
              _diseaseResult = "Error";
              _confidence = "Confidence: 0%";
            });
          }
        } else {
          setState(() {
            _diseaseResult = "Error: Unable to process image";
            _confidence = "Confidence: 0%";
          });
        }
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _diseaseResult = "Error processing image";
        _confidence = "Confidence: 0%";
      });
      print("Error picking image: $e");
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: TopBar.buildTopBar(title: 'Crop Disease Detection', context: context),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF4e54c8), Color(0xFF8f94fb)],
          ),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Image Selection Card
                Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 4,
                  child: InkWell(
                    onTap: _pickImage,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        color: Colors.white,
                      ),
                      child: Column(
                        children: [
                          Icon(
                            _selectedImage == null ? Icons.add_a_photo : Icons.check_circle,
                            size: 64,
                            color: _selectedImage == null
                                ? Colors.deepPurpleAccent
                                : Colors.green,
                          ),
                          SizedBox(height: 16),
                          Text(
                            _selectedImage == null
                                ? "Select Image"
                                : "Selected Image",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.deepPurpleAccent,
                            ),
                          ),
                          if (_selectedImage != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Text(
                                _diseaseResult,
                                style: TextStyle(
                                  color: _diseaseResult.contains("Detected")
                                      ? Colors.red
                                      : Colors.green,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          Padding(padding: const EdgeInsets.only(top: 8.0)),
                          if (_selectedImage != null)
                            Text(
                              _confidence,
                              style: TextStyle(
                                color: Colors.black54,
                                fontSize: 16,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),

                if (_isLoading)
                  Padding(
                    padding: const EdgeInsets.only(top: 24),
                    child: CircularProgressIndicator(),
                  ),

                // Instructions
                Padding(
                  padding: const EdgeInsets.only(top: 32),
                  child: Text(
                    _selectedImage == null
                        ? "Tap to select an image from your gallery"
                        : "Processing complete",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}