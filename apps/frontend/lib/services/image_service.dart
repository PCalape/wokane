import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class ImageService {
  static final ImagePicker _picker = ImagePicker();

  /// Pick an image from the gallery
  /// Returns image bytes that can be used for display and upload
  static Future<Uint8List?> pickImageBytesFromGallery({
    double? maxWidth,
    double? maxHeight,
    int? imageQuality,
  }) async {
    try {
      print("IMAGE_SERVICE: Starting gallery picker");
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: maxWidth,
        maxHeight: maxHeight,
        imageQuality: imageQuality ?? 85,
      );

      print(
          "IMAGE_SERVICE: Gallery picker returned: ${pickedFile != null ? 'file' : 'null'}");
      if (pickedFile == null) return null;

      try {
        // Get the bytes directly
        final bytes = await pickedFile.readAsBytes();
        print(
            "IMAGE_SERVICE: Successfully read ${bytes.length} bytes from gallery image");
        return bytes;
      } catch (e) {
        print("IMAGE_SERVICE: Failed to read bytes from gallery image: $e");
        return null;
      }
    } catch (e) {
      print("IMAGE_SERVICE: Error in gallery picker: $e");
      return null;
    }
  }

  /// Take a picture using the camera
  /// Returns image bytes that can be used for display and upload
  static Future<Uint8List?> takePhotoBytesWithCamera({
    double? maxWidth,
    double? maxHeight,
    int? imageQuality,
  }) async {
    try {
      print("IMAGE_SERVICE: Starting camera");
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: maxWidth,
        maxHeight: maxHeight,
        imageQuality: imageQuality ?? 85,
      );

      print(
          "IMAGE_SERVICE: Camera returned: ${pickedFile != null ? 'file' : 'null'}");
      if (pickedFile == null) return null;

      try {
        // Get the bytes directly
        final bytes = await pickedFile.readAsBytes();
        print(
            "IMAGE_SERVICE: Successfully read ${bytes.length} bytes from camera image");
        return bytes;
      } catch (e) {
        print("IMAGE_SERVICE: Failed to read bytes from camera image: $e");
        return null;
      }
    } catch (e) {
      print("IMAGE_SERVICE: Error with camera: $e");
      return null;
    }
  }

  /// Shows an image picker dialog that lets the user choose between
  /// taking a new photo or selecting from gallery
  static Future<Uint8List?> showImagePickerDialog(BuildContext context) async {
    print("IMAGE_SERVICE: Showing image picker dialog");

    // Create a completer to handle the async result
    final Completer<Uint8List?> completer = Completer<Uint8List?>();

    // Show the dialog but don't await its result directly
    showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Select Image'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  child: const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Text('Take a Picture'),
                  ),
                  onTap: () async {
                    print("IMAGE_SERVICE: Take picture option tapped");
                    // Close dialog first
                    Navigator.of(dialogContext).pop();

                    // Then perform the image picking operation
                    final Uint8List? photoBytes =
                        await takePhotoBytesWithCamera();

                    // Complete with the result
                    if (photoBytes != null) {
                      print(
                          "IMAGE_SERVICE: Returning camera photo bytes: ${photoBytes.length}");
                      completer.complete(photoBytes);
                    } else {
                      print("IMAGE_SERVICE: Camera returned null");
                      if (!completer.isCompleted) {
                        completer.complete(null);
                      }
                    }
                  },
                ),
                const SizedBox(height: 16),
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  child: const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Text('Choose from Gallery'),
                  ),
                  onTap: () async {
                    print("IMAGE_SERVICE: Gallery option tapped");
                    // Close dialog first
                    Navigator.of(dialogContext).pop();

                    // Then perform the image picking operation
                    final Uint8List? galleryImageBytes =
                        await pickImageBytesFromGallery();

                    // Complete with the result
                    if (galleryImageBytes != null) {
                      print(
                          "IMAGE_SERVICE: Returning gallery bytes: ${galleryImageBytes.length}");
                      completer.complete(galleryImageBytes);
                    } else {
                      print("IMAGE_SERVICE: Gallery picker returned null");
                      if (!completer.isCompleted) {
                        completer.complete(null);
                      }
                    }
                  },
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                print("IMAGE_SERVICE: Cancel button tapped");
                Navigator.of(dialogContext).pop();
                completer.complete(null);
              },
            ),
          ],
        );
      },
    );

    // Return the future from the completer
    return completer.future;
  }
}
