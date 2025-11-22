import 'dart:io';
import 'package:flutter/material.dart';

class ImageHelper {
  // Compress image for upload
  static Future<File> compressImage(
    File imageFile, {
    int maxWidth = 1024,
    int maxHeight = 1024,
    int quality = 85,
  }) async {
    // final dir = await getTemporaryDirectory();
    
    // Use flutter_image_compress or similar package
    // This is a placeholder - implement with actual compression
    return imageFile;
  }
  
  // Get image size
  static Future<Size> getImageSize(File imageFile) async {
    final image = await decodeImageFromList(
      await imageFile.readAsBytes(),
    );
    return Size(image.width.toDouble(), image.height.toDouble());
  }
  
  // Validate image file
  static bool isValidImageFile(String path) {
    final extension = path.split('.').last.toLowerCase();
    return ['jpg', 'jpeg', 'png'].contains(extension);
  }
  
  // Get file size in MB
  static Future<double> getFileSizeInMB(File file) async {
    final bytes = await file.length();
    return bytes / (1024 * 1024);
  }
}