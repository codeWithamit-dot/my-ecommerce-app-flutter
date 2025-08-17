// lib/models/media_file.dart

// यह क्लास Supabase से मिली फाइल की जानकारी रखेगी।
class MediaFile {
  final String name; // फाइल का नाम ही उसकी ID होगी
  final String url;
  final DateTime? uploadedAt;

  MediaFile({
    required this.name,
    required this.url,
    required this.uploadedAt,
  });
}