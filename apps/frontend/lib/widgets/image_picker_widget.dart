import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:expense_tracker/services/image_service.dart';

class ImagePickerWidget extends StatefulWidget {
  final Function(Uint8List) onImageSelected;
  final double height;
  final double? width;
  final String? initialImageUrl;
  final String placeholder;

  const ImagePickerWidget({
    Key? key,
    required this.onImageSelected,
    this.height = 200,
    this.width, // Changed to nullable and removed default value
    this.initialImageUrl,
    this.placeholder = 'Tap to select an image',
  }) : super(key: key);

  @override
  State<ImagePickerWidget> createState() => _ImagePickerWidgetState();
}

class _ImagePickerWidgetState extends State<ImagePickerWidget> {
  Uint8List? _selectedImageBytes;
  bool _imageLoadError = false;
  String _debugInfo = '';

  @override
  void initState() {
    super.initState();
    print('IMAGE_PICKER_WIDGET: Initializing');
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        print('IMAGE_PICKER_WIDGET: Tapped to pick image');

        try {
          print(
              'IMAGE_PICKER_WIDGET: Calling ImageService.showImagePickerDialog');
          final Uint8List? pickedImageBytes =
              await ImageService.showImagePickerDialog(context);

          if (pickedImageBytes != null) {
            print(
                'IMAGE_PICKER_WIDGET: Image picked - ${pickedImageBytes.length} bytes');

            setState(() {
              _selectedImageBytes = pickedImageBytes;
              _imageLoadError = false;
              _debugInfo = 'Size: ${pickedImageBytes.length} bytes';
            });
            print('IMAGE_PICKER_WIDGET: setState called with new image');

            // Call the callback
            widget.onImageSelected(pickedImageBytes);
            print('IMAGE_PICKER_WIDGET: Callback executed');
          } else {
            print('IMAGE_PICKER_WIDGET: No image selected (returned null)');
          }
        } catch (e) {
          print('IMAGE_PICKER_WIDGET: Exception during image selection: $e');
          setState(() {
            _imageLoadError = true;
            _debugInfo = 'Exception: $e';
          });
        }
      },
      child: Container(
        height: widget.height,
        width:
            widget.width, // Use width as is - it will be constrained by parent
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _imageLoadError ? Colors.red : Colors.grey[300]!,
            width: _imageLoadError ? 2 : 1,
          ),
        ),
        child: _buildImageContent(),
      ),
    );
  }

  Widget _buildImageContent() {
    print(
        'IMAGE_PICKER_WIDGET: Building content, selectedImageBytes: ${_selectedImageBytes != null ? '${_selectedImageBytes!.length} bytes' : 'null'}');

    if (_selectedImageBytes != null) {
      print('IMAGE_PICKER_WIDGET: Displaying selected image bytes');
      // Show selected image from memory
      return Stack(
        fit: StackFit.expand,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.memory(
              _selectedImageBytes!,
              fit: BoxFit.cover,
              // Remove infinite width and height constraints
              // width: double.infinity,
              // height: double.infinity,
              errorBuilder: (context, error, stackTrace) {
                print(
                    'IMAGE_PICKER_WIDGET: Error displaying image from memory: $error');
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, color: Colors.red, size: 30),
                      Text('Error loading image',
                          style: TextStyle(color: Colors.red)),
                      Text(_debugInfo, style: TextStyle(fontSize: 10)),
                    ],
                  ),
                );
              },
            ),
          ),
          Positioned(
            bottom: 8,
            right: 8,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Image selected',
                style: TextStyle(color: Colors.white, fontSize: 10),
              ),
            ),
          ),
        ],
      );
    } else if (widget.initialImageUrl != null &&
        widget.initialImageUrl!.isNotEmpty) {
      print(
          'IMAGE_PICKER_WIDGET: Displaying image from URL: ${widget.initialImageUrl}');
      // Show image from URL
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.network(
          widget.initialImageUrl!,
          fit: BoxFit.cover,
          // Remove infinite width and height constraints
          // width: double.infinity,
          // height: double.infinity,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Center(
              child: CircularProgressIndicator(
                value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded /
                        loadingProgress.expectedTotalBytes!
                    : null,
              ),
            );
          },
          errorBuilder: (context, error, stackTrace) {
            print('IMAGE_PICKER_WIDGET: Error loading network image: $error');
            return _buildPlaceholder();
          },
        ),
      );
    } else {
      print('IMAGE_PICKER_WIDGET: Showing placeholder');
      // Show placeholder
      return _buildPlaceholder();
    }
  }

  Widget _buildPlaceholder() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.add_a_photo,
            size: 40,
            color: Colors.grey,
          ),
          const SizedBox(height: 8),
          Text(
            widget.placeholder,
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
          if (_imageLoadError)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                _debugInfo,
                style: TextStyle(color: Colors.red, fontSize: 10),
                textAlign: TextAlign.center,
              ),
            ),
        ],
      ),
    );
  }
}
