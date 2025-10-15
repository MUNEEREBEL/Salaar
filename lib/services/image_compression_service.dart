// lib/services/image_compression_service.dart
import 'dart:io';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path/path.dart' as path;

class ImageCompressionService {
  static const int maxSizeMB = 5;
  static const int maxSizeBytes = maxSizeMB * 1024 * 1024; // 5MB in bytes

  static Future<File> compressImage(File file) async {
    // Check file size
    final fileSize = await file.length();
    
    // If already under 5MB, return as is
    if (fileSize <= maxSizeBytes) {
      return file;
    }

    // Calculate quality based on how much we need to compress
    int quality = 85;
    if (fileSize > maxSizeBytes * 2) {
      quality = 70;
    }
    if (fileSize > maxSizeBytes * 3) {
      quality = 60;
    }

    final dir = path.dirname(file.path);
    final fileName = path.basenameWithoutExtension(file.path);
    final ext = path.extension(file.path);
    final targetPath = path.join(dir, '${fileName}_compressed$ext');

    try {
      final result = await FlutterImageCompress.compressAndGetFile(
        file.absolute.path,
        targetPath,
        quality: quality,
        minWidth: 1920,
        minHeight: 1920,
        format: CompressFormat.jpeg,
      );

      if (result == null) {
        return file; // Return original if compression fails
      }

      final compressedFile = File(result.path);
      final compressedSize = await compressedFile.length();

      // If still too large, compress more aggressively
      if (compressedSize > maxSizeBytes) {
        final secondResult = await FlutterImageCompress.compressAndGetFile(
          compressedFile.absolute.path,
          targetPath.replaceAll('.jpg', '_final.jpg'),
          quality: 50,
          minWidth: 1280,
          minHeight: 1280,
          format: CompressFormat.jpeg,
        );
        
        if (secondResult != null) {
          return File(secondResult.path);
        }
      }

      return compressedFile;
    } catch (e) {
      print('Error compressing image: $e');
      return file; // Return original if error
    }
  }

  static Future<List<File>> compressMultipleImages(List<File> files) async {
    final List<File> compressedFiles = [];
    
    for (final file in files) {
      final compressed = await compressImage(file);
      compressedFiles.add(compressed);
    }
    
    return compressedFiles;
  }

  static Future<bool> isFileSizeValid(File file) async {
    final size = await file.length();
    return size <= maxSizeBytes;
  }

  static String getFileSizeString(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(2)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
  }
}

