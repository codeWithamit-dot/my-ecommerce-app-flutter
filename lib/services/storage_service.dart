// lib/services/storage_service.dart

import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:my_ecommerce_app/model/media_file.dart'; // पैकेज-रिलेटिव पाथ

class StorageService {
  final SupabaseClient _client;
  final String _bucketName = 'media_gallery';

  StorageService(this._client);

  Future<String?> uploadFile(File file) async {
    try {
      final fileName = "${DateTime.now().millisecondsSinceEpoch}_${file.path.split('/').last}";
      await _client.storage.from(_bucketName).upload(fileName, file);
      return _client.storage.from(_bucketName).getPublicUrl(fileName);
    } on StorageException catch (error) {
      if (kDebugMode) {
        debugPrint('Upload Error: ${error.message}');
      }
      return null;
    }
  }

  Future<List<MediaFile>> getFiles() async {
    try {
      final fileObjects = await _client.storage.from(_bucketName).list();

      final mediaFiles = fileObjects.map((file) {
        final url = _client.storage.from(_bucketName).getPublicUrl(file.name);
        
        // ✅ ठीक किया गया: createdAt के टाइप को सुरक्षित रूप से हैंडल करना
        // यह सुनिश्चित करता है कि अगर createdAt स्ट्रिंग में भी आता है, तो भी ऐप क्रैश नहीं होगा।
        final createdAtDateTime = file.createdAt != null
            ? DateTime.tryParse(file.createdAt.toString())
            : null;

        return MediaFile(name: file.name, url: url, uploadedAt: createdAtDateTime);
      }).toList();

      // सबसे नई फ़ाइल को सबसे पहले दिखाने के लिए सॉर्ट करें
      mediaFiles.sort((a, b) => (b.uploadedAt ?? DateTime(1970)).compareTo(a.uploadedAt ?? DateTime(1970)));

      return mediaFiles;
    } on StorageException catch (error) {
      if (kDebugMode) {
        debugPrint('Fetch Error: ${error.message}');
      }
      return [];
    }
  }

  Future<bool> deleteFile(String fileName) async {
    try {
      await _client.storage.from(_bucketName).remove([fileName]);
      return true;
    } on StorageException catch (error) {
      if (kDebugMode) {
        debugPrint('Delete Error: ${error.message}');
      }
      return false;
    }
  }
}