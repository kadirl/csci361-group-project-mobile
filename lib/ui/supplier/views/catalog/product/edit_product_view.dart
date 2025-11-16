import 'dart:developer';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../../core/constants/button_sizes.dart';
import '../../../../../../data/models/product.dart';
import '../../../../../../data/repositories/product_repository.dart';
import '../../../../../../data/repositories/uploads_repository.dart';
import '../../../../../../l10n/app_localizations.dart';
import '../../../../shared/product_images_picker.dart';
import 'product_detail_view.dart';

// Full-screen page for editing an existing product.
class EditProductView extends ConsumerStatefulWidget {
  const EditProductView({super.key, required this.product});

  final Product product;

  @override
  ConsumerState<EditProductView> createState() => _EditProductViewState();
}

class _EditProductViewState extends ConsumerState<EditProductView> {
  // Form key to manage validation state.
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  // Controllers for all form fields.
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _stockQuantityController;
  late final TextEditingController _retailPriceController;
  late final TextEditingController _thresholdController;
  late final TextEditingController _bulkPriceController;
  late final TextEditingController _minimumOrderController;
  late final TextEditingController _unitController;

  // Track original image URLs from the product (for deletion tracking).
  late final List<String> _originalImageUrls;

  // Track currently kept existing image URLs (user can remove these).
  List<String> _keptImageUrls = <String>[];

  // Track newly uploaded image URLs.
  List<String> _newImageUrls = <String>[];

  // Dio client for direct upload to S3 using presigned URLs.
  final Dio _uploadDio = Dio();

  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();

    // Prefill all controllers with current product values.
    _nameController = TextEditingController(text: widget.product.name);
    _descriptionController = TextEditingController(text: widget.product.description);
    _stockQuantityController = TextEditingController(text: widget.product.stockQuantity.toString());
    _retailPriceController = TextEditingController(text: widget.product.retailPrice.toString());
    _thresholdController = TextEditingController(text: widget.product.threshold.toString());
    _bulkPriceController = TextEditingController(text: widget.product.bulkPrice.toString());
    _minimumOrderController = TextEditingController(text: widget.product.minimumOrder.toString());
    _unitController = TextEditingController(text: widget.product.unit);

    // Initialize image URL tracking.
    _originalImageUrls = List<String>.from(widget.product.pictureUrls);
    _keptImageUrls = List<String>.from(widget.product.pictureUrls);
    _newImageUrls = <String>[];
  }

  @override
  void dispose() {
    // Dispose controllers to avoid memory leaks.
    _nameController.dispose();
    _descriptionController.dispose();
    _stockQuantityController.dispose();
    _retailPriceController.dispose();
    _thresholdController.dispose();
    _bulkPriceController.dispose();
    _minimumOrderController.dispose();
    _unitController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations localization = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(localization.catalogEditProductTitle),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            autovalidateMode: AutovalidateMode.onUnfocus,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                // Name input
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: localization.catalogProductNameLabel,
                    border: const OutlineInputBorder(),
                  ),
                  validator: (value) =>
                      _validateRequiredField(value, localization.catalogProductNameLabel),
                ),

                const SizedBox(height: 12),

                // Description input
                TextFormField(
                  controller: _descriptionController,
                  decoration: InputDecoration(
                    labelText: localization.catalogProductDescriptionLabel,
                    border: const OutlineInputBorder(),
                  ),
                  maxLines: 3,
                  validator: (value) =>
                      _validateRequiredField(value, localization.catalogProductDescriptionLabel),
                ),

                const SizedBox(height: 12),

                // Stock quantity
                _buildIntegerField(
                  context: context,
                  controller: _stockQuantityController,
                  label: localization.catalogProductStockQuantityLabel,
                ),

                const SizedBox(height: 12),

                // Retail price
                _buildIntegerField(
                  context: context,
                  controller: _retailPriceController,
                  label: localization.catalogProductRetailPriceLabel,
                ),

                const SizedBox(height: 12),

                // Threshold
                _buildIntegerField(
                  context: context,
                  controller: _thresholdController,
                  label: localization.catalogProductThresholdLabel,
                ),

                const SizedBox(height: 12),

                // Bulk price
                _buildIntegerField(
                  context: context,
                  controller: _bulkPriceController,
                  label: localization.catalogProductBulkPriceLabel,
                ),

                const SizedBox(height: 12),

                // Minimum order
                _buildIntegerField(
                  context: context,
                  controller: _minimumOrderController,
                  label: localization.catalogProductMinimumOrderLabel,
                ),

                const SizedBox(height: 12),

                // Unit input (free text)
                TextFormField(
                  controller: _unitController,
                  decoration: InputDecoration(
                    labelText: localization.catalogProductUnitLabel,
                    border: const OutlineInputBorder(),
                  ),
                  validator: (value) =>
                      _validateRequiredField(value, localization.catalogProductUnitLabel),
                ),

                const SizedBox(height: 12),

                // Existing product images section.
                if (_keptImageUrls.isNotEmpty) ...<Widget>[
                  Text(
                    localization.catalogProductImagesLabel,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 112,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _keptImageUrls.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (BuildContext context, int index) {
                        final String imageUrl = _keptImageUrls[index];

                        return Stack(
                          children: <Widget>[
                            // Image preview container.
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Container(
                                width: 96,
                                height: 96,
                                color: Colors.grey.shade200,
                                child: Image.network(
                                  imageUrl,
                                  width: 96,
                                  height: 96,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => const Icon(Icons.image_not_supported),
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
                                  onPressed: () {
                                    setState(() {
                                      _keptImageUrls.removeAt(index);
                                    });
                                  },
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 12),
                ],

                // Product images picker for new images.
                ProductImagesPicker(
                  maxImages: 5 - _keptImageUrls.length,
                  labelText: localization.catalogProductImagesLabel,
                  placeholderText: localization.catalogProductImagesPlaceholder,
                  uploadImage: _uploadProductImageToS3,
                  onImagesChanged: _handleNewImagesChanged,
                  isEnabled: _keptImageUrls.length < 5,
                  onMaxImagesExceeded: () {
                    // Show alert when user tries to add more than 5 total images.
                    showDialog<void>(
                      context: context,
                      builder: (BuildContext dialogContext) => AlertDialog(
                        title: Text(localization.catalogProductImagesMaxExceededTitle),
                        content: Text(localization.catalogProductImagesMaxExceededMessage),
                        actions: <Widget>[
                          FilledButton(
                            onPressed: () => Navigator.of(dialogContext).pop(),
                            child: const Text('OK'),
                          ),
                        ],
                      ),
                    );
                  },
                ),

                const SizedBox(height: 24),

                // Submit button
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      minimumSize: ButtonSizes.mdFill,
                    ),
                    onPressed: _isSubmitting ? null : () => _handleSubmit(context),
                    child: _isSubmitting
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : Text(localization.commonSubmit),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Build a numeric field that accepts only integers.
  Widget _buildIntegerField({
    required BuildContext context,
    required TextEditingController controller,
    required String label,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      keyboardType: TextInputType.number,
      inputFormatters: <TextInputFormatter>[
        FilteringTextInputFormatter.digitsOnly,
      ],
      validator: (value) => _validateIntegerField(value, label),
    );
  }

  // Validate that a field is not empty.
  String? _validateRequiredField(String? value, String fieldLabel) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldLabel is required.';
    }

    return null;
  }

  // Validate that a value is a non-empty integer.
  String? _validateIntegerField(String? value, String fieldLabel) {
    final String? requiredValidation = _validateRequiredField(value, fieldLabel);
    if (requiredValidation != null) {
      return requiredValidation;
    }

    final String trimmed = value!.trim();
    if (int.tryParse(trimmed) == null) {
      return '$fieldLabel must be a valid integer.';
    }

    return null;
  }

  // Upload a single image to S3 using the presigned POST from UploadsRepository.
  Future<String> _uploadProductImageToS3(
    Uint8List imageBytes,
    String fileExtension,
  ) async {
    try {
      log(
        'EditProductView -> Starting image upload (ext: $fileExtension, '
        'size: ${imageBytes.length} bytes)',
      );

      // Get repository from Riverpod.
      final UploadsRepository uploadsRepository =
          ref.read(uploadsRepositoryProvider);

      // Ask backend for presigned POST response for this extension.
      log(
        'EditProductView -> Requesting presigned POST for extension: '
        '$fileExtension',
      );
      final presignedResponse =
          await uploadsRepository.getUploadUrl(ext: fileExtension);
      log(
        'EditProductView -> Received presigned POST: url=${presignedResponse.uploadUrl}, '
        'finalUrl=${presignedResponse.finalUrl}',
      );

      // Build form data with all required fields plus the file.
      final FormData formData = FormData.fromMap(<String, dynamic>{
        ...presignedResponse.fields,
        'file': MultipartFile.fromBytes(
          imageBytes,
          filename: 'image.$fileExtension',
        ),
      });

      // Upload to S3 using POST with form data.
      log('EditProductView -> Uploading image to S3 via POST...');
      final Response<dynamic> uploadResponse = await _uploadDio.post<dynamic>(
        presignedResponse.uploadUrl,
        data: formData,
        options: Options(
          validateStatus: (int? status) {
            // S3 returns 204 No Content or 200 OK on successful upload.
            return status != null && status >= 200 && status < 300;
          },
        ),
      );

      log(
        'EditProductView -> S3 upload response: status=${uploadResponse.statusCode}, '
        'headers=${uploadResponse.headers}',
      );

      if (uploadResponse.statusCode != null &&
          uploadResponse.statusCode! >= 200 &&
          uploadResponse.statusCode! < 300) {
        log(
          'EditProductView -> Successfully uploaded image to S3: '
          '${presignedResponse.finalUrl}',
        );
      } else {
        throw Exception(
          'S3 upload failed with status ${uploadResponse.statusCode}',
        );
      }

      // Return the final public URL where the file is accessible.
      return presignedResponse.finalUrl;
    } catch (error, stackTrace) {
      log(
        'EditProductView -> Failed to upload image to S3: $error',
        error: error,
        stackTrace: stackTrace,
      );

      // Re-throw the error so the widget can handle it.
      Error.throwWithStackTrace(error, stackTrace);
    }
  }

  // Update local state when the image picker reports new URLs.
  void _handleNewImagesChanged(List<String> urls) {
    setState(() {
      _newImageUrls = urls;
    });
  }

  Future<void> _handleSubmit(BuildContext context) async {
    final AppLocalizations localization = AppLocalizations.of(context)!;

    // Ensure product has an ID for update.
    if (widget.product.id == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(localization.catalogUpdateProductErrorGeneric('Product ID is missing')),
          ),
        );
      }
      return;
    }

    // Trigger form validation first.
    final bool isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid) {
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      // Calculate which images to delete (original URLs that are no longer kept).
      final List<String> imagesToDelete = _originalImageUrls
          .where((String url) => !_keptImageUrls.contains(url))
          .toList();

      // Delete removed images via API.
      if (imagesToDelete.isNotEmpty) {
        log(
          'EditProductView -> Deleting ${imagesToDelete.length} removed images...',
        );

        final UploadsRepository uploadsRepository =
            ref.read(uploadsRepositoryProvider);

        // Delete each removed image.
        for (final String imageUrl in imagesToDelete) {
          try {
            await uploadsRepository.deleteFile(fileUrl: imageUrl);
            log('EditProductView -> Deleted image: $imageUrl');
          } catch (error) {
            log(
              'EditProductView -> Failed to delete image $imageUrl: $error',
            );
            // Continue with other deletions even if one fails.
          }
        }
      }

      // Combine kept existing images and newly uploaded images.
      final List<String> finalPictureUrls = <String>[
        ..._keptImageUrls,
        ..._newImageUrls,
      ];

      log(
        'EditProductView -> Final picture URLs: ${finalPictureUrls.length} '
        '(${_keptImageUrls.length} kept, ${_newImageUrls.length} new)',
      );

      // Map form fields to ProductRequest.
      final ProductRequest request = ProductRequest(
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        pictureUrls: finalPictureUrls,
        stockQuantity: int.parse(_stockQuantityController.text.trim()),
        retailPrice: int.parse(_retailPriceController.text.trim()),
        threshold: int.parse(_thresholdController.text.trim()),
        bulkPrice: int.parse(_bulkPriceController.text.trim()),
        minimumOrder: int.parse(_minimumOrderController.text.trim()),
        unit: _unitController.text.trim(),
      );

      final ProductRepository repository = ref.read(productRepositoryProvider);

      // Update the product.
      final Product updatedProduct = await repository.updateProduct(
        productId: widget.product.id!,
        request: request,
      );

      if (mounted) {
        // Replace the edit view with the updated product detail view.
        Navigator.of(context).pushReplacement(
          MaterialPageRoute<void>(
            builder: (BuildContext context) {
              // Show success snackbar after the detail view is built.
              WidgetsBinding.instance.addPostFrameCallback((_) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(localization.catalogUpdateProductSuccess),
                  ),
                );
              });
              return ProductDetailView(product: updatedProduct);
            },
          ),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              localization.catalogUpdateProductErrorGeneric(error.toString()),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }
}

