import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../../core/constants/button_sizes.dart';
import '../../../../../../data/models/product.dart';
import '../../../../../../data/repositories/product_repository.dart';
import '../../../../../../l10n/app_localizations.dart';

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

    try {
      // Build placeholder image URLs payload: four items alternating between given links.
      const String urlA =
          'https://csci361bucket.s3.eu-north-1.amazonaws.com/uploads/f5323d7c-b9fc-4396-99dc-eb30bb51c653.jpg';
      const String urlB =
          'https://csci361bucket.s3.eu-north-1.amazonaws.com/uploads/f8c7b4bf-b4a0-4140-8ac5-0851c6d6fcda.jpg';

      final List<String> pictureUrls = <String>[urlA, urlB, urlA, urlB];

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

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(localization.catalogCreateProductSuccess),
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              localization.catalogCreateProductErrorGeneric(error.toString()),
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


