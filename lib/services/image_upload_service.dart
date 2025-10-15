// lib/services/image_upload_service.dart
import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:path/path.dart' as path;

class ImageUploadService {
  static final SupabaseClient _supabase = Supabase.instance.client;

  static Future<List<String>> uploadImages(List<File> images) async {
    try {
      print('🖼️ Starting image upload for ${images.length} images');
      
      final user = _supabase.auth.currentUser;
      if (user == null) {
        print('❌ No user logged in for image upload');
        return [];
      }

      List<String> uploadedUrls = [];

      for (int i = 0; i < images.length; i++) {
        try {
          final file = images[i];
          
          // Check if file exists
          if (!await file.exists()) {
            print('❌ Image $i file does not exist');
            continue;
          }

          // Generate unique filename
          final timestamp = DateTime.now().millisecondsSinceEpoch;
          final fileExtension = path.extension(file.path);
          final fileName = '${user.id}_${timestamp}_$i$fileExtension';
          
          print('📤 Uploading image $i: $fileName');

          // Upload file directly
          await _supabase.storage
              .from('issue-images')
              .upload(fileName, file);

          // Get public URL
          final publicUrl = _supabase.storage
              .from('issue-images')
              .getPublicUrl(fileName);

          print('✅ Upload successful: $publicUrl');
          uploadedUrls.add(publicUrl);

        } catch (e) {
          print('❌ Error uploading image $i: $e');
        }
      }

      print('🎉 Image upload completed: ${uploadedUrls.length}/${images.length} uploaded');
      return uploadedUrls;
    } catch (e) {
      print('❌ Image upload service error: $e');
      return [];
    }
  }

  static Future<String?> uploadSingle(File image) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return null;
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final ext = path.extension(image.path);
      final fileName = '${user.id}_$timestamp$ext';
      await _supabase.storage.from('issue-images').upload(fileName, image);
      return _supabase.storage.from('issue-images').getPublicUrl(fileName);
    } catch (_) {
      return null;
    }
  }
}