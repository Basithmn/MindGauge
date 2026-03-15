import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'ui_components.dart';

class PhotosSection extends StatefulWidget {
  final List<String> initialPhotos;
  final Function(List<String>)? onPhotosChanged;
  final bool isReadOnly;

  const PhotosSection({
    super.key,
    required this.initialPhotos,
    this.onPhotosChanged,
    this.isReadOnly = false,
  });

  @override
  State<PhotosSection> createState() => _PhotosSectionState();
}

class _PhotosSectionState extends State<PhotosSection> {
  late List<String> _photos;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _photos = List.from(widget.initialPhotos);
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(source: source);
      if (image != null) {
        setState(() {
          _photos.add(image.path);
        });
        if (widget.onPhotosChanged != null) {
          widget.onPhotosChanged!(_photos);
        }
      }
    } catch (e) {
      debugPrint("Error picking image: $e");
    }
  }

  void _removePhoto(String path) {
    setState(() {
      _photos.remove(path);
    });
    if (widget.onPhotosChanged != null) {
      widget.onPhotosChanged!(_photos);
    }
  }

  void _showPickerOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              ListTile(
                leading: const Icon(
                  Icons.photo_library,
                  color: AppColors.primary,
                ),
                title: const Text(
                  'Photo Library',
                  style: TextStyle(color: AppColors.text),
                ),
                onTap: () {
                  _pickImage(ImageSource.gallery);
                  Navigator.of(context).pop();
                },
              ),
              ListTile(
                leading: const Icon(
                  Icons.photo_camera,
                  color: AppColors.primary,
                ),
                title: const Text(
                  'Camera',
                  style: TextStyle(color: AppColors.text),
                ),
                onTap: () {
                  _pickImage(ImageSource.camera);
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'PERSONAL PHOTOS',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.secondary,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.cardColor,
            borderRadius: BorderRadius.circular(15),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_photos.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10.0),
                  child: Text(
                    widget.isReadOnly
                        ? 'No personal photos added yet. Add them in Interests.'
                        : 'Add personal photos that remind you of good times!',
                    style: const TextStyle(
                      fontStyle: FontStyle.italic,
                      color: AppColors.text,
                    ),
                  ),
                )
              else
                _buildCollage(context),
              if (!widget.isReadOnly)
                Column(
                  children: [
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => _showPickerOptions(context),
                        icon: const Icon(Icons.add_a_photo),
                        label: const Text('Add Photo'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ],
    );
  }

  // --- COLLAGE LOGIC ---

  Widget _buildCollage(BuildContext context) {
    const double collageHeight = 250.0;

    return GestureDetector(
      onTap: () {
        // Open the full collage expanded view
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => FullScreenCollageScreen(
              photos: _photos,
              isReadOnly: widget.isReadOnly,
            ),
          ),
        );
      },
      child: Container(
        height: collageHeight,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(15),
          child: _getCollageLayout(),
        ),
      ),
    );
  }

  Widget _getCollageLayout() {
    int count = _photos.length;
    if (count == 1) {
      return _buildPhotoTile(_photos[0], 0);
    } else if (count == 2) {
      return Row(
        children: [
          Expanded(child: _buildPhotoTile(_photos[0], 0)),
          const SizedBox(width: 4),
          Expanded(child: _buildPhotoTile(_photos[1], 1)),
        ],
      );
    } else if (count == 3) {
      return Row(
        children: [
          Expanded(flex: 2, child: _buildPhotoTile(_photos[0], 0)),
          const SizedBox(width: 4),
          Expanded(
            flex: 1,
            child: Column(
              children: [
                Expanded(child: _buildPhotoTile(_photos[1], 1)),
                const SizedBox(height: 4),
                Expanded(child: _buildPhotoTile(_photos[2], 2)),
              ],
            ),
          ),
        ],
      );
    } else {
      // 4 or more
      return Row(
        children: [
          Expanded(flex: 2, child: _buildPhotoTile(_photos[0], 0)),
          const SizedBox(width: 4),
          Expanded(
            flex: 1,
            child: Column(
              children: [
                Expanded(child: _buildPhotoTile(_photos[1], 1)),
                const SizedBox(height: 4),
                Expanded(child: _buildPhotoTile(_photos[2], 2)),
                const SizedBox(height: 4),
                Expanded(
                  child: _buildPhotoTile(
                    _photos[3],
                    3,
                    showOverlayIfMore: true,
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }
  }

  Widget _buildPhotoTile(
    String photoPath,
    int index, {
    bool showOverlayIfMore = false,
  }) {
    bool hasMore = showOverlayIfMore && _photos.length > 4;
    int remainingCount = _photos.length - 4;

    return Stack(
      fit: StackFit.expand,
      children: [
        GestureDetector(
          onTap: () {
            // Open individual image in full screen (with Hero transition)
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) =>
                    FullScreenPhotoViewer(photoPath: photoPath, tag: photoPath),
              ),
            );
          },
          child: Hero(
            tag: photoPath,
            child: Image.file(File(photoPath), fit: BoxFit.cover),
          ),
        ),
        // Overlay for "+X more"
        if (hasMore)
          Container(
            color: Colors.black.withOpacity(0.5),
            child: Center(
              child: Text(
                '+$remainingCount',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        // Edit Mode Delete Button
        if (!widget.isReadOnly)
          Positioned(
            top: 4,
            right: 4,
            child: GestureDetector(
              onTap: () => _removePhoto(photoPath),
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.black54,
                  shape: BoxShape.circle,
                ),
                padding: const EdgeInsets.all(4),
                child: const Icon(Icons.close, size: 16, color: Colors.white),
              ),
            ),
          ),
      ],
    );
  }
}

// --- FULL SCREEN VIEWERS ---

class FullScreenCollageScreen extends StatelessWidget {
  final List<String> photos;
  final bool isReadOnly;

  const FullScreenCollageScreen({
    super.key,
    required this.photos,
    required this.isReadOnly,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('Collage Viewer'),
        elevation: 0,
      ),
      body: SafeArea(
        // We use AspectRatio or let it naturally fill the bounds
        // using Grid/List for a structured, ratio-independent collage
        child: Padding(
          padding: const EdgeInsets.all(4.0),
          child: GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount:
                  2, // 2 columns looks good for a phone ratio gallery
              crossAxisSpacing: 4,
              mainAxisSpacing: 4,
            ),
            itemCount: photos.length,
            itemBuilder: (context, index) {
              final photoPath = photos[index];
              return GestureDetector(
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => FullScreenPhotoViewer(
                        photoPath: photoPath,
                        tag: 'grid_$photoPath',
                      ),
                    ),
                  );
                },
                child: Hero(
                  tag: 'grid_$photoPath',
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.file(File(photoPath), fit: BoxFit.cover),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class FullScreenPhotoViewer extends StatelessWidget {
  final String photoPath;
  final String tag;

  const FullScreenPhotoViewer({
    super.key,
    required this.photoPath,
    required this.tag,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Pinch to Zoom viewer
          Center(
            child: InteractiveViewer(
              panEnabled: true,
              minScale: 1.0,
              maxScale: 4.0,
              child: Hero(
                tag: tag,
                child: Image.file(
                  File(photoPath),
                  fit: BoxFit.contain, // Fit ratio dynamically inside screen
                  width: double.infinity,
                  height: double.infinity,
                ),
              ),
            ),
          ),
          // Clean back button over the image
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            left: 10,
            child: IconButton(
              icon: const Icon(
                Icons.arrow_back_ios,
                color: Colors.white,
                size: 28,
              ),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
        ],
      ),
    );
  }
}
