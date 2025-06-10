import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import '../core/constants/firebase_constants.dart';

class ImageService {
  static final FirebaseStorage _storage = FirebaseStorage.instance;

  static Future<String> uploadCompressedImage(File imageFile, String fileName) async {
    try {
      // Compress image before upload
      final compressedFile = await _compressImage(imageFile, fileName);
      
      final ref = _storage
          .ref()
          .child(FirebaseConstants.imagesStorage)
          .child(fileName);
      
      final uploadTask = ref.putFile(compressedFile);
      final snapshot = await uploadTask;
      
      // Delete temporary compressed file
      await compressedFile.delete();
      
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      throw Exception('خطأ في رفع الصورة: ${e.toString()}');
    }
  }

  static Future<String> uploadImage(File imageFile, String fileName) async {
    try {
      final ref = _storage
          .ref()
          .child(FirebaseConstants.imagesStorage)
          .child(fileName);
      
      final uploadTask = ref.putFile(imageFile);
      final snapshot = await uploadTask;
      
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      throw Exception('خطأ في رفع الصورة: ${e.toString()}');
    }
  }

  static Future<File> _compressImage(File file, String fileName) async {
    try {
      final tempDir = await getTemporaryDirectory();
      final compressedPath = '${tempDir.path}/compressed_$fileName.jpg';
      
      final compressedFile = await FlutterImageCompress.compressAndGetFile(
        file.absolute.path,
        compressedPath,
        quality: 70, // Good balance between quality and size
        minHeight: 1920,
        minWidth: 1080,
        format: CompressFormat.jpeg,
      );
      
      return compressedFile != null ? File(compressedFile.path) : file;
    } catch (e) {
      print('Image compression failed: $e');
      return file; // Return original if compression fails
    }
  }

  static Future<void> deleteImage(String imageUrl) async {
    try {
      final ref = _storage.refFromURL(imageUrl);
      await ref.delete();
    } catch (e) {
      // Ignore delete errors
      print('Failed to delete image: $e');
    }
  }

  static Future<File?> downloadImage(String imageUrl, String fileName) async {
    try {
      final ref = _storage.refFromURL(imageUrl);
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/$fileName');
      
      await ref.writeToFile(file);
      return file;
    } catch (e) {
      print('Failed to download image: $e');
      return null;
    }
  }
}