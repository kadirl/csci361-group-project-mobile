import 'dart:developer';

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

// Full-screen page for creating a new product.
class CreateProductView extends ConsumerStatefulWidget {
  const CreateProductView({super.key});

  @override
  ConsumerState<CreateProductView> createState() => _CreateProductViewState();
}

class _CreateProductViewState extends ConsumerState<CreateProductView> {
  // Form key to manage validation state.
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  // Controllers for all form fields.
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _stockQuantityController = TextEditingController();
  final TextEditingController _retailPriceController = TextEditingController();
  final TextEditingController _thresholdController = TextEditingController();
  final TextEditingController _bulkPriceController = TextEditingController();
  final TextEditingController _minimumOrderController = TextEditingController();
  final TextEditingController _unitController = TextEditingController();

  // Store uploaded product image URLs.
  List<String> _productImageUrls = <String>[];

  // Dio client for direct PUT to S3 using the presigned URL.
  final Dio _uploadDio = Dio();

  bool _isSubmitting = false;

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
        title: Text(localization.catalogCreateProductTitle),
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

                // Product images picker with immediate S3 upload.
                ProductImagesPicker(
                  maxImages: 5,
                  labelText: localization.catalogProductImagesLabel,
                  placeholderText: localization.catalogProductImagesPlaceholder,
                  uploadImage: _uploadProductImageToS3,
                  onImagesChanged: _handleProductImagesChanged,
                ),

                const SizedBox(height: 24),

                // Submit button (no images yet; uses placeholder URLs on submit).
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
        'CreateProductView -> Starting image upload (ext: $fileExtension, '
        'size: ${imageBytes.length} bytes)',
      );

      // Get repository from Riverpod.
      final UploadsRepository uploadsRepository =
          ref.read(uploadsRepositoryProvider);

      // Ask backend for presigned POST response for this extension.
      log(
        'CreateProductView -> Requesting presigned POST for extension: '
        '$fileExtension',
      );
      final presignedResponse =
          await uploadsRepository.getUploadUrl(ext: fileExtension);
      log(
        'CreateProductView -> Received presigned POST: url=${presignedResponse.uploadUrl}, '
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
      log('CreateProductView -> Uploading image to S3 via POST...');
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
        'CreateProductView -> S3 upload response: status=${uploadResponse.statusCode}, '
        'headers=${uploadResponse.headers}',
      );

      if (uploadResponse.statusCode != null &&
          uploadResponse.statusCode! >= 200 &&
          uploadResponse.statusCode! < 300) {
        log(
          'CreateProductView -> Successfully uploaded image to S3: '
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
        'CreateProductView -> Failed to upload image to S3: $error',
        error: error,
        stackTrace: stackTrace,
      );

      // Re-throw the error so the widget can handle it.
      Error.throwWithStackTrace(error, stackTrace);
    }
  }

  // Update local state when the image picker reports new URLs.
  void _handleProductImagesChanged(List<String> urls) {
    setState(() {
      _productImageUrls = urls;
    });
  }

  Future<void> _handleSubmit(BuildContext context) async {
    final AppLocalizations localization = AppLocalizations.of(context)!;

    // Trigger form validation first.
    final bool isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid) {
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    // Store references before async gap to avoid BuildContext issues.
    final NavigatorState navigator = Navigator.of(context);
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);

    try {
      // Build picture URLs payload from uploaded images.
      final List<String> pictureUrls = _productImageUrls;

      // Map form fields to ProductRequest.
      final ProductRequest request = ProductRequest(
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        pictureUrls: pictureUrls,
        stockQuantity: int.parse(_stockQuantityController.text.trim()),
        retailPrice: int.parse(_retailPriceController.text.trim()),
        threshold: int.parse(_thresholdController.text.trim()),
        bulkPrice: int.parse(_bulkPriceController.text.trim()),
        minimumOrder: int.parse(_minimumOrderController.text.trim()),
        unit: _unitController.text.trim(),
      );

      final ProductRepository repository = ref.read(productRepositoryProvider);

      await repository.addProduct(request: request);

      if (!mounted) {
        return;
      }

      messenger.showSnackBar(
        SnackBar(
          content: Text(localization.catalogCreateProductSuccess),
        ),
      );
      navigator.pop();
    } catch (error) {
      if (!mounted) {
        return;
      }

      messenger.showSnackBar(
        SnackBar(
          content: Text(
            localization.catalogCreateProductErrorGeneric(error.toString()),
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }
}


