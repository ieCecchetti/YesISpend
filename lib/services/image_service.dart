import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;

class ImageService {
  static final ImagePicker _picker = ImagePicker();

  // Pick one or more images (always uses camera)
  static Future<List<XFile>> pickImages({bool allowMultiple = true}) async {
    try {
      // Always use camera
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
      );
      return image != null ? [image] : [];
    } catch (e, stackTrace) {
      print('Error picking image from camera: $e');
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }

  // Save image to app documents directory
  static Future<String> saveImage(String transactionId, XFile image, int index) async {
    final directory = await getApplicationDocumentsDirectory();
    final imagesDir = Directory('${directory.path}/transaction_images');
    
    // Create directory if it doesn't exist
    if (!await imagesDir.exists()) {
      await imagesDir.create(recursive: true);
    }

    // Get file extension
    final extension = path.extension(image.path);
    
    // Create unique filename
    final fileName = '${transactionId}_${index}$extension';
    final filePath = '${imagesDir.path}/$fileName';

    // Copy image to app directory
    final file = File(image.path);
    await file.copy(filePath);

    return filePath;
  }

  // Delete image file
  static Future<void> deleteImage(String imagePath) async {
    try {
      final file = File(imagePath);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      print('Error deleting image: $e');
    }
  }

  // Delete multiple images
  static Future<void> deleteImages(List<String> imagePaths) async {
    for (final path in imagePaths) {
      await deleteImage(path);
    }
  }

  // Verify if image file exists
  static Future<bool> imageExists(String imagePath) async {
    try {
      final file = File(imagePath);
      return await file.exists();
    } catch (e) {
      return false;
    }
  }

  // Filter out non-existent image paths
  static Future<List<String>> filterValidImagePaths(List<String> imagePaths) async {
    final List<String> validPaths = [];
    for (final path in imagePaths) {
      if (await imageExists(path)) {
        validPaths.add(path);
      }
    }
    return validPaths;
  }
}

