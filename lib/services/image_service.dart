import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

class ImageService {
  final ImagePicker _picker = ImagePicker();

  Future<XFile?> pickImage() async {
    return await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 25,
      maxWidth: 400,
      maxHeight: 400,
    );
  }

  Future<String?> processImageBase64(XFile? pickedImage) async {
    if (pickedImage == null) return null;
    try {
      final bytes = await pickedImage.readAsBytes();
      if (bytes.length > 400000) {
        throw Exception("Image is too large. Please select a smaller photo.");
      }
      return base64Encode(bytes);
    } catch (e) {
      debugPrint("Image encode error: $e");
      throw Exception("Image processing failed: $e");
    }
  }
}
