import 'dart:developer';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

/// Local representation of one picked image, including upload state.
class LocalProductImage {
  // Raw bytes for local preview.
  final Uint8List bytes;

  // Uploaded URL on S3 (null until upload succeeds).
  final String? uploadedUrl;

  // Whether this image is currently uploading.
  final bool isUploading;

  // Whether the last upload attempt failed.
  final bool hasUploadError;

  const LocalProductImage({
    required this.bytes,
    required this.uploadedUrl,
    required this.isUploading,
    required this.hasUploadError,
  });

  // Create a new instance with updated fields.
  LocalProductImage copyWith({
    Uint8List? bytes,
    String? uploadedUrl,
    bool? isUploading,
    bool? hasUploadError,
  }) {
    return LocalProductImage(
      bytes: bytes ?? this.bytes,
      uploadedUrl: uploadedUrl ?? this.uploadedUrl,
      isUploading: isUploading ?? this.isUploading,
      hasUploadError: hasUploadError ?? this.hasUploadError,
    );
  }
}

/// Signature for the function that uploads one image and returns its final URL.
typedef ImageUploadFunction = Future<String> Function(
  Uint8List imageBytes,
  String fileExtension,
);

/// Reusable picker widget:
/// - Lets user pick up to [maxImages] images.
/// - Uploads each image immediately via [uploadImage].
/// - Notifies parent about uploaded URLs via [onImagesChanged].
class ProductImagesPicker extends StatefulWidget {
  final int maxImages;
  final ImageUploadFunction uploadImage;
  final ValueChanged<List<String>> onImagesChanged;

  final String labelText;
  final String placeholderText;

  final bool isEnabled;

  /// Optional callback when user tries to add more images than [maxImages] allows.
  final VoidCallback? onMaxImagesExceeded;

  const ProductImagesPicker({
    super.key,
    required this.maxImages,
    required this.uploadImage,
    required this.onImagesChanged,
    required this.labelText,
    required this.placeholderText,
    this.isEnabled = true,
    this.onMaxImagesExceeded,
  });

  @override
  State<ProductImagesPicker> createState() => _ProductImagesPickerState();
}

class _ProductImagesPickerState extends State<ProductImagesPicker> {
  // Picker used to access gallery / camera.
  final ImagePicker _imagePicker = ImagePicker();

  // Internal list of images with their upload state.
  final List<LocalProductImage> _images = <LocalProductImage>[];

  // Notify parent with the list of uploaded URLs.
  void _notifyParentAboutUrls() {
    final List<String> uploadedUrls = _images
        .map((LocalProductImage image) => image.uploadedUrl)
        .whereType<String>()
        .toList();

    widget.onImagesChanged(uploadedUrls);
  }

  // Handle tap on the "add images" area.
  Future<void> _handleAddImagesTap() async {
    if (!widget.isEnabled) {
      return;
    }

    final int remainingSlots = widget.maxImages - _images.length;

    if (remainingSlots <= 0) {
      return;
    }

    final List<XFile> pickedFiles = await _imagePicker.pickMultiImage();

    if (pickedFiles.isEmpty) {
      return;
    }

    // Check if user tried to add more images than allowed.
    if (pickedFiles.length > remainingSlots && widget.onMaxImagesExceeded != null) {
      widget.onMaxImagesExceeded!();
    }

    // Only keep as many as we have remaining slots for.
    final List<XFile> limitedFiles =
        pickedFiles.take(remainingSlots).toList(growable: false);

    for (final XFile file in limitedFiles) {
      await _addSingleImage(file);
    }
  }

  // Add one picked image: read bytes, show preview, upload to S3.
  Future<void> _addSingleImage(XFile file) async {
    // Read bytes from the picked file so we can show a preview.
    final Uint8List imageBytes = await file.readAsBytes();

    // Infer file extension from the path (e.g., ".jpg").
    final String filePath = file.path;
    final String extension = _extractFileExtension(filePath);

    // Create a temporary entry in the list to show local preview.
    final LocalProductImage initialImage = LocalProductImage(
      bytes: imageBytes,
      uploadedUrl: null,
      isUploading: true,
      hasUploadError: false,
    );

    setState(() {
      _images.add(initialImage);
    });

    final int imageIndex = _images.length - 1;

    try {
      // Upload the image bytes to S3 using the provided callback.
      final String uploadedUrl = await widget.uploadImage(
        imageBytes,
        extension,
      );

      // Validate that we got a non-empty URL.
      if (uploadedUrl.isEmpty) {
        throw Exception('Upload succeeded but returned empty URL');
      }

      log('ProductImagesPicker -> Successfully uploaded image: $uploadedUrl');

      // Update entry with the returned URL and mark upload as finished.
      setState(() {
        _images[imageIndex] = _images[imageIndex].copyWith(
          uploadedUrl: uploadedUrl,
          isUploading: false,
          hasUploadError: false,
        );
      });

      // Inform parent that URLs changed.
      _notifyParentAboutUrls();
    } catch (error, stackTrace) {
      // Log the error with full details.
      log(
        'ProductImagesPicker -> Failed to upload image: $error',
        error: error,
        stackTrace: stackTrace,
      );

      // If upload fails, mark this entry with an error.
      setState(() {
        _images[imageIndex] = _images[imageIndex].copyWith(
          isUploading: false,
          hasUploadError: true,
        );
      });
    }
  }

  // Remove an image by index (does not call delete on backend).
  void _removeImageAt(int index) {
    if (index < 0 || index >= _images.length) {
      return;
    }

    setState(() {
      _images.removeAt(index);
    });

    _notifyParentAboutUrls();
  }

  // Extract extension from a file path; default to "jpg".
  String _extractFileExtension(String filePath) {
    final int dotIndex = filePath.lastIndexOf('.');
    if (dotIndex == -1 || dotIndex == filePath.length - 1) {
      // Default when we cannot infer the extension.
      return 'jpg';
    }

    return filePath.substring(dotIndex + 1).toLowerCase();
  }

  @override
  Widget build(BuildContext context) {
    // Compute how many more images can be added.
    final int remainingSlots = widget.maxImages - _images.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        // Tap area that looks like a regular input with upload icon.
        InkWell(
          onTap: remainingSlots > 0 ? _handleAddImagesTap : null,
          child: InputDecorator(
            decoration: InputDecoration(
              labelText: widget.labelText,
              border: const OutlineInputBorder(),
              suffixIcon: const Icon(Icons.file_upload),
            ),
            child: Text(
              _images.isEmpty
                  ? widget.placeholderText
                  : '${_images.length} / ${widget.maxImages}',
              style: TextStyle(
                color: _images.isEmpty ? Colors.grey : null,
              ),
            ),
          ),
        ),

        const SizedBox(height: 12),

        // Horizontal row of previews with delete + upload state.
        if (_images.isNotEmpty)
          SizedBox(
            height: 112,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _images.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (BuildContext context, int index) {
                final LocalProductImage image = _images[index];

                return Stack(
                  children: <Widget>[
                    // Image preview container.
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        width: 96,
                        height: 96,
                        color: Colors.grey.shade200,
                        child: image.bytes.isEmpty
                            ? const Icon(Icons.image, size: 40)
                            : Image.memory(
                                image.bytes,
                                width: 96,
                                height: 96,
                                fit: BoxFit.cover,
                              ),
                      ),
                    ),

                    // Top-right delete button.
                    Positioned(
                      top: 0,
                      right: 0,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: IconButton(
                          padding: EdgeInsets.zero,
                          iconSize: 20,
                          icon: const Icon(
                            Icons.close,
                            color: Colors.white,
                          ),
                          onPressed: () => _removeImageAt(index),
                        ),
                      ),
                    ),

                    // Centered progress indicator while uploading.
                    if (image.isUploading)
                      Positioned.fill(
                        child: Container(
                          color: Colors.black26,
                          child: const Center(
                            child: SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                              ),
                            ),
                          ),
                        ),
                      ),

                    // Error badge if upload failed.
                    if (image.hasUploadError)
                      Positioned(
                        bottom: 4,
                        left: 4,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.redAccent,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'Error',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                            ),
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
      ],
    );
  }
}

