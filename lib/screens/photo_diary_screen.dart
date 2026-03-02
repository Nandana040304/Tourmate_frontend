import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:io';
import '../config/api_config.dart';

class PhotoDiaryScreen extends StatefulWidget {
  final String accessToken;


  const PhotoDiaryScreen({
    super.key,
    required this.accessToken,
  });

  @override
  State<PhotoDiaryScreen> createState() => _PhotoDiaryScreenState();
}

class _PhotoDiaryScreenState extends State<PhotoDiaryScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();
  List<PhotoMemory> _photoMemories = [];
  List<PhotoMemory> _filteredMemories = [];
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _fetchPhotos();   // 🔥 VERY IMPORTANT
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      _isSearching = _searchController.text.isNotEmpty;
      _filterPhotos();
    });
  }

  void _filterPhotos() {
    if (_searchController.text.isEmpty) {
      _filteredMemories = List.from(_photoMemories);
    } else {
      final query = _searchController.text.toLowerCase();
      _filteredMemories = _photoMemories.where((photo) =>
          photo.caption.toLowerCase().contains(query) ||
          photo.location.toLowerCase().contains(query)
      ).toList();
    }
  }

  Future<void> _fetchPhotos() async {
    final url = Uri.parse(ApiConfig.getPhotos);

    final response = await http.get(
      url,
      headers: {
        "Authorization": "Bearer ${widget.accessToken}",
      },
    );

    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);

      setState(() {
        _photoMemories = data.map((photo) {
          return PhotoMemory(
            id: photo["id"],
            imageUrl: photo["image"],   // now this is server URL
            caption: photo["caption"],
            location: photo["location"],
            dateTime: DateTime.parse(photo["created_at"]),
          );
        }).toList();

        _filterPhotos();
      });
    }
  }

  Future<void> _deletePhoto(int photoId) async {
    final response = await http.delete(
      Uri.parse("${ApiConfig.baseUrl}/api/photodiary/delete/$photoId/"),
      headers: {
        "Authorization": "Bearer ${widget.accessToken}",
      },
    );

    if (response.statusCode == 200) {
      _showSuccessSnackBar("Deleted successfully");
      _fetchPhotos();
    } else {
      _showErrorSnackBar("Delete failed");
    }
  }

  // Show image source selection dialog
  Future<void> showImageSourceDialog() {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Photo'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Camera'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Gallery'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  // Pick image from camera or gallery
  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        _showAddPhotoDialog(pickedFile.path);
      }
    } catch (e) {
      _showErrorSnackBar('Failed to pick image: $e');
    }
  }

  // Show dialog to add caption and location
  void _showAddPhotoDialog(String imagePath) {
    final captionController = TextEditingController();
    final locationController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Memory'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Image preview
              Container(
                height: 150,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.grey[100],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.file(
                    File(imagePath),
                    fit: BoxFit.cover,
                  )
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: captionController,
                decoration: const InputDecoration(
                  labelText: 'Caption',
                  hintText: 'Add a caption...',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: locationController,
                decoration: const InputDecoration(
                  labelText: 'Location',
                  hintText: 'Where was this taken?',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (captionController.text.isNotEmpty && locationController.text.isNotEmpty) {
                _addPhotoMemory(
                  imagePath,
                  captionController.text,
                  locationController.text,
                );
                Navigator.pop(context);
              } else {
                _showErrorSnackBar('Please fill in all fields');
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  // Add new photo memory
  Future<void> _addPhotoMemory(
      String imagePath, String caption, String location) async {

    final url = Uri.parse(ApiConfig.uploadPhoto);

    var request = http.MultipartRequest("POST", url);

    request.headers["Authorization"] = "Bearer ${widget.accessToken}";

    request.fields["caption"] = caption;
    request.fields["location"] = location;

    request.files.add(
      await http.MultipartFile.fromPath(
        "image",
        imagePath,
      ),
    );

    var response = await request.send();

    if (response.statusCode == 201) {
      _fetchPhotos();
      _showSuccessSnackBar("Memory uploaded successfully!");
    } else {
      _showErrorSnackBar("Upload failed");
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  // Show photo details
  void _showPhotoDetails(PhotoMemory photo) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Close button
            Align(
              alignment: Alignment.topRight,
              child: IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close),
              ),
            ),

            // Image
            Container(
              height: 300,
              width: double.infinity,
              child: ClipRRect(
                borderRadius:
                const BorderRadius.vertical(top: Radius.circular(4)),
                child: Image.network(
                  "${ApiConfig.baseUrl}${photo.imageUrl}",
                  fit: BoxFit.cover,
                )
              ),
            ),

            // Details
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    photo.caption,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),

                  Row(
                    children: [
                      const Icon(Icons.location_on,
                          size: 16, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(
                        photo.location,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 4),

                  Row(
                    children: [
                      const Icon(Icons.access_time,
                          size: 16, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(
                        _formatDateTime(photo.dateTime),
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // 🔴 DELETE BUTTON ADDED HERE
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        _deletePhoto(photo.id);
                      },
                      icon: const Icon(Icons.delete),
                      label: const Text("Delete"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        return '${difference.inMinutes} minutes ago';
      }
      return '${difference.inHours} hours ago';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Column(
          children: [
            _buildSearchBar(),
            Expanded(
              child: _filteredMemories.isEmpty
                  ? _buildEmptyState()
                  : _buildPhotoGrid(),
            ),
          ],
        ),
        // Floating action button
        Positioned(
          bottom: 16,
          right: 16,
          child: FloatingActionButton(
            onPressed: showImageSourceDialog,
            backgroundColor: const Color(0xFF2196F3),
            child: const Icon(Icons.add, color: Colors.white),
          ),
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.grey[50],
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search photos',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _isSearching
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                  },
                )
              : null,
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(25),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.photo_library_outlined,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No memories yet',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Start adding your travel moments!',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[50],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoGrid() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 0.8,
        ),
        itemCount: _filteredMemories.length,
        itemBuilder: (context, index) {
          final photo = _filteredMemories[index];
          return _buildPhotoCard(photo);
        },
      ),
    );
  }

  Widget _buildPhotoCard(PhotoMemory photo) {
    return GestureDetector(
      onTap: () => _showPhotoDetails(photo),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image
              Expanded(
                flex: 3,
                child: SizedBox(
                  width: double.infinity,
                  child:Image.network(
                    "${ApiConfig.baseUrl}${photo.imageUrl}",
                    fit: BoxFit.cover,
                  )

                ),
              ),
              // Caption and location
              Expanded(
                flex: 1,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(8),
                  color: Colors.white,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        photo.caption,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          const Icon(
                            Icons.location_on,
                            size: 10,
                            color: Colors.grey,
                          ),
                          const SizedBox(width: 2),
                          Expanded(
                            child: Text(
                              photo.location,
                              style: const TextStyle(
                                fontSize: 10,
                                color: Colors.grey,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
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

// Photo memory model
class PhotoMemory {
  final int id;
  final String imageUrl;
  final String caption;
  final String location;
  final DateTime dateTime;

  PhotoMemory({
    required this.id,
    required this.imageUrl,
    required this.caption,
    required this.location,
    required this.dateTime,
  });
}
