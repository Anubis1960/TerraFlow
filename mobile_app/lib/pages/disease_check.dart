// disease_check_screen.dart

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:typed_data';
import '../components/top_bar.dart';
import '../util/constants.dart';
import '../util/storage/base_storage.dart';
import 'package:http_parser/http_parser.dart';

/// DiseaseCheckScreen is a Flutter widget that allows users to upload an image of a plant leaf to check for diseases. It uses the ImagePicker package to select images and sends them to a server for processing. The results are displayed on the screen, including the predicted disease and confidence level.
class DiseaseCheckScreen extends StatefulWidget {
  const DiseaseCheckScreen({Key? key}) : super(key: key);

  @override
  _DiseaseCheckScreenState createState() => _DiseaseCheckScreenState();
}

/// State class for DiseaseCheckScreen that manages the image selection, processing, and result display.
class _DiseaseCheckScreenState extends State<DiseaseCheckScreen> {
  XFile? _selectedImage;
  String _diseaseResult = "No disease detected";
  String _confidence = "Confidence: 0%";
  bool _isLoading = false;

  /// Picks an image from the gallery, processes it, and sends it to the server for disease prediction.
  /// Handles both web and mobile platforms, ensuring the image is resized appropriately.
  /// @return A [Future] that completes when the image is picked and processed.
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
          final bytes = await image.readAsBytes();
          request.files.add(
            http.MultipartFile.fromBytes(
              'image',
              bytes,
              filename: image.name,
              contentType: MediaType('image', 'jpeg'),
            ),
          );
        } else {
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
              _diseaseResult = "Verdict: $prediction";
              _confidence = "Confidence: $confidence";
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

  /// Builds the image preview widget that displays the selected image.
  /// @return A [Widget] that shows the selected image or a placeholder if no image is selected.
  Widget _buildImagePreview() {
    if (_selectedImage == null) return SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white, width: 2),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: kIsWeb
              ? FutureBuilder<Uint8List>(
            future: _selectedImage!.readAsBytes(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.done &&
                  snapshot.hasData) {
                return Image.memory(
                  snapshot.data!,
                  height: 250,
                  fit: BoxFit.cover,
                );
              } else if (snapshot.hasError) {
                return Text("Failed to load image");
              } else {
                return Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: CircularProgressIndicator(),
                );
              }
            },
          )
              : Image.file(
            File(_selectedImage!.path),
            height: 250,
            fit: BoxFit.cover,
          ),
        ),
      ),
    );
  }

  /// Builds the main UI of the DiseaseCheckScreen.
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: TopBar.buildTopBar(title: 'Disease Detection', context: context),
      body: Container(
        padding: const EdgeInsets.all(24),
        color: Colors.grey[200], // Light neutral background
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Image Selection Button
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
                              ? Colors.blueGrey
                              : Colors.green,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _selectedImage == null
                              ? "Select Image"
                              : "Image Selected",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.blueGrey.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Preview Image
              _buildImagePreview(),

              // Result Display
              if (_diseaseResult.isNotEmpty && !_isLoading)
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Text(
                    _diseaseResult,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: _diseaseResult.contains("Detected")
                          ? Colors.redAccent
                          : Colors.green.shade700,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ),

              if (_confidence.isNotEmpty && !_isLoading)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    _confidence,
                    style: TextStyle(
                      color: Colors.grey[700],
                      fontSize: 16,
                    ),
                  ),
                ),

              if (_isLoading)
                Padding(
                  padding: const EdgeInsets.only(top: 24),
                  child: CircularProgressIndicator(
                    color: Colors.blueGrey,
                  ),
                ),

              // Instructions
              Padding(
                padding: const EdgeInsets.only(top: 24),
                child: Text(
                  _selectedImage == null
                      ? "Tap to select an image from your gallery"
                      : "Processing complete",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}