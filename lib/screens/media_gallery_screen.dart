// lib/screens/media_gallery_screen.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';

import 'package:my_ecommerce_app/services/storage_service.dart';
import 'package:my_ecommerce_app/model/media_file.dart';

class MediaGalleryScreen extends StatefulWidget {
  const MediaGalleryScreen({super.key});

  @override
  MediaGalleryScreenState createState() => MediaGalleryScreenState();
}

class MediaGalleryScreenState extends State<MediaGalleryScreen> {
  late final StorageService _storageService;
  late Future<List<MediaFile>> _mediaFuture;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _storageService = StorageService(Supabase.instance.client);
    _refreshGallery();
  }

  void _refreshGallery() {
    setState(() {
      _mediaFuture = _storageService.getFiles();
    });
  }

  Future<void> _uploadImage() async {
    setState(() { _isUploading = true; });

    final picker = ImagePicker();
    final imageFile = await picker.pickImage(source: ImageSource.gallery, maxWidth: 800);

    if (imageFile == null) {
      setState(() => _isUploading = false);
      return;
    }

    final file = File(imageFile.path);
    await _storageService.uploadFile(file);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Image uploaded!'), backgroundColor: Colors.green),
    );

    setState(() { _isUploading = false; });
    _refreshGallery();
  }

  Future<void> _deleteImage(String fileName) async {
    final success = await _storageService.deleteFile(fileName);
    if (!mounted) return;
    if(success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$fileName deleted.')),
      );
       _refreshGallery();
    } else {
       ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Deletion failed.'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Media Gallery'),
        actions: [
          if (_isUploading)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.0),
              child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3,)),
            )
          else
            IconButton(
              icon: const Icon(Icons.add_photo_alternate_outlined),
              onPressed: _uploadImage,
              tooltip: 'Upload Image',
            ),
        ],
      ),
      body: FutureBuilder<List<MediaFile>>(
        future: _mediaFuture,
        builder: (context, snapshot) {
          // ✅ ठीक किया गया: CircularProgressIndicator की स्पेलिंग सही की गई
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          
          // ✅ ठीक किया गया: Error और खाली डेटा की स्थिति को हैंडल किया गया
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Text(
                'No media found. Press + to upload!',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            );
          }

          // जब डेटा सफलतापूर्वक लोड हो जाए
          final mediaFiles = snapshot.data!;
          return RefreshIndicator(
            onRefresh: () async => _refreshGallery(),
            child: GridView.builder(
              padding: const EdgeInsets.all(8),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: mediaFiles.length,
              itemBuilder: (context, index) {
                final media = mediaFiles[index];
                return ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: GridTile(
                    footer: GridTileBar(
                      backgroundColor: Colors.black45,
                      title: Text(
                        media.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 10),
                      ),
                      // ✅ ठीक किया गया: अब _deleteImage फंक्शन यहाँ इस्तेमाल हो रहा है
                      trailing: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.white, size: 18),
                        onPressed: () => _deleteImage(media.name),
                        tooltip: 'Delete Image',
                      ),
                    ),
                    child: CachedNetworkImage(
                      imageUrl: media.url,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(color: Colors.grey[200]),
                      errorWidget: (context, url, error) => const Icon(Icons.error, color: Colors.red),
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}